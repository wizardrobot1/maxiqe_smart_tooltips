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
        // min = min,
        // max = max,
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

    // clip health damage at current health
    damage = ::Math.min(damage, target.m.Hitpoints);

    hit_info.DamageInflictedHitpoints = damage;

    return hit_info
}

::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance <- function(attacker, target, skill){
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);
    return head_hit_chance;
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



local function missing_value() {
    return "<span> </span>"
}


local function tooltip_fragment(icon_name, values, max = null) {
    local join = "";
    foreach(idx,val in values) {
        local val_str;
        if (typeof val == "float" && (10 * val) % 10 != 0) {
            val_str = format("%2.1f", val);
        } else {
            val_str = format("%i", ::Math.round(val));
        }
        // val_str = "<b>" + val_str + "</b>";

        join += val_str;
        if (idx < values.len() - 1) {
            join += " - ";
        }
    }

    return format("<span> <img src='coui://gfx/ui/icons/%s'/> %s </span>", icon_name, join)
}


local function tooltip_fragment_from_distribution(icon_name, distribution_info, max = null) {
    // If the range of values is small, show mean as float
    // If it is large, round the mean: we can ignore the digits
    local range = distribution_info.max - distribution_info.min;
    if (range > 5) distribution_info.mean = ::Math.round(distribution_info.mean);

    local middle = 1. * (distribution_info.max + distribution_info.min) / 2.;
    local show_mean = (
        // If the max is above 100, we don't have enough space
        distribution_info.max < 100
        // If the mean is roughly in the middle of the range, don't show it
        && middle - 0.1 * range < distribution_info.mean
        && distribution_info.mean < middle + 0.1 * range
    );

    local values = [distribution_info.min, distribution_info.max];
    if (show_mean) values = [distribution_info.min, distribution_info.mean, distribution_info.max];

    // If all 3 values are identical, show only a single one
    if (range == 0) values = [distribution_info.min];

    return tooltip_fragment(icon_name, values, max)
}


local function is_close(value1, value2)
{
    return (value1 - value2 <= 0.01) && (value2 - value1 <= 0.01)
}

local function tablesAreEqual(table1, table2) {
    // Check if both inputs are tables
    foreach (key, value in table1) {
        if (!table2.rawin(key) || !is_close(table1[key], table2[key]) ) {
            return false;
        }
    }
    return true
}


local function attack_info_tooltip_line(kill_proba, health_value, armor_value, hitchance, hitchance_icon)
{
        local text_tooltip = "<div class='maxi-damage-tooltip'>";

        kill_proba = ::Math.round(100 * kill_proba);
        if (kill_proba > 0) {
            text_tooltip += tooltip_fragment("maxi_tt_kill_given_hit.png", [kill_proba]);
        } else {
            text_tooltip += missing_value();
        }

        health_value = ::Math.round(health_value);
        if (health_value > 0) {
            text_tooltip += tooltip_fragment("regular_damage.png", [health_value]);
        } else {
            text_tooltip += missing_value();
        }

        armor_value = ::Math.round(armor_value);
        if (armor_value > 0) {
            text_tooltip += tooltip_fragment("armor_damage.png", [armor_value]);
        } else {
            text_tooltip += missing_value();
        }

        text_tooltip += tooltip_fragment(hitchance_icon, [hitchance]);

        text_tooltip += "</div>"

        return text_tooltip
}


function deepEquals(_a, _b)
{
	if (_a instanceof ::WeakTableRef)
		_a = _a.get();
	if (_b instanceof ::WeakTableRef)
		_b = _b.get();
	switch (typeof _a)
	{
		case "table":
			if (_a.len() != _b.len())
				return false;
			foreach (k, v in _a)
			{
				if (!(k in _b) || !deepEquals(v, _b[k]))
					return false;
			}
			return true;
		case "array":
			if (_a.len() != _b.len())
				return false;
			foreach (i, v in _a)
			{
				if (!deepEquals(v, _b[i]))
					return false;
			}
			return true;
		case "instance":
			if (!(typeof _b != "instance") || _a.getclass() != _b.getclass())
				return false;
			foreach (k, v in _a.getclass())
			{
				if (!deepEquals(v, _b[k]))
					return false;
			}
			return true;
        case "float":
            return _a - _b <= 0.01 && _b - _a <= 0.01
		default:
			return _a == _b;
	}
}

::ModMaxiTooltips.deepEquals <- deepEquals;


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip <- function(attacker, target, skill){
    if (skill.getID() == "actives.split_man") {
        return ::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_split_man(attacker, target, skill);
    }
    
    local num_attacks = ::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks(skill);
    if (num_attacks >= 2) {
        return ::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_multi_hit(attacker, target, skill);
    }
    
    local hitchance = skill.getHitchance(target);

    local tooltip = [];

    ::MSU.Utils.Timer("maxi tt timer");
    local info_exact = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary(attacker, target, skill);
    local delta_exact = ::MSU.Utils.Timer("maxi tt timer").silentStop();
    ::MSU.Utils.Timer("maxi tt timer");
    local info_exact_via_params = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters(attacker, target, skill);
    local delta_exact_via_params = ::MSU.Utils.Timer("maxi tt timer").silentStop();
    ::MSU.Utils.Timer("maxi tt timer");
    local info_fast = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__fast(attacker, target, skill);
    local delta_fast = ::MSU.Utils.Timer("maxi tt timer").silentStop();
    ::MSU.Utils.Timer("maxi tt timer");
    local info_smartfast = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast(attacker, target, skill);
    local delta_smartfast = ::MSU.Utils.Timer("maxi tt timer").silentStop();

    // if (!::ModMaxiTooltips.deepEquals(info_exact, info_exact_via_params))
    {
        ::logError("MaxiTT: Error; both methods give different results!");
        ::MSU.Log.printData(info_exact, 2);
        ::MSU.Log.printData(info_exact_via_params, 2);

        tooltip.push({
                type = "text",
                text = "Exact calculation; " + ::Math.round(delta_exact) + " ms"
        })

        local info = info_exact

        // Show a single damage line: taking from body
        local show_single_line = (
            info.target.head_armor == 0
            && info.target.body_armor == 0
            && tablesAreEqual(info.distribution_head_health, info.distribution_body_health)
        );

        if (info.kill_proba >= 1)
        {
            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(info.kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(info.kill_proba * hitchance / 100)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100, "hitchance.png"),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, info.head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

    }

    // if (!::ModMaxiTooltips.deepEquals(info_fast, info_exact_via_params))
    {
        local info = info_exact_via_params;

        tooltip.push({
                type = "text",
                text = "Exact cvp; " + ::Math.round(delta_exact_via_params) + " ms"
        })

        // Show a single damage line: taking from body
        local show_single_line = (
            info.target.head_armor == 0
            && info.target.body_armor == 0
            && tablesAreEqual(info.distribution_head_health, info.distribution_body_health)
        );

        if (info.kill_proba >= 1)
        {
            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(info.kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(info.kill_proba * hitchance / 100)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100, "hitchance.png"),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, info.head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

        if (false || ::ModMaxiTooltips.Mod.Debug.isEnabled())
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
    }

    {
        local info = info_fast;

        tooltip.push({
                type = "text",
                text = "Fast cvp; " + ::Math.round(delta_fast) + " ms"
        })

        // Show a single damage line: taking from body
        local show_single_line = (
            info.target.head_armor == 0
            && info.target.body_armor == 0
            && tablesAreEqual(info.distribution_head_health, info.distribution_body_health)
        );

        if (info.kill_proba >= 1)
        {
            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(info.kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(info.kill_proba * hitchance / 100)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100, "hitchance.png"),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, info.head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

        if (false || ::ModMaxiTooltips.Mod.Debug.isEnabled())
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
    }

    {
        local info = info_smartfast;

        tooltip.push({
                type = "text",
                text = "Smartfast cvp; " + ::Math.round(delta_smartfast) + " ms"
        })

        // Show a single damage line: taking from body
        local show_single_line = (
            info.target.head_armor == 0
            && info.target.body_armor == 0
            && tablesAreEqual(info.distribution_head_health, info.distribution_body_health)
        );

        if (info.kill_proba >= 1)
        {
            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(info.kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(info.kill_proba * hitchance / 100)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100, "hitchance.png"),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, info.head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

        if (false || ::ModMaxiTooltips.Mod.Debug.isEnabled())
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
    }


    return tooltip
}


::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks <- function (skill) {
    local three_hit_skills = [
        "actives.cascade",
        "actives.hail"
    ];
    if (three_hit_skills.find(skill.getID()) != null) {
        return 3
    }

    local two_hit_skills = [];
    if (two_hit_skills.find(skill.getID()) != null) {
        return 2
    }

    return 1
}


local function compute_hit_distribution(hitchance, num_attacks) {
    local factorial = [1, 1, 2, 6, 24, 120, 720];

    if (num_attacks >= factorial.len()) {
        return [0., 0.]
    }

    local res = [];
    for (local num_hits = 0; num_hits <= num_attacks; num_hits++) {
        local proba_atomic = ::Math.pow(1. * hitchance / 100, num_hits) * ::Math.pow(1 - 1. * hitchance / 100, num_attacks - num_hits);
        local combinatorial_count = factorial[num_attacks] / factorial[num_hits] / factorial[num_attacks - num_hits];
        res.push(::Math.round(100 * proba_atomic * combinatorial_count));
    }

    return res
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_multi_hit <- function(attacker, target, skill){
    local hitchance = skill.getHitchance(target);
    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local num_attacks = ::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks(skill);
    local hit_distribution = compute_hit_distribution(hitchance, num_attacks);

    local tooltip = [];

    local info = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast(attacker, target, skill);

    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);
    local summary_info_mc = ::ModMaxiTooltips.TacticalTooltip.multi_hit_summary__monte_carlo(parameters_body, parameters_head, num_attacks, head_hit_chance)

    {
        tooltip.push({
                type = "text",
                text = "Monte-Carlo calculation"
        })

        {
            local text_hit_distribution = "<div class='maxi-damage-tooltip'>";
            foreach (idx, value in hit_distribution) {
                local icon_name = format("maxi_tt_num_hits_%x.png", idx)
                text_hit_distribution += tooltip_fragment(icon_name, [value]);
            }
            text_hit_distribution += "</div>"
            tooltip.push({
                type = "text",
                text = text_hit_distribution,
                rawHTMLInText = true
            })
        }

        local overall_kill_proba = 0;
        for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
            overall_kill_proba += 1. * summary_info_mc[num_hits].kill_proba * hit_distribution[num_hits+1] / 100;
        }

        {
            local marginal_kill_proba = overall_kill_proba * hitchance;

            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(overall_kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(marginal_kill_proba)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
            local total_armor_damage = summary_info_mc[num_hits].body_armor_damage + summary_info_mc[num_hits].head_armor_damage;
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(summary_info_mc[num_hits].kill_proba / 100, summary_info_mc[num_hits].health_damage, total_armor_damage, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

    }


    {
        tooltip.push({
                type = "text",
                text = "Smartfast calculation"
        })

        if (info.kill_proba >= 1)
        {
            local marginal_kill_proba = info.kill_proba * (100 - hit_distribution[0]) / 100;

            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(info.kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(marginal_kill_proba)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, info.head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line(info.distribution_body_health.proba, info.distribution_body_health.mean, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }

    }

    return tooltip
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_split_man <- function(attacker, target, skill){
    local hitchance = skill.getHitchance(target);
    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local tooltip = [];

    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_info_mc = ::ModMaxiTooltips.TacticalTooltip.split_man_summary__monte_carlo(parameters_body, parameters_head);

    {

        tooltip.push({
                type = "text",
                text = "MonteCarlo calculation"
        })

        local kill_proba = head_hit_chance * summary_info_mc.summary_head.kill_proba / 100 + (100 - head_hit_chance) * summary_info_mc.summary_body.kill_proba / 100;

        if (kill_proba >= 1)
        {
            local marginal_kill_proba = kill_proba * hitchance / 100;

            local text_kill = "<div class='maxi-damage-tooltip'>";
            text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", [::Math.round(kill_proba)]);
            text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", [::Math.round(marginal_kill_proba)]);
            text_kill += "</div>"
            tooltip.push({
                type = "text",
                text = text_kill,
                rawHTMLInText = true
            })
        }

        {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(summary_info_mc.summary_head.kill_proba / 100, summary_info_mc.summary_head.health_damage, summary_info_mc.summary_head.head_armor_damage, head_hit_chance, "chance_to_hit_head.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line(summary_info_mc.summary_body.kill_proba / 100, summary_info_mc.summary_body.health_damage, summary_info_mc.summary_body.body_armor_damage, 100 - head_hit_chance, "hitchance.png"),
                rawHTMLInText = true
            })
        }
    }

    return tooltip
}
