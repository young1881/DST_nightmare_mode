-- roge/wickerbottom.lua
-- 薇克巴顿：随身书本耐久恢复 + 万物百科阅读范围理智恢复

-- ====== 书本在本人主物品栏+手部内恢复（与 bookstation 在薇克巴顿附近时一致） ======
-- TUNING.BOOKSTATION_RESTORE_TIME 周期内 SetPercent(percent + BOOKSTATION_RESTORE_AMOUNT * BOOKSTATION_WICKER_BONUS)

function RogeIsWickerBookItem(player, item)
	if item == nil or not item:IsValid() or player == nil then
		return false
	end
	local invitem = item.components.inventoryitem
	if invitem == nil or invitem.owner ~= player then
		return false
	end
	if item.components.finiteuses == nil then
		return false
	end
	return item:HasTag("book")
		or item.components.book ~= nil
		or item:HasTag("bookcabinet_item")
end

function RogeRepairWickerBooksTick(inst)
	if inst == nil or not inst:IsValid() or inst.prefab ~= "wickerbottom" then
		return
	end
	local inv = inst.components.inventory
	if inv == nil then
		return
	end
	local function repair_one(item)
		if not RogeIsWickerBookItem(inst, item) then
			return
		end
		local fu = item.components.finiteuses
		if fu == nil or fu.GetPercent == nil or fu.SetPercent == nil then
			return
		end
		local percent = fu:GetPercent()
		if percent >= 1 then
			return
		end
		local delta = TUNING.BOOKSTATION_RESTORE_AMOUNT * TUNING.BOOKSTATION_WICKER_BONUS
		fu:SetPercent(math.min(1, percent + delta))
	end
	for _, item in pairs(inv.itemslots) do
		repair_one(item)
	end
	for _, item in pairs(inv.equipslots) do
		repair_one(item)
	end
end

AddPlayerPostInit(function(inst)
	if inst.prefab ~= "wickerbottom" then
		return
	end
	if not TheWorld.ismastersim then
		return
	end
	if inst._roge_wicker_book_regen_task ~= nil then
		inst._roge_wicker_book_regen_task:Cancel()
		inst._roge_wicker_book_regen_task = nil
	end
	inst._roge_wicker_book_regen_task = inst:DoPeriodicTask(TUNING.BOOKSTATION_RESTORE_TIME, RogeRepairWickerBooksTick)
end)

-- ====== 万物百科：阅读成功后，为范围内存活玩家各恢复最大理智的 50% ======
ROGE_WANWU_BAIKE_PREFAB = "book_research_station"

function RogeWanwuGetBookRange(inst)
	if inst == nil then
		return 20
	end
	if inst.cast_scope ~= nil and inst.cast_scope > 0 then
		return inst.cast_scope
	end
	if inst.def ~= nil and inst.def.range ~= nil and inst.def.range > 0 then
		return inst.def.range
	end
	return 20
end

function RogeWanwuHealNearbyPlayers(reader, book_inst)
	if TheWorld == nil or not TheWorld.ismastersim then
		return
	end
	if reader == nil or not reader:IsValid() or not reader:HasTag("player") then
		return
	end
	local radius = RogeWanwuGetBookRange(book_inst)
	local x, y, z = reader.Transform:GetWorldPosition()
	local ents = TheSim:FindEntities(x, y, z, radius, { "player" }, { "playerghost", "INLIMBO" })
	for _, p in ipairs(ents) do
		if p:IsValid() and p.components.sanity ~= nil and not p:HasTag("playerghost") then
			local sm = p.components.sanity
			local maxv = sm.max
			if maxv == nil or maxv <= 0 then
				maxv = (sm.GetMaxWithPenalty ~= nil and sm:GetMaxWithPenalty()) or TUNING.SANITY_MAX or 200
			end
			sm:DoDelta(maxv * 0.5)
		end
	end
end

function RogeWanwuWrapBookOnRead(inst)
	if not TheWorld.ismastersim or inst.components.book == nil then
		return
	end
	local bookcomp = inst.components.book
	local old_read = bookcomp.onread
	bookcomp:SetOnRead(function(book_inst, reader)
		local ok, reason = true, nil
		if old_read ~= nil then
			ok, reason = old_read(book_inst, reader)
		end
		if ok ~= false then
			RogeWanwuHealNearbyPlayers(reader, book_inst)
		end
		return ok, reason
	end)
end

AddPrefabPostInit(ROGE_WANWU_BAIKE_PREFAB, function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, RogeWanwuWrapBookOnRead)
end)
