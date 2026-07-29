-- Offline harness for HelloFish's item selection, state machine and restoration.

local checks, failures = 0, 0
local function expect(label, actual, wanted)
  checks = checks + 1
  if actual ~= wanted then
    failures = failures + 1
    print(("FAIL  %s: got %s, wanted %s"):format(label, tostring(actual), tostring(wanted)))
  else
    print("ok    " .. label)
  end
end

local root = (...) or "."
local inventory, bags, unusable = {}, { [0] = {}, [1] = {} }, {}
local knownFishing, knownRank, lureActive, lureRemaining, combat = true, 7620, false, 0, false
local messages, cursor, cursorOrigin = {}, nil, nil

local ITEMS = {
  [19970] = "Arcanite Fishing Pole", [19022] = "Nat Pagle's Extreme Angler FC-5000",
  [6367] = "Big Iron Fishing Pole", [6366] = "Darkwood Fishing Pole",
  [6365] = "Strong Fishing Pole", [12225] = "Blump Family Fishing Pole",
  [6256] = "Fishing Pole", [6533] = "Aquadynamic Fish Attractor",
  [7307] = "Flesh Eating Worm", [6532] = "Bright Baubles",
  [6530] = "Nightcrawlers", [6529] = "Shiny Bauble",
  [1001] = "Sword", [1002] = "Shield", [1003] = "Dagger",
}

local function item(id, suffix)
  if not id then return nil end
  return { itemID = id, hyperlink = ("item:%d:%s"):format(id, suffix or "plain") }
end

local function reset()
  inventory = {}
  bags = { [0] = {}, [1] = {} }
  unusable = {}
  knownFishing, knownRank, lureActive, lureRemaining, combat = true, 7620, false, 0, false
  messages, cursor, cursorOrigin = {}, nil, nil
  HelloFishCharDB = {}
end

NUM_BAG_SLOTS = 1
C_Item = { RequestLoadItemDataByID = function() end }
C_Container = {}
function C_Container.GetContainerNumSlots() return 4 end
function C_Container.GetContainerItemInfo(bag, slot) return bags[bag][slot] end
function C_Container.PickupContainerItem(bag, slot)
  if cursor then
    bags[bag][slot] = cursor
    cursor, cursorOrigin = nil, nil
  else
    cursor = bags[bag][slot]
    bags[bag][slot] = nil
    cursorOrigin = cursor and { bag = bag, slot = slot } or nil
  end
end

function GetItemCount(itemID)
  local count = 0
  for _, entry in pairs(inventory) do if entry and entry.itemID == itemID then count = count + 1 end end
  for _, bag in pairs(bags) do
    for _, entry in pairs(bag) do if entry and entry.itemID == itemID then count = count + 1 end end
  end
  return count
end
function IsUsableItem(itemID) return not unusable[itemID] end
function GetItemInfo(itemID) return ITEMS[itemID], nil, nil, nil, nil, nil, nil, nil, nil, "icon:" .. itemID end
function GetItemInfoInstant(itemID) return itemID, nil, nil, nil, "icon:" .. itemID end
function GetInventoryItemID(_, slot) return inventory[slot] and inventory[slot].itemID end
function GetInventoryItemLink(_, slot) return inventory[slot] and inventory[slot].hyperlink end
function GetWeaponEnchantInfo() return lureActive, lureRemaining * 1000 end
function GetSpellInfo(spellID)
  if spellID == 7620 then return "Localized Fishing", nil, "icon:fishing" end
end
function IsSpellKnown(spellID) return knownFishing and spellID == knownRank end
function IsInventoryItemLocked() return false end
function CursorHasItem() return cursor ~= nil end
function SpellIsTargeting() return false end
function GetCursorInfo() return cursor and "item" or nil end
function ClearCursor() cursor, cursorOrigin = nil, nil end
function PickupInventoryItem(slot)
  if cursor then
    local displaced = inventory[slot]
    inventory[slot] = cursor
    if cursorOrigin and cursorOrigin.bag then
      bags[cursorOrigin.bag][cursorOrigin.slot] = displaced
      cursor, cursorOrigin = nil, nil
    else
      cursor = displaced
      cursorOrigin = cursor and { inv = slot } or nil
    end
  else
    cursor = inventory[slot]
    inventory[slot] = nil
    cursorOrigin = cursor and { inv = slot } or nil
  end
end
function InCombatLockdown() return combat end
function GetTime() return 0 end
C_Timer = { After = function(_, callback) callback() end }

local addon = { events = {}, Button = { Refresh = function() end } }
function addon:On(event, callback) self.events[event] = callback end
function addon:Print(message) messages[#messages + 1] = message end
assert(loadfile(root .. "/Fishing.lua"))("HelloFish", addon)
local Fishing = addon.Fishing

reset()
knownFishing = false
expect("untrained character is disabled", Fishing:State().kind, "disabled")

reset()
expect("missing pole is disabled", Fishing:State().reason, "Carry a fishing pole in your bags.")

reset()
bags[0][1], bags[0][2] = item(6365), item(19970)
expect("strongest pole wins", Fishing:State().itemID, 19970)
unusable[19970] = true
expect("carried pole remains equippable through secure item action", Fishing:State().itemID, 19970)

reset()
inventory[16] = item(6256)
expect("equipped pole without lures casts", Fishing:State().kind, "cast")
expect("cast uses localized spell name", Fishing:State().name, "Localized Fishing")
knownRank = 18248
expect("Artisan rank still counts as trained", Fishing:State().kind, "cast")

reset()
inventory[16] = item(6256)
bags[0][1], bags[0][2] = item(6529), item(6533)
expect("strongest lure wins", Fishing:State().itemID, 6533)
expect("lure stack count is reported", Fishing:State().count, 1)
unusable[6533] = true
expect("unusable lure is skipped", Fishing:State().itemID, 6529)
lureActive, lureRemaining = true, 359
expect("active lure changes action to cast", Fishing:State().kind, "cast")
expect("active lure time is reported", Fishing:State().lureSeconds, 359)

reset()
inventory[16], inventory[17] = item(1001, "fiery"), item(1002, "stamina")
Fishing:CaptureLoadout()
expect("main-hand enchant identity captured", HelloFishCharDB.loadout.main.link, "item:1001:fiery")
inventory[16] = item(1003)
Fishing:CaptureLoadout()
expect("active snapshot is not overwritten", HelloFishCharDB.loadout.main.itemID, 1001)
expect("same ID with different enchant differs",
  Fishing.SameItem(HelloFishCharDB.loadout.main, "item:1001:plain", 1001), false)

reset()
HelloFishCharDB.loadout = { main = { itemID = 1001, link = "item:1001:fiery" },
  off = { itemID = 1002, link = "item:1002:stamina" } }
inventory[16] = item(6256)
bags[0][1], bags[0][2] = item(1001, "plain"), item(1001, "fiery")
bags[0][3] = item(1002, "stamina")
Fishing:RestoreLoadout()
expect("exact enchanted duplicate restored", inventory[16].hyperlink, "item:1001:fiery")
expect("off-hand restored", inventory[17].itemID, 1002)
expect("successful restore clears snapshot", HelloFishCharDB.loadout, nil)

reset()
HelloFishCharDB.loadout = { main = { itemID = 1001, link = "item:1001:plain" }, off = false }
inventory[16], inventory[17] = item(6256), item(1003)
bags[0][1] = item(1001)
Fishing:RestoreLoadout()
expect("empty off-hand is restored", inventory[17], nil)
expect("displaced off-hand goes to a bag", bags[0][2].itemID, 1003)

reset()
HelloFishCharDB.loadout = { main = { itemID = 1001, link = "item:1001:plain" }, off = false }
inventory[16] = item(6256)
Fishing:RestoreLoadout()
expect("missing weapon keeps snapshot for retry", HelloFishCharDB.loadout ~= nil, true)
expect("missing weapon is reported", messages[#messages], "a saved weapon is no longer in your bags.")

reset()
HelloFishCharDB.loadout = { main = false, off = false }
inventory[16] = item(6256)
for bag = 0, 1 do for slot = 1, 4 do bags[bag][slot] = item(1003) end end
Fishing:RestoreLoadout()
expect("full bags keep snapshot", HelloFishCharDB.loadout ~= nil, true)
expect("full bags are reported", messages[#messages], "not enough bag space to remove the fishing pole.")

reset()
HelloFishCharDB.loadout = { main = false, off = false }
combat = true
Fishing:RestoreLoadout()
expect("combat blocks restoration", Fishing.restoreJob, nil)
expect("combat failure is reported", messages[#messages], "can't restore weapons in combat.")

local buttonAddon = { On = function() end, Fishing = Fishing }
assert(loadfile(root .. "/Button.lua"))("HelloFish", buttonAddon)
expect("default position sits left of HelloWarrior", buttonAddon.Button.DEFAULT_POSITION.x, -168)
expect("default position aligns with HelloWarrior", buttonAddon.Button.DEFAULT_POSITION.y, -160)
expect("equip is assigned to right-click item action",
  buttonAddon.Button.RightItem({ kind = "equip", itemID = 6256 }), "item:6256")
expect("equip state has no left-click action",
  buttonAddon.Button.ActionMacro({ kind = "equip", itemID = 6256 }), "")
expect("global middle-click uses physical button 3", buttonAddon.Button.MIDDLE_BINDING, "BUTTON3")
expect("cast macro uses localized name", buttonAddon.Button.ActionMacro({ kind = "cast", name = "Pêcher" }),
  "#showtooltip Pêcher\n/cast [nocombat] Pêcher")

local configAddon = {}
assert(loadfile(root .. "/Config.lua"))("HelloFish", configAddon)
expect("fishing button is shown by default", configAddon.Config.DEFAULTS.visible, true)

reset()
inventory[16] = item(6256)
local clearedOwner, boundKey, boundFrame, boundButton
function ClearOverrideBindings(owner) clearedOwner = owner end
function SetOverrideBindingClick(_, _, key, frameName, mouseButton)
  boundKey, boundFrame, boundButton = key, frameName, mouseButton
end
local function attributeFrame(name)
  return {
    attributes = {},
    SetAttribute = function(self, key, value) self.attributes[key] = value end,
    GetName = function() return name end,
  }
end
buttonAddon.Button.bindingOwner = {}
buttonAddon.Button.middleButton = attributeFrame("HelloFishMiddleCastButton")
buttonAddon.Button.frame = attributeFrame("HelloFishButton")
buttonAddon.Button:ApplyMiddleBinding()
expect("middle binding owner is isolated", clearedOwner, buttonAddon.Button.bindingOwner)
expect("pole enables global middle binding", buttonAddon.Button.middleBound, true)
expect("middle binding key is BUTTON3", boundKey, "BUTTON3")
expect("middle binding targets secure cast button", boundFrame, "HelloFishMiddleCastButton")
expect("middle binding dispatches a secure left click", boundButton, "LeftButton")
inventory[16] = item(1001)
buttonAddon.Button:ApplyMiddleBinding()
expect("removing pole releases middle binding", buttonAddon.Button.middleBound, false)

if failures == 0 then
  print(("PASS — %d checks"):format(checks))
else
  print(("FAIL — %d of %d checks failed"):format(failures, checks))
end
os.exit(failures == 0 and 0 or 1)
