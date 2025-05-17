AddPrefabPostInit("shadowthrall_hands",function (inst)
    inst.entity:SetCanSleep(false)
end)

AddPrefabPostInit("shadowthrall_horns",function (inst)
    inst.entity:SetCanSleep(false)
end)

AddPrefabPostInit("shadowthrall_wings",function (inst)
    inst.entity:SetCanSleep(false)
end)

TUNING.SHADOWTHRALL_HORNS_WALKSPEED = 5

--[[AddStategraphPostInit("shadowthrall_hands",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)

AddStategraphPostInit("shadowthrall_wings",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)

AddStategraphPostInit("shadowthrall_horns",function(sg)
    sg.events["attacked"].fn=function(inst,data)
        return false
    end
end)]]
