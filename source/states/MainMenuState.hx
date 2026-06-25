package states;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxGradient;
#if(debug)import debugging.Debugger;#end

class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<FlxButton>=[];
    public function new() {
        super();
        final POD_SPACING:Float = 20;
        var pods:FlxBackdrop = new FlxBackdrop(Paths.image('ui/menu', 'pod'), XY, 0.0, 0.0);
        add(pods);
        pods.velocity.x = -50;
        var chars:FlxBackdrop = new FlxBackdrop(Paths.image('ui/menu', 'char'), X, (377/2)+80, 50.0);
        add(chars);
        chars.velocity.x = -50;
        //for(i in 0...5){
        //    var pod:FlxSprite = new FlxSprite(0+(355*i), 0).loadGraphic(Paths.image('ui/menu', 'pod'));
        //    var char:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/menu', 'char'));
        //    char.center(pod, FlxPoint.weak(-85, 0));
//
        //    
            FlxTween.tween(chars, {y: chars.y+15}, 5.2314, {ease: FlxEase.circInOut, type: PINGPONG}); //TODO: bubbles.
        //    insert(0+i, char);
        //    insert(0+i, pod);
//
        //    FlxTween.tween(pod, {x: 0-pod.width}, 6+(1*i), {ease: FlxEase.linear, type: LOOPING, onComplete: (_)->{
        //        pod.x = FlxG.width-(pod.width*i);
        //    }});
        //}
        
        var grad:FlxSprite = FlxGradient.createGradientFlxSprite((FlxG.width/2).floor(), FlxG.height, [0x00000000, 0x98000000], 1, 0, true);
        add(grad);
        grad.x = FlxG.width/2-grad.width;
        add(new FlxSprite(FlxG.width/2, 0).makeGraphic((FlxG.width/2).floor(), FlxG.height, 0x98000000));



        var vText:ExtendedText = new ExtendedText(0, 0, 0, '${Flags.VERSION_PREFIX}${Application.current.meta.get('version')}', 12, true);
        add(vText);
        vText.setPosition(FlxG.width-vText.width, FlxG.height-vText.height);

        logo=new FlxSprite(FlxG.width-500, 0).loadGraphic(Paths.image('ui/menu', 'logo'));
        logo.setGraphicSize(500);
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
            ()->{#if(debug) Main.Trace(DEBUG, 'gallery');#end},
            ()->{#if(debug) Main.Trace(DEBUG, 'achivements');#end},
            ()->{Sys.exit(1);}
        ];
        Music.stopLoops(true);
        Music.playMusic("CellCompilation", true, "", true, "loop");

        for(i in 0...6) {
            var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), "", onButtonClicked[i]);
            button.text = [
                Language.getTranslatedKey("menu.newgame", button),
                Language.getTranslatedKey("menu.loadgame", button),
                Language.getTranslatedKey("menu.config", button),
                Language.getTranslatedKey("menu.art", button),
                Language.getTranslatedKey("menu.awards", button),
                Language.getTranslatedKey("menu.quit", button)
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