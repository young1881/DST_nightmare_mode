--[[
Copyright (C) 2018 Forged Forge

This file is part of Forged Forge.

The source code of this program is shared under the RECEX
SHARED SOURCE LICENSE (version 1.0).
The source code is shared for referrence and academic purposes
with the hope that people can read and learn from it. This is not
Free and Open Source software, and code is not redistributable
without permission of the author. Read the RECEX SHARED
SOURCE LICENSE for details 
The source codes does not come with any warranty including
the implied warranty of merchandise. 
You should have received a copy of the RECEX SHARED SOURCE
LICENSE in the form of a LICENSE file in the root of the source
directory. If not, please refer to 
<https://raw.githubusercontent.com/Recex/Licenses/master/SharedSourceLicense/LICENSE.txt>
]]
local function MakeBattleCry(name, build, scale, offset)
    local assets = {
        Asset("ANIM", "anim/"..build..".zip"),
    }
	--------------------------------------------------------------------------
	local function SetTarget(inst, target)
		inst.Follower:FollowSymbol(target.GUID, "torso", offset, offset, 1)
		target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/battle_cry")
	end
	--------------------------------------------------------------------------
    local function fn()
        local inst = COMMON_FNS.BasicEntityInit(build, build, "in", {pristine_fn = function(inst)
	        inst.entity:AddFollower()
	        ------------------------------------------
	        inst.AnimState:SetMultColour(.5, .5, .5, .5)
	        ------------------------------------------
	        inst.Transform:SetScale(scale, scale, scale)
	        ------------------------------------------
			COMMON_FNS.AddTags(inst, "DECOR", "NOCLICK")
		end})
		------------------------------------------
        if not TheWorld.ismastersim then
            return inst
        end
		------------------------------------------
		-- Create Battle Cry icon for the given target
		inst.SetTarget = function(inst_tar, target, damage_mult, store_time)
			-- Create Battle Cry icon
			inst_tar.Follower:FollowSymbol(target.GUID, "torso", offset, offset, 1)
			target.SoundEmitter:PlaySound("dontstarve/common/lava_arena/spell/battle_cry")
		end
		
		-- Remove the Battle Cry
		inst.RemoveBattleCryFX = function()		
			-- Play ending animation of the Battle Cry
			inst.AnimState:PlayAnimation("out")
		end
		
		-- Update animation at the end of each animation
		inst:ListenForEvent("animover", function(inst)
			-- idle animation until the "out" animation
			if inst.AnimState:IsCurrentAnimation("out") then
				inst:Remove()
			else
				inst.AnimState:PlayAnimation("idle")
			end
		end)
		------------------------------------------
        return inst
    end
	--------------------------------------------------------------------------
	return Prefab(name, fn, assets)
end
--------------------------------------------------------------------------
return MakeBattleCry("passive_battlecry_fx_self", "lavaarena_attack_buff_effect", 1.4, 0),
	MakeBattleCry("passive_battlecry_fx_other", "lavaarena_attack_buff_effect2", 1, 1)
