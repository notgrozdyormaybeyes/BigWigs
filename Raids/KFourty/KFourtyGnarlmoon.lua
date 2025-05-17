
local module, L = BigWigs:ModuleDeclaration("Keeper Gnarlmoon", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"lunarshift", "owls", "owlsHp", "ravens", "color", "gaze"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
 lunarshift = true,
 owls = true,
 owlsHp = true,
 ravens = true,
 color = true,
 gaze = true,
}

L:RegisterTranslations("enUS", function()
    return {
        cmd = "Gnarlmoon",

        lunarshift_cmd = "lunarshift",
        lunarshift_name = "Lunar Shift Alert",
        lunarshift_desc = "Warn for Lunar Shift",

        owls_cmd = "owls",
        owls_name = "Owls Alert",
        owls_desc = "Warn for Owls",
        
        owlsHp_cmd = "OwlsHP",
        owlsHp_name = "Owls HP Alert",
        owlsHp_desc = "Warn for Owls HP",
        
        ravens_cmd = "ravens",
        ravens_name = "Blood Ravens Alert",
        ravens_desc = "Warns for Blood Ravens",
        
        color_cmd = "color",
        color_name = "Color Alert",
        color_desc = "Warns for Color and Color change",
        
        gaze_cmd = "gaze",
        gaze_name = "Owl Gaze Alert",
        gaze_desc = "Warn for Owl Gaze",
        
        trigger_lunarShiftCast = "Behold, the Lunar Shift", --CHAT_MSG_MONSTER_YELL
        bar_lunarShiftCast = "Lunar Shift Cast",
        msg_lunarShift = "Casting Lunar Shift!",
        soundlunar = "Interface\\Addons\\BigWigs\\Sounds\\lunar.mp3",
        
        trigger_lunarShiftAfflic = "Keeper Gnarlmoon begins to cast Lunar Shift.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
        bar_lunarShiftCd = "Next Lunar Shift",
        
        msg_owlOne = "Gnarlmoon under 68% - Owl Phase Soon (@ 66.6%)!",
        msg_owlTwo = "Gnarlmoon under 35% - Owl Phase Soon (@ 33.3%)!",
        
        trigger_owls = "Keeper Gnarlmoon gains Worgen Dimension", --CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
        trigger_end_owls = "Worgen Dimension fades from Keeper Gnarlmoon.",
        msg_owls = "Gnarlmoon is Immune! Kill the Owls at the same time!",
        bar_owls = "Owls enrage in..",
        bar_owlsenrage = "Enrage soon, kill the owls!!",
        
        redowl = "Red Owl",
        blueowl = "Blue Owl",
        selfhitone = "Your ",  -- i am too lazy for regex
        selfhittwo = " hits ",
        selfhitthree = " for ",
        selfspellone = " suffers ",  -- i am too lazy for regex
        selfspelltwo = " damage from your ",
        
        bar_ravens = "Next Ravens",
        bar_ravensSoon = "Ravens Soon",
        msg_ravens = "Blood Ravens! Blue side kill them!",
        
        trigger_colorblue = "You are afflicted by Blue Moon (1).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
        msg_blue = "You are now BLUE! Go RIGHT side!",
        trigger_colorred = "You are afflicted by Red Moon (1).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
        msg_red = "You are now RED! Go LEFT side!",
        
        trigger_gaze = "You are afflicted by Owl Gaze (1).", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
        trigger_gazeOther = "(.+) is afflicted by Owl Gaze (1).", --CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE // CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE
        bar_gaze = " Owl Gaze !",
        msg_gaze = " is afflicted by Owl Gaze!",
        msg_gazeYou = "You are afflicted by Owl Gaze! Check debuffs!",
        
        trigger_engage = "The Moon, it calls...", --CHAT_MSG_MONSTER_YELL
        trigger_bossDead = "It was meant to be..", --CHAT_MSG_MONSTER_YELL
    } 
end 
)

local boss_guid = ""
local ravens_guid = 51083
local redowlone_guid = nil
local redowltwo_guid = nil
local blueowlone_guid = nil
local blueowltwo_guid = nil
local lowHp = 0
local healthPct = 100
local lunarShiftCounter = 0
local previousColor = nil
--local redhp = 100
--local bluehp = 100


local timer = {
    lunarshift = 30,
    lunarshift_cast = 4,
    owls_enrage = 60,
    owls_enragesoon = 10,
    ravens_first = 15,
    ravens = 40, -- useless because hardcoded...
    mark = 5,
}
local icon = {
    lunarshift = "Spell_Nature_StarFall",
    ravens = "Spell_Nature_Sentinal",
    owls = "Ability_EyeOfTheOwl",
    owls_enrage = "Ability_Druid_ChallangingRoar",
    red = "Inv_misc_head_dragon_red",
    blue = "Inv_misc_head_dragon_blue",
    gaze = "Spell_Shadow_Charm",
    mark = "Ability_Hunter_Snipershot",
    hpBar = "Spell_Holy_SealOfSacrifice", 
    hpBarCross = "INV_Bijou_Red", 
    hpBarCircle = "INV_Bijou_Orange", 
    hpBarSquare = "INV_Bijou_Blue", 
    hpBarTriangle = "INV_Bijou_Green", 
}
local color = {
    lunarshift = "Black",
    lunarshift_cast = "White",
    owls = "White",
    owls_enrage = "Red",
    ravens = "Blue",
    ravens_soon = "Cyan",
    gaze = "Green",
    mark = "Green",
    hpBar = "Magenta",
}
local syncName = {
    bossguid = "BossGuid"..module.revision,
    lunarshift = "LunarShift"..module.revision,
    ravens = "Ravens"..module.revision,
    owls = "Owls"..module.revision,
    redowlone = "RedOwlOne"..module.revision,
    redowltwo = "RedOwlTwo"..module.revision,
    blueowlone = "BlueOwlOne"..module.revision,
    blueowltwo = "BlueOwlTwo"..module.revision,
    gaze = "Gaze"..module.revision,
    gazeother = "GazeOther"..module.revision,
    lowHp = "KeeperGnarlmoon"..module.revision,
}



module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event")--trigger_engage,--trigger_lunarShiftCast,--trigger_bossDead
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "Event") --trigger_owls
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_BUFF", "Event") --trigger_owls
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event") --trigger_owls
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")--trigger_lunarShiftAfflic
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event") --trigger_gaze, --trigger_colorRed, --trigger_colorBlue
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event") 
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event") 
    self:RegisterEvent("UNIT_HEALTH") --lowHp
    
    if SUPERWOW_VERSION then -- check if SuperWoW is used. pray that RL has it to sync with you :)
        self:RegisterEvent("UNIT_CASTEVENT", "CastEvent")
    end
    
    self:ThrottleSync(20, syncName.bossguid)
    self:ThrottleSync(5, syncName.lunarshift)
    self:ThrottleSync(20, syncName.ravens)
    self:ThrottleSync(5, syncName.owls)
    self:ThrottleSync(1, syncName.redowlone)
    self:ThrottleSync(1, syncName.redowltwo)
    self:ThrottleSync(1, syncName.blueowlone)
    self:ThrottleSync(1, syncName.blueowltwo)
    self:ThrottleSync(5, syncName.gaze)
    self:ThrottleSync(5, syncName.gazeother)
    self:ThrottleSync(3, syncName.lowHp)
    lunarShiftCounter = 0
end

function module:OnSetup()
    self.started = nil
end

function module:OnEngage()
    if SUPERWOW_VERSION and IsRaidLeader() then --UnitClass("Player") == "Hunter" then -- hunter chads helping other chads
        TargetByName("Keeper Gnarlmoon", true) --enUS hardcoded... should use L["bossname"]
        local _, bossguid = UnitExists("target")
        self:Sync(syncName.bossguid.." "..bossguid)
        TargetLastTarget()
    end
    if self.db.profile.lunarshift then
        self:Bar(L["bar_lunarShiftCd"], timer.lunarshift, icon.lunarshift, true, color.lunarshift)
        --self:DelayedBar(timer.lunarshift, L["bar_lunarShiftCast"], timer.lunarshift_cast, icon.lunarshift, true, color.lunarshift_cast)
    end
    
    if self.db.profile.ravens then
        self:Bar(L["bar_ravens"], timer.ravens_first, icon.ravens, true, color.ravens)
        --self:ScheduleRepeatingEvent("Ravens", self.Ravens, 40, self)
    end
end

function module:OnDisengage()
end

function module:CastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
    if spellId == ravens_guid and eventType == "START" then 
        self:Sync(syncName.ravens)
    end
    if casterGuid == boss_guid then
        if eventType == "START" then 
            --print(casterGuid.." "..targetGuid.." "..eventType.." "..spellId.." "..castTime)
        end
    end
end

function module:UNIT_HEALTH(msg)
    if UnitName(msg) == "Keeper Gnarlmoon" then
        healthPct = UnitHealth(msg) * 100 / UnitHealthMax(msg)
        if lowHp ~= 0 and healthPct >= 69 then
            lowHp = 0
        elseif lowHp == 0 and healthPct < 69 and healthPct > 65 then
            self:Sync(syncName.lowHp)
        elseif lowHp == 1 and healthPct < 36 then
            self:Sync(syncName.lowHp)
        elseif lowHp == 2 and healthPct <= 33 then
            lowHp = -1
        end
    end
end

function module:CheckOwlsHP()
    
    -- check if guid are nil, ie if raid leader has turned off hp bars, then make them disappear
    if redowlone_guid == nil or redowltwo_guid == nil or blueowlone_guid == nil or blueowltwo_guid == nil then
        self:EndOwls()
    else
        
        local redowloneHP = nil
        local redowltwoHP = nil
        local blueowloneHP = nil
        local blueowltwoHP = nil
        
        for i = 1, GetNumRaidMembers() do
            if UnitName("Raid" .. i .. "Target") == L["redowl"] then
                local redhp = math.ceil((UnitHealth("Raid" .. i .. "Target") / UnitHealthMax("Raid" .. i .. "Target")) * 100)
                local _, potential_guid = UnitExists("Raid" .. i .. "Target")
                if redowlone_guid and potential_guid == redowlone_guid then
                    redowloneHP = redhp
                    self:UpdateOwlHP(redowlone_guid, redowlonehp)
                elseif redowltwo_guid and potential_guid == redowltwo_guid then
                    redowltwoHP = redhp
                    self:UpdateOwlHP(redowltwo_guid, redowltwoHP)
                end
            elseif UnitName("Raid" .. i .. "Target") == L["blueowl"] then
                local bluehp = math.ceil((UnitHealth("Raid" .. i .. "Target") / UnitHealthMax("Raid" .. i .. "Target")) * 100)
                local _, potential_guid = UnitExists("Raid" .. i .. "Target")
                if blueowlone_guid and potential_guid == blueowlone_guid then
                    blueowloneHP = bluehp
                    self:UpdateOwlHP(blueowlone_guid, blueowloneHP)
                elseif blueowltwo_guid and potential_guid == blueowltwo_guid then
                    blueowltwoHP = bluehp
                    self:UpdateOwlHP(blueowltwo_guid, blueowltwoHP)
                end
            end
            if redowlone_guid and redowltwo_guid and blueowlone_guid and blueowltwo_guid and redowloneHP and redowltwoHP and blueowloneHP and blueowltwoHP then
                self:Sync(syncName.redowlone.." "..redowlone_guid.." "..redowlonehp)
                self:Sync(syncName.redowltwo.." "..redowltwo_guid.." "..redowltwohp)
                self:Sync(syncName.blueowlone.." "..blueowlone_guid.." "..blueowlonehp)
                self:Sync(syncName.blueowltwo.." "..blueowltwo_guid.." "..blueowltwohp)
                break
            end
        end
    end
    
end

function module:Event(msg)
    if msg == L["trigger_engage"] then
        module:SendEngageSync()
        
    elseif string.find(msg, L["trigger_lunarShiftCast"]) then
        self:Sync(syncName.lunarshift)
    
    elseif string.find(msg, L["trigger_owls"]) then
        self:Sync(syncName.owls)
    elseif string.find(msg, L["trigger_end_owls"]) then
        self:EndOwls()
    elseif msg == L["trigger_gaze"] and self.db.profile.gaze then
        self:Gaze()
        
    elseif string.find(msg, L["trigger_gazeOther"]) and self.db.profile.gaze then
        local _,_, markedPlayer = string.find(msg, L["trigger_gazeOther"])
        self:GazeOther(markedPlayer)
    
    elseif msg == L["trigger_colorblue"] and self.db.profile.color then
        self:NewColor("Blue")
    
    elseif msg == L["trigger_colorred"] and self.db.profile.color then
        self:NewColor("Red")
    end
end


function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.lunarshift and self.db.profile.lunarshift then
        self:LunarShift()
    elseif sync == syncName.ravens and self.db.profile.ravens then
        self:RavensSpawn()
    elseif sync == syncName.owls and self.db.profile.owls then
        self:Owls()
    elseif sync == syncName.lowHp then
        self:LowHp()
    elseif sync == syncName.redowlone and rest then
        local rest_id, rest_hp = string.match(tostring(rest), "(%S+)%s(%S+)")
        redowlone_guid = rest_id
        self:UpdateOwlHP(rest_id, tonumber(rest_hp))
    elseif sync == syncName.redowltwo and rest then
        local rest_id, rest_hp = string.match(tostring(rest), "(%S+)%s(%S+)")
        redowltwo_guid = rest_id
        self:UpdateOwlHP(rest_id, tonumber(rest_hp))
    elseif sync == syncName.blueowlone and rest then
        local rest_id, rest_hp = string.match(tostring(rest), "(%S+)%s(%S+)")
        blueowlone_guid = rest_id
        self:UpdateOwlHP(rest_id, tonumber(rest_hp))
    elseif sync == syncName.blueowltwo and rest then
        local rest_id, rest_hp = string.match(tostring(rest), "(%S+)%s(%S+)")
        blueowltwo_guid = rest_id
        self:UpdateOwlHP(rest_id, tonumber(rest_hp))
    end
end

function module:LowHp()
    if healthPct < 36 and lowHp == 1 then
        self:Message(L["msg_owlTwo"], "Important", true, "Alarm")
        lowHp = 2
    elseif lowHp == 0 then
        self:Message(L["msg_owlOne"], "Important", true, "Alarm")
        lowHp = 1
    end    
end

function module:NewColor(newColor)
    if previousColor and previousColor ~= newColor then
        if newColor == "Blue" then
            self:Message(L["msg_blue"], "Important", true, "Alarm")
        elseif newColor == "Red" then
            self:Message(L["msg_red"], "Important", true, "Alarm")
        end
        self:Sound("Beware")
        previousColor = newColor
    end
end

function module:RavensSpawn()
    self:Message(L["msg_ravens"], "Important", true, "Alarm")
    self:WarningSign(icon.ravens, 5)
end

function module:LunarShift()
    --PlaySoundFile(L["soundlunar"])
    self:Sound("Beware")
    self:Bar( L["bar_lunarShiftCast"], timer.lunarshift_cast, icon.lunarshift, true, color.lunarshift_cast)
    self:Bar(L["bar_lunarShiftCd"], timer.lunarshift, icon.lunarshift, true, color.lunarshift)
    lunarShiftCounter = lunarShiftCounter + 1
    if mod(lunarShiftCounter, 4) == 1 then
        self:Bar(L["bar_ravens"], 21, icon.ravens, true, color.ravens)
        self:DelayedBar(21, L["bar_ravensSoon"], 4, icon.ravens, true, color.ravens)
    elseif mod(lunarShiftCounter, 4) == 2 then
        self:DelayedBar(5, L["bar_ravens"], 21, icon.ravens, true, color.ravens)
        self:DelayedBar(26, L["bar_ravensSoon"], 4, icon.ravens, true, color.ravens)
    elseif mod(lunarShiftCounter, 4) == 3 then
        self:DelayedBar(15, L["bar_ravens"], 21, icon.ravens, true, color.ravens)
        self:DelayedBar(36, L["bar_ravensSoon"], 4, icon.ravens, true, color.ravens)
    end
end

function module:Owls()
    self:Bar(L["bar_owls"], timer.owls_enrage, icon.owls, true, color.owls_enragesoon)
    --self:DelayedBar(timer.owls_enrage - timer.owls_enragesoon, L["bar_owlsenrage"], timer.owls_enragesoon, icon.owls_enragesoon, true, color.owls_enragesoon)
    self:Message(L["msg_owls"], "Urgent", true, "Alarm")
    self:DelayedMessage(timer.owls_enrage - timer.owls_enragesoon, L["bar_owlsenrage"], "Urgent", nil, nil, true)
    redowlone_guid = nil
    redowltwo_guid = nil
    blueowlone_guid = nil
    blueowltwo_guid = nil
    if self.db.profile.owlsHp then
        self:ScheduleEvent("SetupOwlsBarsEvent", function() self:SetupOwlsBars() end, 5)
    end
    self:ScheduleEvent("bWDelayedEndOwls", function() self:EndOwls() end, timer.owls_enrage)
end

function module:EndOwls()
    self:CancelScheduledEvent("bWCheckOwlsHP")
    self:CancelScheduledEvent("bWDelayedCheckOwlsHP")
    self:TriggerEvent("BigWigs_StopHPBar", self, "Cross Red Owl")
    self:TriggerEvent("BigWigs_StopHPBar", self, "Circle Red Owl")
    self:TriggerEvent("BigWigs_StopHPBar", self, "Square Blue Owl")
    self:TriggerEvent("BigWigs_StopHPBar", self, "Triangle Blue Owl")
    redowlone_guid = nil 
    redowltwo_guid = nil
    blueowlone_guid = nil
    blueowltwo_guid = nil
end

function module:Gaze()
    self:Message(L["msg_gazeYou"], "Urgent", true, "Alarm")
end

function module:GazeOther(rest)
    self:Message(rest..L["msg_gaze"], "Attention")

    -- self:Bar(rest..L["bar_gaze"].. " >Click Me<", timer.mark, icon.mark, true, color.mark)
    --self:SetCandyBarOnClick("BigWigsBar "..rest..L["bar_gaze"].. " >Click Me<", function(name, button, extra) TargetByName(extra, true) end, rest)

    --if (IsRaidLeader() or IsRaidOfficer()) then
    --    for i=1,GetNumRaidMembers() do
    --        if UnitName("raid"..i) == rest then
    --            SetRaidTarget("raid"..i, 2)
    --        end
    --    end
    --end
end

function module:SetupOwlsBars()
    self:TriggerEvent("BigWigs_StartHPBar", self, "Cross Red Owl", 100, "Interface\\Icons\\" .. icon.hpBarCross, true, color.hpBar)
    self:TriggerEvent("BigWigs_SetHPBar", self, "Cross Red Owl", 0)
    self:TriggerEvent("BigWigs_StartHPBar", self, "Circle Red Owl", 100, "Interface\\Icons\\" .. icon.hpBarCircle, true, color.hpBar)
    self:TriggerEvent("BigWigs_SetHPBar", self, "Circle Red Owl", 0)
    self:TriggerEvent("BigWigs_StartHPBar", self, "Square Blue Owl", 100, "Interface\\Icons\\" .. icon.hpBarSquare, true, color.hpBar)
    self:TriggerEvent("BigWigs_SetHPBar", self, "Square Blue Owl", 0)
    self:TriggerEvent("BigWigs_StartHPBar", self, "Triangle Blue Owl", 100, "Interface\\Icons\\" .. icon.hpBarTriangle, true, color.hpBar)
    self:TriggerEvent("BigWigs_SetHPBar", self, "Triangle Blue Owl", 0)
    
	local redowloneHP = nil
	local redowltwoHP = nil
	local blueowloneHP = nil
	local blueowltwoHP = nil
    
    if SUPERWOW_VERSION and (IsRaidLeader() ) then -- RL sacrificed for the greater good, sorry bro
        for i = 1, GetNumRaidMembers() do
            if UnitName("Raid" .. i .. "Target") == L["redowl"] then
                local redhp = math.ceil((UnitHealth("Raid" .. i .. "Target") / UnitHealthMax("Raid" .. i .. "Target")) * 100)
                local _, potential_guid = UnitExists("Raid" .. i .. "Target")
                if redowlone_guid == nil and redowltwo_guid == nil and potential_guid ~= nil then
                    redowlone_guid = potential_guid
                    SetRaidTarget("Raid" .. i .. "Target", 7); -- cross
                    redowloneHP = redhp
                elseif redowlone_guid ~= nil and redowltwo_guid == nil and potential_guid ~= nil then
                    redowltwo_guid = potential_guid
                    SetRaidTarget("Raid" .. i .. "Target", 2); -- circle
                    redowltwoHP = redhp
                end
            elseif UnitName("Raid" .. i .. "Target") == L["blueowl"] then
                local bluehp = math.ceil((UnitHealth("Raid" .. i .. "Target") / UnitHealthMax("Raid" .. i .. "Target")) * 100)
                local _, potential_guid = UnitExists("Raid" .. i .. "Target")
                if blueowlone_guid == nil and blueowltwo_guid == nil and potential_guid ~= nil then
                    blueowlone_guid = potential_guid
                    SetRaidTarget("Raid" .. i .. "Target", 6); -- square
                    blueowloneHP = bluehp
                elseif blueowlone_guid ~= nil and blueowltwo_guid == nil and potential_guid ~= nil then
                    blueowltwo_guid = potential_guid
                    SetRaidTarget("Raid" .. i .. "Target", 4); -- triangle
                    blueowltwoHP = bluehp
                end
            end
            if redowlone_guid and redowltwo_guid and blueowlone_guid and blueowltwo_guid and redowloneHP and redowltwoHP and blueowloneHP and blueowltwoHP then
                self:Sync(syncName.redowlone.." "..redowlone_guid.." "..redowlonehp)
                self:Sync(syncName.redowltwo.." "..redowltwo_guid.." "..redowltwohp)
                self:Sync(syncName.blueowlone.." "..blueowlone_guid.." "..blueowlonehp)
                self:Sync(syncName.blueowltwo.." "..blueowltwo_guid.." "..blueowltwohp)
                break
            end
        end
        self:ScheduleRepeatingEvent("bWCheckOwlsHP", self.CheckOwlsHP, 1, self)
    elseif SUPERWOW_VERSION then
        self:ScheduleEvent("bWDelayedCheckOwlsHP", function() self:ScheduleRepeatingEvent("bWCheckOwlsHP", self.CheckOwlsHP, 1, self) end, 3)
    end
    
    
end

function module:UpdateOwlHP(owlguid, hp_pct)
    if self.db.profile.owlsHp then
        if owlguid == redowlone_guid then 
            self:TriggerEvent("BigWigs_SetHPBar", self, "Cross Red Owl", 100 - hp_pct)
        elseif owlguid == redowltwo_guid then 
            self:TriggerEvent("BigWigs_SetHPBar", self, "Circle Red Owl", 100 - hp_pct)
        elseif owlguid == blueowlone_guid then 
            self:TriggerEvent("BigWigs_SetHPBar", self, "Square Blue Owl", 100 - hp_pct)
        elseif owlguid == blueowltwo_guid then 
            self:TriggerEvent("BigWigs_SetHPBar", self, "Triangle Blue Owl", 100 - hp_pct)
        end
    end
end