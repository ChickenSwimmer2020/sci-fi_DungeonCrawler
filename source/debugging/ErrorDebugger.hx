package debugging;

#if(debug)
class ErrorDebugger extends FlxState {
    public function new() {
        super();
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey("debugger.genericexit", null, ["[EXITKEY]"=>"BACKSPACE"]), 24, true);
        add(text);

        var missingObjectInput:FlxInputText=new FlxInputText(0, 0, 80, "debug", 8);
        add(missingObjectInput);
        var buttons:Array<FlxButton>=[];

        for(i in 0...Lambda.count(Main.ErrorType)) {
            var button:FlxButton = new FlxButton(0, (FlxG.height/2-20/2-(20*Lambda.count(Main.ErrorType)))+(20*i), [
                Language.getTranslatedKey("debugger.error.labels.test", null),
                Language.getTranslatedKey("debugger.error.labels.io", null),
                Language.getTranslatedKey("debugger.error.labels.render", null),
                Language.getTranslatedKey("debugger.error.labels.cache", null),
                Language.getTranslatedKey("debugger.error.labels.lang", null),
                Language.getTranslatedKey("debugger.error.labels.item", null),
                Language.getTranslatedKey("debugger.error.labels.map", null)
            ][i], [
                ()->{Main.showError("TEST", missingObjectInput.text);},
                ()->{Main.showError("IOERROR", missingObjectInput.text);},
                ()->{Main.showError("RENDERFAILURE", missingObjectInput.text);},
                ()->{Main.showError("SAVENOTCACHED", missingObjectInput.text);},
                ()->{Main.showLanguageError(missingObjectInput.text);},
                ()->{Main.showError("NULLITEM", missingObjectInput.text);},
                ()->{Main.showError("MAPNULL", missingObjectInput.text);}
            ][i]);
            buttons.push(button);
            add(button);

            button.x = FlxG.width/2-button.width/2;
        }
        missingObjectInput.setPosition(FlxG.width/2-missingObjectInput.width/2, buttons[buttons.length-1].y+20);
    }

    override public function update(elapsed:Float){
        super.update(elapsed);

        if(FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(()->new MainMenuState(true));
    }
}
#end