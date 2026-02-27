package backend;

enum abstract Lang(String) from String to String {
    var EN_US="en_us";
    var KLINGON="tomfuckery";
}

class Language {
    public static function getTranslatedKey(language:Lang, key:String):String {
        if(FileSystem.exists('assets/lang/$language.lang')) {
            var lang:Dynamic=Json.parse(File.getContent('assets/lang/$language.lang'));
            if(Reflect.hasField(lang, key)) return Reflect.field(lang, key);
            else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(language);
        return null;
    }
    public static function getTranslatedErrorMessage(language:Lang, ?missingObject:Dynamic, key:String):String {
        if(FileSystem.exists('assets/lang/$language.lang')) {
            var lang:Dynamic=Json.parse(File.getContent('assets/lang/$language.lang'));
            if(Reflect.hasField(lang, key)){
                var error:String=Reflect.field(lang, key);
                return error.replace('{OBJ}', missingObject);
            }else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(language);
        return null;
    }
}