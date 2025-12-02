if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


::ModMaxiTooltips.TacticalTooltip.getDistributionInfoMC <- function(x_min, x_max, y_min, y_max, scalar_function, threshold = null, n = null)
{
    // Compute information about the distribution of `scalar_function`.
    // Assumes that `x, y` are two random variables with uniform 
    // distribution over the intervals [x_min, x_max], [y_min, y_max]
    // We want to find information about the distribution of scalar_function(x, y)
    //
    // This function computes the min, max, mean of the distribution
    
    if (n == null) n = 21;

    n = n * n;

    // Convert to float
    x_min = 1. * x_min;
    x_max = 1. * x_max;
    y_min = 1. * y_min;
    y_max = 1. * y_max;

    // Generate table of values
    local x_array = [x_min, x_min, x_max, x_max];
    local y_array = [y_min, y_max, y_min, y_max];

    for (local i = 0; i < n; i++)
    {
        x_array.push(::Math.rand(x_min, x_max));
        y_array.push(::Math.rand(y_min, y_max));
        if (i < 20) ::logError("x_array : " + x_array[i]);
    }

    // Iterate all x and y, compute values and joint weights
    local result_array = [];

    for (local idx = 0; idx < n; idx++)
    {
        result_array.push(
            scalar_function(x_array[idx], y_array[idx])
        );
    }

    local min = result_array[0];
    local max = result_array[0];
    local sum = 0;
    local proba = 0;

    foreach (idx, result in result_array)
    {
        if (result < min) min = result;

        if (result > max) max = result;

        sum += result * 1. / x_array.len();

        if (threshold != null && result >= threshold) proba += 1. / x_array.len();
    }

    return {
        min = min,
        max = max,
        mean = sum,
        proba = proba,
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
        min = min,
        max = max,
        mean = sum,
        proba = proba,
    }
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
    local res_min_body = damageFromRolls(properties.DamageRegularMin, properties.DamageRegularMin, ::Const.BodyPart.Body, skill, attacker, target);

    local hit_info = clone ::Const.Tactical.HitInfo;
    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);

    local body_armor = other_properties.Armor[::Const.BodyPart.Body] * other_properties.ArmorMult[::Const.BodyPart.Body];
    local head_armor = other_properties.Armor[::Const.BodyPart.Head] * other_properties.ArmorMult[::Const.BodyPart.Head];
    local health = target.m.Hitpoints;

    local function curried_damage_body_armor(x, y) {
        return damageFromRolls(x, y, ::Const.BodyPart.Body, skill, attacker, target).DamageInflictedArmor
    }
    local function  curried_damage_body_health(x, y) {
        return damageFromRolls(x, y, ::Const.BodyPart.Body, skill, attacker, target).DamageInflictedHitpoints
    }
    local function  curried_damage_head_armor(x, y) {
        return damageFromRolls(x, y, ::Const.BodyPart.Head, skill, attacker, target).DamageInflictedArmor
    }
    local function  curried_damage_head_health(x, y) {
        return damageFromRolls(x, y, ::Const.BodyPart.Head, skill, attacker, target).DamageInflictedHitpoints
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


local function tooltip_fragment(icon_name, values, max = null) {
    local join = "";
    foreach(idx,val in values) {
        local val_str;
        if (typeof val == "float" && (10 * val) % 10 != 0 && val < 100) {
            val_str = format("<b>%2.1f</b>", val);
        } else {
            val_str = format("<b>%i</b>", ::Math.round(val));
        }
        if (max != null && val >= max) {
            val_str = "<b>" + val_str + "</b>";
        }

        join += val_str;
        if (idx < values.len() - 1) {
            join += " - ";
        }
    }

    return format("<img src='coui://gfx/ui/icons/%s'/> <span> %s </span>", icon_name, join)
}


local function tooltip_fragment_from_distribution(icon_name, distribution_info, max = null) {
    local values = [distribution_info.min, distribution_info.mean, distribution_info.max];
    return tooltip_fragment(icon_name, values, max)
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip <- function(attacker, target, skill){
    local info = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary(attacker, target, skill)

    ::logError("MaxiTT: attack_info_tooltip; info = ");
    ::MSU.Log.printData(info, 2);

    local tooltip = [];

    {
        local target_text = "<div class='maxi-damage-tooltip'>";
        target_text += tooltip_fragment("health.png", [info.target.health]);
        target_text += tooltip_fragment("armor_head.png", [info.target.head_armor]);
        target_text += tooltip_fragment("armor_body.png", [info.target.body_armor]);
        target_text += "</div>";
        tooltip.push({
            type = "text",
            text = target_text,
            rawHTMLInText = true
        })
    }

    {
        local text_head = "<div class='maxi-damage-tooltip'>";
        text_head += tooltip_fragment_from_distribution("regular_damage.png", info.distribution_head_health, info.target.health);
        text_head += tooltip_fragment_from_distribution("armor_damage.png", info.distribution_head_armor, info.target.head_armor);
        text_head += tooltip_fragment("chance_to_hit_head.png", [info.head_hit_chance]);
        text_head += "</div>"

        tooltip.push({
            type = "text",
            text = text_head,
            rawHTMLInText = true
        })
    }
    
    {
        local text_body = "<div class='maxi-damage-tooltip'>";
        text_body += tooltip_fragment_from_distribution("regular_damage.png", info.distribution_body_health, info.target.health);
        text_body += tooltip_fragment_from_distribution("armor_damage.png", info.distribution_body_armor, info.target.body_armor);
        text_body += tooltip_fragment("hitchance.png", [100 - info.head_hit_chance]);
        text_body += "</div>"

        tooltip.push({
            type = "text",
            text = text_body,
            rawHTMLInText = true
        })
    }

    {
        local text_kill = "<div class='maxi-damage-tooltip'>";
        text_kill += tooltip_fragment("kills.png", [info.kill_proba]);
        text_kill += "</div>"
        tooltip.push({
            type = "text",
            text = text_kill,
            rawHTMLInText = true
        })
    }

    return tooltip
}
