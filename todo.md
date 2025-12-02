# Plan

## Todo

- menu control

    - monte-carlo: num-samples
    - fast: num samples
    - ::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params
        - local total_number_of_points = 7;

- ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast <- function(parameters) {
    local maximum_sampling_points = 105;
    local armor_roll_number_of_points = 7;

    - raise armor_roll_number_of_points if the number of points is low enough that (max - min + 1)**2 <= maximum_sampling_points


- ::ModMaxiTooltips.TacticalTooltip.attack_info_tooltip_split_man
    
    - x single line when damage is equal

- hit factors: code improvements
    - add nine lives
    - separate function for each section
    - util functions:
        - show value: function(val: number) -> color, display +%
        - tooltip line: icon name, content
    - separate function for each line
    - improve code for immunities
    - improve damage reduction code

- hit factors: visual improvements
    - icons?
    - clearly separate sections
    - clear alerts for immunities and 9lives

- bugs:
    - "Perk+" tooltips not working?
        - check if it works in legends?
    - Rounding error difference between the two smartfast calculations somehow
        - check details of code?
        - >> replaced a maxf by max?

- tests:

    - check gash sound

    - unit tests to compare:

        - `damage_from_parameters__summary__smartfast`
            - using `damage_from_parameters__with_roll`
        - `damage_direct__summary__smartfast`
            - using `damage_direct__with_roll`

        - `damage_from_parameters__summary__exact`
            - using `damage_from_parameters__with_roll`
        - `attack_info_summary__slow__exact`
            - using `damage_direct__with_roll`

- benchmark:

    - compare `damage_from_parameters__summary__exact`
    - to `damage_from_parameters__summary__smartfast`

- MSU: enable RawHtml in all tooltips

- documentation

- remove timers

## Smartfast estimation

- Decompose interval of rolls for armor damage into:
    - those that destroy armor: represent as a single point
    - the others: represent them using an interval of values
    - use at most 7 values to represent everything by default

- Represent the interval of rolls for health with 100 / armor_array.len()

- use that distribution as an approximation for the real one

## MonteCarlo

- Just roll 100 samples
- Compute the empirical average

- for multi-hit: condition on the number of hits
- for split-man: condition on where the initial hit lands: head or body

## Manual Tests

Use the combat simulator mod from taro

- Test weapons with the highest range and benchmark the time it takes to compute the damage info
- Test weapons with the Gash skill: do they spam the sound? I think they will
- Test weapons with split man
- Test the multi-hit weapons


## Wishlist

- objective:

    - all information is available
    - you should never need to go to the wiki for information

- all features togglable on and off via menu.

- x Explicit values for enemy health, armor, action points.
- x View enemy and player stats on tooltips (MA, MD, RA, RD, Init, Valor).
- show enemy damage
- Integrate with the nested tooltips mod.
- Rewrite tactical hit factors to integrate nested tooltips and add information.
    - head hit chance
    - damage prediction
    - percent chance to kill (if non 0)
    - show shield health and damage if attack targets shields

- damage estimation:

    - x from skill.getExpectedDamage( _target ) (in D:\Downloads\bb_data\extracted\data_001\scripts\skills\skill.nut)
    - x from a better calculator
    - even better calculation: injury risk

- Rewrite show turn order to also show initiative, and show iniative in section at bottom

- nice to have:

    - show injury threshold / give information about injury chance
    - show shield health
