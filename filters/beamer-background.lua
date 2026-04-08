-- beamer-background.lua
--
-- Adds per-slide background image support for Beamer PDF output.
-- Reads the same attributes used by reveal.js, so slides work across
-- both output formats without any changes to the Markdown source.
--
-- Supported attributes on ## headings:
--   background-image="img/foo.jpg"        (required)
--   background-size="cover"               (optional; "cover" or "contain", default: cover)
--   background-opacity="0.4"              (optional; 0.0–1.0, default: 1.0)
--
-- Example:
--   ## My Slide {background-image="img/hero.jpg" background-size="cover"}
--
-- Title slide (frontmatter):
--   title-slide-attributes:
--     data-background-image: img/hero.jpg
--     data-background-size: cover
--     data-background-opacity: "0.5"      (optional)
--
-- ── Strategy ─────────────────────────────────────────────────────────────────
-- The pandoc beamer template emits the title frame as \frame{\titlepage} and
-- section-title frames as \frame{\sectionpage}.  The \frame{} command does NOT
-- trigger etoolbox's \BeforeBeginEnvironment{frame} hook (which only fires for
-- the environment form \begin{frame}).  Content slides, however, always use
-- \begin{frame}, so the hook fires reliably for them.
--
-- Hybrid approach:
--   • Title slide  – direct \usebackgroundtemplate in the preamble, cleared by
--                    a reset injected as the very first body block (before any
--                    \begin{frame} or \frame{\sectionpage}).
--   • Content slides – a global flag (\ifbgpending) is armed just before the
--                    target \begin{frame}; \BeforeBeginEnvironment{frame} reads
--                    the flag and either applies or resets the background at
--                    the true outer TeX level, avoiding all \aftergroup /
--                    \egroup layering problems.

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

-- ── Title-slide helpers (direct template, same as original approach) ──────────

local function set_background_latex(image, size, opacity)
  size = size or "cover"
  local img_opts
  if size == "contain" then
    img_opts = "width=\\paperwidth,height=\\paperheight,keepaspectratio"
  else
    img_opts = "width=\\paperwidth,height=\\paperheight"
  end

  if is_opaque(opacity) then
    return string.format(
      "\\usebackgroundtemplate{\\includegraphics[%s]{%s}}",
      img_opts, image
    )
  else
    return string.format(
      "\\setbeamertemplate{background}{%%\n" ..
      "  \\begin{tikzpicture}[remember picture,overlay]\n" ..
      "    \\node[opacity=%s] at (current page.center)\n" ..
      "      {\\includegraphics[%s]{%s}};\n" ..
      "  \\end{tikzpicture}%%\n" ..
      "}",
      opacity, img_opts, image
    )
  end
end

-- Schedule a one-shot background reset that fires AFTER the title page ships
-- out (using LaTeX 2020's \AddToHookNext).  This avoids inserting a raw block
-- in the document body, which pandoc would wrap in an extra blank \begin{frame}
-- and produce a spurious blank page between the title and the first section.
local function title_reset_latex()
  return table.concat({
    "% Reset background after the title page ships (one-shot hook).",
    "\\AddToHookNext{shipout/after}{%",
    "  \\usebackgroundtemplate{}%",
    "  \\setbeamertemplate{background}{}%",
    "}",
  }, "\n")
end

-- ── Content-slide helpers (flag + BeforeBeginEnvironment hook) ────────────────

-- Arm the global flag just before a \begin{frame}.
-- \BeforeBeginEnvironment{frame} will read these globals and apply or clear
-- the background at the outer TeX level (before any frame group is opened),
-- then clear the flag so all subsequent frames revert automatically.
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

-- Preamble block: defines the \BeforeBeginEnvironment{frame} hook and the
-- global variables it uses.  Installed only when at least one content slide
-- requests a background.
local PREAMBLE_HOOK = [[
\usepackage{etoolbox}
\newif\ifbgpending
\newif\ifbgopaque
\global\bgpendingfalse
\global\bgopaquetrue
\gdef\bgpendingimage{}
\gdef\bgpendingsize{cover}
\gdef\bgpendingopc{1}
% This hook fires at the true outer TeX level, before \begin{frame} opens
% any group, so assignments here are safe and global without \global.
\BeforeBeginEnvironment{frame}{%
  \ifbgpending
    \def\tmpbgsize{\bgpendingsize}%
    \def\tmpcontain{contain}%
    \ifbgopaque
      \ifx\tmpbgsize\tmpcontain
        \usebackgroundtemplate{%
          \includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]%
            {\bgpendingimage}}%
      \else
        \usebackgroundtemplate{%
          \includegraphics[width=\paperwidth,height=\paperheight]%
            {\bgpendingimage}}%
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
  \else
    % No background pending: reset both template slots so that a background
    % from a previous slide does not bleed into this one.
    \usebackgroundtemplate{}%
    \setbeamertemplate{background}{}%
  \fi
}]]

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
  local has_content_bg = false   -- any ## slide requests a background
  local needs_tikz     = false   -- any opacity was used anywhere

  -- ── Content slides: inject flag-setter before each background heading ───────
  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and (block.level == 1 or block.level == 2) then
      local bg      = block.attr.attributes["background-image"]
      local size    = block.attr.attributes["background-size"]
      local opacity = block.attr.attributes["background-opacity"]

      if bg then
        has_content_bg = true
        if not is_opaque(opacity) then needs_tikz = true end

        -- Arm the flag just before the heading; even if this raw block ends
        -- up inside the previous frame (inside a block environment), the
        -- \gdef / \global assignments are unconditionally global in TeX and
        -- will be visible when \BeforeBeginEnvironment{frame} fires for the
        -- *next* \begin{frame}.
        table.insert(new_blocks, pandoc.RawBlock("latex",
          set_pending_latex(resolve_image_path(bg), size, opacity)))

        -- Strip background attrs so Beamer doesn't trip on unknown keys.
        block.attr.attributes["background-image"]   = nil
        block.attr.attributes["background-size"]    = nil
        block.attr.attributes["background-opacity"] = nil
      end
    end

    table.insert(new_blocks, block)
  end

  -- ── Title slide: direct template in preamble + post-shipout reset ───────────
  -- \frame{\titlepage} does NOT trigger \BeforeBeginEnvironment{frame}, so the
  -- flag mechanism cannot be used.  Instead the template is set directly in the
  -- preamble and a \AddToHookNext{shipout/after} one-shot hook resets it after
  -- the title page ships.  (Inserting a raw reset block in the document body
  -- would cause pandoc to wrap it in a spurious blank \begin{frame}.)
  -- NOTE: section-separator pages also use \frame{\sectionpage} and are equally
  -- invisible to the hook; the shipout reset targets them too.
  local meta = doc.meta
  local tsa  = meta["title-slide-attributes"]
  if tsa then
    local bg      = tsa["data-background-image"]
    local size    = tsa["data-background-size"]
    local opacity = tsa["data-background-opacity"]

    if bg then
      bg      = pandoc.utils.stringify(bg)
      size    = size    and pandoc.utils.stringify(size)    or "cover"
      opacity = opacity and pandoc.utils.stringify(opacity) or nil

      local use_tikz = not is_opaque(opacity)
      if use_tikz then needs_tikz = true end

      prepend_header_include(meta,
        set_background_latex(resolve_image_path(bg), size, opacity))

      -- Schedule a one-shot reset that fires after the title page ships out.
      -- Inserting a raw LaTeX reset as the first body block would cause pandoc
      -- to wrap it in an extra \begin{frame}, creating a spurious blank page.
      prepend_header_include(meta, title_reset_latex())
    end
  end

  -- ── Preamble: install hook infrastructure (content slides only) ─────────────
  if has_content_bg then
    if needs_tikz then
      prepend_header_include(meta, "\\usepackage{tikz}")
    end
    -- PREAMBLE_HOOK goes first (outermost prepend applied last).
    prepend_header_include(meta, PREAMBLE_HOOK)
  end

  return pandoc.Pandoc(new_blocks, meta)
end
