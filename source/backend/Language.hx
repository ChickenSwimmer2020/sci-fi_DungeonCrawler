package backend;

enum abstract Lang(String) from String to String {
    var EN_US="EN_US"; //enlish
    var JP="JP"; //japanese
    var ES="ES"; //spanish
}

class Language {
    public static final languageInformation:Map<String,Dynamic>=[
        "EN_US"=>[
            "application_title"=>"Sublevel Atlas-Zero",
            "label"=>"English (US)"
        ],
        "JP"=>[
            "application_title"=>"「サブレベル・アトラス・ゼロ」",
            "label"=>"にほんご"
        ],
        "WIPLanguages"=>[
            "JP"
        ]
    ];
    /**
     * keys that the Language parser will completely ignore, EG: just return nothing if the key is disabled.
     */
    private static final disabledKeys:Array<String>=[
        "",
        "weapon.null",
        "window title"
    ];
    public static var activeLanguageObject:Map<String, Dynamic> = [];
    public static function getLanguageLable(key:String):String{ //return the key, if its null just return the input.
        if(languageInformation.get(Main.curLanguage).get("label")!=null) return languageInformation.get(Main.curLanguage).get("label");
        else return key;

        return null;
    }
    public static function getTranslatedKey(key:String, object:Null<Dynamic>, ?overrides:Map<String,String>):String {
        if(disabledKeys.indexOf(key)!=-1)return ""; //ignore disabled keys.
        if(#if (html5) Assets.getText(Paths.lang(Main.curLanguage))!=null #else FileSystem.exists(Paths.lang(Main.curLanguage))#end) {
            var lang:Dynamic=Json.parse(#if (html5) Assets.getText(Paths.lang(Main.curLanguage)) #else File.getContent(Paths.lang(Main.curLanguage))#end);
            var targetString:String = "";
            if(object!=null && activeLanguageObject.get(key)==null){
                activeLanguageObject.set(key, object);
            }
            targetString = Json.checkRecursive(lang, key)??key;
            if(targetString==key){
                Main.Trace(WARN, 'could not locate language key for "$key" in ${getLanguageLable(Main.curLanguage)}!');
                return key; //causes crashes if this isnt here??
            }else if(overrides!=null){
                for(key => replacer in overrides) targetString = targetString.replace(key, replacer);
                return targetString;
            }else return targetString;

        }else Main.showLanguageError(Main.curLanguage, haxe.CallStack.toString(haxe.CallStack.callStack()));
        return null;
    }
}