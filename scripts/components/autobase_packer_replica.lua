local Autobase_Packer = Class(function(self, inst)
    self.inst = inst
	self.contents_name = {}
	self.contents_rel_x = {}
	self.contents_rel_z = {}
	self.initialized = false

end)


	
function Autobase_Packer:GetPosRelX(entity, inst)
	--print(self.inst.components.autobase_packer.contents_rel_x[1])
    if self.inst.components.autobase_packer ~= nil then
        return "12"
    -- else
        -- return self.classified ~= nil and self.classified:GetPosRelX() or {}
    end
end

return Autobase_Packer
