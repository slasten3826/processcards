local M = {}

M.OPERATORS = {
    "FLOW",
    "CONNECT",
    "DISSOLVE",
    "ENCODE",
    "CHOOSE",
    "OBSERVE",
    "LOGIC",
    "CYCLE",
    "RUNTIME",
    "MANIFEST",
}

M.TRUMP_CANON = {
    {"FLOW", "CONNECT"},
    {"FLOW", "DISSOLVE"},
    {"FLOW", "OBSERVE"},
    {"CONNECT", "DISSOLVE"},
    {"CONNECT", "OBSERVE"},
    {"CONNECT", "ENCODE"},
    {"DISSOLVE", "OBSERVE"},
    {"DISSOLVE", "CHOOSE"},
    {"OBSERVE", "ENCODE"},
    {"OBSERVE", "CHOOSE"},
    {"OBSERVE", "RUNTIME"},
    {"ENCODE", "CHOOSE"},
    {"ENCODE", "RUNTIME"},
    {"ENCODE", "CYCLE"},
    {"CHOOSE", "RUNTIME"},
    {"CHOOSE", "LOGIC"},
    {"LOGIC", "CYCLE"},
    {"LOGIC", "RUNTIME"},
    {"LOGIC", "MANIFEST"},
    {"CYCLE", "RUNTIME"},
    {"CYCLE", "MANIFEST"},
    {"RUNTIME", "MANIFEST"},
}

M.TRUMP_NAMES = {
    [1] = "FOOL",
    [2] = "EJECT",
    [14] = "SHUFFLE",
    [16] = "RECAST",
    [17] = "RESET",
    [21] = "UNVEIL",
    [22] = "HALT",
}

return M
