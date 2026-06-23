-- 必须保留在 scripts/components/：引擎 require 为 components/<name>，子目录 nightmare 无法被该 require 解析。

local SEC = Vector3(236 / 255, 126 / 255, 121 / 255)
local function PushFlash(inst, flash)
	if flash > 0 then
		local r = SEC.x * flash
		local g = SEC.y * flash
		local b = SEC.z * flash
		if inst.components.colouradder ~= nil then
			inst.components.colouradder:PushColour(PushFlash, r, g, b, 0)
		else
			inst.AnimState:SetAddColour(r, g, b, 0)
		end
		inst.flashflash = inst:DoTaskInTime(0, PushFlash, flash - FRAMES)
	else
		if inst.components.colouradder ~= nil then
			inst.components.colouradder:PopColour(PushFlash)
		elseif inst.components.freezable ~= nil then
			inst.components.freezable:UpdateTint()
		else
			inst.AnimState:SetAddColour(0, 0, 0, 0)
		end
		inst.flashflash = nil
	end
end

local function IsCreatureCombatTarget(target)
	if target == nil or not target:IsValid() then
		return false
	end
	if target.components == nil or target.components.health == nil then
		return false
	end
	if target.components.health:IsDead() then
		return false
	end
	if target:HasTag("player") then
		return false
	end
	if target:HasTag("structure") or target:HasTag("wall") then
		return false
	end
	return true
end

local JOURNAL_FAIL_SAY_COOLDOWN = 5

local function FindWaxwellJournalInMainSlots(inv)
	if inv == nil or inv.itemslots == nil then
		return nil
	end
	for _, item in pairs(inv.itemslots) do
		if item ~= nil and item.prefab == "waxwelljournal" and item.components.fueled ~= nil then
			return item
		end
	end
	return nil
end

local function CanAffordJournalShadowStrike(journal)
	if journal == nil or journal.components.fueled == nil then
		return false
	end
	local pct = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT or 0.2
	return journal.components.fueled:GetPercent() >= pct
end

local function ConsumeJournalFuelForShadowStrike(journal, doer)
	if journal == nil or journal.components.fueled == nil then
		return
	end
	local f = journal.components.fueled
	local pct = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FUEL_COST_PERCENT or 0.2
	f:DoDelta(-pct * f.maxfuel, doer)
end

local function AnnounceJournalDrain(player, comp)
	if player.components.talker == nil then
		return
	end
	local now = GetTime()
	if comp._journal_drain_say_time ~= nil and now - comp._journal_drain_say_time < JOURNAL_FAIL_SAY_COOLDOWN then
		return
	end
	comp._journal_drain_say_time = now
	local msg = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.JOURNAL_FAIL_ANNOUNCE
	if msg == nil or msg == "" then
		msg = "我的暗影力量正在流失..."
	end
	player.components.talker:Say(msg)
end

local a = 5
local b = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.MAX_SHADOW_SPAWN
local c = 2 * math.pi / b
local d = Class(function(self, e)
	self.player = e
	self.hits_on_target = 0
	self.current_target = nil
	self.shadow_fx = {}
	self.hits_required = TUNING.THE_FORGE_ITEM_PACK.SHADOWS.HITS_REQUIRED or 4
	self._journal_drain_say_time = nil
	self.offsets = {}
	for f = 1, b do
		local g = c * f * 2
		self.offsets[f] = {
			x = a * math.sin(g),
			y = 0,
			z = a * math.cos(g),
		}
	end
	self.player:ListenForEvent("onhitother", function(_, i)
		if i == nil or i.target == nil then
			return
		end
		if self.player.prefab ~= "waxwell" then
			return
		end
		if not IsCreatureCombatTarget(i.target) then
			return
		end
		local dealt = i.damageresolved or i.damage or 0
		if dealt <= 0 then
			return
		end
		self:OnHitCreature(i)
	end)
end)

function d:OnHitCreature(i)
	local target = i.target
	self.current_target = target
	self.hits_on_target = self.hits_on_target + 1
	if self.hits_on_target >= self.hits_required then
		local journal = FindWaxwellJournalInMainSlots(self.player.components.inventory)
		if not CanAffordJournalShadowStrike(journal) then
			AnnounceJournalDrain(self.player, self)
			self.hits_on_target = 0
			return
		end
		self:ApplyShadows(target)
		ConsumeJournalFuelForShadowStrike(journal, self.player)
		for k in pairs(self.player.components.leader.followers) do
			if k:HasTag("shadowminion") then
				if k.components.health and k.components.health:GetPercent() < 1 then
					local sp = self.player.ShadowPoint or 1
					k.components.health:DoDelta(sp * 2)
					PushFlash(k, 0.5)
				end
			end
		end
		self.hits_on_target = 0
	end
end

function d:ApplyShadows(strike_target)
	local target = strike_target ~= nil and strike_target or self.current_target
	if target == nil or not target:IsValid() or not IsCreatureCombatTarget(target) then
		return
	end
	for f = 1, b do
		self.player:DoTaskInTime(0.1 * f, function()
			if target == nil or not target:IsValid() or not IsCreatureCombatTarget(target) then
				return
			end
			local j = Point(target.Transform:GetWorldPosition())
			self.shadow_fx[f] = SpawnPrefab("passive_shadow_fx")
			if self.shadow_fx[f] == nil then
				return
			end
			self.shadow_fx[f]:SetPlayer(self.player)
			self.shadow_fx[f]:SetPosition(j, self.offsets[f])
			self.shadow_fx[f]:SetTarget(target)
		end)
	end
end

function d:RemoveShadows()
	for _, fx in pairs(self.shadow_fx) do
		if fx ~= nil and fx:IsValid() then
			fx:Remove()
		end
	end
	self.shadow_fx = {}
end

function d:SetDamageThreshold(k)
	self.hits_required = k
end

function d:SetHitsRequired(k)
	self.hits_required = k
end

return d
