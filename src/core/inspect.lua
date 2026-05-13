local state_lib = require("src.core.state")

local M = {}

local function join_cards(cards)
    local out = {}
    for _, card_id in ipairs(cards) do
        out[#out + 1] = card_id
    end
    return table.concat(out, ", ")
end

local function join_slots(zone)
    local out = {}
    for i = 1, zone.slot_count do
        out[#out + 1] = string.format("%d:%s", i, zone.cards[i] or "-")
    end
    return table.concat(out, " | ")
end

function M.snapshot(state)
    local lines = {}
    lines[#lines + 1] = "STATE SNAPSHOT"
    lines[#lines + 1] = string.format(
        "board_closed=%s deck=%d hand=%d grave=%d trump_flow=%d pending_operator=%s armed_operator=%s pending_flow=%s pending_encode=%s pending_pair=%s pending_public=%s pending_hidden=%s pending_hand=%s pending_manifest=%s pending_unrevealed=%s pending_trump=%s",
        state_lib.is_board_closed(state) and "true" or "false",
        #state.zones.deck.cards,
        #state.zones.hand.cards,
        #state.zones.grave.cards,
        #state.zones.trump_flow.cards,
        state.pending_operator_choice and "yes" or "no",
        state.pending_operator_choice and (state.pending_operator_choice.armed_operator or "none") or "-",
        state.pending_flow_choice and "yes" or "no",
        state.pending_encode_choice and "yes" or "no",
        state.pending_pair_card_choice and "yes" or "no",
        state.pending_public_choice and "yes" or "no",
        state.pending_hidden_choice and "yes" or "no",
        state.pending_hand_choice and "yes" or "no",
        state.pending_manifest_choice and "yes" or "no",
        state.pending_unrevealed_choice and "yes" or "no",
        state.pending_trump and "yes" or "no"
    )
    lines[#lines + 1] = "manifest: " .. join_slots(state.zones.manifest)
    lines[#lines + 1] = "latent:   " .. join_slots(state.zones.latent)
    lines[#lines + 1] = "targets:  " .. join_slots(state.zones.targets)
    lines[#lines + 1] = "trump:    " .. join_slots(state.zones.trump)
    lines[#lines + 1] = "play:     " .. join_slots(state.zones.play)
    lines[#lines + 1] = "runtime:  " .. join_slots(state.zones.runtime)
    lines[#lines + 1] = "hand:     " .. join_cards(state.zones.hand.cards)
    lines[#lines + 1] = "grave:    " .. join_cards(state.zones.grave.cards)
    lines[#lines + 1] = "flow:     " .. join_cards(state.zones.trump_flow.cards)
    if state.pending_flow_choice then
        lines[#lines + 1] = "armed_flow_card: " .. tostring(state.pending_flow_choice.armed_card_id or "-")
        lines[#lines + 1] = "armed_flow_direction: " .. tostring(state.pending_flow_choice.armed_direction or "-")
    end
    if state.pending_encode_choice then
        lines[#lines + 1] = "armed_encode_first: " .. tostring(state.pending_encode_choice.armed_first_card_id or "-")
        lines[#lines + 1] = "armed_encode_second: " .. tostring(state.pending_encode_choice.armed_second_card_id or "-")
    end
    if state.pending_manifest_choice then
        lines[#lines + 1] = "armed_manifest_slot: " .. tostring(state.pending_manifest_choice.armed_slot or "-")
    end
    if state.pending_pair_card_choice then
        lines[#lines + 1] = "armed_pair_public: " .. tostring(state.pending_pair_card_choice.armed_public_card_id or "-")
        lines[#lines + 1] = "armed_pair_hand: " .. tostring(state.pending_pair_card_choice.armed_hand_card_id or "-")
    end
    if state.pending_public_choice then
        lines[#lines + 1] = "armed_public_card: " .. tostring(state.pending_public_choice.armed_card_id or "-")
    end
    if state.pending_hidden_choice then
        lines[#lines + 1] = "armed_hidden_card: " .. tostring(state.pending_hidden_choice.armed_card_id or "-")
    end
    if state.pending_unrevealed_choice then
        lines[#lines + 1] = "armed_unrevealed_card: " .. tostring(state.pending_unrevealed_choice.armed_card_id or "-")
    end
    if state.pending_hand_choice then
        lines[#lines + 1] = "armed_hand_target: " .. tostring(state.pending_hand_choice.armed_card_id or "-")
    end
    return table.concat(lines, "\n")
end

return M
