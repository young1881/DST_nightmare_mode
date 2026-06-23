-- 神圣任务：按固定顺序铺房间（入口→残塔→野地↔家具交替），避免家具相邻无野地。

GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

modimport("scripts/map/sacred_terrain_meta.lua")

local Story = require("map/storygen")

local FURNITURE_ROOM_ORDER = {
    "SacredBarracks",
    "Bishops",
    "Spiral",
}

local function ResolveRoomCount(count)
    if type(count) == "function" then
        return count()
    end
    return count or 1
end

local function CloneStoryRoom(story, roomname)
    local new_room = story:GetRoom(roomname)
    assert(new_room, "Couldn't find room with name " .. roomname)
    if new_room.contents == nil then
        new_room.contents = {}
    end
    if new_room.contents.fn then
        new_room.contents.fn(new_room)
    end
    return new_room
end

local function PushStoryRoom(story, stack, roomname)
    stack:push(CloneStoryRoom(story, roomname))
end

local function BuildSacredForwardChain(task)
    local furniture = {}
    for _, roomname in ipairs(FURNITURE_ROOM_ORDER) do
        local count = task.room_choices ~= nil and task.room_choices[roomname] or nil
        if count ~= nil then
            count = ResolveRoomCount(count)
            for _ = 1, count do
                table.insert(furniture, roomname)
            end
        end
    end

    local chain = { "BrokenAltar" }
    for i, furn in ipairs(furniture) do
        local wild = (i == #furniture and math.random() < 0.23) and "SacredWildPatchLarge" or "SacredWildPatch"
        table.insert(chain, wild)
        table.insert(chain, furn)
    end
    table.insert(chain, "SacredWildPatch")
    table.insert(chain, "Altar")
    return chain
end

local function PushEntranceRoom(story, task, room_choices)
    if task.entrance_room == nil then
        return
    end
    local r = math.random()
    if task.entrance_room_chance ~= nil and task.entrance_room_chance <= r then
        return
    end
    if type(task.entrance_room) == "table" then
        task.entrance_room = GetRandomItem(task.entrance_room)
    end
    local new_room = story:GetRoom(task.entrance_room)
    assert(new_room, "Couldn't find entrance room with name " .. tostring(task.entrance_room))
    if new_room.contents == nil then
        new_room.contents = {}
    end
    if new_room.contents.fn then
        new_room.contents.fn(new_room)
    end
    new_room.entrance = true
    room_choices:push(new_room)
end

local function FinishNodesFromRoomStack(story, task, crossLinkFactor, starting_node_name, room_choices)
    local task_node = Graph(task.id, {
        parent = story.rootNode,
        default_bg = task.room_bg,
        colour = task.colour,
        background = task.background_room,
        set_pieces = task.set_pieces,
        random_set_pieces = task.random_set_pieces,
        maze_tiles = task.maze_tiles,
        maze_tile_size = task.maze_tile_size,
        room_tags = task.room_tags,
        required_prefabs = task.required_prefabs,
    })
    task_node.substitutes = task.substitutes

    WorldSim:AddChild(story.rootNode.id, task.id, task.room_bg, task.colour.r, task.colour.g, task.colour.b, task.colour.a)

    local newNode = nil
    local prevNode = nil
    local roomID = 0
    local hub_node = nil
    local starting_node_picked = false

    while room_choices:getn() > 0 do
        local next_room = room_choices:pop()
        local is_starting_room = starting_node_name == next_room.name and not starting_node_picked

        if is_starting_room then
            print("Found starting task " .. task.id .. ", picked existing room " .. next_room.name)
            starting_node_picked = true
            next_room.id = "START"
        else
            next_room.id = task.id .. ":" .. roomID .. ":" .. next_room.name
        end

        next_room.task = task.id
        story:RunTaskSubstitution(task, next_room.contents.distributeprefabs)

        local extra_contents, extra_tags = story:GetExtrasForRoom(next_room)
        local next_room_data = {
            type = next_room.entrance and NODE_TYPE.Blocker or next_room.type,
            task = next_room.task,
            name = next_room.name,
            colour = next_room.colour,
            value = next_room.value,
            internal_type = next_room.internal_type,
            tags = ArrayUnion(extra_tags, task.room_tags),
            custom_tiles = next_room.custom_tiles,
            custom_objects = next_room.custom_objects,
            terrain_contents = next_room.contents,
            terrain_contents_extra = extra_contents,
            terrain_filter = story.terrain.filter,
            entrance = next_room.entrance,
            required_prefabs = next_room.required_prefabs,
            random_node_exit_weight = next_room.random_node_exit_weight,
            random_node_entrance_weight = next_room.random_node_entrance_weight,
            SafeFromDisconnect = next_room.SafeFromDisconnect,
        }

        if is_starting_room then
            next_room_data.name = "START"
            next_room_data.colour = { r = 0, g = 1, b = 1, a = .80 }
            next_room_data.random_node_exit_weight = 0
            next_room_data.random_node_entrance_weight = 0
            story:AddStartingSetPiece(next_room_data)
        end

        newNode = task_node:AddNode({
            id = next_room.id,
            data = next_room_data,
        })

        if task.hub_room ~= nil and hub_node == nil and next_room.name == task.hub_room then
            hub_node = newNode
            hub_node.data.random_node_exit_weight = 0
            hub_node.data.random_node_entrance_weight = 0
        end

        if task.hub_room == nil or task.make_loop then
            if newNode ~= hub_node then
                if prevNode then
                    task_node:AddEdge({ node1id = newNode.id, node2id = prevNode.id })
                end
                prevNode = newNode
            end
        end
        roomID = roomID + 1
    end

    if task.make_loop then
        task_node:MakeLoop()
    end

    if hub_node ~= nil then
        task_node:MakeHub(hub_node.id)
    end

    if crossLinkFactor then
        task_node:CrosslinkRandom(crossLinkFactor)
    end

    return task_node
end

local _GenerateNodesFromTask = Story.GenerateNodesFromTask

Story.GenerateNodesFromTask = function(self, task, crossLinkFactor, starting_node_name)
    if task.id ~= "Sacred" then
        return _GenerateNodesFromTask(self, task, crossLinkFactor, starting_node_name)
    end

    RecordSacredLayoutInstalled()
    RecordSacredLayoutApplied()

    local room_choices = Stack:Create()
    PushEntranceRoom(self, task, room_choices)

    local forward_chain = BuildSacredForwardChain(task)
    for i = #forward_chain, 1, -1 do
        PushStoryRoom(self, room_choices, forward_chain[i])
    end

    return FinishNodesFromRoomStack(self, task, crossLinkFactor, starting_node_name, room_choices)
end

-- 仅内存标记：表示脚本已挂载（modimport 时安全，不写 TheSim）
RecordSacredLayoutInstalled()
print("[SacredTaskLayout] ordered room chain installed")
