-- MACHINE_CLI_SLICE_2026-07-28 §12, which manifests MACHINE_CLI_LAW.
--
-- Nine slice checks, mechanism in src/sim/session_check.lua.
--
-- Two of them build a position with plant (the refill and the empty-deck
-- warning), so those report reached = "planted" and the rest do not. The
-- split is by check rather than by module, which is the point: a module-wide
-- flag would mark the honest ones as unpaid too.

local registry = require("src.check.init")
local session_check = require("src.sim.session_check")

local M = {}

M.cites = {"MACHINE_CLI_SLICE_2026-07-28 §12"}

local CITE = "MACHINE_CLI_SLICE_2026-07-28 §12"

-- Checks that construct their position instead of playing to it.
local PLANTED = {
    plant_refill = true,
    plant_warns = true,
}

function M.run(opts)
    opts = opts or {}
    local report = session_check.run(opts.seeds or 20, opts.steps or 80)
    local results = {}

    for _, entry in ipairs(report.results) do
        local reached = {reached = PLANTED[entry.name] and "planted" or "played"}
        local detail = entry.detail
            and string.format("%s: %s", entry.name, entry.detail)
            or entry.name

        -- src/sim/session_check reports a declined check as ok with SKIP in
        -- the detail text. That is the third outcome living where nothing can
        -- count it; translate it into a status here.
        local declined = entry.detail and entry.detail:match("^SKIP")

        if declined then
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
