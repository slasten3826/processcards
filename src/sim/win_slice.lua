-- Mechanism for WIN_MODULE_SLICE §11 and STEP_CHECK_SLICE §6.
--
-- Positions are built by hand, so every result here is reached = "planted":
-- the victory pattern needs six specific slots and random play does not get
-- there. DEV_CLI_LAW §7 wants that visible rather than assumed.
--
-- Card iteration goes through sorted ids everywhere. pairs() over a hash table
-- has no defined order in Lua, and the first version of this test was green by
-- luck: which trumps landed in the target zone changed between runs.

local core = require("src.core.game")
local rng = require("src.sim.rng")
local win = require("src.core.win")
local turn = require("src.core.turn")
local state_lib = require("src.core.state")

local M = {}

local used = {}

local function sorted_ids(game)
    local ids = {}
    for id in pairs(game.cards) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end

local function fresh(seed)
    used = {}
    local game = core.new()
    core.start_game(game, {rng = rng.from_seed(seed or 1), enabled_effects = {}})
    return game
end

local function put(game, card_id, zone, slot, info)
    state_lib.remove_from_current_zone(game, card_id)
    state_lib.place_card(game, card_id, zone, slot)
    state_lib.set_info_state(game, card_id, info)
end

local function free_minor(game, row, operator)
    for _, id in ipairs(sorted_ids(game)) do
        local card = game.cards[id]
        if card.class == "minor" and card[row] == operator and not used[id] then
            used[id] = true
            return id
        end
    end
end

-- Three trumps into the target zone, and the sequence is read back OFF THE
-- BOARD rather than assumed: the order inside a trump comes from TRUMP_CANON,
-- not from how anyone names it.
local function seed_targets(game, info)
    local picked, n = {}, 0
    for _, id in ipairs(sorted_ids(game)) do
        if game.cards[id].class == "trump" and n < 3 then
            n = n + 1
            picked[n] = id
        end
    end
    local seq = {}
    for slot = 1, 3 do
        put(game, picked[slot], "targets", slot, info or "revealed")
        local card = game.cards[picked[slot]]
        seq[#seq + 1] = card.op_a
        seq[#seq + 1] = card.op_b
    end
    return seq
end

local function build_manifest(game, seq, row)
    for slot = 1, 6 do
        put(game, free_minor(game, row, seq[slot]), "manifest", slot, "revealed")
    end
end

-- Set the hand to exactly n cards, so an ENOUGH claim can be made to verify
-- or to fail on purpose instead of being skipped.
local function set_hand(game, n)
    while #game.zones.hand.cards > n do
        state_lib.remove_from_current_zone(game, game.zones.hand.cards[1])
    end
    while #game.zones.hand.cards < n do
        local taken
        for _, id in ipairs(sorted_ids(game)) do
            local card = game.cards[id]
            if card.class == "minor" and card.zone == "deck" and not used[id] then
                used[id] = true
                taken = id
                break
            end
        end
        if not taken then break end
        state_lib.remove_from_current_zone(game, taken)
        state_lib.place_card(game, taken, "hand", nil)
    end
end

local function revealed_board(game)
    local n = 0
    for _, zone_name in ipairs({"manifest", "latent"}) do
        local zone = game.zones[zone_name]
        for slot = 1, zone.slot_count do
            local id = zone.cards[slot]
            if id and state_lib.is_revealed(game, id) then n = n + 1 end
        end
    end
    return n
end

--------------------------------------------------------------------------

local function add(results, name, ok, detail)
    results[#results + 1] = {name = name, ok = ok, detail = detail}
end

function M.run()
    local results = {}
    local game, seq, outcome

    -- 1, 2: both readings
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    outcome = win.check(game, "pattern")
    add(results, "1 upper reading", outcome and outcome.reading == "upper",
        outcome and outcome.reading or "no verdict")

    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_b")
    outcome = win.check(game, "pattern")
    add(results, "2 lower reading", outcome and outcome.reading == "lower",
        outcome and outcome.reading or "no verdict")

    -- 3: five of six
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    put(game, free_minor(game, "op_a", seq[6] == "FLOW" and "LOGIC" or "FLOW"),
        "manifest", 6, "revealed")
    add(results, "3 five of six is not victory", win.check(game, "pattern") == nil)

    -- 4: CONTROL. A mixed reading must not win.
    game = fresh(); seq = seed_targets(game)
    for slot = 1, 6 do
        local row = slot <= 3 and "op_a" or "op_b"
        put(game, free_minor(game, row, seq[slot]), "manifest", slot, "revealed")
    end
    add(results, "4 CONTROL mixed reading is not victory",
        win.check(game, "pattern") == nil)

    -- 5: a minor in the target zone
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    put(game, free_minor(game, "op_a", "FLOW"), "targets", 3, "revealed")
    add(results, "5 minor in target zone is not victory",
        win.check(game, "pattern") == nil)

    -- 13, 14: CONTROL PAIR on timing
    game = fresh(); seq = seed_targets(game, "hidden"); build_manifest(game, seq, "op_a")
    add(results, "13 hidden trump is not victory", win.check(game, "pattern") == nil)
    for slot = 1, 3 do
        state_lib.set_info_state(game, game.zones.targets.cards[slot], "revealed")
    end
    outcome = win.check(game, "pattern")
    add(results, "14 exposed in the same turn wins",
        outcome and outcome.reading == "upper")

    -- 6, 8: ENOUGH verified, then repeated
    game = fresh()
    outcome = win.request(game, {signature = "ENOUGH", basis = {revealed = 6, hand = 6}})
    add(results, "6 ENOUGH verified", outcome and outcome.by == "ENOUGH")
    add(results, "6 outcome recorded", game.outcome ~= nil)
    local _, err = win.request(game, {signature = "ENOUGH"})
    add(results, "8 repeat claim after victory", err == "already_over", tostring(err))

    -- 7: ENOUGH unverified is a loud refusal, nothing recorded
    game = fresh()
    state_lib.remove_from_current_zone(game, game.zones.hand.cards[1])
    core.drain_events(game)
    local _, err2 = win.request(game, {signature = "ENOUGH", basis = {revealed = 6, hand = 99}})
    add(results, "7 unverified claim refused", err2 == "claim_not_verified", tostring(err2))
    add(results, "7 outcome NOT recorded", game.outcome == nil)
    local loud = false
    for _, event in ipairs(core.drain_events(game)) do
        if event.type == "win_claim_rejected" then loud = true end
    end
    add(results, "7 refused LOUDLY", loud)

    -- 8a: a claim at step 8 is not overwritten by step 9
    -- The pattern is complete AND the ENOUGH equality holds, so both would
    -- fire. ENOUGH claims first, at step 8; step 9 must not relabel it.
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    set_hand(game, revealed_board(game))
    outcome = win.request(game, {signature = "ENOUGH"})
    if not outcome then
        add(results, "8a signature stays ENOUGH", false,
            "ENOUGH did not verify, the case is not being tested")
    else
        turn.step_check(game)
        add(results, "8a signature stays ENOUGH", game.outcome.by == "ENOUGH",
            game.outcome.by)
        add(results, "8a pattern would also have won",
            win.check(game, "pattern") ~= nil)
    end

    -- STEP_CHECK_SLICE §6.3: game_won lands between the step boundaries
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    core.drain_events(game)
    turn.step_check(game)
    local order, won = {}, false
    for _, event in ipairs(core.drain_events(game)) do
        order[#order + 1] = event.type
        if event.type == "game_won" then won = true end
    end
    add(results, "step §6.3 game_won between the boundaries",
        won and order[1] == "step_check_begin"
            and order[#order] == "step_check_end",
        table.concat(order, ","))

    -- STEP_CHECK_SLICE §6.1: emitted from exactly one place. A structural
    -- check: it reads the source, not a run, so it sees every site at once and
    -- not only the ones a game happened to reach.
    local sites = 0
    local pipe = io.popen("grep -c 'transition.emit(state, \"step_check_begin\"' src/core/*.lua 2>/dev/null")
    if pipe then
        for line in pipe:lines() do
            local count = tonumber(line:match(":(%d+)$"))
            if count then sites = sites + count end
        end
        pipe:close()
    end
    add(results, "step §6.1 emitted from exactly one place", sites == 1,
        sites .. " sites")

    local ok = true
    for _, entry in ipairs(results) do
        ok = ok and entry.ok
    end
    return {ok = ok, results = results}
end

return M
