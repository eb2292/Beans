local ADDON_NAME = ...

local DEFAULTS = {
  dayKey = nil,
  weekKey = nil,
  dailyNet = 0,
  weeklyNet = 0,
  lastMoney = nil,
  options = {
    lockFrame = false,
    showFrame = true,
    display = "daily",
  },
  framePoint = nil,
}

local function GetDayKey()
  return date("%Y-%m-%d")
end

local function GetWeekKey()
  return date("%Y-%U")
end

local function FormatMoney(amount)
  local copper = math.abs(amount)
  local sign = amount < 0 and "-" or ""
  return sign .. GetCoinTextureString(copper)
end

local function EnsureDefaults()
  if not BeansDB then
    BeansDB = {}
  end

  for key, value in pairs(DEFAULTS) do
    if BeansDB[key] == nil then
      if type(value) == "table" then
        BeansDB[key] = {}
        for innerKey, innerValue in pairs(value) do
          BeansDB[key][innerKey] = innerValue
        end
      else
        BeansDB[key] = value
      end
    elseif type(value) == "table" then
      for innerKey, innerValue in pairs(value) do
        if BeansDB[key][innerKey] == nil then
          BeansDB[key][innerKey] = innerValue
        end
      end
    end
  end
end

local function ResetIfNeeded()
  local dayKey = GetDayKey()
  local weekKey = GetWeekKey()

  if BeansDB.dayKey ~= dayKey then
    BeansDB.dayKey = dayKey
    BeansDB.dailyNet = 0
  end

  if BeansDB.weekKey ~= weekKey then
    BeansDB.weekKey = weekKey
    BeansDB.weeklyNet = 0
  end
end

local function UpdateFrameText(frame)
  if not frame then
    return
  end

  local display = BeansDB.options.display
  local value = display == "weekly" and BeansDB.weeklyNet or BeansDB.dailyNet
  local label = display == "weekly" and "Week" or "Day"
  frame.text:SetText(label .. ": " .. FormatMoney(value))
end

local function SaveFramePosition(frame)
  local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
  BeansDB.framePoint = {
    point = point,
    relativePoint = relativePoint,
    x = xOfs,
    y = yOfs,
  }
end

local function RestoreFramePosition(frame)
  if not BeansDB.framePoint then
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    return
  end

  frame:SetPoint(
    BeansDB.framePoint.point,
    UIParent,
    BeansDB.framePoint.relativePoint,
    BeansDB.framePoint.x,
    BeansDB.framePoint.y
  )
end

local function CreateFrameUI()
  local frame = CreateFrame("Button", "BeansFrame", UIParent)
  frame:SetSize(140, 20)
  frame:SetFrameStrata("MEDIUM")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:RegisterForDrag("LeftButton")

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)

  frame:SetScript("OnDragStart", function(self)
    if BeansDB.options.lockFrame then
      return
    end
    self:StartMoving()
  end)

  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self)
  end)

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 2)
    GameTooltip:AddLine("Beans")
    GameTooltip:AddLine("Daily net: " .. FormatMoney(BeansDB.dailyNet), 1, 1, 1)
    GameTooltip:AddLine("Weekly net: " .. FormatMoney(BeansDB.weeklyNet), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("/beans for options", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  frame:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      BeansDB.options.display = BeansDB.options.display == "weekly" and "daily" or "weekly"
      UpdateFrameText(frame)
    end
  end)

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)

  RestoreFramePosition(frame)
  UpdateFrameText(frame)

  if BeansDB.options.showFrame then
    frame:Show()
  else
    frame:Hide()
  end

  return frame
end

local function PrintMessage(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff8bc34aBeans:|r " .. message)
end

local function HandleSlashCommand(msg)
  local command = string.lower(msg or "")

  if command == "lock" then
    BeansDB.options.lockFrame = true
    PrintMessage("Frame locked.")
  elseif command == "unlock" then
    BeansDB.options.lockFrame = false
    PrintMessage("Frame unlocked.")
  elseif command == "show" then
    BeansDB.options.showFrame = true
    BeansFrame:Show()
    PrintMessage("Frame shown.")
  elseif command == "hide" then
    BeansDB.options.showFrame = false
    BeansFrame:Hide()
    PrintMessage("Frame hidden.")
  elseif command == "reset day" then
    BeansDB.dailyNet = 0
    BeansDB.dayKey = GetDayKey()
    UpdateFrameText(BeansFrame)
    PrintMessage("Daily totals reset.")
  elseif command == "reset week" then
    BeansDB.weeklyNet = 0
    BeansDB.weekKey = GetWeekKey()
    UpdateFrameText(BeansFrame)
    PrintMessage("Weekly totals reset.")
  elseif command == "reset all" then
    BeansDB.dailyNet = 0
    BeansDB.weeklyNet = 0
    BeansDB.dayKey = GetDayKey()
    BeansDB.weekKey = GetWeekKey()
    UpdateFrameText(BeansFrame)
    PrintMessage("Daily and weekly totals reset.")
  elseif command == "display daily" then
    BeansDB.options.display = "daily"
    UpdateFrameText(BeansFrame)
    PrintMessage("Frame display set to daily net.")
  elseif command == "display weekly" then
    BeansDB.options.display = "weekly"
    UpdateFrameText(BeansFrame)
    PrintMessage("Frame display set to weekly net.")
  else
    PrintMessage("Commands:")
    PrintMessage("/beans lock - Lock the frame.")
    PrintMessage("/beans unlock - Unlock the frame for dragging.")
    PrintMessage("/beans show - Show the frame.")
    PrintMessage("/beans hide - Hide the frame.")
    PrintMessage("/beans reset day - Reset daily net.")
    PrintMessage("/beans reset week - Reset weekly net.")
    PrintMessage("/beans reset all - Reset daily and weekly net.")
    PrintMessage("/beans display daily - Show daily net on the frame.")
    PrintMessage("/beans display weekly - Show weekly net on the frame.")
    PrintMessage("Right-click the icon to toggle daily/weekly display.")
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    EnsureDefaults()
    ResetIfNeeded()
    CreateFrameUI()
    BeansDB.lastMoney = GetMoney()
  elseif event == "PLAYER_MONEY" then
    if not BeansDB.lastMoney then
      BeansDB.lastMoney = GetMoney()
      return
    end

    ResetIfNeeded()

    local currentMoney = GetMoney()
    local diff = currentMoney - BeansDB.lastMoney
    BeansDB.lastMoney = currentMoney
    BeansDB.dailyNet = BeansDB.dailyNet + diff
    BeansDB.weeklyNet = BeansDB.weeklyNet + diff
    UpdateFrameText(BeansFrame)
  end
end)

SLASH_BEANS1 = "/beans"
SlashCmdList.BEANS = HandleSlashCommand
