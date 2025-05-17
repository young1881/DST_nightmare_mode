GLOBAL.setfenv(1, GLOBAL)

function MakePlayerOnlyTarget(inst)
    inst.components.combat:AddNoAggroTag("epic")
    if inst.components.damagetyperesist == nil then
        inst:AddComponent("damagetyperesist")
    end
    inst.components.damagetyperesist:AddResist("epic", inst, 0)
end
