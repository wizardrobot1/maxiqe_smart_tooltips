// Test ::ModMaxiTooltips.TacticalTooltip.CustomRNG
// - check min and max
// - check mean
// - check cross-correlation
// - check reproducibility

const TEST_SAMPLE_SIZE = 1000;
const MEAN_TOLERANCE = 0.05; // Acceptable deviation as a percentage of the total range (max - min)
const CORR_TOLERANCE = 0.08; // Maximum acceptable absolute cross-correlation

// Helper function to generate a set of samples
function generate_samples(min, max, count, seed) {
    local rng = ::ModMaxiTooltips.TacticalTooltip.CustomRNG(seed);
    local samples = [];
    for (local i = 0; i < count; i++) {
        samples.append(rng.rand(min, max));
    }
    return samples;
}


// Helper function to calculate the arithmetic mean of a sample array
function calculate_mean(samples) {
    local sum = 0.0;
    foreach (val in samples) {
        sum += val;
    }
    return sum / samples.len().tofloat();
}

// Helper function to calculate the Pearson cross-correlation between successive values (X_i vs X_{i+1})
function calculate_correlation(samples) {
    local n = samples.len();
    if (n < 2) return 0.0;

    local n_prime = n - 1;

    // Calculate means of the two successive series segments (X and Y)
    local sum_x = 0.0;
    local sum_y = 0.0;
    for (local i = 0; i < n_prime; i++) {
        sum_x += samples[i].tofloat();
        sum_y += samples[i+1].tofloat();
    }
    local mean_x = sum_x / n_prime.tofloat();
    local mean_y = sum_y / n_prime.tofloat();

    // Calculate cross-covariance and individual variances
    local sum_xy = 0.0;
    local sum_x2 = 0.0;
    local sum_y2 = 0.0;

    for (local i = 0; i < n_prime; i++) {
        local diff_x = samples[i].tofloat() - mean_x;
        local diff_y = samples[i+1].tofloat() - mean_y;

        sum_xy += diff_x * diff_y;
        sum_x2 += diff_x * diff_x;
        sum_y2 += diff_y * diff_y;
    }

    local denominator_corr = sqrt(sum_x2 * sum_y2);

    if (denominator_corr == 0.0) return 1.0; // All samples equal, perfect correlation

    // Pearson correlation coefficient
    return sum_xy / denominator_corr;
}


// 1. Check that min, max in the samples are exactly min and max
function test_min_max(min, max) {
    local samples = generate_samples(min, max, TEST_SAMPLE_SIZE, 54321);
    local actual_min = max;
    local actual_max = min;

    foreach(val in samples) {
        if (val < actual_min) actual_min = val;
        if (val > actual_max) actual_max = val;
    }

    // Note: For a true uniform random number generator, hitting the min and max
    // is statistically probable but not guaranteed in a small sample size like 1000.
    // However, the test is implemented strictly as requested.
    local result = (actual_min == min) && (actual_max == max);

    ::ModMaxiTooltips.Mod.Debug.printError(format("  - Min/Max Check (%d samples): Min/Max Hit: %s. Actual Min=%d, Actual Max=%d. Expected Min=%d, Max=%d.",
                 TEST_SAMPLE_SIZE, result ? "PASS" : "FAIL", actual_min, actual_max, min, max));

    if (result) {
        ::ModMaxiTooltips.Mod.Debug.printError("    [PASS] Boundary values were hit exactly.");
    } else {
        ::ModMaxiTooltips.Mod.Debug.printError("    [FAIL] Boundary values were NOT hit exactly.");
    }
    return result;
}

// 2. Check that the mean is roughly at (min + max) / 2
function test_mean(min, max) {
    local samples = generate_samples(min, max, TEST_SAMPLE_SIZE, 67890);
    local mean = calculate_mean(samples);
    local expected_mean = (min.tofloat() + max.tofloat()) / 2.0;

    local deviation = abs(mean - expected_mean);
    local range = max - min;
    local tolerance = range.tofloat() * MEAN_TOLERANCE;

    local passed = deviation < tolerance;

    ::ModMaxiTooltips.Mod.Debug.printError(format("  - Mean Check (%d samples): Actual Mean=%.4f, Expected Mean=%.4f. Deviation=%.4f (Tolerance=%.4f).",
                 TEST_SAMPLE_SIZE, mean, expected_mean, deviation, tolerance));

    if (passed) {
        ::ModMaxiTooltips.Mod.Debug.printError("    [PASS] Mean is within tolerance.");
    } else {
        ::ModMaxiTooltips.Mod.Debug.printError("    [FAIL] Mean is outside tolerance.");
    }
    return passed;
}

// 3. Check reproducibility from two separate instances of the same seed
function test_reproducibility(min, max) {
    local SEED = 42;
    local N = 10;

    // Instance 1
    local rng1 = ::ModMaxiTooltips.TacticalTooltip.CustomRNG(SEED);
    local values1 = [];
    for (local i = 0; i < N; i++) {
        values1.append(rng1.rand(min, max));
    }

    // Instance 2
    local rng2 = ::ModMaxiTooltips.TacticalTooltip.CustomRNG(SEED);
    local values2 = [];
    for (local i = 0; i < N; i++) {
        values2.append(rng2.rand(min, max));
    }

    local equal = true;
    for (local i = 0; i < N; i++) {
        if (values1[i] != values2[i]) {
            equal = false;
            break;
        }
    }

    ::ModMaxiTooltips.Mod.Debug.printError(format("  - Reproducibility Check (%d values, Seed %d): Sequences are equal? %s",
                 N, SEED, equal ? "Yes" : "No"));

    if (equal) {
        ::ModMaxiTooltips.Mod.Debug.printError("    [PASS] Two separate instances with the same seed produced identical sequences.");
    } else {
        ::ModMaxiTooltips.Mod.Debug.printError("    [FAIL] Sequences differed, indicating a problem with state initialization or progression.");
    }
    return equal;
}

// 4. Compute the cross-correlation between successive values; check that it is close enough to 0
function test_correlation(min, max) {
    local samples = generate_samples(min, max, TEST_SAMPLE_SIZE, 98765);
    local correlation = calculate_correlation(samples);

    // Check if the absolute correlation is close to 0
    local passed = abs(correlation) < CORR_TOLERANCE;

    ::ModMaxiTooltips.Mod.Debug.printError(format("  - Correlation Check (%d values): Successive Cross-Correlation=%.4f. Tolerance=%.4f.",
                 TEST_SAMPLE_SIZE, correlation, CORR_TOLERANCE));

    if (passed) {
        ::ModMaxiTooltips.Mod.Debug.printError(format("    [PASS] Correlation (%.4f) is close to 0, suggesting low linear dependence.", correlation));
    } else {
        ::ModMaxiTooltips.Mod.Debug.printError(format("    [FAIL] Correlation (%.4f) is too high, suggesting non-random behavior.", correlation));
    }
    return passed;
}

// --- TEST RUNNER ---

// Main function to execute all test suites
function run_all_tests() {
    ::ModMaxiTooltips.Mod.Debug.printError("\n--- CustomRNG Test Suite ---");

    // Test Case 1: Standard positive range
    local min1 = 1;
    local max1 = 100;
    ::ModMaxiTooltips.Mod.Debug.printError(format("\n[TEST SET 1] Range: %d to %d (Sample Size: %d)", min1, max1, TEST_SAMPLE_SIZE));
    test_min_max(min1, max1);
    test_mean(min1, max1);
    test_reproducibility(min1, max1);
    test_correlation(min1, max1);

    // Test Case 2: Range including negative numbers
    local min2 = -50;
    local max2 = 50;
    ::ModMaxiTooltips.Mod.Debug.printError(format("\n[TEST SET 2] Range: %d to %d (Sample Size: %d)", min2, max2, TEST_SAMPLE_SIZE));
    test_min_max(min2, max2);
    test_mean(min2, max2);
    test_reproducibility(min2, max2);
    test_correlation(min2, max2);

    // Test Case 3: Small range
    local min3 = 5;
    local max3 = 8;
    ::ModMaxiTooltips.Mod.Debug.printError(format("\n[TEST SET 3] Range: %d to %d (Sample Size: %d)", min3, max3, TEST_SAMPLE_SIZE));
    test_min_max(min3, max3);
    test_mean(min3, max3);
    test_reproducibility(min3, max3);
    test_correlation(min3, max3);
}


// TODO: if debug
if (false) {
    run_all_tests();
}