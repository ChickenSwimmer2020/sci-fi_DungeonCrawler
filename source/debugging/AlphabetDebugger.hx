package debugging;

#if (debug)
class AlphabetDebugger extends FlxUIState{
    var widthStepper:FlxUINumericStepper;
    var heightStepper:FlxUINumericStepper;
    var GenerateButton:FlxUIButton;
    public function new() {
        super();
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey("debugger.alphabet.exit"), 24, true);
        add(text);

        var alphabet:Alphabet=new Alphabet(0, 50, 0, "ABCDEFGHIJKLMNOPQRSTUVWXYZ \n abcdefghijklmnopqrstuvwxyz \n 0123456789 \n ~!@#$%^&*()_+{}|:\"<>? \n `-=[]\\;',./", 12);
        add(alphabet);
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        //READING_textInputOther.visible = READING_textInputOther.active = (tabs_radio_1.selectedId=="OTHER"||tabs_radio_1.selectedId=="INVENTORY");

        if(FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(MainMenuState.new);
            openSubState(new DebuggerChooser());
        }
    }
}
#end