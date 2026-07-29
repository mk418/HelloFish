local ADDON_NAME, addon = ...

addon.ADDON_NAME = ADDON_NAME
addon.events = {}

_G.BINDING_HEADER_HELLOFISH = "HelloFish"
_G["BINDING_NAME_CLICK HelloFishButton:LeftButton"] = "Use fishing helper"
_G["BINDING_NAME_CLICK HelloFishButton:RightButton"] = "Equip pole / restore weapons"

local frame = CreateFrame("Frame")
addon.eventFrame = frame

function addon:On(event, handler)
  local handlers = self.events[event]
  if not handlers then
    handlers = {}
    self.events[event] = handlers
    frame:RegisterEvent(event)
  end
  handlers[#handlers + 1] = handler
end

frame:SetScript("OnEvent", function(_, event, ...)
  local handlers = addon.events[event]
  if not handlers then return end
  for i = 1, #handlers do
    local ok, err = pcall(handlers[i], ...)
    if not ok then
      addon:Print(("error handling %s: %s"):format(event, tostring(err)))
    end
  end
end)

function addon:Print(message)
  print("|cff58c7e8HelloFish:|r " .. tostring(message))
end

addon:On("ADDON_LOADED", function(name)
  if name ~= ADDON_NAME then return end
  addon.Config:Init()
end)

addon:On("PLAYER_LOGIN", function()
  addon.Fishing:RequestItemData()
  addon.Button:Build()
  addon.Config:CreatePanel()
  addon:Print("loaded — right-click the button to equip a pole; middle-click anywhere to fish.")
end)

local function trim(message)
  return (message or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
end

local function requireOutOfCombat()
  if not InCombatLockdown() then return true end
  addon:Print("can't change the fishing button in combat.")
  return false
end

SLASH_HELLOFISH1 = "/hf"
SLASH_HELLOFISH2 = "/hellofish"
SlashCmdList.HELLOFISH = function(message)
  local command = trim(message)
  if command == "" then
    if not requireOutOfCombat() then return end
    addon.Config:SetVisible(not HelloFishDB.visible)
  elseif command == "show" then
    if requireOutOfCombat() then addon.Config:SetVisible(true) end
  elseif command == "hide" then
    if requireOutOfCombat() then addon.Config:SetVisible(false) end
  elseif command == "lock" then
    addon.Config:SetLocked(true)
  elseif command == "unlock" then
    addon.Config:SetLocked(false)
  elseif command == "config" then
    addon.Config:OpenPanel()
  elseif command == "resetpos" then
    if requireOutOfCombat() then addon.Config:ResetPosition() end
  elseif command == "reset" then
    if not requireOutOfCombat() then return end
    HelloFishDB = nil
    HelloFishCharDB = nil
    ReloadUI()
  else
    addon:Print("commands: /hf show | hide | lock | unlock | config | resetpos | reset")
  end
end
