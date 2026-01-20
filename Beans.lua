local ADDON_NAME = ...

local CHARACTER_DEFAULTS = {
  dayKey = nil,
  weekKey = nil,
  dailyNet = 0,
  dailyIn = 0,
  dailyOut = 0,
  weeklyNet = 0,
  sessionNet = 0,
  lastMoney = nil,
  options = {
    lockFrame = false,
    showFrame = true,
    display = "session",
  },
  framePoint = nil,
}

local function GetDayKey()
  return date("%Y-%m-%d")
end

local function GetWeekKey()
  return date("%Y-%U")
end

local function GetCharacterKey()
  local name, realm = UnitName("player")
  if not name then
    return "unknown"
  end
  realm = realm or GetRealmName() or "unknown"
  return name .. "-" .. realm
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

  if not BeansDB.characters then
    BeansDB.characters = {}
  end
end

local function GetCharacterData()
  EnsureDefaults()
  local characterKey = GetCharacterKey()
  if not BeansDB.characters[characterKey] then
    BeansDB.characters[characterKey] = {}
  end

  local data = BeansDB.characters[characterKey]
  for key, value in pairs(CHARACTER_DEFAULTS) do
    if data[key] == nil then
      if type(value) == "table" then
        data[key] = {}
        for innerKey, innerValue in pairs(value) do
          data[key][innerKey] = innerValue
        end
      else
        data[key] = value
      end
    elseif type(value) == "table" then
      for innerKey, innerValue in pairs(value) do
        if data[key][innerKey] == nil then
          data[key][innerKey] = innerValue
        end
      end
    end
  end

  return data
end

local function ResetIfNeeded(data)
  local dayKey = GetDayKey()
  local weekKey = GetWeekKey()

  if data.dayKey ~= dayKey then
    data.dayKey = dayKey
    data.dailyNet = 0
    data.dailyIn = 0
    data.dailyOut = 0
  end

  if data.weekKey ~= weekKey then
    data.weekKey = weekKey
    data.weeklyNet = 0
  end
end

local function UpdateFrameText(frame, data)
  if not frame then
    return
  end

  local display = data.options.display
  local value
  local label
  if display == "weekly" then
    value = data.weeklyNet
    label = "Week"
  elseif display == "daily" then
    value = data.dailyNet
    label = "Day"
  else
    value = data.sessionNet
    label = "Session"
  end
  frame.text:SetText(label .. ": " .. FormatMoney(value))
end

local function SaveFramePosition(frame, data)
  local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
  data.framePoint = {
    point = point,
    relativePoint = relativePoint,
    x = xOfs,
    y = yOfs,
  }
end

local function RestoreFramePosition(frame, data)
  if not data.framePoint then
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    return
  end

  frame:SetPoint(
    data.framePoint.point,
    UIParent,
    data.framePoint.relativePoint,
    data.framePoint.x,
    data.framePoint.y
  )
end

local function CreateFrameUI(data)
  local frame = CreateFrame("Button", "BeansFrame", UIParent)
  frame:SetSize(140, 20)
  frame:SetFrameStrata("MEDIUM")
  frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  frame:RegisterForDrag("LeftButton")

  frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.text:SetPoint("LEFT", frame, "LEFT", 0, 0)

  frame:SetScript("OnDragStart", function(self)
    if data.options.lockFrame then
      return
    end
    self:StartMoving()
  end)

  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveFramePosition(self, data)
  end)

  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 2)
    GameTooltip:AddLine("Beans")
    GameTooltip:AddLine("Daily net: " .. FormatMoney(data.dailyNet), 1, 1, 1)
    GameTooltip:AddLine("Daily in: " .. FormatMoney(data.dailyIn), 1, 1, 1)
    GameTooltip:AddLine("Daily out: " .. FormatMoney(data.dailyOut), 1, 1, 1)
    GameTooltip:AddLine("Weekly net: " .. FormatMoney(data.weeklyNet), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("/beans for options", 0.8, 0.8, 0.8)
    GameTooltip:Show()
  end)

  frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  frame:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
      if data.options.display == "session" then
        data.options.display = "daily"
      elseif data.options.display == "daily" then
        data.options.display = "weekly"
      else
        data.options.display = "session"
      end
      UpdateFrameText(frame, data)
    end
  end)

  frame:SetMovable(true)
  frame:SetClampedToScreen(true)

  RestoreFramePosition(frame, data)
  UpdateFrameText(frame, data)

  if data.options.showFrame then
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
  local data = GetCharacterData()
  local command = string.lower(msg or "")

  if command == "lock" then
    data.options.lockFrame = true
    PrintMessage("Frame locked.")
  elseif command == "unlock" then
    data.options.lockFrame = false
    PrintMessage("Frame unlocked.")
  elseif command == "show" then
    data.options.showFrame = true
    BeansFrame:Show()
    PrintMessage("Frame shown.")
  elseif command == "hide" then
    data.options.showFrame = false
    BeansFrame:Hide()
    PrintMessage("Frame hidden.")
  elseif command == "reset day" then
    data.dailyNet = 0
    data.dailyIn = 0
    data.dailyOut = 0
    data.dayKey = GetDayKey()
    UpdateFrameText(BeansFrame, data)
    PrintMessage("Daily totals reset.")
  elseif command == "reset week" then
    data.weeklyNet = 0
    data.weekKey = GetWeekKey()
    UpdateFrameText(BeansFrame, data)
    PrintMessage("Weekly totals reset.")
  elseif command == "reset all" then
    data.dailyNet = 0
    data.dailyIn = 0
    data.dailyOut = 0
    data.weeklyNet = 0
    data.dayKey = GetDayKey()
    data.weekKey = GetWeekKey()
    UpdateFrameText(BeansFrame, data)
    PrintMessage("Daily and weekly totals reset.")
  elseif command == "display session" then
    data.options.display = "session"
    UpdateFrameText(BeansFrame, data)
    PrintMessage("Frame display set to session net.")
  elseif command == "display daily" then
    data.options.display = "daily"
    UpdateFrameText(BeansFrame, data)
    PrintMessage("Frame display set to daily net.")
  elseif command == "display weekly" then
    data.options.display = "weekly"
    UpdateFrameText(BeansFrame, data)
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
    PrintMessage("/beans display session - Show session net on the frame.")
    PrintMessage("/beans display daily - Show daily net on the frame.")
    PrintMessage("/beans display weekly - Show weekly net on the frame.")
    PrintMessage("Right-click the icon to toggle session/daily/weekly display.")
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    local data = GetCharacterData()
    ResetIfNeeded(data)
    data.sessionNet = 0
    CreateFrameUI(data)
    data.lastMoney = GetMoney()
  elseif event == "PLAYER_MONEY" then
    local data = GetCharacterData()
    if not data.lastMoney then
      data.lastMoney = GetMoney()
      return
    end

    ResetIfNeeded(data)

    local currentMoney = GetMoney()
    local diff = currentMoney - data.lastMoney
    data.lastMoney = currentMoney
    data.dailyNet = data.dailyNet + diff
    data.weeklyNet = data.weeklyNet + diff
    data.sessionNet = data.sessionNet + diff
    if diff > 0 then
      data.dailyIn = data.dailyIn + diff
    elseif diff < 0 then
      data.dailyOut = data.dailyOut + (-diff)
    end
    UpdateFrameText(BeansFrame, data)
  end
end)

SLASH_BEANS1 = "/beans"
SlashCmdList.BEANS = HandleSlashCommand
