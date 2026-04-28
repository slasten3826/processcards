-- ProcessCards glyph shapes
-- Each function draws one operator glyph centered at (x, y) with size gs.
-- Ink color is passed as parameter -- glyphs do not choose their own color.
-- See: docs/manifest/glyphs/GLYPH_PLACEMENT_LAW.md

local glyphs = {}

--▽ FLOW -- downward equilateral triangle (outline)
glyphs.FLOW = function(x, y, gs)
    local h = gs * 0.60
    love.graphics.polygon("line",
        x, y + h,
        x - h, y - h * 0.55,
        x + h, y - h * 0.55
    )
end

--△ MANIFEST -- upward equilateral triangle (outline)
glyphs.MANIFEST = function(x, y, gs)
    local h = gs * 0.60
    love.graphics.polygon("line",
        x, y - h,
        x - h, y + h * 0.55,
        x + h, y + h * 0.55
    )
end

-- Trigrams: each is 3 horizontal strokes (solid or broken), read bottom-to-top.
-- Bottom = first line, middle = second, top = third.
-- See: docs/manifest/glyphs/TRIGRAMS.md

local function draw_trigram(x, y, gs, pattern, mode)
    mode = mode or "fill"
    local w = math.floor(gs * 1.2 + 0.5)
    local thick = math.max(1, math.floor(gs * 0.15 + 0.5))
    local vgap = math.max(1, math.floor(gs * 0.35 + 0.5))
    local half = math.floor(w * 0.5)
    local seg = math.floor(gs * 0.5 + 0.5)
    local base_y = math.floor(y + vgap + 0.5)

    for i = 1, 3 do
        local cy = math.floor(base_y - (i - 1) * (thick + vgap) + 0.5)
        if mode == "line" then
            if pattern[i] == "solid" then
                local sx = math.floor(x - half + 0.5)
                local ex = math.floor(x + half + 0.5)
                love.graphics.line(sx, cy, ex, cy)
            else
                local lx1 = math.floor(x - half + 0.5)
                local lx2 = math.floor(x - half + seg + 0.5)
                local rx1 = math.floor(x + half - seg + 0.5)
                local rx2 = math.floor(x + half + 0.5)
                love.graphics.line(lx1, cy, lx2, cy)
                love.graphics.line(rx1, cy, rx2, cy)
            end
        else
            if pattern[i] == "solid" then
                love.graphics.rectangle(mode, x - half, math.floor(cy - thick * 0.5 + 0.5), w, thick)
            else
                local lx = math.floor(x - half + 0.5)
                local rx = math.floor(x + half - seg + 0.5)
                local ty = math.floor(cy - thick * 0.5 + 0.5)
                love.graphics.rectangle(mode, lx, ty, seg, thick)
                love.graphics.rectangle(mode, rx, ty, seg, thick)
            end
        end
    end
end

--☰ CONNECT -- solid, solid, solid
glyphs.CONNECT = function(x, y, gs)
    draw_trigram(x, y, gs, {"solid", "solid", "solid"})
end

--☷ DISSOLVE -- broken, broken, broken
glyphs.DISSOLVE = function(x, y, gs)
    draw_trigram(x, y, gs, {"broken", "broken", "broken"})
end

--☵ ENCODE -- broken, solid, broken
glyphs.ENCODE = function(x, y, gs)
    draw_trigram(x, y, gs, {"broken", "solid", "broken"})
end

--☳ CHOOSE -- solid, broken, broken
glyphs.CHOOSE = function(x, y, gs)
    draw_trigram(x, y, gs, {"solid", "broken", "broken"})
end

--☴ OBSERVE -- broken, solid, solid
glyphs.OBSERVE = function(x, y, gs)
    draw_trigram(x, y, gs, {"broken", "solid", "solid"})
end

--☲ CYCLE -- solid, broken, solid
glyphs.CYCLE = function(x, y, gs)
    draw_trigram(x, y, gs, {"solid", "broken", "solid"})
end

--☶ LOGIC -- broken, broken, solid
glyphs.LOGIC = function(x, y, gs)
    draw_trigram(x, y, gs, {"broken", "broken", "solid"})
end

--☱ RUNTIME -- solid, solid, broken (line mode: outline, not fill)
glyphs.RUNTIME = function(x, y, gs)
    draw_trigram(x, y, gs, {"solid", "solid", "broken"}, "line")
end

return glyphs
