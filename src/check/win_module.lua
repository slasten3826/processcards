-- WIN_MODULE_SLICE_2026-07-29 §11 and STEP_CHECK_SLICE_2026-07-29 §6.
--
-- Mechanism in src/sim/win_slice.lua. Every position is built by hand, so all
-- results report reached = "planted": six specific manifest slots are not
-- something random play arrives at.
--
-- Check 11 of the win slice is separate below: it reads the module source
-- rather than running it, which is the only way to see a mutator that exists
-- but has not been executed yet.

local registry = require("src.check.init")
local slice = require("src.sim.win_slice")

local M = {}

M.cites = {
    "WIN_MODULE_SLICE_2026-07-29 §11",
    "STEP_CHECK_SLICE_2026-07-29 §6",
}

local WIN = "WIN_MODULE_SLICE_2026-07-29 §11"
local STEP = "STEP_CHECK_SLICE_2026-07-29 §6"

-- WIN_MODULE_SLICE §11.3. The read-only guarantee is a grep, not a promise.
local FORBIDDEN = {
    "state_lib%.place_card",
    "state_lib%.remove_from_current_zone",
    "state_lib%.set_info_state",
    "state_lib%.hide_card",
    "state_lib%.know_card",
    "state_lib%.reveal_card",
    'require%("src%.core%.draw"%)',
    'require%("src%.core%.repair"%)',
    'require%("src%.core%.turn"%)',
    'require%("src%.core%.trump"%)',
}

local function read_only_check()
    local file = io.open("src/core/win.lua", "r")
    if not file then
        return registry.skip(WIN, "src/core/win.lua not readable")
    end
    local source = file:read("a")
    file:close()

    local found = {}
    for _, pattern in ipairs(FORBIDDEN) do
        if source:find(pattern) then
            found[#found + 1] = (pattern:gsub("%%", ""))
        end
    end
    if #found > 0 then
        return registry.fail(WIN,
            "module reaches for a mutator: " .. table.concat(found, ", "))
    end
    return registry.ok(WIN,
        string.format("check 11: none of %d forbidden calls present", #FORBIDDEN))
end

function M.run()
    local report = slice.run()
    local results = {}

    for _, entry in ipairs(report.results) do
        local cites = entry.name:match("^step ") and STEP or WIN
        local detail = entry.detail
            and string.format("%s: %s", entry.name, entry.detail)
            or entry.name
        if entry.detail and tostring(entry.detail):match("^SKIP") then
            results[#results + 1] = registry.skip(cites, detail, {reached = "planted"})
        elseif entry.ok then
            results[#results + 1] = registry.ok(cites, detail, {reached = "planted"})
        else
            results[#results + 1] = registry.fail(cites, detail, {reached = "planted"})
        end
    end

    results[#results + 1] = read_only_check()

    return {results = results}
end

return M
