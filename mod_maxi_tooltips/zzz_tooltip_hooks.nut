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

::ModMaxiTooltips.ModHook.hook("scripts/skills/skill", function(q) {

    q.getHitFactors = @(__original) function(tile) {
		if (ModMaxiTooltips.Mod.ModSettings.getSetting("show_original_hitfactors").getValue()) {
            return __original(tile)
        } else {
			return ::ModMaxiTooltips.TacticalTooltip.getHitFactors(this, tile)
		}
    }

});


// ::ModMaxiTooltips.ModHook.hook("scripts/ui/screens/tooltip/tooltip_events", function(q) {

//     q.general_queryUIPerkTooltipData = @(__original) function( _entityId, _perkId ) {
// 		local perk = this.Const.Perks.findById(_perkId);
// 		local player = this.Tactical.getEntityByID(_entityId);

// 		::ModMaxiTooltips.Mod.Debug.printLog("general_queryUIPerkTooltipData; _entityId = " + _entityId + "; _perkId = " + _perkId);

// 		return __original( _entityId, _perkId )
// 	}
// });


