::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/actor", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
		local tooltip = __original(_targetedWithSkill);

        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(tooltip, this);
	}

});

::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/player", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
		local tooltip = __original(_targetedWithSkill);

        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(tooltip, this);
	}

});

