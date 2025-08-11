TUNING.CHARLIE_STAGE_RESET_TIME = 480
TUNING.CHARLIE_STAGE_RESET_TIME_VARIABLE = 480

local REWARDPOOL = {
    { name = "miner",    "goldenpickaxe",             "minerhat",                 "lantern" },
    { name = "farmer",   "premiumwateringcan",        "golden_farm_hoe",          "farm_plow_item" },
    { name = "fisher",   "oceanfishingrod",           "oceanfishingbobber_ball",  "oceanfishinglure_hermit_heavy" },
    { name = "hiker",    "goldenaxe",                 "backpack",                 "goldenshovel" },
    { name = "hunter",   "hambat",                    "armorwood",                "footballhat" },
    { name = "weather",  "yellowstaff",               "meat_dried",               "umbrella" },
    { name = "tailor",   "tophat",                    "sewing_kit",               "spidereggsack" },
    { name = "winter",   "heatrock",                  "cane",                     "walrushat" },
    { name = "builder",  "turf_ruinsbrick_blueprint", "turf_ruinstrim_blueprint", "turf_cotl_gold_blueprint" },
    { name = "loser",    "winter_food4",              "trinket_24",               "trinket_35" },
    { name = "chessser", "trinket_15",                "trinket_28",               "trinket_30" }
}

local function OnPlayPerformed(inst, data)
    if not data.next and not data.error then
        local REWARDS = inst._rewardpool[math.random(1, #inst._rewardpool)]
        local theta = math.random() * TWOPI
        for _, reward in ipairs(REWARDS) do -- NOTES(JBK): Keep this ipairs because rewards metadata is being stored in the table.
            inst:DoTaskInTime(1 + (math.random() * 2), spawnhound, reward, theta)
            theta = theta + PI / 6
        end
        inst.components.stageactingprop:DisableProp(TUNING.CHARLIE_STAGE_RESET_TIME +
            (math.random() * TUNING.CHARLIE_STAGE_RESET_TIME_VARIABLE))
    end
end

AddPrefabPostInit("charlie_stage_post", function(inst)
    if not TheWorld.ismastersim then
        return
    end
    inst._rewardpool = REWARDPOOL
    inst:ListenForEvent("play_performed", OnPlayPerformed)
end)
