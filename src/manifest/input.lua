local layout_lib = require("src.manifest.layout")

local M = {}

local function legal_card_set(list)
    local set = {}
    for _, card_id in ipairs(list or {}) do
        set[card_id] = true
    end
    return set
end

local function legal_slot_set(list)
    local set = {}
    for _, slot in ipairs(list or {}) do
        set[slot] = true
    end
    return set
end

local function pending_pair_card_set(app)
    local set = {}
    local pending = app.game and app.game.pending_pair_card_choice or nil
    if not pending then
        return set
    end
    for _, card_id in ipairs(pending.legal_public_card_ids or {}) do
        set[card_id] = true
    end
    for _, card_id in ipairs(pending.legal_hand_card_ids or {}) do
        set[card_id] = true
    end
    if pending.armed_public_card_id then
        set[pending.armed_public_card_id] = true
    end
    if pending.armed_hand_card_id then
        set[pending.armed_hand_card_id] = true
    end
    return set
end

function M.pick_card(app, x, y)
    local views = layout_lib.card_views(app.layout, app.game.zones)
    local ordered = {}
    for _, zone_name in ipairs({"hand", "manifest", "latent", "targets", "play", "runtime", "trump", "grave", "deck", "trump_flow"}) do
        local zone = app.game.zones[zone_name]
        if zone.kind == "slots" then
            for i = zone.slot_count, 1, -1 do
                local card_id = zone.cards[i]
                if card_id and views[card_id] then
                    ordered[#ordered + 1] = card_id
                end
            end
        else
            for i = #zone.cards, 1, -1 do
                local card_id = zone.cards[i]
                if card_id and views[card_id] then
                    ordered[#ordered + 1] = card_id
                end
            end
        end
    end
    for _, card_id in ipairs(ordered) do
        if layout_lib.point_in_rect(x, y, views[card_id]) then
            return card_id, views[card_id]
        end
    end
    return nil
end

function M.pick_manifest_slot(app, x, y)
    local rects = layout_lib.slot_rects_for_zone(app.layout, app.game.zones, "manifest")
    for slot, rect in ipairs(rects) do
        if layout_lib.point_in_rect(x, y, rect) then
            return slot
        end
    end
    return nil
end

function M.pick_operator_button(app, x, y)
    for _, button in ipairs(app.ui.operator_buttons) do
        if layout_lib.point_in_rect(x, y, button.rect) then
            return button
        end
    end
    return nil
end

function M.pick_footer_button(app, x, y)
    for _, button in ipairs(app.ui.footer_buttons) do
        if layout_lib.point_in_rect(x, y, button.rect) then
            return button
        end
    end
    return nil
end

function M.click(app, x, y)
    local ix = app.interaction
    local picked_card_id = nil

    if app.ui.grave_open then
        local viewer = app.ui.grave_viewer
        if not layout_lib.point_in_rect(x, y, viewer.rect) then
            app.ui.grave_open = false
            app:set_message("Grave viewer closed.")
            app:trace("grave_close", "click outside grave viewer")
            return
        end
        if ix.phase == "await_target" and ix.legal.targets.zones.grave then
            for _, card_id in ipairs(viewer.ordered_cards or {}) do
                local rect = viewer.card_rects[card_id]
                if rect and layout_lib.point_in_rect(x, y, rect) then
                    app:trace("grave_target_click", "card=" .. tostring(card_id))
                    app:apply_action({
                        kind = "arm_target",
                        target = {kind = "card", card_id = card_id},
                    }, "Arm grave target")
                    return
                end
            end
            app:trace("grave_target_noop", "click inside grave viewer but no legal grave card hit")
            return
        end
        app:trace("grave_viewer_noop", "click inside grave viewer")
        return
    end

    local footer = M.pick_footer_button(app, x, y)
    if footer then
        app:trace("footer_click", "id=" .. tostring(footer.id))
        if footer.id == "start" then
            app:start_game()
            return
        elseif footer.id == "draw" then
            app:apply_action({kind = "draw"}, "Draw")
            return
        elseif footer.id == "reset" then
            app:start_game()
            return
        end
    end

    local op_button = M.pick_operator_button(app, x, y)
    if op_button and ix.phase == "await_operator" then
        app:trace("operator_click", "op=" .. tostring(op_button.op_name))
        app:apply_action({kind = "arm_operator", operator = op_button.op_name}, "Arm operator")
        return
    elseif op_button then
        app:trace("operator_click_noop", "op=" .. tostring(op_button.op_name) .. " phase=" .. tostring(ix.phase))
        return
    end

    if layout_lib.point_in_rect(x, y, app.layout.right.grave) then
        app.ui.grave_open = true
        app:trace("grave_open", "panel click")
        return
    end

    if ix.phase == "await_start" then
        local slot = M.pick_manifest_slot(app, x, y)
        local legal_slots = legal_slot_set(ix.legal.commit_slots)
        if slot and legal_slots[slot] then
            app:trace("start_commit", "slot=" .. tostring(slot))
            app:apply_action({kind = "commit_manifest", slot = slot}, "Commit")
            return
        elseif slot then
            app:trace("start_commit_noop", "slot=" .. tostring(slot) .. " not legal")
            return
        end
    end

    if ix.phase == "await_target" and ix.legal.targets.kind == "manifest_slot" then
        local slot = M.pick_manifest_slot(app, x, y)
        local legal_slots = legal_slot_set(ix.legal.targets.slots)
        if slot and legal_slots[slot] then
            app:trace("manifest_target_click", "slot=" .. tostring(slot))
            app:apply_action({
                kind = "arm_target",
                target = {kind = "slot", zone = "manifest", slot = slot},
            }, "Arm manifest target")
            return
        elseif slot then
            app:trace("manifest_target_click_noop", "slot=" .. tostring(slot) .. " not legal")
            return
        end
    end

    local card_id = M.pick_card(app, x, y)
    picked_card_id = card_id
    if not card_id then
        app:trace("click_no_card", "phase=" .. tostring(ix.phase))
        return
    end

    local card = app.game.cards[card_id]
    if not card then
        app:trace("click_no_card_data", "phase=" .. tostring(ix.phase))
        return
    end

    if ix.phase == "await_start" then
        if card.zone == "manifest" then
            local legal_slots = legal_slot_set(ix.legal.commit_slots)
            if legal_slots[card.slot] then
                app:trace("start_commit_card", "slot=" .. tostring(card.slot) .. " card=" .. tostring(card_id))
                app:apply_action({kind = "commit_manifest", slot = card.slot}, "Commit")
            else
                app:trace("start_commit_card_noop", "not legal")
            end
            return
        end
        if card.zone == "hand" then
            app:trace("start_arm", "card=" .. tostring(card_id))
            app:apply_action({kind = "arm_hand", card_id = card_id}, "Arm")
            return
        end
        return
    end

    if ix.phase == "await_complete" then
        local is_committed_card = app.game.committed and app.game.committed.card_id == card_id
        local is_armed_card = app.game.armed_hand == card_id

        if is_committed_card then
            app:trace("complete_deselect_commit", "card=" .. tostring(card_id))
            app:apply_action({kind = "clear_selection"}, "Deselect")
            return
        end
        if is_armed_card then
            app:trace("complete_deselect_arm", "card=" .. tostring(card_id))
            app:apply_action({kind = "clear_selection"}, "Deselect")
            return
        end

        if app.game.committed then
            if card.zone == "manifest" then
                local legal_slots = legal_slot_set(ix.legal.commit_slots)
                if legal_slots[card.slot] then
                    app:trace("complete_recommit", "slot=" .. tostring(card.slot) .. " card=" .. tostring(card_id))
                    app:apply_action({kind = "commit_manifest", slot = card.slot}, "Recommit")
                    return
                end
            end
            if card.zone == "hand" then
                local legal = legal_card_set(ix.legal.hand_cards)
                if legal[card_id] then
                    app:trace("complete_arm", "card=" .. tostring(card_id))
                    app:apply_action({kind = "arm_hand", card_id = card_id}, "Arm")
                else
                    app:set_message("This hand card does not fit the committed manifest.")
                end
                return
            end
            return
        end

        if app.game.armed_hand then
            if card.zone == "manifest" then
                local legal_slots = legal_slot_set(ix.legal.commit_slots)
                if legal_slots[card.slot] then
                    app:trace("complete_commit_from_hand", "slot=" .. tostring(card.slot) .. " card=" .. tostring(card_id))
                    app:apply_action({kind = "commit_manifest", slot = card.slot}, "Commit")
                    return
                end
                return
            end
            if card.zone == "hand" then
                app:trace("complete_rearm", "card=" .. tostring(card_id))
                app:apply_action({kind = "arm_hand", card_id = card_id}, "Rearm")
                return
            end
            return
        end
        return
    end

    if ix.phase == "await_ready" then
        local is_committed_card = app.game.committed and app.game.committed.card_id == card_id
        local is_armed_card = app.game.armed_hand == card_id

        if is_committed_card then
            app:trace("ready_deselect_commit", "card=" .. tostring(card_id))
            app:apply_action({kind = "clear_committed"}, "Deselect commit")
            return
        end
        if is_armed_card then
            app:trace("ready_deselect_arm", "card=" .. tostring(card_id))
            app:apply_action({kind = "clear_armed"}, "Deselect arm")
            return
        end
        if card.zone == "manifest" then
            local legal_slots = legal_slot_set(ix.legal.commit_slots)
            if legal_slots[card.slot] then
                app:trace("ready_recommit", "slot=" .. tostring(card.slot) .. " card=" .. tostring(card_id))
                app:apply_action({kind = "clear_selection"}, "Clear")
                app:apply_action({kind = "commit_manifest", slot = card.slot}, "Recommit")
                return
            end
            return
        end
        if card.zone == "hand" then
            local legal = legal_card_set(ix.legal.hand_cards)
            if legal[card_id] then
                app:trace("ready_rearm", "card=" .. tostring(card_id))
                app:apply_action({kind = "clear_selection"}, "Clear")
                app:apply_action({kind = "arm_hand", card_id = card_id}, "Rearm")
                return
            end
            return
        end
        return
    end

    if ix.phase == "await_target" then
        if ix.legal.targets.kind == "manifest_slot" then
            return
        end

        local legal_cards
        if ix.legal.targets.kind == "pair_card" then
            legal_cards = pending_pair_card_set(app)
        else
            legal_cards = legal_card_set(ix.legal.targets.cards)
        end
        if legal_cards[card_id] then
            if ix.legal.targets.kind == "pair_card" then
                local zone = app.game.cards[card_id] and app.game.cards[card_id].zone or "-"
                app:trace("pair_card_target_click", "card=" .. tostring(card_id) .. " zone=" .. tostring(zone))
            elseif ix.legal.targets.kind == "hand_card" then
                app:trace("hand_target_click", "card=" .. tostring(card_id))
            elseif ix.legal.targets.kind == "public_minor_card" then
                app:trace("public_target_click", "card=" .. tostring(card_id))
            elseif ix.legal.targets.kind == "hidden_card" then
                app:trace("hidden_target_click", "card=" .. tostring(card_id))
            elseif ix.legal.targets.kind == "unrevealed_card" then
                app:trace("unrevealed_target_click", "card=" .. tostring(card_id))
            else
                app:trace("target_click", "kind=" .. tostring(ix.legal.targets.kind) .. " card=" .. tostring(card_id))
            end
            app:apply_action({kind = "arm_target", target = {kind = "card", card_id = card_id}}, "Arm target")
        else
            local zone = app.game.cards[card_id] and app.game.cards[card_id].zone or "-"
            app:set_message("Choose a legal target.")
            app:trace("target_click_noop", "kind=" .. tostring(ix.legal.targets.kind) .. " card=" .. tostring(card_id) .. " zone=" .. tostring(zone) .. " not legal")
        end
        return
    end

    local zone = app.game.cards[card_id] and app.game.cards[card_id].zone or "-"
    app:trace("click_noop", "phase=" .. tostring(ix.phase) .. " card=" .. tostring(card_id) .. " zone=" .. tostring(zone))
end

return M
