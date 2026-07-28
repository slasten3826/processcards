-- Honest player-facing observation.
--
-- Why this module exists:
--
-- 1. inspect.snapshot() is a DEBUG view. It prints every card id.
-- 2. A card id encodes its identity: cards.minor_pair_from_index derives
--    op_a / op_b directly from the index in "MINOR-<index>", and trump ids
--    map into constants.TRUMP_CANON the same way.
-- 3. Therefore printing the id of a hidden card leaks its operators
--    completely, even when info_state is respected.
--
-- This module exposes identity only for cards the player is allowed to know
-- (state.is_known, i.e. known or revealed). Hidden cards appear as position
-- plus an opaque handle. Actions on hidden cards are built through
-- M.build_action so an agent never has to see an id in order to act.
--
-- Universal rule, no per-zone exceptions:
--
--     identity is exposed  <=>  state_lib.is_known(state, card_id)
--
-- GRAVE_LAW makes grave cards revealed on entry, so grave stays fully
-- visible under this rule without a special case.

local state_lib = require("src.core.state")

local M = {}

M.contract_version = "view.honest.v0"

-- Fixed order so handles are stable within one observation.
local HANDLE_ZONE_ORDER = {
    "manifest",
    "latent",
    "targets",
    "trump",
    "play",
    "runtime",
}

local SLOT_ZONES = {
    manifest = true,
    latent = true,
    targets = true,
    trump = true,
    play = true,
    runtime = true,
}

local function card_public_view(state, card_id, handle)
    local card = state.cards[card_id]
    if not card then
        return nil
    end
    if not state_lib.is_known(state, card_id) then
        return {
            present = true,
            state = card.info_state,
            handle = handle,
        }
    end
    return {
        present = true,
        state = card.info_state,
        id = card.id,
        class = card.class,
        op_a = card.op_a,
        op_b = card.op_b,
        trump_name = card.trump_name,
    }
end

local function position_key(zone_name, slot)
    return zone_name .. ":" .. tostring(slot)
end

local function observe_slot_zone(state, zone_name, handles, next_handle, at)
    local zone = state.zones[zone_name]
    local out = {}
    for slot = 1, zone.slot_count do
        local card_id = zone.cards[slot]
        if not card_id then
            out[slot] = {present = false}
        else
            local handle = nil
            if not state_lib.is_known(state, card_id) then
                handle = string.format("H%d", next_handle())
                handles[handle] = {zone = zone_name, slot = slot}
                at[position_key(zone_name, slot)] = handle
            end
            out[slot] = card_public_view(state, card_id, handle)
        end
    end
    return out
end

local function observe_ordered_zone(state, zone_name, handles, next_handle, at)
    local zone = state.zones[zone_name]
    local out = {}
    for index, card_id in ipairs(zone.cards) do
        local handle = nil
        if not state_lib.is_known(state, card_id) then
            handle = string.format("H%d", next_handle())
            handles[handle] = {zone = zone_name, index = index}
            at[position_key(zone_name, index)] = handle
        end
        out[index] = card_public_view(state, card_id, handle)
    end
    return out
end

-- Deck: the player sees the pile height and the top card only if it is known.
local function observe_deck(state, handles, next_handle, at)
    local zone = state.zones.deck
    local count = #zone.cards
    local top_id = zone.cards[count]
    local top = nil
    if top_id then
        local handle = nil
        if not state_lib.is_known(state, top_id) then
            handle = string.format("H%d", next_handle())
            handles[handle] = {zone = "deck", index = count}
            at[position_key("deck", count)] = handle
        end
        top = card_public_view(state, top_id, handle)
    end
    return {
        count = count,
        top = top,
    }
end

function M.observe(state, opts)
    opts = opts or {}

    local handles = {}
    local counter = 0
    local function next_handle()
        counter = counter + 1
        return counter
    end

    -- position -> handle, kept LOCAL. Storing card_id -> handle would put the
    -- identity of a hidden card into the observation itself, which is the one
    -- thing this module exists to prevent.
    local at = {}

    local zones = {}
    for _, zone_name in ipairs(HANDLE_ZONE_ORDER) do
        zones[zone_name] = observe_slot_zone(state, zone_name, handles, next_handle, at)
    end

    -- Own hand is fully legible to its holder regardless of info_state.
    local hand = {}
    for index, card_id in ipairs(state.zones.hand.cards) do
        local card = state.cards[card_id]
        hand[index] = {
            present = true,
            state = card.info_state,
            id = card.id,
            class = card.class,
            op_a = card.op_a,
            op_b = card.op_b,
            trump_name = card.trump_name,
        }
    end
    zones.hand = hand

    zones.grave = observe_ordered_zone(state, "grave", handles, next_handle, at)
    zones.trump_flow = observe_ordered_zone(state, "trump_flow", handles, next_handle, at)
    zones.deck = observe_deck(state, handles, next_handle, at)

    local observation = {
        contract = M.contract_version,
        board_closed = state_lib.is_board_closed(state),
        counts = {
            deck = #state.zones.deck.cards,
            hand = #state.zones.hand.cards,
            grave = #state.zones.grave.cards,
            trump_flow = #state.zones.trump_flow.cards,
        },
        zones = zones,
        handles = handles,
        hidden_count = counter,
    }

    if opts.interaction then
        local ix = opts.interaction
        observation.phase = ix.phase
        observation.prompt = ix.prompt
        observation.legal_operators = {}
        for index, operator in ipairs((ix.legal and ix.legal.operators) or {}) do
            observation.legal_operators[index] = operator
        end
        observation.advance_enabled = ix.advance and ix.advance.enabled or false
        observation.advance_reason = ix.advance and ix.advance.reason or nil

        observation.legal_directions = {}
        for index, direction in ipairs((ix.legal and ix.legal.directions) or {}) do
            observation.legal_directions[index] = direction
        end

        -- A prompt without a list of choices is not an observation, it is a
        -- riddle. Hidden targets are offered by HANDLE, so the player can pick
        -- one without being told which card it is.
        observation.legal_target_slots = {}
        for index, slot in ipairs((ix.legal and ix.legal.targets and ix.legal.targets.slots) or {}) do
            observation.legal_target_slots[index] = slot
        end

        observation.legal_targets = {}
        for _, card_id in ipairs((ix.legal and ix.legal.targets and ix.legal.targets.cards) or {}) do
            if state_lib.is_known(state, card_id) then
                observation.legal_targets[#observation.legal_targets + 1] = card_id
            else
                local card = state.cards[card_id]
                local key = card and position_key(card.zone, card.slot) or nil
                local handle = key and at[key] or nil
                if not handle and card and card.zone then
                    -- targetable but standing where nothing was enumerated:
                    -- mint a handle for the position rather than drop the option
                    handle = string.format("H%d", next_handle())
                    local ref = {zone = card.zone}
                    if SLOT_ZONES[card.zone] then
                        ref.slot = card.slot
                    else
                        ref.index = card.slot
                    end
                    handles[handle] = ref
                    at[key] = handle
                end
                if handle then
                    observation.legal_targets[#observation.legal_targets + 1] = handle
                end
            end
        end
    end

    -- which world node is committed, so a policy can tell a dead end from a
    -- fresh choice; the slot is public, the card in it is already revealed
    if state.committed and state.committed.slot then
        observation.committed_slot = state.committed.slot
    end

    if opts.legal_action_count then
        observation.legal_action_count = opts.legal_action_count
    end

    return observation
end

-- Turn a handle back into a real card id. This is the trusted boundary:
-- it exists so an agent can ACT on a hidden card without ever reading its
-- identity. Do not use it to inspect.
function M.resolve_handle(state, observation, handle)
    local ref = observation.handles and observation.handles[handle]
    if not ref then
        return nil, "unknown_handle"
    end
    local zone = state.zones[ref.zone]
    if not zone then
        return nil, "unknown_zone"
    end
    local card_id
    if SLOT_ZONES[ref.zone] then
        card_id = zone.cards[ref.slot]
    else
        card_id = zone.cards[ref.index]
    end
    if not card_id then
        return nil, "empty_position"
    end
    return card_id
end

-- Build a real action table from a handle-bearing intent, so the agent
-- protocol never needs to carry ids of hidden cards.
function M.build_action(state, observation, intent)
    if type(intent) ~= "table" then
        return nil, "invalid_intent"
    end
    local action = {}
    for key, value in pairs(intent) do
        if key ~= "handle" then
            action[key] = value
        end
    end
    if intent.handle then
        local card_id, err = M.resolve_handle(state, observation, intent.handle)
        if not card_id then
            return nil, err
        end
        if action.target then
            local target = {}
            for key, value in pairs(action.target) do
                target[key] = value
            end
            target.card_id = card_id
            action.target = target
        else
            action.target = {card_id = card_id}
        end
    end
    return action
end

local function count_operator(list, operator)
    local total = 0
    for _, entry in ipairs(list or {}) do
        if entry.present and entry.id and (entry.op_a == operator or entry.op_b == operator) then
            total = total + 1
        end
    end
    return total
end

-- Same weights as game.evaluate_state, minus the hidden_trumps term, and with
-- manifest CONNECT counted only over cards the player may know. Keeping the
-- weights identical is deliberate: one variable changes, so the two scores
-- stay comparable.
function M.evaluate(observation)
    local hand_count = observation.counts.hand
    local deck_count = observation.counts.deck
    local grave_count = observation.counts.grave
    local connect_in_hand = count_operator(observation.zones.hand, "CONNECT")
    local connect_in_manifest = count_operator(observation.zones.manifest, "CONNECT")
    local legal_action_count = observation.legal_action_count or 0
    local board_closed = observation.board_closed

    local score =
        hand_count * 12 +
        deck_count * 0.25 +
        connect_in_hand * 18 +
        connect_in_manifest * 8 +
        legal_action_count * 1.5 +
        (board_closed and 15 or -25) -
        grave_count * 0.1 -
        observation.counts.trump_flow * 4

    return {
        score = score,
        hand_count = hand_count,
        deck_count = deck_count,
        grave_count = grave_count,
        connect_in_hand = connect_in_hand,
        connect_in_manifest = connect_in_manifest,
        legal_action_count = legal_action_count,
        board_closed = board_closed,
        phase = observation.phase,
        hidden_count = observation.hidden_count,
    }
end

local function format_card(entry)
    if not entry or not entry.present then
        return "-"
    end
    if not entry.id then
        return string.format("?%s", entry.handle or "")
    end
    local name = entry.trump_name and (entry.trump_name .. " ") or ""
    return string.format("%s%s/%s", name, entry.op_a, entry.op_b)
end

local function format_slot_zone(list, slot_count)
    local parts = {}
    for slot = 1, slot_count do
        parts[#parts + 1] = string.format("%d:%s", slot, format_card(list[slot]))
    end
    return table.concat(parts, " | ")
end

local function format_ordered_zone(list)
    local parts = {}
    for _, entry in ipairs(list) do
        parts[#parts + 1] = format_card(entry)
    end
    return table.concat(parts, ", ")
end

function M.format(observation)
    local lines = {}
    lines[#lines + 1] = "PLAYER OBSERVATION  " .. observation.contract
    lines[#lines + 1] = string.format(
        "phase=%s board_closed=%s deck=%d hand=%d grave=%d trump_flow=%d hidden=%d",
        tostring(observation.phase or "-"),
        observation.board_closed and "true" or "false",
        observation.counts.deck,
        observation.counts.hand,
        observation.counts.grave,
        observation.counts.trump_flow,
        observation.hidden_count
    )
    lines[#lines + 1] = "manifest: " .. format_slot_zone(observation.zones.manifest, 6)
    lines[#lines + 1] = "latent:   " .. format_slot_zone(observation.zones.latent, 6)
    lines[#lines + 1] = "targets:  " .. format_slot_zone(observation.zones.targets, 3)
    lines[#lines + 1] = "trump:    " .. format_slot_zone(observation.zones.trump, 2)
    lines[#lines + 1] = "play:     " .. format_slot_zone(observation.zones.play, 1)
    lines[#lines + 1] = "runtime:  " .. format_slot_zone(observation.zones.runtime, 1)
    lines[#lines + 1] = "hand:     " .. format_ordered_zone(observation.zones.hand)
    lines[#lines + 1] = "grave:    " .. format_ordered_zone(observation.zones.grave)
    lines[#lines + 1] = "flow:     " .. format_ordered_zone(observation.zones.trump_flow)
    lines[#lines + 1] = string.format(
        "deck top: %s  (remaining %d)",
        format_card(observation.zones.deck.top),
        observation.zones.deck.count
    )
    if observation.prompt then
        lines[#lines + 1] = "prompt:   " .. tostring(observation.prompt)
    end
    if observation.legal_operators and #observation.legal_operators > 0 then
        lines[#lines + 1] = "legal operators: " .. table.concat(observation.legal_operators, " ")
    end
    if observation.legal_directions and #observation.legal_directions > 0 then
        lines[#lines + 1] = "legal directions: " .. table.concat(observation.legal_directions, " ")
    end
    if observation.legal_target_slots and #observation.legal_target_slots > 0 then
        local parts = {}
        for _, slot in ipairs(observation.legal_target_slots) do
            parts[#parts + 1] = tostring(slot)
        end
        lines[#lines + 1] = "legal target slots: " .. table.concat(parts, " ")
    end
    if observation.legal_targets and #observation.legal_targets > 0 then
        lines[#lines + 1] = "legal targets: " .. table.concat(observation.legal_targets, " ")
    end
    return table.concat(lines, "\n")
end

return M
