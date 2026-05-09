package states;
#if(debug)import debugging.Debugger;#end

class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<FlxButton>=[];
    public function new() {
        super();

        var vText:FlxText = new FlxText(0, 0, 0, '${Flags.VERSION_PREFIX}${Application.current.meta.get('version')}', 12, true);
        add(vText);
        vText.setPosition(FlxG.width-vText.width, FlxG.height-vText.height);

        logo=new FlxSprite(FlxG.width-500, 0).loadGraphic(Paths.image('ui/menu', 'logo'));
        logo.setGraphicSize(500, 200);
        logo.updateHitbox();
        add(logo);


        var pod:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/menu', 'pod'));
        var char:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/menu', 'char'));
        char.center(pod, FlxPoint.weak(-85, 0));

        add(char);
        FlxTween.tween(char, {y: char.y+15}, 5.2314, {ease: FlxEase.circInOut, type: PINGPONG}); //TODO: bubbles.
        add(pod);

        
        final onButtonClicked:Array<Void->Void>=[
            ()->{
                Music.deathFadeOut(1); //so, funnily enough, we can use this lol.
                FlxG.camera.fade(0xFF000000, 1, false, ()->{
                    FlxG.switchState(GameIntroState.new);
                });
            },
            ()->{openSubState(new LoadGameSubstate());},
            ()->{openSubState(new OptionsMenuSubstate());},
            ()->{#if(debug) Main.Trace(DEBUG, 'gallery');#end},
            ()->{#if(debug) Main.Trace(DEBUG, 'achivements');#end},
            #if(windows||hl)()->{Sys.exit(1);}#end
        ];
        Music.stopLoops(true);
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


        #if (debug)
            var debuggerButton:FlxButton = new FlxButton(FlxG.width-(logo.width+80), 200, "", ()->{
                //openSubState(new DebuggerChooser());
                FlxG.switchState(Debugger.new);
            });
            debuggerButton.text = Language.getTranslatedKey("menu.debug.debugger", debuggerButton);
            add(debuggerButton);
        #end
    }
}