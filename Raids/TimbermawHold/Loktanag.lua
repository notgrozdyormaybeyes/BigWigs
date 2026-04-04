-- nothing here this boss does nothing, just dispell decurse depoison ???
local module, L = BigWigs:ModuleDeclaration("Loktanag the Vile", "Timbermaw Hold")


module.revision = 30020
module.enabletrigger = "Loktanag the Vile"
module.toggleoptions = {"bosskill"}
module.zonename = "TimbermawHold"

module.defaultDB = {
}
L:RegisterTranslations("enUS", function() return {
    cmd = "Loktanag",
    
    stupid_text = "Tank him out of poisons, kill adds away from players and win",
    
    
} end )


function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "Event") 
    
end

function module:OnSetup()
end

function module:OnEngage()
    if (IsRaidLeader()) then
        SendChatMessage(L["stupid_text"],"RAID_WARNING")
    end
end

function module:Event(msg)
end

-- tests
SLASH_LOKTANAGTEST1 = "/loktanagtest"
SlashCmdList["LOKTANAGTEST"] = function(msg)
    module:Test(msg)
end
function module:Test(msg)
    self:OnEngage()
end

