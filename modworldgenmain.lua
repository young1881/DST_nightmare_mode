GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

require("map/tasks")
require("map/lockandkey")

local Layouts = require("map/layouts").Layouts
local StaticLayout = require("map/static_layout")

-- Layouts[""]

Layouts["WalledGarden2"] = StaticLayout.Get("map/static_layouts/walledgarden2",
    {
        areas =
        {
            plants = function(area)
                return PickSomeWithDups(0.3 * area,
                    { "cave_fern", "lichen", "flower_cave", "flower_cave_double", "flower_cave_triple" })
            end,
        },
        start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
        layout_position = LAYOUT_POSITION.CENTER
    })
Layouts["Barracks3"] = StaticLayout.Get("map/static_layouts/barracks_three", {
    start_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    fill_mask = PLACE_MASK.IGNORE_IMPASSABLE_BARREN_RESERVED,
    layout_position = LAYOUT_POSITION.CENTER
})



if true then
    AddRoom("Metal_Labyrinth", { -- Not a real Labyrinth.. more of a maze really.    铁迷宫
        colour = { r = .25, g = .28, b = .25, a = .50 },
        value = WORLD_TILES.BRICK,
        tags = { "Labyrinth", "Nightmare" },
        --internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeCentroid,
        contents = {
            distributepercent = 0.15,
            distributeprefabs = {


                chessjunk_spawner = 0.1,
                spider_robot_spawner = 0.05,
                shadowdragon_spawner = 0.2,
                scanner_spawn = 0.05,
                bishop_nightmare_spawner = 0.9,
                knight_nightmare_spawner = 0.9,

                thulecite_pieces = 0.1,

                shadoweyeturret_spawner = 0.15,

                shadoweyeturret2_spawner = 0.1
            },
        }
    })

    AddRoom("HulkGuarden", {
        colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
        value = WORLD_TILES.BRICK,
        tags = { "Nightmare" },
        required_prefabs = {},
        type = NODE_TYPE.Room,
        internal_type = NODE_INTERNAL_CONNECTION_TYPE.EdgeSite,
        contents = {
            countstaticlayouts = {
                ["WalledGarden2"] = 1,
            },
            countprefabs = {
                chessjunk_spawner = function() return 4 + math.random(4) end
            }
        }
    })
    --[[locks={LOCKS.TIER4, LOCKS.RUINS,LOCKS.Sacred},
        keys_given= {KEYS.TIER5, KEYS.RUINS},]]

    AddTask("MeTal_Labyrinth_Task", {
        locks = { LOCKS.RUINS, LOCKS.SACRED },
        keys_given = { KEYS.RUINS },
        room_tags = { "Nightmare" },
        entrance_room = "LabyrinthEntrance",
        room_choices = {
            ["Metal_Labyrinth"] = function() return 3 + math.random(1) end,
            ["HulkGuarden"] = 1,
        },
        room_bg = WORLD_TILES.IMPASSABLE,
        background_room = "Metal_Labyrinth",
        colour = { r = 0.4, g = 0.4, b = 0.0, a = 1 },
    })
    AddRoom("BGMilitaryRoom", { --军事野地（存疑）
        colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
        value = WORLD_TILES.UNDERROCK,
        tags = { "Maze", "Nightmare" },
        contents = {
            distributepercent = 0.1,
            distributeprefabs =
            {
                nightmarelight = 0.25,

                scanner_spawn = 0.2,

                shadowdragon_spawner = 0.08,

                rook_nightmare_spawner = 0.09,
                knight_nightmare_spawner = 0.09,
                bishop_nightmare_spawner = 0.09,

                ruins_statue_head_spawner = .1,
                ruins_statue_mage_spawner = .1,

                chessjunk_spawner = 0.1,

                shadoweyeturret_spawner = 0.03,

                shadoweyeturret2_spawner = 0.01


            }
        }
    })
    AddRoom("MilitaryMazeRoom", {
        colour = { r = 0.3, g = 0.2, b = 0.1, a = 0.3 },
        value = WORLD_TILES.UNDERROCK,
        tags = { "Maze", "Nightmare" },
    })
    AddTaskSetPreInit("cave_default", function(task)
        task.tasks = {
            "MudWorld",
            "MudCave",
            "MudLights",
            "MudPit",

            "BigBatCave",
            "RockyLand",
            "RedForest",
            "GreenForest",
            "BlueForest",
            "SpillagmiteCaverns",

            "MoonCaveForest",
            "ArchiveMaze",

            "CaveExitTask1",
            "CaveExitTask2",
            "CaveExitTask3",
            "CaveExitTask4",
            "CaveExitTask5",
            "CaveExitTask6",
            "CaveExitTask7",
            "CaveExitTask8",
            "CaveExitTask9",
            "CaveExitTask10",

            "ToadStoolTask1",
            "ToadStoolTask2",
            "ToadStoolTask3",

            -- ruins
            "LichenLand",
            "CaveJungle",
            "Residential",
            "Military",
            "Sacred",
            "TheLabyrinth",
            "AtriumMaze",
            "MeTal_Labyrinth_Task",
        }
        task.numoptionaltasks = 6
        task.optionaltasks = {
            "SwampySinkhole",
            "CaveSwamp",
            "UndergroundForest",
            "PleasantSinkhole",
            "BatCloister",
            "RabbitTown",
            "RabbitCity",
            "SpiderLand",
            "RabbitSpiderWar"
        }
        task.set_pieces["TentaclePillar"] = {
            count = 4,
            tasks = { -- Note: An odd number because AtriumMaze contains one
                "MudWorld", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest",
                "SpillagmiteCaverns", "CaveSwamp",
            }
        }
        task.set_pieces["ResurrectionStone"] = {
            count = 2,
            tasks = {
                "MudWorld", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest",
                "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
            }
        }
        task.set_pieces["skeleton_notplayer"] = {
            count = 1,
            tasks = {
                "MudWorld", "MudLights", "MudPit", "BigBatCave", "RockyLand", "RedForest", "GreenForest", "BlueForest",
                "SpillagmiteCaverns", "SwampySinkhole", "CaveSwamp",
            }
        }
    end)

    AddTaskPreInit("Sacred", function(task)
        task.keys_given = { KEYS.RUINS, KEYS.SACRED }
        task.room_choices = {
            ["SacredBarracks"] = function() return math.random(1, 2) end,
            ["Bishops"] = function() return math.random(1, 2) end,
            ["Spiral"] = function() return math.random(1, 2) end,
            ["BrokenAltar"] = function() return math.random(1, 2) end,
            ["Altar"] = 1,
        }
        task.room_bg = WORLD_TILES.BRICK
        task.background_room = "BGSacred"
    end)

    AddTaskPreInit("Military", function(task)
        task.room_choices =
        {
            ["MilitaryMaze"] = 6,
            ["Barracks"] = 1
        }
        task.background_room = "BGMilitaryRoom"
    end)
    AddTaskPreInit("Residential", function(task)
        task.room_choices =
        {
            ["CaveJungle"] = 1,
            ["Vacant"] = 3,
        }
    end)
    AddTaskPreInit("CaveJungle", function(task)
        task.room_choices = {
            ["LichenMeadow"] = 1,
            ["CaveJungle"] = 1,
            ["Vacant"] = 1,
            ["MonkeyMeadow"] = 1,
        }
    end)
    AddRoomPreInit("RuinedCity", function(room)
        room.value = WORLD_TILES.MUD
    end)
    AddRoomPreInit("Barracks", function(room)
        room.contents.distributepercent = 0.06
    end)
    AddRoomPreInit("BGSacred", function(room) --家具野地
        room.contents.distributepercent = 0.1
        room.value = WORLD_TILES.TILES

        room.contents.distributeprefabs =
        {
            chessjunk_spawner = .2,

            nightmarelight = 0.25,

            ruins_statue_head_spawner = .1,

            shadowdragon_spawner = .09,

            rook_nightmare_spawner = .08,

            ruins_statue_mage_spawner = .1,

            knight_nightmare_spawner = .25,

            bishop_nightmare_spawner = .25,

            scanner_spawn = .09,

            shadoweyeturret_spawner = 0.09,
            shadoweyeturret2_spawner = 0.06
        }
    end)
    AddRoomPreInit("Bishops", function(room)
        room.internal_type = nil
        room.contents.countstaticlayouts = {
            ["Barracks3"] = 1,
        }
    end)

    AddRoomPreInit("MandrakeHome", function(room)
        room.internal_type = nil
        room.contents.countprefabs = {
            mandrake_planted = 1,
            mandrakehouse = 1,
        }
    end)
    Layouts["MilitaryEntrance"].layout["shadowdragon_spawner"] = { { x = -4, y = 4 } }
    Layouts["BrokenAltar"].layout["shadowdragon_spawner"] = { { x = 1, y = -4 } }
    Layouts["SacredBarracks"].layout["scanner_spawn"] = { { x = -3, y = 0 }, { x = 0, y = 0 } }
    Layouts["Barracks"].layout["scanner_spawn"] = { { x = 0, y = 0 } }
    Layouts["AltarRoom"].layout["shadowdragon_spawner"] = { { x = 0, y = 3 } }
    Layouts["MilitaryEntrance"].layout["shadoweyeturret_spawner"]={{x=3,y=3}}  --军事入口
    Layouts["BrokenAltar"].layout["shadoweyeturret_spawner"]={{x=1,y=-2}}
    Layouts["Barracks"].layout["shadoweyeturret2_spawner"] = { { x = 0, y = 0 } }
    Layouts["AltarRoom"].layout["shadoweyeturret2_spawner"] = { { x = 0, y = 1 } }
end
