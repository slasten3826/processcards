-- Glyph placement: coordinates for minor and trump cards.
-- See: docs/manifest/glyphs/GLYPH_PLACEMENT_LAW.md §1

local layout = {}

-- Minor cards: diagonal operator composition.
-- op_a in upper-left corner, op_b in lower-right corner.
function layout.minor_pos(rect)
    return {
        ax = rect.x + rect.w * 0.30,
        ay = rect.y + rect.h * 0.30,
        bx = rect.x + rect.w * 0.70,
        by = rect.y + rect.h * 0.70,
    }
end

-- Trump cards: vertical event seam.
-- op_a left side, op_b right side, centered vertically.
function layout.trump_pos(rect)
    return {
        ax = rect.x + rect.w * 0.25,
        ay = rect.y + rect.h * 0.44,
        bx = rect.x + rect.w * 0.75,
        by = rect.y + rect.h * 0.44,
    }
end

return layout
