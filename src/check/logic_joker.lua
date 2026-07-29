-- LOGIC_JOKER_SLICE_2026-07-27 §9, which manifests LOGIC_JOKER_LAW.
--
-- Fifteen slice checks, mechanism in src/sim/logic_joker_check.lua. They are
-- numbered by the crystall, which is why the citation points there: the code
-- manifests from §9 and from nothing else.
--
-- Every one of them builds its position with plant, so every result reports
-- reached = "planted". DEV_CLI_LAW §7 requires that to be visible: a planted
-- position is valid without being reachable, and the best-covered law in the
-- repository turns out to be verified entirely in positions nobody paid for.

local registry = require("src.check.init")
local joker = require("src.sim.logic_joker_check")

local M = {}

M.cites = {"LOGIC_JOKER_SLICE_2026-07-27 §9"}

local CITE = "LOGIC_JOKER_SLICE_2026-07-27 §9"

function M.run(opts)
    opts = opts or {}
    local report = joker.run(opts.seed or 3)
    local results = {}

    for _, entry in ipairs(report.checks) do
        local detail = string.format("%s: %s", entry.name, entry.detail or "")
        local reached = {reached = "planted"}
        if entry.skipped then
            results[#results + 1] = registry.skip(CITE, detail, reached)
        elseif entry.ok then
            results[#results + 1] = registry.ok(CITE, detail, reached)
        else
            results[#results + 1] = registry.fail(CITE, detail, reached)
        end
    end

    if #results == 0 then
        results[1] = registry.skip(CITE, "no slice check produced a verdict")
    end

    return {results = results}
end

return M
