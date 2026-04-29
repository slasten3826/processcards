local constants = require("src.core.constants")

local M = {}

local function minor_pair_from_index(index)
    local ops = constants.OPERATORS
    local count = #ops
    local zero = index - 1
    local a = ops[(zero % count) + 1]
    local b = ops[(math.floor(zero / count) % count) + 1]
    return a, b
end

local function trump_pair_from_index(index)
    local pair = constants.TRUMP_CANON[index]
    return pair[1], pair[2]
end

function M.create_card_store()
    return {}
end

function M.create_minor(store, index)
    local id = string.format("MINOR-%d", index)
    local op_a, op_b = minor_pair_from_index(index)
    store[id] = {
        id = id,
        class = "minor",
        op_a = op_a,
        op_b = op_b,
        info_state = "hidden",
        face_up = false,
        zone = nil,
        slot = nil,
    }
    return id
end

function M.create_trump(store, index)
    local id = string.format("TRUMP-%d", index)
    local op_a, op_b = trump_pair_from_index(index)
    store[id] = {
        id = id,
        class = "trump",
        op_a = op_a,
        op_b = op_b,
        trump_name = constants.TRUMP_NAMES[index],
        info_state = "hidden",
        face_up = false,
        zone = nil,
        slot = nil,
    }
    return id
end

function M.append_minor_deck(store, target)
    for i = 1, 100 do
        target[#target + 1] = M.create_minor(store, i)
    end
end

function M.append_trump_deck(store, target)
    for i = 1, 22 do
        target[#target + 1] = M.create_trump(store, i)
    end
end

return M
