-- roge/recipes.lua
-- 强心针：原版配方改为仅需一枚彩虹宝石
AddRecipePostInit("lifeinjector", function(recipe)
	recipe.ingredients = {
		Ingredient("opalpreciousgem", 1),
	}
end)

-- 恐惧弹丸：禁用原版制作
AddRecipePostInit("slingshotammo_dreadstone", function(recipe)
	recipe.canbuild = function()
		return false
	end
end)

-- 养蜂笔记：暂时禁用原版配方（4 蜂蜜 + 8 蜂刺 + 2 莎草纸）
AddRecipePostInit("book_bees", function(recipe)
	recipe.canbuild = function()
		return false
	end
end)

-- 蛛形纲（蛛网书）：6 蛛丝 + 2 莎草纸
AddRecipePostInit("book_web", function(recipe)
	recipe.ingredients = {
		Ingredient("silk", 6),
		Ingredient("papyrus", 2),
	}
end)

-- 暗影锻造台：10 恐惧弹丸 -> 彩虹宝石（与虚空装备同属 SHADOWFORGING_TWO，需在基座旁解锁）
AddRecipe2("roge_opalpreciousgem_dreadammo",
	{ Ingredient("slingshotammo_dreadstone", 12) },
	TECH.SHADOWFORGING_TWO,
	{
		product = "opalpreciousgem",
		image = "opalpreciousgem.tex",
		description = "roge_opalpreciousgem_dreadammo",
		station_tag = "shadow_forge",
		nounlock = true,
	})
