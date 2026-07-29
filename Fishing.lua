local _, addon = ...

addon.Fishing = {}
local Fishing = addon.Fishing

local MAIN_HAND, OFF_HAND = 16, 17
local FISHING_SPELL_ID = 7620
local FISHING_RANK_IDS = { 7620, 7731, 7732, 18248 }

-- Highest fishing bonus first. This is deliberately the standard Era catalog:
-- expansion and seasonal poles do not quietly change which item is equipped.
Fishing.POLES = {
  { id = 19970, bonus = 35 }, -- Arcanite Fishing Pole
  { id = 19022, bonus = 25 }, -- Nat Pagle's Extreme Angler FC-5000
  { id = 6367,  bonus = 20 }, -- Big Iron Fishing Pole
  { id = 6366,  bonus = 15 }, -- Darkwood Fishing Pole
  { id = 6365,  bonus = 5  }, -- Strong Fishing Pole
  { id = 12225, bonus = 3  }, -- Blump Family Fishing Pole
  { id = 6256,  bonus = 0  }, -- Fishing Pole
}

Fishing.LURES = {
  { id = 6533, bonus = 100 }, -- Aquadynamic Fish Attractor
  { id = 7307, bonus = 75  }, -- Flesh Eating Worm
  { id = 6532, bonus = 75  }, -- Bright Baubles
  { id = 6530, bonus = 50  }, -- Nightcrawlers
  { id = 6529, bonus = 25  }, -- Shiny Bauble
}

local poleIDs = {}
for _, pole in ipairs(Fishing.POLES) do poleIDs[pole.id] = true end

local function itemCount(itemID)
  return GetItemCount(itemID) or 0
end

local function usable(itemID)
  if not IsUsableItem then return true end
  local canUse = IsUsableItem(itemID)
  return canUse and true or false
end

local function itemData(itemID)
  local name, _, _, _, _, _, _, _, _, icon = GetItemInfo(itemID)
  if not icon and GetItemInfoInstant then
    local _, _, _, _, instantIcon = GetItemInfoInstant(itemID)
    icon = instantIcon
  end
  return name, icon
end

function Fishing:RequestItemData()
  if not C_Item or not C_Item.RequestLoadItemDataByID then return end
  for _, list in ipairs({ self.POLES, self.LURES }) do
    for _, item in ipairs(list) do C_Item.RequestLoadItemDataByID(item.id) end
  end
end

function Fishing:IsPole(itemID)
  return itemID and poleIDs[itemID] or false
end

function Fishing:EquippedPole()
  local itemID = GetInventoryItemID("player", MAIN_HAND)
  if self:IsPole(itemID) then return itemID end
end

function Fishing:BestPole()
  for _, pole in ipairs(self.POLES) do
    if itemCount(pole.id) > 0 and usable(pole.id) then return pole end
  end
end

function Fishing:BestLure()
  for _, lure in ipairs(self.LURES) do
    if itemCount(lure.id) > 0 and usable(lure.id) then return lure end
  end
end

function Fishing:LureState()
  local hasEnchant, remaining = GetWeaponEnchantInfo()
  return hasEnchant and true or false, (remaining or 0) / 1000
end

function Fishing:FishingSpell()
  local name, _, icon = GetSpellInfo(FISHING_SPELL_ID)
  local known = not IsSpellKnown
  if IsSpellKnown then
    for _, spellID in ipairs(FISHING_RANK_IDS) do
      if IsSpellKnown(spellID) then
        known = true
        break
      end
    end
  end
  if name and known then return name, icon end
end

function Fishing:State()
  local spellName, spellIcon = self:FishingSpell()
  if not spellName then
    return { kind = "disabled", reason = "Learn Fishing first." }
  end

  local equipped = self:EquippedPole()
  if not equipped then
    local pole = self:BestPole()
    if not pole then
      return { kind = "disabled", reason = "Carry a fishing pole in your bags." }
    end
    local name, icon = itemData(pole.id)
    return { kind = "equip", itemID = pole.id, name = name or "Fishing pole", icon = icon }
  end

  local hasLure, seconds = self:LureState()
  if not hasLure then
    local lure = self:BestLure()
    if lure then
      local name, icon = itemData(lure.id)
      return { kind = "lure", itemID = lure.id, name = name or "Fishing lure",
        icon = icon, count = itemCount(lure.id) }
    end
  end

  return { kind = "cast", name = spellName, icon = spellIcon,
    lureSeconds = hasLure and seconds or nil }
end

local function snapshotSlot(slot)
  local itemID = GetInventoryItemID("player", slot)
  if not itemID then return false end
  return { itemID = itemID, link = GetInventoryItemLink("player", slot) }
end

function Fishing:CaptureLoadout()
  if HelloFishCharDB.loadout then return end
  HelloFishCharDB.loadout = {
    main = snapshotSlot(MAIN_HAND),
    off = snapshotSlot(OFF_HAND),
  }
end

local function sameItem(snapshot, link, itemID)
  if snapshot == false then return itemID == nil end
  if not itemID or itemID ~= snapshot.itemID then return false end
  return not snapshot.link or not link or snapshot.link == link
end
Fishing.SameItem = sameItem

local function bagItem(bag, slot)
  local info = C_Container.GetContainerItemInfo(bag, slot)
  if not info then return nil end
  return info.hyperlink, info.itemID, info.isLocked
end

local function findBagItem(snapshot)
  local fallback
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local link, itemID, locked = bagItem(bag, slot)
      if itemID == snapshot.itemID then
        local candidate = { bag = bag, slot = slot, locked = locked }
        if snapshot.link and link == snapshot.link then return candidate end
        fallback = fallback or candidate
      end
    end
  end
  return fallback
end

local function findFreeBagSlot()
  for bag = 0, NUM_BAG_SLOTS do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      if not C_Container.GetContainerItemInfo(bag, slot) then
        return bag, slot
      end
    end
  end
end

local function cursorBusy()
  return CursorHasItem() or SpellIsTargeting() or GetCursorInfo() ~= nil
end

local function finishCursorMove()
  if not CursorHasItem() then return true end
  ClearCursor()
  return false
end

local function moveBagToSlot(bag, bagSlot, invSlot)
  C_Container.PickupContainerItem(bag, bagSlot)
  if not CursorHasItem() then return false end
  PickupInventoryItem(invSlot)
  return finishCursorMove()
end

local function moveSlotToBag(invSlot, bag, bagSlot)
  PickupInventoryItem(invSlot)
  if not CursorHasItem() then return false end
  C_Container.PickupContainerItem(bag, bagSlot)
  return finishCursorMove()
end

function Fishing:Restored(loadout)
  if not loadout then return true end
  return sameItem(loadout.main, GetInventoryItemLink("player", MAIN_HAND),
      GetInventoryItemID("player", MAIN_HAND))
    and sameItem(loadout.off, GetInventoryItemLink("player", OFF_HAND),
      GetInventoryItemID("player", OFF_HAND))
end

function Fishing:FinishRestore(success, message)
  self.restoreJob = nil
  if success then HelloFishCharDB.loadout = nil end
  if message then addon:Print(message) end
  if addon.Button then addon.Button:Refresh() end
end

function Fishing:RestorePass()
  local job = self.restoreJob
  if not job then return end
  if InCombatLockdown() then
    job.waitingForCombat = true
    return
  end
  if cursorBusy() then
    self:FinishRestore(false, "the cursor is busy; clear it and right-click again.")
    return
  end
  if self:Restored(job.loadout) then
    self:FinishRestore(true, "weapons restored.")
    return
  end
  if GetTime() - job.started > 6 or job.passes >= 20 then
    self:FinishRestore(false, "couldn't finish restoring the saved weapons; right-click to retry.")
    return
  end
  job.passes = job.passes + 1

  for _, target in ipairs({ { slot = MAIN_HAND, saved = job.loadout.main },
      { slot = OFF_HAND, saved = job.loadout.off } }) do
    local link = GetInventoryItemLink("player", target.slot)
    local itemID = GetInventoryItemID("player", target.slot)
    if not sameItem(target.saved, link, itemID) then
      if IsInventoryItemLocked(target.slot) then
        C_Timer.After(0.15, function() Fishing:RestorePass() end)
        return
      end
      if target.saved == false then
        local bag, bagSlot = findFreeBagSlot()
        if not bag then
          self:FinishRestore(false, "not enough bag space to remove the fishing pole.")
          return
        end
        moveSlotToBag(target.slot, bag, bagSlot)
      else
        local source = findBagItem(target.saved)
        if not source then
          self:FinishRestore(false, "a saved weapon is no longer in your bags.")
          return
        end
        if source.locked then
          C_Timer.After(0.15, function() Fishing:RestorePass() end)
          return
        end
        moveBagToSlot(source.bag, source.slot, target.slot)
      end
      C_Timer.After(0.15, function() Fishing:RestorePass() end)
      return
    end
  end
end

function Fishing:RestoreLoadout()
  if InCombatLockdown() then
    addon:Print("can't restore weapons in combat.")
    return
  end
  if not HelloFishCharDB.loadout then
    addon:Print("no saved weapons to restore.")
    return
  end
  if self.restoreJob then return end
  self.restoreJob = { loadout = HelloFishCharDB.loadout, started = GetTime(), passes = 0 }
  self:RestorePass()
end

addon:On("PLAYER_REGEN_ENABLED", function()
  if Fishing.restoreJob and Fishing.restoreJob.waitingForCombat then
    Fishing.restoreJob.waitingForCombat = nil
    Fishing:RestorePass()
  end
end)
