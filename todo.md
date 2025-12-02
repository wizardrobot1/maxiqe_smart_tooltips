# Plan

## Todo

- MSU: enable RawHtml in all tooltips

- x include hit factors
    - done, via direct copying of built-in hit-factors + reference mod

- x add first line head / body distinction in multi-hit MC

- tests:
    - check attack tooltip in various conditions
    - check gash skill

- Icon tooltips to explain what is going on

- hit factors: visual improvements
    - icons?
    - clearly separate sections
    - clear alerts for immunities and 9lives

- hit factors: code improvements
    - add nine lives
    - separate function for each section
    - util functions:
        - show value: function(val: number) -> color, display +%
        - tooltip line: icon name, content
    - separate function for each line
    - improve code for immunities
    - improve damage reduction code

- bugs:
    - "Perk+" tooltips not working?
        - check if it works in legends?
    - Rounding error difference between the two smartfast calculations somehow
        - check details of code?
        - >> replaced a maxf by max?

- menu control

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
