// Test functions for damage_estimation

local epsilon = 0.1;
function is_close(value1, value2)
{
    return (::Math.abs(value1 - value2) <= epsilon)
}

local did_a_test_fail = false;

function tablesAreEqual(table1, table2) {
    // Check if both inputs are tables
    foreach (key, value in table1) {
        if (!table2.rawin(key) || !is_close(table1[key], table2[key]) ) {
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


function run_test(test_name, scalar_function, threshold, expected_ret)
{
    local ret = ::ModMaxiTooltips.TacticalTooltip.getDistributionInfo(0, 10, 0, 10, scalar_function, threshold);
    if (!tablesAreEqual(ret, expected_ret)) {
        ::ModMaxiTooltips.Mod.Debug.printError(
            format("MaxiTT: test `%s` failed!", test_name)
        );
        did_a_test_fail = true;
        ::MSU.Log.printData(expected_ret);
        ::MSU.Log.printData(ret);
    }
}

local test_name;
local threshold;
local expected_ret;

test_name = "Constant function";
function constant_10 (x, y) {
    return 10.
}
threshold = 1;
expected_ret = {
    min = 10.,
    max = 10.,
    mean = 10.,
    proba = 1.,
};

run_test(test_name, constant_10, threshold, expected_ret);

test_name = "sum: x + 2 * y"
function sum_function(x, y) {
    return 0. + x + 2 * y
}
threshold = 10;
expected_ret = {
    min = 0.,
    max = 30.,
    mean = 15.,
    proba = 0.752,
};

run_test(test_name, sum_function, threshold, expected_ret);


test_name = "indicator function x >= 5 && y >= 5"
function indicator(x, y) {
    if (x >= 5 && y >= 5) {
        return 5.
    } else {
        return 0.
    }
}
threshold = 1;
expected_ret = {
    min = 0,
    max = 5,
    mean = 1.488,
    proba = 0.2975,
};

run_test(test_name, indicator, threshold, expected_ret);

test_name = "pseudo_damage"
function pseudo_damage(x, y) {
    local armor = 4.;
    local damage = 0.0;
    armor = ::Math.maxf(0, armor - x);
    local armor_damage = 4 - armor;
    damage += ::Math.maxf(0, 0.25 * y - 0.1 * armor);
    if (armor == 0) damage += ::Math.maxf(0, 0.75 * y - armor_damage);
    return damage
}

threshold = 4;
expected_ret = {
    min = 0,
    max = 6,
    mean = 1.74752,
    proba = 0.1735,
};

run_test(test_name, pseudo_damage, threshold, expected_ret);


test_name = "pseudo_damage_2"
function pseudo_damage_2(x, y) {
    local start_armor = 40.0;
    local armor = start_armor;
    local damage = 0.0;
    armor = ::Math.maxf(0, armor - x);
    local armor_damage = start_armor - armor;
    damage += ::Math.maxf(0, 0.5 * y - 0.1 * armor);
    if (armor == 0) damage += ::Math.maxf(0, 0.5 * y - armor_damage);
    return damage
}

threshold = 1;
expected_ret = {
    min = 0,
    max = 2,
    mean = 0.28512,
    proba = 0.14876,
};

run_test(test_name, pseudo_damage_2, threshold, expected_ret);


if (!did_a_test_fail) {
    ::ModMaxiTooltips.Mod.Debug.printError("MaxiTT: tests concluded!");
}
