if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
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


::ModMaxiTooltips.TacticalTooltip.split_man_summary__monte_carlo <- function (parameters_body, parameters_head) {
    local start_health = parameters_body.health;
    local start_body_armor = parameters_body.armor;
    local start_head_armor = parameters_head.armor;
    
    // For a main attack to body
    local parameters_secondary_hit = clone parameters_head;
    parameters_secondary_hit.health_multiplier *= 0.5;
    parameters_secondary_hit.armor_multiplier *= 0.5;
    parameters_secondary_hit.bodypart_damage_mult = 1;

    local health_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    local body_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    local head_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    local kill_proba = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();

    local num_repeats = 100;

    for (local repeat = 0; repeat < num_repeats; repeat++) {
        // Reset health and armor
        parameters_body.health = start_health;
        parameters_body.armor = start_body_armor;
        parameters_head.health = start_health;
        parameters_head.armor = start_head_armor;
        parameters_secondary_hit.health = start_health;
        parameters_secondary_hit.armor = start_head_armor;

        {
            local attacked_parameters = parameters_body;

            local armor_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
            local health_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

            attacked_parameters.health -= res.health_damage;
            attacked_parameters.armor -= res.armor_damage;

            parameters_body.health = attacked_parameters.health;
            parameters_head.health = attacked_parameters.health;
            parameters_secondary_hit.health = attacked_parameters.health;
            parameters_secondary_hit.armor = parameters_head.armor;
        }

        {
            local attacked_parameters = parameters_secondary_hit;

            local armor_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
            local health_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

            attacked_parameters.health -= res.health_damage;
            attacked_parameters.armor -= res.armor_damage;

            parameters_body.health = attacked_parameters.health;
            parameters_head.health = attacked_parameters.health;
            parameters_secondary_hit.health = attacked_parameters.health;
            parameters_head.armor = parameters_secondary_hit.armor;
        }

        // Update accumulators
        health_damage.update(start_health - parameters_secondary_hit.health);
        body_armor_damage.update(start_body_armor - parameters_body.armor);
        head_armor_damage.update(start_head_armor - parameters_secondary_hit.armor);
        kill_proba.update(parameters_secondary_hit.health <= 0);
    }

    local summary_body = {
        health_damage=health_damage.value(),
        body_armor_damage=body_armor_damage.value(),
        head_armor_damage=head_armor_damage.value(),
        kill_proba=kill_proba.value()
    }

    // for a main attack to head
    local parameters_secondary_hit = clone parameters_body;
    parameters_secondary_hit.health_multiplier *= 0.5;
    parameters_secondary_hit.armor_multiplier *= 0.5;
    parameters_secondary_hit.bodypart_damage_mult = 1;

    health_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    body_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    head_armor_damage = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    kill_proba = ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();

    for (local repeat = 0; repeat < num_repeats; repeat++) {
        // Reset health and armor
        parameters_body.health = start_health;
        parameters_body.armor = start_body_armor;
        parameters_head.health = start_health;
        parameters_head.armor = start_head_armor;
        parameters_secondary_hit.health = start_health;
        parameters_secondary_hit.armor = start_body_armor;

        {
            local attacked_parameters = parameters_head;

            local armor_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
            local health_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

            attacked_parameters.health -= res.health_damage;
            attacked_parameters.armor -= res.armor_damage;

            parameters_body.health = attacked_parameters.health;
            parameters_head.health = attacked_parameters.health;
            parameters_secondary_hit.health = attacked_parameters.health;
        }

        {
            local attacked_parameters = parameters_secondary_hit;

            local armor_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
            local health_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

            attacked_parameters.health -= res.health_damage;
            attacked_parameters.armor -= res.armor_damage;

            parameters_body.health = attacked_parameters.health;
            parameters_head.health = attacked_parameters.health;
            parameters_secondary_hit.health = attacked_parameters.health;
        }

        // Update accumulators
        health_damage.update(start_health - parameters_secondary_hit.health);
        body_armor_damage.update(start_body_armor - parameters_secondary_hit.armor);
        head_armor_damage.update(start_head_armor - parameters_head.armor);
        kill_proba.update(parameters_secondary_hit.health <= 0);
    }

    local summary_head = {
        health_damage=health_damage.value(),
        body_armor_damage=body_armor_damage.value(),
        head_armor_damage=head_armor_damage.value(),
        kill_proba=kill_proba.value()
    }
    
    return {
        summary_body=summary_body,
        summary_head=summary_head
    }
}



::ModMaxiTooltips.TacticalTooltip.multi_hit_summary__monte_carlo <- function (parameters_body, parameters_head, num_attacks, head_hit_chance) {
    local start_health = parameters_body.health;
    local start_body_armor = parameters_body.armor;
    local start_head_armor = parameters_head.armor;

    local health_damage = {};
    local body_armor_damage = {};
    local head_armor_damage = {};
    local kill_proba = {};

    for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
        health_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        body_armor_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        head_armor_damage[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        kill_proba[num_hits] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    }

    foreach (key in ["body", "head"]) {
        health_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        body_armor_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        head_armor_damage[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
        kill_proba[key] <- ::ModMaxiTooltips.TacticalTooltip.MeanCalculator();
    }

    local num_repeats = 400;

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
                local body_part_roll = ::Math.rand(1, 100);
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

                local armor_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);
                local health_roll = ::Math.rand(attacked_parameters.min_damage, attacked_parameters.max_damage);

                local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, attacked_parameters);

                attacked_parameters.health -= res.health_damage;
                attacked_parameters.armor -= res.armor_damage;

                parameters_body.health = attacked_parameters.health;
                parameters_head.health = attacked_parameters.health;
            }

            health_damage[num_hits].update(start_health - parameters_body.health);
            body_armor_damage[num_hits].update(start_body_armor - parameters_body.armor);
            head_armor_damage[num_hits].update(start_head_armor - parameters_head.armor);
            kill_proba[num_hits].update(parameters_body.health <= 0);

            if (num_hits == 0 && attack_key) {
                health_damage[attack_key].update(start_health - parameters_body.health);
                body_armor_damage[attack_key].update(start_body_armor - parameters_body.armor);
                head_armor_damage[attack_key].update(start_head_armor - parameters_head.armor);
                kill_proba[attack_key].update(parameters_body.health <= 0);
            }
        }
    }

    local res = {};

    for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
        res[num_hits] <- ({
            num_hits=num_hits+1,
            health_damage=health_damage[num_hits].value(),
            body_armor_damage=body_armor_damage[num_hits].value(),
            head_armor_damage=head_armor_damage[num_hits].value(),
            kill_proba=kill_proba[num_hits].value(),
        })
    }

    foreach (key in ["body", "head"]) {
        res[key] <- {
            health_damage=health_damage[key].value(),
            body_armor_damage=body_armor_damage[key].value(),
            head_armor_damage=head_armor_damage[key].value(),
            kill_proba=kill_proba[key].value(),
        }
    }

    return res;
}
