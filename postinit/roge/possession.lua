-- roge/possession.lua
-- Possession 2 附身系统（整合自 Workshop 3676492192，适配黎明杀饥 roge 规则）
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local G = GLOBAL
local GA = G.ACTIONS
local F = G.FRAMES

-- roge 附身配置（原 mod 的 modinfo 选项在此写死；天数/黑名单限制由 ghost.lua 负责）
local ROGE_POSS_CONFIG = {
	Duration = 20,
	Permanent = true,
	Revival = false,
	Players = 0,
	Boats = 0,
	Pets = 0,
	Critters = 0,
	["Friendly NPCs"] = 0,
	Summonables = 0,
	["Neutral NPCs"] = 2,
	["Hostile NPCs"] = 2,
	["Shadow Creatures"] = 2,
	["Mini-Bosses"] = 2,
	Bosses = 2,
	["Shadow Bosses"] = 2,
	["Super Bosses"] = 2,
	["Everything except Players & Boats"] = 0,
	AllowUnlistedByTag = true,
	AllowCombatTag = true,
	AllowMonsterTag = true,
	AllowAnimalTag = true,
	AllowHostileTag = true,
	PrintDebug = false,
}

local function D(key)
	return ROGE_POSS_CONFIG[key]
end

local LOCALE = LOC.GetLocaleCode()
local isCN = (LOCALE == "zh" or LOCALE == "zht" or LOCALE == "zhr")
local function T(zh, en) return isCN and zh or en end

local function IsAdmin(p)
	if p and p.userid and p.userid ~= "" then
		local t = G.TheNet:GetClientTableForUser(p.userid)
		return t.admin
	end
end

local function PrintDebug(msg)
	if D("PrintDebug") then G.print("[Possession 2 Debug] - "..msg) end
end

-- Shared logging system to be created later
local function SharedLogs(msg)
end

--[[
	To Do:


		Fix Glitches:
			�?Click-To-Move does not work while possessing players if Lag Compensation is off.
				The cause of this is still unknown.

			�?Client hosts are unable to view stats.
			�?Sanity display causes sanity meter to randomly convert to lunacy
			�?Stale component references for temporary stat displays

		Add:
			�?"Crafting & Inventory" Control
				Roadblocks:
					�?In-inventory items cannot be previewed by outside parties, for some reason.
					�?Still haven't figured out how to allow several players to share the same inventory.

			�?"Action" Control (chop, mine, dig, attack, harvest, pick, etc.)
				Roadblocks:
					�?Actions performed by those who are possessing someone are not sent through the person they are possessing.
						The cause of this is still unknown, as action control has a ton of factors involved.

			�?Server-Client "shared" logs
				This is a low-priority feature, I'll consider adding it when the bigger features are taken care of.
]]

-- For easily making sure if someone is still ingame
local function Valid(Ent) return Ent and Ent.IsValid and Ent:IsValid() end

local function IsActivelyPossessing(doer)
	return Valid(doer)
		and doer.Poss2 ~= nil
		and doer.poss2_possessing
		and Valid(doer.Poss2.Possessing)
		and not doer.Poss2.Possessing:HasTag("boat")
end

-- 服务端附身攻击：Poss2.Possessing 在 PlayerStartPossessing 里设置。
local function IsPossessionCombatActive(doer)
	return Valid(doer)
		and doer.Poss2 ~= nil
		and Valid(doer.Poss2.Possessing)
		and not doer.Poss2.Possessing:HasTag("boat")
end

-- 客户端附身攻击：Poss2.Possessing 不会自动同步到客户端，只能用 poss2_possessing。
local function IsClientPossessingCombat(player)
	return Valid(player) and player.poss2_possessing == true
end

local function SyncPossessingTargetNet(Possessor, Possessed)
	if Possessor.net_poss2_target == nil then
		return
	end
	Possessor.net_poss2_target:set(Possessed)
	Possessor.net_poss2_target:set_local(Possessed)
end

-- Action override: only while actively possessing (prevents post-release empty attacks on humans)
for _,Action in pairs(GA) do
	PrintDebug("Action Override: \"".._.."\"!")
	local OLDFN = Action.fn
	Action.fn = function(act, ...)
		if IsActivelyPossessing(act.doer) then
			PrintDebug(act.doer.name.." forced "..act.doer.Poss2.Possessing.name.." to perform action \"".._.."\"!")
			act.doer = act.doer.Poss2.Possessing
		end
		return OLDFN(act, ...)
	end
end

-- 加载特殊攻击配置文件
modimport("scripts/creature_attacks_config.lua")
local SpecialAttacks = G.SPECIAL_ATTACKS_CONFIG or {}

-- 无法主动攻击的生物黑名单（碰撞伤害、被动伤害等）
local NoActiveAttack = {
	["shadowthrall_centipede_controller"] = true,
	["shadowthrall_centipede_body"] = true,
	["butterfly"] = true,
	["moonbutterfly"] = true,
	["rabbit"] = true,
	["mole"] = true,
	["bird_mutant"] = true,
	["bird_mutant_spitter"] = true,
	["canary"] = true,
	["canary_poisoned"] = true,
	["crow"] = true,
	["robin"] = true,
	["robin_winter"] = true,
	["puffin"] = true,
	["pigeon"] = true,
	["carrat"] = true,
	["mandrake_active"] = true,
	["grassgekko"] = true,
	["wobster_sheller"] = true,
	["wobster_sheller_land"] = true,
}

-- 近战伤害为 0 但仍需允许附身攻击的武器（魔杖特效走 doattack + 武器 onattack）
local ZERO_DAMAGE_POSSESS_WEAPONS = {
	icestaff = true,
	icestaff2 = true,
	icestaff3 = true,
	firestaff = true,
}

local function RogePossessedCanUsePossessAttack(possessed)
	local combat = possessed.components.combat
	if combat == nil then
		return false
	end
	if (combat.defaultdamage or 0) > 0 then
		return true
	end
	local inv = possessed.components.inventory
	if inv == nil then
		return false
	end
	local weapon = inv:GetEquippedItem(EQUIPSLOTS.HANDS)
	return weapon ~= nil and ZERO_DAMAGE_POSSESS_WEAPONS[weapon.prefab] == true
end

-- Hook PlayerController 的 OnRemoteControllerAttackButton
AddComponentPostInit("playercontroller", function(self)
	local OldOnRemoteControllerAttackButton = self.OnRemoteControllerAttackButton
	self.OnRemoteControllerAttackButton = function(self, target, isreleased, noforce)
		if IsPossessionCombatActive(self.inst) and target and target:IsValid() then
			local possessed = self.inst.Poss2.Possessing

			if possessed.components.combat then
				if NoActiveAttack[possessed.prefab] then
					return
				end

				if not RogePossessedCanUsePossessAttack(possessed) then
					return
				end

				local current_time = G.GetTime()
				if possessed.Poss2.LastAttackTime and (current_time - possessed.Poss2.LastAttackTime) < 0.5 then
					return
				end

				possessed.Poss2.LastAttackTime = current_time
				possessed.components.combat:SetTarget(target)

				if target.Transform and possessed.Transform then
					local tx, ty, tz = target.Transform:GetWorldPosition()
					if tx then
						possessed:ForceFacePoint(tx, ty, tz)
					end
				end

				if possessed.brain then
					possessed.brain:Start()
				end

				local config = SpecialAttacks[possessed.prefab]

				possessed:DoTaskInTime(0, function()
					if possessed and possessed:IsValid() and target and target:IsValid() then
						if config then
							if config.event then
								possessed:PushEvent(config.event, {target = target})
							elseif config.state and possessed.sg and possessed.sg:HasState(config.state) then
								if not possessed.sg:HasStateTag("busy") and not possessed.sg:HasStateTag("attack") then
									possessed.sg:GoToState(config.state, target)
								end
							end
						else
							if possessed.sg and possessed.sg:HasState("attack") and not possessed.sg:HasStateTag("busy") and not possessed.sg:HasStateTag("attack") then
								possessed.sg:GoToState("attack", target)
							elseif possessed.components.combat:CanAttack(target) then
								possessed.components.combat:DoAttack(target)
							end
						end
					end
				end)

				local stop_delay = 1
				if possessed.prefab == "mutatedbearger" then
					stop_delay = 0.5
				end

				possessed:DoTaskInTime(stop_delay, function()
					if possessed and possessed:IsValid() and possessed.brain then
						possessed.brain:Stop()
						if possessed.prefab == "mutatedbearger" and possessed.components.combat then
							possessed.components.combat:SetTarget(nil)
						end
					end
				end)

				return
			end
		end

		OldOnRemoteControllerAttackButton(self, target, isreleased, noforce)
	end
end)



-- 添加攻击按钮处理
local OldAttackButton = G.TheInput and G.TheInput.OnControl or nil

local OldHaunt = GA.HAUNT.fn
GA.HAUNT.fn = function(act,...)

	if act.doer and act.target then
		if (act.target.Poss2 and act.target.Poss2.Possessing)
		or (act.doer.Poss2 and act.doer.Poss2.Possessing)
		or act.doer == act.target then
			act.doer:PushEvent("attacked",{}) -- prevent haunting animation softlock
			return
		end
	end

	return OldHaunt(act,...)
end

-- Set duration as either the selected duration (or as 68 years if Permanent is enabled)
local Dur = D("Duration")
if D("Permanent") == true then Dur = 2147000000 end

-- Boring network stuff
local function SetVal(val,newval)
	val:set_local(newval)
	val:set(newval)
end

-- For use in the MakePossessable function
local function MakeHauntable(Thing, Start)
	if not Thing then
		return
	end

	if not Thing.components.hauntable then
		Thing:AddComponent("hauntable")
	end

	Thing.components.hauntable.cooldown = 0
	Thing.components.hauntable.usefx = false
	Thing.components.hauntable.onhaunt = function(inst, haunter)
		if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(inst) then
			return false
		end
		return Start(inst, haunter)
	end
end

-- Blank function which acts as a replacement when none are available
local NoFN = function() return end

-- This table is the main way the game knows who to run possession code on.
local Poss2 = {}
Poss2.Possessed = {}

-- Some old code from Player Possession. hopefully it'll fix the lag compensation issue.
local function FixLagComp(Possessed)
	if Possessed.Poss2.Level > 0 then
		local SpdMlt = Possessed.components.locomotor:GetSpeedMultiplier()
		local SX,SY,SZ = Possessed.Transform:GetScale() -- Scale changes speed, so account for that too.
		for _,Possessor in pairs(Possessed.Poss2.Possessors) do
			Possessor.Transform:SetScale(SpdMlt*SX,0.571,SpdMlt*SZ)
		end
	end
end


-- Oh dear, this code is so messy!
-- I really should have planned this better...
local RevivalItems = {
	["reviver"] = true,
	["amulet"] = true,
}

-- Finds the owner of an item, regardless of if it's in a sub-container or not.
local function FindOwner(Container)
	if not Container then return end

	local SubC = nil
	if Container.components.inventoryitem then
		SubC = Container.components.inventoryitem.owner
	end
	
	if Container:HasTag("player") then
		return Container
	elseif SubC and SubC:HasTag("player") then
		return SubC
	end
	return
end

-- Pick a random table item, as if that wasn't obvious enough.
local function PickRandomFromTable(Tabl)
	local NumberTable = {}
	for K,V in pairs(Tabl) do
		NumberTable[#NumberTable+1] = V
	end
	return NumberTable[math.floor(math.random(1,#NumberTable)+0.5)]
end

-- If an item is put into an inventory (or an inventory carried by someone), trace the owner & revive their possessor if they have one.
local function RevFunc(Item)
	Item:ListenForEvent("onputininventory",function(Self,Container)
		Item:DoTaskInTime(0,function(Self)
			local Owner = FindOwner(Container)
			if not Owner then return end
			if Owner.Poss2.Level > 0 then
				local Rand = PickRandomFromTable(Owner.Poss2.Possessors)
				if Rand:HasTag("playerghost") then Rand:PushEvent("respawnfromghost",{source = Owner}) else Rand.Poss2.EndFN(Owner,Rand) end
				Item:Remove()
			end
		end)
	end)
end

-- Search every slot of someone's inventory for a revival item
-- Some mods can interfere with this (such as ones adding extra equip slots).
local function DeepSearchInventoryForRevivers(Possessed,Possessor)
	local Inv = Possessed.components.inventory
	local Revived = false

	local function CheckItem(Item)
		if Item and RevivalItems[Item.prefab] and not Revived then
			Possessor:PushEvent("respawnfromghost",{source = Possessed})
			Item:Remove()
			return true
		end
	end

	local function DeepSearch(slots)
		for K,V in pairs(slots) do
			if V.components.container ~= nil then
				for _,Item in pairs(V.components.container.slots) do
					if not Revived then Revived = CheckItem(Item) end
				end
			else
				if not Revived then Revived = CheckItem(V) end
			end
		end
	end

	DeepSearch(Inv.itemslots)
	DeepSearch(Inv.equipslots)
	if not Revived then Revived = CheckItem(Inv.activeitem) end

	return Revived
end

-- Add "Possession Defense" property to certain revival items.
for RevivalItem,_ in pairs(RevivalItems) do AddPrefabPostInit(RevivalItem,RevFunc) end

-- Before changing a possessor's vision to their victim's, save it for later.
local function SaveVision(Possessor)
	Possessor.Poss2.Vision.isghostmode = Possessor.player_classified.isghostmode:value()
end

-- Update possessor vision to match their victim's
local function ChangeVision(Possessed,Possessor)
	local t = (Possessed.player_classified or {isghostmode = {value = NoFN}})
	local Val = t.isghostmode:value() or Possessed:HasTag("ghost")
	Possessor.player_classified.isghostmode:set(t.isghostmode:value() or false)
	Possessor.components.playervision:SetGhostVision(Val)
end

-- Reset vision back to the one saved in SaveVision function.
local function ResetVision(Possessor)
	local Val = Possessor.Poss2.Vision.isghostmode
	Possessor.player_classified.isghostmode:set(Val)
	Possessor.components.playervision:SetGhostVision(Val)
end

-- states we're not supposed to break out of
local BadStates = {
	["death"] = true,
	["corpse"] = true,
	["frozen"] = true,
	["thaw"] = true,
	["hit"] = true,
	["knockout"] = true,
}

local function CanChangeSG(Thing)
	return not BadStates[Thing.sg.currentstate.name]
end

local function RogePossessedInPreAttackCombat(Possessed)
	if Possessed.sg == nil then
		return false
	end
	if Possessed.sg:HasStateTag("taunt") or Possessed.sg:HasStateTag("attack") then
		return true
	end
	local state = Possessed.sg.currentstate ~= nil and Possessed.sg.currentstate.name
	return state == "nm_pre_attack_taunt" or state == "roge_pre_attack_taunt"
end

-- This is really messy. clean it up later
local function doPossessionFx(Possessed,Possessor)
	if not Valid(Possessed) or not Valid(Possessor) then return end

	-- This prevents possessors from being softlocked when unpossessing.
	if Possessor.sg.currentstate.name ~= "death" and Possessor.sg:HasState("hit") then
		Possessor.sg:GoToState("hit")
	end

	-- The classic possession sound that everybody knows & loves (or hates)!
	Possessor.SoundEmitter:PlaySound("dontstarve/creatures/together/stalker/death_pop")

	if Possessed.sg == nil then return end
	-- To add a little more impact. because who wouldn't be startled if someone took over their body? owo
	if CanChangeSG(Possessed) then
		if Possessed:HasTag("player") then
			if Possessed:HasTag("playerghost") and Possessed.sg:HasState("hit") then
				Possessed.sg:GoToState("hit")
			elseif Possessed.sg:HasState("startle") then
				Possessed.sg:GoToState("startle")
			end
		elseif Possessed.sg:HasState("hit") and not RogePossessedInPreAttackCombat(Possessed) then
			Possessed.sg:GoToState("hit")
		end
	end

end

-- Every component in this list will be taken control of by the possessor.
-- Some components work better than others when doing this type of override.
local ComponentsToGrab = {
	"wisecracker",
	"talker",
}

-- Override components listed in ComponentsToGrab.
-- Save the original components for later so they aren't lost.

local function sendComponentsTo(Possessed,Possessor)
	for K,V in pairs(ComponentsToGrab) do
		if Possessed.components[V] then
			Possessor.Poss2.Components[V] = Possessor.components[V]
			Possessor.components[V] = Possessed.components[V]
		end
	end
end

-- Remember those components we saved earlier? We're going to send those back to the possessor.

local function resetComponentsToNormal(Person)
	for K,V in pairs(ComponentsToGrab) do
		if Person.Poss2.Components[V] then
			Person.components[V] = Person.Poss2.Components[V]
			Person.Poss2.Components[V] = nil
		end
	end
end

-- Prevent stat display from exceeding the unsigned 16 bit integer limit
-- Necessary to prevent the Misery Toadstool crash
local function NetMax(N) return math.min(N,65535) end

-- These "stat update" functions send information about the possessed person directly to the HUDs of the person(s) possessing them.
local function UpdateHunger(Person)
	local c = Person.components.hunger
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local r = Possessor.replica.hunger
		if r then r:SetCurrent(NetMax(c.current)) r:SetMax(NetMax(c.max)) end
	end
end

--[[

-- Disabled sanity functions due to lunacy glitch
local function UpdateSanity(Person)
	local c = Person.components.sanity
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local r = Possessor.replica.sanity
		if r then r:SetCurrent(NetMax(c.current)) r:SetMax(NetMax(c.max)) r:SetPenalty(c.penalty) end
	end
end

local function SanityGoSaneOrInsane(Person)
	local c = Person.components.sanity
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local r = Possessor.replica.sanity
		if r then r:SetIsSane(c.sane) end
	end
end
]]

local function UpdateHealth(Person)
	local c = Person.components.health
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local r = Possessor.replica.health
		if r then r:SetCurrent(NetMax(c.currenthealth)) r:SetPenalty(c.penalty) r:SetMax(NetMax(c.maxhealth)) end
	end
end

local function UpdateFireDamage(Person)
	local c = Person.components.health
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local r = Possessor.replica.health
		if r then r:SetIsTakingFireDamage(c.takingfiredamage) end
	end
end





local function UpdateMoisture(Person)
	local c = Person.components.moisture
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local pc = Possessor.player_classified
		if pc then pc.moisture:set(NetMax(c.moisture)) pc.maxmoisture:set(NetMax(c.maxmoisture)) end
	end
end

local function UpdateTemperature(Person)
	local c = Person.components.temperature
	if not c then return end
	for _,Possessor in pairs(Person.Poss2.Possessors) do
		local pc = Possessor.player_classified
		if pc then pc:SetTemperature(c.current) end
	end
end

local function UpdateAllStats(Person)
	--SanityGoSaneOrInsane(Person)
	UpdateFireDamage(Person)
	UpdateTemperature(Person)
	UpdateMoisture(Person)
	UpdateHunger(Person)
	--UpdateSanity(Person)
	UpdateHealth(Person)
end

--[[
	
-- I'm actually a little proud of this one. :) - It's a shame it was too glitchy to use.

local function UpdatePetHealthbar(Pet)
	local c,l = Pet.components.health,(Pet.components.follower or {}).leader
	if not c or not l then return end
	for _,Possessor in pairs(l.Poss2.Possessors) do
		local phb = Possessor.components.pethealthbar
		if phb then phb._maxhealth:set(c.maxhealth) phb._healthpct:set(c:GetPercent()) end
	end
end

]]


-- reading this code is like having a very delightful aneurysm
-- (reset the person's visual stats to normal)
local function ResetStats(Person)

	-- shorthand variables
	local c,r,pc = Person.components,Person.replica,Person.player_classified

	-- replica & component shorthand
	local rhu,rsa,rhe,chu,csa,che,cm,ct,phb = r.hunger,r.sanity,r.health,c.hunger,c.sanity,c.health,c.moisture,c.temperature

	-- hunger, sanity, & health
	if rhu and chu then rhu:SetCurrent(chu.current) rhu:SetMax(chu.max) end
	--if rsa and csa then rsa:SetCurrent(csa.current) rsa:SetMax(csa.max) rsa:SetPenalty(csa.penalty) rsa:SetIsSane(csa.sane) end
	if rhe and che then rhe:SetCurrent(che.currenthealth) rhe:SetMax(che.maxhealth) rhe:SetPenalty(che.penalty) rhe:SetIsTakingFireDamage(che.takingfiredamage) end

	-- wetness & temperature
	if pc then
		if cm then pc.moisture:set(cm.moisture) end
		if ct then pc:SetTemperature(ct.current) end
	end

	-- we don't need to reset the pet healthbar.

end


-- Run whenever someone gets possessed or is no longer possessed
local function OnPossessionChanged(Possessed,Possessor)
	if Possessed.components.talker then Possessed.components.talker:Say("") end
	if Possessor.components.talker then Possessor.components.talker:Say("") end
	if Possessed.components.locomotor then
		Possessed.components.locomotor:Stop()
	end
	if Possessed.Transform and Possessor.Transform then
		Possessor.Transform:SetPosition(Possessed.Transform:GetWorldPosition())
	end
	doPossessionFx(Possessed,Possessor)
end

-- Generic function run on all possessions
local function PlayerStopPossessing(Possessed,Possessor)
	-- Clear possession routing before restoring control so humans use vanilla attack logic.
	Possessor.Poss2.Possessing = nil
	SyncPossessingTargetNet(Possessor, nil)
	Possessor:SetPossessing(false)
	Possessor:SetPossessingPlayer(false)

	if Possessor.components.playercontroller then
		if Possessor.components.locomotor ~= nil then
			Possessor.components.playercontroller.locomotor = Possessor.components.locomotor
		elseif Possessor.Poss2.Loco.Old ~= nil then
			Possessor.components.playercontroller.locomotor = Possessor.Poss2.Loco.Old
		end
		Possessor.Poss2.Loco.Old = nil
	end

	if Possessor.components.combat then
		Possessor.components.combat.ignorehitrange = false
	end

	Possessed.Poss2.Level = Possessed.Poss2.Level - 1

	-- 取消无敌状态
	if Possessor.components.health then
		Possessor.components.health:SetInvincible(false)
	end

	ResetVision(Possessor)
	
	if Possessed.Poss2.Level == 0 then
		-- stop updating the information if there is nobody to show it to
		Possessed:RemoveEventCallback("hungerdelta",UpdateHunger)

		--Possessed:RemoveEventCallback("sanitydelta",UpdateSanity)
		--Possessed:RemoveEventCallback("goinsane",SanityGoSaneOrInsane)
		--Possessed:RemoveEventCallback("gosane",SanityGoSaneOrInsane)

		Possessed:RemoveEventCallback("healthdelta",UpdateHealth)
		Possessed:RemoveEventCallback("startfiredamage",UpdateFireDamage)
		Possessed:RemoveEventCallback("stopfiredamage",UpdateFireDamage)
		
		Possessed:RemoveEventCallback("moisturedelta",UpdateMoisture)
		Possessed:RemoveEventCallback("temperaturedelta",UpdateTemperature)
	end

	Possessor:DoTaskInTime(0,function()
		local S = Possessor.Poss2.Scale
		Possessor.Transform:SetScale(S[1],S[2],S[3])
		Possessor.Poss2.Scale = {}
	end)

	resetComponentsToNormal(Possessor)
	local s = Possessor.Poss2.PhysSize or 0.5
	Possessor.Physics:SetCapsule(s,s,s)
	Possessor:Show()
	Possessor:RemoveTag("noplayerindicator")
	Possessor.MiniMapEntity:SetEnabled(true)
	Possessor.Light:SetRadius(Possessor.Poss2.LightRad)
	Possessor.Poss2.LightRad = 0
	Possessed.Poss2.Possessors[Possessor.GUID] = nil

	ResetStats(Possessor)

	if Possessed.Poss2.Level <= 0 then
		Poss2.Possessed[Possessed.GUID] = nil
		if Possessed.brain then
			Possessed.brain:Start()
		end
	end

	Possessor.Poss2.Timer:Cancel()

	OnPossessionChanged(Possessed,Possessor)
	if Possessed:HasTag("player") then Possessed:SetPossessed(false) end
end

-- Generic function run on all possessions
local function PlayerStartPossessing(Possessed,Possessor)
	if not Possessor:HasTag("player") then return end

	-- 让附身玩家完全无敌，避免被投掷物等攻击
	if Possessor.components.health then
		Possessor.components.health:SetInvincible(true)
	end

	SaveVision(Possessor)
	ChangeVision(Possessed,Possessor)

	if Possessed.Poss2.Level == 0 then
		-- send information to possessors
		Possessed:ListenForEvent("hungerdelta",UpdateHunger)

		--Possessed:ListenForEvent("sanitydelta",UpdateSanity)
		--Possessed:ListenForEvent("goinsane",SanityGoSaneOrInsane)
		--Possessed:ListenForEvent("gosane",SanityGoSaneOrInsane)

		Possessed:ListenForEvent("healthdelta",UpdateHealth)
		Possessed:ListenForEvent("startfiredamage",UpdateFireDamage)
		Possessed:ListenForEvent("stopfiredamage",UpdateFireDamage)

		Possessed:ListenForEvent("moisturedelta",UpdateMoisture)
		Possessed:ListenForEvent("temperaturedelta",UpdateTemperature)
	end
	
	Possessed.Poss2.Level = Possessed.Poss2.Level + 1
	Possessor.Poss2.Loco.Old = Possessor.components.locomotor

	if Possessed.components.locomotor and Possessor.components.playercontroller then
		Possessor.components.playercontroller.locomotor = Possessed.components.locomotor
	end

	local X,Y,Z = Possessor.Transform:GetScale()
	Possessor.Poss2.Scale = {X,Y,Z}
	Possessor.Transform:SetScale(X,0.571,Z)

	local Phys = Possessor.Physics:GetRadius()
	Possessor.Poss2.PhysSize = Phys

	sendComponentsTo(Possessed,Possessor)
	Possessor.Physics:SetCapsule(0,0,0)
	Possessor:Hide()
	Possessor:AddTag("noplayerindicator")
	Possessor.MiniMapEntity:SetEnabled(false)
	Possessor.Poss2.LightRad = Possessor.Light:GetRadius()
	Possessor.Light:SetRadius(0.000001)
 
	Possessor.Poss2.Possessing = Possessed
	SyncPossessingTargetNet(Possessor, Possessed)
	Possessed.Poss2.Possessors[Possessor.GUID] = Possessor
	Poss2.Possessed[Possessed.GUID] = Possessed

	-- stats need to be updated after Poss2.Possessors is updated
	UpdateAllStats(Possessed)

	Possessor.Poss2.Timer = Possessor:DoTaskInTime(Dur,function() Possessed.Poss2.EndFN(Possessed,Possessor) end)
	Possessor.Poss2.StartTime = math.floor(G.GetTime())
	Possessor:SetPossessing(true)

	-- Only activate speech control when you're actually controlling a player.
	Possessor:SetPossessingPlayer(Possessed:HasTag("player") and Possessed.userid ~= "")

	OnPossessionChanged(Possessed,Possessor)
	if Possessed:HasTag("player") then Possessed:SetPossessed(true) end
end

-- Not to be confused with PlayerTickFN.
local function PlayerGenericTick(Possessed,Possessor)
	if Possessed.Transform and Possessor.Transform then
		Possessor.Transform:SetPosition(Possessed.Transform:GetWorldPosition())
	end
end

-- NPC possession behavior differs from that of players, so they use different functions.
-- Run when a generic creature stops being possessed
local function GenericEndFN(Possessed,Possessor)
	PlayerStopPossessing(Possessed,Possessor)
end

-- Run when generic creatures are possessed
local function GenericInitFN(Possessed,Possessor)
	if not Possessor:HasTag("player") then return end
	if RogeCanGhostHauntOrPossess ~= nil and not RogeCanGhostHauntOrPossess(Possessor) then return end
	if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(Possessed) then return end
	if RogeIsHauntDayUnlocked ~= nil and not RogeIsHauntDayUnlocked(Possessed) then return end
	if ROGE_WARG_HAUNT_BLOCK_PREFABS ~= nil and ROGE_WARG_HAUNT_BLOCK_PREFABS[Possessed.prefab]
		and IsWargHauntBlocked ~= nil and IsWargHauntBlocked() then
		return
	end
	if Possessor.Poss2.Permissions > Possessed.Poss2.RestrictionLevel then return end

	if Possessed.brain then
		Possessed.brain:Stop()
	end
	
	PlayerStartPossessing(Possessed,Possessor)
end

-- Run every tick on generic creatures
local function GenericTickFN(Possessed,Possessor)
	PlayerGenericTick(Possessed,Possessor)

	-- 不要每帧都停止AI，这会阻止生物攻击
	-- AI在InitFN中已经停止了，不需要重复停止
end

-- Special end function for boats
local function BoatEndFN(Possessed,Possessor)

	GenericEndFN(Possessed,Possessor)

	local B = Possessed.components.boatphysics

	-- Stop all drift
	if B then
		B.velocity_x = 0
		B.velocity_z = 0
	end

end

-- Special tick function for Boats
local function BoatTickFN(Possessed,Possessor)
	PlayerGenericTick(Possessed,Possessor)

	if not Possessed.components.boatphysics then return else
		local B = Possessed.components.boatphysics

		-- Velocity & Length Variables
		local PV,L = G.Vector3(Possessor.Physics:GetVelocity()):GetNormalizedAndLength()
		local BV,BL = G.Vector3(Possessed.Physics:GetVelocity()):GetNormalizedAndLength()

		-- Apply player's controls to the boat
		B:ApplyForce(PV.x,PV.z,L*0.175)

		-- Opinion: Severe boat drifting is an unrealistic & extremely stupid mechanic.
		-- Water friction should bring the boat to a relative halt unless it is extremely heavy.

		-- Stop boat from drifting (Artificial Drag)
		B:ApplyForce(BV.x,BV.z,BL*-0.3)

	end

end


-- when Person emotes, force the person they are controlling to do the same thing.
local function RelayEmote(Person,Data)
	if Person.Poss2.Possessing == nil then return end
	Data.requires_validation = false
	Person.Poss2.Possessing.Poss2EmoteBypass = Data
	Person.Poss2.Possessing:PushEvent("emote",Data)
end

-- Block people who are being possessed from emoting
-- Stole half this code from original possession because I couldn't be bothered to figure it out again.
local function FailEmote(Person,Data)
	if Person.Poss2.Level <= 0 or Person.Poss2EmoteBypass == Data then return end
	Person.Poss2EmoteBypass = {}
	if not Person.components.inventory.heavylifting then
		Person.components.inventory.heavylifting = true
		Person:DoTaskInTime(0,function()
			-- May cause strange visuals if someone tries emoting too much
			if Person then
				Person.components.inventory.heavylifting = false
			end
		end)
	end
end

-- For when a shutoff is triggered by the possessor rather than the possessed
local function EmergencyRetroShutoff(Person)
	if Person.Poss2.Possessing == nil then return end
	Person.Poss2.Possessing.Poss2.EndFN(Person.Poss2.Possessing,Person)
end

-- In the event of a possessed thing being deleted mid-possession, we need to shut everything off so nothing crashes.
local function EmergencyShutoff(Person)
	EmergencyRetroShutoff(Person)
	for ID,Possessor in pairs(Person.Poss2.Possessors) do
		Person.Poss2.EndFN(Person,Possessor)
	end
end


--[[

-- experimental inventory shit that doesn't work
-- items in inventories are unable to be previewed by outside parties for some reason

local function ClearInventory(Person)
	for Slot,Item in pairs(Person.components.inventory.itemslots) do
		Person.replica.inventory.classified:SetSlotItem(Slot,nil)
	end
	for ESlot,Item in pairs(Person.components.inventory.equipslots) do
		Person.replica.inventory.classified:SetSlotEquip(Solt,nil)
	end
	Person.replica.inventory.classified:SetActiveItem(nil)
end

local function UpdateInventory(Possessed,Possessor)

	-- Wipe the slate clean
	ClearInventory(Possessor)

	-- Show the possessor the inventory items of the possessed.
	for Slot,Item in pairs(Possessed.components.inventory.itemslots) do
		Possessor.replica.inventory.classified:SetSlotItem(Slot,Item)
	end
	for ESlot,Item in pairs(Possessed.components.inventory.equipslots) do
		Possessor.replica.inventory.classified:SetSlotEquip(ESlot,Item)
	end
	Possessor.replica.inventory.classified:SetActiveItem(Possessed.components.inventory:GetActiveItem())

end

local function ResetInventory(Person)

	-- Wipe the slate clean
	ClearInventory(Person)

	-- Return the appearance of the possessor's inventory back to normal.
	for Slot,Item in pairs(Person.components.inventory.itemslots) do
		Person.replica.inventory.classified:SetSlotItem(Slot,Item)
	end
	for ESlot,Item in pairs(Person.components.inventory.equipslots) do
		Person.replica.inventory.classified:SetSlotEquip(ESlot,Item)
	end
	Person.replica.inventory.classified:SetActiveItem(Person.components.inventory:GetActiveItem())

end

local function EndInventoryControl(Possessed,Possessor)

	if Possessor.components.inventory and Possessed.components.inventory and Possessor:HasTag("playerghost") then
		Possessor.components.inventory:Close()
		Possessor.components.inventory:Hide()
	end
	
	ResetInventory(Possessor)
end


local function StartInventoryControl(Possessed,Possessor)
	if Possessor.components.inventory and Possessed.components.inventory then
		Possessor.components.inventory:Open()
		Possessor.components.inventory:Show()
	end
	UpdateInventory(Possessed,Possessor)
end

]]

-- Run on Players once they stop being possessed.
local function PlayerEndFN(Possessed,Possessor)
	G.print("[Possession 2] - "..Possessor.name.." "..Possessor.userid.." stopped possessing "..Possessed.name.."! "..Possessed.userid.." (Duration: "..G.tostring(math.floor(G.GetTime())-Possessor.Poss2.StartTime).." Seconds)")
	
	PlayerStopPossessing(Possessed,Possessor)

	if Possessed.player_classified then
		Possessed:ShowHUD(not (Possessed.Poss2.Level > 0))      
		Possessed:SetCameraZoomed((Possessed.Poss2.Level > 0))
	end

	if Possessed.components.playercontroller then
	
		-- this causes a crash and i don't know why...
		-- the resulting error log is unreadable
		-- removing this doesn't seem to cause any problems though
		--Possessed.components.playercontroller:Activate()
		
		Possessed.components.playercontroller:Enable(true)
	end

	--EndInventoryControl(Possessed,Possessor)
end

-- Run on Players when they initially get possessed
local function PlayerInitFN(Possessed,Possessor)
	if not Possessor:HasTag("player") or Possessed == Possessor or Possessor.Poss2.Possessing then return end
	if RogeCanGhostHauntOrPossess ~= nil and not RogeCanGhostHauntOrPossess(Possessor) then return end
	if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(Possessed) then return end
	if RogeIsHauntDayUnlocked ~= nil and not RogeIsHauntDayUnlocked(Possessed) then return end
	if ROGE_WARG_HAUNT_BLOCK_PREFABS ~= nil and ROGE_WARG_HAUNT_BLOCK_PREFABS[Possessed.prefab]
		and IsWargHauntBlocked ~= nil and IsWargHauntBlocked() then
		return
	end
	if Possessor.Poss2.Permissions > Possessed.Poss2.RestrictionLevel or (D("Revival") and DeepSearchInventoryForRevivers(Possessed,Possessor)) then return end
	G.print("[Possession 2] - "..Possessor.name.." "..Possessor.userid.." began possessing "..Possessed.name.."! "..Possessed.userid)
	PlayerStartPossessing(Possessed,Possessor)

	--StartInventoryControl(Possessed,Possessor)
end

-- Runs every tick on possessed players
local function PlayerTickFN(Possessed,Possessor)
	PlayerGenericTick(Possessed,Possessor)

	if Possessed.components.playercontroller then
		if Possessed.AnimState:IsCurrentAnimation("jump_pre") and not Possessed.sg.currentstate.name == "death" then Possessed.sg:GoToState("startle") end
		Possessed.components.playercontroller:Deactivate()
		Possessed.components.playercontroller:Enable(false)
	end

	if Possessed.player_classified then
		Possessed:ShowHUD(not (Possessed.Poss2.Level > 0))      
		Possessed:SetCameraZoomed((Possessed.Poss2.Level > 0))
	end
	
end


--[[
	Every tick, check the Poss2.Possessed table to see if anything is possessed.
	If a possessed thing is found, check to make sure it exists & use the possessed thing's designated tick function.

	This is essentially the heart of the entire mod.
]]
G.scheduler:ExecutePeriodic(F,function()
	for _,Possessed in pairs(Poss2.Possessed) do

		-- Might as well do some cleanup while we're here
		if not Valid(Possessed) then
			Poss2.Possessed[Possessed.GUID] = nil
		elseif Possessed.Poss2 == nil or Possessed.Poss2.Possessors == nil then
			-- 实体仍有效但附身数据已缺失（异常状态），清理掉避免后续崩溃
			Poss2.Possessed[Possessed.GUID] = nil
		else

			for ID,Possessor in pairs(Possessed.Poss2.Possessors) do
				if not Valid(Possessor) then
					Possessed.Poss2.EndFN(Possessed,Possessor) -- If one of the people possessing the entity somehow vanishes, use the end function for them.
				else
					Possessed.Poss2.TickFN(Possessed,Possessor) -- Otherwise, run the tick code as usual.
				end
			end

		end
	end
end)

-- Table which contains most of an entity's possession-related data (so we won't have to create like 20 indexes on the player)
local function CreatePossessionTable(tick,start,stop,perms)
	return {
		SG = "",
		Possessing = nil,
		Loco = {},
		Vision = {isghostmode = false,},
		Scale = {},
		Components = {},
		Possessors = {},
		Networked = false,
		Level = 0,
		LightRad = 0,
		StartTime = 0,
		LastAttackTime = 0,
		VisionCount = 0,
		Permissions = -1,
		PhysSize = 0.5,
		RestrictionLevel = perms,
		TickFN = tick or NoFN,
		StartFN = start or NoFN,
		EndFN = stop or NoFN,
		Timer = {Cancel = NoFN},
	}
end

local PrefabCanBePossessed = {}

-- Make something possessable
local function MakePossessable(Thing, Tick, Start, Stop, Perms)
	if Thing.Poss2 then
		return
	end
	if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(Thing) then
		return
	end
	MakeHauntable(Thing, Start)
	Thing.Poss2 = CreatePossessionTable(Tick,Start,Stop,Perms)
	Thing:ListenForEvent("onremove",EmergencyShutoff)
	Thing:ListenForEvent("death",EmergencyShutoff)
	Thing:ListenForEvent("locomote",FixLagComp)
	Thing:RemoveTag("noclick") -- for aquatic creatures
end

-- Autodetection is great and all, but some people want more control.
local ThingsYouCanPossess = {
	["Pets"] = {
		"critter_kitten",
		"critter_puppy",
		"critter_lamb",
		"critter_perdling",
		"critter_dragonling",
		"critter_glomling",
		"critter_lunarmothling",
		"salty_dog",
		"critter_bulbin",
	},

	["Critters"] = {
		"carrat",
		"rabbit",
		"mole",
		"catcoon",
		"butterfly",
		"moonbutterfly",
		"stalker_minion1",
		"stalker_minion2",
		"grassgekko",
		"robin",
		"robin_winter",
		"crow",
		"canary",
		"puffin",
		"pigeon",
		"deer",
		"spore_small",
		"spore_medium",
		"spore_tall",
		"spore_moon",
		"tumbleweed",
		"stagehand",
		"wobster_sheller",
		"wobster_sheller_land",
		"gingerbreadpig",
		"wobster_moonglass_land",
	},

	["Friendly NPCs"] = {
		"chester",
		"hutch",
		"glommer",
		"hermitcrab",
		"wobysmall",
		"wobybig",
		"bernie_active",
		"bernie_big",
		"mandrake_active",
		"lavae_pet",
		"mermking",
		"lucy",
		"graveguard_ghost",
		"smallghost",
		"polly_rogers",
	},

	["Summonables"] = {
		"abigail",
		"shadowduelist",
		"shadowdigger",
		"shadowminer",
		"shadowlumber",
	},

	["Neutral NPCs"] = {
		"beefalo",
		"babybeefalo",
		"koalefant_summer",
		"koalefant_winter",
		"pigman",
		"pigguard",
		"bunnyman",
		"merm",
		"mermguard",
		"merm_lunar",
		"mermguard_lunar",
		"mermguard_shadow",
		"merm_shadow",
		"grassgator",
		"penguin",
		"bee",
		"rocky",
		"buzzard",
		"fruitdragon",
		"lightninggoat",
		"perd",
		"mossling",
		"squid",
		"mushgnome",
		"dustmoth",
		"gnarwail",
		"teenbird",
		"smallbird",
	},

	-- 本 mod 自定义生物（附身天数/黑名单仍由 ghost.lua 拦截）
	["Roge Mod Creatures"] = {
		"shadowdragon",
		"shadoweyeturret",
		"shadoweyeturret2",
		"spider_robot",
		"mandrakeman",
		"ironlord",
		"king_squid",
		"pigelitefighter1",
		"pigelitefighter2",
		"pigelitefighter3",
		"pigelitefighter4",
		"shadow_bishop",
	},

	["Hostile NPCs"] = {
		"knight",
		"bishop",
		"rook",
		"knight_nightmare",
		"bishop_nightmare",
		"rook_nightmare",
		"mutatedhound",
		"hound",
		"firehound",
		"icehound",
		"hedgehound",
		"clayhound",
		"lavae",
		"krampus",
		"deer_red",
		"deer_blue",
		"slurtle",
		"snurtle",
		"bat",
		"ghost",
		"beeguard",
		"gestalt",
		"monkey",
		"slurper",
		"spider",
		"spider_warrior",
		"spider_moon",
		"spider_dropper",
		"spider_hider",
		"spider_spitter",
		"little_walrus",
		"walrus",
		"tallbird",
		"worm",
		"frog",
		"lunarfrog",
		"mosquito",
		"killerbee",
		"cookiecutter",
		"tentacle",
		"molebat",
		"shark",
		"eyeofterror_mini",
		"eyeofterror_mini_grounded",
		"bird_mutant",
		"bird_mutant_spitter",
		"cave_vent_mite",
		"prime_mate",
		"powder_monkey",
		"crabking_cannontower",
		"crabking_claw",
		"gelblob",
		"gestalt_guard_evolved",
		"chest_mimic_revealed",
		"fruitfly",
		"birchnutdrake",
		"mutatedbuzzard_gestalt",
		"otter",
		"mutated_penguin",
		"rabbitkingminion_bunnyman",
		"wagdrone_rolling",
		"wagdrone_flying",
		"crabking_mob_knight",
		"crabking_mob",
		"lureplant",
		"eyeplant",
	},

	["Shadow Creatures"] = {
		"crawlinghorror",
		"terrorbeak",
		"crawlingnightmare",
		"nightmarebeak",
		"oceanhorror",
		"waveyjones",
		"ruinsnightmare",
		"shadow_leech",
		"ruins_shadeling",
		"itemmimic_revealed",
		"shadowchanneler",
		"fused_shadeling_bomb",
		"fused_shadeling",
	},

	["Mini-Bosses"] = {
		"archive_centipede",
		"spiderqueen",
		"leif",
		"leif_sparse",
		"warg",
		"claywarg",
		"spat",
		"shadowthrall_horns",
		"shadowthrall_hands",
		"shadowthrall_wings",
		"shadowthrall_mouth",
		"lunarthrall_plant",
	},

	["Bosses"] = {
		"moose",
		"deerclops",
		"bearger",
		"malbatross",
		"sharkboi",
		"eyeofterror",
	},

	["Shadow Bosses"] = {
		"shadow_knight",
		"shadow_bishop",
		"shadow_rook",
	},

	["Super Bosses"] = {
		"dragonfly",
		"klaus",
		"beequeen",
		"stalker",
		"stalker_forest",
		"stalker_atrium",
		"toadstool",
		"toadstool_dark",
		"minotaur",
		"shadowthrall_centipede_head",
		"alterguardian_phase1",
		"alterguardian_phase2",
		"alterguardian_phase3",
		"alterguardian_phase1_lunarrift",
		"alterguardian_phase4_lunarrift",
		"wagboss_robot",
		"twinofterror1",
		"twinofterror2",
		"mutateddeerclops",
		"mutatedbearger",
		"mutatedwarg",
		"daywalker1",
		"daywalker2",
		"antlion",
	},
}

for I=1,9 do ThingsYouCanPossess["Critters"][#ThingsYouCanPossess["Critters"]+1] = "oceanfish_small_"..I end
for I=1,8 do ThingsYouCanPossess["Critters"][#ThingsYouCanPossess["Critters"]+1] = "oceanfish_medium_"..I end


if D("Players") ~= 0 then
	PrintDebug("Possession is Enabled for Players!")
else
	PrintDebug("Possession is Disabled for Players!")
end


-- Check each category to see if possession is enabled for it. If so, make everything in the category possessable with generic possession functions
for CatName,Category in pairs(ThingsYouCanPossess) do
	local perms = D(CatName)
	if CatName == "Roge Mod Creatures" then
		perms = 2
	end
	if perms ~= 0 then
		for _,NPC in pairs(Category) do
			PrefabCanBePossessed[NPC] = true
			AddPrefabPostInit(NPC,function(Thing)
				MakePossessable(Thing,GenericTickFN,GenericInitFN,GenericEndFN,perms)
			end)
		end
		PrintDebug("Possession is Enabled for "..CatName.."!")
	else
		PrintDebug("Possession is Disabled for "..CatName.."!")
	end
end


-- Automatically detect boats.
if D("Boats") ~= 0 then
	PrintDebug("Possession is Enabled for Boats!")
	AddClassPostConstruct("components/boatphysics",function(self)
		self.inst:DoTaskInTime(0,function()
			if self.inst.prefab then
				PrefabCanBePossessed[self.inst.prefab] = true
				MakePossessable(self.inst,BoatTickFN,GenericInitFN,BoatEndFN,D("Boats"))
			end
		end)
	end)
end


-- Automatically detect all unwhitelisted entities. (Useful for modded servers & future-proofing)
if D("Everything except Players & Boats") ~= 0 then
	PrintDebug("Possession is Enabled for 'Everything except Players & Boats!'")
	AddClassPostConstruct("components/locomotor", function(self)
		self.inst:DoTaskInTime(0, function()
			if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(self.inst) then
				return
			end
			if not self.inst:HasTag("player") and self.inst.prefab then
				PrefabCanBePossessed[self.inst.prefab] = true
				MakePossessable(self.inst,GenericTickFN,GenericInitFN,GenericEndFN,D("Everything except Players & Boats"))
			end
		end)
	end)
end

-- 新增：基于标签的附身系统
-- 使用游戏已有的标签来判断可附身生物（仅针对未在 ThingsYouCanPossess 中列出的模组生物）
AddPrefabPostInitAny(function(inst)
	inst:DoTaskInTime(0, function()
		if RogeIsHauntBlocked ~= nil and RogeIsHauntBlocked(inst) then
			return
		end
		-- 已列入白名单的跳过
		if PrefabCanBePossessed[inst.prefab] then return end
		-- 检查是否有combat组件且不是玩家或船
		if inst.components and inst.components.combat and
		   not inst:HasTag("player") and
		   not inst:HasTag("boat") and
		   not inst.Poss2 then

			-- 如果不允许通过标签附身模组生物，直接跳过
			if not D("AllowUnlistedByTag") then return end

			-- 逐标签检查权限
			local has_combat = inst:HasTag("_combat")
			local has_monster = inst:HasTag("monster")
			local has_animal = inst:HasTag("animal")
			local has_hostile = inst:HasTag("hostile")
			local has_prey = inst:HasTag("prey")
			local has_insect = inst:HasTag("insect")
			local has_bird = inst:HasTag("bird")

			local is_creature = (has_combat and D("AllowCombatTag")) or
			                   (has_monster and D("AllowMonsterTag")) or
			                   (has_animal and D("AllowAnimalTag")) or
			                   (has_hostile and D("AllowHostileTag")) or
			                   has_prey or has_insect or has_bird

			if is_creature then
				PrintDebug("Making "..tostring(inst.prefab).." possessable via combat tag! (combat="..tostring(has_combat)..", monster="..tostring(has_monster)..", animal="..tostring(has_animal)..", hostile="..tostring(has_hostile)..")")
				PrefabCanBePossessed[inst.prefab] = true
				MakePossessable(inst, GenericTickFN, GenericInitFN, GenericEndFN, 2)
			end
		end
	end)
end)

-- Run on every player that spawns
AddPlayerPostInit(function(player)
	if Valid(player) then

		local plystr = G.tostring(player)

		PrintDebug("Constructing Poss2 table for "..plystr.."!")
		player.Poss2 = player.Poss2 or CreatePossessionTable(PlayerTickFN,PlayerInitFN,PlayerEndFN,D("Players"))

		-- inefficient network stuff that I don't understand very well
		PrintDebug("Running network code for "..plystr.."!")
			
		player.poss2_say = player.poss2_say or ""
		player.poss2_whisper = player.poss2_whisper or false
		player.poss2_emote = player.poss2_emote or false
		player.poss2_possessing = player.poss2_possessing or false
		player.poss2_possessing_player = player.poss2_possessing_player or false
		player.poss2_possessed = player.poss2_possessed or false
		
		player.net_poss2_say = player.net_poss2_say or G.net_string(player.GUID, "poss2_say", "poss2say_dirty")
		player.net_poss2_whisper = player.net_poss2_whisper or G.net_bool(player.GUID, "poss2_whisper", "poss2whisper_dirty")
		player.net_poss2_emote = player.net_poss2_emote or G.net_bool(player.GUID, "poss2_emote", "poss2emote_dirty")
		player.net_poss2_possessing = player.net_poss2_possessing or G.net_bool(player.GUID, "poss2_possessing", "poss2_possessing_dirty")
		player.net_poss2_possessing_player = player.net_poss2_possessing_player or G.net_bool(player.GUID, "poss2_possessing_player", "poss2_possessing_player_dirty")
		player.net_poss2_possessed = player.net_poss2_possessed or G.net_bool(player.GUID, "poss2_possessed", "poss2_possessed_dirty")
		player.net_poss2_target = player.net_poss2_target or G.net_entity(player.GUID, "poss2_target", "poss2_target_dirty")

		if not G.TheWorld.ismastersim then
			local function Poss2Say_dirty(player)
				player.poss2_say = player.net_poss2_say:value()
			end

			local function Poss2Whisper_dirty(player)
				player.poss2_whisper = player.net_poss2_whisper:value()
			end

			local function Poss2Emote_dirty(player)
				player.poss2_emote = player.net_poss2_emote:value()
			end


			local function Poss2_Possessing_Dirty(player)
				player.poss2_possessing = player.net_poss2_possessing:value()
				if not player.poss2_possessing and player.Poss2 ~= nil then
					player.Poss2.Possessing = nil
				end
			end

			local function Poss2_Target_Dirty(player)
				if player.Poss2 == nil then
					return
				end
				local ent = player.net_poss2_target:value()
				player.Poss2.Possessing = (ent ~= nil and ent:IsValid()) and ent or nil
			end

			-- necessary for speech control
			local function Poss2_Possessing_Player_Dirty(player)
				player.poss2_possessing_player = player.net_poss2_possessing_player:value()
			end

			local function Poss2_Possessed_Dirty(player)
				player.poss2_possessed = player.net_poss2_possessed:value()
			end
			
			player:ListenForEvent("poss2say_dirty",Poss2Say_dirty)
			player:ListenForEvent("poss2whisper_dirty",Poss2Whisper_dirty)
			player:ListenForEvent("poss2emote_dirty",Poss2Emote_dirty)
			player:ListenForEvent("poss2_possessing_dirty",Poss2_Possessing_Dirty)
			player:ListenForEvent("poss2_possessing_player_dirty",Poss2_Possessing_Player_Dirty)
			player:ListenForEvent("poss2_possessed_dirty",Poss2_Possessed_Dirty)
			player:ListenForEvent("poss2_target_dirty",Poss2_Target_Dirty)
			Poss2_Target_Dirty(player)
		else
			function player:Poss2Say(message)
				local msg = message or ""
				player.poss2_say = msg
				player.net_poss2_say:set(msg)
			end

			function player:Poss2Whisper(state)
				local st = state or false
				player.poss2_whisper = st
				player.net_poss2_whisper:set(st)
			end

			function player:Poss2Emote(state)
				local st = state or false
				player.poss2_emote = st
				player.net_poss2_emote:set(st)
			end

			function player:SetPossessing(state)
				local st = state or false
				player.poss2_possessing = st
				player.net_poss2_possessing:set(st)
				player.net_poss2_possessing:set_local(st)
			end

			function player:SetPossessingPlayer(state)
				local st = state or false
				player.poss2_possessing_player = st
				player.net_poss2_possessing_player:set(st)
				player.net_poss2_possessing_player:set_local(st)
			end

			function player:SetPossessed(state)
				local st = state or false
				player.poss2_possessed = st
				player.net_poss2_possessed:set(st)
				player.net_poss2_possessed:set_local(st)
			end
		end

		player:DoTaskInTime(0,function()
			PrintDebug("Running delayed startup code for "..plystr.."!")

			if IsAdmin(player) then
				player.Poss2.Permissions = 1
			else
				player.Poss2.Permissions = 2
			end
			
			if D("Players") ~= 0 then
				PrefabCanBePossessed[player.prefab] = true
				MakeHauntable(player,PlayerInitFN)
			end

			-- Shutoff
			player:ListenForEvent("respawnfromghost",EmergencyShutoff)
			player:ListenForEvent("onremove",EmergencyShutoff)
			player:ListenForEvent("death",EmergencyShutoff)

			-- Emote Related
			player:ListenForEvent("emote",RelayEmote)
			player:ListenForEvent("emote",FailEmote)

			-- Partial fix for the lag compensation issues
			player:ListenForEvent("locomote",FixLagComp)

			-- Actionpicker breaks for some reason if this isn't delayed
			player:DoTaskInTime(G.FRAMES,function()
			
				-- comment from future self in 2023: not sure what i was trying to do here,
				-- but adding the playercontroller component caused a crash when spawning npc players
				if player.components.playercontroller == nil then
					-- player:AddComponent("playercontroller")
					player:AddComponent("playeractionpicker")
				end
				
			end)
		end)
	end
end)

-- Disables speech while possessed & sends speech commands when possessing
local OldSay = G.NetworkProxy.Say
G.NetworkProxy.Say = function(self,message,whisper,emote)
	message,whisper,emote = message or "",whisper or false,emote or false
	if not G.ThePlayer then return OldSay(self,message,whisper,emote) end
	if G.ThePlayer.poss2_possessed and (G.ThePlayer.poss2_say == "" or G.ThePlayer.poss2_say == nil) then return end
	if not G.ThePlayer.poss2_possessing_player then
		return OldSay(self,message,whisper,emote)
	else
		SendModRPCToServer(GetModRPC("poss2_say", "poss2_say"), message, whisper, emote)
	end
end


-- When speech commands are sent from a client who is possessing someone, relay the command to the person they're possessing.
AddModRPCHandler("poss2_say","poss2_say",function(caller,message,whisper,emote, ...)
	if G.checkstring(message) and G.checkbool(whisper) and G.checkbool(emote) and caller.Poss2 and caller.Poss2.Possessing then
		local p = caller.Poss2.Possessing
		if p.userid ~= "" and p.userid ~= nil then
			p:Poss2Say(message)
			p:Poss2Whisper(whisper)
			p:Poss2Emote(emote)
		elseif p.components.talker ~= nil then
			p.components.talker:Say(message)
		end
	end
end)


-- Stop possessing (保留RPC，以防其他地方调用)?
AddModRPCHandler("poss2_pstop","poss2_pstop",function(caller, ...)
    G.print("[poss2_pstop] RPC from:", caller and caller.name or "nil",
        " Poss2:", caller and caller.Poss2,
        " Possessing:", caller and caller.Poss2 and caller.Poss2.Possessing)
    if caller == nil then G.print("  -> caller nil!") return end
    if caller.Poss2 == nil then G.print("  -> caller.Poss2 nil!") return end
    if caller.Poss2.Possessing == nil then G.print("  -> caller.Poss2.Possessing nil!") return end
    local Possessed = caller.Poss2.Possessing
    G.print("  -> calling EndFN, Possessed:", Possessed and Possessed.name or "nil",
        " Valid:", Possessed and Possessed:IsValid() or "nil")
    if Possessed and Possessed:IsValid() and Possessed.Poss2 and Possessed.Poss2.EndFN then
        Possessed.Poss2.EndFN(Possessed, caller)
    else
        G.print("  -> EndFN skipped: not valid or no EndFN")
    end
end)

-- 解除附身聊天指令
G.AddModUserCommand("Possession 2", "Possession", {
    aliases = {"附身"},
    permission = G.COMMAND_PERMISSION.USER,
    slash = true,
    params = {},
	paramsoptional = {true},
	serverfn = function(params, caller)
		if caller == nil or caller.Poss2 == nil or caller.Poss2.Possessing == nil then return end
		caller.Poss2.Possessing.Poss2.EndFN(caller.Poss2.Possessing,caller)
    end
})

-- Run on any client that joins. (Necessary for speech control and auto-closing of console & chat)
local function ClientBackdoor()

	-- I have no idea why, but players will say "" after joining. This prevents it.
	G.scheduler:ExecuteInTime(1,function() 
		if G.ThePlayer then
			G.ThePlayer.poss2_say = "" 
		end
	end)

	-- 关闭延迟补偿时，附身操控需要额外走 ControllerAttackButton RPC；
	-- 不可对普通玩家全局启用，否则鼠标指向目标即可无视距离攻击（防空 A bug）。
	local OldOnControl = G.TheInput.OnControl
	G.TheInput.OnControl = function(self, control, down, ...)
		if down and control == G.CONTROL_ATTACK and G.ThePlayer then
			local player = G.ThePlayer
			if IsClientPossessingCombat(player) then
				local target = G.TheInput:GetWorldEntityUnderMouse()
				if target and target:IsValid() and not target:IsInLimbo() and target ~= player then
					G.SendRPCToServer(G.RPC.ControllerAttackButton, target, true)
				end
			end
		end
		return OldOnControl(self, control, down, ...)
	end

	-- Run this code every tick
	G.scheduler:ExecutePeriodic(G.FRAMES,function()
		local player = G.ThePlayer
		if Valid(player) then

			-- If you receive a speech command from your possessor, run it.
			if player.poss2_say ~= "" and player.poss2_say ~= nil then
				G.TheNet:Say(player.poss2_say,player.poss2_whisper,player.poss2_emote)
				player.poss2_say = ""
				player.poss2_whisper = nil
				player.poss2_emote = nil
			end

			-- Prevent chat & console from being opened while possessed (sorry)
			if player.poss2_possessed then
				if G.require("screens/chatinputscreen") then G.require("screens/chatinputscreen"):Close() end
				if G.require("screens/consolescreen") then G.require("screens/consolescreen"):Close() end
			end

		end
	end)
end
AddClassPostConstruct("widgets/controls", ClientBackdoor)

-- ============================================
-- 解除附身UI按钮系统（幽灵装饰图标 + 居中按钮）
-- ============================================

local function AddPoss2Button(self)
    local TEMPLATES = require("widgets/redux/templates")

    -- 中心按钮（长条，可显示文字）
    local btn = self:AddChild(TEMPLATES.StandardButton(function()
        local env = getfenv(1)
        if not rawget(env, "SendModRPCToServer") then rawset(env, "SendModRPCToServer", G.SendModRPCToServer) end
        if not rawget(env, "GetModRPC") then rawset(env, "GetModRPC", G.GetModRPC) end
        SendModRPCToServer(GetModRPC("poss2_pstop", "poss2_pstop"))
    end, "", {160, 50}))

    btn:SetHAnchor(0)
    btn:SetVAnchor(0)
    btn:SetScaleMode(SCALEMODE_PROPORTIONAL)
    btn:SetMaxPropUpscale(MAX_HUD_SCALE)
    btn:Hide()

    -- 状态变量
    self.poss2_btn      = btn
    self.poss2_last_lang = nil

    -- 每帧更新
    local old_onupdate = self.OnUpdate
    self.OnUpdate = function(self_, dt, ...)
        if old_onupdate then old_onupdate(self_, dt, ...) end

        local player = G.ThePlayer
        if not player then
            if self_.poss2_btn and self_.poss2_btn.shown then
                self_:HidePoss2UI()
            end
            return
        end

        local is_ghost      = player:HasTag("playerghost") or player:HasTag("ghost")
        local is_possessing = player.poss2_possessing
            or (player.Poss2 and Valid(player.Poss2.Possessing))
        local lang = LOC.GetLocaleCode()
        local isCN = (lang == "zh" or lang == "zht" or lang == "zhr")

        if is_possessing or is_ghost then
            if not self_.poss2_btn.shown then self_:ShowPoss2UI() end
            if self_.poss2_last_lang ~= isCN then
                self_.poss2_last_lang = isCN
                self_.poss2_btn:SetText(isCN and "解除附身" or "Release Possession")
            end
        else
            if self_.poss2_btn.shown then self_:HidePoss2UI() end
        end
    end

    function self:ShowPoss2UI()
        local y = -RESOLUTION_Y * 0.5 - 80

        self.poss2_btn:SetPosition(0, y, 0)
        self.poss2_btn:Show()
    end

    function self:HidePoss2UI()
        self.poss2_btn:Hide()
    end
end

AddClassPostConstruct("widgets/controls", AddPoss2Button)
