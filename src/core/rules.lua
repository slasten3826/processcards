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
        if M.full_pair_fit(manifest_card, state.cards[hand_card_id]) then
            result[#result + 1] = hand_card_id
        end
    end
    return result
end

return M
