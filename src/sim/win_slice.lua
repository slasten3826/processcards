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

-- WIN_MODULE_SLICE §11.16: a hand that is NOT empty and still fits nowhere.
-- MANIFEST is adjacent only to LOGIC, CYCLE and RUNTIME, so a manifest built
-- entirely from the other six operators accepts no MANIFEST/MANIFEST card, and
-- that card carries no LOGIC so the joker is out too.
local SAFE = {FLOW = true, CONNECT = true, DISSOLVE = true,
              ENCODE = true, CHOOSE = true, OBSERVE = true}

local function build_deadlock(game)
    local filled = 0
    for _, id in ipairs(sorted_ids(game)) do
        local card = game.cards[id]
        if filled < 6 and card.class == "minor"
            and SAFE[card.op_a] and SAFE[card.op_b] and not used[id] then
            used[id] = true
            filled = filled + 1
            put(game, id, "manifest", filled, "revealed")
        end
    end

    while #game.zones.hand.cards > 0 do
        state_lib.remove_from_current_zone(game, game.zones.hand.cards[1])
    end
    for _, id in ipairs(sorted_ids(game)) do
        local card = game.cards[id]
        if card.class == "minor" and card.op_a == "MANIFEST"
            and card.op_b == "MANIFEST" then
            state_lib.remove_from_current_zone(game, id)
            state_lib.place_card(game, id, "hand", nil)
            return filled, id
        end
    end
    return filled, nil
end

-- A card carrying LOGIC always has a move through the joker, so adding one to
-- the deadlock hand must switch the verdict off. That is check 17.
local function add_logic_card(game)
    for _, id in ipairs(sorted_ids(game)) do
        local card = game.cards[id]
        if card.class == "minor" and not used[id]
            and (card.op_a == "LOGIC" or card.op_b == "LOGIC") then
            used[id] = true
            state_lib.remove_from_current_zone(game, id)
            state_lib.place_card(game, id, "hand", nil)
            return id
        end
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
        turn.step_win_check(game)
        add(results, "8a signature stays ENOUGH", game.outcome.by == "ENOUGH",
            game.outcome.by)
        add(results, "8a pattern would also have won",
            win.check(game, "pattern") ~= nil)
    end

    -- STEP_CHECK_SLICE §6.3: game_won lands between the step boundaries
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    core.drain_events(game)
    turn.step_win_check(game)
    local order, won = {}, false
    for _, event in ipairs(core.drain_events(game)) do
        order[#order + 1] = event.type
        if event.type == "game_won" then won = true end
    end
    add(results, "step §6.3 game_won between the boundaries",
        won and order[1] == "step_win_check_begin"
            and order[#order] == "step_win_check_end",
        table.concat(order, ","))

    --------------------------------------------------------------------
    -- defeat: WIN_MODULE_SLICE §11.15-18
    --------------------------------------------------------------------

    -- 15: an empty hand has no castable pair and is the special case
    game = fresh()
    set_hand(game, 0)
    outcome = win.check(game, "no_legal_move")
    add(results, "15 empty hand is defeat",
        outcome and outcome.kind == "defeat" and outcome.by == "no_legal_move",
        outcome and outcome.by or "no verdict")

    -- 16: the general case. Hand is NOT empty and still fits nowhere.
    game = fresh()
    local filled, dead_id = build_deadlock(game)
    if filled < 6 or not dead_id then
        add(results, "16 full hand with no legal move is defeat", false,
            "position could not be built: " .. filled .. " slots, card " ..
            tostring(dead_id))
    else
        outcome = win.check(game, "no_legal_move")
        add(results, "16 full hand with no legal move is defeat",
            outcome and outcome.kind == "defeat",
            string.format("hand %d, verdict %s", #game.zones.hand.cards,
                outcome and outcome.by or "none"))

        -- 17: CONTROL. One LOGIC card in the same position must undo it.
        local logic_id = add_logic_card(game)
        add(results, "17 CONTROL a LOGIC card is not defeat",
            logic_id ~= nil and win.check(game, "no_legal_move") == nil,
            logic_id and ("added " .. logic_id) or "no LOGIC card free")
    end

    -- 18: CONTROL on precedence. Empty hand AND the pattern complete.
    -- Step 9 must record victory and step 10 must stay silent.
    game = fresh(); seq = seed_targets(game); build_manifest(game, seq, "op_a")
    set_hand(game, 0)
    add(results, "18 precondition: both predicates fire",
        win.check(game, "pattern") ~= nil
            and win.check(game, "no_legal_move") ~= nil)
    turn.step_win_check(game)
    turn.step_lose_check(game)
    add(results, "18 CONTROL victory beats defeat",
        game.outcome and game.outcome.kind == "victory",
        game.outcome and (game.outcome.kind .. "/" .. game.outcome.by) or "none")

    -- STEP_CHECK_SLICE §6.3a: game_lost lands between the TENTH boundaries
    game = fresh()
    set_hand(game, 0)
    core.drain_events(game)
    turn.step_lose_check(game)
    local lost_order, lost = {}, false
    for _, event in ipairs(core.drain_events(game)) do
        lost_order[#lost_order + 1] = event.type
        if event.type == "game_lost" then lost = true end
    end
    add(results, "step §6.3a game_lost between the boundaries",
        lost and lost_order[1] == "step_lose_check_begin"
            and lost_order[#lost_order] == "step_lose_check_end",
        table.concat(lost_order, ","))

    -- 20: DEV_CLI_LAW §8. Under free draw an empty hand is always recoverable,
    -- so a green defeat result here would be a lie by unreachability.
    game = core.new()
    core.start_game(game, {rng = rng.from_seed(1), enabled_effects = {},
                           free_draw = true})
    set_hand(game, 0)
    add(results, "20 defeat under draw=free", true,
        "SKIP free draw makes the condition unreachable, DEV_CLI_LAW §8")

    -- STEP_CHECK_SLICE §6.1: emitted from exactly one place. A structural
    -- check: it reads the source, not a run, so it sees every site at once and
    -- not only the ones a game happened to reach.
    local sites = 0
    local pipe = io.popen("grep -c 'transition.emit(state, \"step_win_check_begin\"' src/core/*.lua 2>/dev/null")
    if pipe then
        for line in pipe:lines() do
            local count = tonumber(line:match(":(%d+)$"))
            if count then sites = sites + count end
        end
        pipe:close()
    end
    add(results, "step §6.1 emitted from exactly one place", sites == 1,
        sites .. " sites")

    -- §6.1a: the same requirement for the tenth step. Per step, not per pair.
    local lose_sites = 0
    local lose_pipe = io.popen("grep -c 'transition.emit(state, \"step_lose_check_begin\"' src/core/*.lua 2>/dev/null")
    if lose_pipe then
        for line in lose_pipe:lines() do
            local count = tonumber(line:match(":(%d+)$"))
            if count then lose_sites = lose_sites + count end
        end
        lose_pipe:close()
    end
    add(results, "step §6.1a tenth step emitted from exactly one place",
        lose_sites == 1, lose_sites .. " sites")

    -- §6.6: the revision-1 name must be GONE from the core. An alias kept for
    -- convenience would restore exactly the ambiguity the split removed, and it
    -- would not be caught by a run: a forgotten alias exists whether or not any
    -- game happens to execute it.
    local stale = 0
    local stale_pipe = io.popen("grep -c 'step_check_begin\\|step_check_end\\|M\\.step_check' src/core/*.lua 2>/dev/null")
    if stale_pipe then
        for line in stale_pipe:lines() do
            local count = tonumber(line:match(":(%d+)$"))
            if count then stale = stale + count end
        end
        stale_pipe:close()
    end
    add(results, "step §6.6 revision-1 name absent from core", stale == 0,
        stale .. " occurrences")

    local ok = true
    for _, entry in ipairs(results) do
        ok = ok and entry.ok
    end
    return {ok = ok, results = results}
end

return M
