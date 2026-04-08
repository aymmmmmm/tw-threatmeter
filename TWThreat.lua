local _G, _ = _G or getfenv()

-- todo tankmode messages to send if guid is target, for tankmode highlight
-- todo save TWT_SPEC per sender so it caches from other people's inspects

local __lower = string.lower
local __repeat = string.rep
local __strlen = string.len
local __find = string.find
local __substr = string.sub
local __parseint = tonumber
local __parsestring = tostring
local __getn = table.getn
local __tinsert = table.insert
local __tsort = table.sort
local __pairs = pairs
local __floor = math.floor
local __abs = abs
local __char = string.char

local TPS_BUFFER_SIZE = 10

local L = TWT_L
local TWT = CreateFrame("Frame")
_G.TWT = TWT

local has_superwow = SUPERWOW_VERSION or SetAutoloot

TWT.addonVer = GetAddOnMetadata('TWThreat', 'Version')

TWT.threatApi = 'TWTv4=';
TWT.tankModeApi = 'TMTv1=';
TWT.UDTS = 'TWT_UDTSv4';

TWT.showedUpdateNotification = false
TWT.addonName = '|cffabd473TWThreat'

TWT.prefix = 'TWT'
TWT.channel = 'RAID'

TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = __lower(cl)

TWT.lastAggroWarningSoundTime = 0
TWT.lastAggroWarningGlowTime = 0

TWT.AGRO = '-Pull Aggro at-'
TWT.threatsFrames = {}

TWT.threats = {}

TWT.targetName = ''
TWT.relayTo = {}
TWT.shouldRelay = false
TWT.inCombat = false
TWT.healerMasterTarget = ''

TWT.updateSpeed = 0.2

TWT.targetFrameVisible = false
TWT.PFUItargetFrameVisible = false

TWT.nameLimit = 30
TWT.windowStartWidth = 300
TWT.windowWidth = 300

-- Available bar textures (matching ShaguDPS)
TWT.textures = {
    "Interface\\BUTTONS\\WHITE8X8",
    "Interface\\TargetingFrame\\UI-StatusBar",
    "Interface\\Tooltips\\UI-Tooltip-Background",
    "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar"
}

-- Static popup for confirmations
StaticPopupDialogs["TWT_QUESTION"] = {
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

TWT.roles = {}
TWT.spec = {}
TWT.units = {}

TWT.tankModeThreats = {}

TWT.withAddon = 0
TWT.addonStatus = {}

TWT.classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
    ["pet"] = { r = 0.3, g = 0.7, b = 0.3, c = "|cff4db84d" },
    ["agro"] = { r = 0.96, g = 0.1, b = 0.1, c = "|cffff1111" }
}

TWT.classCoords = {
    ["priest"] = { 0.52, 0.73, 0.27, 0.48 },
    ["mage"] = { 0.23, 0.48, 0.02, 0.23 },
    ["warlock"] = { 0.77, 0.98, 0.27, 0.48 },
    ["rogue"] = { 0.48, 0.73, 0.02, 0.23 },
    ["druid"] = { 0.77, 0.98, 0.02, 0.23 },
    ["hunter"] = { 0.02, 0.23, 0.27, 0.48 },
    ["shaman"] = { 0.27, 0.48, 0.27, 0.48 },
    ["warrior"] = { 0.02, 0.23, 0.02, 0.23 },
    ["paladin"] = { 0.02, 0.23, 0.52, 0.73 },
    ["pet"] = { 0.02, 0.23, 0.27, 0.48 },
}


local function twtprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. GetTime() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(TWT.classColors[TWT.class].c .. "[TWT] |cffffffff" .. a)
end

local function twtdebug(a)
    local time = GetTime() + 0.0001
    if not TWT_CONFIG.debug then
        return false
    end
    if a == nil then
        twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff attempt to print a nil value.')
        return
    end
    if type(a) == 'boolean' then
        if a then
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[true]')
        else
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[false]')
        end
        return true
    end
    twtprint('|cff0070de[D:' .. time .. ']|cffffffff[' .. a .. ']')
end

SLASH_TWT1 = "/twt"
SlashCmdList["TWT"] = function(msg)
    if not msg or msg == "" then
        local p = function(s) DEFAULT_CHAT_FRAME:AddMessage(s) end
        p("|cffabd473TW|cffffffff Threat:")
        p("  /twt show    |cffcccccc- " .. L["Show main window"])
        p("  /twt toggle  |cffcccccc- " .. L["Toggle window"])
        p("  /twt lock    |cffcccccc- " .. L["Toggle lock"])
        p("  /twt reset   |cffcccccc- " .. L["Reset threat data"])
        p("  /twt texture [1-4] |cffcccccc- " .. L["Set bar texture"])
        p("  /twt spacing [0-10] |cffcccccc- " .. L["Set bar spacing"])
        p("  /twt pastel  |cffcccccc- " .. L["Toggle pastel colors"])
        p("  /twt saturation [1-20] |cffcccccc- " .. L["Set color saturation"])
        p("  /twt backdrop |cffcccccc- " .. L["Toggle backdrop"])
        p("  /twt scale [50-150] |cffcccccc- " .. L["Set window scale"])
        p("  /twt tankmode |cffcccccc- " .. L["Toggle tank mode"])
        return
    end

    local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
    if not cmd then return end
    cmd = strlower(cmd)

    local p = function(s) DEFAULT_CHAT_FRAME:AddMessage("|cffabd473TW|cffffffff Threat: " .. s) end

    if cmd == "show" then
        TWTUI.mainWindow:Show()
        TWT_CONFIG.visible = true
        return
    elseif cmd == "toggle" then
        TWT_CONFIG.visible = not TWT_CONFIG.visible
        if TWT_CONFIG.visible then TWTUI.mainWindow:Show() else TWTUI.mainWindow:Hide() end
        p(L["Visible"] .. ": " .. (TWT_CONFIG.visible and "on" or "off"))
        return
    elseif cmd == "lock" then
        TWT_CONFIG.lock = not TWT_CONFIG.lock
        TWTUI.settingsCallback("lock", TWT_CONFIG.lock)
        if TWT_CONFIG.lock then
            TWTUI.mainWindow.btnLock.caption:SetText("L")
        else
            TWTUI.mainWindow.btnLock.caption:SetText("U")
        end
        p(L["Lock"] .. ": " .. (TWT_CONFIG.lock and "on" or "off"))
        return
    elseif cmd == "reset" then
        TWT.resetData()
        p(L["Data reset."])
        return
    elseif cmd == "texture" then
        local n = tonumber(args)
        if n and TWT.textures[n] then
            TWT_CONFIG.texture = n
            TWTUI.settingsCallback("texture", n)
            p(L["Texture"] .. ": " .. n)
        else
            p("|cffff5511" .. L["Valid options:"] .. " 1-" .. table.getn(TWT.textures))
        end
        return
    elseif cmd == "spacing" then
        local n = tonumber(args)
        if n and n >= 0 and n <= 10 then
            TWT_CONFIG.spacing = n
            TWTUI.settingsCallback("spacing", n)
            p(L["Bar Spacing"] .. ": " .. n)
        else
            p("|cffff5511" .. L["Valid options:"] .. " 0-10")
        end
        return
    elseif cmd == "pastel" then
        TWT_CONFIG.pastel = not TWT_CONFIG.pastel
        TWTUI.settingsCallback("pastel", TWT_CONFIG.pastel)
        p(L["Pastel Colors"] .. ": " .. (TWT_CONFIG.pastel and "on" or "off"))
        return
    elseif cmd == "saturation" then
        local n = tonumber(args)
        if n and n >= 1 and n <= 20 then
            TWT_CONFIG.saturation = n
            TWTUI.settingsCallback("saturation", TWT_CONFIG.saturation)
            p(L["Color Saturation"] .. ": " .. n)
        else
            p("|cffff5511" .. L["Valid options:"] .. " 1-20")
        end
        return
    elseif cmd == "backdrop" then
        TWT_CONFIG.backdrop = not TWT_CONFIG.backdrop
        TWTUI.settingsCallback("backdrop", TWT_CONFIG.backdrop)
        p(L["Show Backdrops"] .. ": " .. (TWT_CONFIG.backdrop and "on" or "off"))
        return
    elseif cmd == "scale" then
        local n = tonumber(args)
        if n and n >= 50 and n <= 150 then
            TWT_CONFIG.windowScale = n * 0.01
            TWT.applyWindowScale()
            p(L["Window Scale"] .. ": " .. n)
        else
            p("|cffff5511" .. L["Valid options:"] .. " 50-150")
        end
        return
    elseif cmd == "tankmode" then
        if TWT_CONFIG.tankMode then
            twtprint(L["Tank Mode is already enabled."])
        else
            TWT_CONFIG.tankMode = true
            twtprint(L["Tank Mode enabled."])
        end
        return
    elseif cmd == "debug" then
        TWT_CONFIG.debug = not TWT_CONFIG.debug
        twtprint(TWT_CONFIG.debug and L["Debugging enabled"] or L["Debugging disabled"])
        return
    elseif cmd == "who" then
        TWT.queryWho()
        return
    elseif cmd == "specinfo" then
        local _, cl = UnitClass('player')
        p('职业: ' .. cl)
        for i = 2, 4 do
            local name, texture = GetSpellTabInfo(i)
            if name and texture then
                local texParts = __explode(texture, '\\')
                local texName = texParts[__getn(texParts)]
                local talents = 0
                for j = 1, GetNumTalents(i - 1) do
                    local _, _, _, _, currRank = GetTalentInfo(i - 1, j)
                    talents = talents + currRank
                end
                p('  天赋' .. (i-1) .. ': ' .. name .. ' | 图标: ' .. texName .. ' | 点数: ' .. talents)
            end
        end
        return
    end

    p(L["Unknown command. Type /twt for help."])
end

SLASH_TWTSHOW1 = "/twtshow"
SlashCmdList["TWTSHOW"] = function()
    TWTUI.mainWindow:Show()
    TWT_CONFIG.visible = true
end

TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_LOGIN")
TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")
TWT:RegisterEvent("PLAYER_ENTERING_WORLD")
TWT:RegisterEvent("PARTY_MEMBERS_CHANGED")
if has_superwow then
    TWT:RegisterEvent("UNIT_MODEL_CHANGED")
end

TWT.threatQuery = CreateFrame("Frame")
TWT.threatQuery:Show()

local timeStart = GetTime()
local totalPackets = 0
local totalData = 0
local uiUpdates = 0

local eventHandlers = {}

eventHandlers.UNIT_MODEL_CHANGED = function()
    if __substr(arg1,3,3) ~= "F" then return end
    local low_id = tonumber(__substr(arg1,-4),16)
    if not low_id then return end
    for low,whole in pairs(TWT.units) do
        if not UnitExists(whole) then
            TWT.units[low] = nil
        end
    end
    TWT.units[low_id] = arg1
end

eventHandlers.ADDON_LOADED = function()
    if string.lower(arg1) == 'twthreat' then
        return TWT.init()
    end
end

eventHandlers.PLAYER_LOGIN = function()
    TWTUI.mainWindow:ClearAllPoints()
    TWTUI.mainWindow:SetPoint(unpack(TWT_CONFIG.windowPoint))
end

eventHandlers.PARTY_MEMBERS_CHANGED = function()
    return TWT.getClasses()
end

eventHandlers.PLAYER_ENTERING_WORLD = function()
    TWT.sendMyVersion()
    TWT.combatEnd()
    if UnitAffectingCombat('player') then
        TWT.combatStart(true)
    end
end

eventHandlers.CHAT_MSG_ADDON = function()
    if __find(arg2, TWT.threatApi, 1, true) then
        totalPackets = totalPackets + 1
        totalData = totalData + __strlen(arg2)

        local threatData = arg2
        if __find(threatData, '#') and __find(threatData, TWT.tankModeApi) then
            local packetEx = __explode(threatData, '#')
            if packetEx[1] and packetEx[2] then
                threatData = packetEx[1]
                TWT.handleTankModePacket(packetEx[2])
            end
        end

        return TWT.handleThreatPacket(threatData)
    end

    if arg1 == TWT.prefix then
        if __substr(arg2, 1, 11) == 'TWTVersion:' and arg4 ~= TWT.name then
            if not TWT.showedUpdateNotification then
                local verEx = __explode(arg2, ':')
                if TWT.version(verEx[2]) > TWT.version(TWT.addonVer) then
                    twtprint('New version available ' ..
                            TWT.classColors[TWT.class].c .. 'v' .. verEx[2] .. ' |cffffffff(current version ' ..
                            TWT.classColors['paladin'].c .. 'v' .. TWT.addonVer .. '|cffffffff)')
                    twtprint('Update at ' .. TWT.classColors[TWT.class].c .. 'https://github.com/MarcelineVQ/TWThreat')
                    TWT.showedUpdateNotification = true
                end
            end
            return true
        end

        if __substr(arg2, 1, 7) == 'TWT_WHO' then
            TWT.send('TWT_ME:' .. TWT.addonVer)
            return true
        end

        if __substr(arg2, 1, 15) == 'TWTRoleTexture:' then
            local tex = __explode(arg2, ':')[2] or ''
            TWT.roles[arg4] = tex
            return true
        end

        if __substr(arg2, 1, 7) == 'TWT_ME:' then
            if TWT.addonStatus[arg4] then
                local msg = __explode(arg2, ':')[2]
                local verColor = ""
                if TWT.version(msg) == TWT.version(TWT.addonVer) then
                    verColor = TWT.classColors['hunter'].c
                end
                if TWT.version(msg) < TWT.version(TWT.addonVer) then
                    verColor = '|cffff1111'
                end
                if TWT.version(msg) + 1 == TWT.version(TWT.addonVer) then
                    verColor = '|cffff8810'
                end

                TWT.addonStatus[arg4]['v'] = '    ' .. verColor .. msg
                TWT.withAddon = TWT.withAddon + 1
                TWT.updateWithAddon()
                return true
            end
            return false
        end

        return false
    end
end

eventHandlers.PLAYER_REGEN_DISABLED = function()
    return TWT.combatStart(true)
end

eventHandlers.PLAYER_REGEN_ENABLED = function()
    return TWT.combatEnd()
end

eventHandlers.PLAYER_TARGET_CHANGED = function()
    if not TWT.targetChanged() then
        TWT.queue_hide = GetTime() * 1000
    end
end

TWT:SetScript("OnEvent", function()
    local handler = eventHandlers[event]
    if handler then handler() end
end)

function TWT.queryWho()
    TWT.withAddon = 0
    TWT.addonStatus = {}
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            TWT.addonStatus[n] = {
                ['class'] = __lower(class),
                ['v'] = '|cff888888   -   '
            }
            if z == 'Offline' then
                TWT.addonStatus[n]['v'] = '|cffff0000' .. L["offline"]
            end
        end
    end
    twtprint(L["Sending who query..."])
    if TWTUI.addonStatus then
        TWTUI.addonStatus:Show()
    end
    TWT.send('TWT_WHO')
end

function TWT.updateWithAddon()
    local rosterList = ''
    local i = 0
    for n, data in next, TWT.addonStatus do
        i = i + 1
        rosterList = rosterList .. TWT.classColors[data['class']].c .. n .. __repeat(' ', 12 - __strlen(n)) .. ' ' .. data['v'] .. ' |cff888888'
        if i < 4 then
            rosterList = rosterList .. '| '
        end
        if i == 4 then
            rosterList = rosterList .. '\n'
            i = 0
        end
    end
    if TWTUI.addonStatus then
        TWTUI.addonStatus.text:SetText(rosterList)
        TWTUI.addonStatus.caption:SetText('|cffabd473' .. L["Addon Raid Status"] .. ' ' .. TWT.withAddon .. '/' .. GetNumRaidMembers())
    end
end

TWT.glowFader = CreateFrame('Frame')
TWT.glowFader:Hide()

TWT.glowFader:SetScript("OnShow", function()
    this.startTime = GetTime() - 1
    this.dir = 10
    if TWTUI.fullScreenGlow then
        TWTUI.fullScreenGlow:SetAlpha(0.01)
        TWTUI.fullScreenGlow:Show()
    end
end)
TWT.glowFader:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
TWT.glowFader:SetScript("OnUpdate", function()
    local plus = 0.04
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()

        if TWTUI.fullScreenGlow:GetAlpha() >= 0.6 then
            this.dir = -1
        end

        TWTUI.fullScreenGlow:SetAlpha(TWTUI.fullScreenGlow:GetAlpha() + 0.03 * this.dir)

        if TWTUI.fullScreenGlow:GetAlpha() <= 0 then
            TWT.glowFader:Hide()
        end
    end
end)

function TWT.init()

    if not TWT_CONFIG then
        TWT_CONFIG = {
            visible = true,
            colTPS = true,
            colThreat = true,
            colPerc = true,
            labelRow = true,
            units = {}
        }
    end

    TWT_CONFIG.windowPoint = TWT_CONFIG.windowPoint or {"CENTER", "UIParent", "BOTTOMLEFT", unpack({UIParent:GetCenter()})}
    TWT_CONFIG.windowScale = TWT_CONFIG.windowScale or 1
    TWT_CONFIG.font = TWT_CONFIG.font or 'Roboto'
    TWT_CONFIG.barHeight = TWT_CONFIG.barHeight or 20
    TWT_CONFIG.visibleBars = TWT_CONFIG.visibleBars or 8
    TWT_CONFIG.aggroThreshold = TWT_CONFIG.aggroThreshold or 85
    TWT_CONFIG.tankModeStick = TWT_CONFIG.tankModeStick or 'Free'
    TWT_CONFIG.texture = TWT_CONFIG.texture or 2
    TWT_CONFIG.spacing = TWT_CONFIG.spacing or 0
    TWT_CONFIG.combatAlpha = TWT_CONFIG.combatAlpha or 1
    TWT_CONFIG.oocAlpha = TWT_CONFIG.oocAlpha or 1
    TWT_CONFIG.units = TWT_CONFIG.units or {}

    -- Boolean defaults: use nil check to preserve saved false values
    if TWT_CONFIG.visible == nil then TWT_CONFIG.visible = true end
    if TWT_CONFIG.colTPS == nil then TWT_CONFIG.colTPS = true end
    if TWT_CONFIG.colThreat == nil then TWT_CONFIG.colThreat = true end
    if TWT_CONFIG.colPerc == nil then TWT_CONFIG.colPerc = true end
    if TWT_CONFIG.labelRow == nil then TWT_CONFIG.labelRow = true end
    if TWT_CONFIG.backdrop == nil then TWT_CONFIG.backdrop = true end
    if TWT_CONFIG.glow == nil then TWT_CONFIG.glow = false end
    if TWT_CONFIG.perc == nil then TWT_CONFIG.perc = false end
    if TWT_CONFIG.glowPFUI == nil then TWT_CONFIG.glowPFUI = false end
    if TWT_CONFIG.percPFUI == nil then TWT_CONFIG.percPFUI = false end
    if TWT_CONFIG.percPFUItop == nil then TWT_CONFIG.percPFUItop = false end
    if TWT_CONFIG.percPFUIbottom == nil then TWT_CONFIG.percPFUIbottom = false end
    if TWT_CONFIG.showInCombat == nil then TWT_CONFIG.showInCombat = false end
    if TWT_CONFIG.hideOOC == nil then TWT_CONFIG.hideOOC = false end
    if TWT_CONFIG.fullScreenGlow == nil then TWT_CONFIG.fullScreenGlow = false end
    if TWT_CONFIG.aggroSound == nil then TWT_CONFIG.aggroSound = false end
    if TWT_CONFIG.tankMode == nil then TWT_CONFIG.tankMode = false end
    if TWT_CONFIG.lock == nil then TWT_CONFIG.lock = false end
    if TWT_CONFIG.pastel == nil then TWT_CONFIG.pastel = false end
    if TWT_CONFIG.saturation == nil then TWT_CONFIG.saturation = 10 end
    if TWT_CONFIG.debug == nil then TWT_CONFIG.debug = false end

    TWT.units = TWT_CONFIG.units

    -- Create all UI elements
    TWTUI.CreateMainWindow()
    TWTUI.CreateSettings()
    TWTUI.CreateTankModeWindow()
    TWTUI.CreateFullScreenGlow()
    TWTUI.CreateWarning()
    TWTUI.CreateTargetOverlays()
    TWTUI.CreateAddonStatusWindow()

    -- Set up the settings callback for side effects
    TWTUI.settingsCallback = function(key, value)
        if key == 'tankMode' then
            if value then
                TWT.testBars(true)
                TWT_CONFIG.fullScreenGlow = false
                TWT_CONFIG.aggroSound = false
                TWTUI.tankModeWindow:Show()
            else
                TWTUI.tankModeWindow:Hide()
            end
        elseif key == 'aggroSound' and value and not UnitAffectingCombat('player') then
            PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
        elseif key == 'fullScreenGlow' and value and not UnitAffectingCombat('player') then
            TWT.glowFader:Show()
        elseif key == 'tankModeStick' then
            TWT.applyTankModeStick(value)
        elseif key == 'windowScale' then
            TWT.applyWindowScale()
        elseif key == 'backdrop' then
            TWT.applyBackdrop()
        elseif key == 'barHeight' then
            local headerH = TWT_CONFIG.labelRow and 40 or 20
            local bars = TWT_CONFIG.visibleBars or 8
            TWTUI.mainWindow:SetHeight(TWT_CONFIG.barHeight * bars + headerH + (bars == 0 and 2 or 3))
            TWT.setMinMaxResize()
            TWT.updateUI('barHeight changed')
        elseif key == 'texture' or key == 'spacing' or key == 'pastel' or key == 'saturation' then
            TWT.updateUI('appearance changed')
        elseif key == 'combatAlpha' or key == 'oocAlpha' then
            TWTUI.mainWindow:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)
        elseif key == 'labelRow' or key == 'colTPS' or key == 'colThreat' or key == 'colPerc' then
            TWT.setColumnLabels()
            local colHeaderH = TWT_CONFIG.labelRow and 40 or 20
            local colBars = TWT_CONFIG.visibleBars or 8
            TWTUI.mainWindow:SetHeight(TWT_CONFIG.barHeight * colBars + colHeaderH + (colBars == 0 and 2 or 3))
            TWT.setMinMaxResize()
            TWT.updateUI('column setting changed')
        elseif key == 'percPFUItop' and value then
            TWT_CONFIG.percPFUIbottom = false
        elseif key == 'percPFUIbottom' and value then
            TWT_CONFIG.percPFUItop = false
        elseif key == 'refreshAddonStatus' then
            TWT.queryWho()
        end
    end

    if TWT_CONFIG.visible then
        TWTUI.mainWindow:Show()
    else
        TWTUI.mainWindow:Hide()
    end

    -- Set lock icon
    if TWT_CONFIG.lock then
        TWTUI.mainWindow.btnLock.caption:SetText("L")
    else
        TWTUI.mainWindow.btnLock.caption:SetText("U")
    end

    -- Apply backdrop setting
    TWT.applyBackdrop()

    -- Set fullscreen glow size
    if TWTUI.fullScreenGlow and TWTUI.fullScreenGlow.texture then
        TWTUI.fullScreenGlow.texture:SetWidth(GetScreenWidth())
        TWTUI.fullScreenGlow.texture:SetHeight(GetScreenHeight())
    end

    -- Set main window height
    local initHeaderH = TWT_CONFIG.labelRow and 40 or 20
    local initBars = TWT_CONFIG.visibleBars or 8
    TWTUI.mainWindow:SetHeight(TWT_CONFIG.barHeight * initBars + initHeaderH + (initBars == 0 and 2 or 3))

    -- Restore saved window width
    if TWT_CONFIG.windowWidth then
        TWTUI.mainWindow:SetWidth(TWT_CONFIG.windowWidth)
    end

    -- Set target overlay scale
    if TWTUI.targetOverlay then
        TWTUI.targetOverlay:SetScale(UIParent:GetScale())
    end

    TWT.setColumnLabels()

    TWT.updateTitleBarText()

    TWT.checkTargetFrames()

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff ' .. L["loaded."])
    return true
end

function TWT.applyWindowScale()
    local x, y = TWTUI.mainWindow:GetLeft(), TWTUI.mainWindow:GetTop()
    local sx, sy, sposX, sposY
    if TWTUI.tankModeWindow then
        sx = TWTUI.tankModeWindow:GetLeft()
        sy = TWTUI.tankModeWindow:GetTop()
    end
    local s = TWTUI.mainWindow:GetEffectiveScale()
    local ss = TWTUI.tankModeWindow and TWTUI.tankModeWindow:GetEffectiveScale() or s
    local posX, posY

    if x and y and s then
        x, y = x * s, y * s
        posX = x
        posY = y
    end
    if sx and sy and ss then
        sx, sy = sx * ss, sy * ss
        sposX = sx
        sposY = sy
    end

    TWTUI.mainWindow:SetScale(TWT_CONFIG.windowScale)
    if TWTUI.tankModeWindow then
        TWTUI.tankModeWindow:SetScale(TWT_CONFIG.windowScale)
    end

    s = TWTUI.mainWindow:GetEffectiveScale()
    ss = TWTUI.tankModeWindow and TWTUI.tankModeWindow:GetEffectiveScale() or s
    if posX and posY then
        posX, posY = posX / s, posY / s
        TWTUI.mainWindow:ClearAllPoints()
        TWTUI.mainWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    end
    if sposX and sposY and TWTUI.tankModeWindow then
        sposX, sposY = sposX / ss, sposY / ss
        TWTUI.tankModeWindow:ClearAllPoints()
        TWTUI.tankModeWindow:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", sposX, sposY)
    end

    if TWT_CONFIG.tankModeStick ~= 'Free' then
        TWT.applyTankModeStick(TWT_CONFIG.tankModeStick)
    end
end

function TWTHealerMasterTarget_OnClick()

    TWT.getClasses()

    if not UnitExists('target') or not UnitIsPlayer('target')
            or UnitName('target') == TWT.name then

        if TWT.healerMasterTarget == '' then
            twtprint(L["Please target a tank."])
        else
            TWT.removeHealerMasterTarget()
        end

        return false
    end

    if UnitName('target') == TWT.healerMasterTarget then
        return TWT.removeHealerMasterTarget()
    end

    TWT.send('TWT_HMT:' .. UnitName('target'))

    local color = TWT.classColors[TWT.getClass(UnitName('target'))]

    twtprint(L["Trying to set Healer Master Target to "] .. color.c .. UnitName('target'))

end

function TWT.removeHealerMasterTarget()
    TWT.send('TWT_HMT_REM:' .. TWT.healerMasterTarget)

    twtprint(L["Healer Master Target cleared."])

    TWT.healerMasterTarget = ''
    TWT.targetName = ''

    TWT.threats = TWT.wipe(TWT.threats)

    TWT.updateUI('removeHealerMasterTarget')

    return true
end

function TWT.addInspectMenu(to)
    local found = 0
    for i, j in UnitPopupMenus[to] do
        if j == "TRADE" then
            found = i
        end
    end
    if found ~= 0 then
        UnitPopupMenus[to][__getn(UnitPopupMenus[to]) + 1] = UnitPopupMenus[to][__getn(UnitPopupMenus[to])]
        for i = __getn(UnitPopupMenus[to]) - 1, found, -1 do
            UnitPopupMenus[to][i] = UnitPopupMenus[to][i - 1]
        end
    end
    UnitPopupMenus[to][found] = "INSPECT_TALENTS"
end

TWT.classes = {}
TWT.pets = {}

function TWT.getClass(name)
    if TWT.classes[name] then return TWT.classes[name] end
    local owner = TWT.pets[name]
    if owner then return 'pet' end
    return 'pet'
end

function TWT.getPets()
    TWT.pets = {}
    if UnitExists('pet') then
        local petName = UnitName('pet')
        if petName then
            TWT.pets[petName] = TWT.name
        end
    end
    if TWT.channel == 'RAID' then
        for i = 1, GetNumRaidMembers() do
            local unitId = 'raidpet' .. i
            if UnitExists(unitId) then
                local petName = UnitName(unitId)
                local ownerName = UnitName('raid' .. i)
                if petName and ownerName then
                    TWT.pets[petName] = ownerName
                end
            end
        end
    end
    if TWT.channel == 'PARTY' then
        for i = 1, GetNumPartyMembers() do
            local unitId = 'partypet' .. i
            if UnitExists(unitId) then
                local petName = UnitName(unitId)
                local ownerName = UnitName('party' .. i)
                if petName and ownerName then
                    TWT.pets[petName] = ownerName
                end
            end
        end
    end
end

function TWT.getClasses()
    -- 添加玩家自己
    TWT.classes[TWT.name] = TWT.class
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local name = GetRaidRosterInfo(i)
                local _, raidCls = UnitClass('raid' .. i)
                TWT.classes[name] = __lower(raidCls)
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) and UnitClass('party' .. i) then
                    local name = UnitName('party' .. i)
                    local _, raidCls = UnitClass('party' .. i)
                    TWT.classes[name] = __lower(raidCls)
                end
            end
        end
    end
    TWT.getPets()
    twtdebug('classes saved')
    return true
end

TWT.history = {}

TWT.tankName = ''

function TWT.handleThreatPacket(packet)

    --twtdebug(packet)

    local playersString = __substr(packet, __find(packet, TWT.threatApi) + __strlen(TWT.threatApi), __strlen(packet))

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.tankName = ''

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        -- udts handling
        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] then

            local player = msgEx[1]
            local tank = msgEx[2] == '1'
            local threat = __parseint(msgEx[3])
            local perc = __parseint(msgEx[4])
            local melee = msgEx[5] == '1'

            -- TODO: relay system sends data but has no receiver implementation;
            -- relayTo list has no UI to manage targets. Complete or remove in future.
            if UnitName('target') and not UnitIsPlayer('target') and TWT.shouldRelay then
                for i, name in TWT.relayTo do
                    twtdebug('relaying to ' .. i .. ' ' .. name)
                end
                TWT.send('TWTRelayV1' ..
                        ':' .. UnitName('target') ..
                        ':' .. player ..
                        ':' .. msgEx[3] ..
                        ':' .. threat ..
                        ':' .. perc ..
                        ':' .. msgEx[6]);
            end

            local now = GetTime()
            if not TWT.history[player] then
                TWT.history[player] = { values = {}, head = 0, size = 0 }
            end
            local buf = TWT.history[player]
            buf.head = math.mod(buf.head, TPS_BUFFER_SIZE) + 1
            buf.values[buf.head] = { time = now, threat = threat }
            if buf.size < TPS_BUFFER_SIZE then
                buf.size = buf.size + 1
            end

            if not TWT.classes[player] and not TWT.pets[player] then
                TWT.getPets()
            end

            TWT.threats[player] = {
                threat = threat,
                tank = tank,
                perc = perc,
                melee = melee,
                tps = TWT.calcTPS(player),
                class = TWT.getClass(player)
            }

            if tank then
                TWT.tankName = player
            end
        end
    end

    if not TWT.threats[TWT.name] then
        TWT.threats[TWT.name] = {
                threat = 0,
                tank = 0,
                perc = 0,
                melee = 0,
                tps = 0,
                class = TWT.class
            }
    end

    TWT.calcAGROPerc()

    TWT.updateUI()

end

function TWT.handleTankModePacket(packet)

    --twtdebug(msg)

    local playersString = __substr(packet, __find(packet, TWT.tankModeApi) + __strlen(TWT.tankModeApi), __strlen(packet))

    TWT.tankModeThreats = TWT.wipe(TWT.tankModeThreats)

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then

            local creature = msgEx[1]
            local guid = msgEx[2] --keep it string
            local name = msgEx[3]
            local perc = __parseint(msgEx[4])

            TWT.tankModeThreats[guid] = {
                creature = creature,
                name = name,
                perc = perc
            }

        end

    end

end

function TWT.calcAGROPerc()

    local tankThreat = 0
    for _, data in next, TWT.threats do
        if data.tank then
            tankThreat = data.threat
            break
        end
    end

    TWT.threats[TWT.AGRO] = {
        class = 'agro',
        threat = 0,
        perc = 100,
        tps = '',
        history = {},
        tank = false,
        melee = false
    }

    if not TWT.threats[TWT.name] then
        twtdebug('threats de name is bad')
        return false
    end

    TWT.threats[TWT.AGRO].threat = tankThreat * (TWT.threats[TWT.name].melee and 1.1 or 1.3)
    if TWT.threats[TWT.AGRO].threat == 0 then
        TWT.threats[TWT.AGRO].threat = 1
    end
    TWT.threats[TWT.AGRO].perc = TWT.threats[TWT.name].melee and 110 or 130

end

function TWT.combatStart(startforced)
    if TWT.inCombat == true and startforced ~= true then
        return
    end
    TWT.inCombat = true
    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    TWT.hideThreatFrames(true)
    TWT.shouldRelay = TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if TWT_CONFIG.showInCombat then
        TWTUI.mainWindow:Show()
    end

    TWT.spec = {}
    for t = 1, GetNumTalentTabs() do
        TWT.spec[t] = {
            talents = 0,
            texture = ''
        }
        for i = 1, GetNumTalents(t) do
            local _, _, _, _, currRank = GetTalentInfo(t, i);
            TWT.spec[t].talents = TWT.spec[t].talents + currRank
        end
    end

    local specIndex = 1
    for i = 2, 4 do
        local name, texture = GetSpellTabInfo(i);
        if name and texture then
            TWT.spec[specIndex].name = name
            texture = __explode(texture, '\\')
            texture = texture[__getn(texture)]
            TWT.spec[specIndex].texture = texture
            specIndex = specIndex + 1
        end
    end

    local sendTex = TWT.spec[1].texture
    if TWT.spec[2].talents > TWT.spec[1].talents and TWT.spec[2].talents > TWT.spec[3].talents then
        sendTex = TWT.spec[2].texture
    end
    if TWT.spec[3].talents > TWT.spec[1].talents and TWT.spec[3].talents > TWT.spec[2].talents then
        sendTex = TWT.spec[3].texture
    end

    if TWT.class == 'warrior' and __lower(sendTex) == 'ability_rogue_eviscerate' then
        sendTex = 'ability_warrior_savageblow' --ms
    end

    TWT.send('TWTRoleTexture:' .. sendTex)

    TWT.getClasses()

    TWT.updateUI('combatStart')

    TWT.threatQuery:Show()
    TWT.barAnimator:Show()

    TWT.applyTankModeStick()

    TWTUI.mainWindow:SetAlpha(TWT_CONFIG.combatAlpha)

    return true
end

function TWT.combatEnd()
    TWT.inCombat = false
    TWT.updateTargetFrameThreatIndicators(-1, '')

    twtdebug('time = ' .. (TWT.round(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    twtdebug('wipe threats combat end')

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.tankModeThreats = TWT.wipe(TWT.tankModeThreats)
    TWT.history = TWT.wipe(TWT.history)

    if TWT_CONFIG.hideOOC then
        TWTUI.mainWindow:Hide()
    end

    TWT.updateUI('combatEnd')

    TWT.barAnimator:Hide()

    if TWT_CONFIG.tankMode then
        TWTUI.tankModeWindow:Hide()
    end

    if TWTUI.warning then
        TWTUI.warning:Hide()
    end

    TWT.updateTitleBarText()

    TWTUI.mainWindow:SetAlpha(TWT_CONFIG.oocAlpha)

    TWT.hideThreatFrames(true)

    return true

end

function TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if __getn(TWT.relayTo) == 0 then
        return false
    end

    -- in raid
    if TWT.channel == 'RAID' and GetNumRaidMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(i) and UnitName('raid' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end
    if TWT.channel == 'PARTY' and GetNumPartyMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end

    if __getn(TWT.relayTo) == 0 then
        return false
    end

    return true
end

function TWT.checkTargetFrames()
    if _G['TargetFrame'] and _G['TargetFrame']:IsVisible() ~= nil then
        TWT.targetFrameVisible = true
    else
        TWT.targetFrameVisible = false
    end

    if _G['pfTarget'] and _G['pfTarget']:IsVisible() ~= nil then
        TWT.PFUItargetFrameVisible = true
    else
        TWT.PFUItargetFrameVisible = false
    end
end

function TWT.hideThreatFrames(force)
    if TWT.tableSize(TWT.threats) > 0 or force then
        for idx in next, TWT.threatsFrames do
            TWT.threatsFrames[idx]:Hide()
        end
        -- Also hide TWTUI bars
        for idx, bar in pairs(TWTUI.bars) do
            bar:Hide()
        end
    end
end

function TWT.targetChanged()

    if not UnitAffectingCombat('player') and TWTUI.settings and TWTUI.settings:IsVisible() then
        return true
    end

    TWT.channel = (GetNumRaidMembers() > 0) and 'RAID' or 'PARTY'

    if TWTUI.targetOverlay and UIParent:GetScale() ~= TWTUI.targetOverlay:GetScale() then
        TWTUI.targetOverlay:SetScale(UIParent:GetScale())
    end

    if TWT.healerMasterTarget ~= '' then
        return true
    end

    TWT.targetName = ''
    TWT.updateTargetFrameThreatIndicators(-1)

    -- lost target
    if not UnitExists('target') then
        return false
    end

    -- target is dead, dont show anything
    if UnitIsDead('target') then
        return false
    end

    -- dont show anything
    if UnitIsPlayer('target') then
        return false
    end

    -- non interesting target
    if UnitClassification('target') ~= 'worldboss' and UnitClassification('target') ~= 'elite' then
        return false
    end

    -- no raid or party
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    -- not in combat
    if not UnitAffectingCombat('target') then
        return false
    end

    TWT.targetName = TWT.unitNameForTitle(UnitName('target'))

    TWT.updateTitleBarText(TWT.targetName)

    return true
end

function TWT.send(msg)
    SendAddonMessage(TWT.prefix, msg, TWT.channel)
end

function TWT.UnitDetailedThreatSituation(limit)
    SendAddonMessage(TWT.UDTS .. (TWT_CONFIG.tankMode and '_TM' or ''), "limit=" .. limit, TWT.channel)
end

-- Helper: build the right-side text for a bar based on column config
local function buildBarRightText(data, name)
    local parts = {}
    if TWT_CONFIG.colTPS and data.tps and data.tps ~= '' then
        __tinsert(parts, __parsestring(data.tps))
    end
    if TWT_CONFIG.colThreat then
        if name == TWT.AGRO then
            __tinsert(parts, '+' .. TWT.formatNumber(data.threat - (TWT.threats[TWT.name] and TWT.threats[TWT.name].threat or 0)))
        else
            __tinsert(parts, TWT.formatNumber(data.threat))
        end
    end
    if TWT_CONFIG.colPerc then
        local percText
        if TWT.name ~= TWT.tankName and name == TWT.AGRO then
            percText = (100 - TWT.round(TWT.threats[TWT.name] and TWT.threats[TWT.name].perc or 0)) .. '%'
        else
            percText = TWT.round(data.perc) .. '%'
        end
        __tinsert(parts, percText)
    end

    if __getn(parts) == 0 then return '' end

    -- Join with ' - '
    local result = parts[1]
    for i = 2, __getn(parts) do
        result = result .. ' - ' .. parts[i]
    end
    return result
end

function TWT.updateUI(from)

    --twtdebug('update ui call from [' .. (from or '') .. ']')

    TWT.checkTargetFrames()

    uiUpdates = uiUpdates + 1

    if not TWT.barAnimator:IsVisible() then
        TWT.barAnimator:Show()
    end

    TWT.hideThreatFrames()

    if TWT.inCombat ~= true and TWTUI.settings and not TWTUI.settings:IsVisible() then
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    if TWT.targetName == '' then
        return false
    end

    if TWTUI.settings and TWTUI.settings:IsVisible() and not UnitAffectingCombat('player') then
        TWT.tankName = 'Tenk'
    end

    local index = 0
    local barTex = TWT.textures[TWT_CONFIG.texture] or TWT.textures[2]

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do

        if data and TWT.threats[TWT.name] and index < TWT_CONFIG.visibleBars then

            index = index + 1

            -- Create bar if it doesn't exist
            if not TWTUI.bars[index] then
                TWTUI.CreateBar(TWTUI.mainWindow, index)
            end

            local bar = TWTUI.bars[index]

            bar:SetAlpha(TWT_CONFIG.combatAlpha)

            bar:SetStatusBarTexture(barTex)
            bar.bg:SetStatusBarTexture(barTex)
            bar:ClearAllPoints()
            bar:SetPoint("TOPLEFT", TWTUI.mainWindow, "TOPLEFT", 2,
                    (TWT_CONFIG.labelRow and -40 or -20) +
                            TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)
            bar:SetPoint("TOPRIGHT", TWTUI.mainWindow, "TOPRIGHT", -2,
                    (TWT_CONFIG.labelRow and -40 or -20) +
                            TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)
            bar:SetHeight(TWT_CONFIG.barHeight - TWT_CONFIG.spacing)

            -- Role icon
            bar.roleIcon:Hide()
            if name ~= TWT.AGRO then
                bar.roleIcon:SetWidth(TWT_CONFIG.barHeight - 2)
                bar.roleIcon:SetHeight(TWT_CONFIG.barHeight - 2)
                bar.textLeft:SetPoint('LEFT', bar.roleIcon, 'RIGHT', 1 + (TWT_CONFIG.barHeight / 15), -1)
                if data.class == 'pet' then
                    bar.roleIcon:SetTexture('Interface\\Icons\\Ability_Hunter_BeastCall')
                    bar.roleIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    bar.roleIcon:Show()
                else
                    bar.roleIcon:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes')
                    bar.roleIcon:SetTexCoord(unpack(TWT.classCoords[data.class] or TWT.classCoords["priest"]))
                    bar.roleIcon:Show()
                end
            else
                bar.textLeft:SetPoint('LEFT', bar, 'LEFT', 5, 0)
            end

            -- Name with index prefix (like ShaguDPS)
            local classColor = TWT.classColors[data.class] or TWT.classColors['priest']
            bar.textLeft:SetText("|cffffffff" .. index .. ". " .. classColor.c .. name)

            -- Update tooltip data (reuse existing table to reduce GC)
            if not bar.tooltipData then bar.tooltipData = {} end
            bar.tooltipData.name = name
            bar.tooltipData.threat = TWT.formatNumber(data.threat)
            bar.tooltipData.tps = data.tps and __parsestring(data.tps) or '0'
            bar.tooltipData.percent = TWT.round(data.perc)

            -- Bar color and value
            local color = TWT.classColors[data.class]

            if name == TWT.name then

                if TWT_CONFIG.aggroSound and data.perc >= TWT_CONFIG.aggroThreshold and time() - TWT.lastAggroWarningSoundTime > 5
                        and not TWT_CONFIG.fullScreenGlow then
                    PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    TWT.lastAggroWarningSoundTime = time()
                end

                if TWT_CONFIG.fullScreenGlow and data.perc >= TWT_CONFIG.aggroThreshold and time() - TWT.lastAggroWarningGlowTime > 5 then
                    TWT.glowFader:Show()
                    TWT.lastAggroWarningGlowTime = time()
                    if TWT_CONFIG.aggroSound then
                        PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    end
                end

                TWT.updateTitleBarText(TWT.targetName .. ' (' .. TWT.round(data.perc) .. '%)')

                if data.perc == 0 then
                    bar:SetValue(0)
                else
                    TWT.barAnimator:animateTo(index, data.perc)
                end

                local cr, cg, cb = 1, 0.2, 0.2
                local sat = (TWT_CONFIG.saturation or 10) / 10
                if sat ~= 1 then
                    local avg = (cr + cg + cb) / 3
                    cr = math.max(0, math.min(1, avg + (cr - avg) * sat))
                    cg = math.max(0, math.min(1, avg + (cg - avg) * sat))
                    cb = math.max(0, math.min(1, avg + (cb - avg) * sat))
                end
                bar:SetStatusBarColor(cr, cg, cb)
                bar.bg:SetStatusBarColor(0.2, 0.2, 0.2, 0.5)

            elseif name == TWT.AGRO then

                TWT.barAnimator:animateTo(index, nil)
                bar:SetValue(100)

                local cr, cg, cb = 0, 1, 0
                local colorLimit = 50

                if TWT.threats[TWT.name].perc >= 0 and TWT.threats[TWT.name].perc < colorLimit then
                    cr = TWT.threats[TWT.name].perc / colorLimit
                    cg = 1
                    cb = 0
                elseif TWT.threats[TWT.name].perc >= colorLimit then
                    cr = 1
                    cg = 1 - (TWT.threats[TWT.name].perc - colorLimit) / colorLimit
                    cb = 0
                end

                if TWT.tankName == TWT.name then
                    cr, cg, cb = 1, 0, 0
                end

                local sat = (TWT_CONFIG.saturation or 10) / 10
                if sat ~= 1 then
                    local avg = (cr + cg + cb) / 3
                    cr = math.max(0, math.min(1, avg + (cr - avg) * sat))
                    cg = math.max(0, math.min(1, avg + (cg - avg) * sat))
                    cb = math.max(0, math.min(1, avg + (cb - avg) * sat))
                end
                bar:SetStatusBarColor(cr, cg, cb, 0.9)

            else

                TWT.barAnimator:animateTo(index, data.perc)
                local cr, cg, cb = color.r, color.g, color.b
                if TWT_CONFIG.pastel then
                    cr = (cr + 0.5) * 0.5
                    cg = (cg + 0.5) * 0.5
                    cb = (cb + 0.5) * 0.5
                end
                local sat = (TWT_CONFIG.saturation or 10) / 10
                if sat ~= 1 then
                    local avg = (cr + cg + cb) / 3
                    cr = math.max(0, math.min(1, avg + (cr - avg) * sat))
                    cg = math.max(0, math.min(1, avg + (cg - avg) * sat))
                    cb = math.max(0, math.min(1, avg + (cb - avg) * sat))
                end
                bar:SetStatusBarColor(cr, cg, cb, 0.9)
                bar.bg:SetStatusBarColor(0.2, 0.2, 0.2, 0.5)
            end

            if data.tank then
                TWT.barAnimator:animateTo(index, 100, true)
            end

            if name == TWT.name then
                TWT.updateTargetFrameThreatIndicators(data.perc)
            end

            -- Build right text
            bar.textRight:SetText(buildBarRightText(data, name))

            bar:Show()

        end

    end

    -- Tank mode
    if TWT_CONFIG.tankMode then

        -- Hide all entries first
        for i = 1, 5 do
            if TWTUI.tankModeEntries and TWTUI.tankModeEntries[i] then
                TWTUI.tankModeEntries[i]:Hide()
            end
        end

        if TWTUI.tankModeWindow then
            TWTUI.tankModeWindow:SetHeight(0)
        end

        if TWT.tableSize(TWT.tankModeThreats) > 1 then

            -- Sort by threat percentage descending
            local sorted = {}
            for guid, data in next, TWT.tankModeThreats do
                __tinsert(sorted, { guid = guid, creature = data.creature, name = data.name, perc = data.perc })
            end
            __tsort(sorted, function(a, b) return a.perc > b.perc end)

            local i = 0
            for _, data in ipairs(sorted) do

                i = i + 1
                if i > 5 then
                    break
                end

                if TWTUI.tankModeWindow then
                    TWTUI.tankModeWindow:SetHeight(i * 25 + 23)
                end

                local entry = TWTUI.tankModeEntries[i]
                if entry then
                    entry.creatureName:SetText(data.creature)
                    entry.playerName:SetText(TWT.classColors[TWT.getClass(data.name)].c .. data.name)
                    entry.threatPct:SetText(TWT.round(data.perc) .. '%')
                    entry.targetUnit = data.name

                    entry:ClearAllPoints()
                    entry:SetPoint("TOPLEFT", TWTUI.tankModeWindow, "TOPLEFT", 2, -20 - (i - 1) * 18)
                    entry:SetPoint("TOPRIGHT", TWTUI.tankModeWindow, "TOPRIGHT", -2, -20 - (i - 1) * 18)

                    if data.perc >= 0 and data.perc < 50 then
                        entry.bg:SetTexture(data.perc / 50, 1, 0, 0.5)
                    else
                        entry.bg:SetTexture(1, 1 - (data.perc - 50) / 50, 0, 0.5)
                    end

                    entry:Show()
                end

                if TWTUI.tankModeWindow then
                    TWTUI.tankModeWindow:Show()
                end

            end

        else
            if TWTUI.tankModeWindow then
                TWTUI.tankModeWindow:Hide()
            end
        end
    else
        if TWTUI.tankModeWindow then
            TWTUI.tankModeWindow:Hide()
        end
    end

end

TWT.barAnimator = CreateFrame('Frame')
TWT.barAnimator:Hide()
TWT.barAnimator.frames = {}

function TWT.barAnimator:animateTo(index, perc, instant)
    local bar = TWTUI.bars[index]
    if not bar then return end

    local key = "bar" .. index

    if perc == nil then
        -- stop animating this bar
        self.frames[key] = nil
        return
    end

    local targetVal = math.min(perc, 100)

    if instant then
        bar:SetValue(targetVal)
        self.frames[key] = nil
    else
        self.frames[key] = { index = index, target = targetVal }
    end
end

TWT.barAnimator:SetScript("OnShow", function()
    this.frames = {}
end)

TWT.barAnimator:SetScript("OnUpdate", function()
    local SMOOTHING = 6
    local elapsed = arg1

    for key, info in pairs(this.frames) do
        local bar = TWTUI.bars[info.index]
        if bar then
            local current = bar:GetValue()
            local diff = info.target - current
            if diff ~= 0 then
                local step = diff * math.min(1, SMOOTHING * elapsed)
                bar:SetValue(current + step)
            end
            if math.abs(diff) < 0.5 then
                bar:SetValue(info.target)
                this.frames[key] = nil
            end
        else
            this.frames[key] = nil
        end
    end
end)

local threatQueryElapsed = 0

TWT.threatQuery:SetScript("OnShow", function()
    threatQueryElapsed = 0
end)
TWT.threatQuery:SetScript("OnHide", function()
end)
TWT.threatQuery:SetScript("OnUpdate", function()
    threatQueryElapsed = threatQueryElapsed + arg1

    -- check if target swap was long enough to actually do
    if TWT.queue_hide then
        local gt = GetTime() * 1000
        if gt >= TWT.queue_hide + 100 then
            if not TWT.targetChanged() then
                TWT.hideThreatFrames(true)
            end
            TWT.queue_hide = nil
        end
    end

    if threatQueryElapsed < TWT.updateSpeed then return end
    threatQueryElapsed = 0

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end
    if UnitAffectingCombat('target') then
        TWT.combatStart()
        if TWT.targetName == '' then
            twtdebug('threatQuery target = blank ')
            TWT.targetChanged()
            return false
        end

        if TWT_CONFIG.glow or TWT_CONFIG.perc or
                TWT_CONFIG.glowPFUI or TWT_CONFIG.percPFUI or
                TWT_CONFIG.fullScreenGlow or TWT_CONFIG.tankMode or
                TWT_CONFIG.visible then
            if TWT.healerMasterTarget == '' then
                TWT.UnitDetailedThreatSituation(TWT_CONFIG.visibleBars - 1)
            end
        else
            twtdebug('not asking threat situation')
        end
    end
end)

function TWT.calcTPS(name)
    local buf = TWT.history[name]
    if not buf or buf.size < 2 then return 0 end

    local newest = buf.values[buf.head]
    local oldestIdx = math.mod((buf.head - buf.size) + TPS_BUFFER_SIZE, TPS_BUFFER_SIZE) + 1
    local oldest = buf.values[oldestIdx]

    if not newest or not oldest then return 0 end

    local timeDiff = newest.time - oldest.time
    if timeDiff <= 0 then return 0 end

    local threatDiff = newest.threat - oldest.threat
    local result = threatDiff / timeDiff

    if result < 0 then return 0 end
    return TWT.round(result)
end

function TWT.updateTargetFrameThreatIndicators(perc)

    if TWTUI.fullScreenGlow then
        if TWT_CONFIG.fullScreenGlow then
            TWTUI.fullScreenGlow:Show()
        else
            TWTUI.fullScreenGlow:Hide()
        end
    end

    if perc == -1 then
        TWT.updateTitleBarText()
        if TWTUI.targetOverlay then TWTUI.targetOverlay:Hide() end
        if TWTUI.targetOverlayPFUI then TWTUI.targetOverlayPFUI:Hide() end
        return false
    end

    if not TWT_CONFIG.glow and not TWT_CONFIG.perc and not TWT.targetFrameVisible then
        if TWTUI.targetOverlay then TWTUI.targetOverlay:Hide() end
    end

    if not TWT_CONFIG.glowPFUI and not TWT_CONFIG.percPFUI and not TWT.PFUItargetFrameVisible then
        if TWTUI.targetOverlayPFUI then TWTUI.targetOverlayPFUI:Hide() end
    end

    if not TWT.targetFrameVisible and not TWT.PFUItargetFrameVisible then
        return false
    end

    if TWT.targetFrameVisible and TWTUI.targetOverlay then
        TWTUI.targetOverlay:Show()
    end
    if TWT.PFUItargetFrameVisible and TWTUI.targetOverlayPFUI then
        TWTUI.targetOverlayPFUI:Show()
    end

    perc = TWT.round(perc)

    if TWT_CONFIG.glow and TWTUI.targetOverlay then

        local unitClassification = UnitClassification('target')
        if unitClassification == 'worldboss' then
            unitClassification = 'elite'
        end

        TWTUI.targetOverlay.glow:SetTexture('Interface\\addons\\TWThreat\\images\\' .. unitClassification)

        if perc >= 0 and perc < 50 then
            TWTUI.targetOverlay.glow:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            TWTUI.targetOverlay.glow:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        TWTUI.targetOverlay.glow:Show()
    else
        if TWTUI.targetOverlay then TWTUI.targetOverlay.glow:Hide() end
    end

    if TWT_CONFIG.glowPFUI and _G['pfTarget'] and TWTUI.targetOverlayPFUI then

        if perc >= 0 and perc < 50 then
            TWTUI.targetOverlayPFUI.glow:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            TWTUI.targetOverlayPFUI.glow:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        TWTUI.targetOverlayPFUI.glow:Show()
    else
        if TWTUI.targetOverlayPFUI then TWTUI.targetOverlayPFUI.glow:Hide() end
    end

    if TWT_CONFIG.perc and TWTUI.targetOverlay then

        local percText = perc .. '%'

        if TWT_CONFIG.tankMode then
            local second = ''
            local tindex = 0
            for tname, tdata in TWT.ohShitHereWeSortAgain(TWT.threats, true) do
                tindex = tindex + 1
                if tindex == 3 then
                    percText = TWT.unitNameForTitle(tname, 6) .. ' ' .. TWT.round(tdata.perc) .. '%'
                    break
                end
            end
        end

        TWTUI.targetOverlay.percent:SetText(percText)
        TWTUI.targetOverlay.percent:Show()
    else
        if TWTUI.targetOverlay then TWTUI.targetOverlay.percent:Hide() end
    end

    if TWT_CONFIG.percPFUI and _G['pfTarget'] and TWTUI.targetOverlayPFUI then

        local percText = perc .. '%'

        if TWT_CONFIG.tankMode then
            local second = ''
            local tindex = 0
            for tname, tdata in TWT.ohShitHereWeSortAgain(TWT.threats, true) do
                tindex = tindex + 1
                if tindex == 3 then
                    percText = TWT.unitNameForTitle(tname, 6) .. ' ' .. TWT.round(tdata.perc) .. '%'
                    break
                end
            end
        end

        TWTUI.targetOverlayPFUI.percent:SetText(percText)
        TWTUI.targetOverlayPFUI.percent:Show()
    else
        if TWTUI.targetOverlayPFUI then TWTUI.targetOverlayPFUI.percent:Hide() end
    end

end

function TWT.setColumnLabels()
    local width = TWT.windowStartWidth - 70 - 70 - 70

    TWT.nameLimit = 5

    if TWT_CONFIG.colPerc then
        width = width + 70
        TWT.nameLimit = TWT.nameLimit + 8
    end

    if TWT_CONFIG.colThreat then
        width = width + 70
        TWT.nameLimit = TWT.nameLimit + 8
    end

    if TWT_CONFIG.colTPS then
        width = width + 70
        TWT.nameLimit = TWT.nameLimit + 8
    end

    if TWT.nameLimit < 14 then
        TWT.nameLimit = 14
    end

    if width < 190 then
        width = 190
    end

    -- Only set width if current width is smaller than calculated minimum
    TWT.windowWidth = width
    if TWTUI.mainWindow:GetWidth() < width then
        TWTUI.mainWindow:SetWidth(width)
    end

    TWT.setMinMaxResize()
end

function TWT.setMinMaxResize()
    local headerH = TWT_CONFIG.labelRow and 40 or 20
    TWTUI.mainWindow:SetMinResize(150, headerH)
end

function TWT.applyBackdrop()
    if not TWTUI.mainWindow then return end
    if TWT_CONFIG.backdrop then
        TWTUI.mainWindow:SetBackdrop(TWTUI.backdrop_window)
        TWTUI.mainWindow:SetBackdropColor(.5, .5, .5, .5)
        TWTUI.mainWindow.border:SetBackdrop(TWTUI.backdrop_border)
        TWTUI.mainWindow.border:SetBackdropBorderColor(.7, .7, .7, 1)
    else
        TWTUI.mainWindow:SetBackdrop(nil)
        TWTUI.mainWindow.border:SetBackdrop(nil)
    end
end

function TWT.resetData()
    TWT.threats = {}
    TWT.tankModeThreats = {}
    TWT.hideThreatFrames(true)
    TWT.updateTitleBarText()
    if TWTUI.warning then TWTUI.warning:Hide() end
end

function TWT.testBars(show)

    if UnitAffectingCombat('player') then
        return false
    end

    if show then
        TWT.roles['Tenk'] = 'ability_warrior_defensivestance'
        TWT.roles['Chad'] = 'spell_holy_auraoflight'
        TWT.roles[TWT.name] = 'ability_hunter_pet_turtle'
        TWT.roles['Olaf'] = 'ability_racial_bearform'
        TWT.roles['Jimmy'] = 'ability_backstab'
        TWT.roles['Miranda'] = 'spell_shadow_shadowwordpain'
        TWT.roles['Karen'] = 'spell_holy_powerinfusion'
        TWT.roles['Felix'] = 'spell_fire_sealoffire'
        TWT.roles['Tom'] = 'spell_shadow_shadowbolt'
        TWT.roles['Bill'] = 'ability_marksmanship'
        TWT.threats = {
            [TWT.AGRO] = {
                class = 'agro', threat = 1100, perc = 110, tps = '',
                history = {}, melee = true, tank = false
            },
            ['Tenk'] = {
                class = 'warrior', threat = 1000, perc = 100, tps = 100,
                history = {}, melee = true, tank = true },
            ['Chad'] = {
                class = 'paladin', threat = 990, perc = 99, tps = 99,
                history = {}, melee = true, tank = false },
            [TWT.name] = {
                class = TWT.class, threat = 750, perc = 75, tps = 75,
                history = {}, melee = false, tank = false
            },
            ['Olaf'] = {
                class = 'druid', threat = 700, perc = 70, tps = 70,
                history = {}, melee = true, tank = false
            },
            ['Jimmy'] = {
                class = 'rogue', threat = 500, perc = 50, tps = 50,
                history = {}, melee = true, tank = false
            },
            ['Miranda'] = {
                class = 'priest', threat = 450, perc = 45, tps = 45,
                history = {}, melee = false, tank = false
            },
            ['Karen'] = {
                class = 'priest', threat = 400, perc = 40, tps = 40,
                history = {}, melee = true, tank = false
            },
            ['Felix'] = {
                class = 'mage', threat = 350, perc = 35, tps = 35,
                history = {}, melee = false, tank = false
            },
            ['Tom'] = {
                class = 'warlock', threat = 250, perc = 25, tps = 25,
                history = {}, melee = false, tank = false
            },
            ['Bill'] = {
                class = 'hunter', threat = 100, perc = 10, tps = 10,
                history = {}, melee = false, tank = false
            }
        }

        TWT.tankModeThreats = {
            [1] = {
                creature = 'Infectious Ghoul',
                name = 'Bob',
                perc = 78
            },
            [2] = {
                creature = 'Venom Stalker',
                name = 'Alice',
                perc = 95
            },
            [3] = {
                creature = 'Living Monstrosity',
                name = 'Chad',
                perc = 52
            },
            [4] = {
                creature = 'Deathknight Captain',
                name = 'Olaf',
                perc = 81
            },
            [5] = {
                creature = 'Patchwerk TEST',
                name = 'Jimmy',
                perc = 12
            },
        }

        TWT.targetChanged()

        TWT.targetName = "Patchwerk TEST"

        TWT.updateUI('testBars')
    else
        TWT.combatEnd()
    end
end

function TWT.applyTankModeStick(to)
    if to then
        TWT_CONFIG.tankModeStick = to
    end
    if not TWTUI.tankModeWindow or not TWTUI.mainWindow then return end

    if TWT_CONFIG.tankModeStick == 'Top' then
        TWTUI.tankModeWindow:ClearAllPoints()
        TWTUI.tankModeWindow:SetPoint('BOTTOMLEFT', TWTUI.mainWindow, 'TOPLEFT', 0, 1)
    elseif TWT_CONFIG.tankModeStick == 'Right' then
        TWTUI.tankModeWindow:ClearAllPoints()
        TWTUI.tankModeWindow:SetPoint('TOPLEFT', TWTUI.mainWindow, 'TOPRIGHT', 1, 0)
    elseif TWT_CONFIG.tankModeStick == 'Bottom' then
        TWTUI.tankModeWindow:ClearAllPoints()
        TWTUI.tankModeWindow:SetPoint('TOPLEFT', TWTUI.mainWindow, 'BOTTOMLEFT', 0, -1)
    elseif TWT_CONFIG.tankModeStick == 'Left' then
        TWTUI.tankModeWindow:ClearAllPoints()
        TWTUI.tankModeWindow:SetPoint('TOPRIGHT', TWTUI.mainWindow, 'TOPLEFT', -1, 0)
    end
end

function TWTTargetButton_OnClick(index)

    if TWT.tankModeThreats[__parsestring(index)] then
        local unit = TWT.units[index]
        if has_superwow and unit then
            TargetUnit(unit)
        else
            AssistByName(TWT.tankModeThreats[__parsestring(index)].name)
        end
        return true
    end

    twtprint(L["Cannot target tankmode target."])

    return false
end

function __explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = __find(str, delimiter, from, true)
    while delim_from do
        __tinsert(result, __substr(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = __find(str, delimiter, from, true)
    end
    __tinsert(result, __substr(str, from))
    return result
end

TWT._sortCache = {}

function TWT.ohShitHereWeSortAgain(t, reverse)
    local a = TWT._sortCache
    local idx = 0
    for n, l in __pairs(t) do
        idx = idx + 1
        if not a[idx] then a[idx] = {} end
        a[idx].threat = l.threat
        a[idx].perc = l.perc
        a[idx].tps = l.tps
        a[idx].name = n
    end
    for i = idx + 1, __getn(a) do
        a[i] = nil
    end
    if reverse then
        __tsort(a, function(b, c)
            return b.perc > c.perc
        end)
    else
        __tsort(a, function(b, c)
            return b.perc < c.perc
        end)
    end

    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i].name, t[a[i].name]
        end
    end
    return iter
end

function TWT.formatNumber(n)
    if n < 0 then n = 0 end
    if n < 1000 then return TWT.round(n) end
    if n < 1000000 then
        return TWT.round(n / 1000, 1) .. 'K'
    end
    return TWT.round(n / 1000000, 1) .. 'M'
end

function TWT.tableSize(t)
    local size = 0
    for _, _ in next, t do
        size = size + 1
    end
    return size
end

function TWT.targetFromName(name)
    if name == TWT.name then
        return 'target'
    end
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == name then
                    return 'raid' .. i
                end
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) then
                    if name == UnitName('party' .. i) then
                        return 'party' .. i
                    end
                end
            end
        end
    end

    return 'target'
end

function TWT.unitNameForTitle(name, limit)
    limit = limit or TWT.nameLimit
    if __strlen(name) > limit then
        return __substr(name, 1, limit) .. ' '
    end
    return name
end

function TWT.targetRaidIcon(iconIndex)

    for i = 1, GetNumRaidMembers() do
        if TWT.targetRaidSymbolFromUnit("raid" .. i, iconIndex) then
            return true
        end
    end
    for i = 1, GetNumPartyMembers() do
        if TWT.targetRaidSymbolFromUnit("party" .. i, iconIndex) then
            return true
        end
    end
    if TWT.targetRaidSymbolFromUnit("player", iconIndex) then
        return true
    end
    return false
end

function TWT.updateTitleBarText(text)
    if not TWTUI.mainWindow or not TWTUI.mainWindow.caption then return end
    if not text then
        TWTUI.mainWindow.caption:SetText(TWT.addonName)
        return true
    end
    TWTUI.mainWindow.caption:SetText(text)
end


function TWT.wipe(src)
    for k in __pairs(src) do
        src[k] = nil
    end
    return src
end

TWT.hooks = {}
--https://github.com/shagu/pfUI/blob/master/compat/vanilla.lua#L37
function TWT.hooksecurefunc(name, func, append)
    if not _G[name] then
        return
    end

    TWT.hooks[__parsestring(func)] = {}
    TWT.hooks[__parsestring(func)]["old"] = _G[name]
    TWT.hooks[__parsestring(func)]["new"] = func

    if append then
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = TWT.hooks[__parsestring(func)]["function"]
end

function TWT.pairsByKeys(t, f)
    local a = {}
    for n in __pairs(t) do
        __tinsert(a, n)
    end
    __tsort(a, f or function(a, b)
        return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function TWT.round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return __floor(num * mult + 0.5) / mult
end

function TWT.version(ver)
    local verEx = __explode(ver, '.')

    if verEx[3] then
        -- new versioning with 3 numbers
        return __parseint(verEx[1]) * 100 +
                __parseint(verEx[2]) * 10 +
                __parseint(verEx[3]) * 1
    end

    -- old versioning
    return __parseint(verEx[1]) * 10 +
            __parseint(verEx[2]) * 1

end

function TWT.sendMyVersion()
    local msg = "TWTVersion:" .. TWT.addonVer
    if GetNumRaidMembers() > 0 then
        SendAddonMessage(TWT.prefix, msg, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage(TWT.prefix, msg, "PARTY")
    end
    if IsInGuild() then
        SendAddonMessage(TWT.prefix, msg, "GUILD")
    end
end

-- [DEBUG] Confirm successful load (remove after debugging)
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[TWT] TWThreat.lua loaded OK, TWT=" .. tostring(TWT) .. " type=" .. type(TWT))
