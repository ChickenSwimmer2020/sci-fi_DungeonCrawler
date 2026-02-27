package backend.game.states.substates;

import states.MainMenuState;
import flixel.util.FlxTimer;
import flixel.system.replay.CodeValuePair;
import flixel.ui.FlxButton;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSubState;
using flixel.util.FlxSpriteUtil;

class PauseMenu extends FlxSubState {
    var pauseCamera:FlxCamera;
    var menuBG:FlxSprite;
    var buttons:Array<FlxButton> = [];
    public function new() {
        super();
        FlxG.state.persistentUpdate = false;
        pauseCamera = new FlxCamera(0, 0, 1280, 720, 1);
        pauseCamera.bgColor = 0x00000000;
        FlxG.cameras.add(pauseCamera, false);

        menuBG = new FlxSprite(1185, 720).makeGraphic(100, 200, 0x00FF0000);
        add(menuBG);
        menuBG.drawPolygon([
            FlxPoint.get(0, 0),
            FlxPoint.get(100, 50),
            FlxPoint.get(100, 200),
            FlxPoint.get(0, 200),
            FlxPoint.get(0, 0)
        ], 0xFFFF0000);
        menuBG.flipX = true;
        FlxTween.tween(menuBG, {y: 520}, 0.25, {ease:FlxEase.expoInOut});


        //TODO: buttons
        for(i in 0...(Main.loadedTestedState?6:5)) {
            var button:FlxButton = new FlxButton(1195, 720, [
                Language.getTranslatedKey(Main.curLanguage, "pause.resume"),
                "",
                "",
                "",
                "",
                Language.getTranslatedKey(Main.curLanguage, "pause.debug.exittestingstate")
            ][i], [
                ()->{
                    FlxTween.tween(menuBG, {y: 720}, 0.75, {ease:FlxEase.expoOut, onComplete: (_)->{
                        close();
                    }});
                    for(i in 0...buttons.length) {
                        FlxTween.tween(buttons[i], {y: 720}, 0.75, {ease:FlxEase.expoOut});
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
            FlxTween.tween(button, {y: 585+(20*i)}, 0.25, {ease:FlxEase.expoInOut});
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
                        FlxTween.tween(menuBG, {y: 720}, 0.75, {ease:FlxEase.expoOut, onComplete: (_)->{
                close();
            }});
            for(i in 0...buttons.length) {
                FlxTween.tween(buttons[i], {y: 720}, 0.75, {ease:FlxEase.expoOut});
            }
        }
    }
}