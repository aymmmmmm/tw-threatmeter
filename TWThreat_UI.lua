-- TWThreat UI Module
-- Implements all visual components in pure Lua, matching ShaguDPS visual style.
-- Requires TWT_L (localization table) to be loaded first.

local L = TWT_L

TWTUI = {}
TWTUI.bars = {}

-- ============================================================================
-- Backdrops (matching ShaguDPS)
-- ============================================================================

local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

TWTUI.backdrop_window = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

TWTUI.backdrop_border = {
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local backdrop_window = TWTUI.backdrop_window
local backdrop_border = TWTUI.backdrop_border

-- Default bar texture
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

-- ============================================================================
-- Settings callback stub (TWThreat.lua overrides this)
-- ============================================================================

TWTUI.settingsCallback = function(key, value) end

-- ============================================================================
-- Helper: button tooltip handlers
-- ============================================================================

function TWTUI.btnEnter()
  if this.tooltip then
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    for i, data in pairs(this.tooltip) do
      if type(data) == "string" then
        GameTooltip:AddLine(data)
      elseif type(data) == "table" then
        GameTooltip:AddDoubleLine(data[1], data[2])
      end
    end
    GameTooltip:Show()
  end
  this:SetBackdropBorderColor(1, .8, 0, 1)
end

function TWTUI.btnLeave()
  if this.tooltip then
    GameTooltip:Hide()
  end
  this:SetBackdropBorderColor(.4, .4, .4, 1)
end

-- ============================================================================
-- Helper: CreateConfig (matching ShaguDPS settings pattern)
-- ============================================================================

function TWTUI.CreateConfig(parent, caption, entry, check)
  parent.entries = parent.entries and parent.entries + 1 or 1

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  text:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -parent.entries * 18 - 4)
  text:SetWidth(140)
  text:SetHeight(18)
  text:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  text:SetJustifyH("LEFT")
  text:SetText(caption)

  if check == "header" then
    text:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, -parent.entries * 18 - 8)
    text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
    text:SetTextColor(1, .8, 0)
    return
  end

  if check == "boolean" then
    local input = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
    input:SetHeight(18)
    input:SetWidth(18)
    input:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -parent.entries * 18 - 8)

    input:SetScript("OnShow", function()
      local val = TWT_CONFIG and TWT_CONFIG[entry]
      if val == true or val == 1 then
        this:SetChecked(true)
      else
        this:SetChecked(false)
      end
    end)

    input:SetScript("OnClick", function()
      local val = this:GetChecked() and true or false
      if TWT_CONFIG then
        TWT_CONFIG[entry] = val
      end
      TWTUI.settingsCallback(entry, val)
    end)

    input:Show()
    return input
  end

  if check == "number" or type(check) == "table" then
    local values = type(check) == "table" and check or nil
    local input = TWTUI.CreateSelector(parent, values)
    input.entry = entry
    input:Show()
    return input
  end
end

-- ============================================================================
-- Helper: CreateSelector (matching ShaguDPS number/list selector)
-- ============================================================================

function TWTUI.CreateSelector(parent, values)
  local input = CreateFrame("Frame", nil, parent)
  input.values = values

  input:Hide()
  input:SetHeight(18)
  input:SetWidth(values and 112 or 54)
  input:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, -parent.entries * 18 - 4)
  input:SetBackdrop(backdrop)
  input:SetBackdropColor(.2, .2, .2, 1)
  input:SetBackdropBorderColor(.4, .4, .4, 1)
  input:SetScript("OnShow", function() input:change() end)

  input.texture = input:CreateTexture()
  input.texture:SetPoint("TOPLEFT", input, "TOPLEFT", 13, -3)
  input.texture:SetPoint("BOTTOMRIGHT", input, "BOTTOMRIGHT", -13, 3)
  input.texture:SetVertexColor(.8, .4, .2)

  input.caption = input:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.caption:SetText("--")
  input.caption:SetAllPoints()

  input.left = CreateFrame("Button", nil, input)
  input.left:SetPoint("LEFT", input, "LEFT", 1, 0)
  input.left:SetWidth(12)
  input.left:SetHeight(16)
  input.left:SetBackdrop(backdrop)
  input.left:SetBackdropColor(.2, .2, .2, 1)
  input.left:SetBackdropBorderColor(.4, .4, .4, 1)
  input.left:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  input.left:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  input.left:SetScript("OnClick", function() input:change(-1) end)
  input.left.caption = input.left:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.left.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.left.caption:SetText("<")
  input.left.caption:SetAllPoints()

  input.right = CreateFrame("Button", nil, input)
  input.right:SetPoint("RIGHT", input, "RIGHT", -1, 0)
  input.right:SetWidth(12)
  input.right:SetHeight(16)
  input.right:SetBackdrop(backdrop)
  input.right:SetBackdropColor(.2, .2, .2, 1)
  input.right:SetBackdropBorderColor(.4, .4, .4, 1)
  input.right:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  input.right:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  input.right:SetScript("OnClick", function() input:change(1) end)
  input.right.caption = input.right:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  input.right.caption:SetFont(STANDARD_TEXT_FONT, 10)
  input.right.caption:SetText(">")
  input.right.caption:SetAllPoints()

  input.change = function(self, mod)
    if not TWT_CONFIG or not self.entry then return end

    local currentVal = TWT_CONFIG[self.entry]
    if currentVal == nil then currentVal = 0 end

    -- For ranged number values with a scale factor
    local scaleFactor = self.scaleFactor
    local displayMin = self.displayMin
    local displayMax = self.displayMax

    if scaleFactor then
      -- Convert stored value to display value
      local displayVal = math.floor(currentVal / scaleFactor + 0.5)
      if mod then
        displayVal = displayVal + mod
        if displayMin and displayVal < displayMin then displayVal = displayMin end
        if displayMax and displayVal > displayMax then displayVal = displayMax end
        currentVal = displayVal * scaleFactor
        TWT_CONFIG[self.entry] = currentVal
        TWTUI.settingsCallback(self.entry, currentVal)
      end
      self.caption:SetText(math.floor(currentVal / scaleFactor + 0.5))
    elseif self.values then
      -- Table-based selector
      local id = currentVal
      if type(id) ~= "number" then id = 1 end
      if mod and self.values[id + mod] then
        id = math.ceil(id + mod)
        TWT_CONFIG[self.entry] = id
        TWTUI.settingsCallback(self.entry, id)
      end
      if self.values[id] then
        local _, _, clean = string.find(self.values[id], ".+\\(.+)")
        self.caption:SetText(clean or self.values[id])
      else
        self.caption:SetText(id)
      end

      -- Texture preview (for texture selector)
      if self.entry == "texture" and self.values[id] then
        self.texture:SetTexture(self.values[id])
      end

      if not self.values[id + 1] then
        self.right:SetAlpha(0.25)
      else
        self.right:SetAlpha(1.00)
      end
      if not self.values[id - 1] then
        self.left:SetAlpha(0.25)
      else
        self.left:SetAlpha(1.00)
      end
    else
      -- Plain number selector
      if mod then
        currentVal = math.ceil(currentVal + mod)
        if displayMin and currentVal < displayMin then currentVal = displayMin end
        if displayMax and currentVal > displayMax then currentVal = displayMax end
        TWT_CONFIG[self.entry] = currentVal
        TWTUI.settingsCallback(self.entry, currentVal)
      end
      self.caption:SetText(currentVal)

      if displayMax and currentVal >= displayMax then
        self.right:SetAlpha(0.25)
      else
        self.right:SetAlpha(1.00)
      end
      if displayMin and currentVal <= displayMin then
        self.left:SetAlpha(0.25)
      else
        self.left:SetAlpha(1.00)
      end
    end
  end

  return input
end

-- Helper to create a number selector with explicit range
local function CreateRangeSelector(parent, entry, displayMin, displayMax, scaleFactor)
  local input = TWTUI.CreateSelector(parent, nil)
  input.entry = entry
  input.displayMin = displayMin
  input.displayMax = displayMax
  input.scaleFactor = scaleFactor
  input:Show()
  return input
end

-- ============================================================================
-- 1. TWTUI.CreateMainWindow()
-- ============================================================================

function TWTUI.CreateMainWindow()
  local frame = CreateFrame("Frame", "TWTMain", UIParent)
  frame.scroll = 0

  frame:SetWidth(300)
  frame:SetHeight(200)
  frame:EnableMouse(true)
  frame:EnableMouseWheel(1)
  frame:SetResizable(true)
  frame:SetMinResize(200, 60)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)

  -- window background
  frame:SetBackdrop(backdrop_window)
  frame:SetBackdropColor(.5, .5, .5, .5)

  -- window border
  frame.border = CreateFrame("Frame", nil, frame)
  frame.border:ClearAllPoints()
  frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.border:SetFrameLevel(100)
  frame.border:SetBackdrop(backdrop_border)
  frame.border:SetBackdropBorderColor(.7, .7, .7, 1)

  -- title bar (20px dark overlay)
  frame.title = frame:CreateTexture(nil, "NORMAL")
  frame.title:SetTexture(0, 0, 0, .6)
  frame.title:SetHeight(20)
  frame.title:SetPoint("TOPLEFT", 2, -2)
  frame.title:SetPoint("TOPRIGHT", -2, -2)

  -- title text (target name)
  frame.caption = frame:CreateFontString("TWTMainTitle", "OVERLAY", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  frame.caption:SetText("|cffabd473TW|cffffffff Threat")
  frame.caption:SetPoint("LEFT", frame.title, "LEFT", 5, 0)
  frame.caption:SetJustifyH("LEFT")

  -- Close button (X)
  frame.btnClose = CreateFrame("Button", nil, frame)
  frame.btnClose:SetPoint("RIGHT", frame.title, "RIGHT", -4, 0)
  frame.btnClose:SetFrameStrata("MEDIUM")
  frame.btnClose:SetHeight(16)
  frame.btnClose:SetWidth(16)
  frame.btnClose:SetBackdrop(backdrop)
  frame.btnClose:SetBackdropColor(.2, .2, .2, 1)
  frame.btnClose:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnClose.tooltip = { L["Close Window"] }
  frame.btnClose:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnClose:SetScript("OnLeave", TWTUI.btnLeave)
  frame.btnClose:SetScript("OnClick", function()
    frame:Hide()
    if TWT_CONFIG then TWT_CONFIG.visible = false end
  end)

  frame.btnClose.tex = frame.btnClose:CreateTexture()
  frame.btnClose.tex:SetWidth(10)
  frame.btnClose.tex:SetHeight(10)
  frame.btnClose.tex:SetPoint("CENTER", 0, 0)
  frame.btnClose.tex:SetTexture("Interface\\AddOns\\ShaguPlates\\img\\close")

  -- Lock/Unlock button
  frame.btnLock = CreateFrame("Button", "TWTMainLockButton", frame)
  frame.btnLock:SetPoint("RIGHT", frame.btnClose, "LEFT", -1, 0)
  frame.btnLock:SetFrameStrata("MEDIUM")
  frame.btnLock:SetHeight(16)
  frame.btnLock:SetWidth(16)
  frame.btnLock:SetBackdrop(backdrop)
  frame.btnLock:SetBackdropColor(.2, .2, .2, 1)
  frame.btnLock:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnLock.tooltip = { L["Lock/Unlock Window"] }
  frame.btnLock:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnLock:SetScript("OnLeave", TWTUI.btnLeave)
  frame.btnLock:SetScript("OnClick", function()
    if TWT_CONFIG then
      TWT_CONFIG.lock = not TWT_CONFIG.lock
      if TWT_CONFIG.lock then
        frame.btnLock.caption:SetText("L")
      else
        frame.btnLock.caption:SetText("U")
      end
      TWTUI.settingsCallback("lock", TWT_CONFIG.lock)
    end
  end)

  frame.btnLock.caption = frame.btnLock:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.btnLock.caption:SetFont(STANDARD_TEXT_FONT, 10)
  frame.btnLock.caption:SetText("U")
  frame.btnLock.caption:SetAllPoints()

  -- Settings button (gear)
  frame.btnSettings = CreateFrame("Button", nil, frame)
  frame.btnSettings:SetPoint("RIGHT", frame.btnLock, "LEFT", -1, 0)
  frame.btnSettings:SetFrameStrata("MEDIUM")
  frame.btnSettings:SetHeight(16)
  frame.btnSettings:SetWidth(16)
  frame.btnSettings:SetBackdrop(backdrop)
  frame.btnSettings:SetBackdropColor(.2, .2, .2, 1)
  frame.btnSettings:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnSettings.tooltip = { L["Open Settings"] }
  frame.btnSettings:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnSettings:SetScript("OnLeave", TWTUI.btnLeave)
  frame.btnSettings:SetScript("OnClick", function()
    if TWTUI.settings then
      if TWTUI.settings:IsShown() then
        TWTUI.settings:Hide()
        TWT.testBars(false)
      else
        TWTUI.settings:Show()
        TWT.testBars(true)
      end
    end
  end)

  frame.btnSettings.tex = frame.btnSettings:CreateTexture()
  frame.btnSettings.tex:SetWidth(10)
  frame.btnSettings.tex:SetHeight(10)
  frame.btnSettings.tex:SetPoint("CENTER", 0, 0)
  frame.btnSettings.tex:SetTexture("Interface\\AddOns\\ShaguDPS\\img\\settings")

  -- Reset button
  frame.btnReset = CreateFrame("Button", nil, frame)
  frame.btnReset:SetPoint("RIGHT", frame.btnSettings, "LEFT", -1, 0)
  frame.btnReset:SetFrameStrata("MEDIUM")
  frame.btnReset:SetHeight(16)
  frame.btnReset:SetWidth(16)
  frame.btnReset:SetBackdrop(backdrop)
  frame.btnReset:SetBackdropColor(.2, .2, .2, 1)
  frame.btnReset:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnReset.tooltip = {
    L["Reset Data"],
    { "|cffffffff" .. L["Click"], "|cffaaaaaa" .. L["Ask to reset all data."] },
    { "|cffffffff" .. L["Shift-Click"], "|cffaaaaaa" .. L["Reset all data."] },
  }
  frame.btnReset:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnReset:SetScript("OnLeave", TWTUI.btnLeave)
  local doReset = function() if TWT and TWT.resetData then TWT.resetData() end end
  frame.btnReset:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      doReset()
    else
      local dialog = StaticPopupDialogs["TWT_QUESTION"]
      dialog.text = L["Do you wish to reset the data?"]
      dialog.OnAccept = doReset
      StaticPopup_Show("TWT_QUESTION")
    end
  end)

  frame.btnReset.tex = frame.btnReset:CreateTexture()
  frame.btnReset.tex:SetWidth(10)
  frame.btnReset.tex:SetHeight(10)
  frame.btnReset.tex:SetPoint("CENTER", 0, 0)
  frame.btnReset.tex:SetTexture("Interface\\AddOns\\ShaguDPS\\img\\reset")

  -- Drag handlers
  frame:SetScript("OnDragStart", function()
    if TWT_CONFIG and not TWT_CONFIG.lock then
      frame:StartMoving()
    end
  end)

  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if TWT_CONFIG then
      TWT_CONFIG.windowPoint = { "CENTER", "UIParent", "BOTTOMLEFT", frame:GetCenter() }
    end
  end)

  -- Mouse wheel scrolling
  frame:SetScript("OnMouseWheel", function()
    frame.scroll = frame.scroll or 0
    if arg1 > 0 then
      frame.scroll = frame.scroll - 1
    else
      frame.scroll = frame.scroll + 1
    end
    frame.scroll = math.max(frame.scroll, 0)
  end)

  -- Resize grip
  frame.btnResize = CreateFrame("Frame", nil, frame)
  frame.btnResize:SetPoint("BOTTOMRIGHT", -3, 3)
  frame.btnResize:SetWidth(12)
  frame.btnResize:SetHeight(12)
  frame.btnResize:EnableMouse(1)
  frame.btnResize.tex = frame.btnResize:CreateTexture(nil, "BACKGROUND")
  frame.btnResize.tex:SetAllPoints()
  frame.btnResize.tex:SetTexture("Interface\\AddOns\\TWThreat\\images\\ResizeGrip")
  frame.btnResize:SetFrameLevel(50)

  frame.btnResize:SetScript("OnMouseDown", function()
    if not this:GetParent().sizing and TWT_CONFIG and not TWT_CONFIG.lock then
      this:GetParent().sizing = true
      this:GetParent():StartSizing("BOTTOMRIGHT")
    end
  end)

  frame.btnResize:SetScript("OnMouseUp", function()
    this:GetParent().sizing = nil
    this:GetParent():StopMovingOrSizing()
    if TWT_CONFIG and TWTUI.mainWindow then
      TWT_CONFIG.windowWidth = TWTUI.mainWindow:GetWidth()
    end
    -- Final Resize to snap height
    this:GetParent():Resize()
  end)

  -- Resize: calculate bars from current height (called every frame during drag, like ShaguDPS)
  frame.Resize = function(self)
    if not TWT_CONFIG then return end
    local width = self:GetWidth()
    local height = self:GetTop() - self:GetBottom()
    local headerH = TWT_CONFIG.labelRow and 40 or 20
    local bars = math.floor((height - headerH) / TWT_CONFIG.barHeight)
    if bars < 0 then bars = 0 end

    TWT_CONFIG.windowWidth = width

    if TWT_CONFIG.visibleBars ~= bars then
      TWT_CONFIG.visibleBars = bars
      -- Snap height to exact bar boundary, preserve width (like ShaguDPS)
      self:SetWidth(width)
      self:SetHeight(TWT_CONFIG.barHeight * bars + headerH + (bars == 0 and 2 or 3))
      if TWT and TWT.updateUI then
        TWT.updateUI('resize')
      end
    end
  end

  -- Update handler: real-time resize + show/hide grip
  frame:SetScript("OnUpdate", function()
    -- Every frame during sizing (no throttle)
    if this.sizing then
      this:Resize()
    end

    -- Throttled: show/hide resize grip
    if (this.tick or 1) > GetTime() then return else this.tick = GetTime() + .2 end
    if TWT_CONFIG and not TWT_CONFIG.lock and MouseIsOver(this) then
      this.btnResize:SetAlpha(.5)
    else
      this.btnResize:SetAlpha(0)
    end
  end)

  -- Load saved position
  frame.LoadPosition = function()
    if TWT_CONFIG and TWT_CONFIG.windowPoint then
      frame:ClearAllPoints()
      frame:SetPoint(unpack(TWT_CONFIG.windowPoint))
    else
      frame:ClearAllPoints()
      frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    if TWT_CONFIG and TWT_CONFIG.windowScale then
      frame:SetScale(TWT_CONFIG.windowScale)
    end
  end

  frame:Hide()
  TWTUI.mainWindow = frame
  return frame
end

-- ============================================================================
-- 2. TWTUI.CreateBar(parent, index)
-- ============================================================================

function TWTUI.CreateBar(parent, index)
  local barHeight = (TWT_CONFIG and TWT_CONFIG.barHeight) or 20
  local spacing = (TWT_CONFIG and TWT_CONFIG.spacing) or 0
  local barTex = (TWT and TWT.textures and TWT_CONFIG and TWT.textures[TWT_CONFIG.texture]) or BAR_TEXTURE

  local bar = CreateFrame("StatusBar", "TWTBar" .. index, parent)
  bar:SetStatusBarTexture(barTex)
  bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 2, -barHeight * (index - 1) - 22)
  bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -2, -barHeight * (index - 1) - 22)
  bar:SetHeight(barHeight - spacing)
  bar:SetFrameLevel(4)
  bar:SetMinMaxValues(0, 100)
  bar:SetValue(0)

  -- Background bar (colored threat portion)
  bar.bg = CreateFrame("StatusBar", nil, bar)
  bar.bg:SetStatusBarTexture(barTex)
  bar.bg:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
  bar.bg:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
  bar.bg:SetStatusBarColor(0.2, 0.2, 0.2, 0.5)
  bar.bg:SetMinMaxValues(0, 100)
  bar.bg:SetValue(100)
  bar.bg:SetFrameLevel(2)

  -- Left text (player name)
  bar.textLeft = bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  bar.textLeft:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  bar.textLeft:SetJustifyH("LEFT")
  bar.textLeft:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, 1)
  bar.textLeft:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -5, 0)

  -- Right text (threat info)
  bar.textRight = bar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  bar.textRight:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  bar.textRight:SetJustifyH("RIGHT")
  bar.textRight:SetPoint("TOPLEFT", bar, "TOPLEFT", 5, 1)
  bar.textRight:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -5, 0)

  -- Role icon (tank/healer, optional)
  bar.roleIcon = bar:CreateTexture(nil, "OVERLAY")
  bar.roleIcon:SetWidth(12)
  bar.roleIcon:SetHeight(12)
  bar.roleIcon:SetPoint("LEFT", bar, "LEFT", 2, 0)
  bar.roleIcon:Hide()

  -- Mouse hover tooltip
  bar:EnableMouse(true)
  bar:SetScript("OnEnter", function()
    if this.tooltipData then
      GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
      if this.tooltipData.name then
        GameTooltip:AddLine(this.tooltipData.name)
      end
      if this.tooltipData.threat then
        GameTooltip:AddDoubleLine("|cffffffff" .. L["Threat"], "|cffffffff" .. this.tooltipData.threat)
      end
      if this.tooltipData.tps then
        GameTooltip:AddDoubleLine("|cffffffff" .. L["TPS"], "|cffffffff" .. this.tooltipData.tps)
      end
      if this.tooltipData.percent then
        GameTooltip:AddDoubleLine("|cffffffff" .. L["% Max"], "|cffffffff" .. this.tooltipData.percent .. "%")
      end
      GameTooltip:Show()
    end
  end)

  bar:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  TWTUI.bars[index] = bar
  return bar
end

-- ============================================================================
-- 3. TWTUI.CreateSettings()
-- ============================================================================

function TWTUI.CreateSettings()
  local frame = CreateFrame("Frame", "TWTSettings", UIParent)
  frame:Hide()
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 32)
  frame:SetWidth(240)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetFrameStrata("DIALOG")

  -- window background
  frame:SetBackdrop(backdrop_window)
  frame:SetBackdropColor(.5, .5, .5, .9)

  -- window border
  frame.border = CreateFrame("Frame", nil, frame)
  frame.border:ClearAllPoints()
  frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.border:SetFrameLevel(100)
  frame.border:SetBackdrop(backdrop_border)
  frame.border:SetBackdropBorderColor(.7, .7, .7, 1)

  -- title bar
  frame.title = frame:CreateTexture(nil, "NORMAL")
  frame.title:SetTexture(0, 0, 0, .6)
  frame.title:SetHeight(20)
  frame.title:SetPoint("TOPLEFT", 2, -2)
  frame.title:SetPoint("TOPRIGHT", -2, -2)

  frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  frame.caption:SetText(TWT.addonName .. " |cffabd473v" .. TWT.addonVer .. "|cffffffff - " .. L["Settings"])
  frame.caption:SetAllPoints(frame.title)

  -- Close button
  frame.btnClose = CreateFrame("Button", nil, frame)
  frame.btnClose:SetPoint("RIGHT", frame.title, "RIGHT", -4, 0)
  frame.btnClose:SetHeight(16)
  frame.btnClose:SetWidth(16)
  frame.btnClose:SetBackdrop(backdrop)
  frame.btnClose:SetBackdropColor(.2, .2, .2, 1)
  frame.btnClose:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnClose:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  frame.btnClose:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  frame.btnClose:SetScript("OnClick", function() frame:Hide() end)

  frame.btnClose.caption = frame.btnClose:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.btnClose.caption:SetFont(STANDARD_TEXT_FONT, 14)
  frame.btnClose.caption:SetText("x")
  frame.btnClose.caption:SetAllPoints()

  -- attach helper methods
  frame.CreateConfig = TWTUI.CreateConfig
  frame.CreateSelector = TWTUI.CreateSelector

  -- =========================================================================
  -- Settings entries
  -- =========================================================================

  -- General
  frame:CreateConfig(L["General"], nil, "header")
  frame:CreateConfig(L["Always Show in Combat"], "showInCombat", "boolean")
  frame:CreateConfig(L["Hide Out Of Combat"], "hideOOC", "boolean")
  frame:CreateConfig(L["Tank Mode"], "tankMode", "boolean")
  frame:CreateConfig(L["Show Labels"], "labelRow", "boolean")
  frame:CreateConfig(L["Lock/Unlock Window"], "lock", "boolean")

  -- Display
  frame:CreateConfig(L["Bars"], nil, "header")
  frame:CreateConfig(L["Bar Texture"], "texture", TWT.textures)
  frame:CreateConfig(L["Show TPS"], "colTPS", "boolean")
  frame:CreateConfig(L["Show Threat"], "colThreat", "boolean")
  frame:CreateConfig(L["Show % Max"], "colPerc", "boolean")

  -- Bar Spacing (number, 0-10)
  frame.entries = frame.entries + 1
  local spText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  spText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  spText:SetWidth(140)
  spText:SetHeight(18)
  spText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  spText:SetJustifyH("LEFT")
  spText:SetText(L["Bar Spacing"])
  local spSelector = CreateRangeSelector(frame, "spacing", 0, 10)
  spSelector:ClearAllPoints()
  spSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  -- Bar Height (number, 10-30)
  frame.entries = frame.entries + 1
  local bhText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  bhText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  bhText:SetWidth(140)
  bhText:SetHeight(18)
  bhText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  bhText:SetJustifyH("LEFT")
  bhText:SetText(L["Bar Height"])
  local bhSelector = CreateRangeSelector(frame, "barHeight", 10, 30)
  bhSelector:ClearAllPoints()
  bhSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  frame:CreateConfig(L["Pastel Colors"], "pastel", "boolean")

  -- Color Saturation (1-20, default 10 = 1.0x)
  frame.entries = frame.entries + 1
  local satText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  satText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  satText:SetWidth(140)
  satText:SetHeight(18)
  satText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  satText:SetJustifyH("LEFT")
  satText:SetText(L["Color Saturation"])
  local satSelector = CreateRangeSelector(frame, "saturation", 1, 20)
  satSelector:ClearAllPoints()
  satSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  frame:CreateConfig(L["Show Backdrops"], "backdrop", "boolean")

  -- Warnings
  frame:CreateConfig(L["Full Screen Glow"], nil, "header")
  frame:CreateConfig(L["Full Screen Glow"], "fullScreenGlow", "boolean")
  frame:CreateConfig(L["Sound Warning"], "aggroSound", "boolean")

  -- Aggro Threshold (number, 65-95)
  frame.entries = frame.entries + 1
  local atText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  atText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  atText:SetWidth(140)
  atText:SetHeight(18)
  atText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  atText:SetJustifyH("LEFT")
  atText:SetText(L["Aggro Threshold"])
  local atSelector = CreateRangeSelector(frame, "aggroThreshold", 65, 95)
  atSelector:ClearAllPoints()
  atSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  -- Integration
  frame:CreateConfig(L["Integration"], nil, "header")
  frame:CreateConfig(L["Target Frame Glow (default UI)"], "glow", "boolean")
  frame:CreateConfig(L["Target Frame Threat Percentage (default UI)"], "perc", "boolean")
  frame:CreateConfig(L["Target Frame Glow (pfUI)"], "glowPFUI", "boolean")
  frame:CreateConfig(L["Target Frame Threat Percentage (pfUI)"], "percPFUI", "boolean")

  -- Opacity
  frame.entries = frame.entries + 1
  local opText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  opText:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -frame.entries * 18 - 8)
  opText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  opText:SetTextColor(1, .8, 0)
  opText:SetWidth(140)
  opText:SetHeight(18)
  opText:SetJustifyH("LEFT")
  opText:SetText(L["Combat Opacity"])

  -- Combat Opacity (display 50-100, stored as 0.5-1.0)
  frame.entries = frame.entries + 1
  local caText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  caText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  caText:SetWidth(140)
  caText:SetHeight(18)
  caText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  caText:SetJustifyH("LEFT")
  caText:SetText(L["Combat Opacity"])
  local caSelector = CreateRangeSelector(frame, "combatAlpha", 50, 100, 0.01)
  caSelector:ClearAllPoints()
  caSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  -- OOC Opacity (display 50-100, stored as 0.5-1.0)
  frame.entries = frame.entries + 1
  local oaText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  oaText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  oaText:SetWidth(140)
  oaText:SetHeight(18)
  oaText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  oaText:SetJustifyH("LEFT")
  oaText:SetText(L["OOC Opacity"])
  local oaSelector = CreateRangeSelector(frame, "oocAlpha", 50, 100, 0.01)
  oaSelector:ClearAllPoints()
  oaSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  -- Window Scale (display 50-150, stored as 0.5-1.5)
  frame.entries = frame.entries + 1
  local wsText = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  wsText:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -frame.entries * 18 - 4)
  wsText:SetWidth(140)
  wsText:SetHeight(18)
  wsText:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  wsText:SetJustifyH("LEFT")
  wsText:SetText(L["Window Scale"])
  local wsSelector = CreateRangeSelector(frame, "windowScale", 50, 150, 0.01)
  wsSelector:ClearAllPoints()
  wsSelector:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -frame.entries * 18 - 4)

  -- Set final height based on total entries
  frame:SetHeight(frame.entries * 18 + 30)

  TWTUI.settings = frame
  return frame
end

-- ============================================================================
-- 4. TWTUI.CreateTankModeWindow()
-- ============================================================================

function TWTUI.CreateTankModeWindow()
  local frame = CreateFrame("Frame", "TWTTankMode", UIParent)
  frame:Hide()
  frame:SetWidth(220)
  frame:SetHeight(120)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)

  -- window background
  frame:SetBackdrop(backdrop_window)
  frame:SetBackdropColor(.5, .5, .5, .5)

  -- window border
  frame.border = CreateFrame("Frame", nil, frame)
  frame.border:ClearAllPoints()
  frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.border:SetFrameLevel(100)
  frame.border:SetBackdrop(backdrop_border)
  frame.border:SetBackdropBorderColor(.7, .7, .7, 1)

  -- title bar
  frame.title = frame:CreateTexture(nil, "NORMAL")
  frame.title:SetTexture(0, 0, 0, .6)
  frame.title:SetHeight(20)
  frame.title:SetPoint("TOPLEFT", 2, -2)
  frame.title:SetPoint("TOPRIGHT", -2, -2)

  frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  frame.caption:SetText("|cffabd473" .. L["Tank Mode Window"])
  frame.caption:SetPoint("LEFT", frame.title, "LEFT", 5, 0)
  frame.caption:SetJustifyH("LEFT")

  -- Close button (also disables tank mode)
  frame.btnClose = CreateFrame("Button", nil, frame)
  frame.btnClose:SetPoint("RIGHT", frame.title, "RIGHT", -4, 0)
  frame.btnClose:SetHeight(16)
  frame.btnClose:SetWidth(16)
  frame.btnClose:SetBackdrop(backdrop)
  frame.btnClose:SetBackdropColor(.2, .2, .2, 1)
  frame.btnClose:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnClose.tooltip = { L["Close Window and disable Tank Mode"] }
  frame.btnClose:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnClose:SetScript("OnLeave", TWTUI.btnLeave)
  frame.btnClose:SetScript("OnClick", function()
    frame:Hide()
    if TWT_CONFIG then
      TWT_CONFIG.tankMode = false
    end
    TWTUI.settingsCallback("tankMode", false)
  end)

  frame.btnClose.tex = frame.btnClose:CreateTexture()
  frame.btnClose.tex:SetWidth(10)
  frame.btnClose.tex:SetHeight(10)
  frame.btnClose.tex:SetPoint("CENTER", 0, 0)
  frame.btnClose.tex:SetTexture("Interface\\AddOns\\TWThreat\\images\\icon_x")

  -- Stick buttons (top, right, bottom, left)
  local stickButtons = {
    { name = "Top",    icon = "arrow_to_top",    tooltip = L["Stick Top"],    desc = L["Stick this window to the top of the main window."] },
    { name = "Right",  icon = "arrow_to_right",  tooltip = L["Stick Right"],  desc = L["Stick this window to the right of the main window."] },
    { name = "Bottom", icon = "arrow_to_bottom", tooltip = L["Stick Bottom"], desc = L["Stick this window to the bottom of the main window."] },
    { name = "Left",   icon = "arrow_to_left",   tooltip = L["Stick Left"],   desc = L["Stick this window to the left of the main window."] },
  }

  local prevBtn = frame.btnClose
  for i, info in ipairs(stickButtons) do
    local btn = CreateFrame("Button", nil, frame)
    btn:SetPoint("RIGHT", prevBtn, "LEFT", -1, 0)
    btn:SetHeight(16)
    btn:SetWidth(16)
    btn:SetBackdrop(backdrop)
    btn:SetBackdropColor(.2, .2, .2, 1)
    btn:SetBackdropBorderColor(.4, .4, .4, 1)
    btn.tooltip = { info.tooltip, "|cffffffff" .. info.desc }
    btn:SetScript("OnEnter", TWTUI.btnEnter)
    btn:SetScript("OnLeave", TWTUI.btnLeave)

    btn.tex = btn:CreateTexture()
    btn.tex:SetWidth(10)
    btn.tex:SetHeight(10)
    btn.tex:SetPoint("CENTER", 0, 0)
    btn.tex:SetTexture("Interface\\AddOns\\TWThreat\\images\\" .. info.icon)

    local stickName = info.name
    btn:SetScript("OnClick", function()
      if TWT_CONFIG then
        TWT_CONFIG.tankModeStick = stickName
      end
      TWTUI.settingsCallback("tankModeStick", stickName)
    end)

    frame["btnStick" .. info.name] = btn
    prevBtn = btn
  end

  -- Drag handlers
  frame:SetScript("OnDragStart", function()
    if TWT_CONFIG and not TWT_CONFIG.lock then
      frame:StartMoving()
      if TWT_CONFIG then
        TWT_CONFIG.tankModeStick = "Free"
      end
    end
  end)

  frame:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
  end)

  -- Create 5 entry rows
  TWTUI.tankModeEntries = {}

  for i = 1, 5 do
    local row = CreateFrame("Button", "TWTTankModeEntry" .. i, frame)
    row:SetHeight(18)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -20 - (i - 1) * 18)
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -20 - (i - 1) * 18)

    -- Row background
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    row.bg:SetTexture(0, 0, 0, 0.3)

    -- Creature name (left)
    row.creatureName = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    row.creatureName:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
    row.creatureName:SetJustifyH("LEFT")
    row.creatureName:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.creatureName:SetWidth(90)

    -- Player name (center)
    row.playerName = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    row.playerName:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
    row.playerName:SetJustifyH("CENTER")
    row.playerName:SetPoint("CENTER", row, "CENTER", 0, 0)
    row.playerName:SetWidth(70)

    -- Threat % (right)
    row.threatPct = row:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    row.threatPct:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
    row.threatPct:SetJustifyH("RIGHT")
    row.threatPct:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.threatPct:SetWidth(40)

    -- Click to target
    row:SetScript("OnClick", function()
      if this.targetUnit then
        TargetByName(this.targetUnit, true)
      end
    end)

    row:SetScript("OnEnter", function()
      this.bg:SetTexture(1, 1, 1, 0.1)
    end)

    row:SetScript("OnLeave", function()
      this.bg:SetTexture(0, 0, 0, 0.3)
    end)

    row:Hide()
    TWTUI.tankModeEntries[i] = row
  end

  -- Adjust frame height
  frame:SetHeight(20 + 5 * 18 + 4)

  TWTUI.tankModeWindow = frame
  return frame
end

-- ============================================================================
-- 5. TWTUI.CreateFullScreenGlow()
-- ============================================================================

function TWTUI.CreateFullScreenGlow()
  local frame = CreateFrame("Frame", "TWTFullScreenGlow", UIParent)
  frame:Hide()
  frame:SetFrameStrata("BACKGROUND")
  frame:SetAllPoints(UIParent)
  frame:EnableMouse(false)

  frame.texture = frame:CreateTexture("TWTFullScreenGlowTexture", "BACKGROUND")
  frame.texture:SetTexture("Interface\\AddOns\\TWThreat\\images\\fs_glow")
  frame.texture:SetAllPoints(frame)
  frame.texture:SetVertexColor(1, 0, 0, 0.6)
  frame.texture:SetBlendMode("ADD")

  TWTUI.fullScreenGlow = frame
  return frame
end

-- ============================================================================
-- 6. TWTUI.CreateWarning()
-- ============================================================================

function TWTUI.CreateWarning()
  local frame = CreateFrame("Frame", "TWTWarning", UIParent)
  frame:Hide()
  frame:SetFrameStrata("HIGH")
  frame:SetWidth(400)
  frame:SetHeight(60)
  frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  frame:EnableMouse(false)

  frame.text = frame:CreateFontString(nil, "OVERLAY")
  frame.text:SetFont(STANDARD_TEXT_FONT, 32, "OUTLINE")
  frame.text:SetTextColor(1, 0.1, 0.1, 1)
  frame.text:SetText("STOP DPS!")
  frame.text:SetPoint("CENTER", frame, "CENTER", 0, 0)

  TWTUI.warning = frame
  return frame
end

-- ============================================================================
-- 7. TWTUI.CreateTargetOverlays()
-- ============================================================================

function TWTUI.CreateTargetOverlays()
  -- Default UI target frame overlay
  local overlay = CreateFrame("Frame", "TWTTargetOverlay", TargetFrame or UIParent)
  overlay:Hide()
  overlay:SetAllPoints(overlay:GetParent())
  overlay:SetFrameLevel((overlay:GetParent():GetFrameLevel() or 0) + 5)

  -- Glow texture for default UI
  overlay.glow = overlay:CreateTexture(nil, "OVERLAY")
  overlay.glow:SetTexture("Interface\\AddOns\\TWThreat\\images\\numericthreatborder")
  overlay.glow:SetAllPoints(overlay)
  overlay.glow:SetBlendMode("ADD")
  overlay.glow:SetVertexColor(0, 1, 0, 0.5)
  overlay.glow:Hide()

  -- Percentage text for default UI
  overlay.percent = overlay:CreateFontString(nil, "OVERLAY")
  overlay.percent:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
  overlay.percent:SetTextColor(1, 1, 1, 1)
  overlay.percent:SetPoint("BOTTOM", overlay, "TOP", 0, 2)
  overlay.percent:SetText("")
  overlay.percent:Hide()

  TWTUI.targetOverlay = overlay

  -- pfUI target frame overlay (created but parenting deferred until pfUI is detected)
  local pfOverlay = CreateFrame("Frame", "TWTTargetOverlayPFUI", UIParent)
  pfOverlay:Hide()
  pfOverlay:SetWidth(1)
  pfOverlay:SetHeight(1)
  pfOverlay:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  -- Glow texture for pfUI
  pfOverlay.glow = pfOverlay:CreateTexture(nil, "OVERLAY")
  pfOverlay.glow:SetTexture("Interface\\AddOns\\TWThreat\\images\\pfui_glow")
  pfOverlay.glow:SetAllPoints(pfOverlay)
  pfOverlay.glow:SetBlendMode("ADD")
  pfOverlay.glow:SetVertexColor(0, 1, 0, 0.5)
  pfOverlay.glow:Hide()

  -- Percentage text for pfUI
  pfOverlay.percent = pfOverlay:CreateFontString(nil, "OVERLAY")
  pfOverlay.percent:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
  pfOverlay.percent:SetTextColor(1, 1, 1, 1)
  pfOverlay.percent:SetPoint("BOTTOM", pfOverlay, "TOP", 0, 2)
  pfOverlay.percent:SetText("")
  pfOverlay.percent:Hide()

  TWTUI.targetOverlayPFUI = pfOverlay

  return overlay, pfOverlay
end

-- ============================================================================
-- 8. TWTUI.CreateAddonStatusWindow()
-- ============================================================================

function TWTUI.CreateAddonStatusWindow()
  local frame = CreateFrame("Frame", "TWTAddonStatus", UIParent)
  frame:Hide()
  frame:SetWidth(280)
  frame:SetHeight(300)
  frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", function() this:StartMoving() end)
  frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
  frame:SetFrameStrata("DIALOG")
  frame:SetClampedToScreen(true)

  -- window background
  frame:SetBackdrop(backdrop_window)
  frame:SetBackdropColor(.5, .5, .5, .9)

  -- window border
  frame.border = CreateFrame("Frame", nil, frame)
  frame.border:ClearAllPoints()
  frame.border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
  frame.border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
  frame.border:SetFrameLevel(100)
  frame.border:SetBackdrop(backdrop_border)
  frame.border:SetBackdropBorderColor(.7, .7, .7, 1)

  -- title bar
  frame.title = frame:CreateTexture(nil, "NORMAL")
  frame.title:SetTexture(0, 0, 0, .6)
  frame.title:SetHeight(20)
  frame.title:SetPoint("TOPLEFT", 2, -2)
  frame.title:SetPoint("TOPRIGHT", -2, -2)

  frame.caption = frame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.caption:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
  frame.caption:SetText("|cffabd473" .. L["Addon Raid Status"])
  frame.caption:SetPoint("LEFT", frame.title, "LEFT", 5, 0)
  frame.caption:SetJustifyH("LEFT")

  -- Close button
  frame.btnClose = CreateFrame("Button", nil, frame)
  frame.btnClose:SetPoint("RIGHT", frame.title, "RIGHT", -4, 0)
  frame.btnClose:SetHeight(16)
  frame.btnClose:SetWidth(16)
  frame.btnClose:SetBackdrop(backdrop)
  frame.btnClose:SetBackdropColor(.2, .2, .2, 1)
  frame.btnClose:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnClose:SetScript("OnEnter", function() this:SetBackdropBorderColor(1.0, 0.8, 0.0, 1) end)
  frame.btnClose:SetScript("OnLeave", function() this:SetBackdropBorderColor(0.4, 0.4, 0.4, 1) end)
  frame.btnClose:SetScript("OnClick", function() frame:Hide() end)

  frame.btnClose.caption = frame.btnClose:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.btnClose.caption:SetFont(STANDARD_TEXT_FONT, 14)
  frame.btnClose.caption:SetText("x")
  frame.btnClose.caption:SetAllPoints()

  -- Refresh button
  frame.btnRefresh = CreateFrame("Button", nil, frame)
  frame.btnRefresh:SetPoint("RIGHT", frame.btnClose, "LEFT", -1, 0)
  frame.btnRefresh:SetHeight(16)
  frame.btnRefresh:SetWidth(16)
  frame.btnRefresh:SetBackdrop(backdrop)
  frame.btnRefresh:SetBackdropColor(.2, .2, .2, 1)
  frame.btnRefresh:SetBackdropBorderColor(.4, .4, .4, 1)
  frame.btnRefresh.tooltip = { L["Refresh"] }
  frame.btnRefresh:SetScript("OnEnter", TWTUI.btnEnter)
  frame.btnRefresh:SetScript("OnLeave", TWTUI.btnLeave)
  frame.btnRefresh:SetScript("OnClick", function()
    -- TWThreat.lua will override this
    TWTUI.settingsCallback("refreshAddonStatus", true)
  end)

  frame.btnRefresh.caption = frame.btnRefresh:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.btnRefresh.caption:SetFont(STANDARD_TEXT_FONT, 9)
  frame.btnRefresh.caption:SetText("R")
  frame.btnRefresh.caption:SetAllPoints()

  -- Text area (scrollable)
  frame.scrollFrame = CreateFrame("ScrollFrame", "TWTAddonStatusScroll", frame, "UIPanelScrollFrameTemplate")
  frame.scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -24)
  frame.scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -26, 6)

  frame.textArea = CreateFrame("Frame", nil, frame.scrollFrame)
  frame.textArea:SetWidth(248)
  frame.textArea:SetHeight(1) -- will grow as text is added

  frame.scrollFrame:SetScrollChild(frame.textArea)

  frame.text = frame.textArea:CreateFontString(nil, "OVERLAY", "GameFontWhite")
  frame.text:SetFont(STANDARD_TEXT_FONT, 10, "THINOUTLINE")
  frame.text:SetJustifyH("LEFT")
  frame.text:SetJustifyV("TOP")
  frame.text:SetPoint("TOPLEFT", frame.textArea, "TOPLEFT", 0, 0)
  frame.text:SetWidth(248)
  frame.text:SetText("")

  TWTUI.addonStatus = frame
  return frame
end
