-- 进阶地形：世界生成阶段写入记录，进游戏后通过 TheSim:GetPersistentString 读取。

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local META_KEY = "nm_sacred_terrain_v1"

local function DefaultStats()
    return {
        layout_installed = false,
        layout_applied = false,
        void_patch_installed = false,
        void_tiles_carved = 0,
        void_sites = 0,
    }
end

local stats = DefaultStats()

local function EncodeStats(s)
    return string.format(
        "layout_installed=%s;layout_applied=%s;void_patch_installed=%s;void_tiles=%d;void_sites=%d",
        tostring(s.layout_installed),
        tostring(s.layout_applied),
        tostring(s.void_patch_installed),
        s.void_tiles_carved or 0,
        s.void_sites or 0
    )
end

local function DecodeStats(str)
    if str == nil or str == "" then
        return nil
    end
    local s = DefaultStats()
    for pair in string.gmatch(str, "[^;]+") do
        local k, v = pair:match("^([^=]+)=(.+)$")
        if k == "layout_installed" then
            s.layout_installed = v == "true"
        elseif k == "layout_applied" then
            s.layout_applied = v == "true"
        elseif k == "void_patch_installed" then
            s.void_patch_installed = v == "true"
        elseif k == "void_tiles" then
            s.void_tiles_carved = tonumber(v) or 0
        elseif k == "void_sites" then
            s.void_sites = tonumber(v) or 0
        end
    end
    return s
end

local function CacheSacredTerrainStats()
    rawset(GLOBAL, "NM_SACRED_TERRAIN_STATS", stats)
end

local function PersistSacredTerrainMeta()
    local encoded = EncodeStats(stats)
    CacheSacredTerrainStats()

    local sd = rawget(GLOBAL, "SaveData")
    if sd ~= nil then
        sd.meta = sd.meta or {}
        sd.meta.nm_sacred_terrain = encoded
    end

    if TheSim ~= nil and TheSim.SetPersistentString ~= nil and TheWorld ~= nil then
        TheSim:SetPersistentString(META_KEY, encoded, false)
    end
end

local function UpdateSacredTerrainMeta(persist)
    CacheSacredTerrainStats()
    if persist then
        PersistSacredTerrainMeta()
    end
end

function RecordSacredLayoutInstalled()
    stats.layout_installed = true
    UpdateSacredTerrainMeta(false)
end

function RecordSacredLayoutApplied()
    stats.layout_applied = true
    UpdateSacredTerrainMeta(true)
end

function RecordSacredWildVoidInstalled()
    stats.void_patch_installed = true
    UpdateSacredTerrainMeta(false)
end

function RecordSacredWildVoidCarved(total_tiles, site_count)
    stats.void_tiles_carved = (stats.void_tiles_carved or 0) + (total_tiles or 0)
    stats.void_sites = math.max(stats.void_sites or 0, site_count or 0)
    UpdateSacredTerrainMeta(true)
end

function LoadSacredTerrainMetaFromPersistent()
    local cached = rawget(GLOBAL, "NM_SACRED_TERRAIN_STATS")
    if cached ~= nil then
        return cached
    end

    local sd = rawget(GLOBAL, "SaveData")
    if sd ~= nil and sd.meta ~= nil and sd.meta.nm_sacred_terrain ~= nil and sd.meta.nm_sacred_terrain ~= "" then
        local decoded = DecodeStats(sd.meta.nm_sacred_terrain)
        rawset(GLOBAL, "NM_SACRED_TERRAIN_STATS", decoded)
        return decoded
    end

    if TheSim ~= nil and TheSim.GetPersistentString ~= nil then
        local ok, str = TheSim:GetPersistentString(META_KEY, false)
        if ok and str ~= nil and str ~= "" then
            local decoded = DecodeStats(str)
            rawset(GLOBAL, "NM_SACRED_TERRAIN_STATS", decoded)
            return decoded
        end
    end
    return nil
end

function BuildSacredTerrainStatusLines()
    local lines = { "【3350 进阶地形检测】" }
    local saved = LoadSacredTerrainMetaFromPersistent()

    if saved == nil then
        table.insert(lines, "未找到生成记录：请确认已用本模组开新世界（洞穴）。")
        table.insert(lines, "旧存档或未重开世界时无法写入记录。")
        return lines
    end

    local layout_ok = saved.layout_installed and saved.layout_applied
    local void_ok = saved.void_patch_installed and saved.void_tiles_carved > 0

    table.insert(lines, string.format(
        "神圣区固定房间链：%s（脚本=%s，已应用=%s）",
        layout_ok and "已启用" or "未确认",
        saved.layout_installed and "是" or "否",
        saved.layout_applied and "是" or "否"
    ))
    table.insert(lines, string.format(
        "神圣野地挖洞：%s（脚本=%s，镂空地皮=%d，野地=%d）",
        void_ok and "已启用" or "未确认",
        saved.void_patch_installed and "是" or "否",
        saved.void_tiles_carved or 0,
        saved.void_sites or 0
    ))

    if layout_ok and void_ok then
        table.insert(lines, "结论：两项进阶地形均已成功启用。")
    else
        table.insert(lines, "结论：至少一项未生效，请查看开世界时的服务器日志。")
        table.insert(lines, "日志关键字：[SacredTaskLayout] / [SacredWildVoid]")
    end

    return lines
end
