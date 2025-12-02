// Test functions for damage_estimation

local function is_close(value1, value2, epsilon=0.1)
{
    return (::Math.abs(value1 - value2) <= epsilon)
}


local function tablesAreEqual(table1, table2, epsilon=0.1) {
    // Check if both inputs are tables
    foreach (key, value in table1) {
        if (!table2.rawin(key) || !is_close(table1[key], table2[key], epsilon) ) {
            ::ModMaxiTooltips.Mod.Debug.printError(
                "Comparison failed at key = " + key
                + " " + table1[key]
                + " " + typeof table1[key]
                + " " + table2[key]
                + " " + typeof table2[key]
                + " " + is_close(table1[key], table2[key])
            );
            return false;
        }
    }
    return true;
}


// Compute information about the distribution of `scalar_function`.
// Assumes that `x, y` are two random variables with uniform
// distribution over the intervals [x_min, x_max], [y_min, y_max]
// We want to find information about the distribution of scalar_function(x, y)
//
// This function computes the mean of the distribution and proba of exceeding threshold
local function getDistributionInfo(x_min, x_max, y_min, y_max, scalar_function, threshold = null)
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
local function damage_direct__from_roll(armor_roll, health_roll, body_part_hit, skill, attacker, target){
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


// Compute and format damage information from attacker, target, skill triplet
// Super slow but should be the most accurate
// Used for tests against the fast function
local function damage_info__slow_but_accurate(attacker, target, skill)
{
    local properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);

    local hit_info = clone ::Const.Tactical.HitInfo;
    local other_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);

    local body_armor = other_properties.Armor[::Const.BodyPart.Body] * other_properties.ArmorMult[::Const.BodyPart.Body];
    local head_armor = other_properties.Armor[::Const.BodyPart.Head] * other_properties.ArmorMult[::Const.BodyPart.Head];
    local health = target.m.Hitpoints;

    local function curried_damage_body_armor(x, y) {
        return damage_direct__from_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).armor_damage
    }
    local function  curried_damage_body_health(x, y) {
        return damage_direct__from_roll(x, y, ::Const.BodyPart.Body, skill, attacker, target).health_damage
    }
    local function  curried_damage_head_armor(x, y) {
        return damage_direct__from_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).armor_damage
    }
    local function  curried_damage_head_health(x, y) {
        return damage_direct__from_roll(x, y, ::Const.BodyPart.Head, skill, attacker, target).health_damage
    }

    local distribution_body_armor = getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_body_armor,
        body_armor
    );
    local distribution_body_health = getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_body_health,
        health
    );
    local distribution_head_armor = getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_head_armor,
        head_armor
    );
    local distribution_head_health = getDistributionInfo(
        properties.DamageRegularMin, properties.DamageRegularMax,
        properties.DamageRegularMin, properties.DamageRegularMax,
        curried_damage_head_health,
        health
    );

    local kill_proba = (head_hit_chance * distribution_head_health.proba + (100 - head_hit_chance) * distribution_body_health.proba);

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
        hit_chance = 100 - head_hit_chance,
    };

    local kill_chance = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba) / 100;

    return {
        head = summary_head,
        body = summary_body,
        kill_chance = kill_chance,
        marginal_kill_chance = 0
    }
}


local function entity_factory__from_script(script)
{
    local function entity_factory()
    {
        ::ModMaxiTooltips.Mod.Debug.printLog("entity_factory__from_script; script = " + script);
        return ::World.getTemporaryRoster().create(script);
    }

    return entity_factory
}


local function equip_item_decorator__from_script(script)
{
    // Decorate an entity factory: add an item to the entity
    local function decorator(entity_factory)
    {
        local function decorated_entity_factory()
        {
            ::ModMaxiTooltips.Mod.Debug.printLog("equip_item_decorator__from_script; script = " + script);
            local item = ::new(script);
            item.create();

            local entity = entity_factory();

            entity.m.Items.equip(item);

            return entity
        }

        return decorated_entity_factory
    }

    return decorator
}


local function gain_skill_decorator__from_script(script)
{
    // Decorate an entity factory: add a skill to the entity
    local function decorator(entity_factory)
    {
        local function decorated_entity_factory()
        {
            ::ModMaxiTooltips.Mod.Debug.printLog("gain_skill_decorator__from_script; script = " + script);
            local entity = entity_factory();

            entity.m.Skills.add(::new(script));

            return entity
        }

        return decorated_entity_factory
    }

    return decorator
}


// Pairs of name, entity_factory
local target_list = [
    // Enemies taken straight from the game
    // Test for racials, perks, etc. in realistic situations
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],
    ["", entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")],

    // bandit-thug with various armor
    ["", equip_item_decorator__from_script("scripts/items/armor/butcher_apron")(
        entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
    )],
    ["", equip_item_decorator__from_script("scripts/items/armor/reinforced_leather_tunic")(
        entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
    )],
    ["", equip_item_decorator__from_script("scripts/items/armor/light_scale_armor")(
        entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
    )],
    ["", equip_item_decorator__from_script("scripts/items/armor/coat_of_plates")(
        entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
    )],

    // bandit-thug + BF with various armor
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_battle_forged")(
        equip_item_decorator__from_script("scripts/items/armor/butcher_apron")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_battle_forged")(
        equip_item_decorator__from_script("scripts/items/armor/reinforced_leather_tunic")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_battle_forged")(
        equip_item_decorator__from_script("scripts/items/armor/light_scale_armor")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_battle_forged")(
        equip_item_decorator__from_script("scripts/items/armor/coat_of_plates")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],

    // bandit-thug + nimble with various armor
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_nimble")(
        equip_item_decorator__from_script("scripts/items/armor/coat_of_plates")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_nimble")(
        equip_item_decorator__from_script("scripts/items/armor/reinforced_leather_tunic")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_nimble")(
        equip_item_decorator__from_script("scripts/items/armor/light_scale_armor")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_nimble")(
        equip_item_decorator__from_script("scripts/items/armor/coat_of_plates")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],

    // bandit-thug + injury with various armor; to test executioner
    ["", gain_skill_decorator__from_script("scripts/skills/injury/dislocated_shoulder_injury")(
        equip_item_decorator__from_script("scripts/items/armor/reinforced_leather_tunic")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/injury/dislocated_shoulder_injury")(
        equip_item_decorator__from_script("scripts/items/armor/coat_of_plates")(
            entity_factory__from_script("scripts/entity/tactical/enemies/bandit_thug")
        )
    )],
];


// Pairs of name, entity_factory
// Attacker + skills but without weapon and skills
// This uses the human script to have a body without any skill going on
local raw_attacker_list = [
    ["No skills", entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")],

    // Perks
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_coup_de_grace")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_mastery_hammer")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_mastery_crossbow")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/perks/perk_duelist")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/effects/killing_frenzy_effect")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],

    // Backgrounds
    ["", gain_skill_decorator__from_script("scripts/skills/backgrounds/killer_on_the_run_background")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],

    // Traits
    ["", gain_skill_decorator__from_script("scripts/skills/traits/brute_trait")(      // Brute: additional head-shot damage
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/traits/drunkard_trait")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/traits/huge_trait")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
    ["", gain_skill_decorator__from_script("scripts/skills/traits/tiny_trait")(
        entity_factory__from_script("scripts/entity/tactical/humans/barbarian_thrall")
    )],
];


local weapon_script__skill_id__pairs = [
    ["scripts/items/weapons/warhammer", "actives.hammer"],
    ["scripts/items/weapons/boar_spear", "actives.thrust"],

    // ["SCRIPT_NAME", "SKILL_ID"],
];


// local name__attacker__skill_id__triplets = [];
// foreach (raw_attacker_pair, raw_attacker_factory)
// {
//     local raw_attacker_name = raw_attacker_pair[0];
//     local raw_attacker_factory = raw_attacker_pair[1];
//     foreach (weapon_skill_pair in weapon_script__skill_id__pairs) {
//         local weapon_script = weakpon_skill_pair[0];
//         local skill_id = weakpon_skill_pair[1];

//         name__attacker__skill_id__triplets.push(
//             [
//                 raw_attacker_name + "___" + skill_id,
//                 equip_item_decorator__from_script(weapon_script)(raw_attacker_factory),
//                 skill_id,
//             ]
//         )
//     }
// }


local roll_value_list = [20, 27, 30, 33, 40, 41, 60, 66, 80];


local function test__damage_on_specific_roll_is_equal(attacker_factory, target_factory, weapon_script, skill_id, armor_roll, health_roll) {
    attacker_factory = equip_item_decorator__from_script(weapon_script)(attacker_factory);

    local attacker = attacker_factory();
    local target = target_factory();

    local skill = attacker.getSkills().getSkillByID(skill_id);

    ::ModMaxiTooltips.Mod.Debug.printLog("test__damage_on_specific_roll_is_equal information");
    attacker.getSkills().print();
    target.getSkills().print();
    ::ModMaxiTooltips.Mod.Debug.printLog("skill.m.ID = " + skill.m.ID);

    local success = true;
    foreach (body_part in [::Const.BodyPart.Head, ::Const.BodyPart.Head]) {
        local parameters = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, body_part);
        local damage_1 = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);
        local damage_2 = damage_direct__from_roll(armor_roll, health_roll, body_part, skill, attacker, target);

        local is_similar = tablesAreEqual(damage_1, damage_2, 0.01);

        if (!is_similar) {
            ::ModMaxiTooltips.Mod.Debug.printLog("Test failed: test__damage_on_specific_roll_is_equal");
            ::MSU.Log.printData(damage_1);
            ::MSU.Log.printData(damage_2);
        }

        success = success && is_similar;
    }

    // Teardown objects properly
    ::World.getTemporaryRoster().remove(attacker);
    ::World.getTemporaryRoster().remove(target);

    return success
}

::ModMaxiTooltips.TacticalTooltip.test__damage_estimation <- function()
{
    local success = true;

    local attacker_name = raw_attacker_list[0][0];
    local attacker_factory = raw_attacker_list[0][1];

    local target_name = target_list[0][0];
    local target_factory = target_list[0][1];

    local weapon_script = weapon_script__skill_id__pairs[0][0];
    local skill_id = weapon_script__skill_id__pairs[0][1];

    local armor_roll = roll_value_list[0];
    local health_roll = roll_value_list[3];

    success = success && test__damage_on_specific_roll_is_equal(attacker_factory, target_factory, weapon_script, skill_id, armor_roll, health_roll);

    if (success) {
        // TEST_SUCCESSFULL();
    } else {
        // TEST_FAILED();
    }
}
