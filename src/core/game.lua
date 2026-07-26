local state_lib = require("src.core.state")
local setup = require("src.core.setup")
local inspect = require("src.core.inspect")
local interaction = require("src.core.interaction")
local transition = require("src.core.transition")
local turn = require("src.core.turn")
local draw = require("src.core.draw")
local trump = require("src.core.trump")
local rules = require("src.core.rules")

local M = {}

local function list_contains(list, value)
    for _, item in ipairs(list or {}) do
        if item == value then
            return true
        end
    end
    return false
end

local function deep_copy(value, seen)
    if type(value) ~= "table" then
        return value
    end
    seen = seen or {}
    if seen[value] then
        return seen[value]
    end
    local out = {}
    seen[value] = out
    for k, v in pairs(value) do
        out[deep_copy(k, seen)] = deep_copy(v, seen)
    end
    return out
end

local function count_hidden_trumps(state)
    local total = 0
    for _, zone_name in ipairs({"latent", "targets"}) do
        local zone = state.zones[zone_name]
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local card = state.cards[card_id]
                if card and card.class == "trump" and card.info_state == "hidden" then
                    total = total + 1
                end
            end
        end
    end
    return total
end

local function count_operator_in_zone(state, zone_name, operator)
    local total = 0
    local zone = state.zones[zone_name]
    if zone.kind == "slots" then
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id then
                local card = state.cards[card_id]
                if card.class == "minor" and (card.op_a == operator or card.op_b == operator) then
                    total = total + 1
                end
            end
        end
        return total
    end
    for _, card_id in ipairs(zone.cards) do
        local card = state.cards[card_id]
        if card.class == "minor" and (card.op_a == operator or card.op_b == operator) then
            total = total + 1
        end
    end
    return total
end

local function append_action(list, action)
    list[#list + 1] = action
end

function M.new()
    return state_lib.new_game()
end

function M.start_game(state, opts)
    transition.begin(state, "start_game", {})
    setup.start_game(state, opts)
    transition.emit(state, "setup_complete", {
        deck = #state.zones.deck.cards,
        hand = #state.zones.hand.cards,
        manifest = state_lib.zone_count(state, "manifest"),
        latent = state_lib.zone_count(state, "latent"),
        targets = state_lib.zone_count(state, "targets"),
    })
    return transition.finish(state, {
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.snapshot(state)
    return inspect.snapshot(state)
end

function M.interaction(state)
    return interaction.read(state)
end

function M.interaction_text(state)
    return interaction.format(interaction.read(state))
end

function M.advance(state)
    local ix = interaction.read(state)

    if ix.phase == "await_ready" then
        if not state.committed or not state.armed_hand then
            transition.begin(state, "advance", {phase = ix.phase})
            return transition.finish(state, {error = "selection_incomplete"})
        end
        return turn.resolve_turn(state, state.committed.slot, state.armed_hand)
    end

    if ix.phase == "await_operator" then
        return M.confirm_operator_phase(state)
    end

    if ix.phase == "await_target" then
        if state.pending_flow_choice then
            return M.confirm_flow_target(state)
        end
        if state.pending_encode_choice then
            return M.confirm_encode_target(state)
        end
        if state.pending_pair_card_choice then
            return M.confirm_pair_card_target(state)
        end
        if state.pending_manifest_choice then
            return M.confirm_manifest_target(state)
        end
        if state.pending_hidden_choice then
            return M.confirm_hidden_target(state)
        end
        if state.pending_unrevealed_choice then
            return M.confirm_unrevealed_target(state)
        end
        if state.pending_public_choice then
            return M.confirm_public_target(state)
        end
        if state.pending_hand_choice then
            return M.confirm_hand_target(state)
        end
        transition.begin(state, "advance", {phase = ix.phase})
        return transition.finish(state, {error = "missing_target_phase"})
    end

    if ix.phase == "await_trump" then
        return M.resolve_pending_trump(state)
    end

    transition.begin(state, "advance", {phase = ix.phase})
    return transition.finish(state, {error = "advance_not_available"})
end

function M.apply_action(state, action)
    if type(action) ~= "table" then
        transition.begin(state, "apply_action", {})
        return transition.finish(state, {error = "invalid_action"})
    end

    local kind = action.kind
    if kind == "commit_manifest" then
        return M.commit_manifest(state, action.slot)
    end
    if kind == "arm_hand" then
        return M.arm_hand(state, action.card_id)
    end
    if kind == "clear_selection" then
        local ix = interaction.read(state)
        transition.begin(state, "clear_selection", {phase = ix.phase})
        if not (ix.legal and ix.legal.clears and ix.legal.clears.selection) then
            return transition.finish(state, {error = "clear_selection_not_available"})
        end
        turn.clear_selection(state)
        return transition.finish(state, {})
    end
    if kind == "clear_committed" then
        local ix = interaction.read(state)
        transition.begin(state, "clear_committed", {phase = ix.phase})
        if not (ix.legal and ix.legal.clears and ix.legal.clears.committed) then
            return transition.finish(state, {error = "clear_committed_not_available"})
        end
        turn.clear_committed(state)
        return transition.finish(state, {})
    end
    if kind == "clear_armed" then
        local ix = interaction.read(state)
        transition.begin(state, "clear_armed", {phase = ix.phase})
        if not (ix.legal and ix.legal.clears and ix.legal.clears.armed) then
            return transition.finish(state, {error = "clear_armed_not_available"})
        end
        turn.clear_armed(state)
        return transition.finish(state, {})
    end
    if kind == "arm_operator" then
        return M.arm_operator(state, action.operator)
    end
    if kind == "arm_direction" then
        if state.pending_flow_choice then
            return M.arm_flow_direction(state, action.direction)
        end
        transition.begin(state, "apply_action", {kind = kind})
        return transition.finish(state, {error = "no_pending_direction_phase"})
    end
    if kind == "arm_target" then
        local target = action.target or {}
        if state.pending_flow_choice then
            return M.arm_flow_target(state, target.card_id)
        end
        if state.pending_encode_choice then
            return M.arm_encode_target(state, target.card_id)
        end
        if state.pending_pair_card_choice then
            return M.arm_pair_card_target(state, target.card_id)
        end
        if state.pending_manifest_choice then
            return M.arm_manifest_target(state, target.slot)
        end
        if state.pending_hidden_choice then
            return M.arm_hidden_target(state, target.card_id)
        end
        if state.pending_unrevealed_choice then
            return M.arm_unrevealed_target(state, target.card_id)
        end
        if state.pending_public_choice then
            return M.arm_public_target(state, target.card_id)
        end
        if state.pending_hand_choice then
            return M.arm_hand_target(state, target.card_id)
        end
        transition.begin(state, "apply_action", {kind = kind})
        return transition.finish(state, {error = "no_pending_target_phase"})
    end
    if kind == "advance" then
        return M.advance(state)
    end
    if kind == "draw" then
        return M.draw_to_hand(state)
    end
    if kind == "resolve_pending_trump" then
        return M.resolve_pending_trump(state)
    end

    transition.begin(state, "apply_action", {kind = tostring(kind)})
    return transition.finish(state, {error = "unknown_action"})
end

function M.commit_manifest(state, slot)
    transition.begin(state, "commit_manifest", {slot = slot})
    local legal, err = turn.commit_manifest(state, slot)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "commit_manifest", {
        slot = slot,
        card_id = state.committed and state.committed.card_id or nil,
        legal = legal,
    })
    return transition.finish(state, {legal = legal})
end

function M.arm_hand(state, card_id)
    local ix = interaction.read(state)
    transition.begin(state, "arm_hand", {
        card_id = card_id,
        phase = ix.phase,
    })
    if not (ix.phase == "await_start" or ix.phase == "await_complete" or ix.phase == "await_ready") then
        return transition.finish(state, {error = "arm_hand_not_available"})
    end
    if not list_contains(ix.legal and ix.legal.hand_cards or {}, card_id) then
        return transition.finish(state, {error = "illegal_hand_card"})
    end
    local armed, err = turn.arm_hand(state, card_id)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "arm_hand", {
        card_id = card_id,
        armed = armed,
    })
    return transition.finish(state, {armed = armed})
end

function M.reorder_hand(state, card_id, index)
    transition.begin(state, "reorder_hand", {
        card_id = card_id,
        index = index,
    })
    local insert_at, err = turn.reorder_hand(state, card_id, index)
    if err then
        return transition.finish(state, {error = err})
    end
    transition.emit(state, "reorder_hand", {
        card_id = card_id,
        index = insert_at,
    })
    return transition.finish(state, {index = insert_at})
end

function M.resolve_turn(state, slot, hand_card_id)
    return turn.resolve_turn(state, slot, hand_card_id)
end

function M.choose_operator(state, op_name)
    return turn.choose_operator(state, op_name)
end

function M.arm_operator(state, op_name)
    return turn.arm_operator(state, op_name)
end

function M.confirm_operator_phase(state)
    return turn.confirm_operator_phase(state)
end

function M.choose_manifest_target(state, slot)
    return turn.choose_manifest_target(state, slot)
end

function M.arm_manifest_target(state, slot)
    return turn.arm_manifest_target(state, slot)
end

function M.confirm_manifest_target(state)
    return turn.confirm_manifest_target(state)
end

function M.choose_public_target(state, card_id)
    return turn.choose_public_target(state, card_id)
end

function M.arm_public_target(state, card_id)
    return turn.arm_public_target(state, card_id)
end

function M.choose_pair_card_target(state, card_id)
    return turn.choose_pair_card_target(state, card_id)
end

function M.arm_pair_card_target(state, card_id)
    return turn.arm_pair_card_target(state, card_id)
end

function M.confirm_pair_card_target(state)
    return turn.confirm_pair_card_target(state)
end

function M.arm_flow_target(state, card_id)
    return turn.arm_flow_target(state, card_id)
end

function M.arm_flow_direction(state, direction)
    return turn.arm_flow_direction(state, direction)
end

function M.confirm_flow_target(state)
    return turn.confirm_flow_target(state)
end

function M.arm_encode_target(state, card_id)
    return turn.arm_encode_target(state, card_id)
end

function M.confirm_encode_target(state)
    return turn.confirm_encode_target(state)
end

function M.confirm_public_target(state)
    return turn.confirm_public_target(state)
end

function M.choose_hand_target(state, card_id)
    return turn.choose_hand_target(state, card_id)
end

function M.arm_hand_target(state, card_id)
    return turn.arm_hand_target(state, card_id)
end

function M.confirm_hand_target(state)
    return turn.confirm_hand_target(state)
end

function M.choose_hidden_target(state, card_id)
    return turn.choose_hidden_target(state, card_id)
end

function M.arm_hidden_target(state, card_id)
    return turn.arm_hidden_target(state, card_id)
end

function M.confirm_hidden_target(state)
    return turn.confirm_hidden_target(state)
end

function M.choose_unrevealed_target(state, card_id)
    return turn.choose_unrevealed_target(state, card_id)
end

function M.arm_unrevealed_target(state, card_id)
    return turn.arm_unrevealed_target(state, card_id)
end

function M.confirm_unrevealed_target(state)
    return turn.confirm_unrevealed_target(state)
end

function M.draw_to_hand(state)
    transition.begin(state, "draw_to_hand", {})
    local card_id, err = draw.draw_to_hand(state)
    trump.refresh_pending_trump(state)
    return transition.finish(state, {
        card_id = card_id,
        error = err,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.resolve_pending_trump(state)
    transition.begin(state, "resolve_pending_trump", {})
    local card_id, err = trump.resolve_pending_trump(state)
    trump.refresh_pending_trump(state)
    return transition.finish(state, {
        card_id = card_id,
        error = err,
        pending_trump = state.pending_trump,
        board_closed = state_lib.is_board_closed(state),
    })
end

function M.clone(state)
    return deep_copy(state)
end

function M.check_fit(state, hand_card_id, manifest_card_id)
    local hand_card = state.cards[hand_card_id]
    local manifest_card = state.cards[manifest_card_id]
    if not hand_card or not manifest_card then
        return {
            ok = false,
            error = "missing_card",
        }
    end
    return {
        ok = true,
        hand_card_id = hand_card_id,
        manifest_card_id = manifest_card_id,
        fits = rules.full_pair_fit(manifest_card, hand_card),
    }
end

function M.enumerate_legal_actions(state)
    local ix = interaction.read(state)
    local actions = {}
    local clears = ix.legal and ix.legal.clears or {}

    if ix.phase == "await_start" or ix.phase == "await_complete" or ix.phase == "await_ready" then
        for _, slot in ipairs(ix.legal.commit_slots or {}) do
            append_action(actions, {kind = "commit_manifest", slot = slot})
        end
        for _, card_id in ipairs(ix.legal.hand_cards or {}) do
            append_action(actions, {kind = "arm_hand", card_id = card_id})
        end
    elseif ix.phase == "await_operator" then
        for _, operator in ipairs(ix.legal.operators or {}) do
            append_action(actions, {kind = "arm_operator", operator = operator})
        end
        append_action(actions, {kind = "arm_operator", operator = nil})
    elseif ix.phase == "await_target" then
        for _, direction in ipairs(ix.legal.directions or {}) do
            append_action(actions, {kind = "arm_direction", direction = direction})
        end
        for _, slot in ipairs(ix.legal.targets and ix.legal.targets.slots or {}) do
            append_action(actions, {kind = "arm_target", target = {zone = "manifest", slot = slot}})
        end
        for _, card_id in ipairs(ix.legal.targets and ix.legal.targets.cards or {}) do
            local card = state.cards[card_id]
            append_action(actions, {
                kind = "arm_target",
                target = {
                    zone = card and card.zone or nil,
                    slot = card and card.slot or nil,
                    card_id = card_id,
                },
            })
        end
    elseif ix.phase == "await_trump" then
        append_action(actions, {kind = "resolve_pending_trump"})
    end

    if clears.selection then
        append_action(actions, {kind = "clear_selection"})
    end
    if clears.committed then
        append_action(actions, {kind = "clear_committed"})
    end
    if clears.armed then
        append_action(actions, {kind = "clear_armed"})
    end
    if ix.advance and ix.advance.enabled then
        append_action(actions, {kind = "advance"})
    end

    return actions
end

function M.predict(state, action_or_actions)
    local sandbox = M.clone(state)
    local actions = action_or_actions
    if type(actions) ~= "table" or actions.kind then
        actions = {action_or_actions}
    end

    local transitions = {}
    for _, action in ipairs(actions) do
        local result = M.apply_action(sandbox, action)
        transitions[#transitions + 1] = result
        if result.summary and result.summary.error then
            return {
                ok = false,
                error = result.summary.error,
                state = sandbox,
                snapshot = inspect.snapshot(sandbox),
                interaction = interaction.read(sandbox),
                transition = result,
                transitions = transitions,
                events = transition.drain_events(sandbox),
            }
        end
    end

    return {
        ok = true,
        state = sandbox,
        snapshot = inspect.snapshot(sandbox),
        interaction = interaction.read(sandbox),
        transition = sandbox.last_transition,
        transitions = transitions,
        events = transition.drain_events(sandbox),
    }
end

function M.evaluate_state(state)
    local ix = interaction.read(state)
    local hand_count = #state.zones.hand.cards
    local deck_count = #state.zones.deck.cards
    local grave_count = #state.zones.grave.cards
    local hidden_trumps = count_hidden_trumps(state)
    local connect_in_hand = count_operator_in_zone(state, "hand", "CONNECT")
    local connect_in_manifest = count_operator_in_zone(state, "manifest", "CONNECT")
    local legal_actions = M.enumerate_legal_actions(state)
    local board_closed = state_lib.is_board_closed(state)

    local score =
        hand_count * 12 +
        deck_count * 0.25 +
        connect_in_hand * 18 +
        connect_in_manifest * 8 +
        #legal_actions * 1.5 +
        (board_closed and 15 or -25) +
        hidden_trumps * 6 -
        grave_count * 0.1 -
        #state.zones.trump_flow.cards * 4

    return {
        score = score,
        hand_count = hand_count,
        deck_count = deck_count,
        grave_count = grave_count,
        hidden_trumps = hidden_trumps,
        connect_in_hand = connect_in_hand,
        connect_in_manifest = connect_in_manifest,
        legal_action_count = #legal_actions,
        board_closed = board_closed,
        phase = ix.phase,
        pending_trump = state.pending_trump,
    }
end

function M.drain_events(state)
    return transition.drain_events(state)
end

function M.last_transition(state)
    return state.last_transition
end

return M
