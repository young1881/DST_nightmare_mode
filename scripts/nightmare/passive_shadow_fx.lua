local SHADOW_STRIKE_DAMAGE_MULT = 1.0
local SHADOW_STRIKE_PLANAR_MULT = 1.5

local function GetEquippedWeapon(player)
	if player == nil or not player:IsValid() then
		return nil
	end
	local inv = player.components.inventory
	if inv == nil then
		return nil
	end
	return inv:GetEquippedItem(EQUIPSLOTS.HANDS)
end

local function GetEquippedWeaponPhysicalDamage(player, target)
	local weapon = GetEquippedWeapon(player)
	if weapon ~= nil and weapon.components.weapon ~= nil then
		return weapon.components.weapon:GetDamage(player, target) or 0
	end
	if player.components.combat ~= nil then
		return (player.components.combat.defaultdamage or 0)
			* (player.components.combat.damagemultiplier or 1)
	end
	return 0
end

local function GetEquippedWeaponPlanarDamage(player)
	local weapon = GetEquippedWeapon(player)
	if weapon ~= nil and weapon.components.planardamage ~= nil then
		return weapon.components.planardamage:GetDamage() or 0
	end
	return 0
end

local assets = {}
local deps = {
	"statue_transition_2",
	"shadowstrike_slash_fx",
	"shadowstrike_slash2_fx",
	"weaponsparks",
}

local function playlunge(self)
	SpawnPrefab("statue_transition_2").Transform:SetPosition(self.Transform:GetWorldPosition())
	self.AnimState:PlayAnimation("lunge_pre")
	self.AnimState:PushAnimation("lunge_loop")
	self.AnimState:PushAnimation("lunge_pst")
	self:DoTaskInTime(12 * FRAMES, function(d)
		d.Physics:SetMotorVel(TUNING.THE_FORGE_ITEM_PACK.SHADOWS.LUNGE_SPEED, 0, 0)
	end)
	self:DoTaskInTime(15 * FRAMES, function(d)
		d:Attack()
	end)
	self:DoTaskInTime(22 * FRAMES, function(d)
		d.Physics:ClearMotorVelOverride()
	end)
	self:DoTaskInTime(35 * FRAMES, function(d)
		d:Remove()
	end)
end

local function fn()
	local inst = CreateEntity()
	inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddPhysics()
	inst.entity:AddNetwork()
	inst.Transform:SetFourFaced(inst)
	inst.AnimState:SetBank("lavaarena_shadow_lunge")
	inst.AnimState:SetBuild("waxwell")
	inst.AnimState:AddOverrideBuild("lavaarena_shadow_lunge")
	inst.AnimState:SetMultColour(0, 0, 0, 0.5)
	inst.AnimState:OverrideSymbol("swap_object", "swap_nightmaresword", "swap_nightmaresword")
	inst.AnimState:Hide("hat")
	inst.AnimState:Hide("hat_hair")
	inst.Physics:SetMass(1)
	inst.Physics:SetFriction(0)
	inst.Physics:SetDamping(5)
	inst.Physics:SetCollisionGroup(COLLISION.CHARACTERS)
	inst.Physics:ClearCollisionMask()
	inst.Physics:CollidesWith(COLLISION.GROUND)
	inst.Physics:SetCapsule(0.5, 1)
	inst:AddTag("scarytoprey")
	inst:AddTag("NOBLOCK")
	inst.entity:SetPristine()
	if not TheWorld.ismastersim then
		return inst
	end
	inst:AddComponent("combat")
	function inst:SetPlayer(player)
		inst.player = player
	end
	function inst:SetTarget(target)
		inst.target = target
		inst.target_pos = Point(target.Transform:GetWorldPosition())
		inst:FacePoint(inst.target_pos)
	end
	function inst:SetPosition(pos, offset)
		inst.offset = offset
		inst.Transform:SetPosition(pos.x + offset.x, pos.y + offset.y, pos.z + offset.z)
		playlunge(inst)
	end
	function inst:Attack()
		local target = self.target
		local player = self.player
		if target == nil or not target:IsValid() then
			return
		end
		if player == nil or not player:IsValid() then
			return
		end
		local shadows = TUNING.THE_FORGE_ITEM_PACK.SHADOWS
		local damage_mult = (shadows ~= nil and shadows.DAMAGE_MULT) or SHADOW_STRIKE_DAMAGE_MULT
		local planar_mult = (shadows ~= nil and shadows.PLANAR_DAMAGE_MULT) or SHADOW_STRIKE_PLANAR_MULT
		local physical = GetEquippedWeaponPhysicalDamage(player, target) * damage_mult
		local planar = GetEquippedWeaponPlanarDamage(player) * planar_mult
		local function slashfx(fx)
			if fx == nil or not fx:IsValid() then
				return
			end
			local tp = self.target_pos
			if tp == nil then
				return
			end
			fx.Transform:SetPosition(tp.x, tp.y, tp.z)
			fx.Transform:SetRotation(self.Transform:GetRotation())
			if planar > 0 and target.components ~= nil and target.components.combat ~= nil then
				target.components.combat:GetAttacked(self, 0, nil, nil, { planar = planar })
			end
		end
		local roll = math.random(1, 2)
		if roll == 1 then
			slashfx(SpawnPrefab("shadowstrike_slash_fx"))
		else
			slashfx(SpawnPrefab("shadowstrike_slash2_fx"))
		end
		local scale = 0.25
		local ox, oy, oz = 0, 0, 0
		if self.offset ~= nil then
			ox = self.offset.x * scale
			oy = self.offset.y * scale
			oz = self.offset.z * scale
		end
		local sparks = SpawnPrefab("weaponsparks_fx") or SpawnPrefab("weaponsparks")
		if sparks ~= nil and sparks.SetThrusting ~= nil then
			sparks:SetThrusting(player, target, Vector3(ox, oy, oz))
		end
		if self.components.combat ~= nil and physical > 0 then
			self.components.combat:SetDefaultDamage(physical)
			self.components.combat:DoAttack(target, nil, nil, "strong")
		end
	end
	inst.persists = false
	inst.OnLoad = inst.Remove
	return inst
end

RegisterPrefabs(Prefab("passive_shadow_fx", fn, assets, deps))
