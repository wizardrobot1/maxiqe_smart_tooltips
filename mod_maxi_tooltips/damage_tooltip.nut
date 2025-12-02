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
        if (key == "hitchance") {}  // ignore hitchance!
        else if (!table2.rawin(key) || !is_close(table1[key], table2[key]) ) {
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
        text_kill += tooltip_fragment("maxi_tt_overall_kill_given_hit.png", conditional_kill_proba);
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
local function attack_info_tooltip_line_5(info, hitchance_icon)
{
    local kill_proba = info.kill_proba;
    local health_value = info.health_damage;
    local head_armor = info.head_armor_damage;
    local body_armor = info.body_armor_damage;
    local hitchance = info.hit_chance;

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
    return "<div class='maxi-damage-tooltip'>" + tooltip_fragment("maxi_tt_calculation_time.png", time) + "</div>"
}



local function tooltip_from_info(info, calculation_time, info_keys, icons)
{
    local tooltip = [];

    // TODO: only debug mode
    tooltip.push({
            type = "text",
            text = attack_info_tooltip__calculation_time(calculation_time, "Calculation time"),
            rawHTMLInText = true
    })

    if (info.marginal_kill_chance >= 1)
    {
        tooltip.push({
            type = "text",
            text = attack_info_tooltip__kill_chance(info.kill_chance, info.marginal_kill_chance),
            rawHTMLInText = true
        })
    }

    // If all info lines are equal, then show only the first one, with a modified hit_chance
    local show_single_line = true;
    foreach (key in info_keys) {
        show_single_line = show_single_line && tablesAreEqual(info[info_keys[0]], info[key])
    }

    if (show_single_line) {
        // Single-line collapsed tooltip
        local combined_hit_chance = 0;
        foreach (key in info_keys) {
            combined_hit_chance = combined_hit_chance + info[key].hit_chance;
        }
        local first_info = info[info_keys[0]];
        first_info.hit_chance = combined_hit_chance;
        tooltip.push({
            type = "text",
            text = attack_info_tooltip_line_5(first_info, "maxi_tt_generic_hit_chance.png"),
            rawHTMLInText = true
        })

    } else {
        // Standard multiline tooltip
        foreach (idx, key in info_keys) {
            if (info[key].hit_chance >= 1) {
                tooltip.push({
                    type = "text",
                    text =  attack_info_tooltip_line_5(info[key], icons[idx]),
                    rawHTMLInText = true
                })
            }
        }

    }

    return tooltip
}



::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip <- function(attacker, target, skill){
    local info;
    local info_keys;
    local icons;
    local calculation_time;
    local tooltip = [];

    local num_attacks = ::ModMaxiTooltips.TacticalTooltip.get_number_of_attacks(skill);

    {
        ::MSU.Utils.Timer("maxi tt timer");

        if (skill.getID() == "actives.split_man") {
            info = ::ModMaxiTooltips.TacticalTooltip.split_man_summary__monte_carlo(attacker, target, skill);
            info_keys = ["head", "body"];
            icons = ["maxi_tt_splitman_head_hit_chance.png", "maxi_tt_splitman_body_hit_chance.png"];
        } else if (num_attacks >= 2) {
            info = ::ModMaxiTooltips.TacticalTooltip.multi_hit_summary__monte_carlo(attacker, target, skill);
            info_keys = ["head", "body"];
            icons = [
                "maxi_tt_multihit_head_hit_chance.png", "maxi_tt_multihit_body_hit_chance.png",
                "maxi_tt_num_hits_2.png", "maxi_tt_num_hits_3.png"
            ];
            for (local num_hits = 1; num_hits < num_attacks; num_hits++) {
                info_keys.push(num_hits);
            }
        } else {
            info = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast(attacker, target, skill);
            info_keys = ["head", "body"];
            icons = ["maxi_tt_head_hit_chance.png", "maxi_tt_body_hit_chance.png"];
        }

        calculation_time = ::MSU.Utils.Timer("maxi tt timer").silentStop();

        tooltip.extend(tooltip_from_info(info, calculation_time, info_keys, icons));
    }

    return tooltip
}
