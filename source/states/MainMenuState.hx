package states;

class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<FlxButton>=[];
    public function new() {
        super();
        logo=new FlxSprite(FlxG.width-500, 0).makeGraphic(500, 200, 0xFFFF0000);
        add(logo); //TODO: placeholder graphic
    
        final strings:Array<String>=[
            Language.getTranslatedKey(Main.curLanguage, "menu.new_game"),Language.getTranslatedKey(Main.curLanguage, "menu.load_game"),Language.getTranslatedKey(Main.curLanguage, "menu.config"),Language.getTranslatedKey(Main.curLanguage, "menu.art"),Language.getTranslatedKey(Main.curLanguage, "menu.awards"),Language.getTranslatedKey(Main.curLanguage, "menu.quit")
        ];
        for(i in 0...strings.length) {
            var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), strings[i], [
                ()->{},
                ()->{},
                ()->{
                    openSubState(new OptionsMenuSubstate());
                },
            ][i]);
            buttons.push(button);
            add(button);
        }

        //TODO: cool bg art
        //TODO: menu theme


        #if (debug && !android)
            var debuggerButton:FlxButton = new FlxButton(FlxG.width-80, FlxG.height-20, Language.getTranslatedKey(Main.curLanguage, "menu.debug.debugger"), ()->{
                openSubState(new DebuggerChooser());
            });
            add(debuggerButton);
        #end
    }
}

#if (debug && !android)
class DebuggerChooser extends FlxSubState {
    final debuggerOptions:Map<String, Void->Void>=[
        Language.getTranslatedKey(Main.curLanguage, "debugger.map") => ()->{
            FlxG.switchState(MapDebugger.new);
        },
        Language.getTranslatedKey(Main.curLanguage, "debugger.testing")=>()->{
            FlxG.switchState(TestingState.new);
        },
        Language.getTranslatedKey(Main.curLanguage, "debugger.save")=>()->{
            FlxG.switchState(SaveDebugger.new);
        }
    ];
    public function new() {
        super();

        var bg = add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000));
        Reflect.setField(bg, "alpha", 0); //stupid that i have to do this but OKAY.
        FlxTween.tween(bg, {alpha: 0.25}, 0.54212, {ease: FlxEase.expoOut});

        var i:Int=0;
        for(lable => func in debuggerOptions) {
            var button = add(new FlxButton(0, 0+(20*i), lable, func));
            add(button);
            Reflect.setField(button, "x", FlxG.width/2-40);
            i++;
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ESCAPE) close();
    }
}
#end