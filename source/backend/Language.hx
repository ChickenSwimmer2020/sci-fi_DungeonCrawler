package backend;

enum abstract Lang(String) from String to String {
    var EN_US="EN_US";
    var KLINGON="tomfuckery";
}

class Language {
    public static function getTranslatedKey(language:Lang, key:String):String {
        if(#if (android || html5) Assets.getText(Paths.lang(language))!=null #else FileSystem.exists(Paths.lang(language))#end) {
            var lang:Dynamic=Json.parse(#if (android || html5) Assets.getText(Paths.lang(language)) #else File.getContent(Paths.lang(language))#end);
            if(Reflect.hasField(lang, key)) return Reflect.field(lang, key);
            else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(language);
        return null;
    }
    public static function getTranslatedErrorMessage(language:Lang, ?missingObject:Dynamic, key:String):String {
        if(#if (android || html5) Assets.getText(Paths.lang(language))!=null #else FileSystem.exists(Paths.lang(language))#end) {
            var lang:Dynamic=Json.parse(#if (android || html5) Assets.getText(Paths.lang(language)) #else File.getContent(Paths.lang(language))#end);
            if(Reflect.hasField(lang, key)){
                var error:String=Reflect.field(lang, key);
                return error.replace('{OBJ}', missingObject);
            }else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(language);
        return null;
    }
}