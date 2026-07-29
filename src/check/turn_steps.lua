-- TURN_STEP_LAW §8: trumps never interrupt.
--
-- The mechanism lives in src/sim/step_invariant.lua. What this module adds is
-- the citation: without it the run produces a verdict nobody can attribute to
-- a law, and coverage cannot count it.

local registry = require("src.check.init")
local invariant = require("src.sim.step_invariant")

local M = {}

M.cites = {"TURN_STEP_LAW §8"}

function M.run(opts)
    opts = opts or {}
    local report = invariant.run(opts.seeds or 20, opts.steps or 300)

    if report.turns == 0 then
        return {results = {registry.skip(
            "TURN_STEP_LAW §8",
            "no closed turn observed, nothing to answer for")}}
    end

    local detail = string.format(
        "%d turns, %d queue entries before SPEND (legal), %d resolutions after",
        report.turns, report.entries_before_spend, report.resolutions_after_spend)

    if report.violations > 0 then
        detail = string.format("%d violations: %s",
            report.violations, table.concat(report.examples, "; "))
        return {results = {registry.fail("TURN_STEP_LAW §8", detail)}}
    end

    return {results = {registry.ok("TURN_STEP_LAW §8", detail)}}
end

return M
