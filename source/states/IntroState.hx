package states;

class IntroState extends FlxState {
    var onBeat:(Int)->Void;
    var cinematicGoesHereText:ExtendedText;
    public function new() {
        super();
        onBeat = (c)->bth(c);
        cinematicGoesHereText = new ExtendedText(0, 0, 0, 'CINEMATICS\nYEAHHHHHHH', 24, true);
        add(cinematicGoesHereText);
        cinematicGoesHereText.visible=false;
        cinematicGoesHereText.screenCenter();
        cinematicGoesHereText.alignment=CENTER;
        Music.playMusic("CellCompilation", true, "", true, "loop", null);

        Conductor.onBeatHit.push(onBeat); //beat based over everything else.
    }

    //these cinematics are supposed to be cutscenes, so we really gotta get the cutscene editor working n shiz.
    function bth(cur:Int) {
        Main.Trace(INFO, 'Beat: $cur');
        switch(cur) {
            case 0: cinematicGoesHereText.visible=true;
            case 8:
                cinematicGoesHereText.visible=false;
                var madePossibleByHeader:ExtendedText = new ExtendedText(0, 0, Language.getTranslatedKey('game.intro.credits.header', null), 12, true);
                add(madePossibleByHeader);
                madePossibleByHeader.screenCenter(X);
                //TODO: show credits.

                FlxTween.tween(madePossibleByHeader, {alpha: 0}, (Conductor.stepCrochet/1000*4), {startDelay: ((Conductor.stepCrochet/1000*4)*4), ease: FlxEase.expoOut, onComplete:(_)->{
                    madePossibleByHeader.destroy();
                }});
            case 16: cinematicGoesHereText.visible=true;
            case 24: cinematicGoesHereText.visible=false;
            case 32: cinematicGoesHereText.visible=true;
            case 40: cinematicGoesHereText.visible=false;
            case 48: cinematicGoesHereText.visible=true;
            case 56:
                cinematicGoesHereText.visible=false;
                var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/menu', 'logo'));
                logo.scale.set(0.5, 0.5);
                logo.screenCenter();
                add(logo);
                FlxTween.tween(logo, {"scale.x": 0.75, "scale.y": 0.75, alpha:1}, (Conductor.stepCrochet/1000*(4*8)), {ease: FlxEase.expoOut, onComplete:(_)->{
                    logo.destroy();
                }});
            case 64:
                Conductor.onBeatHit.remove(onBeat); //should work better?
                Main.Trace(DEBUG, Conductor.onBeatHit); //just to make sure its actually clearing properly.
                FlxG.switchState(()->new MainMenuState(false));
            default: //donothing
        }
        if(cur>=64) { //just as a precaution
            Conductor.onBeatHit.remove(onBeat); //should work better?
            FlxG.switchState(()->new MainMenuState(false));
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        //if any key is pressed, or any mouse buttons are pressed.
        if(FlxG.keys.anyJustPressed([ANY]) || (FlxG.mouse.justPressed || (FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle))) {
            Music.playMusic("CellCompilation", false, "loop", true, "loop");
            Conductor.onBeatHit.remove(onBeat); //forgot to do this when exiting.
            FlxG.switchState(()->new MainMenuState(false));
        }
    }
}