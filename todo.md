# Plan

- x Add coui
- x Add basic css for attributes
- Integrate initiative and tactical tooltips

- Integrate basegame tooltip
- Clean some shit

## Reference

- Tooltips are constructed by data_001\ui\screens\tooltip\modules\tooltip_module.js

## Wishlist

- objective:

    - all information is available
    - you should never need to go to the wiki for information

- all features togglable on and off via menu.

- show enemy damage
- Explicit values for enemy health, armor, action points.
- View enemy and player stats on tooltips (MA, MD, RA, RD, Init, Valor).
- Integrate with the nested tooltips mod.
- Rewrite tactical hit factors to integrate nested tooltips and add information.
    - head hit chance
    - damage prediction
    - percent chance to kill (if non 0)
    - show shield health and damage if attack targets shields

- damage estimation:

    - from skill.getExpectedDamage( _target ) (in D:\Downloads\bb_data\extracted\data_001\scripts\skills\skill.nut)
    - from a better calculator

- Rewrite show turn order to also show initiative, and show iniative in section at bottom

- nice to have:

    - show injury threshold / give information about injury chance
    - show shield health
