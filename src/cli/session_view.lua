-- Readouts over a session position: fits, trace, metrics, card lookup.
--
-- Everything here except card_lookup / find reads only what the player is
-- allowed to know. MACHINE_CLI_LAW §1 requires each command to declare its
-- surface, so the two debug readouts are grouped at the bottom and the caller
-- prints the debug banner for them.

local core = require("src.core.game")
local rules = require("src.core.rules")
local constants = require("src.core.constants")

local M = {}

M.DEBUG_BANNER = "DEBUG SURFACE: full information"

--------------------------------------------------------------------------
-- fits (MACHINE_CLI_SLICE §8) -- honest: own hand against the open manifest
--------------------------------------------------------------------------

function M.fits(game)
    local rows = {}
    local manifest = game.zones.manifest
    for _, hand_card_id in ipairs(game.zones.hand.cards) do
        local hand_card = game.cards[hand_card_id]
        local fit, joker = {}, {}
        for slot = 1, manifest.slot_count do
            local manifest_card_id = manifest.cards[slot]
            local manifest_card = manifest_card_id and game.cards[manifest_card_id]
            if manifest_card then
                if rules.full_pair_fit(manifest_card, hand_card) then
                    fit[#fit + 1] = slot
                elseif rules.move_legal(game, manifest_card, hand_card, hand_card_id) then
                    joker[#joker + 1] = slot
                end
            end
        end
        rows[#rows + 1] = {
            card_id = hand_card_id,
            pair = hand_card.op_a .. "/" .. hand_card.op_b,
            fit = fit,
            joker = joker,
        }
    end
    return rows
end

local function slot_list(list)
    local parts = {}
    for _, slot in ipairs(list) do
        parts[#parts + 1] = tostring(slot)
    end
    return "[" .. table.concat(parts, ",") .. "]"
end

function M.format_fits(rows)
    local lines = {}
    for _, row in ipairs(rows) do
        lines[#lines + 1] = string.format(
            "%-10s %-18s fit:%-14s joker:%s",
            row.card_id, row.pair, slot_list(row.fit), slot_list(row.joker))
    end
    if #lines == 0 then
        lines[#lines + 1] = "(hand empty)"
    end
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- trace (MACHINE_CLI_SLICE §9) -- grouped by turn, step boundaries visible
--------------------------------------------------------------------------

local EXTRA_TRUMP_EVENTS = {
    halt_mode_begin = true,
    halt_mode_end = true,
    latent_trump_revealed = true,
    deck_shuffled = true,
}

local function is_trump_event(event_type)
    return event_type:find("trump", 1, true) ~= nil or EXTRA_TRUMP_EVENTS[event_type] or false
end

-- Setup events carry entry index 0 and belong to no turn. Folding them into
-- turn 1 would misreport where the first turn begins, and the whole point of
-- the trace is that a boundary is not a guess.
function M.group_turns(events)
    local turns = {}
    local current = {index = 0, setup = true, events = {}}
    for _, event in ipairs(events) do
        if current.setup and event.entry ~= 0 then
            if #current.events > 0 then
                turns[#turns + 1] = current
            end
            current = {index = 1, events = {}}
        end
        current.events[#current.events + 1] = event
        if event.type == "turn_closed" then
            turns[#turns + 1] = current
            current = {index = current.index + 1, events = {}}
        end
    end
    if #current.events > 0 then
        current.open = true
        turns[#turns + 1] = current
    end
    return turns
end

local function payload_text(payload)
    if type(payload) ~= "table" then
        return ""
    end
    local keys = {}
    for key in pairs(payload) do
        keys[#keys + 1] = key
    end
    table.sort(keys)
    local parts = {}
    for _, key in ipairs(keys) do
        local value = payload[key]
        if type(value) ~= "table" then
            parts[#parts + 1] = key .. "=" .. tostring(value)
        end
    end
    return table.concat(parts, " ")
end

function M.format_trace(turns, limit)
    local lines = {}
    local first = 1
    if limit and limit > 0 and #turns > limit then
        first = #turns - limit + 1
    end
    for index = first, #turns do
        local turn = turns[index]
        lines[#lines + 1] = turn.setup
            and "=== setup ==="
            or string.format("=== turn %d%s ===", turn.index, turn.open and " (open)" or "")
        for _, event in ipairs(turn.events) do
            local mark = is_trump_event(event.type) and "T" or " "
            lines[#lines + 1] = string.format(
                "%s   %-28s %s", mark, event.type, payload_text(event.payload))
            if event.type == "step_spend_end" then
                lines[#lines + 1] = "    ---- steps 1-7 done, trump queue drains below ----"
            end
        end
    end
    if #lines == 0 then
        lines[#lines + 1] = "(no events)"
    end
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- metrics (MACHINE_CLI_SLICE §10) -- position only, never a run
--------------------------------------------------------------------------

function M.metrics(game)
    local legal_actions = #core.enumerate_legal_actions(game)

    local legal_pairs = 0
    local manifest = game.zones.manifest
    for _, hand_card_id in ipairs(game.zones.hand.cards) do
        local hand_card = game.cards[hand_card_id]
        for slot = 1, manifest.slot_count do
            local manifest_card_id = manifest.cards[slot]
            local manifest_card = manifest_card_id and game.cards[manifest_card_id]
            if manifest_card and rules.full_pair_fit(manifest_card, hand_card) then
                legal_pairs = legal_pairs + 1
            end
        end
    end

    local hand_count = #game.zones.hand.cards

    local joker_available = false
    for _, hand_card_id in ipairs(game.zones.hand.cards) do
        if rules.logic_available(game, hand_card_id) then
            joker_available = true
            break
        end
    end
    if not joker_available then
        for _, op_name in ipairs(rules.runtime_granted_operators(game)) do
            if op_name == "LOGIC" then
                joker_available = true
                break
            end
        end
    end

    local deck = game.zones.deck.cards
    local trumps_in_deck = 0
    for _, card_id in ipairs(deck) do
        if game.cards[card_id].class == "trump" then
            trumps_in_deck = trumps_in_deck + 1
        end
    end

    local zones = {}
    for name, zone in pairs(game.zones) do
        if zone.kind == "slots" then
            local filled = 0
            for slot = 1, zone.slot_count do
                if zone.cards[slot] then
                    filled = filled + 1
                end
            end
            zones[name] = string.format("%d/%d", filled, zone.slot_count)
        else
            zones[name] = tostring(#zone.cards)
        end
    end

    return {
        legal_actions = legal_actions,
        legal_pairs = legal_pairs,
        locked = legal_pairs == 0 and hand_count > 0,
        joker_available = joker_available,
        trump_density = #deck > 0 and (trumps_in_deck / #deck) or 0,
        trumps_in_deck = trumps_in_deck,
        deck = #deck,
        zones = zones,
    }
end

local ZONE_ORDER = {
    "deck", "hand", "manifest", "latent", "targets",
    "play", "runtime", "trump", "trump_flow", "grave",
}

function M.format_metrics(metrics)
    local lines = {}
    lines[#lines + 1] = string.format("legal_actions     %d", metrics.legal_actions)
    lines[#lines + 1] = string.format("legal_pairs       %d", metrics.legal_pairs)
    lines[#lines + 1] = string.format("locked            %s", tostring(metrics.locked))
    lines[#lines + 1] = string.format("joker_available   %s", tostring(metrics.joker_available))
    lines[#lines + 1] = string.format(
        "trump_density     %.3f  (%d of %d in deck)",
        metrics.trump_density, metrics.trumps_in_deck, metrics.deck)
    local parts = {}
    for _, name in ipairs(ZONE_ORDER) do
        parts[#parts + 1] = string.format("%s=%s", name, metrics.zones[name])
    end
    lines[#lines + 1] = "zones             " .. table.concat(parts, " ")
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- DEBUG readouts (MACHINE_CLI_LAW §6)
--------------------------------------------------------------------------

function M.card_lookup(game, card_id)
    local card = game.cards[card_id]
    if not card then
        return nil, "unknown_card"
    end
    return string.format(
        "%s  %s/%s  %s  %s  %s[%s]",
        card.id,
        tostring(card.op_a),
        tostring(card.op_b),
        card.trump_name and card.trump_name or card.class,
        card.info_state,
        tostring(card.zone or "-"),
        tostring(card.slot or "-"))
end

function M.find_pair(game, op_a, op_b)
    local matches = {}
    for _, card in pairs(game.cards) do
        local direct = card.op_a == op_a and card.op_b == op_b
        local swapped = card.op_a == op_b and card.op_b == op_a
        if direct or swapped then
            matches[#matches + 1] = card.id
        end
    end
    table.sort(matches)
    return matches
end

function M.valid_operator(name)
    for _, op in ipairs(constants.OPERATORS) do
        if op == name then
            return true
        end
    end
    return false
end

return M
