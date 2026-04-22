package backend.game.states;

class DeathState extends FlxState {
    private static final OFFSET:Int = 5;
    //var labBG:FlxSprite; //for future use.

    var consoleWindow:FlxSprite;
    var text:FlxText;
    var cursor:FlxSprite;
    public function new() {
        super();
        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFF00FF));

        //TODO: lab BG here
        //TODO: bubble particles here

        consoleWindow=new FlxSprite(0, 0).loadGraphic(Paths.image('ui/death', 'screen'));
        add(consoleWindow);
        consoleWindow.screenCenter();
        consoleWindow.scale.set(1.5, 1.5);

        FlxTween.tween(consoleWindow.scale, {x:1,y:1}, 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET});
        for(i in 0...2) {
            var fakeAspectRatioChange:FlxSprite = new FlxSprite([0, FlxG.width-160][i], 0).makeGraphic(160, FlxG.height, 0xFF000000);
            add(fakeAspectRatioChange);
            FlxTween.tween(fakeAspectRatioChange, [{x: 0-fakeAspectRatioChange.width}, {x: FlxG.width+fakeAspectRatioChange.width}][i], 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET, onComplete: (_)->fakeAspectRatioChange.destroy()});
        }

        text = new FlxText(0, 0, 640, "", 12, true);
        add(text);
        text.scale.set(1.5, 1.5);
        FlxTween.tween(text.scale, {x:1,y:1}, 1.25, {ease: FlxEase.expoInOut, startDelay: OFFSET});

        var textToWrite:String = Language.getTranslatedKey("game.death.consolemessage", null, ["[SAVEFILE]"=>Main.FILE]);
    
        Functions.wait(0.05, (_)->{ //TODO: improve the way this renders
            if(textToWrite.charAt(_.elapsedLoops-1)!=" " && textToWrite.charAt(_.elapsedLoops-1)!="\n")
                FlxG.sound.play('${Paths.paths.get('sfx')}/consoleClick.${#if(html5)'mp3'#else'ogg'#end}');
            text.text+=textToWrite.charAt(_.elapsedLoops-1);
        }, textToWrite.length);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        text.setPosition(consoleWindow.x+64, consoleWindow.y+48); //TODO: make test move properly because it fucking doesnt.
    }
}