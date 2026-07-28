local draw = require("src.core.draw")
local transition = require("src.core.transition")

local M = {}

-- TURN_STEP_LAW: every operator declares the step it resolves on.
-- Three binding points cover all ten. An operator with no declared step
-- binds to EFFECT.
M.descriptors = {
    FLOW     = {step = "EFFECT"},
    CONNECT  = {step = "EFFECT"},
    DISSOLVE = {step = "BURN"},
    ENCODE   = {step = "EFFECT"},
    CHOOSE   = {step = "EFFECT"},
    OBSERVE  = {step = "EFFECT"},
    LOGIC    = {step = "LEGALITY"},
    CYCLE    = {step = "EFFECT"},
    RUNTIME  = {step = "EFFECT"},
    MANIFEST = {step = "EFFECT"},
}

function M.step_of(op_name)
    local descriptor = M.descriptors[op_name]
    return descriptor and descriptor.step or "EFFECT"
end


local function resolve_connect(state)
    transition.emit(state, "operator_effect_begin", {
        operator = "CONNECT",
    })
    draw.draw_to_hand(state)
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

function M.finish_dissolve(state, dissolved_card_id)
    transition.emit(state, "operator_effect_end", {
        operator = "DISSOLVE",
        dissolved_card_id = dissolved_card_id,
    })
end

function M.finish_encode(state, first_card_id, second_card_id)
    transition.emit(state, "operator_effect_end", {
        operator = "ENCODE",
        first_card_id = first_card_id,
        second_card_id = second_card_id,
    })
end

function M.finish_flow(state, zone, direction)
    transition.emit(state, "operator_effect_end", {
        operator = "FLOW",
        zone = zone,
        direction = direction,
    })
end

function M.finish_logic(state, target_card_id, inserted_card_id)
    transition.emit(state, "operator_effect_end", {
        operator = "LOGIC",
        target_card_id = target_card_id,
        inserted_card_id = inserted_card_id,
    })
end

function M.finish_runtime(state, installed_card_id, granted_operators)
    transition.emit(state, "operator_effect_end", {
        operator = "RUNTIME",
        installed_card_id = installed_card_id,
        granted_operators = granted_operators,
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
