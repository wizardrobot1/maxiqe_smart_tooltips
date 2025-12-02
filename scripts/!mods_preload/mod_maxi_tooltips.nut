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
::ModMaxiTooltips.ModHook.require("mod_msu >= 1.2.7", "mod_modern_hooks >= 0.4.10");
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
}, ::Hooks.QueueBucket.FirstWorldInit);
