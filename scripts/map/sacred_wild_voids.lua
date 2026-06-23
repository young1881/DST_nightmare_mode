-- 神圣野地内部镂空：刷怪完成后在野地内部挖 3~5 块约 4~6 地皮宽的洞。

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

modimport("scripts/map/sacred_terrain_meta.lua")

local VOID_TILE = WORLD_TILES.IMPASSABLE

local VOID_COUNT_MIN = 3
local VOID_COUNT_MAX = 5
local VOID_WIDTH_MIN = 4
local VOID_WIDTH_MAX = 6
local MIN_VOID_CELLS = 6
local FILL_RATIO = 0.70
local LARGE_WILD_EXTRA_VOIDS = 1
local LARGE_WILD_AREA_THRESHOLD = 120

local function IsSacredWildPatchNode(node)
    if node == nil or node.data == nil then
        return false
    end
    local name = node.data.name
    return name == "SacredWildPatch" or name == "SacredWildPatchLarge"
end

local function IsLargeWildNode(node, point_count)
    if node ~= nil and node.data ~= nil and node.data.name == "SacredWildPatchLarge" then
        return true
    end
    return (point_count or 0) >= LARGE_WILD_AREA_THRESHOLD
end

local function PickVoidIndicesFromBox(points_x, points_y, in_box, target_count, used)
    local pool = {}
    for _, idx in ipairs(in_box) do
        local key = points_x[idx] .. ":" .. points_y[idx]
        if not used[key] then
            table.insert(pool, idx)
        end
    end
    pool = shuffleArray(pool)
    local picked = {}
    for i = 1, math.min(target_count, #pool) do
        local idx = pool[i]
        local key = points_x[idx] .. ":" .. points_y[idx]
        used[key] = true
        table.insert(picked, idx)
    end
    return picked
end

local function CarveVoidSite(node_id, node, used_global)
    local points_x, points_y = WorldSim:GetPointsForSite(node_id)
    if points_x == nil or #points_x == 0 then
        return 0
    end

    local point_count = #points_x
    local void_count = math.random(VOID_COUNT_MIN, VOID_COUNT_MAX)
    if IsLargeWildNode(node, point_count) then
        void_count = void_count + LARGE_WILD_EXTRA_VOIDS
    end

    local carved = 0
    for _ = 1, void_count do
        local width = math.random(VOID_WIDTH_MIN, VOID_WIDTH_MAX)
        local target_cells = math.max(MIN_VOID_CELLS, math.floor(width * width * FILL_RATIO))

        local center_idx = math.random(1, point_count)
        local cx, cy = points_x[center_idx], points_y[center_idx]

        local in_box = {}
        for i = 1, point_count do
            if math.abs(points_x[i] - cx) <= width and math.abs(points_y[i] - cy) <= width then
                table.insert(in_box, i)
            end
        end
        if #in_box == 0 then
            for i = 1, point_count do
                table.insert(in_box, i)
            end
        end

        local picked = PickVoidIndicesFromBox(points_x, points_y, in_box, target_cells, used_global)
        for _, idx in ipairs(picked) do
            WorldSim:SetTile(points_x[idx], points_y[idx], VOID_TILE)
            carved = carved + 1
        end
    end

    return carved
end

local function FindSacredGraph(root_graph)
    if root_graph == nil or root_graph.GetChildren == nil then
        return nil
    end
    for id, child in pairs(root_graph:GetChildren()) do
        if id == "Sacred" then
            return child
        end
    end
    return nil
end

local function CarveSacredWilderness(root_graph, entities, width, height)
    local sacred_graph = FindSacredGraph(root_graph)
    if sacred_graph == nil then
        return
    end

    local total = 0
    local wild_patch_sites = 0
    local used_global = {}

    for _, node in pairs(sacred_graph:GetNodes(false)) do
        if IsSacredWildPatchNode(node) then
            wild_patch_sites = wild_patch_sites + 1
            total = total + CarveVoidSite(node.id, node, used_global)
        end
    end

    print(string.format("[SacredWildVoid] Sacred task carved %d tiles total", total))
    RecordSacredWildVoidCarved(total, wild_patch_sites)
end

local function InstallSacredWildVoidPatch()
    if Graph == nil or Graph.GlobalPostPopulate == nil then
        print("[SacredWildVoid] Graph.GlobalPostPopulate missing, patch skipped")
        return
    end
    if Graph._nm_sacred_wild_void_patch then
        return
    end
    Graph._nm_sacred_wild_void_patch = true

    local _GlobalPostPopulate = Graph.GlobalPostPopulate
    function Graph:GlobalPostPopulate(entities, width, height)
        _GlobalPostPopulate(self, entities, width, height)
        CarveSacredWilderness(self, entities, width, height)
    end

    print("[SacredWildVoid] patch installed")
    RecordSacredWildVoidInstalled()
end

InstallSacredWildVoidPatch()
