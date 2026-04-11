-- beamer-background.lua
--
-- Adds per-slide and title-slide background image support for Beamer PDF output.
-- Reads the same attributes used by reveal.js, so slides work across
-- both output formats without any changes to the Markdown source.
--
-- Supported attributes on ## headings:
--   background-image="img/foo.jpg"        (required)
--   background-size="cover"               (optional; "cover" or "contain", default: cover)
--   background-opacity="0.4"              (optional; 0.0–1.0, default: 1.0)
--
-- Title slide background is read from the frontmatter:
--   title-slide-attributes:
--     data-background-image: img/foo.jpg
--     data-background-size: cover         (optional)
--     data-background-opacity: "0.4"      (optional)
--
-- Example:
--   ## My Slide {background-image="img/hero.jpg" background-size="cover"}
--
-- ── Strategy ─────────────────────────────────────────────────────────────────
-- Content slides always use \begin{frame}, so \BeforeBeginEnvironment{frame}
-- fires reliably at the true outer TeX level before any group opens.
--
-- A raw LaTeX block is inserted just before each background heading to arm a
-- global flag (\ifbgpending).  The hook reads the flag and installs a TikZ-
-- based \setbeamertemplate{background} overlay.  Using the overlay layer
-- (never \usebackgroundtemplate / background canvas) means the beamer theme's
-- own canvas colour is never disturbed.
--
-- A second flag (\ifbgactive) tracks whether a background is currently applied
-- so that plain frames only receive a reset call on the transition from a
-- background slide, leaving all other frames' default styling completely intact.

local function is_opaque(opacity)
  return opacity == nil or opacity == "" or opacity == "1" or opacity == "1.0"
end

-- Resolve an image path to absolute so lualatex can find it regardless of
-- the temp directory it runs from.  Relative paths are resolved against the
-- directory containing the first input file.
local function resolve_image_path(image)
  if pandoc.path.is_absolute(image) then return image end
  local input = PANDOC_STATE and PANDOC_STATE.input_files and PANDOC_STATE.input_files[1]
  if not input then return image end
  local base = pandoc.path.directory(pandoc.path.join({
    pandoc.system.get_working_directory(), input
  }))
  return pandoc.path.join({base, image})
end

-- Arm the global flag just before a \begin{frame}.
-- Even if this raw block lands inside the previous frame's body (e.g. inside
-- a block environment), \gdef/\global assignments are unconditionally global
-- in TeX and will be visible when the hook fires for the next \begin{frame}.
local function set_pending_latex(image, size, opacity)
  size = size or "cover"
  local lines = {
    string.format("\\gdef\\bgpendingimage{%s}", image),
    string.format("\\gdef\\bgpendingsize{%s}",  size),
  }
  if is_opaque(opacity) then
    table.insert(lines, "\\global\\bgopaquetrue")
  else
    table.insert(lines, string.format("\\gdef\\bgpendingopc{%s}", opacity))
    table.insert(lines, "\\global\\bgopaquefalse")
  end
  table.insert(lines, "\\global\\bgpendingtrue")
  return table.concat(lines, "\n")
end

-- Preamble block: declares flags/macros and installs the hook.
--
-- All image backgrounds are rendered as a TikZ \setbeamertemplate{background}
-- overlay so that the beamer background canvas (theme colours) is never
-- touched.  Conditionals are evaluated inside the hook (at outer TeX level,
-- before the frame group opens) so the correct template variant is installed
-- before beamer captures it for the frame.
--
-- \ifbgactive ensures plain frames only issue a \setbeamertemplate{background}{}
-- reset on the single frame that follows a background slide, and are otherwise
-- left untouched.
local PREAMBLE_HOOK = [[
\usepackage{etoolbox}
\usepackage{tikz}
\newif\ifbgpending  % true → next \begin{frame} should receive a background image
\newif\ifbgopaque   % true → opaque (no alpha); false → semi-transparent TikZ node
\newif\ifbgactive   % true → a background is applied; reset on next plain frame
\global\bgpendingfalse
\global\bgopaquetrue
\global\bgactivefalse
\gdef\bgpendingimage{}
\gdef\bgpendingsize{cover}
\gdef\bgpendingopc{1}
% Hook fires at the true outer TeX level, before \begin{frame} opens any group.
\BeforeBeginEnvironment{frame}{%
  \ifbgpending
    \def\tmpbgsize{\bgpendingsize}%
    \def\tmpcontain{contain}%
    \ifbgopaque
      \ifx\tmpbgsize\tmpcontain
        \setbeamertemplate{background}{%
          \begin{tikzpicture}[remember picture,overlay]
            \node at (current page.center)
              {\includegraphics[width=\paperwidth,height=\paperheight,
                                keepaspectratio]{\bgpendingimage}};
          \end{tikzpicture}}%
      \else
        \setbeamertemplate{background}{%
          \begin{tikzpicture}[remember picture,overlay]
            \node at (current page.center)
              {\includegraphics[width=\paperwidth,height=\paperheight]%
                {\bgpendingimage}};
          \end{tikzpicture}}%
      \fi
    \else
      \ifx\tmpbgsize\tmpcontain
        \setbeamertemplate{background}{%
          \begin{tikzpicture}[remember picture,overlay]
            \node[opacity=\bgpendingopc] at (current page.center)
              {\includegraphics[width=\paperwidth,height=\paperheight,
                                keepaspectratio]{\bgpendingimage}};
          \end{tikzpicture}}%
      \else
        \setbeamertemplate{background}{%
          \begin{tikzpicture}[remember picture,overlay]
            \node[opacity=\bgpendingopc] at (current page.center)
              {\includegraphics[width=\paperwidth,height=\paperheight]%
                {\bgpendingimage}};
          \end{tikzpicture}}%
      \fi
    \fi
    \global\bgpendingfalse
    \global\bgopaquetrue
    \global\bgactivetrue
  \else
    \ifbgactive
      % Transitioning from a background slide to a plain slide: clear only the
      % overlay layer so the theme's background canvas colour is preserved.
      \setbeamertemplate{background}{}%
      \global\bgactivefalse
    \fi
  \fi
}]]

-- Generate title-slide background LaTeX using \AddToHookNext{shipout/background}.
-- This one-shot hook fires exactly once for the first page shipped (the title page)
-- and then removes itself automatically — no bleed onto section separators or content.
-- \AtBeginDocument wrapping ensures tikz is loaded before the hook body executes.
local function make_title_bg_latex(image, size, opacity)
  size = size or "cover"

  local include_opts
  if size == "contain" then
    include_opts = "width=\\paperwidth,height=\\paperheight,keepaspectratio"
  else
    include_opts = "width=\\paperwidth,height=\\paperheight"
  end

  local node_opts = ""
  if not is_opaque(opacity) then
    node_opts = string.format("[opacity=%s]", opacity)
  end

  return string.format([[
\AtBeginDocument{%%
  \AddToHookNext{shipout/background}{%%
    \begin{tikzpicture}[remember picture,overlay]
      \node%s at (current page.center)
        {\includegraphics[%s]{%s}};
    \end{tikzpicture}%%
  }%%
}]], node_opts, include_opts, image)
end

-- Prepend an item to a MetaList (or create one from a single value).
local function prepend_header_include(meta, raw_latex)
  local item = pandoc.MetaBlocks({ pandoc.RawBlock("latex", raw_latex) })
  local hi = meta["header-includes"]
  if hi == nil then
    meta["header-includes"] = pandoc.MetaList({ item })
  elseif hi.t == "MetaList" then
    table.insert(hi, 1, item)
  else
    meta["header-includes"] = pandoc.MetaList({ item, hi })
  end
end

function Pandoc(doc)
  if FORMAT ~= "beamer" then return nil end

  local new_blocks     = {}
  local has_content_bg = false

  -- Inject flag-setter raw blocks before each background-image heading.
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and (block.level == 1 or block.level == 2) then
      local bg      = block.attr.attributes["background-image"]
      local size    = block.attr.attributes["background-size"]
      local opacity = block.attr.attributes["background-opacity"]

      if bg then
        has_content_bg = true

        table.insert(new_blocks, pandoc.RawBlock("latex",
          set_pending_latex(resolve_image_path(bg), size, opacity)))

        -- Strip attrs so Beamer doesn't trip on unknown keys.
        block.attr.attributes["background-image"]   = nil
        block.attr.attributes["background-size"]    = nil
        block.attr.attributes["background-opacity"] = nil
      end
    end

    table.insert(new_blocks, block)
  end

  -- Install preamble hook only when at least one content slide needs it.
  if has_content_bg then
    prepend_header_include(doc.meta, PREAMBLE_HOOK)
  end

  -- Handle title-slide background from frontmatter title-slide-attributes.
  -- \frame{\titlepage} does not trigger \BeforeBeginEnvironment{frame}, so we
  -- use \AddToHookNext{shipout/background} — a one-shot hook that fires for
  -- exactly one page (the title) then removes itself.
  local title_attrs = doc.meta["title-slide-attributes"]
  if title_attrs then
    local title_bg      = nil
    local title_size    = "cover"
    local title_opacity = nil

    for k, v in pairs(title_attrs) do
      local val = pandoc.utils.stringify(v)
      if k == "data-background-image" then
        title_bg = val
      elseif k == "data-background-size" then
        title_size = val
      elseif k == "data-background-opacity" then
        title_opacity = val
      end
    end

    if title_bg then
      title_bg = resolve_image_path(title_bg)
      -- Ensure tikz is available when PREAMBLE_HOOK is not injected.
      if not has_content_bg then
        prepend_header_include(doc.meta, "\\usepackage{tikz}")
      end
      prepend_header_include(doc.meta, make_title_bg_latex(title_bg, title_size, title_opacity))
    end
  end

  return pandoc.Pandoc(new_blocks, doc.meta)
end
