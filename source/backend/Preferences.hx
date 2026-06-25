package backend;

import haxe.DynamicAccess;

class Preferences {
    public static var prefs:Map<String, Dynamic> = []; //for proper prefs storage

    public static function getPref(key:String):Dynamic {
        if(prefs[key]!=null) return prefs[key];
        else Main.Trace(WARN, 'Preference $key doesnt exist!');
        return null;
    }
    public static function setPref(key:String, value:Dynamic):Bool {
        prefs[key] = value;
        writePrefsFile(); //auto do this.

        return true;
    }


    public static inline function generatePrefsFile() File.saveContent("uPrefs.json", Flags.DEFAULT_PREFERENCES_FILE);

    public static function readPrefsFile(lastAttempt:Bool = false) {
        if(FileSystem.exists('uPrefs.json')) {
            var access:DynamicAccess<Dynamic> = Json.parse(File.getContent('uPrefs.json'));
            for(key=>value in access) setPref(key, value);
            Main.Trace(DEBUG, prefs);
            return true;
        }else{
            if(lastAttempt) {
                Main.Trace(ERROR, "Couldnt generate Prefs file!");
                return false;
            }else{
                generatePrefsFile();
                readPrefsFile(true); //try again.
            }
        };
        return false; //backup
    }
    public static function writePrefsFile():Bool {
        if(FileSystem.exists('uPrefs.json')) {
            var dat:Dynamic = {};
            for(key=>value in prefs) {
                Reflect.setField(dat, key, value);
            }
            File.saveContent('uPrefs.json', Json.stringify(dat, null, "    "));
            return true;
        }else Main.Trace(ERROR, "uPrefs.json doenst exist!");
        return false;
    }
}