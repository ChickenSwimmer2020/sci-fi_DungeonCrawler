package backend;

enum abstract Lang(String) from String to String {
    var EN_US="EN_US"; //enlish
    var JP="JP"; //japanese
    var ES="ES"; //spanish
}

class Language {
    public static var activeLanguageObject:Map<String, Dynamic> = [

    ];
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
    public static function getTranslatedKey(key:String, object:Null<Dynamic>, ?overrides:Map<String,String>):String {
        if(#if (html5) Assets.getText(Paths.lang(Main.curLanguage))!=null #else FileSystem.exists(Paths.lang(Main.curLanguage))#end) {
            var lang:Dynamic=Json.parse(#if (html5) Assets.getText(Paths.lang(Main.curLanguage)) #else File.getContent(Paths.lang(Main.curLanguage))#end);
            var targetString:String = "";
            if(object!=null && activeLanguageObject.get(key)==null){
                activeLanguageObject.set(key, object);
            }
            if(Reflect.hasField(lang, key)) targetString = Reflect.field(lang, key);
            else return key; //just return the base string ID if there is no entry. prevents issues.
            if(overrides!=null){
                for(key => replacer in overrides) targetString = targetString.replace(key, replacer);
                return targetString;
            }else return targetString;
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