````js
local properties = skill.m.Container.buildPropertiesForUse(skill, _targetEntity);

local info = {
    Skill = skill,
    Container = skill.getContainer(),
    User = _user,
    TargetEntity = _targetEntity,
    Properties = properties,
    DistanceToTarget = distanceToTarget
};

// Which body part is hit
bodyPart = RANDOM(HEAD | BODY);

// Multipliers
bodyPartDamageMult = _info.Properties.DamageAgainstMult[bodyPart];
local damageMult = this.m.IsRanged ? _info.Properties.RangedDamageMult : _info.Properties.MeleeDamageMult;
damageMult = damageMult * _info.Properties.DamageTotalMult;

// Rolls
local roll_armor = this.Math.rand(_info.Properties.DamageRegularMin, _info.Properties.DamageRegularMax)
local roll_regular = this.Math.rand(_info.Properties.DamageRegularMin, _info.Properties.DamageRegularMax);

local damageArmor = roll_armor * _info.Properties.DamageArmorMult;
damageArmor = this.Math.max(0, damageArmor + _info.DistanceToTarget * _info.Properties.DamageAdditionalWithEachTile);
damageArmor = damageArmor * damageMult;

local damageRegular = roll_regular * _info.Properties.DamageRegularMult;
damageRegular = this.Math.max(0, damageRegular + _info.DistanceToTarget * _info.Properties.DamageAdditionalWithEachTile);
damageRegular = damageRegular * damageMult;

local damageDirect = this.Math.minf(1.0, _info.Properties.DamageDirectMult * (this.m.DirectDamageMult + _info.Properties.DamageDirectAdd + (this.m.IsRanged ? _info.Properties.DamageDirectRangedAdd : _info.Properties.DamageDirectMeleeAdd)));

````