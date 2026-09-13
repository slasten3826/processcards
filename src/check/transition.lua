-- TRANSITION_SLICE_2026-08-02 §9, which manifests TRANSITION_LAW.
--
-- Thirteen checks over the layer every other module reports through. The
-- source law is an inventory of working code, so these do not describe an
-- intention: they pin behaviour that already exists, before the modules of
-- the new architecture start moving on top of it.
--
-- Positions are built by hand — a transition is opened directly rather than
-- reached through a turn — so every behavioural result reports
-- reached = "planted". Check 13 reads the file instead of running it, which
-- is the only way to see a dependency that exists but has not been used yet.

local registry = require("src.check.init")
local state_lib = require("src.core.state")
local transition = require("src.core.transition")

local M = {}

M.cites = {"TRANSITION_SLICE_2026-08-02 §9"}

local CITE = "TRANSITION_SLICE_2026-08-02 §9"
local PLANTED = {reached = "planted"}

local function verdict(results, ok, detail)
    if ok then
        results[#results + 1] = registry.ok(CITE, detail, PLANTED)
    else
        results[#results + 1] = registry.fail(CITE, detail, PLANTED)
    end
end

local function fresh()
    return state_lib.new_game()
end

local function stream_has(state, event_type)
    for _, event in ipairs(state.event_stream) do
        if event.type == event_type then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------

-- 1. Identity of an action. outcome.seq points at it (WIN_MODULE_LAW §3),
-- so a counter that repeats a number makes a recorded outcome unlocatable.
local function check_seq(results)
    local state = fresh()
    local first = transition.begin(state, "test", {}).seq
    transition.finish(state, {})
    local second = transition.begin(state, "test", {}).seq
    transition.finish(state, {})
    verdict(results, second == first + 1,
        string.format("1 seq monotonic: %d then %d", first, second))
end

-- 2, 3. Two places for an event, and the legality of emitting outside a
-- transaction. The third is a CONTROL: without it "an event is always inside
-- a transaction" would pass unnoticed and setup would start failing.
local function check_two_places(results)
    local state = fresh()
    local tr = transition.begin(state, "test", {})
    transition.emit(state, "probe_inside", {})
    local in_stream = stream_has(state, "probe_inside")
    local in_transition = #tr.events == 1 and tr.events[1].type == "probe_inside"
    verdict(results, in_stream and in_transition,
        string.format("2 event in both places: stream=%s transition=%s",
            tostring(in_stream), tostring(in_transition)))
    transition.finish(state, {})
end

local function check_emit_outside(results)
    local state = fresh()
    transition.emit(state, "probe_outside", {})
    verdict(results, stream_has(state, "probe_outside") and state.current_transition == nil,
        "3 CONTROL emit outside a transaction reaches the stream")
end

-- 4. Ownership of the stream. A layer that keeps a copy grows without bound
-- and is only noticed an hour into a session.
local function check_drain(results)
    local state = fresh()
    transition.emit(state, "probe_drain", {})
    local first = transition.drain_events(state)
    local second = transition.drain_events(state)
    verdict(results, #first == 1 and #second == 0,
        string.format("4 drain empties: %d then %d", #first, #second))
end

-- 5, 6, 7. A ceiling that accounts for what it dropped is not a leak.
-- The sixth is the likeliest mistake in a rewrite: reporting the last
-- omitted type instead of the first.
local function check_ceiling(results)
    local state = fresh()
    state.max_transition_events_per_action = 2
    transition.begin(state, "test", {})
    transition.emit(state, "kept_one", {})
    transition.emit(state, "kept_two", {})
    transition.emit(state, "dropped_first", {})
    transition.emit(state, "dropped_second", {})

    local overflow = state.transition_event_overflow
    verdict(results,
        overflow ~= nil
            and overflow.omitted == 2
            and not stream_has(state, "dropped_first"),
        string.format("5 over the ceiling is dropped and counted: omitted=%s",
            overflow and tostring(overflow.omitted) or "nil"))

    verdict(results,
        overflow ~= nil and overflow.first_omitted_type == "dropped_first",
        string.format("6 first omitted type remembered: %s",
            overflow and tostring(overflow.first_omitted_type) or "nil"))

    local summary = transition.finish(state, {}).summary
    verdict(results, summary.error == "transition_event_limit",
        string.format("7 action carries the limit error: %s", tostring(summary.error)))
end

-- 8, 9. Reset belongs to the action, not to the match. The ninth is the
-- written form of "a cycle may not outlive one player action" and has to
-- survive the trump machine rewrite.
local function check_begin_resets(results)
    local state = fresh()
    state.max_transition_events_per_action = 1
    transition.begin(state, "test", {})
    transition.emit(state, "kept", {})
    transition.emit(state, "dropped", {})
    transition.finish(state, {})
    transition.begin(state, "test", {})
    verdict(results, state.transition_event_overflow == nil,
        "8 begin clears the overflow account")
end

local function check_budget_reset(results)
    local state = fresh()
    state.trump_chain_steps = 7
    state.trump_repair_attempts = 4
    transition.begin(state, "test", {})
    verdict(results,
        state.trump_chain_steps == 0 and state.trump_repair_attempts == 0,
        string.format("9 begin zeroes cycle budgets: steps=%d repairs=%d",
            state.trump_chain_steps, state.trump_repair_attempts))
    transition.finish(state, {})
end

-- 10. Precedence of errors. Catches the loss of overflow information when
-- runaway takes the error slot.
local function check_error_precedence(results)
    local state = fresh()
    state.max_transition_events_per_action = 1
    transition.begin(state, "test", {})
    transition.emit(state, "kept", {})
    transition.emit(state, "dropped", {})
    state.trump_runaway = true
    local summary = transition.finish(state, {}).summary
    verdict(results,
        summary.error == "trump_flow_runaway"
            and summary.transition_event_overflow ~= nil,
        string.format("10 runaway outranks the limit, overflow still reported: error=%s overflow=%s",
            tostring(summary.error),
            summary.transition_event_overflow and "present" or "missing"))
end

-- 11. The flag is a property of the match, not of the action. Catches an
-- eager cleanup that would make a terminal condition forgettable.
local function check_flag_survives(results)
    local state = fresh()
    transition.begin(state, "test", {})
    state.trump_runaway = true
    transition.finish(state, {})
    verdict(results, state.trump_runaway == true,
        "11 runaway flag survives finish")
end

-- 12. A degenerate case named so that it does not count as an error.
local function check_finish_without_begin(results)
    local state = fresh()
    local before = state.transition_seq
    local closed = transition.finish(state, {})
    verdict(results, closed == nil and state.transition_seq == before,
        "12 finish without begin does nothing and says so")
end

-- 13. STRUCTURAL. The layer carries no core dependency: that is what lets
-- all seven core modules report through it without knowing each other
-- (TRANSITION_LAW §2). Reading the file is the only way to see it.
local function check_no_core_dependency(results)
    local file = io.open("src/core/transition.lua", "r")
    if not file then
        results[#results + 1] = registry.fail(CITE, "13 STRUCTURAL: src/core/transition.lua unreadable")
        return
    end
    local source = file:read("*a")
    file:close()

    local found = {}
    for name in source:gmatch('require%("src%.core%.([%a_]+)"%)') do
        found[#found + 1] = name
    end
    verdict(results, #found == 0,
        string.format("13 STRUCTURAL: core requires in transition.lua: %d", #found))
end

--------------------------------------------------------------------------

function M.run(opts)
    local results = {}

    check_seq(results)
    check_two_places(results)
    check_emit_outside(results)
    check_drain(results)
    check_ceiling(results)
    check_begin_resets(results)
    check_budget_reset(results)
    check_error_precedence(results)
    check_flag_survives(results)
    check_finish_without_begin(results)
    check_no_core_dependency(results)

    return {results = results}
end

return M
