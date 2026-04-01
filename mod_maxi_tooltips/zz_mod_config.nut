local tacticalTooltipPage = ::ModMaxiTooltips.Mod.ModSettings.addPage("Settings");

// Settings inherited from Reforged
// tacticalTooltipPage.addDivider( "actor_information_divider" );
tacticalTooltipPage.addTitle( "actor_information_title", "角色信息" );
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Attributes", "All", ["All", "AI Only", "Player Only", "None"], "显示属性", "在战术提示中显示单位的近战技能、近战防御等属性。");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Effects", "All", ["All", "AI Only", "Player Only", "None"], "显示状态效果", "在战术提示中显示单位的状态效果。");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Perks", "All", ["All", "AI Only", "Player Only", "None"], "显示专长", "在战术提示中单位实体的专长。");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_EquippedItems", "All", ["All", "AI Only", "Player Only", "None"], "显示已装备物品", "在战术提示中显示单位已装备的物品。");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_BagItems", "All", ["All", "AI Only", "Player Only", "None"], "显示背包物品", "在战术提示中显示单位背包中的物品。");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_ActiveSkills", "All", ["All", "AI Only", "Player Only", "None"], "显示主动技能", "在战术提示中显示单位所有可用的主动技能。");
tacticalTooltipPage.addRangeSetting("CollapseEffectsWhenX", 5, 0, 20, 1, "效果折叠阈值", "当状态效果数量低于此值时，所有状态效果单独显示图标并占用独立行；超过时合并为一段文字以节省空间。");
tacticalTooltipPage.addRangeSetting("CollapsePerksWhenX", 5, 0, 20, 1, "专长折叠阈值", "当专长数量低于此值时，所有专长单独显示图标并占用独立行；超过时合并为一段文字以节省空间。");
tacticalTooltipPage.addRangeSetting("CollapseActivesWhenX", 5, 0, 20, 1, "主动技能折叠阈值", "当主动技能数量低于此值时，单独显示图标并占用独立行；超过时合并为一段文字以节省空间。");
tacticalTooltipPage.addBooleanSetting("TacticalTooltip_CollapseAsText", false, "折叠时使用文字显示", "启用后，折叠的技能将使用名称文字显示；关闭则使用图标显示。");
tacticalTooltipPage.addBooleanSetting("ShowStatusPerkAndEffect", true, "同时显示专长及其状态效果", "某些专长同时也是状态效果。通常效果只有在满足条件时才显示。启用此选项后，即使专长已在「效果」类别中显示，也会在「专长」类别中继续显示（例如效果激活时）。禁用则可在效果显示时隐藏专长栏，以节省空间。");
tacticalTooltipPage.addBooleanSetting("HeaderForEmptyCategories", false, "空类别仍显示标题");

// New settings: damage preview
tacticalTooltipPage.addDivider( "damage_preview_divider" );
tacticalTooltipPage.addTitle( "damage_preview_title", "伤害预览" );
tacticalTooltipPage.addBooleanSetting("clip_health_damage", false, "伤害裁剪至敌人生命值", "启用后，伤害预测不会超过敌人的当前生命值。");
tacticalTooltipPage.addBooleanSetting("clip_armor_damage", true, "伤害裁剪至敌人护甲值", "启用后，伤害预测不会超过敌人的当前护甲值。");
tacticalTooltipPage.addBooleanSetting("show_calculation_time", false, "显示计算耗时", "显示伤害估算的计算时间（单位：毫秒）。");
tacticalTooltipPage.addRangeSetting("num_samples_total", 500, 50, 1000, 10, "总计算量", "如果提示框出现卡顿，请降低此数值；想要更精确的结果则提高。");
tacticalTooltipPage.addRangeSetting("num_samples_monte_carlo", 500, 50, 5000, 50, "蒙特卡洛计算量", "此参数仅用于分裂攻击和多重命中攻击！如果提示框卡顿请降低数值；想要更精确的结果则提高。");
tacticalTooltipPage.addRangeSetting("num_samples_armor", 10, 5, 20, 1, "护甲伤害计算量", "除非你清楚自己在做什么，否则不要修改此项。");

if (::ModMaxiTooltips.Mod.Debug.isEnabled()) {
    tacticalTooltipPage.addDivider( "damage_debug_divider" );
    local button__test__damage_estimation = tacticalTooltipPage.addButtonSetting("test__damage_estimation", "", "运行伤害估算测试");
    button__test__damage_estimation.addCallback(function(_data = null){
        ::ModMaxiTooltips.TacticalTooltip.test__damage_estimation();
    });
    local button__bench__damage_estimation = tacticalTooltipPage.addButtonSetting("bench__damage_estimation", "", "运行伤害估算性能测试");
    button__bench__damage_estimation.addCallback(function(_data = null){
        ::ModMaxiTooltips.TacticalTooltip.bench__damage_estimation();
    });
}

// New settings: hit factors
tacticalTooltipPage.addDivider( "hit_factors_divider" );
tacticalTooltipPage.addTitle( "hit_factors_title", "伤害预览" );
tacticalTooltipPage.addBooleanSetting("show_original_hitfactors", false, "显示原版命中因素", "启用后显示游戏原版的命中因素，而非改进后的易读版本。");