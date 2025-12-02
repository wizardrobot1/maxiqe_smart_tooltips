::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/actor", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(this, _targetedWithSkill);
	}

});

::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/player", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(this, _targetedWithSkill);
	}

});

