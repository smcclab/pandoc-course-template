-- beamer-background.lua
--
-- Adds per-slide, section-page and title-slide background image support for
-- Beamer PDF output. It reads the same attributes reveal.js already uses, so a
-- deck gets the same backgrounds in both output formats with no change to the
-- Markdown source.
--
-- Supported attributes on `#` and `##` headings:
--   background-image="img/foo.jpg"        (required; data-background-image also accepted)
--   background-size="cover"               (optional; "cover" or "contain", default: cover)
--   background-opacity="0.4"              (optional; 0.0–1.0, default: 1.0)
--
-- Title slide background comes from the frontmatter:
--   title-slide-attributes:
--     data-background-image: img/foo.jpg
--     data-background-size: cover         (optional)
--     data-background-opacity: "0.4"      (optional)
--
-- Example:
--   ## My Slide {background-image="img/hero.jpg" background-size="cover"}
--
-- ── Strategy ─────────────────────────────────────────────────────────────────
-- Beamer paints \setbeamertemplate{background} beneath everything else on the
-- page, so that is the layer we use. The theme's own `background canvas` is
-- never touched, which leaves the metropolis/owl colours intact.
--
-- The template is installed exactly once, in the preamble, as an indirection
-- through a single macro:
--
--     \setbeamertemplate{background}{\bgcurrent}
--
-- \bgcurrent is expanded at *shipout*, not where it is set, and a beamer frame
-- ships out at its \end{frame} — after its entire body has been read. So a
-- frame renders whatever \bgcurrent holds at the end of its body:
--
--   * \BeforeBeginEnvironment{frame} clears \bgcurrent, so every frame starts
--     out with no background image.
--   * A frame that wants one carries \gdef\bgcurrent{...} as the first block of
--     its own body. Nothing later can overwrite that before the frame ships,
--     and the assignment is global so the frame group cannot swallow it.
--
-- Setting \bgcurrent from *inside* the body, rather than arming a flag before
-- the frame, is what makes this reliable. Pandoc — not this filter — decides
-- where frames begin and end, and a raw block emitted before a heading does not
-- land where you would hope: it is absorbed into the *previous* frame's body,
-- or, at the very start of the document, becomes a frame of its own and shows
-- up in the PDF as a blank slide.
--
-- \frame{\titlepage} and \frame{\sectionpage} are the command form of the
-- environment, so they never trip \BeforeBeginEnvironment{frame}, and neither
-- has a body this filter can write into. They are handled separately:
--   * the title background is set in \AtBeginDocument and survives until the
--     first real \begin{frame} clears it;
--   * section backgrounds are stored in the preamble under the section number
--     and picked up by a patched \beamer@atbeginsection, which keeps them out
--     of the block stream entirely.

local function is_opaque(opacity)
  return opacity == nil or opacity == "" or opacity == "1" or opacity == "1.0"
end

-- Resolve an image path to absolute so lualatex can find it regardless of the
-- temp directory it runs from. Relative paths are resolved against the
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

-- Preamble: the fitting macros, the one-time template install, and the hooks
-- that clear or supply \bgcurrent for each kind of frame.
--
-- \bgcoverimage reproduces CSS/reveal.js `cover`: scale the image so it fills
-- the slide with no gap and let the excess run off the edge (the surrounding
-- \clip discards it). Scaling to \paperwidth and measuring the result answers
-- "which dimension is the constraining one?" without any ratio arithmetic, and
-- the measured box is reused when width turns out to be the answer.
local PREAMBLE = [[
\usepackage{etoolbox}
\usepackage{tikz}
\newsavebox\bgmeasurebox
\newcommand\bgcoverimage[1]{%
  \sbox\bgmeasurebox{\includegraphics[width=\paperwidth]{#1}}%
  \ifdim\ht\bgmeasurebox<\paperheight
    \includegraphics[height=\paperheight]{#1}%
  \else
    \usebox\bgmeasurebox
  \fi}
\newcommand\bgcontainimage[1]{%
  \includegraphics[width=\paperwidth,height=\paperheight,keepaspectratio]{#1}}
% #1 = node options ([opacity=...] or empty), #2 = fit macro, #3 = image path
\newcommand\bgoverlay[3]{%
  \begin{tikzpicture}[remember picture,overlay]
    \clip (current page.south west) rectangle (current page.north east);
    \node#1 at (current page.center) {#2{#3}};
  \end{tikzpicture}}
\gdef\bgcurrent{}
\setbeamertemplate{background}{\bgcurrent}
% Every frame starts clean; a frame with a background re-arms \bgcurrent itself.
\BeforeBeginEnvironment{frame}{\gdef\bgcurrent{}}
% Section pages are reached through \frame{\sectionpage}, which the environment
% hook above never sees. \beamer@atbeginsection runs after \c@section has been
% stepped, so the section number selects the right stored background; sections
% without one resolve to \relax and render nothing. Both hook variants are
% patched because beamer picks between them on whether the section title is
% blank.
\makeatletter
\preto\beamer@atbeginsection{%
  \gdef\bgcurrent{\csname bgsection@\the\c@section\endcsname}}
\preto\beamer@atbeginsections{%
  \gdef\bgcurrent{\csname bgsection@\the\c@section\endcsname}}
\makeatother]]

-- The TikZ overlay for one background, with the image path baked in literally.
-- Nothing here is read from a mutable macro, so one slide's background can
-- never be confused with another's.
local function overlay_latex(image, size, opacity)
  local node_opts = ""
  if not is_opaque(opacity) then
    node_opts = string.format("[opacity=%s]", opacity)
  end
  local fit = (size == "contain") and "\\bgcontainimage" or "\\bgcoverimage"
  return string.format("\\bgoverlay{%s}{%s}{%s}", node_opts, fit, image)
end

-- Read background attributes off a heading, accepting the data- prefixed
-- spellings reveal.js also allows.
local function background_of(attr)
  local function get(name)
    return attr.attributes[name] or attr.attributes["data-" .. name]
  end
  local image = get("background-image")
  if not image then return nil end
  return {
    image   = resolve_image_path(image),
    size    = get("background-size"),
    opacity = get("background-opacity"),
  }
end

local function strip_background_attrs(attr)
  for _, name in ipairs({ "background-image", "background-size", "background-opacity" }) do
    attr.attributes[name] = nil
    attr.attributes["data-" .. name] = nil
  end
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

-- Title-slide background: \frame{\titlepage} has no body to write into, so set
-- \bgcurrent at the start of the document and let the first \begin{frame} (or
-- the first section page) clear it.
local function title_bg_latex(bg)
  return string.format("\\AtBeginDocument{\\gdef\\bgcurrent{%s}}",
    overlay_latex(bg.image, bg.size, bg.opacity))
end

-- Section-page background, stored under the section number the heading will get.
local function section_bg_latex(number, bg)
  return string.format("\\expandafter\\gdef\\csname bgsection@%d\\endcsname{%s}",
    number, overlay_latex(bg.image, bg.size, bg.opacity))
end

local function is_unnumbered(attr)
  for _, class in ipairs(attr.classes) do
    if class == "unnumbered" then return true end
  end
  return false
end

function Pandoc(doc)
  if FORMAT ~= "beamer" then return nil end

  local new_blocks    = {}
  local section_bgs   = {}
  local section_count = 0
  local used          = false

  for _, block in ipairs(doc.blocks) do
    if block.t == "Header" and block.level == 1 then
      -- Level 1 becomes \section, whose separator page is generated by beamer
      -- rather than appearing in this block list. Count the sections that
      -- \c@section will count, and file any background under that number.
      local numbered = not is_unnumbered(block.attr)
      if numbered then section_count = section_count + 1 end

      local bg = background_of(block.attr)
      if bg then
        strip_background_attrs(block.attr)
        if numbered then
          used = true
          table.insert(section_bgs, section_bg_latex(section_count, bg))
        else
          -- Unnumbered sections never advance \c@section, so there is no key to
          -- file the background under. Drop it rather than mis-assign it.
          io.stderr:write(string.format(
            "[beamer-background] ignoring background on unnumbered section %q\n",
            pandoc.utils.stringify(block.content)))
        end
      end
      table.insert(new_blocks, block)

    elseif block.t == "Header" and block.level == 2 then
      -- Level 2 becomes a frame. Arm the background as the first block of that
      -- frame's own body, where no other slide can reach it.
      local bg = background_of(block.attr)
      table.insert(new_blocks, block)
      if bg then
        used = true
        strip_background_attrs(block.attr)
        table.insert(new_blocks, pandoc.RawBlock("latex",
          string.format("\\gdef\\bgcurrent{%s}",
            overlay_latex(bg.image, bg.size, bg.opacity))))
      end

    else
      table.insert(new_blocks, block)
    end
  end

  -- Title slide background from the frontmatter.
  local title_latex = nil
  local title_attrs = doc.meta["title-slide-attributes"]
  if title_attrs then
    local image, size, opacity
    for k, v in pairs(title_attrs) do
      local val = pandoc.utils.stringify(v)
      if k == "data-background-image" then
        image = val
      elseif k == "data-background-size" then
        size = val
      elseif k == "data-background-opacity" then
        opacity = val
      end
    end
    if image then
      used = true
      title_latex = title_bg_latex({
        image = resolve_image_path(image), size = size, opacity = opacity,
      })
    end
  end

  if not used then return nil end

  -- Order matters: PREAMBLE defines \bgoverlay and the fit macros, so it is
  -- prepended last to land above everything that calls them.
  if title_latex then prepend_header_include(doc.meta, title_latex) end
  for i = #section_bgs, 1, -1 do
    prepend_header_include(doc.meta, section_bgs[i])
  end
  prepend_header_include(doc.meta, PREAMBLE)

  return pandoc.Pandoc(new_blocks, doc.meta)
end
