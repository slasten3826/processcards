-- Slice checks for LOGIC_JOKER_LAW.
--
-- Encodes section 9 of docs/crystall/LOGIC_JOKER_SLICE_2026-07-27.md so the
-- law is verified on demand instead of by hand once.
--
--     lua cli.lua check_logic

local core = require("src.core.game")
local rules = require("src.core.rules")
local state_lib = require("src.core.state")
local rng = require("src.sim.rng")
local draw = require("src.core.draw")

local M = {}

local function new_game(seed)
    local game = core.new()
    core.start_game(game, {rng = rng.from_seed(seed), enabled_trumps = {}})
    return game
end

local function find_card(game, op_a, op_b)
    for id, card in pairs(game.cards) do
        if card.class == "minor" and card.op_a == op_a and card.op_b == op_b then
            return id
        end
    end
    return nil
end

-- Planting a card that already sits on the board would leave a hole there, and
-- then every later assertion would be measuring the fixture instead of the
-- code. So the origin slot is refilled: manifest face-up, latent concealed.
local function plant(game, card_id, zone, slot)
    local card = game.cards[card_id]
    local from_zone, from_slot = card.zone, card.slot
    state_lib.remove_from_current_zone(game, card_id)
    state_lib.reveal_card(game, card_id)
    state_lib.place_card(game, card_id, zone, slot)
    if from_zone == "manifest" and from_slot then
        draw.open_manifest_closure(game, from_slot)
    elseif from_zone == "latent" and from_slot then
        draw.concealed_refill(game, "latent", from_slot)
    elseif from_zone == "targets" and from_slot then
        draw.concealed_refill(game, "targets", from_slot)
    end
end

-- first manifest slot where the hand card does or does not close on its own
local function slot_by_fit(game, hand_card_id, want_fit)
    for slot = 1, game.zones.manifest.slot_count do
        local manifest_id = game.zones.manifest.cards[slot]
        if manifest_id then
            local fits = rules.full_pair_fit(game.cards[manifest_id], game.cards[hand_card_id])
            if fits == want_fit then
                return slot
            end
        end
    end
    return nil
end

local function occupied_manifest_slots(game)
    local total = 0
    for slot = 1, game.zones.manifest.slot_count do
        if game.zones.manifest.cards[slot] then
            total = total + 1
        end
    end
    return total
end

local function board_closed(game)
    for slot = 1, 6 do
        if not game.zones.manifest.cards[slot] or not game.zones.latent.cards[slot] then
            return false
        end
    end
    return true
end

-- Drive one full turn and report what the interaction offered and what happened.
local function play_turn(game, hand_card_id, slot)
    local committed_id = game.zones.manifest.cards[slot]
    core.apply_action(game, {kind = "commit_manifest", slot = slot})
    core.apply_action(game, {kind = "arm_hand", card_id = hand_card_id})
    core.apply_action(game, {kind = "advance"})

    local ix = core.interaction(game)
    local offered = {}
    for index, op_name in ipairs((ix.legal and ix.legal.operators) or {}) do
        offered[index] = op_name
    end

    core.apply_action(game, {kind = "arm_operator", operator = "LOGIC"})
    core.apply_action(game, {kind = "advance"})

    local events = {}
    for _, event in ipairs(core.drain_events(game)) do
        events[#events + 1] = event.type
    end

    return {
        offered = offered,
        events = table.concat(events, ","),
        committed_zone = game.cards[committed_id] and game.cards[committed_id].zone,
        played_zone = game.cards[hand_card_id] and game.cards[hand_card_id].zone,
        slot_refilled = game.zones.manifest.cards[slot] ~= nil,
        closed = board_closed(game),
        phase = core.interaction(game).phase,
    }
end

local function only(list, value)
    return #list == 1 and list[1] == value
end

local function contains(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return true
        end
    end
    return false
end

function M.run(seed)
    seed = seed or 3
    local checks = {}
    local function check(name, ok, detail)
        checks[#checks + 1] = {name = name, ok = ok and true or false, detail = detail}
    end
    -- A seed where the fixture card fits every slot has no joker case to
    -- exercise. That is an absent scenario, not a failed law.
    local function skip(name, detail)
        checks[#checks + 1] = {name = name, skipped = true, detail = detail}
    end

    -- 1 and 6: joker move
    do
        local game = new_game(seed)
        local card = find_card(game, "LOGIC", "OBSERVE")
        plant(game, card, "hand")
        local slot = slot_by_fit(game, card, false)
        if not slot then
            skip("1 joker move", "card fits every slot on this seed")
        else
            local result = play_turn(game, card, slot)
            check("1 joker move offers only LOGIC", only(result.offered, "LOGIC"),
                table.concat(result.offered, ","))
            check("1b no target phase opened",
                not result.events:find("pair_card_choice_pending"), result.events)
            check("1c logic_joker_pass emitted",
                result.events:find("logic_joker_pass") ~= nil, result.events)
            check("6a committed card to grave", result.committed_zone == "grave", result.committed_zone)
            check("6b played card to grave", result.played_zone == "grave", result.played_zone)
            check("6c manifest slot refilled", result.slot_refilled)
            check("7 board closed after joker turn", result.closed)
        end
    end

    -- 2: same card where topology closes on its own
    do
        local game = new_game(seed)
        local card = find_card(game, "LOGIC", "OBSERVE")
        plant(game, card, "hand")
        local slot = slot_by_fit(game, card, true)
        if not slot then
            skip("2 normal fit", "card fits no slot on this seed")
        else
            local result = play_turn(game, card, slot)
            check("2 normal fit keeps full choice",
                contains(result.offered, "LOGIC") and contains(result.offered, "OBSERVE"),
                table.concat(result.offered, ","))
            check("2b no joker pass on a normal fit",
                not result.events:find("logic_joker_pass"), result.events)
            check("2c board closed", result.closed)
        end
    end

    -- 3: a card without LOGIC stays illegal where it does not fit
    do
        local game = new_game(seed)
        local card = find_card(game, "CYCLE", "CYCLE")
        plant(game, card, "hand")
        local illegal = 0
        for slot = 1, 6 do
            local manifest_id = game.zones.manifest.cards[slot]
            if manifest_id and not rules.move_legal(game, game.cards[manifest_id], game.cards[card], card) then
                illegal = illegal + 1
            end
        end
        check("3 non-LOGIC card can still be illegal", illegal > 0, string.format("%d of %d occupied illegal", illegal, occupied_manifest_slots(game)))
    end

    -- 4: the LOGIC double is legal against every occupied slot
    do
        local game = new_game(seed)
        local card = find_card(game, "LOGIC", "LOGIC")
        plant(game, card, "hand")
        local legal = 0
        for slot = 1, 6 do
            local manifest_id = game.zones.manifest.cards[slot]
            if manifest_id and rules.move_legal(game, game.cards[manifest_id], game.cards[card], card) then
                legal = legal + 1
            end
        end
        local occupied = occupied_manifest_slots(game)
        check("4 LOGIC double legal to every slot", legal == occupied,
            string.format("%d/%d occupied", legal, occupied))
    end

    -- 5: LOGIC installed in runtime carries a card that does not hold it
    do
        local game = new_game(seed)
        local runtime_card = find_card(game, "RUNTIME", "LOGIC")
        plant(game, runtime_card, "runtime", 1)
        local card = find_card(game, "CYCLE", "CYCLE")
        plant(game, card, "hand")

        local granted = rules.runtime_granted_operators(game)
        check("5a runtime grants LOGIC", contains(granted, "LOGIC"), table.concat(granted, ","))

        local legal = 0
        for slot = 1, 6 do
            local manifest_id = game.zones.manifest.cards[slot]
            if manifest_id and rules.move_legal(game, game.cards[manifest_id], game.cards[card], card) then
                legal = legal + 1
            end
        end
        local occupied = occupied_manifest_slots(game)
        check("5b runtime LOGIC makes any slot legal", legal == occupied,
            string.format("%d/%d occupied", legal, occupied))

        local slot = slot_by_fit(game, card, false)
        if slot then
            local result = play_turn(game, card, slot)
            check("5c runtime joker still costs the effect", only(result.offered, "LOGIC"),
                table.concat(result.offered, ","))
        else
            skip("5c runtime joker still costs the effect", "card fits every slot on this seed")
        end
    end

    local passed, failed, skipped = 0, 0, 0
    for _, entry in ipairs(checks) do
        if entry.skipped then
            skipped = skipped + 1
        elseif entry.ok then
            passed = passed + 1
        else
            failed = failed + 1
        end
    end

    return {
        seed = seed,
        checks = checks,
        passed = passed,
        failed = failed,
        skipped = skipped,
        total = #checks,
        ok = failed == 0,
    }
end

function M.format(report)
    local lines = {}
    lines[#lines + 1] = string.format("LOGIC JOKER SLICE CHECKS  seed=%d", report.seed)
    for _, entry in ipairs(report.checks) do
        local mark = entry.skipped and "SKIP" or (entry.ok and "OK" or "FAIL")
        lines[#lines + 1] = string.format("  %-4s %-42s %s",
            mark, entry.name, entry.detail or "")
    end
    lines[#lines + 1] = string.format("%d passed, %d failed, %d skipped",
        report.passed, report.failed, report.skipped)
    return table.concat(lines, "\n")
end

return M
