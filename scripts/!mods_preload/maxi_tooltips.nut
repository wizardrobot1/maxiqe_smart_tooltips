::MaxiTooltips <- {
	ID = "maxi_tooltips",
	Name = "MaxiTooltips",
	Version = "1.0.0"
}
::mods_registerMod(::MaxiTooltips.ID, ::MaxiTooltips.Version, ::MaxiTooltips.Name);

::mods_queue(::MaxiTooltips.ID, null, function()
{
	::MaxiTooltips.Mod <- ::MSU.Class.Mod(::MaxiTooltips.ID, ::MaxiTooltips.Version, ::MaxiTooltips.Name);
	::mods_registerJS("./mods/MaxiTooltips/index.js");
	::mods_registerCSS("./mods/MaxiTooltips/index.css");
})