::ModMaxiTooltips <- {
	ID = "mod_maxi_tooltips",
	Name = "ModMaxiTooltips",
	Version = "1.0.0",
	QueueBucket = {
		FirstWorldInit = []
	}

}

local queueLoadOrder = [">mod_msu", ">mod_modern_hooks", ">mod_nested_tooltips"];

::ModMaxiTooltips.ModHook <- ::Hooks.register(::ModMaxiTooltips.ID, ::ModMaxiTooltips.Version, ::ModMaxiTooltips.Name);
::ModMaxiTooltips.ModHook.require("mod_msu >= 1.2.7", "mod_modern_hooks >= 0.4.10", "mod_nested_tooltips >= 0.2.0");
::ModMaxiTooltips.ModHook.queue(queueLoadOrder, function()
{
	// Declare mod
	::ModMaxiTooltips.Mod <- ::MSU.Class.Mod(::ModMaxiTooltips.ID, ::ModMaxiTooltips.Version, ::ModMaxiTooltips.Name);

    ::ModMaxiTooltips.Mod.Debug.enable();

	// file imports
	foreach (file in ::IO.enumerateFiles("mod_maxi_tooltips"))
	{
        ::ModMaxiTooltips.Mod.Debug.printLog("MaxiTooltipsLog: Loading nut file : " + file);
		::include(file);
	}

	foreach (file in ::IO.enumerateFiles("ui/mods/mod_maxi_tooltips/js"))
	{
        ::ModMaxiTooltips.Mod.Debug.printLog("MaxiTooltipsLog: Loading JS file : " + file);
		::Hooks.registerJS(file + ".js");
	}

	foreach (file in ::IO.enumerateFiles("ui/mods/mod_maxi_tooltips/css"))
	{
        ::ModMaxiTooltips.Mod.Debug.printLog("MaxiTooltipsLog: Loading CSS file : " + file);
		::Hooks.registerCSS(file + ".css");
	}
});

::ModMaxiTooltips.ModHook.queue(queueLoadOrder, function() {

	foreach (func in ::ModMaxiTooltips.QueueBucket.FirstWorldInit)
	{
		func();
	}
	delete ::ModMaxiTooltips.QueueBucket;

	{
		local armor = ::new("scripts/items/armor/coat_of_plates.nut");
		armor.create();

		::ModMaxiTooltips.Mod.Debug.printLog(armor.m.ID);


		local thrall = ::World.getTemporaryRoster().create("scripts/entity/tactical/enemies/bandit_thug");

		local hammer = ::new("scripts/items/weapons/warhammer.nut");
		// spear.create();

		thrall.m.Items.equip(hammer);

		foreach (skill in thrall.m.Skills.m.Skills) {
			::MSU.Log.printData(skill.m.ID);
		}

		local attacker = thrall;
		local target = thrall;
		local skill = thrall.getSkills().getSkillByID("actives.hammer");
		local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);

		::ModMaxiTooltips.Mod.Debug.printLog("Parameters for attack");
		::MSU.Log.printData(parameters_head);

		local summary = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_head, "head");

		::ModMaxiTooltips.Mod.Debug.printLog("Summary for attack");
		::MSU.Log.printData(summary);

		local info_exact = ::ModMaxiTooltips.TacticalTooltip.attack_info_summary__slow__exact(attacker, target, skill);

		::ModMaxiTooltips.Mod.Debug.printLog("info_exact.head for attack");
		::MSU.Log.printData(info_exact.head);

		::ModMaxiTooltips.Mod.Debug.printLog("Predicted damage for thrall on thrall violence");
	}


}, ::Hooks.QueueBucket.FirstWorldInit);
