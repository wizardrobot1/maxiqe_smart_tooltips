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


::ModMaxiTooltips.TacticalTooltip.getDistributionInfo <- function(x_min, x_max, y_min, y_max, scalar_function, threshold = null)
{
    // Compute information about the distribution of `scalar_function`.
    // Assumes that `x, y` are two random variables with uniform 
    // distribution over the intervals [x_min, x_max], [y_min, y_max]
    // We want to find information about the distribution of scalar_function(x, y)
    //
    // This function computes the min, max, mean of the distribution
    
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
        // min = min,
        // max = max,
        mean = sum,
        proba = proba,
    }
}


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

    return {
        health_damage=damage,
        armor_damage=::Math.max(0, hit_info.DamageArmor)
    }
}

::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance <- function(attacker, target, skill){
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);
    return head_hit_chance;
}

// Super slow but exact
// Compute the damage of attacker attacking target with skill
::ModMaxiTooltips.TacticalTooltip.attack_info_summary__slow__exact <- function(attacker, target, skill)
{
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);
    local res_min_body = ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(properties.DamageRegularMin, properties.DamageRegularMin, ::Const.BodyPart.Body, skill, attacker, target);

    local hit_info = clone ::Const.Tactical.HitInfo;
    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);

    local body_armor = other_properties.Armor[::Const.BodyPart.Body] * other_properties.ArmorMult[::Const.BodyPart.Body];
    local head_armor = other_properties.Armor[::Const.BodyPart.Head] * other_properties.ArmorMult[::Const.BodyPart.Head];
    local health = target.m.Hitpoints;

    local function curried_damage_body_armor(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).DamageInflictedArmor
    }
    local function  curried_damage_body_health(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).DamageInflictedHitpoints
    }
    local function  curried_damage_head_armor(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).DamageInflictedArmor
    }
    local function  curried_damage_head_health(x, y) {
        return ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).DamageInflictedHitpoints
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

    return ret
}



::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack <- function(attacker, target, skill, body_part_hit) {
        // Get information from attack
    local attacker_properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local bodyPartDamageMult = attacker_properties.DamageAgainstMult[body_part_hit];

    

    local distance_to_target = attacker.getTile().getDistanceTo(target.getTile());

    local attacker_damage_mult = skill.isRanged() ? attacker_properties.RangedDamageMult : attacker_properties.MeleeDamageMult;
    attacker_damage_mult = attacker_damage_mult * attacker_properties.DamageTotalMult;
    
    local damageDirectCoefficient = ::Math.minf(1.0, attacker_properties.DamageDirectMult * (skill.m.DirectDamageMult + attacker_properties.DamageDirectAdd + (skill.isRanged() ? attacker_properties.DamageDirectRangedAdd : attacker_properties.DamageDirectMeleeAdd)));

    // // Unused in vanilla
    // assert(attacker_properties.DamageAdditionalWithEachTile == 0, "Expected properties.DamageAdditionalWithEachTile = 0 but got instead: " + attacker_properties.DamageAdditionalWithEachTile)

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

local default_parameters = {
    armor=100,
    health=100,
    min_damage=40,
    max_damage=80,
    guaranteed_damage=0,
    direct_damage_coefficient=0.4,
    direct_damage_coefficient_multiplier=1,
    health_multiplier=1,
    armor_multiplier=1,
    bodypart_damage_mult=1
}


::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll <- function(armor_roll, health_roll, parameters) {
    // ::MSU.Table.merge(parameters, default_parameters);
    
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
        armorDamage = ::Math.min(armor, damageArmor);
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

    // damage = ::Math.min(damage, parameters.health);

    return {
        health_damage=damage,
        health_damage_direct=health_damage_direct,
        health_damage_armor_break=health_damage_armor_break,
        guaranteed_damage=guaranteed_damage,
        damage_reduction_from_armor=damage_reduction_from_armor,
        armor_damage=::Math.max(0, damageArmor)
    }
}


::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact <- function(parameters) {
    local roll_array = range(parameters.min_damage, parameters.max_damage);
    local weight = 1. / roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in roll_array) {
        foreach (jdx, health_roll in roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);
            local weight_armor = weight;
            local weight_health = weight;

            health_damage += weight_armor * weight_health * res.health_damage;
            health_damage_direct += weight_armor * weight_health * res.health_damage_direct;
            health_damage_armor_break += weight_armor * weight_health * res.health_damage_armor_break;
            guaranteed_damage += weight_armor * weight_health * res.guaranteed_damage;
            damage_reduction_from_armor += weight_armor * weight_health * res.damage_reduction_from_armor;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}


// Analyze armor break from parameters
// Return
// - proba_armor_destroy: float
// - destroy_point: int or None
// - representation: list[tuple[proba: float, a: int, b: int, num: int]]
//   a list of probability and intervals to use to represent armor, for sampling
//   Total number of points should be 7 to do 7 x 15 samples
::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params <- function(parameters) {
    local total_number_of_points = 7;

    // Armor ignoring attack
    if (parameters.armor == 0 || parameters.direct_damage_coefficient >= 1.0) {
        // Note the double-min: we don't need to care about armor value at all
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.min_damage, 1]]
        }
    }

    local max_damage = parameters.max_damage * parameters.armor_multiplier;

    // Armor destroy is impossible: sample uniformly over the interval
    if (max_damage < parameters.armor) {
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.max_damage, total_number_of_points]]
        }
    }

    local min_damage = parameters.min_damage * parameters.armor_multiplier;

    // Armor destroy is certain: use only the max damage
    if (min_damage >= parameters.armor) {
        return {
            proba_armor_destroy=1.,
            destroy_point=parameters.min_damage,
            representation=[[1., parameters.max_damage, parameters.max_damage, 1]]
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

    // A single point in the destroy_armor range and the remainder at low damage values
    local representation = [
        [1 - proba_armor_destroy, parameters.min_damage, destroy_point - 1, total_number_of_points - 1],
        [proba_armor_destroy, parameters.max_damage, parameters.max_damage, 1]
    ]

    return {
        proba_armor_destroy=proba_armor_destroy,
        destroy_point=destroy_point,
        representation=representation
    }
}

::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast <- function(parameters) {
    local num_points_total = 105;

    local armor_destroy_res = ::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params(parameters);

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

    local num_points_health = ::Math.ceil(num_points_total / armor_roll_array.len());

    local health_roll_array = interval(parameters.min_damage, parameters.max_damage, num_points_health);
    local weight_health = 1. / health_roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in armor_roll_array) {
        local weight_armor = weight_armor_array[idx];
        foreach (jdx, health_roll in health_roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);

            health_damage += weight_armor * weight_health * res.health_damage;
            health_damage_direct += weight_armor * weight_health * res.health_damage_direct;
            health_damage_armor_break += weight_armor * weight_health * res.health_damage_armor_break;
            guaranteed_damage += weight_armor * weight_health * res.guaranteed_damage;
            damage_reduction_from_armor += weight_armor * weight_health * res.damage_reduction_from_armor;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}


::ModMaxiTooltips.TacticalTooltip.damage_direct__summary__smartfast <- function(body_part_hit, skill, attacker, target) {
    local num_points_total = 105;
    
    local parameters = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, body_part_hit);

    local armor_destroy_res = ::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params(parameters);

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

    local num_points_health = ::Math.ceil(num_points_total / armor_roll_array.len());

    local health_roll_array = interval(parameters.min_damage, parameters.max_damage, num_points_health);
    local weight_health = 1. / health_roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in armor_roll_array) {
        local weight_armor = weight_armor_array[idx];
        foreach (jdx, health_roll in health_roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_direct__with_roll(armor_roll, health_roll, body_part_hit, skill, attacker, target);

            health_damage += weight_armor * weight_health * res.health_damage;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}




::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__exact <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact(parameters_head);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact(parameters_body);

    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}





::ModMaxiTooltips.TacticalTooltip.attack_info_summary_direct__smartfast <- function(attacker, target, skill) {
    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_direct__summary__smartfast(::Const.BodyPart.Head, skill, attacker, target);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_direct__summary__smartfast(::Const.BodyPart.Body, skill, attacker, target);

    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}



::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_head);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_body);

    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}

