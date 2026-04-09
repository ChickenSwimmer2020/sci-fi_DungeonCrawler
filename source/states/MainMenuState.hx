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
                #if(debug&&(windows||hl)) Main.LOG('new game'); #end
                #if debug
                    Save.DEBUGSAVE('test');
                    Save.DEBUGSAVE('test1');
                    Save.DEBUGSAVE('test2');
                    Save.DEBUGSAVE('test3');
                    Save.DEBUGSAVE('test4');
                #end
            },
            ()->{openSubState(new LoadGameSubstate());},
            ()->{openSubState(new OptionsMenuSubstate());},
            ()->{#if(debug&&(windows||hl)) Main.LOG('gallery');#end},
            ()->{#if(debug&&(windows||hl)) Main.LOG('achivements');#end},
            #if(windows||hl)()->{Sys.exit(1);}#end
        ];
        Music.playMusic("CellCompilation", true, "", true, "loop");

        for(i in 0...#if(windows||hl)6#else 5#end) {
            var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), "", onButtonClicked[i]);
            button.text = [
                Language.getTranslatedKey("menu.new_game", button),
                Language.getTranslatedKey("menu.load_game", button),
                Language.getTranslatedKey("menu.config", button),
                Language.getTranslatedKey("menu.art", button),
                Language.getTranslatedKey("menu.awards", button),
                #if(windows||hl)Language.getTranslatedKey("menu.quit", button)#end
            ][i];
            buttons.push(button);
            add(button);
        }

        //TODO: cool bg art


        #if (debug)
            var debuggerButton:FlxButton = new FlxButton(FlxG.width-(logo.width+80), 200, "", ()->{
                openSubState(new DebuggerChooser());
            });
            debuggerButton.text = Language.getTranslatedKey("menu.debug.debugger", debuggerButton);
            add(debuggerButton);
        #end
    }
}


#if (debug)
class DebuggerChooser extends FlxSubState {
    final debuggerOptions:Map<String, Void->Void>=[
        Language.getTranslatedKey("debugger.map", null) => ()->{
            FlxG.switchState(MapDebugger.new);
        },
        Language.getTranslatedKey("debugger.testing", null)=>()->{
            FlxG.switchState(()->new TestingState(false));
        },
        Language.getTranslatedKey("debugger.save", null)=>()->{
            FlxG.switchState(SaveDebugger.new);
        },
        Language.getTranslatedKey("debugger.alphabet", null)=>()->{
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