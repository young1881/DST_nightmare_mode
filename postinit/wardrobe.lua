local function GetLocaleString(en, zh)
    local locale_code = GLOBAL.LOC.GetLocaleCode()
    if locale_code == "zh" or locale_code == "zht" then
        return zh
    else
        return en
    end
end

local reset_skilltree = GLOBAL.Action()
reset_skilltree.id = "RESET_SKILLTREE"
reset_skilltree.str = GetLocaleString("Reset Insight", "重置洞察")

local function FindDeactivationPath(skilltreeupdater)
    local character_prefab = skilltreeupdater.inst.prefab
    local activated_skills = skilltreeupdater:GetActivatedSkills()
    if character_prefab == nil or activated_skills == nil then
        return nil
    else
        activated_skills = GLOBAL.deepcopy(activated_skills)
    end
    local skill_xp = skilltreeupdater.skilltree.skillxp[character_prefab]
    local path = {}
    local obstacles = { {} }
    local need_to_roll_back
    while table.count(activated_skills) > 0 do
        need_to_roll_back = true
        for skill, _ in pairs(activated_skills) do
            if not table.contains(obstacles[#obstacles], skill) then
                activated_skills[skill] = nil
                if skilltreeupdater.skilltree:ValidateCharacterData(character_prefab, activated_skills, skill_xp) then
                    table.insert(path, skill)
                    table.insert(obstacles, {})
                    need_to_roll_back = false
                    break
                else
                    activated_skills[skill] = true
                    table.insert(obstacles[#obstacles], skill)
                end
            end
        end
        if need_to_roll_back then
            if #path == 0 then
                return nil
            end
            activated_skills[path[#path]] = true
            obstacles[#obstacles] = nil
            table.insert(obstacles[#obstacles], path[#path])
            path[#path] = nil
        end
    end
    return path
end

reset_skilltree.fn = function(act) --只在服务端运行
    local skilltreeupdater = act.doer.components.skilltreeupdater
    if not skilltreeupdater then
        return false
    end
    local deactivation_path = FindDeactivationPath(skilltreeupdater)
    if not deactivation_path then
        return false
    end
    for index = 1, #deactivation_path do
        skilltreeupdater:DeactivateSkill(deactivation_path[index])
    end
    if act.doer.components.talker ~= nil then
        act.doer.components.talker:Say(GetLocaleString("Reset Successfully", "重置成功"))
    end
    return true
end

AddAction(reset_skilltree)
AddStategraphActionHandler("wilson", GLOBAL.ActionHandler(reset_skilltree, "dolongaction"))
AddStategraphActionHandler("wilson_client", GLOBAL.ActionHandler(reset_skilltree, "dolongaction"))
AddComponentAction("SCENE", "wardrobe", function(inst, doer, actions, right)
    if inst.prefab == "wardrobe" and right then
        table.insert(actions, GLOBAL.ACTIONS.RESET_SKILLTREE)
    end
end)
