local M = {}

local VALID_INFO_STATES = {
    hidden = true,
    known = true,
    revealed = true,
}

local function new_zone(name, kind, slot_count)
    return {
        name = name,
        kind = kind,
        slot_count = slot_count or 0,
        cards = kind == "slots" and {} or {},
    }
end

local function init_slots(zone)
    for i = 1, zone.slot_count do
        zone.cards[i] = nil
    end
end

function M.new_game()
    local state = {
        cards = {},
        zones = {
            deck = new_zone("deck", "stack"),
            play = new_zone("play", "slots", 1),
            runtime = new_zone("runtime", "slots", 1),
            trump_flow = new_zone("trump_flow", "row"),
            trump = new_zone("trump", "slots", 2),
            targets = new_zone("targets", "slots", 3),
            manifest = new_zone("manifest", "slots", 6),
            latent = new_zone("latent", "slots", 6),
            hand = new_zone("hand", "fan"),
            grave = new_zone("grave", "stack"),
        },
        log = {},
        event_stream = {},
        current_transition = nil,
        last_transition = nil,
        transition_seq = 0,
        rng = nil,
        committed = nil,
        legal_hints = {},
        armed_hand = nil,
        pending_flow_choice = nil,
        pending_encode_choice = nil,
        pending_pair_card_choice = nil,
        pending_public_choice = nil,
        pending_hidden_choice = nil,
        pending_hand_choice = nil,
        pending_manifest_choice = nil,
        pending_unrevealed_choice = nil,
        pending_trump = nil,
        pending_operator_choice = nil,
    }

    for _, zone in pairs(state.zones) do
        if zone.kind == "slots" then
            init_slots(zone)
        end
    end

    return state
end

function M.set_armed_operator(state, op_name)
    local pending = state.pending_operator_choice
    if not pending then
        return nil
    end
    pending.armed_operator = op_name
    return pending.armed_operator
end

function M.push_log(state, text)
    state.log[#state.log + 1] = text
end

function M.set_info_state(state, card_id, info_state)
    local card = state.cards[card_id]
    assert(VALID_INFO_STATES[info_state], "invalid info_state: " .. tostring(info_state))
    card.info_state = info_state
    card.face_up = info_state == "revealed"
end

function M.get_info_state(state, card_id)
    local card = state.cards[card_id]
    return card and card.info_state or nil
end

function M.is_hidden(state, card_id)
    return M.get_info_state(state, card_id) == "hidden"
end

function M.is_known(state, card_id)
    local info_state = M.get_info_state(state, card_id)
    return info_state == "known" or info_state == "revealed"
end

function M.is_revealed(state, card_id)
    return M.get_info_state(state, card_id) == "revealed"
end

function M.hide_card(state, card_id)
    M.set_info_state(state, card_id, "hidden")
end

function M.know_card(state, card_id)
    local info_state = M.get_info_state(state, card_id)
    if info_state == "hidden" then
        M.set_info_state(state, card_id, "known")
    end
end

function M.reveal_card(state, card_id)
    M.set_info_state(state, card_id, "revealed")
end

function M.clear_gameplay_selection(state)
    state.committed = nil
    state.legal_hints = {}
    state.armed_hand = nil
end

function M.sync_zone_cards(state, zone_name)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local card = state.cards[card_id]
                card.zone = zone_name
                card.slot = slot
            end
        end
        return
    end

    for index, card_id in ipairs(zone.cards) do
        local card = state.cards[card_id]
        card.zone = zone_name
        card.slot = index
    end
end

function M.remove_from_current_zone(state, card_id)
    local card = state.cards[card_id]
    if not card or not card.zone then
        return
    end

    local zone = state.zones[card.zone]
    if zone.kind == "slots" then
        zone.cards[card.slot] = nil
    else
        table.remove(zone.cards, card.slot)
    end

    card.zone = nil
    card.slot = nil
    M.sync_zone_cards(state, zone.name)
end

function M.place_card(state, card_id, zone_name, slot)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        zone.cards[slot] = card_id
    else
        zone.cards[#zone.cards + 1] = card_id
    end
    M.sync_zone_cards(state, zone_name)
end

function M.first_open_slot(state, zone_name)
    local zone = state.zones[zone_name]
    if zone.kind ~= "slots" then
        return nil
    end
    for i = 1, zone.slot_count do
        if zone.cards[i] == nil then
            return i
        end
    end
    return nil
end

function M.zone_count(state, zone_name)
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        local n = 0
        for i = 1, zone.slot_count do
            if zone.cards[i] ~= nil then
                n = n + 1
            end
        end
        return n
    end
    return #zone.cards
end

function M.is_zone_closed(state, zone_name)
    local zone = state.zones[zone_name]
    if zone.kind ~= "slots" then
        return #zone.cards > 0
    end
    for i = 1, zone.slot_count do
        if zone.cards[i] == nil then
            return false
        end
    end
    return true
end

function M.is_board_closed(state)
    return M.is_zone_closed(state, "manifest")
        and M.is_zone_closed(state, "latent")
        and M.is_zone_closed(state, "targets")
end

return M
