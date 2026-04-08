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

local function is_opaque(opacity)
  return opacity == nil or opacity == "" or opacity == "1" or opacity == "1.0"
end

-- Build the LaTeX command that sets the background for one frame.
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
    -- Opacity requires TikZ overlay
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

-- Build the LaTeX command that clears the background after a frame.
local function reset_background_latex(used_tikz)
  if used_tikz then
    return "\\setbeamertemplate{background}{}"
  else
    return "\\usebackgroundtemplate{}"
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

function Pandoc(doc)
  if FORMAT ~= "beamer" then return nil end

  local new_blocks = {}
  local in_bg      = false   -- currently inside a slide with a custom background
  local bg_tikz    = false   -- that background uses TikZ (opacity)
  local needs_tikz = false   -- any opacity was requested anywhere in the doc

  for _, block in ipairs(doc.blocks) do
    -- A new section (level 1) or slide (level 2) ends any active background.
    if block.t == "Header" and (block.level == 1 or block.level == 2) then
      if in_bg then
        table.insert(new_blocks, pandoc.RawBlock("latex", reset_background_latex(bg_tikz)))
        in_bg   = false
        bg_tikz = false
      end

      -- Check whether this header carries a background-image attribute.
      local bg      = block.attr.attributes["background-image"]
      local size    = block.attr.attributes["background-size"]
      local opacity = block.attr.attributes["background-opacity"]

      if bg then
        local use_tikz = not is_opaque(opacity)
        if use_tikz then needs_tikz = true end
        table.insert(new_blocks, pandoc.RawBlock("latex",
          set_background_latex(bg, size, opacity)))
        in_bg   = true
        bg_tikz = use_tikz

        -- Strip background attrs so Beamer doesn't trip on unknown keys.
        block.attr.attributes["background-image"]   = nil
        block.attr.attributes["background-size"]    = nil
        block.attr.attributes["background-opacity"] = nil
      end
    end

    table.insert(new_blocks, block)
  end

  -- Close any background that was still open at the end of the document.
  if in_bg then
    table.insert(new_blocks, pandoc.RawBlock("latex", reset_background_latex(bg_tikz)))
  end

  -- -------------------------------------------------------------------------
  -- Title slide: honour data-background-image from title-slide-attributes.
  -- -------------------------------------------------------------------------
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

      -- Set the background before the title frame, then reset it inside the
      -- title page template (runs after \titlepage, before \end{frame}).
      local latex = set_background_latex(bg, size, opacity) .. "\n" ..
        "\\addtobeamertemplate{title page}{}{" ..
        reset_background_latex(use_tikz) .. "}"

      prepend_header_include(meta, latex)
    end
  end

  -- -------------------------------------------------------------------------
  -- Load TikZ if any opacity was requested.
  -- -------------------------------------------------------------------------
  if needs_tikz then
    prepend_header_include(meta, "\\usepackage{tikz}")
  end

  return pandoc.Pandoc(new_blocks, meta)
end
