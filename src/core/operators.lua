local draw = require("src.core.draw")
local transition = require("src.core.transition")

local M = {}

local function resolve_connect(state)
    transition.emit(state, "operator_effect_begin", {
        operator = "CONNECT",
    })
    draw.draw_to_hand(state)
    draw.draw_to_hand(state)
    transition.emit(state, "operator_effect_end", {
        operator = "CONNECT",
    })
end

function M.resolve_cycle_draw(state)
    transition.emit(state, "operator_effect_begin", {
        operator = "CYCLE",
    })
    draw.draw_to_hand(state)
end

function M.finish_cycle(state, discarded_card_id)
    transition.emit(state, "operator_effect_end", {
        operator = "CYCLE",
        discarded_card_id = discarded_card_id,
    })
end

function M.finish_observe(state, observed_card_id)
    transition.emit(state, "operator_effect_end", {
        operator = "OBSERVE",
        observed_card_id = observed_card_id,
    })
end

function M.resolve(state, op_name)
    if op_name == "CONNECT" then
        resolve_connect(state)
        return
    end

    transition.emit(state, "operator_effect_stub", {
        operator = op_name,
    })
end

return M
