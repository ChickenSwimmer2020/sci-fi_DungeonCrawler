package backend.game.states.substates;

class PauseMenu extends FlxSubState {
    var pauseCamera:FlxCamera;
    var menuBG:FlxSprite;
    var buttons:Array<FlxButton> = [];
    public function new() {
        super();
        FlxG.state.persistentUpdate = false;
        pauseCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height, 1);
        pauseCamera.bgColor = 0x00000000;
        FlxG.cameras.add(pauseCamera, false);

        menuBG = new FlxSprite(FlxG.width-100, FlxG.height).makeGraphic(100, 200, 0x00FF0000);
        add(menuBG);
        menuBG.drawPolygon([
            FlxPoint.get(0, 0),
            FlxPoint.get(100, 50),
            FlxPoint.get(100, 200),
            FlxPoint.get(0, 200),
            FlxPoint.get(0, 0)
        ], 0xFFFF0000);
        menuBG.flipX = true;
        FlxTween.tween(menuBG, {y: FlxG.height-200}, 0.25, {ease:FlxEase.expoInOut});


        for(i in 0...(#if(debug)Main.loadedTestedState?6:5#else 5#end)) {
            var button:FlxButton = new FlxButton(FlxG.width-85, FlxG.height, [
                Language.getTranslatedKey("pause.resume"),
                "",
                "",
                "",
                "",
                Language.getTranslatedKey("pause.debug.exittestingstate")
            ][i], [
                ()->{
                    FlxTween.tween(menuBG, {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut, onComplete: (_)->{
                        close();
                    }});
                    for(i in 0...buttons.length) {
                        FlxTween.tween(buttons[i], {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut});
                    }
                },
                ()->{},
                ()->{},
                ()->{},
                ()->{},
                ()->{
                    FlxG.switchState(MainMenuState.new);
                }
            ][i]);
            button.camera = pauseCamera;
            add(button);
            FlxTween.tween(button, {y: FlxG.height-135+(20*i)}, 0.25, {ease:FlxEase.expoInOut});
            buttons.push(button);
        }
        
        for(object in [menuBG]) {
            object.scrollFactor.set();
            object.camera = pauseCamera;
        }
    }

    override public function destroy() {
        FlxG.cameras.remove(pauseCamera);
        super.destroy();
        FlxG.state.persistentUpdate = true;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
            if(FlxG.keys.anyJustPressed([ESCAPE, BACKSPACE])){
                        FlxTween.tween(menuBG, {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut, onComplete: (_)->{
                close();
            }});
            for(i in 0...buttons.length) {
                FlxTween.tween(buttons[i], {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut});
            }
        }
    }
}