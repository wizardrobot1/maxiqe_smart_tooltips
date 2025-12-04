var MaxiTooltipsJSConnection = function(_parent)
{
	MSUBackendConnection.call(this);
	this.mModID = MaxiTooltips.ID;
	this.mID = MaxiTooltips.JSConnectionID;
}

MaxiTooltipsJSConnection.prototype = Object.create(MSUBackendConnection.prototype);
Object.defineProperty(MaxiTooltipsJSConnection.prototype, 'constructor', {
	value: MaxiTooltipsJSConnection,
	enumerable: false,
	writable: true
});

registerScreen(MaxiTooltips.JSConnectionID, new MaxiTooltipsJSConnection());
