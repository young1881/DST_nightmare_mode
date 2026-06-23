local Autobase_Packer = Class(function(self, inst)
    self.inst = inst
	self.contents_rel_x = {}
	self.contents_rel_z = {}
end)

-- function Autobase_Packer:AddtoContents(entity, inst)
	-- local ent_x,ent_y,ent_z = entity.Transform:GetWorldPosition()
	-- local inst_x,inst_y,inst_z = inst.Transform:GetWorldPosition()
	-- table.insert(self.contents, entity)
	-- table.insert(self.contents_rel_x, ent_x-inst_x)
	-- table.insert(self.contents_rel_z, ent_z-inst_z)
-- --	TheNet:SystemMessage(inst_x-ent_x, false)
-- --	TheNet:SystemMessage(inst_z-ent_z, false)
-- end

function Autobase_Packer:GetPosRelX(entity, inst)
	local test_ter = "12"
	return test_ter --self.contents_rel_x
end

return Autobase_Packer
