// Functions to compute information about a future damage hit

if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


// Inclusive range
local function range(a, b) {
    local res = [];
    for (local i = a; i <= b; i++) {
        res.push(i);
    }
    return res
}


local function linspace(a, b, n) {
    local step = 1. * (b - a) / (n-1);
    local res = []
    for (local idx = 0.; idx < n; idx++) {
        res.push(idx * step + a);
    }
    return res
}


// Use to represent uniform distributions
// Use range if n is big enough, or linspace
local function interval(a, b, n) {
    local range_len = b + 1 - a;
    if (n >= range_len) {
        return range(a, b);
    } else {
        return linspace(a, b, n);
    }
}


// Compute information about the distribution of `scalar_function`.
// Assumes that `x, y` are two random variables with uniform
// distribution over the intervals [x_min, x_max], [y_min, y_max]
// We want to find information about the distribution of scalar_function(x, y)
//
// This function computes the mean of the distribution and proba of exceeding threshold
::ModMaxiTooltips.TacticalTooltip.getDistributionInfo <- function(x_min, x_max, y_min, y_max, scalar_function, threshold = null)
{

    // Generate array of values
    local x_array = [];
    local y_array = [];
    local marginal_weight_array = [];

    local n = x_max - x_min + 1;
    {
        for (local i = x_min; i <= x_max; i++)
        {
            x_array.push(i);
            y_array.push(i);
            marginal_weight_array.push(1. / n);
        }
    }

    // Iterate all x and y, compute values and joint weights
    local result_array = [];
    local joint_weight_array = [];

    for (local idx = 0; idx < n; idx++)
    {
        for (local jdx = 0; jdx < n; jdx++)
        {
            result_array.push(
                scalar_function(x_array[idx], y_array[jdx])
            );
            joint_weight_array.push(
                marginal_weight_array[idx] * marginal_weight_array[jdx]
            );
        }
    }

    local min = result_array[0];
    local max = result_array[0];
    local sum = 0;
    local proba = 0;

    foreach (idx, result in result_array)
    {
        if (result < min) min = result;

        if (result > max) max = result;

        sum += result * joint_weight_array[idx];

        if (threshold != null && result >= threshold) proba += joint_weight_array[idx];
    }

    return {
        mean = sum,
        proba = proba,
    }
}


// A straight adaptation from the source code
::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll <- function(armor_roll, health_roll, body_part_hit, skill, attacker, target){
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local bodyPartDamageMult = properties.DamageAgainstMult[body_part_hit];

    local distance_to_target = attacker.getTile().getDistanceTo(target.getTile());

    local damageMult = skill.isRanged() ? properties.RangedDamageMult : properties.MeleeDamageMult;
    damageMult = damageMult * properties.DamageTotalMult;
    local damageRegular = health_roll * properties.DamageRegularMult;
    local damageArmor = armor_roll * properties.DamageArmorMult;
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

    attacker.m.Skills.onBeforeTargetHit(skill, target, hit_info);

    if (target.m.Skills.hasSkill("perk.steel_brow"))
    {
        hit_info.BodyDamageMult = 1.0;
    }

    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);
    target.m.Items.onBeforeDamageReceived(attacker, skill, hit_info, other_properties);
    local dmgMult = other_properties.DamageReceivedTotalMult;

    dmgMult = dmgMult * (skill.isRanged() ? other_properties.DamageReceivedRangedMult : other_properties.DamageReceivedMeleeMult);

    hit_info.DamageRegular -= other_properties.DamageRegularReduction;
    hit_info.DamageArmor -= other_properties.DamageArmorReduction;
    hit_info.DamageRegular *= other_properties.DamageReceivedRegularMult * dmgMult;
    hit_info.DamageArmor *= other_properties.DamageReceivedArmorMult * dmgMult;
    local armor = 0;
    local armorDamage = 0;
    local armor_damage_pre_reduction = 0;

    if (hit_info.DamageDirect < 1.0)
    {
        armor = other_properties.Armor[body_part_hit] * other_properties.ArmorMult[body_part_hit];
        armor_damage_pre_reduction = hit_info.DamageArmor;
        armorDamage = ::Math.min(armor, hit_info.DamageArmor);
        armor = armor - armorDamage;
        hit_info.DamageInflictedArmor = ::Math.max(0, armorDamage);
    }

    local damage = 0;
    damage = damage + ::Math.maxf(0.0, hit_info.DamageRegular * hit_info.DamageDirect * other_properties.DamageReceivedDirectMult - armor * this.Const.Combat.ArmorDirectDamageMitigationMult);

    if (armor <= 0 || hit_info.DamageDirect >= 1.0)
    {
        damage = damage + ::Math.max(0, hit_info.DamageRegular * ::Math.maxf(0.0, 1.0 - hit_info.DamageDirect * other_properties.DamageReceivedDirectMult) - armorDamage);
    }

    damage = damage * hit_info.BodyDamageMult;
    damage = ::Math.max(0, ::Math.max(::Math.round(damage), ::Math.min(::Math.round(hit_info.DamageMinimum), ::Math.round(hit_info.DamageMinimum * other_properties.DamageReceivedTotalMult))));

    if (ModMaxiTooltips.Mod.ModSettings.getSetting("clip_health_damage").getValue()) {
        damage = ::Math.min(damage, target.m.Hitpoints);
    }
    if (ModMaxiTooltips.Mod.ModSettings.getSetting("clip_armor_damage").getValue()) {
        armor_damage_pre_reduction = ::Math.min(damage, defender_properties.Armor[body_part_hit] * defender_properties.ArmorMult[body_part_hit]);
    }

    return {
        health_damage=damage,
        armor_damage=armor_damage_pre_reduction
    }
}


// A small util
::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance <- function(attacker, target, skill){
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);
    return head_hit_chance;
}


// Compute the damage of attacker attacking target with skill
// Super slow but should be the most accurate
// Used for tests
::ModMaxiTooltips.TacticalTooltip.attack_info_summary__slow__exact <- function(attacker, target, skill)
{
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);

    local hit_info = clone ::Const.Tactical.HitInfo;
    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);

    local body_armor = other_properties.Armor[::Const.BodyPart.Body] * other_properties.ArmorMult[::Const.BodyPart.Body];
    local head_armor = other_properties.Armor[::Const.BodyPart.Head] * other_properties.ArmorMult[::Const.BodyPart.Head];
    local health = target.m.Hitpoints;

    local function curried_damage_body_armor(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).armor_damage
    }
    local function  curried_damage_body_health(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).health_damage
    }
    local function  curried_damage_head_armor(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).armor_damage
    }
    local function  curried_damage_head_health(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).health_damage
    }

    local distribution_body_armor = ::ModMaxiTooltips.TacticalTooltip.getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_body_armor,
        body_armor
    );
    local distribution_body_health = ::ModMaxiTooltips.TacticalTooltip.getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_body_health,
        health
    );
    local distribution_head_armor = ::ModMaxiTooltips.TacticalTooltip.getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_head_armor,
        head_armor
    );
    local distribution_head_health = ::ModMaxiTooltips.TacticalTooltip.getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_head_health,
        health
    );

    local kill_proba = (head_hit_chance * distribution_head_health.proba + (100 - head_hit_chance) * distribution_body_health.proba);

    // Todo update to new format
    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = health,
            body_armor = body_armor,
            head_armor = head_armor,
        }

        distribution_body_armor = distribution_body_armor,
        distribution_body_health = distribution_body_health,
        distribution_head_armor = distribution_head_armor,
        distribution_head_health = distribution_head_health,
    }

    local summary_head = {
        health_damage = distribution_head_health.mean,
        body_armor_damage = 0,
        head_armor_damage = distribution_head_armor.mean,
        kill_proba = distribution_head_health.proba,
        hit_chance = head_hit_chance,
    };

    local summary_body = {
        health_damage = distribution_body_health.mean,
        body_armor_damage = distribution_body_armor.mean,
        head_armor_damage = 0,
        kill_proba = distribution_body_health.proba,
        hit_chance = head_hit_chance,
    };

    local kill_chance = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba) / 100;

    return {
        head = summary_head,
        body = summary_body,
        kill_chance = kill_chance,
    }
}


// Compute all key parameters that matter for an attack in a single pass
// A lot of heavy inspection and refactoring of the vanilla code
::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack <- function(attacker, target, skill, body_part_hit) {
    local attacker_properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local bodyPartDamageMult = attacker_properties.DamageAgainstMult[body_part_hit];

    local distance_to_target = attacker.getTile().getDistanceTo(target.getTile());

    local attacker_damage_mult = skill.isRanged() ? attacker_properties.RangedDamageMult : attacker_properties.MeleeDamageMult;
    attacker_damage_mult = attacker_damage_mult * attacker_properties.DamageTotalMult;

    local damageDirectCoefficient = ::Math.minf(1.0, attacker_properties.DamageDirectMult * (skill.m.DirectDamageMult + attacker_properties.DamageDirectAdd + (skill.isRanged() ? attacker_properties.DamageDirectRangedAdd : attacker_properties.DamageDirectMeleeAdd)));

    local hit_info = clone ::Const.Tactical.HitInfo;
    hit_info.DamageRegular = 0;
    hit_info.DamageArmor = 0;
    hit_info.DamageDirect = damageDirectCoefficient;
    hit_info.DamageFatigue = ::Const.Combat.FatigueReceivedPerHit * attacker_properties.FatigueDealtPerHitMult;
    hit_info.DamageMinimum = attacker_properties.DamageMinimum;
    hit_info.BodyPart = body_part_hit;
    hit_info.BodyDamageMult = bodyPartDamageMult;
    hit_info.FatalityChanceMult = attacker_properties.FatalityChanceMult;
    // hit_info.Injuries = None;
    hit_info.InjuryThresholdMult = attacker_properties.ThresholdToInflictInjuryMult;
    hit_info.Tile = target.getTile();

    // adapted from _info.Container.onBeforeTargetHit(_info.Skill, _info.TargetEntity, hit_info);
    attacker.m.Skills.onBeforeTargetHit(skill, target, hit_info);

    local defender_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);
    target.m.Items.onBeforeDamageReceived(attacker, skill, hit_info, defender_properties);

    if (target.m.CurrentProperties.IsImmuneToCriticals || target.m.CurrentProperties.IsImmuneToHeadshots)
    {
        hit_info.BodyDamageMult = 1.0;
    }

    local target_damage_mult = defender_properties.DamageReceivedTotalMult;

    // REMOVED A CONDITIONAL if (skill != null)
    target_damage_mult = target_damage_mult * (skill.isRanged() ? defender_properties.DamageReceivedRangedMult : defender_properties.DamageReceivedMeleeMult);

    local parameters = {
        armor=defender_properties.Armor[body_part_hit] * defender_properties.ArmorMult[body_part_hit],
        health=target.m.Hitpoints,
        min_damage=attacker_properties.DamageRegularMin,
        max_damage=attacker_properties.DamageRegularMax,
        guaranteed_damage=::Math.min(::Math.round(hit_info.DamageMinimum), ::Math.round(hit_info.DamageMinimum * defender_properties.DamageReceivedTotalMult)),
        direct_damage_coefficient=hit_info.DamageDirect,
        direct_damage_coefficient_multiplier=defender_properties.DamageReceivedDirectMult,
        health_multiplier=attacker_properties.DamageRegularMult * attacker_damage_mult * defender_properties.DamageReceivedRegularMult * target_damage_mult,
        armor_multiplier=attacker_properties.DamageArmorMult * attacker_damage_mult * defender_properties.DamageReceivedArmorMult * target_damage_mult,
        bodypart_damage_mult=hit_info.BodyDamageMult
    };

    return parameters
}


::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll <- function(armor_roll, health_roll, parameters) {
    local damageRegular = health_roll * parameters.health_multiplier;
    local damageArmor = armor_roll * parameters.armor_multiplier;

    local armor = 0;
    local armorDamage = 0;

    local damage_reduction_from_armor = 0;
    local armor_damage = 0;
    local health_damage_direct = 0;
    local health_damage_armor_break = 0;

    if (parameters.direct_damage_coefficient >= 1.0) {
        damage_reduction_from_armor = 0;
        health_damage_direct = ::Math.maxf(0.0, damageRegular - damage_reduction_from_armor);
        damageArmor = 0;
    } else {
        armor = parameters.armor;
        armorDamage = ::Math.max(0, ::Math.min(armor, damageArmor));
        armor = armor - armorDamage;
        armor_damage = ::Math.max(0, armorDamage);

        damage_reduction_from_armor = armor * ::Const.Combat.ArmorDirectDamageMitigationMult;
        health_damage_direct = ::Math.maxf(0.0, damageRegular * parameters.direct_damage_coefficient * parameters.direct_damage_coefficient_multiplier - damage_reduction_from_armor);

        health_damage_armor_break = 0
        if (armor <= 0)
        {
            health_damage_armor_break = ::Math.maxf(0, damageRegular * ::Math.maxf(0.0, 1.0 - parameters.direct_damage_coefficient * parameters.direct_damage_coefficient_multiplier) - armorDamage);
        }
    }

    local damage = health_damage_direct + health_damage_armor_break;

    damage *= parameters.bodypart_damage_mult;

    local guaranteed_damage = 0
    if (parameters.guaranteed_damage > 0 && parameters.guaranteed_damage > damage) {
        guaranteed_damage = parameters.guaranteed_damage;
        damage = guaranteed_damage;
        health_damage_direct = 0;
        health_damage_armor_break = 0;
    }
    damage = ::Math.max(0, ::Math.round(damage));

    if (ModMaxiTooltips.Mod.ModSettings.getSetting("clip_health_damage").getValue()) {
        damage = ::Math.min(damage, parameters.health);
    }
    if (ModMaxiTooltips.Mod.ModSettings.getSetting("clip_armor_damage").getValue()) {
        damageArmor = ::Math.min(damageArmor, parameters.armor);
    }

    return {
        health_damage=damage,
        armor_damage=damageArmor
    }
}


// Analyze armor break from parameters
// Return
// - proba_armor_destroy: float
// - destroy_point: int or None
// - representation: list[tuple[proba: float, a: int, b: int, num: int]]
//   a list of probability and intervals to use to represent armor, for sampling
// A representation involves at max `armor_roll_number_of_points` points
::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params <- function(parameters, armor_roll_number_of_points) {
    // Armor ignoring attack
    if (parameters.armor == 0 || parameters.direct_damage_coefficient >= 1.0) {
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.max_damage, 2]]
        }
    }

    local max_damage = parameters.max_damage * parameters.armor_multiplier;

    // Armor destroy is impossible: sample uniformly over the interval
    if (max_damage < parameters.armor) {
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.max_damage, armor_roll_number_of_points]]
        }
    }

    local min_damage = parameters.min_damage * parameters.armor_multiplier;

    // Armor destroy is certain: use a two point representation
    if (min_damage >= parameters.armor) {
        return {
            proba_armor_destroy=1.,
            destroy_point=parameters.min_damage,
            representation=[[1., parameters.min_damage, parameters.max_damage, 2]]
        }
    }

    // Find destroy_point
    local armor_roll_interval = range(parameters.min_damage, parameters.max_damage);
    local weight = 1./armor_roll_interval.len();
    local destroy_point;
    local proba_armor_destroy;
    foreach (idx, armor_roll in armor_roll_interval) {
        if ((armor_roll * parameters.armor_multiplier) > parameters.armor) {
            destroy_point = armor_roll;
            proba_armor_destroy = (armor_roll_interval.len() - idx) * weight;
            break
        }
    }

    // Two separate ranges:
    // - Two points in the destroy_armor range
    // - The remainder covering low damage values
    local representation = [
        [1 - proba_armor_destroy, parameters.min_damage, destroy_point - 1, armor_roll_number_of_points - 1],
        [proba_armor_destroy, destroy_point, parameters.max_damage, 2]
    ]

    return {
        proba_armor_destroy=proba_armor_destroy,
        destroy_point=destroy_point,
        representation=representation
    }
}


// A smart approximation of the damage calculation.
// Instead of computing the damage for all possible values of the damage roll, restrict the number of samples
// - sample at most `armor_roll_number_of_points` armor roll values
// - sample at most `maximum_sampling_points` overall
::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast <- function(parameters, bodypart) {
    local maximum_sampling_points = ::ModMaxiTooltips.Mod.ModSettings.getSetting("num_samples_total").getValue();;
    local num_samples_armor = ::ModMaxiTooltips.Mod.ModSettings.getSetting("num_samples_armor").getValue();;
    local armor_roll_number_of_points = num_samples_armor;

    local damage_range_length = parameters.max_damage - parameters.min_damage + 1;

    // The point budget is large enough: do not restrict armor_roll at all
    if (maximum_sampling_points >= damage_range_length * damage_range_length) {
        armor_roll_number_of_points = damage_range_length;
    }

    local armor_destroy_res = ::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params(parameters, armor_roll_number_of_points);

    local armor_roll_array = [];
    local weight_armor_array = [];
    foreach (interval_info in armor_destroy_res.representation) {
        local proba = interval_info[0];
        local local_array = interval(interval_info[1], interval_info[2], interval_info[3]);
        foreach (value in local_array) {
            armor_roll_array.push(value);
            weight_armor_array.push(proba * 1. / local_array.len())
        }
    }

    local num_points_health = ::Math.ceil(maximum_sampling_points / armor_roll_array.len());

    local health_roll_array = interval(parameters.min_damage, parameters.max_damage, num_points_health);
    local weight_health = 1. / health_roll_array.len();

    local health_damage=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in armor_roll_array) {
        local weight_armor = weight_armor_array[idx];
        foreach (jdx, health_roll in health_roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);

            health_damage += weight_armor * weight_health * res.health_damage;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            // proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage = health_damage,
        body_armor_damage = bodypart == "body"? armor_damage : 0,
        head_armor_damage = bodypart != "body"? armor_damage : 0,
        kill_proba = kill_proba,
        hit_chance = 0      // placeholder
    }
}


// Compute and format information for tooltip from attacker, target, skill triplet
::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_head, "head");
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_body, "body");

    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local kill_chance = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local hitchance = skill.getHitchance(target);
    local marginal_kill_chance = kill_chance * hitchance / 100;

    summary_head.hit_chance = head_hit_chance;
    summary_body.hit_chance = 100 - head_hit_chance;

    return {
        head = summary_head,
        body = summary_body,
        kill_chance = kill_chance,
        marginal_kill_chance = marginal_kill_chance
    }
}

