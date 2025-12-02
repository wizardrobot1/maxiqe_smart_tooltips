// Monte-Carlo estimation for all skills with behavior unsuitable for exact estimation
// - split-man
// - multi-hit attacks

if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


// Skill names of attacks with multiple hits
// Expose so that this can be modified by external mods
::ModMaxiTooltips.TacticalTooltip.three_hit_skills <- [
    "actives.cascade",
    "actives.hail"
];
::ModMaxiTooltips.TacticalTooltip.two_hit_skills <- [
];


::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks <- function (skill) {
    if (::ModMaxiTooltips.TacticalTooltip.three_hit_skills.find(skill.getID()) != null) {
        return 3
    }

    if (::ModMaxiTooltips.TacticalTooltip.two_hit_skills.find(skill.getID()) != null) {
        return 2
    }

    return 1
}


::ModMaxiTooltips.TacticalTooltip.MeanCalculator <- class {
    sum = 0.0;
    count = 0;

    function constructor() {
        this.sum = 0.0;
        this.count = 0;
    }

    function update(value) {
        this.sum += value.tofloat();
        this.count += 1;
    }

    function value() {
        return this.sum / this.count;
    }
}


::ModMaxiTooltips.TacticalTooltip.CustomRNG <- class {
    _state = 1;

    // Constants for a 32-bit LCG
    MULTIPLIER = 1664525;
    INCREMENT = 1013904223;
    MAX_VAL = 4294967296.0; // 2^32 as a float

    // Custom constructor with input seed
    constructor(seed) {
        // Initialize state, ensuring it's treated as a 32-bit integer.
        _state = (seed | 0);
        // LCGs should typically start with a non-zero state.
        if (_state == 0) _state = 1;
    }

    // Internal function to generate the next pseudo-random number as a float in [0, 1)
    function _next() {
        // LCG: X_n+1 = (a * X_n + c) mod 2^32
        // We rely on Squirrel's integer behavior to handle the implicit 32-bit modulo.
        // The result is explicitly masked with | 0 to ensure 32-bit integer context.
        _state = ((_state * MULTIPLIER) + INCREMENT) | 0;

        // Convert the 32-bit signed integer state to a positive float value [0, 2^32)
        local float_val = _state.tofloat();
        if (float_val < 0.0) {
            float_val += MAX_VAL;
        }

        // Normalize to [0, 1)
        return float_val / MAX_VAL;
    }

    // Function to sample uniformly from the integers between min and max (inclusive)
    function rand(min, max) {
        // Swap min/max if they are reversed to ensure correct range calculation
        if (min > max) {
            local temp = min;
            min = max;
            max = temp;
        }

        local range = max - min + 1;

        // Generate the raw float [0, 1)
        local raw_float = _next();

        // Scale and shift: floor(raw_float * range) + min
        return ::Math.floor(raw_float * range) + min;
    }
}


// Custom estimation code for split man
//
// Use Monte-Carlo simulation to avoid dealing with the huge sample space
//
// This function simply reproduces the structure of the split-man hit
// - big hit to targetted body part
// - reduced hit to the other body part
//
// <!> Summaries are slightly different since the attack hits both body parts <!>
::ModMaxiTooltips.TacticalTooltip.split_man_summary__monte_carlo <- function (attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);
    local hit_chance = {
        head=head_hit_chance,
        body=100 - head_hit_chance
    }

    local start_health = parameters_body.health;
    local start_armor = {
        body=parameters_body.armor,
        head=parameters_head.armor
    }

    local all_parameters = {
        main={
            body=parameters_body,
            head=parameters_head
        },
        secondary={
            body=clone parameters_body,
            head=clone parameters_head
        }
    }

    // Update parameters for secondary hit
    foreach (body_part in ["body", "head"]) {
        all_parameters.secondary[body_part].health_multiplier *= 0.5;
        all_parameters.secondary[body_part].armor_multiplier *= 0.5;
        all_parameters.secondary[body_part].bodypart_damage_mult = 1;
    }

    local num_repeats = ::ModMaxiTooltips.Mod.ModSettings.getSetting("num_samples_monte_carlo").getValue();

    local summary_res = {};

    foreach (initial_hit_body_part in ["body", "head"]) {
        local health_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        local body_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        local head_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        local kill_proba = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();

        local secondary_hit_body_part = initial_hit_body_part == "body" ? "head": "body";

        // Ensure same hits on both halves of the body
        local rng = ::ModMaxiTooltips.TacticalTooltip.CustomRNG(123456);

        for (local repeat = 0; repeat < num_repeats; repeat++) {
            // Reset health and armor
            foreach (hit_type_temp in ["main", "secondary"]) {
                foreach (body_part_temp in ["body", "head"]) {
                    all_parameters[hit_type_temp][body_part_temp].health = start_health;
                    all_parameters[hit_type_temp][body_part_temp].armor = start_armor[body_part_temp];
                }
            }

            foreach (hit_type in ["main", "secondary"]) {
                local attacked_body_part = hit_type == "main"? initial_hit_body_part : secondary_hit_body_part;

                local attacked_parameters = all_parameters[hit_type][attacked_body_part];

                local armor_roll = rng.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
                local health_roll = rng.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

                local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

                attacked_parameters.health -= res.health_damage;
                attacked_parameters.armor -= res.armor_damage;

                // Resync health and armor on all parameters
                foreach (hit_type_temp in ["main", "secondary"]) {
                    foreach (body_part_temp in ["body", "head"]) {
                        // Update health for all
                        all_parameters[hit_type_temp][body_part_temp].health = attacked_parameters.health;
                    }
                    // Update armor only for attacked_body_part
                    all_parameters[hit_type_temp][attacked_body_part].armor = attacked_parameters.armor;
                }
            }

            // After both hit_type have resolved, update accumulators
            health_damage.update(start_health - all_parameters.main.body.health);
            body_armor_damage.update(start_armor.body - all_parameters.main.body.armor);
            head_armor_damage.update(start_armor.head - all_parameters.main.head.armor);
            kill_proba.update(all_parameters.main.body.health <= 0);
        }

        // After all repeats, create summary
        summary_res[initial_hit_body_part] <- {
            health_damage=health_damage.value(),
            body_armor_damage=body_armor_damage.value(),
            head_armor_damage=head_armor_damage.value(),
            kill_proba=kill_proba.value(),
            hit_chance=hit_chance[initial_hit_body_part]
        }
    }

    local kill_chance = (head_hit_chance * summary_res.head.kill_proba + (100 - head_hit_chance) * summary_res.body.kill_proba);

    local raw_hit_chance = skill.getHitchance(target);
    local marginal_kill_chance = kill_chance * raw_hit_chance / 100;

    return {
        body=summary_res["body"],
        head=summary_res["head"],
        kill_chance=kill_chance,
        marginal_kill_chance=marginal_kill_chance,
    }
}


class FactorialCache {
    _cache = [1, 1];

    function get(n) {
        if (n < _cache.len()) {
            return _cache[n]
        }

        for (local i = _cache.len(); i <= n; i++) {
            local new_val = _cache[i-1] * i;
            _cache.push(new_val);
        }

        return _cache[n]
    }
}


local fact_cache = FactorialCache();


// Compute the probability of scoring 0-hits, 1-hit, etc
// Return an array with the probabilities of each possibility, normalized to 0-1
//
// For example
// compute_hit_distribution(0.5, 2)
// [0.25, 0.5, 0.25]
local function compute_hit_distribution(hitchance, num_attacks) {
    local res = [];
    for (local num_hits = 0; num_hits <= num_attacks; num_hits++) {
        local proba_atomic = ::Math.pow(1. * hitchance / 100, num_hits) * ::Math.pow(1 - 1. * hitchance / 100, num_attacks - num_hits);
        local combinatorial_count = fact_cache.get(num_attacks) / fact_cache.get(num_hits) / fact_cache.get(num_attacks - num_hits);
        res.push(proba_atomic * combinatorial_count);
    }

    return res
}


// Custom estimation code for multi-hit attacks
// <!> This also works for standard attacks <!>
//
// Use Monte-Carlo simulation to avoid dealing with the huge sample space
//
// This function simply reproduces the structure of a multi-hit attack
// - accumulate hits
// - update the corresponding n-hit accumulator
//
// For standard attacks, also increment a standard head / body paired accumulators
::ModMaxiTooltips.TacticalTooltip.multi_hit_summary__monte_carlo <- function (attacker, target, skill) {
    local rng = ::ModMaxiTooltips.TacticalTooltip.CustomRNG(123456);

    local raw_hit_chance = skill.getHitchance(target);
    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local num_attacks = ::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks(skill);
    local hit_distribution = compute_hit_distribution(raw_hit_chance, num_attacks);

    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local start_health = parameters_body.health;
    local start_body_armor = parameters_body.armor;
    local start_head_armor = parameters_head.armor;

    local health_damage = {};
    local body_armor_damage = {};
    local head_armor_damage = {};
    local kill_proba = {};

    // Multi-hit accumulators
    for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
        health_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        body_armor_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        head_armor_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        kill_proba[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    }

    // Body - Head accumulators for standard attacks
    foreach (key in ["body", "head"]) {
        health_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        body_armor_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        head_armor_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        kill_proba[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    }

    local num_repeats = 2 * ::ModMaxiTooltips.Mod.ModSettings.getSetting("num_samples_monte_carlo").getValue();

    for (local repeat = 0; repeat < num_repeats; repeat++) {
        // Reset health and armor
        parameters_body.health = start_health;
        parameters_body.armor = start_body_armor;
        parameters_head.health = start_health;
        parameters_head.armor = start_head_armor;

        for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
            local attack_key = null;
            {
                local attacked_parameters;
                local body_part_roll = rng.rand(1, 100);
                // Make first roll deterministic to split evenly between head and body attacks
                if (num_hits == 0) {
                    body_part_roll = ((100. * repeat / num_repeats) + 1);
                }
                if (body_part_roll <= head_hit_chance) {
                    attack_key = "head";
                    attacked_parameters = parameters_head;
                } else {
                    attack_key = "body";
                    attacked_parameters = parameters_body;
                }

                local armor_roll = rng.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
                local health_roll = rng.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

                local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

                attacked_parameters.health -= res.health_damage;
                attacked_parameters.armor -= res.armor_damage;

                // Synchronize parameters
                // Since armor isn't shared, we don't need to sync it
                parameters_body.health = attacked_parameters.health;
                parameters_head.health = attacked_parameters.health;
            }

            health_damage[num_hits].update(start_health - parameters_body.health);
            body_armor_damage[num_hits].update(start_body_armor - parameters_body.armor);
            head_armor_damage[num_hits].update(start_head_armor - parameters_head.armor);
            kill_proba[num_hits].update(parameters_body.health <= 0);

            // Increment accumulator for a standard attack
            if (num_hits == 0 && attack_key) {
                health_damage[attack_key].update(start_health - parameters_body.health);
                body_armor_damage[attack_key].update(start_body_armor - parameters_body.armor);
                head_armor_damage[attack_key].update(start_head_armor - parameters_head.armor);
                kill_proba[attack_key].update(parameters_body.health <= 0);
            }
        }
    }

    local res = {};

    local marginal_kill_chance = 0;

    // Misleading name: actual number of hits is "num_hits + 1"
    for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
        local hit_chance = hit_distribution[num_hits+1] * 100;
        res[num_hits] <- ({
            num_hits=num_hits+1,
            health_damage=health_damage[num_hits].value(),
            body_armor_damage=body_armor_damage[num_hits].value(),
            head_armor_damage=head_armor_damage[num_hits].value(),
            kill_proba=kill_proba[num_hits].value(),
            hit_chance=hit_chance
        });
        local marginal_kill_chance_increment = kill_proba[num_hits].value() * hit_chance;
        marginal_kill_chance = marginal_kill_chance + marginal_kill_chance_increment;
    }

    foreach (key in ["body", "head"]) {
        res[key] <- {
            health_damage=health_damage[key].value(),
            body_armor_damage=body_armor_damage[key].value(),
            head_armor_damage=head_armor_damage[key].value(),
            kill_proba=kill_proba[key].value(),
            hit_chance=hit_distribution[1] * (key == "head"? head_hit_chance : 100 - head_hit_chance)
        }
    }

    res.marginal_kill_chance <- marginal_kill_chance;
    res.kill_chance <- null;

    return res;
}
