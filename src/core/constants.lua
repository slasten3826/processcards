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
    [3] = "ORACLE",
    [8] = "RUSH",
    [2] = "EJECT",
    [14] = "SHUFFLE",
    [15] = "ERROR",
    [16] = "RECAST",
    [17] = "RESET",
    [19] = "PURGE",
    [20] = "REPEAT",
    [21] = "UNVEIL",
    [22] = "HALT",
}

M.TRUMP_NAME_TO_INDEX = {}
for index, name in pairs(M.TRUMP_NAMES) do
    M.TRUMP_NAME_TO_INDEX[name] = index
end

return M
