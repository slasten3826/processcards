local rules = require("src.core.rules")
local state_lib = require("src.core.state")

local M = {}

local function occupied_manifest_slots(state)
    local slots = {}
    for slot = 1, state.zones.manifest.slot_count do
        if state.zones.manifest.cards[slot] then
            slots[#slots + 1] = slot
        end
    end
    return slots
end

local function legal_hand_cards_from_hints(state)
    local cards = {}
    for _, card_id in ipairs(state.zones.hand.cards) do
        if state.legal_hints[card_id] then
            cards[#cards + 1] = card_id
        end
    end
    return cards
end

local function zone_flags_from_cards(state, card_ids)
    local zones = {}
    for _, card_id in ipairs(card_ids or {}) do
        local card = state.cards[card_id]
        if card and card.zone then
            zones[card.zone] = true
        end
    end
    return zones
end

local function target_ref_for_card(state, card_id)
    if not card_id then
        return nil
    end
    local card = state.cards[card_id]
    if not card then
        return nil
    end
    return {
        kind = "card",
        zone = card.zone,
        card_id = card_id,
        slot = card.slot,
    }
end

local function target_ref_for_slot(zone, slot)
    if not slot then
        return nil
    end
    return {
        kind = "slot",
        zone = zone,
        slot = slot,
        card_id = nil,
    }
end

local function append_target_ref(list, ref)
    if ref then
        list[#list + 1] = ref
    end
end

local function empty_interaction()
    return {
        phase = "idle",
        prompt = "Idle.",
        advance = {
            enabled = false,
            reason = nil,
            label = nil,
        },
        armed = {
            hand_card_id = nil,
            operator = nil,
            target = nil,
            targets = {},
        },
        legal = {
            commit_slots = {},
            hand_cards = {},
            operators = {},
            targets = {
                kind = nil,
                cards = {},
                slots = {},
                zones = {},
            },
        },
        overlays = {
            grave_open = false,
            grave_select_mode = false,
        },
    }
end

function M.read(state)
    local ix = empty_interaction()

    ix.armed.hand_card_id = state.armed_hand
    ix.armed.operator = state.pending_operator_choice and state.pending_operator_choice.armed_operator or nil

    if state.pending_pair_card_choice then
        local pending = state.pending_pair_card_choice
        local armed_public = target_ref_for_card(state, pending.armed_public_card_id)
        local armed_hand = target_ref_for_card(state, pending.armed_hand_card_id)

        ix.phase = "await_target"
        ix.legal.targets.kind = "pair_card"
        append_target_ref(ix.armed.targets, armed_public)
        append_target_ref(ix.armed.targets, armed_hand)
        ix.armed.target = ix.armed.targets[1]

        if pending.armed_public_card_id and pending.armed_hand_card_id then
            ix.prompt = "Confirm the selected pair."
            ix.advance.enabled = true
            ix.advance.reason = "confirm_target"
            ix.advance.label = "Confirm pair"
            return ix
        end

        if pending.armed_public_card_id then
            ix.prompt = "Choose one hand card."
            ix.legal.targets.cards = pending.legal_hand_card_ids or {}
            ix.legal.targets.zones.hand = (#ix.legal.targets.cards > 0)
            return ix
        end

        if pending.armed_hand_card_id then
            ix.prompt = "Choose one revealed minor card."
            ix.legal.targets.cards = pending.legal_public_card_ids or {}
            ix.legal.targets.zones = zone_flags_from_cards(state, ix.legal.targets.cards)
            if ix.legal.targets.zones.grave then
                ix.overlays.grave_select_mode = true
            end
            return ix
        end

        ix.prompt = "Choose the first card of the pair."
        for _, card_id in ipairs(pending.legal_public_card_ids or {}) do
            ix.legal.targets.cards[#ix.legal.targets.cards + 1] = card_id
        end
        for _, card_id in ipairs(pending.legal_hand_card_ids or {}) do
            ix.legal.targets.cards[#ix.legal.targets.cards + 1] = card_id
        end
        ix.legal.targets.zones = zone_flags_from_cards(state, ix.legal.targets.cards)
        if #(pending.legal_hand_card_ids or {}) > 0 then
            ix.legal.targets.zones.hand = true
        end
        if ix.legal.targets.zones.grave then
            ix.overlays.grave_select_mode = true
        end
        return ix
    end

    if state.pending_manifest_choice then
        ix.phase = "await_target"
        ix.prompt = "Choose one revealed manifest card."
        ix.armed.target = target_ref_for_slot("manifest", state.pending_manifest_choice.armed_slot)
        append_target_ref(ix.armed.targets, ix.armed.target)
        ix.legal.targets.kind = "manifest_slot"
        ix.legal.targets.slots = state.pending_manifest_choice.legal_slots or {}
        ix.legal.targets.zones.manifest = (#ix.legal.targets.slots > 0)
        ix.advance.enabled = state.pending_manifest_choice.armed_slot ~= nil
        ix.advance.reason = "confirm_target"
        ix.advance.label = "Confirm target"
        return ix
    end

    if state.pending_hidden_choice then
        ix.phase = "await_target"
        ix.prompt = "Choose one hidden card on board."
        ix.armed.target = target_ref_for_card(state, state.pending_hidden_choice.armed_card_id)
        append_target_ref(ix.armed.targets, ix.armed.target)
        ix.legal.targets.kind = "hidden_card"
        ix.legal.targets.cards = state.pending_hidden_choice.legal_card_ids or {}
        ix.legal.targets.zones = zone_flags_from_cards(state, ix.legal.targets.cards)
        ix.advance.enabled = state.pending_hidden_choice.armed_card_id ~= nil
        ix.advance.reason = "confirm_target"
        ix.advance.label = "Confirm target"
        return ix
    end

    if state.pending_unrevealed_choice then
        ix.phase = "await_target"
        ix.prompt = "Choose one not-revealed card on board."
        ix.armed.target = target_ref_for_card(state, state.pending_unrevealed_choice.armed_card_id)
        append_target_ref(ix.armed.targets, ix.armed.target)
        ix.legal.targets.kind = "unrevealed_card"
        ix.legal.targets.cards = state.pending_unrevealed_choice.legal_card_ids or {}
        ix.legal.targets.zones = zone_flags_from_cards(state, ix.legal.targets.cards)
        ix.advance.enabled = state.pending_unrevealed_choice.armed_card_id ~= nil
        ix.advance.reason = "confirm_target"
        ix.advance.label = "Confirm target"
        return ix
    end

    if state.pending_public_choice then
        ix.phase = "await_target"
        ix.prompt = "Choose one revealed minor card."
        ix.armed.target = target_ref_for_card(state, state.pending_public_choice.armed_card_id)
        append_target_ref(ix.armed.targets, ix.armed.target)
        ix.legal.targets.kind = "public_minor_card"
        ix.legal.targets.cards = state.pending_public_choice.legal_card_ids or {}
        ix.legal.targets.zones = zone_flags_from_cards(state, ix.legal.targets.cards)
        ix.advance.enabled = state.pending_public_choice.armed_card_id ~= nil
        ix.advance.reason = "confirm_target"
        ix.advance.label = "Confirm target"
        if ix.legal.targets.zones.grave then
            ix.overlays.grave_select_mode = true
        end
        return ix
    end

    if state.pending_hand_choice then
        ix.phase = "await_target"
        if state.pending_hand_choice.operator == "CYCLE" then
            ix.prompt = "Choose one hand card to discard."
        else
            ix.prompt = "Choose one hand card."
        end
        ix.armed.target = target_ref_for_card(state, state.pending_hand_choice.armed_card_id)
        append_target_ref(ix.armed.targets, ix.armed.target)
        ix.legal.targets.kind = "hand_card"
        ix.legal.targets.cards = state.pending_hand_choice.legal_card_ids or {}
        ix.legal.targets.zones.hand = (#ix.legal.targets.cards > 0)
        ix.advance.enabled = state.pending_hand_choice.armed_card_id ~= nil
        ix.advance.reason = "confirm_target"
        ix.advance.label = "Confirm target"
        return ix
    end

    if state.pending_operator_choice then
        ix.phase = "await_operator"
        ix.prompt = "Choose one operator or none."
        ix.legal.operators = state.pending_operator_choice.choices or {}
        ix.advance.enabled = true
        if state.pending_operator_choice.armed_operator then
            ix.advance.reason = "confirm_operator"
            ix.advance.label = "Confirm operator"
        else
            ix.advance.reason = "discharge"
            ix.advance.label = "Discharge"
        end
        return ix
    end

    if state.committed and state.armed_hand then
        ix.phase = "await_ready"
        ix.prompt = "Press △ to cast."
        ix.legal.commit_slots = occupied_manifest_slots(state)
        ix.legal.hand_cards = legal_hand_cards_from_hints(state)
        ix.advance.enabled = true
        ix.advance.reason = "confirm_turn"
        ix.advance.label = "△ Cast"
        return ix
    end

    if state.committed then
        ix.phase = "await_complete"
        ix.prompt = "Choose a hand card or click to deselect."
        ix.legal.commit_slots = occupied_manifest_slots(state)
        ix.legal.hand_cards = legal_hand_cards_from_hints(state)
        ix.advance.enabled = false
        return ix
    end

    if state.armed_hand then
        ix.phase = "await_complete"
        ix.prompt = "Choose a manifest slot or click to deselect."
        ix.armed.hand_card_id = state.armed_hand
        ix.legal.commit_slots = rules.legal_manifest_slots_for_hand(state, state.armed_hand)
        ix.legal.hand_cards = {}
        ix.advance.enabled = false
        return ix
    end

    if state.pending_trump then
        ix.phase = "await_trump"
        ix.prompt = "Resolve pending trump event."
        ix.advance.enabled = true
        ix.advance.reason = "resolve_trump"
        ix.advance.label = "Resolve trump"
        return ix
    end

    ix.phase = "await_start"
    ix.prompt = "Choose a manifest slot or a hand card."
    ix.legal.commit_slots = occupied_manifest_slots(state)
    ix.advance.enabled = false
    ix.advance.reason = nil
    ix.advance.label = nil
    return ix
end

function M.format(interaction)
    local lines = {}
    local legal = interaction.legal or {}
    local targets = legal.targets or {}
    local armed = interaction.armed or {}
    local armed_target = armed.target
    local armed_target_bits = {}

    local function join(list)
        local out = {}
        for _, value in ipairs(list or {}) do
            out[#out + 1] = tostring(value)
        end
        return table.concat(out, ", ")
    end

    local zone_bits = {}
    for zone_name, enabled in pairs(targets.zones or {}) do
        if enabled then
            zone_bits[#zone_bits + 1] = zone_name
        end
    end
    table.sort(zone_bits)

    lines[#lines + 1] = "INTERACTION"
    lines[#lines + 1] = "phase=" .. tostring(interaction.phase)
    lines[#lines + 1] = "prompt=" .. tostring(interaction.prompt)
    lines[#lines + 1] = string.format(
        "advance=%s reason=%s label=%s",
        interaction.advance and interaction.advance.enabled and "true" or "false",
        tostring(interaction.advance and interaction.advance.reason or "-"),
        tostring(interaction.advance and interaction.advance.label or "-")
    )
    lines[#lines + 1] = string.format(
        "armed hand=%s operator=%s target=%s",
        tostring(armed.hand_card_id or "-"),
        tostring(armed.operator or "-"),
        armed_target and string.format("%s:%s:%s",
            tostring(armed_target.kind or "-"),
            tostring(armed_target.zone or "-"),
            tostring(armed_target.card_id or armed_target.slot or "-")
        ) or "-"
    )
    for _, ref in ipairs(armed.targets or {}) do
        armed_target_bits[#armed_target_bits + 1] = string.format(
            "%s:%s:%s",
            tostring(ref.kind or "-"),
            tostring(ref.zone or "-"),
            tostring(ref.card_id or ref.slot or "-")
        )
    end
    lines[#lines + 1] = "armed_targets=" .. (#armed_target_bits > 0 and table.concat(armed_target_bits, ", ") or "-")
    lines[#lines + 1] = "legal commit_slots=" .. join(legal.commit_slots)
    lines[#lines + 1] = "legal hand_cards=" .. join(legal.hand_cards)
    lines[#lines + 1] = "legal operators=" .. join(legal.operators)
    lines[#lines + 1] = "legal targets.kind=" .. tostring(targets.kind or "-")
    lines[#lines + 1] = "legal targets.cards=" .. join(targets.cards)
    lines[#lines + 1] = "legal targets.slots=" .. join(targets.slots)
    lines[#lines + 1] = "legal targets.zones=" .. table.concat(zone_bits, ", ")
    lines[#lines + 1] = string.format(
        "overlays grave_open=%s grave_select_mode=%s",
        interaction.overlays and interaction.overlays.grave_open and "true" or "false",
        interaction.overlays and interaction.overlays.grave_select_mode and "true" or "false"
    )
    return table.concat(lines, "\n")
end

return M
