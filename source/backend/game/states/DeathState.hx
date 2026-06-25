package backend.game.states;

import flixel.util.FlxGradient;

class DeathState extends FlxState {
    private static var OFFSET:Float = 6.8;
    var labBG:FlxSprite;
    var consoleGroup:FlxSpriteGroup;
    var consoleWindow:FlxSprite;
    var text:ExtendedText;
    var cursor:FlxSprite;

    var RFEG:Bool=false; //Relocation_Failed Easter Egg (somewhat replaces the death screen with that of Relocation_Failed)
    var RFGradient:FlxSprite;
    var RFCLText:ExtendedText;
    var RFCLText2:ExtendedText;

    var RFEGbeatHit:(Int)->Void;
    public function new() {
        super();
        RFEG=FlxG.random.bool(2);
        if(RFEG) Main.Trace(EG, 'GOT RELOCATION FAILED EASTEREGG!!');
        

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFF00FF));

        labBG = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/death', 'lab'));
        labBG.setGraphicSize(FlxG.width, FlxG.height);
        add(labBG);

        consoleGroup = new FlxSpriteGroup(0, 0);
        add(consoleGroup);
        consoleWindow=new FlxSprite(0, 0).loadGraphic(Paths.image('ui/death', 'screen'));
        consoleGroup.add(consoleWindow); 

        text = new ExtendedText(64, 48, 640, "", 12, true);
        consoleGroup.add(text);
        
        consoleGroup.screenCenter();
        consoleGroup.scale.set(1.5, 1.5);

        Music.stopLoops(true);
        Music.stopMusic();
        Music.makeSureThatSoundsArentLooping();
        FlxTween.tween(consoleGroup.scale, {x:1,y:1}, 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET,onStart:(_)->{
            if(!RFEG) Music.playLoopingMusic('lithiumdegredation'); //!!(OCCASIONAL BUG) MUSIC SOMETIMES DOESNT LOOP
        }, onComplete:(_)->{
            if(RFEG) {
                Music.playLoopingMusic('miscalculation');
                RFGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0xFFFF0000], 1, 90, true);
                add(RFGradient);
                Conductor.cameraBopStrength = 0.02;
                Conductor.cameraBopRate = 1;
                Conductor.bopCamera=true;
                Conductor.additionalBopOnSection=true;
                RFEGbeatHit = (c)->{
                    RFGradient.y=0;
                };
                Conductor.onBeatHit.push(RFEGbeatHit);
                RFCLText = new ExtendedText(0, 0, FlxG.width, 'RECONNECTING', 86, false);
		        RFCLText.setFormat('assets/fonts/terminus.ttf', 86, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.NONE, 0x00000000, true);
                RFCLText.screenCenter(Y);
                RFCLText.setFormat('assets/fonts/terminus.ttf', 86, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.NONE, 0x00000000, true);
                RFCLText.text = 'CONNECTION';
                add(RFCLText);
                RFCLText2 = new ExtendedText(0, 0, FlxG.width, '', 74, false);
                RFCLText2.setFormat('assets/fonts/terminus.ttf', 74, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.NONE, 0x00000000, true);
                RFCLText2.y = RFCLText.y + 58;
                RFCLText2.setFormat('assets/fonts/terminus.ttf', 74, 0xFFFF0000, CENTER, FlxTextBorderStyle.NONE, 0x00000000, true);
                RFCLText2.text = 'FAILED';
                add(RFCLText2);
            }
        }});
        for(i in 0...2) {
            var fakeAspectRatioChange:FlxSprite = new FlxSprite([0, FlxG.width-160][i], 0).makeGraphic(160, FlxG.height, 0xFF000000);
            add(fakeAspectRatioChange);
            FlxTween.tween(fakeAspectRatioChange, [{x: 0-fakeAspectRatioChange.width}, {x: FlxG.width+fakeAspectRatioChange.width}][i], 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET, onComplete: (_)->fakeAspectRatioChange.destroy()});
        }
        GameState.degenerateCameras();
        Main.clearAllCameraFilters(); //clear all camera filters.
        Main.flashCameras(0xFFFFFFFF, 0.5); //flash ALL cameras.

        //text.scale.set(1.5, 1.5);
        //FlxTween.tween(text.scale, {x:1,y:1}, 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET});

        var textToWrite:String = Language.getTranslatedKey("game.death.consolemessage", null, ["[SAVEFILE]"=>Main.FILE]);
    
        Functions.wait(0.05, (_)->{
            if(textToWrite.charAt(_.elapsedLoops-1)!=" " && textToWrite.charAt(_.elapsedLoops-1)!="\n"){
                var snd:String=RFEG?'click${FlxG.random.int(0, 3)}':'consoleClick';
                Music.playSfx(snd, false, null); //relocation failed reference, now uses the relocation failed typing sounds if the easter egg is true.
            }
            text.text+=textToWrite.charAt(_.elapsedLoops-1);

            if(_.elapsedLoops == textToWrite.length-1) canExit=true;
        }, textToWrite.length);
    }
    var canExit:Bool=false;

    function redeploy() {
        if(RFEG) {

        }else{

        }
        Music.resetPitch();
    }

    function exit() {
        if(RFEG) {
            Conductor.cameraBopRate = 4;
            Conductor.bopCamera=false;
            Conductor.additionalBopOnSection=false;
            Conductor.onBeatHit.remove(RFEGbeatHit); ////TODO: rf's cool fade out thingy.
            FlxG.switchState(MainMenuState.new);
        }else FlxG.switchState(MainMenuState.new);
        Conductor.reset();
        GameState.reset();
        GameMap.reset();
        Player.resetVars();
        Music.resetPitch();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(canExit) {
            if(FlxG.keys.justPressed.Y) redeploy();
            if(FlxG.keys.justPressed.N) exit();
        }

        if(RFGradient!=null) {
            RFGradient.y = FlxMath.lerp(FlxG.height, RFGradient.y, Math.exp(-elapsed * 3.125 * 2 * 1));
        }
        //text.setPosition(consoleWindow.x+64, consoleWindow.y+48);
    }
}