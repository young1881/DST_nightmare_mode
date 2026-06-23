-- roge/roll.lua

-- ====== 常量（骰子 / 召唤） ======
-- 掷骰与召唤共用同一冷却秒数（TUNING.DICE_ROLL_COOLDOWN / 服务端 _dicespawncd）
ROGE_DICE_SHARED_COOLDOWN = 100
TUNING.DICE_ROLL_COOLDOWN = ROGE_DICE_SHARED_COOLDOWN
DICE_SPAWN_COOLDOWN = ROGE_DICE_SHARED_COOLDOWN
ROGE_SHIFT_Y_SUMMON_COOLDOWN = 200
ROGE_SHIFT_Y_SUMMON_POOL = { "mandrakeman", "spat", "lunar_grazer", "deer_blue" }
-- Shift+U：第8天起可用；首次召唤 CD 100-300s，用过一次后固定 500s
ROGE_SHIFT_U_SUMMON_MIN_CYCLES = 7
ROGE_SHIFT_U_SUMMON_CD_FIRST_MIN = 100
ROGE_SHIFT_U_SUMMON_CD_FIRST_MAX = 300
ROGE_SHIFT_U_SUMMON_CD_STEADY = 500

-- 怪物池解锁（cycles 0=第1天；time>=0.5=黄昏/入夜段；入夜后永久有效）
ROGE_DICE_DUSK_TIME = 0.5
ROGE_DICE_ZERO_ONLY_CYCLES = 1
ROGE_DICE_DAY25_MIN_CYCLES = 1        -- 第2天黄昏：弱怪池（0-50）
ROGE_DICE_DAY25_MIN_TIME = ROGE_DICE_DUSK_TIME
ROGE_DICE_DAY3_D80_MIN_CYCLES = 2       -- 第3天黄昏：强怪池 d80
ROGE_DICE_DAY3_D80_MIN_TIME = 0.5
ROGE_DICE_LARGE_BOSS_MIN_CYCLES = 4   -- 第5天起：Boss 池 + d100
ROGE_DICE_NORMAL_TO_ELITE_MIN_CYCLES = 5 -- 第6天起：1-50% 改强怪池
ROGE_UNLOCK_DAY8_HEALTH_DAY = 8
ROGE_SHIFT_Y_SUMMON_MIN_DAY = 6
ROGE_DICE_DAY2_MAX = 50
DEFAULT_DICE_SIDES = 100
ROGE_DAY8_HEALTH_MULT = 1.5
-- 分位�?50 普通�?80 精英、其�?20% 巨型�?=80�?local DICE_PCT_NORMAL_MAX = 50
DICE_PCT_NORMAL_MAX = 50
DICE_PCT_ELITE_MAX = 80

-- ====== 天数规则（cycles + 黄昏） ======

function RogeWorldCycles()
	if TheWorld == nil or TheWorld.state == nil then
		return 0
	end
	return TheWorld.state.cycles
end

function RogeGetClockDay()
	if TheWorld == nil then
		return 1
	end
	if TheWorld.net ~= nil and TheWorld.net.components.clock ~= nil
		and TheWorld.net.components.clock.GetNumDays ~= nil then
		return TheWorld.net.components.clock:GetNumDays()
	end
	if TheWorld.state ~= nil and TheWorld.state.cycles ~= nil then
		return TheWorld.state.cycles + 1
	end
	return 1
end

function RogeWorldTime()
	if TheWorld == nil or TheWorld.state == nil or TheWorld.state.time == nil then
		return 0
	end
	return TheWorld.state.time
end

function RogeIsUnlockedAtCycleDusk(min_cycles, min_time)
	min_time = min_time or ROGE_DICE_DUSK_TIME
	local cycles = RogeWorldCycles()
	if cycles > min_cycles then
		return true
	end
	if cycles < min_cycles then
		return false
	end
	return RogeWorldTime() >= min_time
end

function IsDiceDay25WeakUnlocked()
	local cycles = RogeWorldCycles()
	if cycles > ROGE_DICE_DAY25_MIN_CYCLES then
		return false
	end
	if cycles < ROGE_DICE_DAY25_MIN_CYCLES then
		return false
	end
	return RogeWorldTime() >= ROGE_DICE_DAY25_MIN_TIME
end

function IsDiceDay3D80Unlocked()
	return RogeIsUnlockedAtCycleDusk(ROGE_DICE_DAY3_D80_MIN_CYCLES, ROGE_DICE_DAY3_D80_MIN_TIME)
end

function IsWeakPoolUnlocked()
	local cycles = RogeWorldCycles()
	if cycles < ROGE_DICE_DAY25_MIN_CYCLES then
		return false
	end
	if cycles > ROGE_DICE_DAY25_MIN_CYCLES then
		return true
	end
	return RogeWorldTime() >= ROGE_DICE_DAY25_MIN_TIME
end

function IsElitePoolUnlocked()
	return IsDiceDay3D80Unlocked()
end

function IsBossPoolUnlocked()
	return RogeWorldCycles() >= ROGE_DICE_LARGE_BOSS_MIN_CYCLES
end

function IsDiceZeroOnlyPhase()
	if RogeWorldCycles() < ROGE_DICE_ZERO_ONLY_CYCLES then
		return true
	end
	if RogeWorldCycles() == ROGE_DICE_DAY25_MIN_CYCLES and not IsDiceDay25WeakUnlocked() then
		return true
	end
	return false
end

-- 1-50 弱怪池：第 2 天黄昏起，至第 3 天黄昏前
function IsDiceWeakPoolOnlyPhase()
	if IsDiceDay25WeakUnlocked() then
		return true
	end
	local cycles = RogeWorldCycles()
	if cycles == ROGE_DICE_DAY3_D80_MIN_CYCLES and RogeWorldTime() < ROGE_DICE_DAY3_D80_MIN_TIME then
		return true
	end
	return false
end

function GetDiceCapForWorld()
	if IsDiceZeroOnlyPhase() then
		return 0
	end
	if not IsElitePoolUnlocked() then
		return ROGE_DICE_DAY2_MAX
	end
	if not IsBossPoolUnlocked() then
		return DICE_PCT_ELITE_MAX
	end
	return DEFAULT_DICE_SIDES
end

function IsLargeBossDiceUnlocked()
	return IsBossPoolUnlocked()
end

function IsNormalPoolReplacedByElite()
	return RogeWorldCycles() >= ROGE_DICE_NORMAL_TO_ELITE_MIN_CYCLES
end

function RogeGetDay8HealthMult()
	return RogeGetClockDay() >= ROGE_UNLOCK_DAY8_HEALTH_DAY and ROGE_DAY8_HEALTH_MULT or 1
end

function IsShiftUSummonUnlocked()
	return RogeWorldCycles() >= ROGE_SHIFT_U_SUMMON_MIN_CYCLES
end

function RogeShiftUSummonCooldownSeconds(player)
	if player ~= nil and player._roge_shift_u_used_once then
		return ROGE_SHIFT_U_SUMMON_CD_STEADY
	end
	return ROGE_SHIFT_U_SUMMON_CD_FIRST_MIN
		+ math.random() * (ROGE_SHIFT_U_SUMMON_CD_FIRST_MAX - ROGE_SHIFT_U_SUMMON_CD_FIRST_MIN)
end

function RogeScaleAdjustedMaxHealth(inst, base_hp)
	if inst == nil or inst.components.health == nil or inst.components.health:IsDead() then
		return
	end
	local mult = RogeGetDay8HealthMult()
	local hp = math.max(1, math.floor((base_hp or inst.components.health.maxhealth) * mult))
	local pct = inst.components.health:GetPercent()
	inst.components.health:SetMaxHealth(hp)
	inst.components.health:SetPercent(pct)
end

function GetCurrentDiceMaxSides()
	return GetDiceCapForWorld()
end

-- Boss 池未解锁时：若误掷 d100，将点数与面数压至 d80
function NormalizeDiceRollForSpawn(roll_result, max_sides)
	local cap = GetDiceCapForWorld()
	if cap <= 0 then
		return roll_result, max_sides
	end
	max_sides = max_sides or DEFAULT_DICE_SIDES
	if max_sides > cap then
		roll_result = math.min(roll_result, cap)
		max_sides = cap
	elseif roll_result > cap then
		roll_result = cap
	end
	return roll_result, max_sides
end

function ApplyDiceRollWorldRules(roll_result, max_sides)
	if IsDiceZeroOnlyPhase() then
		return 0, ROGE_DICE_DAY2_MAX
	end

	roll_result, max_sides = NormalizeDiceRollForSpawn(roll_result, max_sides)

	local cap = GetDiceCapForWorld()
	if cap > 0 then
		max_sides = cap
		roll_result = math.clamp(roll_result, 1, cap)
	end

	return roll_result, max_sides
end

-- ====== dice_rpc ======
-- ====== 服务�?RPC 注册 ======
AddModRPCHandler("dice_spawn", "spawn_creature", function(player, roll_result, max_sides)
    TrySpawnDiceCreature(player, roll_result, max_sides)
end)

local RPC_SPAWN = GetModRPC("dice_spawn", "spawn_creature")

-- Shift+T：_dicerollcooldown + TheNet:DiceRoll；前六天�?80 面，之后 100 面；并拉取服务端召唤冷却显示文本
AddClientModRPCHandler("dice_spawn", "cd_tip", function(spawn_sec, just_rolled)
    local p = ThePlayer
    if p == nil or not p:IsValid() or p.components.talker == nil then
        return
    end
    local t = GetTime()
    local roll_rem = math.max(0, (p._dicerollcooldown or 0) - t)
    local roll_sec = math.max(0, math.ceil(roll_rem - 1e-4))
    local sp = math.max(0, tonumber(spawn_sec) or 0)
    local jr = tonumber(just_rolled) or 0
    local dice_max = GetCurrentDiceMaxSides()
    local prefix = (jr == 1) and (
        dice_max <= 0 and "Rolled(0) - " or string.format("Rolled(1-%d) - ", dice_max)
    ) or ""
    p.components.talker:Say(string.format("%sroll cd %ds - spawn cd %ds", prefix, roll_sec, sp))
end)

AddModRPCHandler("dice_spawn", "get_cd_tip", function(player, just_rolled)
    if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
        return
    end
    local t = GetTime()
    local sp = 0
    if player._dicespawncd ~= nil and t < player._dicespawncd then
        sp = math.max(0, math.ceil(player._dicespawncd - t - 1e-4))
    end
    local jr = tonumber(just_rolled) or 0
    SendModRPCToClient(GetClientModRPC("dice_spawn", "cd_tip"), player.userid, sp, jr)
end)

local RPC_GET_CD_TIP = GetModRPC("dice_spawn", "get_cd_tip")

function RogeTryShiftTDiceRoll()
    if GLOBAL.ThePlayer == nil or not GLOBAL.ThePlayer:IsValid() then
        return
    end
    local p = GLOBAL.ThePlayer
    local just = 0
    local t = GLOBAL.GetTime()
    if t > (p._dicerollcooldown or 0) then
        p._dicerollcooldown = t + GLOBAL.TUNING.DICE_ROLL_COOLDOWN
        local dice_sides = GetCurrentDiceMaxSides()
        if dice_sides > 0 then
            GLOBAL.TheNet:DiceRoll(dice_sides, 1)
        else
            -- 第 1 天：掷骰结果由 ApplyDiceRollWorldRules 强制为 0
            GLOBAL.TheNet:DiceRoll(1, 1)
        end
        just = 1
    end
    GLOBAL.SendModRPCToServer(RPC_GET_CD_TIP, just)
end

local _roge_shift_t_registered = false
function RogeRegisterShiftTDice()
    if _roge_shift_t_registered or GLOBAL.TheInput == nil then
        return
    end
    _roge_shift_t_registered = true
    GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_T, function()
        if GLOBAL.ThePlayer == nil or not GLOBAL.ThePlayer:IsValid() or GLOBAL.TheInput == nil then
            return
        end
        local inp = GLOBAL.TheInput
        if not (inp:IsKeyDown(GLOBAL.KEY_LSHIFT) or inp:IsKeyDown(GLOBAL.KEY_RSHIFT) or inp:IsKeyDown(GLOBAL.KEY_SHIFT)) then
            return
        end
        RogeTryShiftTDiceRoll()
    end)
end

if GLOBAL.TheInput ~= nil then
    RogeRegisterShiftTDice()
else
    GLOBAL.AddSimPostInit(function()
        RogeRegisterShiftTDice()
    end)
end

AddClientModRPCHandler("roge_mandrakeman", "tip", function(ok, rem_sec)
	local p = GLOBAL.ThePlayer
	if p == nil or not p:IsValid() or p.components.talker == nil then
		return
	end
	local c = tonumber(ok) or 0
	if c == 1 then
		p.components.talker:Say("召唤成功")
	elseif c == 2 then
		p.components.talker:Say("第6天起才能使用 Shift+Y 召唤")
	else
		local rem = math.max(0, tonumber(rem_sec) or 0)
		p.components.talker:Say(string.format("召唤冷却 %ds", rem))
	end
end)

AddModRPCHandler("roge_mandrakeman", "summon", function(player)
	if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
		return
	end
	local code, rem = TrySpawnShiftYSummon(player)
	SendModRPCToClient(GetClientModRPC("roge_mandrakeman", "tip"), player.userid, code, rem)
end)

local RPC_SUMMON_MANDRAKEMAN = GetModRPC("roge_mandrakeman", "summon")

function RogeTryShiftYSummon()
    GLOBAL.SendModRPCToServer(RPC_SUMMON_MANDRAKEMAN)
end

local _roge_shift_y_registered = false
function RogeRegisterShiftYMandrakeman()
	if _roge_shift_y_registered or GLOBAL.TheInput == nil then
		return
	end
	_roge_shift_y_registered = true
	GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_Y, function()
		if GLOBAL.ThePlayer == nil or not GLOBAL.ThePlayer:IsValid() or GLOBAL.TheInput == nil then
			return
		end
		local inp = GLOBAL.TheInput
		if not (inp:IsKeyDown(GLOBAL.KEY_LSHIFT) or inp:IsKeyDown(GLOBAL.KEY_RSHIFT) or inp:IsKeyDown(GLOBAL.KEY_SHIFT)) then
			return
		end
		RogeTryShiftYSummon()
	end)
end

if GLOBAL.TheInput ~= nil then
	RogeRegisterShiftYMandrakeman()
else
	GLOBAL.AddSimPostInit(function()
		RogeRegisterShiftYMandrakeman()
	end)
end

AddClientModRPCHandler("roge_mandrakeman", "tip_u", function(ok, rem_sec)
	local p = GLOBAL.ThePlayer
	if p == nil or not p:IsValid() or p.components.talker == nil then
		return
	end
	local c = tonumber(ok) or 0
	if c == 1 then
		p.components.talker:Say("Boss 召唤成功")
	elseif c == 2 then
		p.components.talker:Say("第8天起才能使用 Shift+U 召唤 Boss")
	else
		local rem = math.max(0, tonumber(rem_sec) or 0)
		p.components.talker:Say(string.format("Boss 召唤冷却 %ds", rem))
	end
end)

AddModRPCHandler("roge_mandrakeman", "summon_u", function(player)
	if TheWorld == nil or not TheWorld.ismastersim or player == nil or not player:IsValid() then
		return
	end
	local code, rem = TrySpawnShiftUSummon(player)
	SendModRPCToClient(GetClientModRPC("roge_mandrakeman", "tip_u"), player.userid, code, rem)
end)

local RPC_SUMMON_BOSS_U = GetModRPC("roge_mandrakeman", "summon_u")

function RogeTryShiftUSummon()
    GLOBAL.SendModRPCToServer(RPC_SUMMON_BOSS_U)
end

local _roge_shift_u_registered = false
function RogeRegisterShiftUBossSummon()
	if _roge_shift_u_registered or GLOBAL.TheInput == nil then
		return
	end
	_roge_shift_u_registered = true
	GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_U, function()
		if GLOBAL.ThePlayer == nil or not GLOBAL.ThePlayer:IsValid() or GLOBAL.TheInput == nil then
			return
		end
		local inp = GLOBAL.TheInput
		if not (inp:IsKeyDown(GLOBAL.KEY_LSHIFT) or inp:IsKeyDown(GLOBAL.KEY_RSHIFT) or inp:IsKeyDown(GLOBAL.KEY_SHIFT)) then
			return
		end
		RogeTryShiftUSummon()
	end)
end

if GLOBAL.TheInput ~= nil then
	RogeRegisterShiftUBossSummon()
else
	GLOBAL.AddSimPostInit(function()
		RogeRegisterShiftUBossSummon()
	end)
end

-- ====== Hook 骰子结果广播 ======
local OldRollAnnouncement = nil

function OnDiceResult(userid, rolls, max)
    local my_uid = TheNet:GetUserID()
    if my_uid == nil or userid ~= my_uid then return end
    if rolls == nil or #rolls == 0 then return end

    local roll_result = rolls[1]
    local max_sides = max or DEFAULT_DICE_SIDES
    roll_result, max_sides = ApplyDiceRollWorldRules(roll_result, max_sides)
    rolls[1] = roll_result

    local player = ThePlayer
    if TheWorld ~= nil and TheWorld.ismastersim then
        if player then
            TrySpawnDiceCreature(player, roll_result, max_sides)
        end
    else
        SendModRPCToServer(RPC_SPAWN, roll_result, max_sides)
    end
end

function TryHook()
    -- 用GLOBAL.rawget直读_G, 因为Networking_RollAnnouncement可能尚未加载
    OldRollAnnouncement = GLOBAL.rawget(GLOBAL, "Networking_RollAnnouncement")
    if OldRollAnnouncement == nil then
        return false
    end
    GLOBAL.Networking_RollAnnouncement = function(userid, name, prefab, colour, rolls, max)
        if rolls ~= nil and #rolls > 0 then
            local adjusted_roll, adjusted_max = ApplyDiceRollWorldRules(rolls[1], max)
            rolls = { adjusted_roll }
            max = adjusted_max
        end
        OldRollAnnouncement(userid, name, prefab, colour, rolls, max)
        OnDiceResult(userid, rolls, max)
    end
    return true
end

if not TryHook() then
    AddSimPostInit(TryHook)
end
