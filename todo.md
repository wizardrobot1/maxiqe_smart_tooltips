# Plan

## Test

test with and without saturation
for a mild value of point budget

CHECK PARAMETERS AHEAD OF TIME
MODIFY THEM PROGRAMMATICALLY MAYBE?

entities

For racial
scripts/entity/tactical/skeleton.nut
scripts/entity/tactical/enemies/alp.nut
scripts/entity/tactical/enemies/schrat.nut
scripts/entity/tactical/enemies/sand_golem.nut
scripts/entity/tactical/enemies/sand_golem_high.nut

racial + BF
scripts/entity/tactical/enemies/skeleton_heavy.nut

BF
scripts/entity/tactical/humans/hedge_knight.nut

nimble
scripts/entity/tactical/humans/assassin.nut

nimble + steel brow
scripts/entity/tactical/humans/noble_sergeant.nut

attacker:
barbarian_thrall

setup:
- add shield scripts/items/shields/kite_shield.nut to 1H attacks
- add duelist for 1H
- add trait for additional damage

weapons
scripts/items/weapons/arming_sword.nut
scripts/items/weapons/crossbow.nut
scripts/items/weapons/battle_whip.nut
scripts/items/weapons/fencing_sword.nut
scripts/items/weapons/greatsword.nut
scripts/items/weapons/javelin.nut
scripts/items/weapons/longaxe.nut
scripts/items/weapons/masterwork_bow.nut
scripts/items/weapons/rondel_dagger.nut
scripts/items/weapons/two_handed_flail.nut
scripts/items/weapons/two_handed_flanged_mace.nut
scripts/items/weapons/two_handed_hammer.nut
scripts/items/weapons/winged_mace.nut
scripts/items/weapons/woodcutters_axe.nut

Find associated skills

armor
scripts/items/armor/cultist_leather_robe.nut
scripts/items/armor/leather_lamellar.nut
scripts/items/armor/coat_of_plates.nut
scripts/items/armor/apron.nut

scripts/items/helmets/cultist_leather_hood.nut
scripts/items/helmets/full_helm.nut
scripts/items/helmets/headscarf.nut
scripts/items/helmets/flat_top_helmet.nut

compare

super slow
- compute_parameters_from_attack
- attack_info_summary__slow__exact

with various rolls
- damage_from_parameters__with_roll
- damage_direct__with_roll

## Todo

- documentation

- hit factors: visual improvements

    - clearly separate sections

- menu control

    - hit factors

- bugs:
    - "Perk+" tooltips not working?
        - check if it works in legends?
    - Rounding error difference between the two smartfast calculations somehow
        - check details of code?
        - >> replaced a maxf by max?
        - run benchmark or test?

- remove timers? Or use them to give a warning to user?

- MSU: enable RawHtml in all tooltips

- $ re-add armor break info

- hit factors: code improvements
    - ? util functions:
        - show value: function(val: number) -> color, display +%
        - tooltip line: icon name, content
    - $ improve code for immunities

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
