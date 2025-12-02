// This files adds new concepts + pop-up tooltips to document the damage tooltip

local tooltipImageKeywords = {
	// attack_info_tooltip__kill_chance
	"ui/icons/maxi_tt_kill_given_hit.png" : "Concept.KillGivenHit",
	"ui/icons/maxi_tt_marginal_kill.png"  : "Concept.MarginalKill",

	// attack_info_tooltip_line_5
	// "ui/icons/maxi_tt_kill_given_hit.png" : "Concept.KillGivenHit",		// already in kill_chance
	"ui/icons/maxi_tt_health_damage.png"  	  : "Concept.MeanHealthDamage",
	"ui/icons/maxi_tt_head_armor_damage.png"  : "Concept.MeanHeadArmorDamage",
	"ui/icons/maxi_tt_body_armor_damage.png"  : "Concept.MeanBodyArmorDamage",

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

	function getNestedPerkName( _obj )
	{
		local perkDef = ::Const.Perks.findById(_obj.getID());
		return format("[%s|Perk+%s]", perkDef != null ? perkDef.Name : _obj.m.Name, _obj.ClassName);
	}

	function getNestedPerkImage( _obj )
	{
		local perkDef = ::Const.Perks.findById(_obj.getID());
		return format("[Img/gfx/%s|Perk+%s]", perkDef != null ? perkDef.Icon : _obj.getIcon(), _obj.ClassName);
	}

	function getNestedSkillName( _obj, _getName = false )
	{
		// We use `.m.Name` instead of `getName()` because some skills (e.g. status effects)
		// modify the name during getName() e.g. to add info about the number of stacks
		return format("[%s|Skill+%s]", _getName ? _obj.getName() : _obj.m.Name, _obj.ClassName);
	}

	function getNestedSkillImage( _obj, _checkUsability = false )
	{
		local icon = !_checkUsability || _obj.isUsable() && _obj.isAffordable() ? _obj.getIconColored() : _obj.getIconDisabled();
		return format("[Img/gfx/%s|Skill+%s]", icon, _obj.ClassName);
	}

	function getNestedItemName( _obj )
	{
		return format("[%s|Item+%s]", _obj.getName(), _obj.ClassName);
	}

	function getNestedItemImage( _obj )
	{
		return format("[Img/gfx/%s|Item+%s]", _obj.getIcon(), _obj.ClassName);
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
        KillGivenHit = ::MSU.Class.BasicTooltip("Kill chance if hit", "Percent chance of this attack killing its target if it hits."),
        MarginalKill = ::MSU.Class.BasicTooltip("Overall kill chance", "Percent chance of this attack killing its target, factoring in the hit chance. For example, if the hitchance is 80% and the 'kill chance if hit' is 50%, the 'overall kill chance' is 40%."),

        MeanHealthDamage = ::MSU.Class.BasicTooltip("Average health damage", "Average health damage."),
        MeanHeadArmorDamage = ::MSU.Class.BasicTooltip("Average head armor damage", "Average head armor damage."),
        MeanBodyArmorDamage = ::MSU.Class.BasicTooltip("Average body armor damage", "Average body armor damage."),

		MaxiHeadHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Percent chance of this attack hitting the head, and corresponding damage information."),
        MaxiBodyHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Percent chance of this attack hitting the body, and corresponding damage information."),

		MaxiMultiHitHeadHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of a single hit to the head, and corresponding damage information."),
        MaxiMultiHitBodyHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of a single hit to the body, and corresponding damage information."),
        MaxiMultiHitZeroHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of zero hits, and corresponding damage information."),
        MaxiMultiHitOneHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of one hit, and corresponding damage information."),
        MaxiMultiHitTwoHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of two hits, and corresponding damage information."),
        MaxiMultiHitThreeHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Probability of three hits, and corresponding damage information."),

		MaxiSplitManHeadHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Percent chance of the main split-man attack hitting the head, and corresponding damage information."),
        MaxiSplitManBodyHitChance = ::MSU.Class.BasicTooltip("Head hit chance", "Percent chance of the main split-man attack hitting the body, and corresponding damage information.."),

		MaxiCalculationTime = ::MSU.Class.BasicTooltip("Head hit chance", "Calculation time."),

		// Base game concepts
		Disabled = ::MSU.Class.BasicTooltip("Disabled", ::ModMaxiTooltips.Mod.Tooltips.parseString("A disabled character is unable to act and will skip their [turn|Concept.Turn].\n\nExamples of [effects|Concept.StatusEffect] which can cause a character to become disabled include [Stunned|Skill+stunned_effect] and [Sleeping.|Skill+sleeping_effect]")),
		Rooted = ::MSU.Class.BasicTooltip("Rooted", ::ModMaxiTooltips.Mod.Tooltips.parseString("A rooted character is stuck in place - unable to move or be moved from their position.\n\nExamples of [effects|Concept.StatusEffect] which can cause a character to become rooted include [Trapped in Net|Skill+net_effect] and [Trapped in Web.|Skill+web_effect]")),
		Wait = ::MSU.Class.BasicTooltip("Wait", ::ModMaxiTooltips.Mod.Tooltips.parseString(format("If you are not the last character in the [turn order|Concept.Turn] in a [round,|Concept.Round] you may use the Wait action. This moves you to the end of the current [turn order,|Concept.Turn] allowing you to act again before the end of the [round.|Concept.Round]\n\nYou can only use Wait once per [turn.|Concept.Turn]%s", ::Const.CharacterProperties.InitiativeAfterWaitMult == 1.0 ? "" : "\n\nUsing Wait causes your [turn order|Concept.Turn] in the next [round|Concept.Round] to be calculated with " + ::MSU.Text.colorizeMult(::Const.CharacterProperties.InitiativeAfterWaitMult) + " " + (::Const.CharacterProperties.InitiativeAfterWaitMult > 1.0 ? "more" : "less") + " [Initiative.|Concept.Initiative]"))),
		Perk = ::MSU.Class.BasicTooltip("Perk", ::ModMaxiTooltips.Mod.Tooltips.parseString("As characters gain levels, they unlock perk points which can be spent to unlock powerful perks. Perks grant a character permanent bonuses or unlock new skills for use. The character\'s current [perk tier|Concept.PerkTier] increases by 1 each time a perk point is spent.")),
		StatusEffect = ::MSU.Class.BasicTooltip("Status Effect", ::ModMaxiTooltips.Mod.Tooltips.parseString("Status effects are positive or negative effects on a character, which are mostly temporary. A status effect can have various effects ranging from increasing/decreasing [attributes|Concept.CharacterAttribute] to unlocking new abilities.")),
		Injury = ::MSU.Class.BasicTooltip("Injury", ::ModMaxiTooltips.Mod.Tooltips.parseString("If sufficient damage is dealt to [Hitpoints|Concept.Hitpoints] during combat, characters can sustain an injury. Injuries are [status effects|Concept.StatusEffect] that confer various maluses.\n\nInjuries sustained during combat are [temporary,|Concept.InjuryTemporary] and will heal over time. Such injuries can be treated at a Temple for faster healing.\n\nIf a character is killed during combat, they have a chance to be struck down instead of being killed and survive the battle with a [permanent injury|Concept.InjuryPermanent]"))
		InjuryTemporary = ::MSU.Class.BasicTooltip("Temporary Injury", ::ModMaxiTooltips.Mod.Tooltips.parseString("Temporary injuries are received during combat when the damage to [Hitpoints|Concept.Hitpoints] received by a character exceeds the injury threshold. These injuries heal over time, but can be treated at a Temple for faster healing."))
		InjuryPermanent = ::MSU.Class.BasicTooltip("Permanent Injury", ::ModMaxiTooltips.Mod.Tooltips.parseString("Permanent injuries are received when a character is \'struck down\' during combat instead of being killed. These injuries, and the maluses they incur, are forever.")),
		InjuryThreshold = ::MSU.Class.BasicTooltip("Injury Threshold", ::ModMaxiTooltips.Mod.Tooltips.parseString("If the damage received to [Hitpoints|Concept.Hitpoints] is at least " + ::MSU.Text.colorNegative(::Const.Combat.InjuryMinDamage) + " and is greater than a certain percentage of the current [Hitpoints,|Concept.Hitpoints] the character receives an [injury.|Concept.InjuryTemporary] This percentage can be modified by certain [perks|Concept.Perk] or traits of both the attacker and the target.\n\nCertain [injuries|Concept.InjuryTemporary] require this percentage to be at least a certain value before they can be inflicted, with heavier [injuries|Concept.InjuryTemporary] requiring a higher percentage.\n\nFor example the threshold for [Cut Arm|Skill+cut_arm_injury] is " + ::MSU.Text.colorNegative(getThresholdForInjury("injury/cut_arm_injury") + "%") + " and that of [Split Hand|Skill+split_hand_injury] is " + ::MSU.Text.colorNegative(getThresholdForInjury("injury/split_hand_injury") + "%") + ".")),
		PerkTier = ::MSU.Class.BasicTooltip("Perk Tier", ::ModMaxiTooltips.Mod.Tooltips.parseString("[Perks|Concept.Perk] are distributed in a character\'s perk tree across 7 rows which are known as tiers. A character must have spent at least as many perk points as the tier-1 to be able to access the perks on that tier.")),
		StackMultiplicatively = ::MSU.Class.BasicTooltip("Stacking Multiplicatively", ::ModMaxiTooltips.Mod.Tooltips.parseString("Values can stack multiplicatively or [additively.|Concept.StackAdditively] Multiplicative stacking means that the values are multiplied.\n\nFor example, imagine a value of 100. Two skills that both increase this by 40% and stack multiplicatively increase the value by a total of 1.4 x 1.4 = 1.96 times, so it becomes 100 x 1.96 = 196. Two skills that reduce it by 40% and stack multiplicatively reduce it by (1.0 - 0.4) x (1.0 - 0.4) = 0.36 times, so it becomes 100 x 0.36 = 36.\n\nGenerally, [additive stacking|Concept.StackAdditively] is stronger when reducing a value or when the value is small and multiplicative stacking is stronger when increasing a value or when the value is large.")),
		StackAdditively = ::MSU.Class.BasicTooltip("Stacking Additively", ::ModMaxiTooltips.Mod.Tooltips.parseString("Values can stack [multiplicatively|Concept.StackMultiplicatively] or additively. Additive stacking means that the values are added.\n\nFor example, imagine a value of 100. Two skills that both increase this by 40% and stack additively increase the value by a total of 1.0 + 0.4 + 0.4 = 1.8 times, so it becomes 100 x 1.8 = 180. Two skills that reduce it by 40% and stack additively reduce it by 1.0 - 0.4 - 0.4 = 0.2 times, so it becomes 100 x 0.2 = 20.\n\nGenerally, additive stacking is stronger when reducing a value or when the value is small and [multiplicative stacking|Concept.StackMultiplicatively] is stronger when increasing a value or when the value is large.")),
		CharacterAttribute = ::MSU.Class.BasicTooltip("Character Attribute", ::ModMaxiTooltips.Mod.Tooltips.parseString("Characters in Battle Brothers have various attributes that describe the character\'s skill and/or aptitude in certain areas. Attributes include: [Hitpoints,|Concept.Hitpoints] [Fatigue,|Concept.Fatigue] [Resolve,|Concept.Bravery] [Initiative|Concept.Initiative] [Melee Skill,|Concept.MeleeSkill] [Melee Defense,|Concept.MeleeDefense] [Ranged Skill|Concept.RangeSkill] and [Ranged Defense.|Concept.RangeDefense]\n\nAs characters gain [experience|Concept.Experience] and [level up|Concept.Level] they can increase their attributes and unlock [perks.|Concept.Perk]")),
		BaseAttribute = ::MSU.Class.BasicTooltip("Base Attribute", ::ModMaxiTooltips.Mod.Tooltips.parseString("A character\'s [attributes|Concept.CharacterAttribute] can be modified by various means e.g. perks, traits, status effects, equipment etc. The Base value of the attribute is the one that is before any such modifications.")),
		Surrounding = ::MSU.Class.BasicTooltip("Surrounding", ::ModMaxiTooltips.Mod.Tooltips.parseString("When a character is in the zone of control of multiple hostile characters, he is considered surrounded. Characters attacking a surrounded target in melee gain additional chance to hit. Several perks such as [Underdog,|Perk.perk_underdog] [Backstabber|Perk.perk_backstabber] interact with the surrounding mechanic, reducing or increasing its effectiveness.")),
		FatigueRecovery = ::MSU.Class.BasicTooltip("Fatigue Recovery", ::ModMaxiTooltips.Mod.Tooltips.parseString("At the start of every turn the [Fatigue|Concept.Fatigue] of a character is reduced by a certain amount. This is known as Fatigue Recovery.\n\nBy default the Fatigue Recovery of player characters is 15, whereas enemies, depending on the enemy type, may have a much higher Fatigue Recovery.\n\nFatigue Recovery may be affected by [perks,|Concept.Perk] [traits,|Concept.Trait] [status effects|Concept.StatusEffect] and [injuries.|Concept.Injury]")),
		AOE = ::MSU.Class.BasicTooltip("Area of Effect", ::ModMaxiTooltips.Mod.Tooltips.parseString("Area of Effect (AOE) skills target multiple tiles with their effects instead of only a single tile.")),
		Fatality = ::MSU.Class.BasicTooltip("Fatality", ::ModMaxiTooltips.Mod.Tooltips.parseString("Fatalities are special forms of death which depict a certain gruesomeness beyond the ordinary. Fatalities include:\n- Decapitation - removing the target\'s head.\n- Disembowelment - opening up the target\'s belly to spill the guts.\n- Smashing - smashing the target\'s head into bits.")),
		Turn = ::MSU.Class.BasicTooltip("Turn", ::ModMaxiTooltips.Mod.Tooltips.parseString("Combat in battle brothers is turn-based. Each combat consists of a series of [rounds.|Concept.Round] During a round, characters act in turns. A character\'s position in the turn order is determined by the character\'s [Initiative|Concept.Initiative] relative to other characters.\n\n[Effects|Concept.StatusEffect] that last a certain number of turns last until the character has started or ended their turn that many times, depending on whether the [effect|Concept.StatusEffect] expires at the start or end of the turn respectively.")),
		Round = ::MSU.Class.BasicTooltip("Round", ::ModMaxiTooltips.Mod.Tooltips.parseString("Combat in battle brothers is turn-based. Each combat consists of a series of rounds. During a round, characters act in [turns.|Concept.Turn] A round ends when all characters have ended their [turns.|Concept.Turn]")),
		ZoneOfControl = ::MSU.Class.BasicTooltip("Zone of Control", ::ModMaxiTooltips.Mod.Tooltips.parseString("Most melee characters exert Zone of Control on their surrounding tiles. Trying to move out of enemy Zone of Control will trigger one free attack from each controlling enemy until the first attack hit or every attack missed. A hit will cancel the movement.")),
		BagSlots = ::MSU.Class.BasicTooltip("Bag Slots", ::ModMaxiTooltips.Mod.Tooltips.parseString("Bag slots can be used to store additional weapons or utility items for use during combat. Every character has " + ::new("scripts/items/item_container").getUnlockedBagSlots() + " bag slots by default and can have a maximum of " + ::Const.ItemSlotSpaces[::Const.ItemSlot.Bag] + "."))
	});

	::ModMaxiTooltips.Mod.Tooltips.setTooltips(::ModMaxiTooltips.NestedTooltips.Tooltips);
});
