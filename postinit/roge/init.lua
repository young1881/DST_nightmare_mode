-- 骰子肉鸽 (roge) 模块入口
GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

local ROGE_MODULES = {
	"roll",              -- 骰子常量、天数规则、RPC
	"dice_hud_buttons",  -- 韦伯 HUD 骰子按钮
	"void_protection",   -- 洞穴虚空保护：海象/钢羊/宝石无眼鹿（须在 boss_pool 之前）
	"dice_summon_neutral", -- 骰子召唤：非玩家生物不主动索敌
	"boss_pool",         -- 怪物池、Boss 血量、各类召唤包
	"shadow_rook",       -- 暗影战车连续闪现啃咬（须在 boss_pool 之后）
	"crab_knight",       -- 弱怪池蟹骑士（满宝石、寄生炮塔）
	"walrus_squad",      -- 海象家族 Boss 召唤包（须在 boss_pool 之后）
	"merm_guard_pack",   -- 精英池鱼人守卫三连（须在 boss_pool 之后）
	"pigelite_squad",    -- 精英猪人举牌组 x2（须在 boss_pool 之后）
	"daywalker2_roge",   -- 拾荒疯猪 Boss 池（须在 boss_pool 之后）
	"ghost",             -- 作祟附身限制、血量惩罚、韦伯鬼魂
	"possession",        -- Poss2 附身系统（须在 ghost 之后）
	"wickerbottom",
	"recipes",
	"starting_supplies",
}

for _, name in ipairs(ROGE_MODULES) do
	modimport("postinit/roge/" .. name .. ".lua")
end
