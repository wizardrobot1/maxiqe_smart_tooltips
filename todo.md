# Plan

## Todo

- bugs:
    - "Perk+" tooltips not working?
        - check if it works in legends?

## Test

- test in scenario?

- check hit factors tooltips
- check swamp hit factor popup
- check riposte
- x check nine lines
- check shieldwall with bonus
- check night hit factor popup
- check racials
- x check items on actor and ground
- x check perks
- x check actives
- check displayed hit chance on tooltip versus in log

- remove `::ModMaxiTooltips.Mod.Debug` in all files

# Improvements for v1.1

- MSU: enable RawHtml in all tooltips

- Add nested tooltip icons to hit factors

- Add nested tooltips to hit factors:

    - x swamp
    - defender abilities
    - x night-time

- hit factor: add defender reduced RD during nighttime

- hit factors: visual improvements

    - clearly separate sections
    - css styling to align the bonus, malus, etc on a single column

- separate armor break as a separate line

- use weighted mean util in main damage calculation

- ? injury threshold, injury chance information

- ? shield attacks

- other remarks

## modular vanilla integration

I don't think it would be a good idea

https://discord.com/channels/965324395851694140/965325048015646770/1445385056422989885

The issue is that vanilla code is pure spaghetti (no disrespect meant: if I were coding a game, my code would also be spaghetti)

    The hit-information object is initialized here and gets modified throughout that function: https://github.com/Battle-Modders/mod_modular_vanilla/blob/development/mod_modular_vanilla/hooks/skills/skill.nut#L442

Then here https://github.com/Battle-Modders/mod_modular_vanilla/blob/e630b6d2d71452e2c5d6d9b8ad5fb45195262714/mod_modular_vanilla/hooks/skills/skill.nut#L244Then it passes through here, with other updates and part of the damage calculation https://github.com/Battle-Modders/mod_modular_vanilla/blob/e630b6d2d71452e2c5d6d9b8ad5fb45195262714/mod_modular_vanilla/hooks/skills/skill.nut#L551finally it goes to here for further calculation and resolution: https://github.com/Battle-Modders/mod_modular_vanilla/blob/development/mod_modular_vanilla/hooks/entity/tactical/actor.nut#L303
Then, there's the minor issue that I can't hook in the current MV functions even with the parameters, requiring some additional modifications there
