local state_lib = require("src.core.state")
local draw = require("src.core.draw")
local trump = require("src.core.trump")
local transition = require("src.core.transition")

local M = {}

function M.repair_manifest_slot(state, slot)
    local latent_id = state.zones.latent.cards[slot]
    if not latent_id then
        transition.emit(state, "repair_skipped", {slot = slot})
        return
    end

    state_lib.remove_from_current_zone(state, latent_id)
    state_lib.reveal_card(state, latent_id)

    if state.cards[latent_id].class == "trump" then
        transition.emit(state, "latent_trump_revealed", {
            card_id = latent_id,
            slot = slot,
        })
        trump.enter_trump_flow(state, latent_id, "latent ascent")
        draw.open_manifest_closure(state, slot)
        draw.concealed_refill(state, "latent", slot)
        return
    end

    state_lib.place_card(state, latent_id, "manifest", slot)
    transition.emit(state, "latent_to_manifest", {
        card_id = latent_id,
        slot = slot,
    })
    draw.concealed_refill(state, "latent", slot)
end

return M
