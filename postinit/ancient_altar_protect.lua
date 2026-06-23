GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

-- 远古伪科学站 / 残缺站：不可摧毁（与远古大门一样无锤拆），残缺站仍可用铥矿修复

local ROGE_PROTECTED_ALTARS = {
	ancient_altar = true,
	ancient_altar_broken = true,
}

local function RogeProtectIntactAltar(inst)
	inst:AddTag("indestructible")
	local w = inst.components.workable
	if w ~= nil then
		w:SetWorkable(false)
		w:SetOnFinishCallback(nil)
		w:SetOnWorkCallback(nil)
	end
end

local function RogeProtectBrokenAltar(inst)
	inst:AddTag("indestructible")
	local w = inst.components.workable
	if w == nil then
		return
	end
	-- 禁止锤到 workleft==0 触发拆除；铥矿修复通过 repairable 增加 workleft，不受影响
	w:SetOnFinishCallback(nil)
	local old_onwork = w.onwork
	w:SetOnWorkCallback(function(altar, worker, workleft, numworks)
		if old_onwork ~= nil then
			old_onwork(altar, worker, workleft, numworks)
		end
		if altar.components.workable ~= nil and altar.components.workable.workleft < 1 then
			altar.components.workable:SetWorkLeft(1)
		end
	end)
end

AddPrefabPostInit("ancient_altar", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, RogeProtectIntactAltar)
end)

AddPrefabPostInit("ancient_altar_broken", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, RogeProtectBrokenAltar)
end)

AddSimPostInit(function()
	if ACTIONS == nil or ACTIONS.HAMMER == nil or ACTIONS.HAMMER.fn == nil then
		return
	end
	if ACTIONS.HAMMER._roge_altar_protect then
		return
	end
	local old_hammer = ACTIONS.HAMMER.fn
	ACTIONS.HAMMER._roge_altar_protect = true
	ACTIONS.HAMMER.fn = function(act)
		local t = act.target
		if t ~= nil and t:IsValid() and ROGE_PROTECTED_ALTARS[t.prefab] then
			if t.prefab == "ancient_altar" then
				return false
			end
			local w = t.components.workable
			if w ~= nil and w:CanBeWorked() and w.workleft ~= nil and w.workleft <= 1 then
				return false
			end
		end
		return old_hammer(act)
	end
end)
