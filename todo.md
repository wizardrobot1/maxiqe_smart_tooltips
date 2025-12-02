# Plan

## Todo

- MSU: enable RawHtml in all tooltips

- test multi-hit
    - bug: head_hit_chance not correctly taken into account: all hits to body instead

- check exactly what's expected in the attack_info_tooltip_line function (probability? 100xproba?) and fix in MC code

- Monte carlo doesn't need to be fixed and use halton points: don't care lol
- Actually, it's trivial isn't it? Fix sequence of 

- split-man info estimation:

    - MonteCarlo with approx 100 hits
        - body: health, body armor, head armor, conditional kill proba
        - head: ...

- 3-flail info estimation:

    - MonteCarlo with approx 100 hits
        - 1 hit: health, body armor, head armor, conditional kill proba
        - 2 hit: ...
        - 3 hits: ...
        - ! Combine the three rolls

- x approximate mean calculation:
    - fast sampling of armor roll
    - precise sampling of health roll

- x Multi-hit tooltip
    - show hit multiplier with current tooltip
    - modify calculation of marginalKillChance (1 - (1 - hitchance)**k) * probaToKill
    - modify display: show marginalKillChance > or >> depending on hit chance
- x split-man tooltip
    - add additional line for second hit with current head armor
    - show that this is the split-man bonus damage line

- include hit factors

- custom icons add concept tooltips to all icons
    - x tooltips
    - icons

## Damage linearity

- If there is no armor, damage is linear
- If the attack cannot break armor, damage is linear
- If the attack always breaks armor:
    - armor damage is fixed
    - first batch is linear
    - second batch is linear with a potential spike at 0 for low damage rolls
- If breaking armor is random:
    - armor damage is linear + spike at current armor
    - first batch is linear in two parts, conditional on whether armor is broken or not
    - second batch is linear in three parts:
        - no armor break: 0
        - armor break but insufficient health damage: 0
        - armor break + sufficient damage

- 4 point linear approximation is decent
- 9 point linear estimation should be even better
- check against MCMC
- check against grouped approximations

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
