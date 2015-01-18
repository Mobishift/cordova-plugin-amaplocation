window.locationService = {
	execute: function(action, successCallback, errorCallback) {
		cordova.exec(    
			successCallback, 
			errorCallback,
			"AMapLocation",
			action,
			[]
		)
	},
	getCurrentPosition: function(successCallback, errorCallback) {
		this.execute("getCurrentPosition", successCallback, errorCallback);
	}
}
module.exports = locationService;