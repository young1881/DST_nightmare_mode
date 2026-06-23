--ban控制台
local function IsAdmin(id)
	local data = TheNet:GetClientTableForUser(id)
	return data and data.admin
end

AddClassPostConstruct("screens/consolescreen", function(self)
	local _OnBecomeActive = self.OnBecomeActive
	function self:OnBecomeActive(...)
		if not IsAdmin(TheNet:GetUserID()) then
			self:Close()
		else
			return _OnBecomeActive(self, ...)
		end
	end
end)