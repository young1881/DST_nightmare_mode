-- 游戏内确认进阶地形是否成功启用：聊天输入 /nmchecksacred

modimport("scripts/map/sacred_terrain_meta.lua")

local COMMAND = "nmchecksacred"

local function FindPlayerByUserId(userid)
    if userid == nil or userid == "" then
        return nil
    end
    for _, player in ipairs(AllPlayers) do
        if player.userid == userid then
            return player
        end
    end
    return nil
end

local function SayLinesToPlayer(player, lines)
    if player == nil or player.components.talker == nil then
        return
    end
    for i, line in ipairs(lines) do
        player:DoTaskInTime((i - 1) * 2.2, function()
            if player:IsValid() and player.components.talker ~= nil then
                player.components.talker:Say(line)
            end
        end)
    end
end

local function RunSacredTerrainCheck(params, caller)
    local lines = BuildSacredTerrainStatusLines()
    local player = FindPlayerByUserId(caller)

    if player ~= nil then
        SayLinesToPlayer(player, lines)
    end

    for _, line in ipairs(lines) do
        print("[NM_SACRED_CHECK]", line)
    end

    if TheNet ~= nil and TheNet.SystemMessage ~= nil then
        TheNet:SystemMessage(lines[#lines])
    end
end

AddUserCommand(COMMAND, {
    prettyname = "检查进阶地形",
    desc = "确认神圣区固定房间链与野地挖洞是否已启用",
    permission = COMMAND_PERMISSION.USER,
    slash = true,
    usermenu = false,
    servermenu = false,
    params = {},
    vote = false,
    canstartfn = function()
        return true
    end,
    serverfn = RunSacredTerrainCheck,
})

AddPrefabPostInit("world", function(inst)
    if not TheWorld.ismastersim or not TheWorld:HasTag("cave") then
        return
    end
    inst:DoTaskInTime(3, function()
        local lines = BuildSacredTerrainStatusLines()
        for _, line in ipairs(lines) do
            print("[NM_SACRED_CHECK]", line)
        end
    end)
end)
