# Plan

## Todo

- MSU: enable RawHtml in all tooltips

- improve tooltip with css:
    - spacing
    - reduced size

- x clip health-damage to current health
- x optimize tooltip:
    - x don't show armor when it is 0
    - x collapse to single value when identical
    - x collapse to duo when mean is roughly in the middle
    - x show single line when damage is same from head and body and both armors are 0 

- x improve tooltip: bold values, single value
- x damage distribution:
    - compute a grid of values for the rolls
    - compute the associated values
    - half-weight on edges, normal weight everywhere else
    - compute mean
- x damage information:
    - min, max, is_min_saturated, is_max_saturated, mean

## Tests

Use the combat simulator mod from taro

- Test weapons with the highest range and benchmark the time it takes to compute the damage info
- Test weapons with the Gash skill: do they spam the sound? I think they will
- Test weapons with split man
- Test the multi-hit weapons

## Reference

- Tooltips are constructed by data_001\ui\screens\tooltip\modules\tooltip_module.js

## Good icons

- kills.png : nice skull; show chance to kill?
- difficulty_easy.png : another nice skull
- obituary.png : another nice skull
- direct_damage.png : show armor_penetrating attack
- health.png
- shield_damage.png
- warning.png

## Damage cases

- If there's no armor and the damage coefficients are the same, then hits to body and head are the same
    - show a single line with no hit-chance
- If it's a hit that's guaranteed to land on head or body, don't show the 0% line; do show hit chance on the other line; bold?
- Cap values at when they reach current armor / health
- Show when a value destroys armor / kills; bold?
- order considerations:
    - Health damage is more important than armor: show first or last?
    - Is the hit chance the less important value?
    - show HD, AD, hitchance?
- show injury threshold somewhere : not in that section; after attributes? modify it with skill (bold?)
- show health and armor? don't show
- multiple attacks:
    - split man:
        - either both halves hit or none
        - 4 rolls
        - two cases, main part goes to head or body
        - head tooltip: health-damage min - max; armor-damage min - max; head hit chance
        - body tooltip: HD min - max; body middle; head middle; body hit chance
    - flails:
        - hits are "independent"
        - show normal line
        - add indicator of the number of hits: `2X`, `3X`

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
