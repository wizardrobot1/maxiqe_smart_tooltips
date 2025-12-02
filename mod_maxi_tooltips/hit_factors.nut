if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


local function green(text) {
    if (!text)
    {
        return "";
    }

    return "[color=" + ::Const.UI.Color.PositiveValue + "]" + text + "[/color]";
};

local function red(text) {
    if (!text)
    {
        return "";
    }

    return "[color=" + ::Const.UI.Color.NegativeValue + "]" + text + "[/color]";
};


local function getDifferenceInProperty(user, targetEntity, skill, property) {
    local props = user.getCurrentProperties();

    if (!(property in props)) {
        return 0;
    }

    local propsWithSkill = props.getClone();
    skill.onAnySkillUsed(skill, targetEntity, propsWithSkill);
    return propsWithSkill[property] - props[property];
};


local function nested_tooltip(text, tt_type, tt_ref = null) {
    if (tt_ref) {
        return ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|%s+%s]", text, tt_type, tt_ref));
    }
    return ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|%s]", text, tt_type));
}


::ModMaxiTooltips.TacticalTooltip.getHitFactors <- function (skill, tile)
{
    local ret = [];
    local user = skill.m.Container.getActor();
    local myTile = user.getTile();
    local targetEntity = tile.IsOccupiedByActor ? tile.getEntity() : null;
    local distanceToTarget = user.getTile().getDistanceTo(tile);

    if (skill.m.HitChanceBonus > 0) {
        ret.push({
            icon = "ui/tooltips/positive.png",
            text = green("" + skill.m.HitChanceBonus + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill))
        });
    }

    if (skill.m.IsTooCloseShown && skill.m.HitChanceBonus < 0)
    {
        ret.push({
            icon = "ui/tooltips/negative.png",
            text = red("" + (-skill.m.HitChanceBonus) + "%") + " Too close"
        });
    }
    else if (skill.m.HitChanceBonus < 0)
    {
        ret.push({
            icon = "ui/tooltips/negative.png",
            text = red("" + (-skill.m.HitChanceBonus) + "%") + " " + skill.getName()
        });
    }

    if (skill.m.HitChanceBonus == 0) {
        local property = skill.m.IsRanged? "RangedSkill" : "MeleeSkill";
        local diff = getDifferenceInProperty(user, targetEntity, skill, property);

        if (diff > 0) {
            ret.push({
				icon = "ui/tooltips/positive.png",
				text = green(diff + "%") + " " + skill.getName()
			});
        }
        if (diff < 0) {
            ret.push({
				icon = "ui/tooltips/negative.png",
				text = green(diff + "%") + " " + skill.getName()
			});
        }
    }

    if (!skill.m.IsRanged && targetEntity != null && targetEntity.getSurroundedCount() != 0) {
        if (!targetEntity.m.CurrentProperties.IsImmuneToSurrounding)
		{
		    local malus = ::Math.max(0, user.getCurrentProperties().SurroundedBonus - targetEntity.getCurrentProperties().SurroundedDefense) * targetEntity.getSurroundedCount();

            if (malus)
            {
                ret.push({
                    icon = "ui/tooltips/positive.png",
                    text = green(malus + "%") + " " + "Surrounded"
                });
            }
		}
    }

    if (tile.Level < skill.m.Container.getActor().getTile().Level)
    {
        ret.push({
            icon = "ui/tooltips/positive.png",
            text = green(::Const.Combat.LevelDifferenceToHitBonus + "%") + " " + "Height advantage"
        });
    }

    if (tile.IsBadTerrain)
    {
        local malus = skill.m.IsRanged? 25 : 25;
        if (malus > 0) {
            local attribute_name = skill.m.IsRanged? "Ranged Defense" : "Melee Defense";
            ret.push({
                icon = "ui/tooltips/positive.png",
                text = "Target on swamp " + red("-" + malus + "%") + " " + attribute_name
            });
        }
    }

    if (skill.m.IsAttack)
    {
        local fast_adaptation = skill.m.Container.getSkillByID("perk.fast_adaption");

        if (fast_adaptation != null && fast_adaptation.isBonusActive())
        {
            local bonus = 10 * fast_adaptation.m.Stacks;
            ret.push({
                icon = "ui/tooltips/positive.png",
                text = green(bonus + "%") + " " + nested_tooltip(format("Fast Adaption (%i)", fast_adaptation.m.Stacks),"Skill",fast_adaptation.ClassName)
            });
        }

        local oath = skill.m.Container.getSkillByID("trait.oath_of_wrath");

        if (oath != null)
        {
            local items = user.getItems();
            local main = items.getItemAtSlot(::Const.ItemSlot.Mainhand);

            if (main != null && main.isItemType(::Const.Items.ItemType.MeleeWeapon) && (main.isItemType(::Const.Items.ItemType.TwoHanded) || items.getItemAtSlot(::Const.ItemSlot.Offhand) == null && !items.hasBlockedSlot(::Const.ItemSlot.Offhand)))
            {
                local bonus = 15
                ret.push({
                    icon = "ui/tooltips/positive.png",
                    text = green(bonus + "%")+ " " + nested_tooltip("Oath of Wrath","Skill",oath.ClassName)
                });
            }
        }
    }


    if (tile.Level > myTile.Level)
    {
        local levelDifference = myTile.Level - tile.Level;
		local malus = ::Const.Combat.LevelDifferenceToHitMalus * levelDifference;
        ret.push({
            icon = "ui/tooltips/negative.png",
            text = red(malus + "%") + " " + "Height disadvantage"
        });
    }

    if (myTile.IsBadTerrain)
    {
        local malus = skill.m.IsRanged? 0 : 25;
        if (malus > 0) {
            local attribute_name = skill.m.IsRanged? "Ranged Skill" : "Melee Skill";
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "On swamp " + red("-" + malus + "%") + " " + attribute_name
            });
        }
    }

    local shieldBonus = 0;
    local shield = targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);

    if (shield != null && shield.isItemType(::Const.Items.ItemType.Shield))
    {
        shieldBonus = (skill.m.IsRanged ? shield.getRangedDefense() : shield.getMeleeDefense()) * (targetEntity.getCurrentProperties().IsSpecializedInShields ? 1.25 : 1.0);

        if (skill.m.IsShieldRelevant) {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = red("-" + (shieldBonus) + "%") + " " + "Armed with shield"
            });
        }

        local shieldwallEffect = targetEntity.getSkills().getSkillByID("effects.shieldwall");
        if (shieldwallEffect) {
            local adjacencyBonus = shieldwallEffect.getBonus();
            if (skill.m.IsShieldwallRelevant) {
                ret.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + (shieldBonus) + "%") + " " + nested_tooltip("Shieldwall", "Skill", shieldwallEffect.ClassName)
                });
                if (adjacencyBonus) {
                    ret.push({
                        icon = "ui/tooltips/negative.png",
                        text = red("-" + (shieldBonus) + "%") + " " + nested_tooltip("Adjacency Bonus", "Skill", shieldwallEffect.ClassName)
                    });
                }
            }
        }
    }

    // Alert riposte
    if (targetEntity && myTile.getDistanceTo(tile) <= 1 && targetEntity.getSkills().hasSkill("effects.riposte") && !skill.isIgnoringRiposte())
    {
        local riposte = targetEntity.getSkills().hasSkill("effects.riposte");
        ret.push({
            icon = "ui/tooltips/negative.png",
            text = nested_tooltip("Riposte", "Skill", riposte.ClassName)
        });
    }

    // Ranged attacks: distance modifier to hitchance; blocked line-of-sight malus
    if (skill.m.IsRanged)
    {
        if (targetEntity)
        {
            local propertiesWithSkill = skill.m.Container.buildPropertiesForUse(skill, targetEntity);
            local malus = (distanceToTarget - skill.m.MinRange) * propertiesWithSkill.HitChanceAdditionalWithEachTile * propertiesWithSkill.HitChanceWithEachTileMult;
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = red(malus + "%") + " " + "Distance of " + tile.getDistanceTo(user.getTile())
            });
        }

        if (skill.m.IsUsingHitchance)
        {
            local blockedTiles = ::Const.Tactical.Common.getBlockedTiles(myTile, tile, user.getFaction(), true);

            if (blockedTiles.len() != 0)
            {
                local propertiesWithSkill = skill.m.Container.buildPropertiesForUse(skill, targetEntity);
                local blockChance = ::Const.Combat.RangedAttackBlockedChance * propertiesWithSkill.RangedAttackBlockedChanceMult;
                blockChance = ::Math.ceil(blockChance * 100);
                ret.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + blockChance + "%") + " " + "Line of fire blocked"
                });
            }
        }
    }

    if (skill.m.IsRanged && user.getCurrentProperties().IsAffectedByNight && user.getSkills().hasSkill("special.night"))
    {
        ret.push({
            icon = "ui/tooltips/negative.png",
            text = "Nighttime" + " " + red("-" + 30 + "%") + " Ranged Skill"
        });
    }

    if (skill.m.ID == "actives.lunge" && targetEntity) {
        local diff = getDifferenceInProperty(user, targetEntity, skill, "DamageTotalMult");

        if (diff > 0) {
            ret.push({
                icon = "ui/tooltips/positive.png",
                text = "High initiative " + green(diff + "%") + " " + "Lunge damage"
            });
        }
        if (diff < 0) {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "Low initiative " + red("-" + (-diff) + "%") + " " + "Lunge damage"
            });
        }
    }

    // Damage resistance
    if (targetEntity) {
        local damage_reduction_skills = [
			"racial.skeleton",
			"racial.golem",
			"racial.serpent",
			"racial.alp",
			"racial.schrat",
            "perk.nimble",
            "perk.battle_forged"
		];
		local damage_reduction_skill;

		for(local i = 0; i < damage_reduction_skills.len(); i++)
		{
			damage_reduction_skill = targetEntity.getSkills().getSkillByID(damage_reduction_skills[i]);

			if (damage_reduction_skill)
			{
                local damage_reduction_skill_tt = "";
                if ("getTooltip" in damage_reduction_skill) {
                    damage_reduction_skill_tt = nested_tooltip(damage_reduction_skill.getName(), "Skill", damage_reduction_skill.ClassName) + " ";
                }
				local propertiesBefore = targetEntity.getCurrentProperties();
                local hitInfo = clone ::Const.Tactical.HitInfo;
                local propertiesAfter = propertiesBefore.getClone();
                damage_reduction_skill.onBeforeDamageReceived(user, skill, hitInfo, propertiesAfter);

                // TODO: refactor this into a for loop over checked properties
                if ("DamageReceivedRegularMult" in propertiesBefore) {
                    local description = "HP damage";
                    local diff = propertiesBefore.DamageReceivedRegularMult - propertiesAfter.DamageReceivedRegularMult;
                    diff = ::Math.ceil(diff * 100);

                    if (diff > 0) {
                        ret.push({
                            icon = "ui/tooltips/positive.png",
                            text = damage_reduction_skill_tt + green(diff + "%") + " " + description
                        });
                    }

                    if (diff < 0) {
                        ret.push({
                            icon = "ui/tooltips/negative.png",
                            text = damage_reduction_skill_tt + " " + red("-" + (-diff) + "%") + " " + description
                        });
                    }
                }
                if ("DamageReceivedArmorMult" in propertiesBefore) {
                    local description = "Armor damage";
                    local diff = propertiesBefore.DamageReceivedArmorMult - propertiesAfter.DamageReceivedArmorMult;
                    diff = ::Math.ceil(diff * 100);

                    if (diff > 0) {
                        ret.push({
                            icon = "ui/tooltips/positive.png",
                            text = damage_reduction_skill_tt + " " + green(diff + "%") + " " + description
                        });
                    }

                    if (diff < 0) {
                        ret.push({
                            icon = "ui/tooltips/negative.png",
                            text = damage_reduction_skill_tt + " " + red("-" + (-diff) + "%") + " " + description
                        });
                    }
                }

			}
		}
    }

    // Immunities
    if (targetEntity) {
        if (targetEntity.getCurrentProperties().IsImmuneToStun && (skill.m.ID == "actives.knock_out" || skill.m.ID == "actives.knock_over" || skill.m.ID == "actives.strike_down"))
        {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "Immune to stun"
            });
        }

        if (targetEntity.getCurrentProperties().IsImmuneToRoot && skill.m.ID == "actives.throw_net")
        {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "Immune to being rooted"
            });
        }

        if ((targetEntity.getCurrentProperties().IsImmuneToDisarm || targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Mainhand) == null) && skill.m.ID == "actives.disarm")
        {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "Immune to being disarmed"
            });
        }

        if (targetEntity.getCurrentProperties().IsImmuneToKnockBackAndGrab && (skill.m.ID == "actives.knock_back" || skill.m.ID == "actives.hook" || skill.m.ID == "actives.repel"))
        {
            ret.push({
                icon = "ui/tooltips/negative.png",
                text = "Immune to being knocked back or hooked"
            });
        }
    }

    return ret;
}


::ModMaxiTooltips.ModHook.hook("scripts/skills/skill", function(q) {

    q.getHitFactors = @(__original) function(tile) {
        return ::ModMaxiTooltips.TacticalTooltip.getHitFactors(this, tile)
    }

});
