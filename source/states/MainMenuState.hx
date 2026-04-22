package states;
class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<FlxButton>=[];
    public function new(#if(debug)fromChooser:Bool=false#end) {
        super();

        logo=new FlxSprite(FlxG.width-500, 0).loadGraphic(Paths.image('ui/menu', 'logo'));
        logo.setGraphicSize(500, 200);
        logo.updateHitbox();
        add(logo);
        
        final onButtonClicked:Array<Void->Void>=[
            ()->{
                Music.deathFadeOut(1); //so, funnily enough, we can use this lol.
                FlxG.camera.fade(0xFF000000, 1, false, ()->{
                    FlxG.switchState(GameIntroState.new);
                });
            },
            ()->{openSubState(new LoadGameSubstate());},
            ()->{openSubState(new OptionsMenuSubstate());},
            ()->{#if(debug&&(windows||hl)) Main.LOG('gallery');#end},
            ()->{#if(debug&&(windows||hl)) Main.LOG('achivements');#end},
            #if(windows||hl)()->{Sys.exit(1);}#end
        ];
        Music.stopLoops();
        Music.playMusic("CellCompilation", true, "", true, "loop");

        for(i in 0...#if(windows||hl)6#else 5#end) {
            var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), "", onButtonClicked[i]);
            button.text = [
                Language.getTranslatedKey("menu.newgame", button),
                Language.getTranslatedKey("menu.loadgame", button),
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
            if(fromChooser) openSubState(new DebuggerChooser());
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
        Language.getTranslatedKey("debugger.map.title", null) => ()->{
            FlxG.switchState(MapDebugger.new);
        },
        Language.getTranslatedKey("debugger.testing", null)=>()->{
            FlxG.switchState(()->new TestingState(false));
        },
        Language.getTranslatedKey("debugger.save.title", null)=>()->{
            FlxG.switchState(SaveDebugger.new);
        },
        Language.getTranslatedKey("debugger.alphabet.title", null)=>()->{
            FlxG.switchState(AlphabetDebugger.new);
        },
        Language.getTranslatedKey("debugger.error.title", null)=>()->{
            FlxG.switchState(ErrorDebugger.new);
        },
        Language.getTranslatedKey("debugger.cutscenemaker.title", null)=>()->{
            FlxG.switchState(CutSceneCreator.new);
        }
    ];
    public function new() {
        super();
        var bg = add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000));
        Reflect.setField(bg, "alpha", 0); //stupid that i have to do this but OKAY.
        FlxTween.tween(bg, {alpha: 0.25}, 0.54212, {ease: FlxEase.expoOut});

        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey('debugger.title', null), 48, true);
        add(text);
        text.screenCenter();
        text.y=0;

        var i:Int=0;
        for(label => func in debuggerOptions) {
            var button = add(new FlxButton((FlxG.width/2)-40, (FlxG.height/2-20/2-(20*Lambda.count(Main.ErrorType)))+(40*i), label, func));
            add(button);
            i++;
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ESCAPE) close();
    }
}
#end