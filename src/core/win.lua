-- Victory module. WIN_MODULE_LAW, WIN_MODULE_SLICE_2026-07-29.
--
-- This is a judge, not a machine. A machine acts; this one answers.
--
-- One entrance, two petitioners:
--
--     win.request(state, {signature = "TURN"})     -- the turn asks
--     win.request(state, {signature = "ENOUGH"})   -- a trump claims
--
-- Everything follows from the single door. The "already decided" guard sits
-- in one place, so a recorded outcome cannot be overwritten -- not because we
-- remembered to guard the second writer, but because there is no second
-- writer.
--
-- Rights (WIN_MODULE_LAW §3):
--
--     board     read only, not one card is moved
--     outcome   this module's own field, and only it writes there
--
-- Ending the game is not a move: it does not touch a card, it answers the
-- board. The module never requires draw, repair, turn or trump, and never
-- calls a state mutator. That is check 11, and it is a grep rather than a
-- promise.

local state_lib = require("src.core.state")
local transition = require("src.core.transition")
-- WIN_MODULE_SLICE §12: rules is pure topology and moves nothing, so reading it
-- keeps the read-only guarantee. It was never on the §11.3 forbidden list.
local rules = require("src.core.rules")

local M = {}

-- name -> predicate(state) -> outcome | nil
M.predicates = {}

-- Predicates raised by the turn itself rather than by a claimant, in the
-- order they are tried. WIN_MODULE_LAW §4 calls the list of ways to win open,
-- so this is a set and not one hardcoded name.
M.unsigned = {"pattern"}

-- Unsigned DEFEAT predicates, in the order they are tried. A separate list from
-- M.unsigned on purpose: victory and defeat must never share a queue, because
-- then precedence would be one editable line again. Precedence lives in the
-- order the turn calls the two steps -- TURN_STEP_LAW §11.
M.terminal = {"no_legal_move"}

function M.is_over(state)
    return state.outcome ~= nil
end

--------------------------------------------------------------------------
-- pattern predicate (WIN_MODULE_LAW §5)
--------------------------------------------------------------------------

-- The trio in target slots 1..3 unrolls into six glyphs in slot order.
--
-- A hidden card does not compile: while it is concealed nobody knows it is a
-- trump. is_known covers known and revealed, and the target zone is the only
-- zone where a trump can sit as known -- anywhere else a revealed trump
-- leaves for the trump flow.
local function compiled_sequence(state)
    local seq = {}
    for slot = 1, 3 do
        local card_id = state.zones.targets.cards[slot]
        local card = card_id and state.cards[card_id]
        if not card
            or card.class ~= "trump"
            or not state_lib.is_known(state, card_id) then
            return nil
        end
        seq[#seq + 1] = card.op_a
        seq[#seq + 1] = card.op_b
    end
    return seq
end

-- One row for all six. Mixing is what separates the implemented law from
-- "six matches anywhere".
local function matches_row(state, seq, row)
    local manifest = state.zones.manifest
    for slot = 1, #seq do
        local card_id = manifest.cards[slot]
        local card = card_id and state.cards[card_id]
        if not card or card[row] ~= seq[slot] then
            return false
        end
    end
    return true
end

M.predicates.pattern = function(state)
    local seq = compiled_sequence(state)
    if not seq then
        return nil
    end
    if matches_row(state, seq, "op_a") then
        return {kind = "victory", by = "pattern", reading = "upper"}
    end
    if matches_row(state, seq, "op_b") then
        return {kind = "victory", by = "pattern", reading = "lower"}
    end
    return nil
end

--------------------------------------------------------------------------
-- ENOUGH predicate (claimed, not raised by the turn)
--------------------------------------------------------------------------

-- ENOUGH §3: count revealed cards in manifest chain and latent layer, compare
-- with hand. The predicate is a pure read of the stabilised board; repair
-- timing belongs to whoever calls, not here.
M.predicates.ENOUGH = function(state)
    local revealed = 0
    for _, zone_name in ipairs({"manifest", "latent"}) do
        local zone = state.zones[zone_name]
        for slot = 1, zone.slot_count do
            local card_id = zone.cards[slot]
            if card_id and state_lib.is_revealed(state, card_id) then
                revealed = revealed + 1
            end
        end
    end
    if revealed ~= #state.zones.hand.cards then
        return nil
    end
    return {kind = "victory", by = "ENOUGH", reading = nil}
end

--------------------------------------------------------------------------
-- reading without writing
--------------------------------------------------------------------------

function M.check(state, name)
    local predicate = M.predicates[name]
    if not predicate then
        return nil
    end
    return predicate(state)
end

-- TURN_STEP_LAW §11. An empty hand is a special case of this and needs no
-- branch: rules.any_legal_move returns false for it through the same loop.
M.predicates.no_legal_move = function(state)
    if rules.any_legal_move(state) then
        return nil
    end
    return {kind = "defeat", by = "no_legal_move"}
end

function M.check_terminal(state)
    for _, name in ipairs(M.terminal) do
        local outcome = M.check(state, name)
        if outcome then
            return outcome
        end
    end
    return nil
end

function M.check_unsigned(state)
    for _, name in ipairs(M.unsigned) do
        local outcome = M.check(state, name)
        if outcome then
            return outcome
        end
    end
    return nil
end

--------------------------------------------------------------------------
-- the only entrance
--------------------------------------------------------------------------

function M.request(state, req)
    if M.is_over(state) then
        return nil, "already_over"
    end

    local signature = req and req.signature
    if not signature then
        return nil, "unsigned_request"
    end

    local outcome
    if signature == "TURN_WIN" then
        -- The machine does not claim, it asks.
        outcome = M.check_unsigned(state)
    elseif signature == "TURN_LOSE" then
        -- A separate list, deliberately. Mixing them would put precedence back
        -- into row order after it was moved into step order.
        outcome = M.check_terminal(state)
    else
        local predicate = M.predicates[signature]
        if not predicate then
            return nil, "unknown_claimant"
        end
        outcome = predicate(state)
        if not outcome then
            -- A claimant asserting something that is not so is a DEFECT, not
            -- an ordinary refusal, so it is loud.
            transition.emit(state, "win_claim_rejected", {
                signature = signature,
                basis = req.basis,
            })
            return nil, "claim_not_verified"
        end
    end

    if not outcome then
        return nil
    end

    -- An unsigned predicate names itself; a claimant is named by its
    -- signature.
    outcome.by = outcome.by or signature
    outcome.seq = state.transition_seq

    state.outcome = outcome
    transition.emit(state, outcome.kind == "defeat" and "game_lost" or "game_won", {
        by = outcome.by,
        reading = outcome.reading,
    })
    return outcome
end

return M
