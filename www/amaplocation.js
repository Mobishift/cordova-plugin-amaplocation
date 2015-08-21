var exec = require('cordova/exec');

var noop = function(){};

window.locationService = {
	execute: function(action, params, successCallback, errorCallback) {
		exec(    
			successCallback, 
			errorCallback,
			"AMapLocation",
			action,
			[params]
		)
	},
	getCurrentPosition: function(successCallback, errorCallback) {
		this.execute("getCurrentPosition", {}, successCallback, errorCallback);
	},
	start: function(callback, errorCallback, options){
		callback = callback || noop;
		errorCallback = errorCallback || noop;
		this.execute("start", options, callback, errorCallback);
	},
	stop: function(successCallback, errorCallback){
		successCallback = successCallback || noop;
		errorCallback = errorCallback || noop;
		this.execute("stop", {}, successCallback, errorCallback);
	},
	read: function(successCallback, errorCallabck){
		successCallback = successCallback || noop;
		errorCallabck = errorCallabck || noop;
		this.execute("read", {}, successCallback, errorCallabck);
	}
};
module.exports = window.locationService;