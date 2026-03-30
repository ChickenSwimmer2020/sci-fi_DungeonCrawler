package backend;

enum abstract Lang(String) from String to String {
    var EN_US="EN_US"; //enlish
    var JP="JP"; //japanese
    var ES="ES"; //spanish
}

class Language {
    public static final applicationTitles:Map<String,String>=[
        "EN_US"=>"Sublevel Atlas-Zero",
        "JP"=>"「サブレベル・アトラス・ゼロ」",
    ];
    public static final WIPLanguages:Array<String>=[
        "JP"
    ];
    private static final languageNames:Map<String, String>=[
        "EN_US"=>"English (US)",
        "JP"=>"にほんご"
    ];
    public static function getLanguageLable(key:String):String{ //return the key, if its null just return the input.
        if(languageNames.get(key)!=null) return languageNames.get(key);
        else return key;

        return null;
    }
    public static function getTranslatedKey(key:String):String { //TODO: way to switch all instances of anything containing FlxText's font and text on the fly without restarting the game.
        if(#if (html5) Assets.getText(Paths.lang(Main.curLanguage))!=null #else FileSystem.exists(Paths.lang(Main.curLanguage))#end) {
            var lang:Dynamic=Json.parse(#if (html5) Assets.getText(Paths.lang(Main.curLanguage)) #else File.getContent(Paths.lang(Main.curLanguage))#end);
            if(Reflect.hasField(lang, key)) return Reflect.field(lang, key);
            else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(Main.curLanguage);
        return null;
    }
    public static function getTranslatedErrorMessage(?missingObject:Dynamic, key:String):String {
        if(#if (html5) Assets.getText(Paths.lang(Main.curLanguage))!=null #else FileSystem.exists(Paths.lang(Main.curLanguage))#end) {
            var lang:Dynamic=Json.parse(#if (html5) Assets.getText(Paths.lang(Main.curLanguage)) #else File.getContent(Paths.lang(Main.curLanguage))#end);
            if(Reflect.hasField(lang, key)){
                var error:String=Reflect.field(lang, key);
                return error.replace('{OBJ}', missingObject);
            }else return key; //just return the base string ID if there is no entry. prevents issues.
        }else Main.showLanguageError(Main.curLanguage);
        return null;
    }
}