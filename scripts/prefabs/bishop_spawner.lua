local RuinsRespawner = require "prefabs/ruinsrespawner"

local function onruinsrespawn(inst, respawner)
	if not respawner:IsAsleep() then
		inst.sg:GoToState("ruinsrespawn")
	end
end

return RuinsRespawner.Inst("bishop", onruinsrespawn), RuinsRespawner.WorldGen("bishop", onruinsrespawn)
