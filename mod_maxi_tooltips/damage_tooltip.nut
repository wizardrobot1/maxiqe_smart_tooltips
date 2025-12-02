// All functions to combine the damage estimation into a legible tooltip

if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}


local epsilon = 0.2;
local function is_close(value1, value2)
{
    return (::Math.abs(value1 - value2) <= epsilon)
}


// Util function: used to sometimes collapse the tooltip into a single line
local function tablesAreEqual(table1, table2) {
    // Check if both inputs are tables
    foreach (key, value in table1) {
        if (!table2.rawin(key) || !is_close(table1[key], table2[key]) ) {
            return false;
        }
    }
    return true
}


// Empty span to fill-out lines
local function missing_value() {
    return "<span> </span>"
}


// Combine icon with value in html span
// Always rounds: input can be float
local function tooltip_fragment(icon_name, value) {
    return format("<span> <img src='coui://gfx/ui/icons/%s'/> %i </span>", icon_name, ::Math.round(value));
}


// A single html line to represent the kill probability in a compact fashion
// conditional_kill_proba: float[0, 100] | None
// marginal_kill_proba: float[0, 100] | None
local function attack_info_tooltip__kill_chance(conditional_kill_proba, marginal_kill_proba)
{
    local text_kill = "<div class='maxi-damage-tooltip'>";
    if (conditional_kill_proba) {
        text_kill += tooltip_fragment("maxi_tt_kill_given_hit.png", conditional_kill_proba);
    } else {
        text_kill += missing_value();
    }
    if (marginal_kill_proba) {
        text_kill += tooltip_fragment("maxi_tt_marginal_kill.png", marginal_kill_proba);
    } else {
        text_kill += missing_value();
    }
    text_kill += "</div>"
    return text_kill
}


// Coerce 5 values into a single html tooltip line
// all numeric inputs are expected to be floats: this function does the rounding
// kill_proba is expected to be normalized between 0 and 1
// hitchance is expected to be normalized between 0 and 100
// kill_proba: float[0, 1] | None
// health_value: float[0, inf] | None
// head_armor: float[0, inf] | None
// body_armor: float[0, inf] | None
// hitchance: float[0, 100]
// hitchance_icon: str
local function attack_info_tooltip_line_5(kill_proba, health_value, head_armor, body_armor, hitchance, hitchance_icon)
{
        local text_tooltip = "<div class='maxi-damage-tooltip'>";

        if (kill_proba) {
            kill_proba = ::Math.round(100 * kill_proba);
            if (kill_proba > 0) {
                text_tooltip += tooltip_fragment("maxi_tt_kill_given_hit.png", kill_proba);
            } else {
                text_tooltip += missing_value();
            }
        } else {
            text_tooltip += missing_value()
        }

        if (health_value) {
            health_value = ::Math.round(health_value);
            if (health_value > 0) {
                text_tooltip += tooltip_fragment("maxi_tt_health_damage.png", health_value);
            } else {
                text_tooltip += missing_value();
            }
        } else {
            text_tooltip += missing_value()
        }

        if (head_armor) {
            head_armor = ::Math.round(head_armor);
            if (head_armor > 0) {
                text_tooltip += tooltip_fragment("maxi_tt_head_armor_damage.png", head_armor);
            } else {
                text_tooltip += missing_value();
            }
        } else {
            text_tooltip += missing_value()
        }

        if (body_armor) {
            body_armor = ::Math.round(body_armor);
            if (body_armor > 0) {
                text_tooltip += tooltip_fragment("maxi_tt_body_armor_damage.png", body_armor);
            } else {
                text_tooltip += missing_value();
            }
        } else {
            text_tooltip += missing_value()
        }

        text_tooltip += tooltip_fragment(hitchance_icon, hitchance);

        text_tooltip += "</div>"

        return text_tooltip
}


local function attack_info_tooltip__calculation_time(time, name)
{
    return "<div> " + tooltip_fragment("maxi_tt_calculation_time.png", time) + "ms </div>"
}


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
    local info_smartfast = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast(attacker, target, skill);
    local delta_smartfast = ::MSU.Utils.Timer("maxi tt timer").silentStop();

    {
        local info = info_smartfast;

        // TODO: only debug mode
        tooltip.push({
                type = "text",
                text = attack_info_tooltip__calculation_time(delta_smartfast, "Approximation")
        })


        if (info.kill_proba >= 1)
        {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip__kill_chance(info.kill_proba, info.kill_proba * hitchance / 100),
                rawHTMLInText = true
            })
        }

        // Check if we should show a single info line
        local show_single_line = (
            info.target.head_armor == 0
            && info.target.body_armor == 0
            && tablesAreEqual(info.distribution_head_health, info.distribution_body_health)
        );

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line_5(info.distribution_body_health.proba, info.distribution_body_health.mean, 0, info.distribution_body_armor.mean, 100, "maxi_tt_body_hit_chance.png"),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line_5(info.distribution_head_health.proba, info.distribution_head_health.mean, info.distribution_head_armor.mean, 0, info.head_hit_chance, "maxi_tt_head_hit_chance.png"),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line_5(info.distribution_body_health.proba, info.distribution_body_health.mean, 0, info.distribution_body_armor.mean, 100 - info.head_hit_chance, "maxi_tt_body_hit_chance.png"),
                rawHTMLInText = true
            })
        }

    }

    // TODO: If debug instead
    if (true) {
        tooltip.extend(
            ::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_multi_hit(attacker, target, skill)
        );
    }


    return tooltip
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


// Todo: rewrite
local function compute_hit_distribution(hitchance, num_attacks) {
    local factorial = [1, 1, 2, 6, 24, 120, 720];

    if (num_attacks >= factorial.len()) {
        return [0., 0.]
    }

    local res = [];
    for (local num_hits = 0; num_hits <= num_attacks; num_hits++) {
        local proba_atomic = ::Math.pow(1. * hitchance / 100, num_hits) * ::Math.pow(1 - 1. * hitchance / 100, num_attacks - num_hits);
        local combinatorial_count = factorial[num_attacks] / factorial[num_hits] / factorial[num_attacks - num_hits];
        res.push(proba_atomic * combinatorial_count);
    }

    return res
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_multi_hit <- function(attacker, target, skill){
    ::MSU.Utils.Timer("maxi tt timer");

    local hitchance = skill.getHitchance(target);
    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local num_attacks = ::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks(skill);
    local hit_distribution = compute_hit_distribution(hitchance, num_attacks);

    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);


    local summary_info_mc = ::ModMaxiTooltips.TacticalTooltip.multi_hit_summary__monte_carlo(parameters_body, parameters_head, num_attacks, head_hit_chance)

    local delta_exact = ::MSU.Utils.Timer("maxi tt timer").silentStop();

    local tooltip = [];

    // TODO: only debug mode
    tooltip.push({
            type = "text",
            text = attack_info_tooltip__calculation_time(delta_exact, "Monte-Carlo (MH)")
    })

    // Normalized to 0-1
    local marginal_kill_proba = 0;
    for (local num_hits = 0; num_hits < num_attacks; num_hits++) {
        marginal_kill_proba += summary_info_mc[num_hits].kill_proba * hit_distribution[num_hits+1];
    }
    // Normalized to 0-100
    marginal_kill_proba *= 100;

    // Using Monte-Carlo simulation for a standard attack
    if (num_attacks == 1) {
        local conditional_kill_proba = summary_info_mc.head.kill_proba * head_hit_chance + summary_info_mc.head.kill_proba * (100 - head_hit_chance);
        tooltip.push({
            type = "text",
            text = attack_info_tooltip__kill_chance(conditional_kill_proba, marginal_kill_proba),,
            rawHTMLInText = true
        })

        foreach (key in ["head", "body"]) {
            local icon_name = key == "head"? "maxi_tt_head_hit_chance.png" : "maxi_tt_body_hit_chance.png";
            local hit_chance = (key == "head"? head_hit_chance : 100 - head_hit_chance);
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line_5(
                    summary_info_mc[key].kill_proba,
                    summary_info_mc[key].health_damage,
                    summary_info_mc[key].head_armor_damage,
                    summary_info_mc[key].body_armor_damage,
                    hit_chance,
                    icon_name
                ),
                rawHTMLInText = true
            })
        }

    // Standard multi-hit attack tooltip
    } else {
        tooltip.push({
            type = "text",
            text = attack_info_tooltip__kill_chance(null, marginal_kill_proba),,
            rawHTMLInText = true
        })

        foreach (key in ["head", "body"]) {
            local icon_name = key == "head"? "maxi_tt_multihit_head_hit_chance.png" : "maxi_tt_multihit_body_hit_chance.png";
            local hit_chance = (key == "head"? head_hit_chance : 100 - head_hit_chance) * hit_distribution[num_hits];
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line_5(
                    summary_info_mc[key].kill_proba,
                    summary_info_mc[key].health_damage,
                    summary_info_mc[key].head_armor_damage,
                    summary_info_mc[key].body_armor_damage,
                    hit_chance,
                    icon_name
                ),
                rawHTMLInText = true
            })
        }

        for (local num_hits = 1; num_hits < num_attacks; num_hits++) {
            local icon_name = format("maxi_tt_num_hits_%x.png", num_hits + 1)
            local total_armor_damage = summary_info_mc[num_hits].body_armor_damage + summary_info_mc[num_hits].head_armor_damage;
            local hit_chance = 100 * hit_distribution[num_hits+1];
            tooltip.push({
                type = "text",
                text = attack_info_tooltip_line_5(
                    summary_info_mc[num_hits].kill_proba,
                    summary_info_mc[num_hits].health_damage,
                    summary_info_mc[num_hits].head_armor_damage,
                    summary_info_mc[num_hits].body_armor_damage,
                    hit_chance,
                    icon_name
                ),
                rawHTMLInText = true
            })
        }

    }

    return tooltip
}


::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_split_man <- function(attacker, target, skill){
    ::MSU.Utils.Timer("maxi tt timer");
    local hitchance = skill.getHitchance(target);
    local head_hit_chance = ::ModMaxiTooltips.TacticalTooltip.compute_head_hit_chance(attacker, target, skill);

    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_info_mc = ::ModMaxiTooltips.TacticalTooltip.split_man_summary__monte_carlo(parameters_body, parameters_head);

    local delta_exact = ::MSU.Utils.Timer("maxi tt timer").silentStop();

    local tooltip = [];

    {

        // TODO: only debug mode
        tooltip.push({
                type = "text",
                text = attack_info_tooltip__calculation_time(delta_exact, "Monte Carlo (SM)")
        })

        // Normalized to 0-100
        local kill_proba = head_hit_chance * summary_info_mc.summary_head.kill_proba + (100 - head_hit_chance) * summary_info_mc.summary_body.kill_proba;

        if (kill_proba >= 1)
        {
            // Normalized to 0-100
            local marginal_kill_proba = kill_proba * hitchance / 100;
            tooltip.push({
                type = "text",
                text = attack_info_tooltip__kill_chance(kill_proba, marginal_kill_proba),
                rawHTMLInText = true
            })

        }

        // Check if we should show a single info line
        local show_single_line = (
            tablesAreEqual(summary_info_mc.summary_head, summary_info_mc.summary_body)
        );

        // Show a single damage line: taking from body
        if (show_single_line) {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line_5(
                    summary_info_mc.summary_body.kill_proba,
                    summary_info_mc.summary_body.health_damage,
                    summary_info_mc.summary_body.head_armor_damage,
                    summary_info_mc.summary_body.body_armor_damage,
                    100,
                    "maxi_tt_splitman_body_hit_chance.png"
                ),
                rawHTMLInText = true
            })
        } else {
            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line_5(
                    summary_info_mc.summary_head.kill_proba,
                    summary_info_mc.summary_head.health_damage,
                    summary_info_mc.summary_head.head_armor_damage,
                    summary_info_mc.summary_head.body_armor_damage,
                    head_hit_chance,
                    "maxi_tt_splitman_head_hit_chance.png"
                ),
                rawHTMLInText = true
            })

            tooltip.push({
                type = "text",
                text =  attack_info_tooltip_line_5(
                    summary_info_mc.summary_body.kill_proba,
                    summary_info_mc.summary_body.health_damage,
                    summary_info_mc.summary_body.head_armor_damage,
                    summary_info_mc.summary_body.body_armor_damage,
                    100 - head_hit_chance,
                    "maxi_tt_splitman_body_hit_chance.png"
                ),
                rawHTMLInText = true
            })
        }
    }

    return tooltip
}
