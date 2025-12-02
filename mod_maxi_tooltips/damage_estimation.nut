if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


local function damageFromRolls(armor_roll, health_roll, body_part_hit, skill, attacker, target){
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local bodyPartDamageMult = properties.DamageAgainstMult[body_part_hit];

    local distance_to_target = attacker.getTile().getDistanceTo(target.getTile());

    local damageMult = skill.isRanged() ? properties.RangedDamageMult : properties.MeleeDamageMult;
    damageMult = damageMult * properties.DamageTotalMult;
    local damageRegular = armor_roll * properties.DamageRegularMult;
    local damageArmor = health_roll * properties.DamageArmorMult;
    damageRegular = ::Math.max(0, damageRegular + distance_to_target * properties.DamageAdditionalWithEachTile);
    damageArmor = ::Math.max(0, damageArmor + distance_to_target * properties.DamageAdditionalWithEachTile);
    local damageDirect = ::Math.minf(1.0, properties.DamageDirectMult * (skill.m.DirectDamageMult + properties.DamageDirectAdd + (skill.isRanged() ? properties.DamageDirectRangedAdd : properties.DamageDirectMeleeAdd)));
    local injuries;

    if (skill.m.InjuriesOnBody != null && body_part_hit == ::Const.BodyPart.Body)
    {
        injuries = skill.m.InjuriesOnBody;
    }
    else if (skill.m.InjuriesOnHead != null && body_part_hit == ::Const.BodyPart.Head)
    {
        injuries = skill.m.InjuriesOnHead;
    }

    local hit_info = clone ::Const.Tactical.HitInfo;
    hit_info.DamageRegular = damageRegular * damageMult;
    hit_info.DamageArmor = damageArmor * damageMult;
    hit_info.DamageDirect = damageDirect;
    hit_info.DamageFatigue = ::Const.Combat.FatigueReceivedPerHit * properties.FatigueDealtPerHitMult;
    hit_info.DamageMinimum = properties.DamageMinimum;
    hit_info.BodyPart = body_part_hit;
    hit_info.BodyDamageMult = bodyPartDamageMult;
    hit_info.FatalityChanceMult = properties.FatalityChanceMult;
    hit_info.Injuries = injuries;
    hit_info.InjuryThresholdMult = properties.ThresholdToInflictInjuryMult;
    hit_info.Tile = target.getTile();

    // adapted from _info.Container.onBeforeTargetHit(_info.Skill, _info.TargetEntity, hit_info);
    attacker.m.Skills.onBeforeTargetHit(skill, target, hit_info);

    if (target.m.Skills.hasSkill("perk.steel_brow"))
    {
        hit_info.BodyDamageMult = 1.0;
    }

    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);
    target.m.Items.onBeforeDamageReceived(attacker, skill, hit_info, other_properties);
    local dmgMult = other_properties.DamageReceivedTotalMult;

    // REMOVED A CONDITIONAL if (skill != null)
    dmgMult = dmgMult * (skill.isRanged() ? other_properties.DamageReceivedRangedMult : other_properties.DamageReceivedMeleeMult);

    hit_info.DamageRegular -= other_properties.DamageRegularReduction;
    hit_info.DamageArmor -= other_properties.DamageArmorReduction;
    hit_info.DamageRegular *= other_properties.DamageReceivedRegularMult * dmgMult;
    hit_info.DamageArmor *= other_properties.DamageReceivedArmorMult * dmgMult;
    local armor = 0;
    local armorDamage = 0;

    if (hit_info.DamageDirect < 1.0)
    {
        armor = other_properties.Armor[body_part_hit] * other_properties.ArmorMult[body_part_hit];
        armorDamage = ::Math.min(armor, hit_info.DamageArmor);
        armor = armor - armorDamage;
        hit_info.DamageInflictedArmor = ::Math.max(0, armorDamage);
    }

    hit_info.DamageFatigue *= other_properties.FatigueEffectMult * other_properties.FatigueReceivedPerHitMult * target.m.CurrentProperties.FatigueLossOnAnyAttackMult;
    // THIS UPDATES !! target.m.Fatigue = ::Math.min(this.getFatigueMax(), ::Math.round(target.m.Fatigue + hit_info.DamageFatigue * other_properties.FatigueReceivedPerHitMult * target.m.CurrentProperties.FatigueLossOnAnyAttackMult));

    local damage = 0;
    damage = damage + ::Math.maxf(0.0, hit_info.DamageRegular * hit_info.DamageDirect * other_properties.DamageReceivedDirectMult - armor * this.Const.Combat.ArmorDirectDamageMitigationMult);

    if (armor <= 0 || hit_info.DamageDirect >= 1.0)
    {
        damage = damage + ::Math.max(0, hit_info.DamageRegular * ::Math.maxf(0.0, 1.0 - hit_info.DamageDirect * other_properties.DamageReceivedDirectMult) - armorDamage);
    }

    damage = damage * hit_info.BodyDamageMult;
    damage = ::Math.max(0, ::Math.max(::Math.round(damage), ::Math.min(::Math.round(hit_info.DamageMinimum), ::Math.round(hit_info.DamageMinimum * other_properties.DamageReceivedTotalMult))));
    hit_info.DamageInflictedHitpoints = damage;

    return hit_info
}

// Compute the damage of attacker attacking target with skill
::ModMaxiTooltips.TacticalTooltip.attack_info_summary <- function(attacker, target, skill)
{
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);
    
    local armor_roll = ::Math.rand(properties.DamageRegularMin, properties.DamageRegularMax);
    local health_roll = ::Math.rand(properties.DamageRegularMin, properties.DamageRegularMax);

    local body_part_hit = ::Const.BodyPart.Body;

    local res_min_body = damageFromRolls(properties.DamageRegularMin, properties.DamageRegularMin, ::Const.BodyPart.Body, skill, attacker, target);
    local res_max_body = damageFromRolls(properties.DamageRegularMax, properties.DamageRegularMax, ::Const.BodyPart.Body, skill, attacker, target);

    local res_min_head = damageFromRolls(properties.DamageRegularMin, properties.DamageRegularMin, ::Const.BodyPart.Head, skill, attacker, target);
    local res_max_head = damageFromRolls(properties.DamageRegularMax, properties.DamageRegularMax, ::Const.BodyPart.Head, skill, attacker, target);

    local ret = {
        head_hit_chance = head_hit_chance,

        body_damage_mult = res_min_body.BodyDamageMult,
        head_damage_mult = res_min_head.BodyDamageMult,

        min_body_ad = res_min_body.DamageInflictedArmor,
        min_body_hd = res_min_body.DamageInflictedHitpoints,

        max_body_ad = res_max_body.DamageInflictedArmor,
        max_body_hd = res_max_body.DamageInflictedHitpoints,

        min_head_ad = res_min_head.DamageInflictedArmor,
        min_head_hd = res_min_head.DamageInflictedHitpoints,

        max_head_ad = res_max_head.DamageInflictedArmor,
        max_head_hd = res_max_head.DamageInflictedHitpoints,
    }

    return ret
}

local function icon_and_text(icon_path, value, other_value = null) {
    local text = format("<span> <img src='coui://gfx/ui/icons/%s'/>  %i </span>", icon_path, value);
    if (other_value != null && other_value != value){
        text = format("<span> <img src='coui://gfx/ui/icons/%s'/>  %i - %i </span>", icon_path, value, other_value);
    }
    return text 
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip <- function(attacker, target, skill){
    local info = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary(attacker, target, skill)

    ::logWarning("MaxiTT: attack_info_summary");
    ::MSU.Log.printData(info);

    local tooltip = []

    if (info.head_hit_chance > 0) {
        local text_head = icon_and_text("chance_to_hit_head.png", info.head_hit_chance);
        if (info.max_head_ad > 0) {
            text_head = text_head + icon_and_text("armor_damage.png", info.min_head_ad, info.max_head_ad);
        }
        if (info.max_head_hd) {
            text_head = text_head + icon_and_text("regular_damage.png", info.min_head_hd, info.max_head_hd);
        }
        tooltip.push({
            type = "text",
            text = text_head,
            rawHTMLInText = true
        })
    }

    local text_body = "";
    if ((100 - info.head_hit_chance) > 0) {
        text_body = text_body + icon_and_text("hitchance.png", 100 - info.head_hit_chance);
    }
    if (info.max_head_ad > 0 && info.body_damage_mult != info.head_damage_mult) {
        text_body = text_body + icon_and_text("armor_damage.png", info.min_body_ad, info.max_body_ad);
    }
    if (info.max_head_hd && info.body_damage_mult != info.head_damage_mult) {
        text_body = text_body + icon_and_text("regular_damage.png", info.min_body_hd, info.max_body_hd);
    }
    tooltip.push({
        type = "text",
        text = text_body,
        rawHTMLInText = true
    })

    return tooltip
}
