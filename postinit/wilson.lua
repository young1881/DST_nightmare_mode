AddPrefabPostInit("wilson", function(inst)
    inst:AddTag("fastbuilder")
    -- inst:AddTag("hungrybuilder")
end)


STRINGS.CHARACTERS.GENERIC.ANNOUNCE_HUNGRY_FASTBUILD = {
    "科学研究催生的成果。",
    "科研过后，胃口大增。",
    "干活干的有点想吃培根煎蛋。",
    "照这么下去我得在天黑前找点吃的了。"
}

-- modmain.lua

local SPECIAL_KILL_TAG = "wilson_kill_remove"

AddPrefabPostInit("archive_centipede", function(inst)
    if not TheWorld.ismastersim then return end

    inst._should_removedirectly = false
    -- 监听被杀死
    inst:ListenForEvent("death", function(inst, data)
        local killer = data and data.afflicter or data.attack or data.attacker or nil
        if killer and killer.prefab == "wilson" then
            inst._should_removedirectly = true
        end
    end)
end)


AddStategraphPostInit("centipede", function(sg)
    local old_death_onenter = sg.states["death"].onenter

    sg.states["death"].onenter = function(inst, ...)
        if inst._should_removedirectly then
            if inst.components.lootdropper then
                inst.components.lootdropper:SpawnLootPrefab("opalpreciousgem")
            end

            inst.SoundEmitter:PlaySound("grotto/creatures/centipede/death")
            inst:DoTaskInTime(0.5, function()
                inst:Remove()
            end)

            if inst.beginfade and inst.light_params and inst._endlight then
                inst.copyparams(inst._endlight, inst.light_params.off)
                inst.beginfade(inst)
            end

            inst.AnimState:PlayAnimation("death")
            inst.SoundEmitter:KillSound("alive")
            return
        end
        
        if old_death_onenter then
            old_death_onenter(inst, ...)
        end
    end
end)
