
local module, L = BigWigs:ModuleDeclaration("Keeper Gnarlmoon", "Karazhan")

module.revision = 30020
module.enabletrigger = module.translatedName
module.toggleoptions = {"lunarshift", "owls", "ravens", "color", "gaze"}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

module.defaultDB = {
 lunarshift = true,
 owls = true,
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
        
        trigger_lunarShiftAfflic = "Keeper Gnarlmoon begins to cast Lunar Shift.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
        bar_lunarShiftCd = "Next Lunar Shift",
        
        msg_owlOne = "Gnarlmoon under 68% - Owl Phase Soon (@ 66.6%)!",
        msg_owlTwo = "Gnarlmoon under 35% - Owl Phase Soon (@ 33.3%)!",
        
        trigger_owls = "Keeper Gnarlmoon gains Worgen Dimension", --CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
        msg_owls = "Gnarlmoon is Immune! Kill the Owls at the same time!",
        bar_owls = "Owls enrage in..",
        bar_owlsenrage = "Enrage soon, kill the owls!!",
        
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
}
local syncName = {
	lunarshift = "LunarShift"..module.revision,
	owls = "Owls"..module.revision,
	gaze = "Gaze"..module.revision,
	gazeother = "GazeOther"..module.revision,
	lowHp = "KeeperGnarlmoon"..module.revision,
}

lowHp = 0
healthPct = 100
lunarShiftCounter = 0
previousColor = ""


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
	
	self:ThrottleSync(5, syncName.lunarshift)
	self:ThrottleSync(5, syncName.owls)
	self:ThrottleSync(5, syncName.gaze)
	self:ThrottleSync(5, syncName.gazeother)
	self:ThrottleSync(3, syncName.lowHp)
end

function module:OnSetup()
	self.started = nil
    lunarShiftCounter = 0
end

function module:OnEngage()
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


function module:UNIT_HEALTH(msg)
	if UnitName(msg) == "Keeper Gnarlmoon" then
		healthPct = UnitHealth(msg) * 100 / UnitHealthMax(msg)
		if healthPct >= 69 and lowHp ~= 0 then
			lowHp = 0
		elseif healthPct < 69 and healthPct > 65 and lowHp == 0 then
			self:Sync(syncName.lowHp)
		elseif healthPct < 36 and lowHp == 1 then
			self:Sync(syncName.lowHp)
        elseif healthPct <= 33 and lowHp == 2 then
			lowHp = -1
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
	elseif sync == syncName.owls and self.db.profile.owls then
		self:Owls()
	elseif sync == syncName.lowHp then
		self:LowHp()
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
        previousColor = newColor
    end
end

function module:LunarShift()
	self:Bar( L["bar_lunarShiftCast"], timer.lunarshift_cast, icon.lunarshift, true, color.lunarshift_cast)
    self:Bar(L["bar_lunarShiftCd"], timer.lunarshift, icon.lunarshift, true, color.lunarshift)
    lunarShiftCounter = lunarShiftCounter + 1
    if mod(lunarShiftCounter, 4) == 1 then
        self:Bar(L["bar_ravens"], 25, icon.ravens, true, color.ravens)
    elseif mod(lunarShiftCounter, 4) == 2 then
        self:DelayedBar(5, L["bar_ravens"], 25, icon.ravens, true, color.ravens)
    elseif mod(lunarShiftCounter, 4) == 3 then
        self:DelayedBar(15, L["bar_ravens"], 25, icon.ravens, true, color.ravens)
    end
end

function module:Owls()
    self:Bar(L["bar_owls"], timer.owls_enrage, icon.owls, true, color.owls_enragesoon)
    --self:DelayedBar(timer.owls_enrage - timer.owls_enragesoon, L["bar_owlsenrage"], timer.owls_enragesoon, icon.owls_enragesoon, true, color.owls_enragesoon)
	self:Message(L["msg_owls"], "Urgent", true, "Alarm")
	self:DelayedMessage(timer.owls_enrage - timer.owls_enragesoonw, L["bar_owlsenrage"], "Urgent", nil, nil, true)
end


function module:Gaze()
	self:Message(L["msg_gazeYou"], "Urgent", true, "Alarm")
end

function module:GazeOther(rest)
	self:Message(rest..L["msg_gaze"], "Attention")

	-- self:Bar(rest..L["bar_gaze"].. " >Click Me<", timer.mark, icon.mark, true, color.mark)
	--self:SetCandyBarOnClick("BigWigsBar "..rest..L["bar_gaze"].. " >Click Me<", function(name, button, extra) TargetByName(extra, true) end, rest)

	--if (IsRaidLeader() or IsRaidOfficer()) then
	--	for i=1,GetNumRaidMembers() do
	--		if UnitName("raid"..i) == rest then
	--			SetRaidTarget("raid"..i, 2)
	--		end
	--	end
	--end
end