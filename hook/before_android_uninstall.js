module.exports = function(context){
	
	var path = context.requireCordovaModule('path'),
        fs = context.requireCordovaModule('fs'),
        projectRoot = context.opts.projectRoot,
        ConfigParser = context.requireCordovaModule('cordova-lib').configparser,
        config = new ConfigParser(path.join(projectRoot, 'config.xml'));
	
	console.log('removing amap location service setting...');
	
	var packageNames = config.android_packageName() || config.packageName();
    var targetFile = path.join(projectRoot, 'platforms', 'android', 'src', packageNames.replace(/\./g, path.sep), 'MainActivity.java');
	
	var content = fs.readFileSync(targetFile, {encoding: 'utf8'});
	if(content.indexOf('com.mobishift.cordova.plugins.amaplocation.LocationPreferences') >= 0){
		content = content.replace('\nimport com.mobishift.cordova.plugins.amaplocation.LocationPreferences;', '')
				.replace('\nLocationPreferences.inBackground = true;', '')
				.replace('\nLocationPreferences.inBackground = false;', '');
		
		fs.writeFileSync(targetFile, content);
	}
};