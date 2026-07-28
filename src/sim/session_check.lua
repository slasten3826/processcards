-- Checks for the machine session CLI, one per item of MACHINE_CLI_SLICE §12.
--
-- These run in process against a scratch journal directory, so they never
-- touch a session a machine is actually playing.

local core = require("src.core.game")
local view = require("src.core.view")
local inspect = require("src.core.inspect")
local rules = require("src.core.rules")
local state_lib = require("src.core.state")
local session = require("src.cli.session")
local readout = require("src.cli.session_view")

local M = {}

local SCRATCH_DIR = ".session/check"

local function fresh_log(seed, trumps)
    local log = session.new_log(seed, trumps or "full")
    return log
end

local function rebuild(log)
    local game, events, failure = session.rebuild(log)
    return game, events, failure
end

local function push(log, kind, text)
    log.entries[#log.entries + 1] = {kind = kind, text = text}
end

-- Walks a game forward with the playtest policy, calling visit at every
-- position. Checking only the opening position would test the setup routine
-- and nothing else; the interesting positions are the ones a game reaches.
local function walk(seed, steps, visit)
    local playtest = require("src.sim.playtest")
    local game = rebuild(fresh_log(seed))
    for _ = 1, steps do
        local stop = visit(game)
        if stop then
            return stop
        end
        local actions = core.enumerate_legal_actions(game)
        if #actions == 0 then
            return nil
        end
        local observation = session.observe(game)
        local action = playtest.protocol_policy(observation, actions)
        if not action then
            return nil
        end
        local result = core.apply_action(game, action)
        if result and result.summary and result.summary.error then
            return nil
        end
    end
    return nil
end

local function report(results, name, ok, detail)
    results[#results + 1] = {name = name, ok = ok, detail = detail}
    return ok
end

--------------------------------------------------------------------------

-- 1. new + do + show: the position matches the actions that were applied.
local function check_applied(results)
    local log = fresh_log(7)
    local game = rebuild(log)
    local hand_card = game.zones.hand.cards[1]

    push(log, "do", "hand:" .. hand_card)
    game = rebuild(log)
    if game.armed_hand ~= hand_card then
        return report(results, "applied", false, "arm_hand did not arm " .. hand_card)
    end

    local slots = rules.legal_manifest_slots_for_hand(game, hand_card)
    if #slots == 0 then
        return report(results, "applied", true, "SKIP: first hand card fits nothing on seed 7")
    end

    push(log, "do", "commit:" .. slots[1])
    game = rebuild(log)
    if not game.committed or game.committed.slot ~= slots[1] then
        return report(results, "applied", false, "commit did not take")
    end

    push(log, "do", "advance")
    game = rebuild(log)
    if game.zones.play.cards[1] ~= hand_card then
        return report(results, "applied", false, "advance did not cast the armed card")
    end
    return report(results, "applied", true)
end

-- 2. the same journal replayed twice yields the same position.
local function check_deterministic(results)
    local log = fresh_log(11)
    local game = rebuild(log)
    local hand_card = game.zones.hand.cards[1]
    local slots = rules.legal_manifest_slots_for_hand(game, hand_card)
    push(log, "do", "hand:" .. hand_card)
    if #slots > 0 then
        push(log, "do", "commit:" .. slots[1])
        push(log, "do", "advance")
    end

    local first = inspect.snapshot((rebuild(log)))
    local second = inspect.snapshot((rebuild(log)))
    return report(results, "deterministic", first == second,
        first ~= second and "two replays of one journal diverged" or nil)
end

-- 3. undo returns exactly to the position before the last entry.
local function check_undo(results)
    local log = fresh_log(11)
    local game = rebuild(log)
    local hand_card = game.zones.hand.cards[1]
    push(log, "do", "hand:" .. hand_card)

    local before = inspect.snapshot((rebuild(log)))
    push(log, "do", "clear_armed_placeholder")
    log.entries[#log.entries] = {kind = "do", text = "clear:armed"}
    local mid_game, _, failure = rebuild(log)
    if failure then
        return report(results, "undo", false, "setup entry failed: " .. tostring(failure.error))
    end
    local _ = mid_game

    table.remove(log.entries)
    local after = inspect.snapshot((rebuild(log)))
    return report(results, "undo", before == after,
        before ~= after and "position after undo differs from position before the entry" or nil)
end

-- 4. planting out of the manifest refills the hole and leaves the board closed.
local function check_plant_refill(results)
    local log = fresh_log(3)
    local game = rebuild(log)
    local deck_before = #game.zones.deck.cards
    local card_id = game.zones.manifest.cards[2]

    local plant_report, err = session.plant(game, card_id, "grave")
    if not plant_report then
        return report(results, "plant_refill", false, tostring(err))
    end
    if not state_lib.is_board_closed(game) then
        return report(results, "plant_refill", false, "board left open after plant")
    end
    if game.cards[card_id].zone ~= "grave" then
        return report(results, "plant_refill", false, "planted card did not land in grave")
    end
    if #game.zones.deck.cards >= deck_before then
        return report(results, "plant_refill", false, "manifest hole was not refilled from the deck")
    end
    return report(results, "plant_refill", true)
end

-- 5. planting with an empty deck reports the hole instead of leaving it silently.
local function check_plant_warns(results)
    local log = fresh_log(3)
    local game = rebuild(log)
    game.zones.deck.cards = {}

    local card_id = game.zones.latent.cards[1]
    local plant_report, err = session.plant(game, card_id, "grave")
    if not plant_report then
        return report(results, "plant_warns", false, tostring(err))
    end
    if not plant_report.hole then
        return report(results, "plant_warns", false, "empty deck did not raise the hole flag")
    end
    local text = session.format_plant(plant_report)
    if not text:find("PLANT WARNING", 1, true) then
        return report(results, "plant_warns", false, "hole was not printed")
    end
    return report(results, "plant_warns", true)
end

-- 6. the honest readout never prints the id of a hidden card.
local function check_no_leak(results, seeds, steps)
    local positions = 0
    for seed = 1, seeds do
        local failure = walk(seed, steps, function(game)
            positions = positions + 1
            local text = view.format(session.observe(game))
            for card_id, card in pairs(game.cards) do
                if card.info_state == "hidden" and text:find(card_id, 1, true) then
                    return string.format("seed %d leaked %s", seed, card_id)
                end
            end
        end)
        if failure then
            return report(results, "no_leak", false, failure)
        end
    end
    return report(results, "no_leak", true, string.format("%d positions", positions))
end

-- 7. a handle resolves to the card actually standing at that position.
local function check_handle(results)
    local log = fresh_log(5)
    local game = rebuild(log)
    local observation = session.observe(game)

    local handle, ref = next(observation.handles)
    if not handle then
        return report(results, "handle", true, "SKIP: no hidden card on the board")
    end
    local resolved = view.resolve_handle(game, observation, handle)
    local expected = ref.slot
        and game.zones[ref.zone].cards[ref.slot]
        or game.zones[ref.zone].cards[ref.index]
    if resolved ~= expected then
        return report(results, "handle", false,
            string.format("%s resolved to %s, expected %s",
                handle, tostring(resolved), tostring(expected)))
    end

    local action, err = session.parse_action(game, "target:" .. handle)
    if not action then
        return report(results, "handle", true,
            "SKIP: no target phase open, parse said " .. tostring(err))
    end
    if action.target.card_id ~= expected then
        return report(results, "handle", false, "parse_action resolved the wrong card")
    end
    return report(results, "handle", true)
end

-- 8. a joker slot is offered only when LOGIC is actually reachable.
local function check_fits_joker(results, seeds, steps)
    local jokers_seen = 0
    for seed = 1, seeds do
        local failure = walk(seed, steps, function(game)
            for _, row in ipairs(readout.fits(game)) do
                if #row.joker > 0 then
                    jokers_seen = jokers_seen + 1
                    if not rules.logic_available(game, row.card_id) then
                        return string.format(
                            "seed %d: %s offered joker slots without LOGIC", seed, row.card_id)
                    end
                end
            end
        end)
        if failure then
            return report(results, "fits_joker", false, failure)
        end
    end
    return report(results, "fits_joker", true,
        string.format("%d joker offers verified", jokers_seen))
end

-- 9. metrics.locked agrees with the rules module, not only with itself.
local function check_locked(results, seeds, steps)
    local locked_seen = 0
    for seed = 1, seeds do
        local failure = walk(seed, steps, function(game)
            local metrics = readout.metrics(game)
            if metrics.locked and not metrics.joker_available then
                locked_seen = locked_seen + 1
                for _, hand_card_id in ipairs(game.zones.hand.cards) do
                    local slots = rules.legal_manifest_slots_for_hand(game, hand_card_id)
                    if #slots > 0 then
                        return string.format("seed %d: locked, yet %s has %d legal slots",
                            seed, hand_card_id, #slots)
                    end
                end
            end
        end)
        if failure then
            return report(results, "locked", false, failure)
        end
    end
    return report(results, "locked", true,
        locked_seen == 0 and "SKIP: no locked position without a joker was reached" or
            string.format("%d locked positions verified", locked_seen))
end

--------------------------------------------------------------------------

function M.run(seeds, steps)
    seeds = seeds or 20
    steps = steps or 80
    local saved_dir = session.dir
    session.dir = SCRATCH_DIR

    local results = {}
    check_applied(results)
    check_deterministic(results)
    check_undo(results)
    check_plant_refill(results)
    check_plant_warns(results)
    check_no_leak(results, seeds, steps)
    check_handle(results)
    check_fits_joker(results, seeds, steps)
    check_locked(results, seeds, steps)

    session.dir = saved_dir

    local ok = true
    for _, entry in ipairs(results) do
        ok = ok and entry.ok
    end
    return {ok = ok, results = results, seeds = seeds, steps = steps}
end

function M.format(report_table)
    local lines = {}
    lines[#lines + 1] = string.format("SESSION CHECK seeds=%d steps=%d", report_table.seeds, report_table.steps)
    for index, entry in ipairs(report_table.results) do
        lines[#lines + 1] = string.format(
            "%d. %-14s %-5s %s",
            index, entry.name, entry.ok and "OK" or "FAIL", entry.detail or "")
    end
    lines[#lines + 1] = report_table.ok and "all checks passed" or "FAILURES PRESENT"
    return table.concat(lines, "\n")
end

return M
