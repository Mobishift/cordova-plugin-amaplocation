module.exports = function(context){
	
	var path = context.requireCordovaModule('path'),
        fs = context.requireCordovaModule('fs'),
        projectRoot = context.opts.projectRoot,
        ConfigParser = context.requireCordovaModule('cordova-lib').configparser,
        config = new ConfigParser(path.join(projectRoot, 'config.xml'));
	
	console.log('setting amap location service...');
	
	var packageNames = config.android_packageName() || config.packageName();
    var targetFile = path.join(projectRoot, 'platforms', 'android', 'src', packageNames.replace(/\./g, path.sep), 'MainActivity.java');
	
	var content = fs.readFileSync(targetFile, {encoding: 'utf8'});
	if(content.indexOf('com.mobishift.cordova.plugins.amaplocation.LocationPreferences') === -1){
		content = content.replace('import org.apache.cordova.*;', [
			'import org.apache.cordova.*;', 
			'import com.mobishift.cordova.plugins.amaplocation.LocationPreferences;'
		].join('\n'));
		
		if(content.indexOf('public void onResume') === -1){
			content = content.replace('public void onCreate', [
				'public void onResume(){',
					'super.onResume();',
					'LocationPreferences.inBackground = true;',
				'}',
				'@Override',
				'public void onCreate',
			].join('\n'));
		}else{
			content = content.replace('super.onResume();', [
				'super.onResume();',
				'LocationPreferences.inBackground = true;',
			].join('\n'));
		}
		
		if(content.indexOf('public void onPause') === -1){
			content = content.replace('public void onCreate', [
				'public void onPause(){',
					'super.onPause();',
					'LocationPreferences.inBackground = false;',
				'}',
				'@Override',
				'public void onCreate',
			].join('\n'));
		}else{
			content = content.replace('super.onPause();', [
				'super.onPause();',
				'LocationPreferences.inBackground = false;'	
			].join('\n'));
		}
		
		fs.writeFileSync(targetFile, content);
	}
};