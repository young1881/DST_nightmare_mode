-- roge/wickerbottom_books.lua
-- 须在 postinit/wickerbottom.lua 之后加载：蛛网书三块分散地皮
-- （养蜂笔记纯粹恐惧充能已暂时注释，恢复时取消下方注释块）

--[[ 暂时禁用：养蜂笔记仅接受纯粹恐惧
local Fueled = require("components/fueled")

if not Fueled._roge_book_bees_horrorfuel_hooked then
	Fueled._roge_book_bees_horrorfuel_hooked = true

	local OldCanAcceptFuelItem = Fueled.CanAcceptFuelItem
	function Fueled:CanAcceptFuelItem(item, ...)
		if self.inst.prefab == "book_bees" and item ~= nil and item.prefab ~= "horrorfuel" then
			local owner = self.inst.components.inventoryitem and self.inst.components.inventoryitem:GetGrandOwner()
			if owner ~= nil and owner.components.talker ~= nil then
				owner:DoTaskInTime(0, function()
					if owner:IsValid() then
						owner.components.talker:Say("它渴望纯粹恐惧，而非普通的噩梦燃料。")
					end
				end)
			end
			return false
		end
		return OldCanAcceptFuelItem(self, item, ...)
	end
end

AddPrefabPostInit("book_bees", function(inst)
	if not TheWorld.ismastersim then
		return
	end
	inst:DoTaskInTime(0, function()
		if not inst:IsValid() or inst.components.book == nil or inst.components.book.onread == nil then
			return
		end
		local old_read = inst.components.book.onread
		inst.components.book:SetOnRead(function(book_inst, reader)
			local fueled = book_inst.components.fueled
			if fueled ~= nil and fueled:IsEmpty() then
				if reader ~= nil and reader.components.talker ~= nil then
					reader.components.talker:Say("这本饥饿的书需要纯粹恐惧的滋养！")
				end
				return false, "NOFUEL"
			end
			return old_read(book_inst, reader)
		end)
	end)
end)
--]]

local BOOK_WEB_COUNT = 3
local BOOK_WEB_RADIUS_MIN = 9
local BOOK_WEB_RADIUS_MAX = 15
local BOOK_WEB_ANGLE_JITTER = 0.5
local PI2 = 2 * math.pi

AddPrefabPostInit("book_web", function(inst)
	if not TheWorld.ismastersim or inst.components.book == nil then
		return
	end
	inst:DoTaskInTime(0, function()
		if not inst:IsValid() or inst.components.book == nil then
			return
		end

		local function SpawnBookWebAt(x, y, z)
			local ground_web = SpawnPrefab("book_web_ground")
			if ground_web ~= nil then
				ground_web.Transform:SetPosition(x, y, z)
			end
		end

		inst.components.book:SetOnRead(function(book_inst, reader)
			if reader == nil or not reader:IsValid() then
				return false
			end

			local x, y, z = reader.Transform:GetWorldPosition()
			local delta_theta = PI2 / BOOK_WEB_COUNT

			for i = 1, BOOK_WEB_COUNT do
				local angle = (i - 1) * delta_theta + (math.random() - 0.5) * BOOK_WEB_ANGLE_JITTER
				local radius = BOOK_WEB_RADIUS_MIN + math.random() * (BOOK_WEB_RADIUS_MAX - BOOK_WEB_RADIUS_MIN)
				local px = x + radius * math.cos(angle)
				local pz = z + radius * math.sin(angle)
				SpawnBookWebAt(px, y, pz)
			end

			return true
		end)
	end)
end)
