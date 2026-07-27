local constants = require("src.core.constants")

local M = {}

local TOPOLOGY_ADJ = {}
for _, op in ipairs(constants.OPERATORS) do
    TOPOLOGY_ADJ[op] = {[op] = true}
end
for _, pair in ipairs(constants.TRUMP_CANON) do
    local a, b = pair[1], pair[2]
    TOPOLOGY_ADJ[a][b] = true
    TOPOLOGY_ADJ[b][a] = true
end

local function topology_adjacent(op_a, op_b)
    return TOPOLOGY_ADJ[op_a] and TOPOLOGY_ADJ[op_a][op_b] or false
end

-- Which operators the installed runtime card grants as extra choices.
-- Lives here rather than in turn.lua because legality now needs it and
-- rules must not depend on turn.
function M.runtime_granted_operators(state)
    local runtime_card_id = state.zones.runtime.cards[1]
    if not runtime_card_id then
        return {}
    end
    local runtime_card = state.cards[runtime_card_id]
    if not runtime_card then
        return {}
    end
    if runtime_card.op_a == "RUNTIME" and runtime_card.op_b == "RUNTIME" then
        return {"RUNTIME"}
    end
    if runtime_card.op_a == "RUNTIME" then
        return {runtime_card.op_b}
    end
    if runtime_card.op_b == "RUNTIME" then
        return {runtime_card.op_a}
    end
    return {runtime_card.op_a, runtime_card.op_b}
end

-- LOGIC_JOKER_LAW: LOGIC is a pass, not an effect. It is available when the
-- hand card carries it or when the installed runtime grants it.
function M.logic_available(state, hand_card_id)
    local hand_card = state.cards[hand_card_id]
    if hand_card and (hand_card.op_a == "LOGIC" or hand_card.op_b == "LOGIC") then
        return true
    end
    for _, op_name in ipairs(M.runtime_granted_operators(state)) do
        if op_name == "LOGIC" then
            return true
        end
    end
    return false
end

-- The single place where move legality is decided. full_pair_fit stays a pure
-- topology function; the joker is a layer above it because it depends on game
-- state, not only on a pair of cards.
function M.move_legal(state, manifest_card, hand_card, hand_card_id)
    if M.full_pair_fit(manifest_card, hand_card) then
        return true
    end
    return M.logic_available(state, hand_card_id)
end

function M.full_pair_fit(manifest_card, hand_card)
    if not manifest_card or not hand_card then
        return false
    end
    return (
        topology_adjacent(manifest_card.op_a, hand_card.op_a) and topology_adjacent(manifest_card.op_b, hand_card.op_b)
    ) or (
        topology_adjacent(manifest_card.op_a, hand_card.op_b) and topology_adjacent(manifest_card.op_b, hand_card.op_a)
    )
end

function M.legal_hand_ids(state, manifest_card_id)
    local result = {}
    local manifest_card = state.cards[manifest_card_id]
    if not manifest_card then
        return result
    end
    for _, hand_card_id in ipairs(state.zones.hand.cards) do
        if M.move_legal(state, manifest_card, state.cards[hand_card_id], hand_card_id) then
            result[#result + 1] = hand_card_id
        end
    end
    return result
end

function M.legal_manifest_slots_for_hand(state, hand_card_id)
    local result = {}
    local hand_card = state.cards[hand_card_id]
    if not hand_card then
        return result
    end
    for slot = 1, state.zones.manifest.slot_count do
        local manifest_card_id = state.zones.manifest.cards[slot]
        if manifest_card_id and state.cards[manifest_card_id] then
            if M.move_legal(state, state.cards[manifest_card_id], hand_card, hand_card_id) then
                result[#result + 1] = slot
            end
        end
    end
    return result
end

return M
