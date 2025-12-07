# Plan

## Test

- test in scenario

- check hit factors tooltips
    - check riposte
    - check swamp hit factor popup
    - x check nine lines
    - x check shieldwall with bonus
    - x check night hit factor popup
    - x check racials
    - x check items on actor and ground
    - x check perks
    - x check actives
    - x check displayed hit chance on tooltip versus in log

- remove `::ModMaxiTooltips.Mod.Debug` in all files

# Improvements for v1.1

- MSU: enable RawHtml in all tooltips

- update all tooltips

```
@MaxiQE When using nested tooltips for vanilla perks, you will run into another issue. There are some vanilla perks for which a perk def entry does not exist in ::Const.Perks.LookupMap. Therefore, they will not display a nested tooltip. We have fixed this in Reforged by adding custom tooltips and custom icons for those perks (some vanilla perks are missing an icon too).

Perhaps it would make sense for Nested Tooltips Framework to include these fixes i.e. we can add perkdefs for these vanilla perks and also add icons for them where relevant.

Here is a list of vanilla perks (these are present only on enemies) that suffer from these issues:

    Battering Ram (missing perkdef)

Stalwart (missing perkdef and icon)Devastating Strikes (missing perkdef and icon)Sundering Strikes (missing perkdef)Battle Flow (missing perkdef and icon)Inspiring Presence (missing perkdef)
Then there are various vanilla perks that use the wrong icon in their perk script file. This doesn't cause any issues in vanilla, but may cause issue if some mod shows them as Status Effect. Examples:

    Backstabber (uses the Brawny icon).

many others.
Then there are various vanilla active skills which are either missing icons or use the wrong icons. E.g.

    Alp teleport (missing icon)

Barbarian Fury (missing disabled icon)For almost all vanilla skills that are present on enemies only, the "Disabled" i.e. black & white icons are missing.Similarly, the icons are also missing from the gfx folder for almost all enemy-only vanilla skills. E.g. orc warlord Warcry.many others.

    Many vanilla enemy-only skills are missing a getTooltip definition, so they will just show their Name and Description in their nested tooltip, no further information.


    Many vanilla enemy-only skills are missing a Name or Description string. So they will just show empty strings for those.
```

- Add nested tooltip icons to hit factors

- Add icons for damage reduction effects, instead of text

- Add explainer text (it's already coded, I think?) for distance to target and height difference

- Add nested tooltips to hit factors:

    - x swamp
    - x night-time
    - defender abilities

- hit factor: add defender reduced RD during nighttime

- hit factors: visual improvements

    - clearly separate sections
    - css styling to align the bonus, malus, etc on a single column

- try? separate armor break as a separate line

- use weighted mean util in main damage calculation

- add:
    - injury list
    - injury threshold
    - ?injury chance?? (but no space to display information?)

- ? shield attacks

- other remarks

## modular vanilla integration

I don't think it would be a good idea

https://discord.com/channels/965324395851694140/965325048015646770/1445385056422989885

The issue is that vanilla code is pure spaghetti (no disrespect meant: if I were coding a game, my code would also be spaghetti)

    The hit-information object is initialized here and gets modified throughout that function: https://github.com/Battle-Modders/mod_modular_vanilla/blob/development/mod_modular_vanilla/hooks/skills/skill.nut#L442

Then here https://github.com/Battle-Modders/mod_modular_vanilla/blob/e630b6d2d71452e2c5d6d9b8ad5fb45195262714/mod_modular_vanilla/hooks/skills/skill.nut#L244Then it passes through here, with other updates and part of the damage calculation https://github.com/Battle-Modders/mod_modular_vanilla/blob/e630b6d2d71452e2c5d6d9b8ad5fb45195262714/mod_modular_vanilla/hooks/skills/skill.nut#L551finally it goes to here for further calculation and resolution: https://github.com/Battle-Modders/mod_modular_vanilla/blob/development/mod_modular_vanilla/hooks/entity/tactical/actor.nut#L303
Then, there's the minor issue that I can't hook in the current MV functions even with the parameters, requiring some additional modifications there
