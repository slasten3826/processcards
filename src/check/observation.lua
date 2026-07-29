-- PLAYER_OBSERVATION_LAW §3, §5, §8.
--
-- Mechanism in src/sim/observation_audit.lua. Three separate results rather
-- than one, because the law says three separate things and a single verdict
-- would hide which of them broke.
--
-- §8 is the control and it is the one that matters most: the full surface is
-- REQUIRED to leak. A control that stops failing means the audit went blind,
-- and a blind audit reports OK forever.

local registry = require("src.check.init")
local audit = require("src.sim.observation_audit")

local M = {}

M.cites = {
    "PLAYER_OBSERVATION_LAW §3",
    "PLAYER_OBSERVATION_LAW §5",
    "PLAYER_OBSERVATION_LAW §8",
}

function M.run(opts)
    opts = opts or {}
    local report = audit.run(opts.seeds or 12, opts.steps or 80)
    local results = {}

    if report.observations_checked == 0 then
        return {results = {registry.skip(
            "PLAYER_OBSERVATION_LAW §3", "no observation produced")}}
    end

    local leaks = report.id_leaks + report.operator_leaks
    if leaks > 0 then
        results[#results + 1] = registry.fail("PLAYER_OBSERVATION_LAW §3",
            string.format("%d identity leaks in %d observations: %s",
                leaks, report.observations_checked,
                table.concat(report.examples, "; ")))
    else
        results[#results + 1] = registry.ok("PLAYER_OBSERVATION_LAW §3",
            string.format("%d observations, no identity of a hidden card exposed",
                report.observations_checked))
    end

    if report.handle_resolution_failures > 0 then
        results[#results + 1] = registry.fail("PLAYER_OBSERVATION_LAW §5",
            string.format("%d handles did not resolve to their position",
                report.handle_resolution_failures))
    else
        results[#results + 1] = registry.ok("PLAYER_OBSERVATION_LAW §5",
            "every handle resolved to the card standing at its position")
    end

    if report.control_snapshot_checked == 0 then
        results[#results + 1] = registry.skip("PLAYER_OBSERVATION_LAW §8",
            "control did not run")
    elseif report.control_snapshot_leaks == 0 then
        results[#results + 1] = registry.fail("PLAYER_OBSERVATION_LAW §8",
            string.format("control did not leak in %d snapshots; the audit is blind",
                report.control_snapshot_checked))
    else
        results[#results + 1] = registry.ok("PLAYER_OBSERVATION_LAW §8",
            string.format("control leaked %d of %d snapshots, as the full surface must",
                report.control_snapshot_leaks, report.control_snapshot_checked))
    end

    return {results = results}
end

return M
