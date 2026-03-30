package states;

class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<FlxButton>=[];
    public function new() {
        super();

        logo=new FlxSprite(FlxG.width-500, 0).makeGraphic(500, 200, 0xFFFF0000);
        add(logo); //TODO: placeholder graphic
        final onButtonClicked:Array<Void->Void>=[
            ()->{
                trace('new game');
                #if debug
                    Save.DEBUGSAVE('test');
                    Save.DEBUGSAVE('test1');
                    Save.DEBUGSAVE('test2');
                    Save.DEBUGSAVE('test3');
                    Save.DEBUGSAVE('test4');
                #end
            },
            ()->{
                openSubState(new LoadGameSubstate());
            },
            ()->{
                openSubState(new OptionsMenuSubstate());
            },
            ()->{trace('gallery');},
            ()->{trace('achivements');},
            ()->{     
                #if html5
                    js.Browser.window.close();
                #else
                    Sys.exit(1);
                #end
            }
        ];
        final strings:Array<String>=[
            Language.getTranslatedKey("menu.new_game"),
            Language.getTranslatedKey("menu.load_game"),
            Language.getTranslatedKey("menu.config"),
            Language.getTranslatedKey("menu.art"),
            Language.getTranslatedKey("menu.awards"),
            Language.getTranslatedKey("menu.quit")
        ];

        for(i in 0...strings.length) {
            var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), strings[i], onButtonClicked[i]);
            buttons.push(button);
            add(button);
        }

        //TODO: cool bg art
        //TODO: menu theme


        #if (debug)
            var debuggerButton:FlxButton = new FlxButton(FlxG.width-(logo.width+80), 200, Language.getTranslatedKey("menu.debug.debugger"), ()->{
                openSubState(new DebuggerChooser());
            });
            add(debuggerButton);
        #end
    }
}

#if (debug)
class DebuggerChooser extends FlxSubState {
    final debuggerOptions:Map<String, Void->Void>=[
        Language.getTranslatedKey("debugger.map") => ()->{
            FlxG.switchState(MapDebugger.new);
        },
        Language.getTranslatedKey("debugger.testing")=>()->{
            FlxG.switchState(()->new TestingState(false));
        },
        Language.getTranslatedKey("debugger.save")=>()->{
            FlxG.switchState(SaveDebugger.new);
        },
        Language.getTranslatedKey("debugger.alphabet")=>()->{
            FlxG.switchState(AlphabetDebugger.new);
        }
    ];
    public function new() {
        super();

        var bg = add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000));
        Reflect.setField(bg, "alpha", 0); //stupid that i have to do this but OKAY.
        FlxTween.tween(bg, {alpha: 0.25}, 0.54212, {ease: FlxEase.expoOut});

        var i:Int=0;
        for(lable => func in debuggerOptions) {
            var button = add(new FlxButton(0, 0+(40*i), lable, func));
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