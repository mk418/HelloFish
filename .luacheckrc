std = "lua51"
max_line_length = false
unused_args = false

ignore = {
    "211/ADDON_NAME",
    "432/self",
}

globals = {
    "HelloFishDB",
    "HelloFishCharDB",
    "SlashCmdList",
    "SLASH_HELLOFISH1",
    "SLASH_HELLOFISH2",
}

read_globals = {
    "CreateFrame", "UIParent", "GameTooltip", "GameTooltip_Hide",
    "Settings", "InterfaceOptions_AddCategory", "InterfaceOptionsFrame_OpenToCategory",
    "C_Item", "C_Container", "C_Timer", "NUM_BAG_SLOTS",
    "GetItemCount", "IsUsableItem", "GetItemInfo", "GetItemInfoInstant",
    "GetInventoryItemID", "GetInventoryItemLink", "GetWeaponEnchantInfo",
    "GetSpellInfo", "IsSpellKnown", "IsInventoryItemLocked",
    "CursorHasItem", "SpellIsTargeting", "GetCursorInfo", "ClearCursor",
    "PickupInventoryItem", "GetTime", "InCombatLockdown",
    "IsShiftKeyDown", "ReloadUI", "print",
}

files["Tests.lua"] = {
    globals = {
        "C_Item", "C_Container", "C_Timer", "NUM_BAG_SLOTS",
        "HelloFishCharDB", "GetItemCount", "IsUsableItem", "GetItemInfo",
        "GetItemInfoInstant", "GetInventoryItemID", "GetInventoryItemLink",
        "GetWeaponEnchantInfo", "GetSpellInfo", "IsSpellKnown",
        "IsInventoryItemLocked", "CursorHasItem", "SpellIsTargeting",
        "GetCursorInfo", "ClearCursor", "PickupInventoryItem", "GetTime",
        "InCombatLockdown",
    },
}
