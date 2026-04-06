package states;

class IntroState extends FlxState {
    public function new() {
        super();
        Functions.wait(20.75, (_)->FlxG.switchState(()->new MainMenuState()));
        Music.playMusic("CellCompilation", true, "", true, "loop", null);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        //if any key is pressed, or any mouse buttons are pressed.
        if(FlxG.keys.anyJustPressed([ANY]) || (FlxG.mouse.justPressed || (FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle))) {
            Music.playMusic("CellCompilation", false, "loop", true, "loop");
            FlxG.switchState(()->new MainMenuState());
        }
    }
}