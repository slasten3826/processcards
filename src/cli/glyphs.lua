local M = {}

M.GLYPHS = {
    FLOW    = "▽",
    CONNECT = "☰",
    DISSOLVE = "☷",
    ENCODE  = "☵",
    CHOOSE  = "☳",
    OBSERVE = "☴",
    LOGIC   = "☶",
    CYCLE   = "☲",
    RUNTIME = "☱",
    MANIFEST = "△",
}

M.NAMES = {
    FLOW    = "FLW",
    CONNECT = "CON",
    DISSOLVE = "DIS",
    ENCODE  = "ENC",
    CHOOSE  = "CHO",
    OBSERVE = "OBS",
    LOGIC   = "LOG",
    CYCLE   = "CYC",
    RUNTIME = "RUN",
    MANIFEST = "MAN",
}

function M.glyph(op)
    return M.GLYPHS[op] or "?"
end

function M.name(op)
    return M.NAMES[op] or "???"
end

function M.pair(a, b)
    return M.glyph(a) .. M.glyph(b)
end

function M.pair_name(a, b)
    return M.name(a) .. "-" .. M.name(b)
end

return M
