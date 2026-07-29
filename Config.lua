local _, addon = ...

addon.Config = {}
local Config = addon.Config

local DEFAULTS = {
  visible = true,
  locked = false,
  scale = 1,
}
Config.DEFAULTS = DEFAULTS

local function applyDefaults(target, defaults)
  for key, value in pairs(defaults) do
    if target[key] == nil then target[key] = value end
  end
end

function Config:Init()
  HelloFishDB = HelloFishDB or {}
  HelloFishCharDB = HelloFishCharDB or {}
  applyDefaults(HelloFishDB, DEFAULTS)
end

function Config:SetVisible(visible)
  if InCombatLockdown() then
    addon:Print("can't show or hide the fishing button in combat.")
    return
  end
  HelloFishDB.visible = visible and true or false
  if addon.Button.frame then addon.Button.frame:SetShown(HelloFishDB.visible) end
  addon:Print(HelloFishDB.visible and "button shown." or "button hidden.")
  self:SyncPanel()
end

function Config:SetLocked(locked)
  HelloFishDB.locked = locked and true or false
  addon:Print(locked and "button locked." or "button unlocked; Shift-drag it to move.")
  self:SyncPanel()
end

function Config:SetScale(scale)
  if InCombatLockdown() then return end
  scale = math.max(0.6, math.min(1.6, scale))
  HelloFishDB.scale = math.floor(scale * 20 + 0.5) / 20
  if addon.Button.frame then addon.Button.frame:SetScale(HelloFishDB.scale) end
end

function Config:ResetPosition()
  HelloFishDB.position = nil
  if addon.Button.frame then addon.Button:ApplyPosition() end
  addon:Print("button position reset.")
end

function Config:SyncPanel()
  if not self.panel then return end
  if self.visibleCheck then self.visibleCheck:SetChecked(HelloFishDB.visible) end
  if self.lockCheck then self.lockCheck:SetChecked(HelloFishDB.locked) end
  if self.scaleSlider then self.scaleSlider:SetValue(HelloFishDB.scale) end
end

local function makeCheck(parent, name, label, anchor, y)
  local check = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
  check:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, y)
  _G[name .. "Text"]:SetText(label)
  return check
end

function Config:CreatePanel()
  if self.panel then return end
  local panel = CreateFrame("Frame")
  panel.name = "HelloFish"

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", 16, -16)
  title:SetText("HelloFish")
  local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
  subtitle:SetText("One-button fishing helper for WoW Classic Era.")

  local visible = makeCheck(panel, "HelloFishVisibleCheck", "Show fishing button", subtitle, -18)
  local locked = makeCheck(panel, "HelloFishLockedCheck", "Lock button position", visible, -6)
  visible:SetScript("OnClick", function(self) Config:SetVisible(self:GetChecked()) end)
  locked:SetScript("OnClick", function(self) Config:SetLocked(self:GetChecked()) end)

  local slider = CreateFrame("Slider", "HelloFishScaleSlider", panel, "OptionsSliderTemplate")
  slider:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 4, -30)
  slider:SetWidth(220)
  slider:SetMinMaxValues(0.6, 1.6)
  slider:SetValueStep(0.05)
  slider:SetObeyStepOnDrag(true)
  if slider.Low then slider.Low:SetText("0.6") end
  if slider.High then slider.High:SetText("1.6") end
  if slider.Text then slider.Text:SetText("Button scale") end
  local scaleValue = slider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  scaleValue:SetPoint("LEFT", slider, "RIGHT", 12, 0)
  slider:SetScript("OnValueChanged", function(_, value)
    Config:SetScale(value)
    scaleValue:SetText(("%.2f"):format(HelloFishDB.scale))
  end)

  local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  reset:SetSize(120, 22)
  reset:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -4, -28)
  reset:SetText("Reset position")
  reset:SetScript("OnClick", function() Config:ResetPosition() end)

  local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  help:SetPoint("TOPLEFT", reset, "BOTTOMLEFT", 0, -18)
  help:SetJustifyH("LEFT")
  help:SetText("Right-click: equip the best pole or restore your saved weapons.\n" ..
    "Left-click: apply the strongest lure or cast Fishing.\n" ..
    "With a pole equipped, middle-click anywhere to cast Fishing.\n" ..
    "Shift-drag while unlocked to move the button.\n\n" ..
    "Key bindings are under Esc > Options > Keybindings > HelloFish.")

  panel:SetScript("OnShow", function() Config:SyncPanel() end)
  if Settings and Settings.RegisterCanvasLayoutCategory then
    local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
    Settings.RegisterAddOnCategory(category)
    self.category = category
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
  end

  self.panel = panel
  self.visibleCheck = visible
  self.lockCheck = locked
  self.scaleSlider = slider
  self:SyncPanel()
end

function Config:OpenPanel()
  if Settings and Settings.OpenToCategory and self.category then
    Settings.OpenToCategory(self.category:GetID())
  elseif InterfaceOptionsFrame_OpenToCategory and self.panel then
    InterfaceOptionsFrame_OpenToCategory(self.panel)
    InterfaceOptionsFrame_OpenToCategory(self.panel)
  end
end
