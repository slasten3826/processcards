local M = {}

M.BASE_W = 1280
M.BASE_H = 720

M.COLORS = {
    bg = {0.05, 0.08, 0.10},
    panel = {0.09, 0.12, 0.15},
    panel_alt = {0.11, 0.14, 0.17},
    outline = {0.28, 0.31, 0.35},
    muted = {0.55, 0.59, 0.63},
    text = {0.92, 0.92, 0.90},
    accent = {0.95, 0.46, 0.20},
    accent_soft = {0.78, 0.47, 0.28},
    success = {0.32, 0.72, 0.46},
    danger = {0.80, 0.34, 0.30},
    card = {0.90, 0.87, 0.80},
    card_text = {0.14, 0.16, 0.18},
    card_back = {0.13, 0.16, 0.18},
    card_back_alt = {0.22, 0.26, 0.29},
    select = {0.35, 0.68, 0.96},
    drop = {0.92, 0.60, 0.24},
}

M.OP_COLORS = {
    FLOW = {0.22, 0.82, 0.82},
    CONNECT = {0.90, 0.78, 0.22},
    DISSOLVE = {0.63, 0.44, 0.88},
    ENCODE = {0.25, 0.49, 0.90},
    CHOOSE = {0.82, 0.26, 0.26},
    OBSERVE = {0.86, 0.86, 0.84},
    LOGIC = {0.34, 0.68, 0.32},
    CYCLE = {0.84, 0.49, 0.18},
    RUNTIME = {0.40, 0.46, 0.52},
    MANIFEST = {0.86, 0.68, 0.26},
}

M.ZONE_META = {
    deck = {title = "DECK", kind = "stack"},
    runtime = {title = "RUNTIME", kind = "slots", slot_count = 1},
    play = {title = "PLAY", kind = "slots", slot_count = 1},
    trump_flow = {title = "TRUMP FLOW", kind = "row"},
    trump = {title = "TRUMP ZONE", kind = "slots", slot_count = 2},
    targets = {title = "TARGETS", kind = "slots", slot_count = 3},
    manifest = {title = "MANIFEST", kind = "slots", slot_count = 6},
    latent = {title = "LATENT", kind = "slots", slot_count = 6},
    hand = {title = "HAND", kind = "fan"},
    grave = {title = "GRAVE", kind = "stack"},
}

return M
