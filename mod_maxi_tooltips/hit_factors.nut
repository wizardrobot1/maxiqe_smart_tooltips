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


// Skill hit-chance bonus
local function getHitFactorSkillHitChanceBonus(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.HitChanceBonus > 0) {
        tooltips.push({
            icon = "ui/tooltips/positive.png",
            text = green("+" + skill.m.HitChanceBonus + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
        });
    }
    return tooltips;
}


// Skill too-close malus
local function getHitFactorSkillTooCloseMalus(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.IsTooCloseShown && skill.m.HitChanceBonus < 0)
    {
        local bonus = ::Math.abs(skill.m.HitChanceBonus);
        tooltips.push({
            icon = "ui/tooltips/negative.png",
            text = red("-" + bonus + "%") + " Too close! " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
        });
    }
    return tooltips;
}


// Skill universal hit-chance malus
local function getHitFactorSkillUniversalMalus(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (!skill.m.IsTooCloseShown && skill.m.HitChanceBonus < 0)
    {
        local malus = ::Math.abs(skill.m.HitChanceBonus)
        tooltips.push({
            icon = "ui/tooltips/negative.png",
            text = red("-" + malus + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
        });
    }
    return tooltips;
}


// Skill hit-chance modifier for ranged attack
local function getHitFactorSkillHitChanceModifier(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.HitChanceBonus == 0) {
        local property = skill.m.IsRanged? "RangedSkill" : "MeleeSkill";
        local diff = getDifferenceInProperty(user, targetEntity, skill, property);

        if (diff > 0) {
            tooltips.push({
                icon = "ui/tooltips/positive.png",
                text = green("+" + diff + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
            });
        }
        if (diff < 0) {
            diff = ::Math.abs(diff);
            tooltips.push({
                icon = "ui/tooltips/negative.png",
                text = red("-" + diff + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
            });
        }
    }
    return tooltips;
}


// Bonus hit-chance from surrounding
local function getHitFactorBonusFromSurrounding(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (!skill.m.IsRanged && targetEntity != null && targetEntity.getSurroundedCount() != 0) {
        if (!targetEntity.m.CurrentProperties.IsImmuneToSurrounding)
        {
            local malus = ::Math.max(0, user.getCurrentProperties().SurroundedBonus - targetEntity.getCurrentProperties().SurroundedDefense) * targetEntity.getSurroundedCount();

            if (malus > 0)
            {
                tooltips.push({
                    icon = "ui/tooltips/positive.png",
                    text = green("+" + malus + "%") + " " + "Surrounded"
                });
            }
        } else {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = "Immune to surrounding"
            });
        }
    }
    return tooltips;
}


// Height-advantage
local function getHitFactorHeightAdvantage(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (myTile.Level > tile.Level)
    {
        local levelDifference = myTile.Level - tile.Level;
        local bonus = ::Math.abs(::Const.Combat.LevelDifferenceToHitBonus);
        tooltips.push({
            icon = "ui/tooltips/positive.png",
            text = green("+" + bonus + "%") + " " + "Height advantage"
        });
    }
    return tooltips;
}


// Target is on swamp
local function getHitFactorTargetOnBadTerrain(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];

    local skill = targetEntity.getSkills().getSkillByID("terrain.swamp");
    if (skill)
    {
        local malus = skill.m.IsRanged? 25 : 25;
        if (malus > 0) {
            local attribute_name = skill.m.IsRanged? "Ranged Defense" : "Melee Defense";
            tooltips.push({
                icon = "ui/tooltips/positive.png",
                // text = "Target on swamp " + red("-" + malus + "%") + " " + attribute_name
                text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Skill+%s]", "Target on swamp", skill.ClassName))
            });
        }
    }
    return tooltips;
}


// Fast adaptation bonus
local function getHitFactorFastAdaptationBonus(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.IsAttack)
    {
        local fast_adaptation = skill.m.Container.getSkillByID("perk.fast_adaption");

        if (fast_adaptation != null && fast_adaptation.isBonusActive())
        {
            local bonus = 10 * fast_adaptation.m.Stacks;
            tooltips.push({
                icon = "ui/tooltips/positive.png",
                text = green("+" + bonus + "%") + " "
                + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill, "entityId:" + user.getID()))
                + format("(%i)", fast_adaptation.m.Stacks)
            });
        }
    }
    return tooltips;
}


// Oath of wrath
local function getHitFactorOathOfWrath(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.IsAttack)
    {
        local oath = skill.m.Container.getSkillByID("trait.oath_of_wrath");

        if (oath != null)
        {
            local items = user.getItems();
            local main = items.getItemAtSlot(::Const.ItemSlot.Mainhand);

            if (main != null && main.isItemType(::Const.Items.ItemType.MeleeWeapon) && (main.isItemType(::Const.Items.ItemType.TwoHanded) || items.getItemAtSlot(::Const.ItemSlot.Offhand) == null && !items.hasBlockedSlot(::Const.ItemSlot.Offhand)))
            {
                local bonus = 15
                tooltips.push({
                    icon = "ui/tooltips/positive.png",
                    text = green("+" + bonus + "%")+ " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(oath, "entityId:" + user.getID()))
                });
            }
        }
    }
    return tooltips;
}


// Height disadvantage
local function getHitFactorHeightDisadvantage(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (tile.Level > myTile.Level)
    {
        local levelDifference = tile.Level - myTile.Level;
        local malus = ::Math.abs(::Const.Combat.LevelDifferenceToHitMalus * levelDifference);
        tooltips.push({
            icon = "ui/tooltips/negative.png",
            text = red("-" + malus + "%") + " " + "Height disadvantage"
        });
    }
    return tooltips;
}


// Malus from swamp
local function getHitFactorMalusFromBadTerrain(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];

    local skill = user.getSkills().getSkillByID("terrain.swamp");
    if (myTile.IsBadTerrain)
    {
        local malus = skill.m.IsRanged? 0 : 25;
        if (malus > 0) {
            local attribute_name = skill.m.IsRanged? "Ranged Skill" : "Melee Skill";
            tooltips.push({
                icon = "ui/tooltips/negative.png",
                // text = "On swamp " + red("-" + malus + "%") + " " + attribute_name
                text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Skill+%s]", "Standing on swamp", skill.ClassName))
            });
        }
    }
    return tooltips;
}


// Armed with shield
local function getHitFactorArmedWithShield(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        local shieldBonus = 0;
        local shield = targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);

        if (shield != null && shield.isItemType(::Const.Items.ItemType.Shield))
        {
            shieldBonus = (skill.m.IsRanged ? shield.getRangedDefense() : shield.getMeleeDefense()) * (targetEntity.getCurrentProperties().IsSpecializedInShields ? 1.25 : 1.0);
            shieldBonus = ::Math.abs(shieldBonus);

            if (skill.m.IsShieldRelevant) {
                tooltips.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + (shieldBonus) + "%") + " " + "Armed with shield"
                });
            }

        }
    }
    return tooltips;
}


// Shieldwall
local function getHitFactorShieldwall(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        local shieldBonus = 0;
        local shield = targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Offhand);

        if (shield != null && shield.isItemType(::Const.Items.ItemType.Shield))
        {
            shieldBonus = (skill.m.IsRanged ? shield.getRangedDefense() : shield.getMeleeDefense()) * (targetEntity.getCurrentProperties().IsSpecializedInShields ? 1.25 : 1.0);
            shieldBonus = ::Math.abs(shieldBonus);
            local shieldwall = targetEntity.getSkills().getSkillByID("effects.shieldwall");
            if (shieldBonus > 0 && shieldwall) {
                local adjacencyBonus = ::Math.abs(shieldwall.getBonus());
                tooltips.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + (shieldBonus) + "%") + " " + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(shieldwall, "entityId:" + targetEntity.getID()))
                });
                if (adjacencyBonus) {
                    tooltips.push({
                        icon = "ui/tooltips/negative.png",
                        text = red("-" + (adjacencyBonus) + "%") + " adjacency bonus"
                    });
                }
            }
        }
    }
    return tooltips;
}


// Alert riposte
local function getHitFactorAlertRiposte(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity && myTile.getDistanceTo(tile) <= 1 && !skill.isIgnoringRiposte())
    {
        local riposte = targetEntity.getSkills().getSkillByID("effects.riposte");
        if (riposte) {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(riposte, "entityId:" + targetEntity.getID()))
            });
        }
    }
    return tooltips;
}


// Alert nine lives
local function getHitFactorAlertNineLives(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity && targetEntity.getSkills().hasSkill("perk.nine_lives"))
    {
        local nineLivesSkill = targetEntity.getSkills().getSkillByID("perk.nine_lives"); // Corrected to use targetEntity

        if (nineLivesSkill != null && !nineLivesSkill.isSpent())
        {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(nineLivesSkill, "entityId:" + targetEntity.getID()))
            });
        }
    }
    return tooltips;
}


// Distance modifier to hitchance
local function getHitFactorDistanceModifier(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.IsRanged)
    {
        if (targetEntity)
        {
            local propertiesWithSkill = skill.m.Container.buildPropertiesForUse(skill, targetEntity);
            local malus = (distanceToTarget - skill.m.MinRange) * propertiesWithSkill.HitChanceAdditionalWithEachTile * propertiesWithSkill.HitChanceWithEachTileMult;
            if (malus < 0) {
                malus = ::Math.abs(malus);
                tooltips.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + malus + "%") + " "
                    + ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill)) + " "
                    + "Distance of " + distanceToTarget,
                });
            }
        }
    }
    return tooltips;
}


// Blocked line-of-sight malus
local function getHitFactorBlockedLineOfSightMalus(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.IsRanged)
    {
        if (skill.m.IsUsingHitchance)
        {
            local blockedTiles = ::Const.Tactical.Common.getBlockedTiles(myTile, tile, user.getFaction(), true);

            if (blockedTiles.len() != 0)
            {
                local propertiesWithSkill = skill.m.Container.buildPropertiesForUse(skill, targetEntity);
                local blockChance = ::Const.Combat.RangedAttackBlockedChance * propertiesWithSkill.RangedAttackBlockedChanceMult;
                blockChance = ::Math.abs(::Math.ceil(blockChance * 100));
                tooltips.push({
                    icon = "ui/tooltips/negative.png",
                    text = red("-" + blockChance + "%") + " " + "Line of fire blocked"
                });
            }
        }
    }
    return tooltips;
}


// Nightime modifier
local function getHitFactorNighttimeModifier(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    local nighttime = user.getSkills().hasSkill("special.night");
    if (skill.m.IsRanged && user.getCurrentProperties().IsAffectedByNight && nighttime)
    {
        tooltips.push({
            icon = "ui/tooltips/negative.png",
            text = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(nighttime, "entityId:" + user.getID())) + " " + red("-" + 30 + "%") + " Ranged Skill"
        });
    }
    return tooltips;
}


// lunge damage modifier
local function getHitFactorLungeDamageModifier(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (skill.m.ID == "actives.lunge" && targetEntity) {
        local diff = getDifferenceInProperty(user, targetEntity, skill, "DamageTotalMult");

        if (diff > 0) {
            tooltips.push({
                icon = "ui/tooltips/positive.png",
                text = "High initiative " + green("+" + diff + "%") + " " + "Lunge damage"
            });
        }
        if (diff < 0) {
            diff = ::Math.abs(diff);
            tooltips.push({
                icon = "ui/tooltips/negative.png",
                text = "Low initiative " + red("-" + diff + "%") + " " + "Lunge damage"
            });
        }
    }
    return tooltips;
}


// Damage resistance
local function getHitFactorDamageResistance(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
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
                    damage_reduction_skill_tt = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(damage_reduction_skill, "entityId:" + targetEntity.getID()));
                }
                local propertiesBefore = targetEntity.getCurrentProperties();
                local hitInfo = clone ::Const.Tactical.HitInfo;
                local propertiesAfter = propertiesBefore.getClone();
                damage_reduction_skill.onBeforeDamageReceived(user, skill, hitInfo, propertiesAfter);

                local paired_properties_description = [
                    ["DamageReceivedRegularMult", "HP damage"],
                    ["DamageReceivedArmorMult", "Armor damage"]
                ]
                foreach (paired_info in paired_properties_description) {
                    local property_name = paired_info[0];
                    local description = paired_info[1];

                    if (property_name in propertiesBefore) {
                        local diff = propertiesBefore[property_name] - propertiesAfter[property_name]
                        diff = ::Math.ceil(diff * 100);

                        if (diff > 0) {
                            tooltips.push({
                                icon = "ui/tooltips/positive.png",
                                text = damage_reduction_skill_tt + " " + green("+" + diff + "%") + " " + description
                            });
                        }

                        if (diff < 0) {
                            diff = ::Math.abs(diff);
                            tooltips.push({
                                icon = "ui/tooltips/negative.png",
                                text = damage_reduction_skill_tt + " " + red("-" + diff + "%") + " " + description
                            });
                        }
                    }
                }
            }
        }
    }
    return tooltips;
}


// Immunity: stun
local function getHitFactorImmunityStun(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        if (targetEntity.getCurrentProperties().IsImmuneToStun && (skill.m.ID == "actives.knock_out" || skill.m.ID == "actives.knock_over" || skill.m.ID == "actives.strike_down"))
        {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = "Immune to stun"
            });
        }
    }
    return tooltips;
}


// Immunity: root
local function getHitFactorImmunityRoot(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        if (targetEntity.getCurrentProperties().IsImmuneToRoot && skill.m.ID == "actives.throw_net")
        {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = "Immune to being rooted"
            });
        }
    }
    return tooltips;
}


// Immunity: disarmed
local function getHitFactorImmunityDisarmed(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        if ((targetEntity.getCurrentProperties().IsImmuneToDisarm || targetEntity.getItems().getItemAtSlot(::Const.ItemSlot.Mainhand) == null) && skill.m.ID == "actives.disarm")
        {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = "Immune to being disarmed"
            });
        }
    }
    return tooltips;
}


// Immunity: forced movement
local function getHitFactorImmunityForcedMovement(skill, tile, user, myTile, targetEntity, distanceToTarget)
{
    local tooltips = [];
    if (targetEntity) {
        if (targetEntity.getCurrentProperties().IsImmuneToKnockBackAndGrab && (skill.m.ID == "actives.knock_back" || skill.m.ID == "actives.hook" || skill.m.ID == "actives.repel"))
        {
            tooltips.push({
                icon = "ui/tooltips/warning.png",
                text = "Immune to being knocked back or hooked"
            });
        }
    }
    return tooltips;
}


::ModMaxiTooltips.TacticalTooltip.hit_factors_tooltip_list <- [
    // Alerts for skills
    getHitFactorAlertNineLives,
    getHitFactorAlertRiposte,

    // Other alerts
    getHitFactorDamageResistance,
    getHitFactorImmunityStun,
    getHitFactorImmunityRoot,
    getHitFactorImmunityDisarmed,
    getHitFactorImmunityForcedMovement,

    // Lunge modifier
    getHitFactorLungeDamageModifier,

    // Hit chance bonus
    getHitFactorSkillHitChanceBonus,
    getHitFactorSkillHitChanceModifier,
    getHitFactorBonusFromSurrounding,
    getHitFactorHeightAdvantage,
    getHitFactorTargetOnBadTerrain,
    getHitFactorFastAdaptationBonus,
    getHitFactorOathOfWrath,

    // Maluses
    getHitFactorSkillTooCloseMalus,
    getHitFactorSkillUniversalMalus,
    getHitFactorHeightDisadvantage,
    getHitFactorMalusFromBadTerrain,
    getHitFactorArmedWithShield,
    getHitFactorShieldwall,
    getHitFactorDistanceModifier,
    getHitFactorBlockedLineOfSightMalus,
    getHitFactorNighttimeModifier,
];


::ModMaxiTooltips.TacticalTooltip.getHitFactors <- function (skill, tile)
{
    local ret = [];
    local user = skill.m.Container.getActor();
    local myTile = user.getTile();
    local targetEntity = tile.IsOccupiedByActor ? tile.getEntity() : null;
    local distanceToTarget = user.getTile().getDistanceTo(tile);

    foreach (single_tooltip_function in ::ModMaxiTooltips.TacticalTooltip.hit_factors_tooltip_list) {
        ret.extend(single_tooltip_function(skill, tile, user, myTile, targetEntity, distanceToTarget));
    }

    return ret
}
