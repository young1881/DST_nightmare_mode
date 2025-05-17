--- 服务器侧模组
--if GLOBAL.TheNet:GetIsServer() ~= true then
--    return
-- end

--- 管理员权限检查表
--- ret:是管理员
local AdminTable = {}

AddComponentPostInit("playerspawner",
    function(PlayerSpawner, inst)
        inst:ListenForEvent("ms_playerspawn",
            function(inst, player)
                for _, v in ipairs(GLOBAL.TheNet:GetClientTable() or {}) do
                    AdminTable[v.userid] = v.admin
                end
            end
        )
    end
)

--- 白名单控制
local WhiteTable = {}
local ConnTable = {}

local optFunction = {
    --- 解除锁定
    ["##unlock"] = function(options)
        for _, player in ipairs(GLOBAL.TheNet:GetClientTable() or {}) do
            if player.name == options[2] then
                WhiteTable[player.userid] = true
                print("[Unlock] ", player.name)
                return true
            end
        end
        return false
    end,
    --- 撤销接触锁定
    ["##lock"] = function(options)
        for _, player in ipairs(GLOBAL.TheNet:GetClientTable() or {}) do
            if player.name == options[2] then
                WhiteTable[player.userid] = false
                print("[Lock] ", player.name)
                return true
            end
        end
        return false
    end,
    --- 交叉授权
    ["##addconn"] = function(options)
        for _, player in ipairs(GLOBAL.TheNet:GetClientTable() or {}) do
            if player.name == options[2] then
                ConnTable[player.userid] = true
                print("[Add Conn] ", player.name)
                return true
            end
        end
        return false
    end,
    --- 命令测试
    ["##nhtest"] = function(options)
        local msg = "NHTEST"
        for _, opt in pairs(options) do
            msg = msg .. " " .. opt
        end
        print(msg)
        return true
    end,
}

-- 分割字符串
local function splitCmd(cmd, reps)
    local options = {}
    string.gsub(cmd, '[^' .. reps .. ']+', function(str)
        table.insert(options, str)
    end)
    return options
end

local _Networking_Say = GLOBAL.Networking_Say
GLOBAL.Networking_Say = function(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
    if (AdminTable[userid] or ConnTable[userid]) and string.sub(message, 1, 2) == "##" then
        local options = splitCmd(message, " ")
        if optFunction[options[1]] then
            if optFunction[options[1]](options) then
                message = message .. " 操作成功"
            end
        end
    end
    return _Networking_Say(guid, userid, name, prefab, message, colour, whisper, isemote, user_vanity)
end

--- 参数注入
local ageLimit = 3
local tolerantTimes = 5

--- 检查实体附近是否有建筑
--- ret:true 实体附近无建筑
local function checkStruct(inst)
    local a, b, c = inst:GetPosition():Get()
    local ents = TheSim:FindEntities(a, b, c, 0.2 * TUNING.FIRE_DETECTOR_RANGE, { "structure" })
    return (GLOBAL.next(ents) == nil)
end

local function checkAccess(player)
    if player.isplayer then
        if player.components.age and player.components.age:GetAgeInDays() > ageLimit then
            return true
        elseif checkStruct(player) then
            return true
        elseif player:HasTag("playerghost") then
            return true
        else
            return false
        end
    else
        return true
    end
end

local BAD_GUYS_LIST = {}

local function sendWarning(act)
    if act then
        -- 查询黑名单
        local badGuyId = act.doer.userid
        if BAD_GUYS_LIST[badGuyId] == nil then
            BAD_GUYS_LIST[badGuyId] = 1
        else
            BAD_GUYS_LIST[badGuyId] = BAD_GUYS_LIST[badGuyId] + 1
        end

        -- 生成消息
        local playerName = act.doer:GetDisplayName()
        local oar = act.doer.components.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        local oarName = nil
        if oar then
            oarName = oar:GetDisplayName()
        else
            oarName = "NULL"
        end
        local msg = nil
        if act.target ~= nil then
            local targetName = act.target:GetDisplayName()
            msg = playerName ..
                " " .. "(" ..
                act.doer.userid ..
                ")" .. oarName .. " " .. targetName .. " 熊孩子" .. tostring(BAD_GUYS_LIST[badGuyId]) .. "次 "
        else
            msg = playerName ..
                " " .. "(" .. act.doer.userid .. ")" .. oarName .. " 熊孩子" .. tostring(BAD_GUYS_LIST[badGuyId]) .. "次 "
        end

        GLOBAL.TheNet:Announce(msg)
        print("[Negative Warning]" .. msg)
    end
end

local _ACTION_LIGHT = GLOBAL.ACTIONS.LIGHT.fn
GLOBAL.ACTIONS.LIGHT.fn = function(act)
    if checkAccess(act.doer) then
        return _ACTION_LIGHT(act)
    else
        sendWarning(act)
        return false
    end
end


local _ACTION_HAMMER = GLOBAL.ACTIONS.HAMMER.fn
GLOBAL.ACTIONS.HAMMER.fn = function(act)
    if checkAccess(act.doer) then
        return _ACTION_HAMMER(act)
    elseif act.target:HasTag("wall") or
        (act.target.prefab and act.target.prefab == "pighouse") or
        (act.target.prefab and act.target.prefab == "rabbithouse") or
        (act.target.prefab and act.target.prefab == "mermhouse") or
        (act.target.prefab and act.target.prefab == "pighead") or
        (act.target.prefab and act.target.prefab == "stagehand") or
        (act.target.prefab and act.target.prefab == "mermead") or
        (act.target.prefab and act.target.prefab == "homesign") or
        (act.target.prefab and act.target.prefab == "researchlab") or
        (act.target.prefab and act.target.prefab == "ancient_altar_broken") or
        (act.target.prefab and act.target.prefab == "catcoonden") or
        (act.target.prefab and act.target.prefab == "monkeyhut") then
        return _ACTION_HAMMER(act)
    else
        sendWarning(act)
        return _ACTION_HAMMER(act)
    end
end

--矮星不引燃
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

AddPrefabPostInit("stafflight", function(inst)
    inst:RemoveComponent("propagator")
end)

local G = GLOBAL
local msg_ban = "喜欢绕本地是吧？"
local test_time = 0.05
local delay = 3

local function ResetFOVAndKick(inst)
    if G.TheCamera then
        G.TheCamera.fov = 20
        -- inst:DoTaskInTime(delay, function()
        --     if inst and inst.userid then
        --         G.TheNet:Announce(inst:GetDisplayName() .. msg_ban)
        --         G.TheNet:Kick(inst.userid)
        --     end
        -- end)
    end
end

local function DisableNightVisionAndKick(inst)
    if inst and inst.components and inst.components.playervision then
        if inst.components.playervision.forcenightvision and not inst.components.playervision.islegitnightvision then
            inst.components.playervision:ForceNightVision(false)
            -- G.TheNet:Kick(inst.userid)
        end
    end
end


local function MonitorFOV(inst)
    inst:DoPeriodicTask(test_time, function()
        if G.TheCamera and G.TheCamera.fov then
            if G.TheCamera.fov >= 36 then
                ResetFOVAndKick(inst)
            end
        end
    end)
end

local function MonitorNightVision(inst)
    inst:DoPeriodicTask(test_time, function()
        if inst and inst.components and inst.components.playervision then
            if inst.components.playervision.forcenightvision and not inst.components.playervision.islegitnightvision then
                DisableNightVisionAndKick(inst)
            end
        end
    end)
end

local function ResetCameraAndKick(inst)
    if G.TheCamera then
        if G.TheWorld:HasTag("cave") then
            G.TheCamera.zoomstep = 4
            G.TheCamera.mindist = 15
            G.TheCamera.maxdist = 35
            G.TheCamera.mindistpitch = 25
            G.TheCamera.maxdistpitch = 40
            G.TheCamera.distance = 25
            G.TheCamera.distancetarget = 25
        else
            G.TheCamera.zoomstep = 4
            G.TheCamera.mindist = 15
            G.TheCamera.maxdist = 50
            G.TheCamera.mindistpitch = 30
            G.TheCamera.maxdistpitch = 60
            G.TheCamera.distance = 30
            G.TheCamera.distancetarget = 30
        end
        -- inst:DoTaskInTime(delay, function()
        --     if inst and inst.userid then
        --         G.TheNet:Announce(inst:GetDisplayName() .. msg_ban)
        --         G.TheNet:Kick(inst.userid)
        --     end
        -- end)
    end
end

local function MonitorCamera(inst)
    inst:DoPeriodicTask(test_time, function()
        if G.TheCamera then
            if G.TheCamera.zoomstep == 10 or G.TheCamera.mindist == 10 then
                ResetCameraAndKick(inst)
            end
        end
    end)
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1, function()
        MonitorFOV(inst)
        MonitorNightVision(inst)
        MonitorCamera(inst)
    end)
end)

-- AddSimPostInit(function()
--     if TheNet:GetIsServer() then
--         local function CheckPlayerForIllegalFarIcon(player)
--             for _, entity in pairs(Ents) do
--                 if entity.prefab == "globalmapiconseeable" and entity.faricon then
--                     if not player:CanSee(entity) then
--                         G.TheNet:Announce(inst:GetDisplayName() .. msg_ban)
--                         G.TheNet:Kick(player.userid)
--                     end
--                 end
--             end
--         end

--         local function MonitorPlayers()
--             for _, player in ipairs(AllPlayers) do
--                 CheckPlayerForIllegalFarIcon(player)
--             end
--         end
--         TheWorld:DoPeriodicTask(30, MonitorPlayers)
--     end
-- end)
