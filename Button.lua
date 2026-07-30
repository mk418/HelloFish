local _, addon = ...

addon.Button = {}
local Button = addon.Button

Button.SIZE = 36
Button.BORDER_SIZE = 66
Button.MIDDLE_BINDING = "BUTTON3"
Button.DEFAULT_POSITION = {
  -- Aligned 2px above the leftmost button in HelloUI's right-hand 4x3 block.
  point = "BOTTOM",
  relativePoint = "BOTTOM",
  x = 265,
  y = 144,
}

local function actionMacro(state)
  if state.kind == "lure" then
    return ("#showtooltip item:%d\n/use [nocombat] item:%d\n/use [nocombat] 16")
      :format(state.itemID, state.itemID)
  elseif state.kind == "cast" then
    return ("#showtooltip %s\n/cast [nocombat] %s"):format(state.name, state.name)
  end
  return ""
end
Button.ActionMacro = actionMacro

local function rightItem(state)
  if state.kind == "equip" then return "item:" .. state.itemID end
end
Button.RightItem = rightItem

function Button:ApplyPosition()
  local frame = self.frame
  if not frame then return end
  frame:ClearAllPoints()
  local position = HelloFishDB.position
  if position then
    frame:SetPoint(position.point, UIParent, position.relativePoint, position.x, position.y)
  else
    local default = self.DEFAULT_POSITION
    frame:SetPoint(default.point, UIParent, default.relativePoint, default.x, default.y)
  end
end

function Button:SavePosition()
  local point, _, relativePoint, x, y = self.frame:GetPoint(1)
  HelloFishDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

function Button:ShouldShow()
  return HelloFishDB.visible and addon.Fishing:BestPole() ~= nil
end

function Button:ApplyVisibility()
  if not self.frame or InCombatLockdown() then return end
  self.frame:SetShown(self:ShouldShow())
end

function Button:UpdateVisual(state)
  local frame = self.frame
  frame.icon:SetTexture(state.icon or "Interface\\Icons\\Trade_Fishing")
  frame.icon:SetDesaturated(state.kind == "disabled")
end

function Button:Refresh()
  if not self.frame then return end
  local state = addon.Fishing:State()
  self.state = state
  self:UpdateVisual(state)
  if InCombatLockdown() then
    self.pendingRefresh = true
    return
  end
  self.pendingRefresh = nil
  self:ApplyVisibility()
  local leftMacro = actionMacro(state)
  self.frame:SetAttribute("type1", leftMacro ~= "" and "macro" or nil)
  self.frame:SetAttribute("macrotext1", leftMacro ~= "" and leftMacro or nil)

  -- Right-click is the fishing-mode toggle. A secure item action equips the
  -- selected pole; once a pole is worn, PreClick handles restoration instead.
  local poleItem = rightItem(state)
  self.frame:SetAttribute("type2", poleItem and "item" or nil)
  self.frame:SetAttribute("item2", poleItem)
  self:ApplyMiddleBinding()
end

function Button:ApplyMiddleBinding()
  if InCombatLockdown() or not self.bindingOwner or not self.middleButton then return end
  ClearOverrideBindings(self.bindingOwner)

  local spellName = addon.Fishing:FishingSpell()
  local macro = spellName and ("#showtooltip %s\n/cast [nocombat] %s"):format(spellName, spellName) or ""
  self.middleButton:SetAttribute("type1", macro ~= "" and "macro" or nil)
  self.middleButton:SetAttribute("macrotext1", macro ~= "" and macro or nil)
  self.frame:SetAttribute("type3", macro ~= "" and "macro" or nil)
  self.frame:SetAttribute("macrotext3", macro ~= "" and macro or nil)

  self.middleBound = addon.Fishing:EquippedPole() ~= nil and macro ~= ""
  if self.middleBound then
    SetOverrideBindingClick(self.bindingOwner, true, self.MIDDLE_BINDING,
      self.middleButton:GetName(), "LeftButton")
  end
end

function Button:ShowTooltip()
  local state = self.state or addon.Fishing:State()
  GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
  GameTooltip:SetText("HelloFish")
  if state.kind == "equip" then
    GameTooltip:AddLine("Right-click: equip " .. state.name, 1, 1, 1, true)
  elseif state.kind == "lure" then
    GameTooltip:AddLine("Left-click: apply " .. state.name, 1, 1, 1, true)
    GameTooltip:AddLine("Right-click: restore saved weapons", 0.75, 0.75, 0.75)
  elseif state.kind == "cast" then
    GameTooltip:AddLine("Left-click: cast Fishing", 1, 1, 1, true)
    GameTooltip:AddLine("Middle-click anywhere: cast Fishing", 0.35, 0.9, 1, true)
    GameTooltip:AddLine("Right-click: restore saved weapons", 0.75, 0.75, 0.75)
  else
    GameTooltip:AddLine(state.reason or "Fishing unavailable", 1, 0.35, 0.25, true)
  end
  if not HelloFishDB.locked then
    GameTooltip:AddLine("Shift-drag: move", 0.75, 0.75, 0.75)
  end
  GameTooltip:Show()
end

function Button:Build()
  if self.frame then return end
  local frame = CreateFrame("Button", "HelloFishButton", UIParent, "SecureActionButtonTemplate")
  frame:SetSize(self.SIZE, self.SIZE)
  frame:RegisterForClicks("AnyUp")
  frame:SetAttribute("useOnKeyDown", false)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:RegisterForDrag("LeftButton")

  -- The always-shown, mouse-disabled secure button is the target of the
  -- temporary BUTTON3 override. Its invisibility does not block secure binding
  -- dispatch, and it never covers or intercepts any part of the UI.
  local bindingOwner = CreateFrame("Frame", "HelloFishMiddleBindOwner")
  local middle = CreateFrame("Button", "HelloFishMiddleCastButton", UIParent,
    "SecureActionButtonTemplate")
  middle:SetSize(1, 1)
  middle:SetPoint("CENTER")
  middle:SetAlpha(0)
  middle:EnableMouse(false)
  middle:RegisterForClicks("AnyUp")
  middle:SetAttribute("useOnKeyDown", false)
  self.bindingOwner = bindingOwner
  self.middleButton = middle

  local icon = frame:CreateTexture(nil, "BACKGROUND")
  icon:SetAllPoints(frame)
  icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  frame.icon = icon
  local border = frame:CreateTexture(nil, "ARTWORK")
  border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
  border:SetSize(self.BORDER_SIZE, self.BORDER_SIZE)
  border:SetPoint("CENTER", frame, "CENTER", 0, -1)
  border:SetAlpha(0.5)

  frame:SetScript("PreClick", function(_, mouseButton)
    if mouseButton == "RightButton" and not InCombatLockdown()
        and Button.state and Button.state.kind == "equip" then
      addon.Fishing:CaptureLoadout()
    elseif mouseButton == "RightButton" then
      addon.Fishing:RestoreLoadout()
    end
  end)
  frame:SetScript("OnEnter", function() Button:ShowTooltip() end)
  frame:SetScript("OnLeave", GameTooltip_Hide)
  frame:SetScript("OnDragStart", function(self)
    if not HelloFishDB.locked and IsShiftKeyDown() and not InCombatLockdown() then
      self:StartMoving()
    end
  end)
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    Button:SavePosition()
  end)

  self.frame = frame
  self:ApplyPosition()
  frame:SetScale(HelloFishDB.scale)
  self:ApplyVisibility()
  self:Refresh()
end

local function refreshForUnit(unit)
  if unit and unit ~= "player" then return end
  Button:Refresh()
end

for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "SPELLS_CHANGED",
    "SKILL_LINES_CHANGED", "GET_ITEM_INFO_RECEIVED", "PLAYER_REGEN_DISABLED" }) do
  addon:On(event, function() Button:Refresh() end)
end
addon:On("UNIT_INVENTORY_CHANGED", refreshForUnit)
addon:On("PLAYER_REGEN_ENABLED", function() Button:Refresh() end)
