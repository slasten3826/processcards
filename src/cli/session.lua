-- Persistent play session for machines.
--
-- MACHINE_CLI_SLICE §1: a session is stored as a JOURNAL, not as state.
--
--     session = seed + trump mode + an ordered list of entries
--
-- Every command loads the journal, starts a fresh game from the seed and
-- replays the journal in full. Nothing derived from state is ever written to
-- disk. Consequences, all of them the reason for this design:
--
--     determinism   holds by construction, not by check
--     undo          is free: drop the tail and replay
--     plant         is reproducible on the same footing as a move
--     format        one line per entry, so it reads and it diffs
--
-- The cost is one replay per command. At a hundred entries that is nothing.

local core = require("src.core.game")
local view = require("src.core.view")
local rng = require("src.sim.rng")
local state_lib = require("src.core.state")
local draw = require("src.core.draw")

local M = {}

M.dir = ".session"

-- Zones a card may be planted into, and the information state natural to each.
-- MACHINE_CLI_SLICE §7.
local ZONE_NATURAL_STATE = {
    manifest = "revealed",
    hand = "revealed",
    grave = "revealed",
    runtime = "revealed",
    trump = "revealed",
    play = "revealed",
    trump_flow = "revealed",
    latent = "hidden",
    targets = "hidden",
    deck = "hidden",
}

-- Which refill closes a hole left in each zone. Zones absent from this table
-- do not refill: their size is not fixed, so no hole exists.
local ZONE_REFILL = {
    manifest = "open",
    latent = "concealed",
    targets = "concealed",
}

function M.path(name)
    return M.dir .. "/" .. (name or "current") .. ".log"
end

local function ensure_dir()
    os.execute("mkdir -p " .. M.dir)
end

--------------------------------------------------------------------------
-- journal
--------------------------------------------------------------------------

function M.new_log(seed, trumps)
    return {
        seed = seed or 1,
        trumps = trumps or "full",
        entries = {},
    }
end

function M.read(name)
    local file = io.open(M.path(name), "r")
    if not file then
        return nil, "no_session"
    end
    local log = nil
    for line in file:lines() do
        if not log then
            local seed, trumps = line:match("^#%s*seed=(%-?%d+)%s+trumps=(%S+)")
            if not seed then
                file:close()
                return nil, "bad_header"
            end
            log = M.new_log(tonumber(seed), trumps)
        elseif line ~= "" then
            local kind, text = line:match("^(%S+)%s+(.*)$")
            if kind ~= "do" and kind ~= "plant" then
                file:close()
                return nil, "bad_entry:" .. line
            end
            log.entries[#log.entries + 1] = {kind = kind, text = text}
        end
    end
    file:close()
    if not log then
        return nil, "empty_session"
    end
    return log
end

function M.write(log, name)
    ensure_dir()
    local file, err = io.open(M.path(name), "w")
    if not file then
        return nil, err
    end
    file:write(string.format("# seed=%d trumps=%s\n", log.seed, log.trumps))
    for _, entry in ipairs(log.entries) do
        file:write(entry.kind .. " " .. entry.text .. "\n")
    end
    file:close()
    return true
end

function M.drop(name)
    return os.remove(M.path(name))
end

function M.append(log, kind, text, name)
    log.entries[#log.entries + 1] = {kind = kind, text = text}
    return M.write(log, name)
end

--------------------------------------------------------------------------
-- action grammar (MACHINE_CLI_SLICE §5)
--------------------------------------------------------------------------

local CLEAR_KINDS = {
    selection = "clear_selection",
    committed = "clear_committed",
    armed = "clear_armed",
}

-- The observation is needed only to turn a handle into a card id. It is built
-- from the position the action is about to be applied to, so the same journal
-- text resolves to the same card on every replay.
function M.parse_action(game, text)
    local head, rest = text:match("^(%a+):(.+)$")
    head = head or text

    if head == "advance" then
        return {kind = "advance"}
    end
    if head == "trump" then
        return {kind = "resolve_pending_trump"}
    end
    if head == "draw" then
        return {kind = "draw"}
    end
    if head == "commit" then
        local slot = tonumber(rest)
        if not slot then
            return nil, "commit_needs_slot"
        end
        return {kind = "commit_manifest", slot = slot}
    end
    if head == "hand" then
        return {kind = "arm_hand", card_id = rest}
    end
    if head == "op" then
        return {kind = "arm_operator", operator = rest}
    end
    if head == "dir" then
        return {kind = "arm_direction", direction = rest}
    end
    if head == "tslot" then
        local slot = tonumber(rest)
        if not slot then
            return nil, "tslot_needs_slot"
        end
        return {kind = "arm_target", target = {kind = "slot", zone = "manifest", slot = slot}}
    end
    if head == "clear" then
        local kind = CLEAR_KINDS[rest or ""]
        if not kind then
            return nil, "unknown_clear"
        end
        return {kind = kind}
    end
    if head == "target" then
        if tonumber(rest) then
            return {kind = "arm_target", target = {kind = "slot", zone = "manifest", slot = tonumber(rest)}}
        end
        if rest:match("^H%d+$") then
            local observation = view.observe(game, {interaction = core.interaction(game)})
            local card_id, err = view.resolve_handle(game, observation, rest)
            if not card_id then
                return nil, "handle:" .. tostring(err)
            end
            return {kind = "arm_target", target = {kind = "card", card_id = card_id}}
        end
        return {kind = "arm_target", target = {kind = "card", card_id = rest}}
    end

    return nil, "unknown_action:" .. tostring(head)
end

--------------------------------------------------------------------------
-- plant (MACHINE_CLI_SLICE §7) -- DEBUG surface, not a move
--------------------------------------------------------------------------

local function is_slot_zone(game, zone_name)
    local zone = game.zones[zone_name]
    return zone and zone.kind == "slots"
end

local function refill(game, zone_name, slot)
    local how = ZONE_REFILL[zone_name]
    if not how then
        return nil, nil
    end
    if how == "open" then
        return draw.open_manifest_closure(game, slot), "open"
    end
    return draw.concealed_refill(game, zone_name, slot), "concealed"
end

-- Returns a report table so the caller decides how to print it.
--
-- Three shapes, and only three, because they are what keeps the board valid:
--
--     target slot empty      move, then refill the hole left behind
--     target slot occupied   SWAP the two cards -- no refill needed, and the
--                            count of every zone is unchanged by construction
--     ordered target zone    append, then refill the hole left behind
function M.plant(game, card_id, zone_name, slot, info_state)
    local card = game.cards[card_id]
    if not card then
        return nil, "unknown_card"
    end
    if not game.zones[zone_name] then
        return nil, "unknown_zone"
    end

    local from_zone, from_slot = card.zone, card.slot
    local report = {
        card_id = card_id,
        from_zone = from_zone,
        from_slot = from_slot,
        to_zone = zone_name,
    }

    if is_slot_zone(game, zone_name) then
        slot = slot or state_lib.first_open_slot(game, zone_name)
        if not slot then
            -- every slot taken and none named: nothing sensible to guess
            return nil, "zone_full_name_a_slot"
        end
        if slot < 1 or slot > game.zones[zone_name].slot_count then
            return nil, "slot_out_of_range"
        end
    else
        slot = nil
    end
    report.to_slot = slot

    if from_zone == zone_name and from_slot == slot then
        report.noop = true
        return report
    end

    local occupant = slot and game.zones[zone_name].cards[slot] or nil
    report.swapped_with = occupant

    state_lib.remove_from_current_zone(game, card_id)

    if occupant then
        -- swap: the occupant takes the place the planted card came from
        state_lib.remove_from_current_zone(game, occupant)
        state_lib.place_card(game, card_id, zone_name, slot)
        state_lib.place_card(game, occupant, from_zone, from_slot)
        local occupant_state = ZONE_NATURAL_STATE[from_zone]
        if occupant_state and occupant_state ~= "hidden" then
            state_lib.set_info_state(game, occupant, occupant_state)
        end
    else
        state_lib.place_card(game, card_id, zone_name, slot)
        if from_zone and from_zone ~= zone_name then
            local filled, how = refill(game, from_zone, from_slot)
            if how then
                report.refilled = filled
                report.refill_kind = how
                report.refill_zone = from_zone
                report.refill_slot = from_slot
                if not filled then
                    report.hole = true
                end
            end
        end
    end

    local target_state = info_state or ZONE_NATURAL_STATE[zone_name]
    if target_state then
        local before = card.info_state
        state_lib.set_info_state(game, card_id, target_state)
        if before ~= "hidden" and target_state == "hidden" then
            report.downgraded = before
        end
    end

    return report
end

function M.format_plant(report)
    local lines = {}
    if report.noop then
        lines[#lines + 1] = string.format("plant %s: already there", report.card_id)
        return table.concat(lines, "\n")
    end
    lines[#lines + 1] = string.format(
        "plant %s: %s[%s] -> %s[%s]",
        report.card_id,
        tostring(report.from_zone),
        tostring(report.from_slot or "-"),
        report.to_zone,
        tostring(report.to_slot or "-"))
    if report.swapped_with then
        lines[#lines + 1] = string.format(
            "  swapped with %s -> %s[%s]",
            report.swapped_with,
            tostring(report.from_zone),
            tostring(report.from_slot or "-"))
    end
    if report.refill_kind then
        if report.hole then
            lines[#lines + 1] = string.format(
                "  PLANT WARNING: hole left at %s[%s], deck empty",
                report.refill_zone, tostring(report.refill_slot))
        else
            lines[#lines + 1] = string.format(
                "  refilled %s[%s] with %s (%s)",
                report.refill_zone, tostring(report.refill_slot),
                tostring(report.refilled), report.refill_kind)
        end
    end
    if report.downgraded then
        lines[#lines + 1] = string.format(
            "  PLANT NOTE: information state %s -> hidden", report.downgraded)
    end
    return table.concat(lines, "\n")
end

--------------------------------------------------------------------------
-- replay
--------------------------------------------------------------------------

local function start(log)
    local game = core.new()
    core.start_game(game, {
        rng = rng.from_seed(log.seed),
        enabled_trumps = (log.trumps == "none") and {} or nil,
    })
    return game
end

local function collect(game, events, entry_index)
    for _, event in ipairs(core.drain_events(game)) do
        events[#events + 1] = {
            entry = entry_index,
            type = event.type,
            payload = event.payload,
        }
    end
end

local function apply_plant_text(game, text)
    local card_id, zone_name, slot, info_state =
        text:match("^(%S+)%s+(%S+)%s*(%S*)%s*(%S*)$")
    if not card_id then
        return nil, "bad_plant_entry"
    end
    return M.plant(
        game,
        card_id,
        zone_name,
        tonumber(slot),
        (info_state ~= "" and info_state) or nil)
end

-- Replays the whole journal. Returns the game, the accumulated event stream
-- and, on failure, the index of the entry that could not be applied.
function M.rebuild(log)
    local game = start(log)
    local events = {}
    collect(game, events, 0)

    for index, entry in ipairs(log.entries) do
        if entry.kind == "do" then
            local action, err = M.parse_action(game, entry.text)
            if not action then
                return game, events, {entry = index, text = entry.text, error = err}
            end
            local result = core.apply_action(game, action)
            local apply_err = result and result.summary and result.summary.error
            collect(game, events, index)
            if apply_err then
                return game, events, {entry = index, text = entry.text, error = apply_err}
            end
        else
            local report, err = apply_plant_text(game, entry.text)
            collect(game, events, index)
            if not report then
                return game, events, {entry = index, text = entry.text, error = err}
            end
        end
    end

    return game, events, nil
end

function M.observe(game)
    return view.observe(game, {
        interaction = core.interaction(game),
        legal_action_count = #core.enumerate_legal_actions(game),
    })
end

return M
