::ModMaxiTooltips.TacticalTooltip <- {}

// Completely replace actor default tooltip
::ModMaxiTooltips.TacticalTooltip.actorTooltipHook <- function(entity, _targetedWithSkill = null)
{
    if (!entity.isPlacedOnMap() || !entity.isAlive() || entity.isDying() || !entity.isDiscovered() || entity.isHiddenToPlayer())
    {
        return [];
    }

    local tooltip = ::ModMaxiTooltips.TacticalTooltip.basicInformation(entity, _targetedWithSkill);

	// A small utility function: check if setting matches entity type
    local function verifySettingValue( _settingID )
    {
        local value = ModMaxiTooltips.Mod.ModSettings.getSetting(_settingID).getValue();
        return value != "None" && (value == "All" || (value == "Player Only" && entity.isPlayerControlled()) || (value == "AI Only" && !entity.isPlayerControlled()))
    }

    if (verifySettingValue("TacticalTooltip_Attributes")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipAttributesSmall(entity, 100));
    if (verifySettingValue("TacticalTooltip_Effects")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipEffects(entity, 200));
    if (verifySettingValue("TacticalTooltip_Perks")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipPerks(entity, 300));
    if (verifySettingValue("TacticalTooltip_ActiveSkills")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getActiveSkills(entity, 400));
    if (verifySettingValue("TacticalTooltip_EquippedItems")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipEquippedItems(entity, 500));
    if (verifySettingValue("TacticalTooltip_BagItems")) tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipBagItems(entity, 600));

    tooltip.extend(ModMaxiTooltips.TacticalTooltip.getGroundItems(entity, 700));

    return tooltip;
};

::ModMaxiTooltips.TacticalTooltip.basicInformation <- function(entity, _targetedWithSkill){
    local turnsToGo = ::Tactical.TurnSequenceBar.getTurnsUntilActive(entity.getID());
    local tooltip = [
        {
            id = 1,
            type = "title",
            text = entity.getName(),
            icon = "ui/tooltips/height_" + entity.getTile().Level + ".png"
        }
    ];

    local acting_text = ::Tactical.TurnSequenceBar.getActiveEntity() == entity ? "Acting right now!" : entity.m.IsTurnDone || turnsToGo == null ? "Turn done" : "Acts in " + turnsToGo + (turnsToGo > 1 ? " turns" : " turn");
    if (entity.m.IsActingEachTurn && !entity.m.IsTurnDone && entity.isWaitActionSpent()){
        acting_text = ModMaxiTooltips.Mod.Tooltips.parseString("Acts [again|Concept.Wait] in " + turnsToGo + (turnsToGo > 1 ? " turns" : " turn"));
    }

    tooltip.extend([
        {
            id = 2,
            type = "text",
            icon = "ui/icons/initiative.png",
            text = acting_text
        }
    ])

    if (!entity.isPlayerControlled() && _targetedWithSkill != null && this.isKindOf(_targetedWithSkill, "skill"))
    {
        local tile = entity.getTile();

        if (tile.IsVisibleForEntity && _targetedWithSkill.isUsableOn(entity.getTile()))
        {
            tooltip.push({
                id = 10,
                type = "text",
                icon = "ui/icons/hitchance.png",
                text = "[color=" + ::Const.UI.Color.PositiveValue + "]" + _targetedWithSkill.getHitchance(entity) + "%[/color] chance to hit",
                children = _targetedWithSkill.getHitFactors(tile)
            });

            tooltip.push(
                {
                    id = 20,
                    type = "text",
                    text = "Total expected damage : " + _targetedWithSkill.getExpectedDamage(entity).TotalDamage,
                }
            );
            // // Modify skill.getTooltip to build skill.getDamageRange
            // // from getExpectedDamage
            // local ret = {
            //     ArmorDamage = armorDamage,
            //     DirectDamage = directDamage,
            //     HitpointDamage = hitpointDamage,
            //     TotalDamage = hitpointDamage + armorDamage + directDamage
            // };
        }
    }


    tooltip.extend(ModMaxiTooltips.TacticalTooltip.getTooltipAttributesSmall(entity, 40));

    // Add all progressbars
    tooltip.extend([
        {
            id = 50,
            type = "progressbar",
            icon = "ui/icons/armor_head.png",
            value = entity.getArmor(::Const.BodyPart.Head),
            valueMax = entity.getArmorMax(::Const.BodyPart.Head),
            text = "" + entity.getArmor(::Const.BodyPart.Head) + " / " + entity.getArmorMax(::Const.BodyPart.Head) + "",
            style = "armor-head-slim"
        },
        {
            id = 51,
            type = "progressbar",
            icon = "ui/icons/armor_body.png",
            value = entity.getArmor(::Const.BodyPart.Body),
            valueMax = entity.getArmorMax(::Const.BodyPart.Body),
            text = "" + entity.getArmor(::Const.BodyPart.Body) + " / " + entity.getArmorMax(::Const.BodyPart.Body) + "",
            style = "armor-body-slim"
        },
        {
            id = 52,
            type = "progressbar",
            icon = "ui/icons/health.png",
            value = entity.getHitpoints(),
            valueMax = entity.getHitpointsMax(),
            text = "" + entity.getHitpoints() + " / " + entity.getHitpointsMax() + "",
            style = "hitpoints-slim"
        },
        {
            id = 53,
            type = "progressbar",
            icon = "ui/icons/morale.png",
            value = entity.getMoraleState(),
            valueMax = ::Const.MoraleState.COUNT - 1,
            text = ::Const.MoraleStateName[entity.getMoraleState()],
            style = "morale-slim"
        },
        {
            id = 54,
            type = "progressbar",
            icon = "ui/icons/fatigue.png",
            value = entity.getFatigue(),
            valueMax = entity.getFatigueMax(),
            text = "" + entity.getFatigue() + " / " + entity.getFatigueMax() + "",
            style = "fatigue-slim"
        },
        {
            id = 55,
            type = "progressbar",
            icon = "ui/icons/action_points.png",
            value = entity.getActionPoints(),
            valueMax = entity.getActionPointsMax(),
            text = "" + entity.getActionPoints() + " / " + entity.getActionPointsMax() + "",
            style = "action-points-slim"
        }
    ]);

    return tooltip
}


// Returns a list of all attributes in tooltip-form which are not displayed as progressbars on the tooltips
// Those are Melee/Ranged Skill/Defense, Resolve and Initiative
::ModMaxiTooltips.TacticalTooltip.getTooltipAttributesSmall <- function( entity, _startID )
{
	local currentProperties = entity.getCurrentProperties();
	local baseProperties = entity.getBaseProperties();

	local function formatString( _img, _attributeCurrent)
    {
    	return format("<span> <img src='coui://%s'/>  %i </span>", _img, _attributeCurrent);
    }

    local ret = {
        id = _startID++,
        type = "text",
        text = "<div class='tooltipAttributeList'>",
        rawHTMLInText = true
    };

    ret.text += formatString("gfx/ui/icons/melee_skill.png", currentProperties.getMeleeSkill());
    ret.text += formatString("gfx/ui/icons/ranged_skill.png", currentProperties.getRangedSkill());
    ret.text += formatString("gfx/ui/icons/bravery.png", currentProperties.getBravery());
    ret.text += formatString("gfx/ui/icons/melee_defense.png", currentProperties.getMeleeDefense());
    ret.text += formatString("gfx/ui/icons/ranged_defense.png", currentProperties.getRangedDefense());
    ret.text += formatString("gfx/ui/icons/initiative.png", entity.getInitiative());

    ret.text += "</div>";

    return [ret];
};

// Returns a list of all effects in tooltip-form
::ModMaxiTooltips.TacticalTooltip.getTooltipEffects <- function( entity, _startID )
{
	local currentID = _startID;
	local collapseThreshold = ::ModMaxiTooltips.Mod.ModSettings.getSetting("CollapseEffectsWhenX").getValue();
	local effectList = [];

	local statusEffects = entity.getSkills().query(::Const.SkillType.StatusEffect | ::Const.SkillType.PermanentInjury, false, true);
	if (statusEffects.len() != 0 || ::ModMaxiTooltips.Mod.ModSettings.getSetting("HeaderForEmptyCategories").getValue() == true) ::ModMaxiTooltips.TacticalTooltip.pushSectionName(effectList, "Effects", currentID);
	currentID++;

	statusEffects.sort(@(_a,_b) _a.getName() <=> _b.getName());
	// Sort injuries to the start of the status effects list
	statusEffects.sort(function( _a, _b ) {
		if (_a.isType(::Const.SkillType.Injury) && !_b.isType(::Const.SkillType.Injury))
		{
			return -1;
		}
		else if (_b.isType(::Const.SkillType.Injury) && !_a.isType(::Const.SkillType.Injury))
		{
			return 1;
		}

		return 0;
	});

	if (statusEffects.len() < collapseThreshold)
	{
		foreach( statusEffect in statusEffects )
		{
			local effect = {
				id = currentID,
				type = "text",
				icon = statusEffect.getIcon(),
				text = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedSkillName(statusEffect, true))
			};
			currentID++;

			effectList.push(effect);
		}
	}
	else
	{
		local entryText = "";
		if (::ModMaxiTooltips.Mod.ModSettings.getSetting("TacticalTooltip_CollapseAsText").getValue())
		{
			foreach( statusEffect in statusEffects )
			{
				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedSkillName(statusEffect) + ", ";
			}
			if (entryText != "") entryText = entryText.slice(0, -2);
		}
		else
		{
			foreach( statusEffect in statusEffects )
			{
				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedSkillImage(statusEffect);
			}
		}

		effectList.push({
			id = currentID,
			type = "text",
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(entryText)
		});
		currentID++;
	}

	return effectList;
};

// Returns a list of all perks in tooltip-form
::ModMaxiTooltips.TacticalTooltip.getTooltipPerks <- function( entity, _startID )
{
	local currentID = _startID;
	local collapseThreshold = ::ModMaxiTooltips.Mod.ModSettings.getSetting("CollapsePerksWhenX").getValue();
	local perkList = [];

	local perks = entity.getSkills().query(::Const.SkillType.Perk, true, true);
	if (perks.len() != 0 || ::ModMaxiTooltips.Mod.ModSettings.getSetting("HeaderForEmptyCategories").getValue() == true) ::ModMaxiTooltips.TacticalTooltip.pushSectionName(perkList, "Perks", currentID);
	currentID++;

	// Sometimes perks add information through their getName(). That is only relevant for the 'Effects' section and should be discarded under 'Perks'
	perks.sort(@(a,b) a.m.Name <=> b.m.Name);
	if (perks.len() < collapseThreshold)
	{
		foreach( i, perk in perks )
		{
			if (::ModMaxiTooltips.Mod.ModSettings.getSetting("ShowStatusPerkAndEffect").getValue() == false)
				if (!perk.isHidden() && perk.isType(::Const.SkillType.StatusEffect)) continue;

			local perkDef = ::Const.Perks.findById(perk.getID());

			local perkEntry = {
				id = currentID,
				type = "text",
				icon = perkDef != null ? perkDef.Icon : perk.getIcon(),
				text = ::ModMaxiTooltips.Mod.Tooltips.parseString(::ModMaxiTooltips.NestedTooltips.getNestedPerkName(perk))
			};
			currentID++;

			perkList.push(perkEntry);
		}
	}
	else
	{
		local entryText = "";
		if (::ModMaxiTooltips.Mod.ModSettings.getSetting("TacticalTooltip_CollapseAsText").getValue())
		{
			foreach( perk in perks )
			{
				if (::ModMaxiTooltips.Mod.ModSettings.getSetting("ShowStatusPerkAndEffect").getValue() == false)
					if (!perk.isHidden() && perk.isType(::Const.SkillType.StatusEffect)) continue;

				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedPerkName(perk) + ", ";
			}
			if (entryText != "") entryText = entryText.slice(0, -2);
		}
		else
		{
			foreach( perk in perks )
			{
				if (::ModMaxiTooltips.Mod.ModSettings.getSetting("ShowStatusPerkAndEffect").getValue() == false)
					if (!perk.isHidden() && perk.isType(::Const.SkillType.StatusEffect)) continue;

				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedPerkImage(perk);
			}
		}

		perkList.push({
			id = currentID,
			type = "text",
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(entryText)
		});
		currentID++;
	}

	return perkList;
};

// Returns a list of all important equipped items of the character in tooltip-form
::ModMaxiTooltips.TacticalTooltip.getTooltipEquippedItems <- function( entity, _startID )
{
	local currentID = _startID;
	local itemList = [];

	local mainhandItems = entity.getItems().getAllItemsAtSlot(::Const.ItemSlot.Mainhand);
	local offhandItems = entity.getItems().getAllItemsAtSlot(::Const.ItemSlot.Offhand);
	local accessories = entity.getItems().getAllItemsAtSlot(::Const.ItemSlot.Accessory);

	if (mainhandItems.len() != 0 || offhandItems.len() != 0 || accessories.len() != 0 || ::ModMaxiTooltips.Mod.ModSettings.getSetting("HeaderForEmptyCategories").getValue() == true) ::ModMaxiTooltips.TacticalTooltip.pushSectionName(itemList, "Equipped Items", currentID);
	currentID++;

	foreach(mainhandItem in mainhandItems)
	{
		itemList.push({
			id = currentID,
			type = "text",
			icon = "ui/items/" + mainhandItem.getIcon(),
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Item+%s,itemId:%s,itemOwner:entity]", mainhandItem.getName(), mainhandItem.ClassName, mainhandItem.getInstanceID()))
		});
		currentID++;
	}
	foreach(offhandItem in offhandItems)
	{
		itemList.push({
			id = currentID,
			type = "text",
			icon = "ui/items/" + offhandItem.getIcon(),
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Item+%s,itemId:%s,itemOwner:entity]", offhandItem.getName(), offhandItem.ClassName, offhandItem.getInstanceID()))
		});
		currentID++;
	}
	foreach(accessory in accessories)
	{
		itemList.push({
			id = currentID,
			type = "text",
			icon = "ui/items/" + accessory.getIcon(),
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Item+%s,itemId:%s,itemOwner:entity]", accessory.getName(), accessory.ClassName, accessory.getInstanceID()))
		});
		currentID++;
	}

	return itemList;
};

// Returns a list of all important bag items of the character in tooltip-form
::ModMaxiTooltips.TacticalTooltip.getTooltipBagItems <- function( entity, _startID )
{
	local currentID = _startID;
	local itemList = [];

	local bagItems = entity.getItems().getAllItemsAtSlot(::Const.ItemSlot.Bag);
	if (bagItems.len() != 0 || ::ModMaxiTooltips.Mod.ModSettings.getSetting("HeaderForEmptyCategories").getValue() == true) ::ModMaxiTooltips.TacticalTooltip.pushSectionName(itemList, "Items in bag", currentID);
	currentID++;

	foreach(bagItem in bagItems)
	{
		itemList.push({
			id = currentID,
			type = "text",
			icon = "ui/items/" + bagItem.getIcon(),
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Item+%s,itemId:%s,itemOwner:entity]", bagItem.getName(), bagItem.ClassName, bagItem.getInstanceID()))
		});
		currentID++;
	}

	return itemList;
};

// Returns a list of all items that are on the ground below the entity in tooltip form
::ModMaxiTooltips.TacticalTooltip.getGroundItems <- function( entity, _startID )
{
	local currentID = _startID;
	local itemList = [];
	if (!entity.isPlacedOnMap()) return itemList;  // Fixes bug when looking at tooltips during actions like rotate when the actors tile is unspecified

	local groundItems = entity.getTile().Items;
	if (groundItems.len() != 0)
	{
		::ModMaxiTooltips.TacticalTooltip.pushSectionName(itemList, "Items on ground", currentID);
		currentID++;
		foreach(groundItem in groundItems)
		{
			itemList.push({
				id = currentID,
				type = "text",
				icon = "ui/items/" + groundItem.getIcon(),
				text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("[%s|Item+%s,itemId:%s,itemOwner:ground]", groundItem.getName(), groundItem.ClassName, groundItem.getInstanceID()))
			});
			currentID++;
		}
	}

	return itemList;
};

::ModMaxiTooltips.TacticalTooltip.getActiveSkills <- function( entity, _startID )
{
	local ret = [];

	local skills = entity.getSkills().getAllSkillsOfType(::Const.SkillType.Active);
	// Hide active skills for which NPC characters do not have an AI Behavior
	// We exclude PlayerAnimals for the edge case where a player may trigger their skills indirectly.
	if (!entity.m.IsControlledByPlayer && entity.getFaction() != ::Const.Faction.PlayerAnimals)
	{
		local behaviorSkillIDs = [];
		foreach (b in entity.getAIAgent().m.Behaviors)
		{
			if (::MSU.isIn("PossibleSkills", b.m, true))
			{
				behaviorSkillIDs.extend(b.m.PossibleSkills);
			}
		}
		for (local i = skills.len() - 1; i >= 0; i--)
		{
			if (behaviorSkillIDs.find(skills[i].getID()) == null)
			{
				skills.remove(i);
			}
		}
	}

	if (skills.len() != 0 || ::ModMaxiTooltips.Mod.ModSettings.getSetting("HeaderForEmptyCategories").getValue() == true)
	{
		::ModMaxiTooltips.TacticalTooltip.pushSectionName(ret, "Actives", _startID);
		_startID++;
	}

	if (skills.len() < ::ModMaxiTooltips.Mod.ModSettings.getSetting("CollapseActivesWhenX").getValue())
	{
		foreach (skill in skills)
		{
			ret.push({
				id = _startID++,
				type = "text",
				icon = skill.getIcon(),
				text = ::ModMaxiTooltips.Mod.Tooltips.parseString(format("%s (%s, %s)", ::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill), ::MSU.Text.colorNegative(skill.getActionPointCost()), ::MSU.Text.colorPositive(skill.getFatigueCost())))
			});
		}
	}
	else
	{
		local entryText = "";
		if (::ModMaxiTooltips.Mod.ModSettings.getSetting("TacticalTooltip_CollapseAsText").getValue())
		{
			foreach (skill in skills)
			{
				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedSkillName(skill) + ", ";
			}
			if (entryText != "") entryText = entryText.slice(0, -2);
		}
		else
		{
			foreach (skill in skills)
			{
				entryText += ::ModMaxiTooltips.NestedTooltips.getNestedSkillImage(skill, true);
			}
		}

		ret.push({
			id = _startID,
			type = "text",
			text = ::ModMaxiTooltips.Mod.Tooltips.parseString(entryText)
		});
	}

	return ret;
};


::ModMaxiTooltips.TacticalTooltip.pushSectionName <- function ( _list, _title, _startID )
{
	_list.push({
		id = _startID,
		type = "text",
		text = "[u][size=15]" + _title + "[/size][/u]"
	});
};
