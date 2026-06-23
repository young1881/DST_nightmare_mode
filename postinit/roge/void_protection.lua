-- roge/void_protection.lua
-- 洞穴虚空保护：忽略视觉悬空，直接检测真实地面并强制传送（不依赖 drownable 状态图）

local VOID_CHECK_PERIOD = 0.5
local RESCUE_SEARCH_MAX = 36

-- 海象、钢羊、宝石无眼鹿启用洞穴虚空检索（其他肉鸽骰子生物不处理）
local ROGE_VOID_PROTECTED = {
	walrus = true,
	spat = true,
	deer_red = true,
	deer_blue = true,
}

local function RogeIsOnSolidGroundStrict(x, y, z)
	local map = TheWorld.Map
	-- ignore_land_overhang=true：不算相邻地块伸过来的“假地面”
	return map:IsPassableAtPointWithPlatformRadiusBias(x, y, z, false, true, 0, true)
end

local function RogeIsOnWalkableGround(x, y, z)
	local map = TheWorld.Map
	if map:IsPassableAtPoint(x, y, z, false) then
		return true
	end
	if map:IsVisualGroundAtPoint(x, y, z) and not map:IsOceanAtPoint(x, y, z, false) then
		local tile = map:GetTileAtPoint(x, y, z)
		if tile ~= nil and tile ~= WORLD_TILES.IMPASSABLE then
			return true
		end
	end
	return false
end

local function RogeEntityHasFooting(inst, x, y, z)
	if RogeIsOnWalkableGround(x, y, z) then
		return true
	end
	local radius = math.max(1, inst:GetPhysicsRadius(0) + 0.5)
	local offsets = {
		{ radius, 0 }, { -radius, 0 }, { 0, radius }, { 0, -radius },
		{ radius * 0.7, radius * 0.7 }, { -radius * 0.7, radius * 0.7 },
		{ radius * 0.7, -radius * 0.7 }, { -radius * 0.7, -radius * 0.7 },
	}
	for _, off in ipairs(offsets) do
		if RogeIsOnWalkableGround(x + off[1], y, z + off[2]) then
			return true
		end
	end
	return false
end

local function RogeIsInCaveVoid(inst)
	if TheWorld == nil or not TheWorld:HasTag("cave") then
		return false
	end
	if inst:GetCurrentPlatform() ~= nil then
		return false
	end
	if inst.components.locomotor == nil then
		return false
	end

	local x, y, z = inst.Transform:GetWorldPosition()
	-- 仍在陆地块/平台边缘：普通可走判定通过则不算虚空（避免 strict 在边缘误触发）
	if RogeEntityHasFooting(inst, x, y, z) then
		return false
	end
	return not RogeIsOnSolidGroundStrict(x, y, z)
end

local function RogeFindSolidGroundNear(x, y, z)
	local pt = Vector3(x, y, z)
	for radius = 3, RESCUE_SEARCH_MAX, 3 do
		local offset = FindWalkableOffset(
			pt,
			math.random() * TWOPI,
			radius,
			16,
			false,
			false,
			function(check_pt)
				return RogeIsOnSolidGroundStrict(check_pt.x, check_pt.y, check_pt.z)
			end
		)
		if offset ~= nil then
			return x + offset.x, y, z + offset.z
		end
	end

	local tx, ty, tz = FindRandomPointOnShoreFromOcean(x, y, z)
	if tx ~= nil then
		return tx, ty, tz
	end
	return nil
end

function RogeTeleportToSolidGround(inst)
	local x, y, z = inst.Transform:GetWorldPosition()
	local tx, ty, tz = RogeFindSolidGroundNear(x, y, z)
	if tx == nil then
		return false
	end

	if inst.components.locomotor ~= nil then
		inst.components.locomotor:Stop()
	end
	if inst.components.sleeper ~= nil and inst.components.sleeper:IsAsleep() then
		inst.components.sleeper:WakeUp()
	end

	if inst.Physics ~= nil then
		inst.Physics:Teleport(tx, ty, tz)
	else
		inst.Transform:SetPosition(tx, ty, tz)
	end
	return true
end

local function RogeTryRescueFromVoid(inst)
	if inst.components.health ~= nil and inst.components.health:IsDead() then
		return
	end
	if not RogeIsInCaveVoid(inst) then
		return
	end
	RogeTeleportToSolidGround(inst)
end

function RogeSetupVoidProtection(inst)
	if inst == nil or not inst:IsValid() then
		return
	end
	if not ROGE_VOID_PROTECTED[inst.prefab] then
		return
	end
	if not TheWorld or not TheWorld.ismastersim or not TheWorld:HasTag("cave") then
		return
	end
	if inst.components.locomotor == nil then
		return
	end
	if inst._roge_void_protection then
		return
	end
	inst._roge_void_protection = true

	if inst._roge_void_periodic_task ~= nil then
		inst._roge_void_periodic_task:Cancel()
		inst._roge_void_periodic_task = nil
	end
	inst._roge_void_periodic_task = inst:DoPeriodicTask(VOID_CHECK_PERIOD, RogeTryRescueFromVoid)
	inst:DoTaskInTime(0, RogeTryRescueFromVoid)
end

for prefab in pairs(ROGE_VOID_PROTECTED) do
	AddPrefabPostInit(prefab, function(inst)
		if not TheWorld or not TheWorld.ismastersim then
			return
		end
		inst:DoTaskInTime(0, RogeSetupVoidProtection)
	end)
end
