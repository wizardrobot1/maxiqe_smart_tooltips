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
