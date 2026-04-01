// This files adds new concepts + pop-up tooltips to document the damage tooltip

local tooltipImageKeywords = {
	// attack_info_tooltip__kill_chance
	"ui/icons/maxi_tt_overall_kill_given_hit.png" : "Concept.OverallKillGivenHit",
	"ui/icons/maxi_tt_kill_given_hit.png" : "Concept.LineKillGivenHit",
	"ui/icons/maxi_tt_marginal_kill.png"  : "Concept.MarginalKill",

	// attack_info_tooltip_line_5
	// "ui/icons/maxi_tt_kill_given_hit.png" : "Concept.KillGivenHit",		// already in kill_chance
	"ui/icons/maxi_tt_health_damage.png"  	  : "Concept.MeanHealthDamage",
	"ui/icons/maxi_tt_head_armor_damage.png"  : "Concept.MeanHeadArmorDamage",
	"ui/icons/maxi_tt_body_armor_damage.png"  : "Concept.MeanBodyArmorDamage",

	// Icons for line_5 for normal attacks
	"ui/icons/maxi_tt_generic_hit_chance.png"  : "Concept.MaxiGenericHitChance",

	// Icons for line_5 for normal attacks
	"ui/icons/maxi_tt_head_hit_chance.png"  : "Concept.MaxiHeadHitChance",
	"ui/icons/maxi_tt_body_hit_chance.png"  : "Concept.MaxiBodyHitChance",

	// Icons for line_5 for multi-hit attacks
	"ui/icons/maxi_tt_multihit_head_hit_chance.png"  : "Concept.MaxiMultiHitHeadHitChance",
	"ui/icons/maxi_tt_multihit_body_hit_chance.png"  : "Concept.MaxiMultiHitBodyHitChance",
	"ui/icons/maxi_tt_num_hits_0.png"  				 : "Concept.MaxiMultiHitZeroHitChance",
	"ui/icons/maxi_tt_num_hits_1.png"  				 : "Concept.MaxiMultiHitOneHitChance",
	"ui/icons/maxi_tt_num_hits_2.png"  				 : "Concept.MaxiMultiHitTwoHitChance",
	"ui/icons/maxi_tt_num_hits_3.png"  				 : "Concept.MaxiMultiHitThreeHitChance",

	// Icons for line_5 for split-man attacks
	"ui/icons/maxi_tt_splitman_head_hit_chance.png"  : "Concept.MaxiSplitManHeadHitChance",
	"ui/icons/maxi_tt_splitman_body_hit_chance.png"  : "Concept.MaxiSplitManBodyHitChance",

	// Calculation time
	"ui/icons/maxi_tt_calculation_time.png"  : "Concept.MaxiCalculationTime",
}

::ModMaxiTooltips.Mod.Tooltips.setTooltipImageKeywords(tooltipImageKeywords);

local getThresholdForInjury = function( _script )
{
	foreach (entry in ::Const.Injury.All)
	{
		if (entry.Script == _script)
			return entry.Threshold * 100;
	}
}


::ModMaxiTooltips.NestedTooltips <- {
	Tooltips = {
		Concept = {}
	},
	AutoConcepts = [
		"character-stats.ActionPoints",
		"character-stats.Hitpoints",
		"character-stats.Morale",
		"character-stats.Fatigue",
		"character-stats.MaximumFatigue",
		"character-stats.ArmorHead",
		"character-stats.ArmorBody",
		"character-stats.MeleeSkill",
		"character-stats.RangeSkill",
		"character-stats.MeleeDefense",
		"character-stats.RangeDefense",
		"character-stats.SightDistance",
		"character-stats.RegularDamage",
		"character-stats.CrushingDamage",
		"character-stats.ChanceToHitHead",
		"character-stats.Initiative",
		"character-stats.Bravery",
		"character-stats.Talent",
		"character-stats.SightDistance"

		"character-screen.left-panel-header-module.Experience",
		"character-screen.left-panel-header-module.Level",

		"assets.BusinessReputation",
		"assets.MoralReputation"
	],

	function getNestedPerkName( _obj, _extraData = null )
	{
		local perkDef = ::Const.Perks.findById(_obj.getID());
		return format("[%s|Perk+%s%s]", perkDef != null ? perkDef.Name : _obj.m.Name, _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedPerkImage( _obj, _extraData = null )
	{
		local perkDef = ::Const.Perks.findById(_obj.getID());
		return format("[Img/gfx/%s|Perk+%s%s]", perkDef != null ? perkDef.Icon : _obj.getIcon(), _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedSkillName( _obj, _extraData = null, _getName = false )
	{
		// We use `.m.Name` instead of `getName()` because some skills (e.g. status effects)
		// modify the name during getName() e.g. to add info about the number of stacks
		return format("[%s|Skill+%s%s]", _getName ? _obj.getName() : _obj.m.Name, _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedSkillImage( _obj, _extraData = null, _checkUsability = false )
	{
		local icon = !_checkUsability || _obj.isUsable() && _obj.isAffordable() ? _obj.getIconColored() : _obj.getIconDisabled();
		return format("[Img/gfx/%s|Skill+%s%s]", icon, _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedItemName( _obj, _extraData = null )
	{
		return format("[%s|Item+%s%s]", _obj.getName(), _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedItemImage( _obj, _extraData = null )
	{
		return format("[Img/gfx/%s|Item+%s%s]", _obj.getIcon(), _obj.ClassName, _extraData == null ? "" : "," + _extraData);
	}

	function getNestedEntityImage( _obj, _extraData = null )
	{
		return format("[Img/gfx/ui/orientation/%s.png|Entity+%i]", _obj.getOverlayImage(), _obj.getID(), _extraData == null ? "" : "," + _extraData);
	}

	function getNestedEntityName( _obj, _extraData = null )
	{
		return format("[%s|Entity+%i]", _obj.getName(), _obj.getID(), _extraData == null ? "" : "," + _extraData);
	}
}

::ModMaxiTooltips.QueueBucket.FirstWorldInit.push(function() {
	foreach (concept in ::ModMaxiTooltips.NestedTooltips.AutoConcepts)
	{
		local desc = ::TooltipScreen.m.TooltipEvents.general_queryUIElementTooltipData(::MSU.getDummyPlayer().getID(), concept, null);
		::ModMaxiTooltips.NestedTooltips.Tooltips.Concept[split(concept, ".").top()] <- ::MSU.Class.CustomTooltip(@(data) desc);
	}

	::MSU.Table.merge(::ModMaxiTooltips.NestedTooltips.Tooltips.Concept, {
		// New concepts for the damage estimation tooltip
        OverallKillGivenHit = ::MSU.Class.BasicTooltip("命中后击杀几率", "此次攻击命中目标后，综合各部位命中概率计算出的总击杀几率。"),
        LineKillGivenHit = ::MSU.Class.BasicTooltip("部位击杀几率", "此次攻击命中该部位后，击杀目标的几率。"),
        MarginalKill = ::MSU.Class.BasicTooltip("总击杀几率", "此次攻击击杀目标的几率，已将命中几率纳入考量。例如，如果命中几率为80%，'命中后击杀几率'为50%，则'总击杀几率'为40%。"),

        MeanHealthDamage = ::MSU.Class.BasicTooltip("平均生命值伤害", ""),
        MeanHeadArmorDamage = ::MSU.Class.BasicTooltip("平均头部护甲伤害", ""),
        MeanBodyArmorDamage = ::MSU.Class.BasicTooltip("平均身体护甲伤害", ""),

		MaxiGenericHitChance = ::MSU.Class.BasicTooltip("命中几率", "此次攻击击中敌人的几率。"),

		MaxiHeadHitChance = ::MSU.Class.BasicTooltip("头部命中几率", "此次攻击击中头部的几率。"),
        MaxiBodyHitChance = ::MSU.Class.BasicTooltip("身体命中几率", "此次攻击击中身体的几率。"),

		MaxiMultiHitHeadHitChance = ::MSU.Class.BasicTooltip("多重攻击的头部命中几率", "多重攻击命中头部的几率，已将命中几率纳入考量。"),
        MaxiMultiHitBodyHitChance = ::MSU.Class.BasicTooltip("多重攻击的身体命中几率", "多重攻击命中身体的几率，已将命中几率纳入考量。"),
        MaxiMultiHitZeroHitChance = ::MSU.Class.BasicTooltip("多重攻击未命中几率", "多重攻击未命中的几率。"),
        MaxiMultiHitOneHitChance = ::MSU.Class.BasicTooltip("多重攻击命中1次几率", "多重攻击命中1次的几率，已将命中几率纳入考量。"),
        MaxiMultiHitTwoHitChance = ::MSU.Class.BasicTooltip("多重攻击命中2次几率", "多重攻击命中2次的几率，已将命中几率纳入考量。"),
        MaxiMultiHitThreeHitChance = ::MSU.Class.BasicTooltip("多重攻击命中3次几率", "多重攻击命中3次的几率，已将命中几率纳入考量。"),

		MaxiSplitManHeadHitChance = ::MSU.Class.BasicTooltip("分裂攻击命中头部几率", "分裂攻击命中头部并造成相应伤害的几率。"),
        MaxiSplitManBodyHitChance = ::MSU.Class.BasicTooltip("分裂攻击命中身体几率", "分裂攻击命中身体并造成相应伤害的几率。"),

		MaxiCalculationTime = ::MSU.Class.BasicTooltip("计算时间", "伤害估算所花费的时间。"),

		// Base game concepts
		Disabled = ::MSU.Class.BasicTooltip("无法行动", ::ModMaxiTooltips.Mod.Tooltips.parseString("一个无法行动的角色将不能执行任何动作，并会跳过他们的[回合|Concept.Turn]。\n\n导致角色无法行动的[效果|Concept.StatusEffect]包括[眩晕|Skill+stunned_effect]和[睡眠|Skill+sleeping_effect]。")),
		Rooted = ::MSU.Class.BasicTooltip("束缚", ::ModMaxiTooltips.Mod.Tooltips.parseString("一个被束缚的角色会固定在原地，无法移动或被移动。\n\n导致角色被束缚的[效果|Concept.StatusEffect]包括[被网困住|Skill+net_effect]和[被蛛网困住|Skill+web_effect]。")),
		Wait = ::MSU.Class.BasicTooltip("等待", ::ModMaxiTooltips.Mod.Tooltips.parseString(format("如果你不是当前[回合|Concept.Round]中最后一个行动的角色，你可以使用等待行动。这会将你移到当前[回合顺序|Concept.Turn]的末尾，让你在[回合|Concept.Round]结束前再次行动。\n\n你每个[回合|Concept.Turn]只能使用一次等待行动。%s", ::Const.CharacterProperties.InitiativeAfterWaitMult == 1.0 ? "" : "\n\n使用等待行动会导致你在下一个[回合|Concept.Round]的[行动顺序|Concept.Turn]以" + ::MSU.Text.colorizeMult(::Const.CharacterProperties.InitiativeAfterWaitMult) + " " + (::Const.CharacterProperties.InitiativeAfterWaitMult > 1.0 ? "更多" : "更少") + "的[主动值|Concept.Initiative]进行计算。"))),
		Perk = ::MSU.Class.BasicTooltip("专长", ::ModMaxiTooltips.Mod.Tooltips.parseString("随着角色升级，他们会解锁专长点数，可用于解锁强大的专长。专长会赋予角色永久性增益或解锁新技能。角色每消耗一个专长点数，其[专长层级|Concept.PerkTier]就会提升1。")),
		StatusEffect = ::MSU.Class.BasicTooltip("状态效果", ::ModMaxiTooltips.Mod.Tooltips.parseString("状态效果是角色身上暂时性的正面或负面效果。状态效果可能产生多种影响，从增减[属性|Concept.CharacterAttribute]到解锁新能力。")),
		Injury = ::MSU.Class.BasicTooltip("受伤", ::ModMaxiTooltips.Mod.Tooltips.parseString("如果在战斗中对[生命值|Concept.Hitpoints]造成足够伤害，角色可能会受伤。受伤是一种[状态效果|Concept.StatusEffect]，会带来各种负面影响。\n\n战斗中受到的伤害是[临时性|Concept.InjuryTemporary]的，会随着时间愈合。此类受伤可在神殿治疗以加快愈合。\n\n如果角色在战斗中被杀死，他们有几率被击倒而不是死亡，并在战斗中带着[永久性受伤|Concept.InjuryPermanent]幸存下来。")),
		InjuryTemporary = ::MSU.Class.BasicTooltip("临时受伤", ::ModMaxiTooltips.Mod.Tooltips.parseString("当角色受到的[生命值|Concept.Hitpoints]伤害超过受伤阈值时，会在战斗中受到临时性伤害。这些伤害会随着时间愈合，但可以在神殿治疗以加快愈合。")),
		InjuryPermanent = ::MSU.Class.BasicTooltip("永久受伤", ::ModMaxiTooltips.Mod.Tooltips.parseString("当角色在战斗中被“击倒”而不是杀死时，会受到永久性伤害。这些伤害及其造成的负面影响是永久性的。")),
		InjuryThreshold = ::MSU.Class.BasicTooltip("受伤阈值", ::ModMaxiTooltips.Mod.Tooltips.parseString("如果受到的[生命值|Concept.Hitpoints]伤害至少为" + ::MSU.Text.colorNegative(::Const.Combat.InjuryMinDamage) + "，并且大于当前[生命值|Concept.Hitpoints]的某个百分比，角色就会[受伤|Concept.InjuryTemporary]。这个百分比可以通过攻击者和目标的一些[专长|Concept.Perk]或特质来修改。\n\n某些[创伤|Concept.InjuryTemporary]需要这个百分比至少达到某个值才能造成，更严重的[创伤|Concept.InjuryTemporary]需要更高的百分比。\n\n例如，[手臂割伤|Skill+cut_arm_injury]的阈值是" + ::MSU.Text.colorNegative(getThresholdForInjury("injury/cut_arm_injury") + "%") + "，而[手部撕裂|Skill+split_hand_injury]的阈值是" + ::MSU.Text.colorNegative(getThresholdForInjury("injury/split_hand_injury") + "%") + "。")),
		PerkTier = ::MSU.Class.BasicTooltip("专长层级", ::ModMaxiTooltips.Mod.Tooltips.parseString("角色的专长树分为7个层级。角色必须消耗至少与该层级-1数量相同的专长点数，才能解锁该层级的专长。")),
		StackMultiplicatively = ::MSU.Class.BasicTooltip("乘法叠加", ::ModMaxiTooltips.Mod.Tooltips.parseString("数值可以[乘法叠加|Concept.StackMultiplicatively]或[加法叠加|Concept.StackAdditively]。乘法叠加意味着数值相乘。\n\n例如，假设一个数值为100。如果两个技能都将其增加40%并乘法叠加，则总共增加1.4 x 1.4 = 1.96倍，因此数值变为100 x 1.96 = 196。如果两个技能都将其减少40%并乘法叠加，则总共减少(1.0 - 0.4) x (1.0 - 0.4) = 0.36倍，因此数值变为100 x 0.36 = 36。\n\n通常，当减少数值或数值较小时，[加法叠加|Concept.StackAdditively]更强；当增加数值或数值较大时，乘法叠加更强。")),
		StackAdditively = ::MSU.Class.BasicTooltip("加法叠加", ::ModMaxiTooltips.Mod.Tooltips.parseString("数值可以[乘法叠加|Concept.StackMultiplicatively]或加法叠加。加法叠加意味着数值相加。\n\n例如，假设一个数值为100。如果两个技能都将其增加40%并加法叠加，则总共增加1.0 + 0.4 + 0.4 = 1.8倍，因此数值变为100 x 1.8 = 180。如果两个技能都将其减少40%并加法叠加，则总共减少1.0 - 0.4 - 0.4 = 0.2倍，因此数值变为100 x 0.2 = 20。\n\n通常，当减少数值或数值较小时，加法叠加更强；当增加数值或数值较大时，[乘法叠加|Concept.StackMultiplicatively]更强。")),
		CharacterAttribute = ::MSU.Class.BasicTooltip("角色属性", ::ModMaxiTooltips.Mod.Tooltips.parseString("《战场兄弟》中的角色拥有各种属性，描述了角色在某些领域的技能和/或天赋。属性包括：[生命值|Concept.Hitpoints]、[疲劳|Concept.Fatigue]、[决心|Concept.Bravery]、[主动值|Concept.Initiative]、[近战技能|Concept.MeleeSkill]、[近战防御|Concept.MeleeDefense]、[远程技能|Concept.RangeSkill]和[远程防御|Concept.RangeDefense]。\n\n随着角色获得[经验|Concept.Experience]并[升级|Concept.Level]，他们可以提升属性并解锁[专长|Concept.Perk]。")),
		BaseAttribute = ::MSU.Class.BasicTooltip("基础属性", ::ModMaxiTooltips.Mod.Tooltips.parseString("角色的[属性|Concept.CharacterAttribute]可以通过各种方式修改，例如专长、特质、状态效果、装备等。属性的基础值是指在任何此类修改之前的值。")),
		Surrounding = ::MSU.Class.BasicTooltip("围攻", ::ModMaxiTooltips.Mod.Tooltips.parseString("当一个角色处于多个敌方角色的控制区域内时，他被视为被围攻。在近战中攻击被围攻目标的角色会获得额外的命中几率。一些专长，如[弱者优势|Perk.perk_underdog]、[背刺者|Perk.perk_backstabber]会与围攻机制互动，减少或增加其有效性。")),
		FatigueRecovery = ::MSU.Class.BasicTooltip("疲劳恢复", ::ModMaxiTooltips.Mod.Tooltips.parseString("每个回合开始时，角色的[疲劳值|Concept.Fatigue]会减少一定量。这被称为疲劳恢复。\n\n默认情况下，玩家角色的疲劳恢复为15，而敌人，根据敌人类型，可能具有更高的疲劳恢复。\n\n疲劳恢复可能会受到[专长|Concept.Perk]、[特质|Concept.Trait]、[状态效果|Concept.StatusEffect]和[受伤|Concept.Injury]的影响。")),
		AOE = ::MSU.Class.BasicTooltip("范围效果", ::ModMaxiTooltips.Mod.Tooltips.parseString("范围效果的技能会瞄准多个格子，而不是单个格子。")),
		Fatality = ::MSU.Class.BasicTooltip("致命一击", ::ModMaxiTooltips.Mod.Tooltips.parseString("致命一击是特殊形式的死亡，其残忍程度超乎寻常。致命一击包括：\n- 斩首 - 移除目标的头部。\n- 开膛破肚 - 剖开目标的腹部，使其内脏流出。\n- 粉碎 - 将目标的头部砸成碎片。")),
		Turn = ::MSU.Class.BasicTooltip("回合", ::ModMaxiTooltips.Mod.Tooltips.parseString("《战场兄弟》中的战斗是回合制的。每次战斗都由一系列的[回合|Concept.Round]组成。在一个回合中，角色们轮流行动。角色在行动顺序中的位置由角色的[主动值|Concept.Initiative]相对于其他角色决定。\n\n持续一定回合数的[效果|Concept.StatusEffect]会持续到角色开始或结束其回合那么多次，具体取决于[效果|Concept.StatusEffect]是在回合开始还是结束时过期。")),
		Round = ::MSU.Class.BasicTooltip("轮次", ::ModMaxiTooltips.Mod.Tooltips.parseString("《战场兄弟》中的战斗是回合制的。每次战斗都由一系列的轮次组成。在一个轮次中，角色们轮流[行动|Concept.Turn]。当所有角色都结束了他们的[行动|Concept.Turn]时，一个轮次就结束了。")),
		ZoneOfControl = ::MSU.Class.BasicTooltip("控制区域", ::ModMaxiTooltips.Mod.Tooltips.parseString("大多数近战角色都会在其周围的格子上施加控制区域。试图移出敌人控制区域会触发每个控制敌人的免费攻击，直到第一次攻击命中或所有攻击都未命中。命中会取消移动。")),
		BagSlots = ::MSU.Class.BasicTooltip("背包栏位", ::ModMaxiTooltips.Mod.Tooltips.parseString("背包栏位可用于存放额外的武器或实用物品，以供战斗中使用。每个角色默认有" + ::new("scripts/items/item_container").getUnlockedBagSlots() + "个背包栏位，最多可拥有" + ::Const.ItemSlotSpaces[::Const.ItemSlot.Bag] + "个。"))
	});

	::ModMaxiTooltips.Mod.Tooltips.setTooltips(::ModMaxiTooltips.NestedTooltips.Tooltips);
});