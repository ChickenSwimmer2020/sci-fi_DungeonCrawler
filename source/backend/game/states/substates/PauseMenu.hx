package backend.game.states.substates;

import backend.extensions.ExtendedCamera;

class PauseMenu extends FlxSubState {
    var pauseCamera:ExtendedCamera;
    var menuBG:FlxSprite;
    var buttons:Array<FlxButton> = [];

    var playerVelocity:FlxPoint;
    public function new() {
        super();
        //"pause" the player.

        if(Player.instance!=null){
            Player.instance.canFireWeapon=Player.instance.canMove=Player.instance.canOpenInventory=Player.instance.canZoom=false;
            if(Player.instance.velocity != FlxPoint.weak(0, 0)) {
                playerVelocity = FlxPoint.weak(Player.instance.velocity.x, Player.instance.velocity.y);
            }else playerVelocity = FlxPoint.weak(0, 0);
            Player.instance.velocity.set(); //stop the player velocity
        }
        
        Music.doPauseFade();
        pauseCamera = new ExtendedCamera(0, 0, FlxG.width, FlxG.height, 1);
        pauseCamera.bgColor = 0x00000000;
        Main.addCameraToGame(pauseCamera, "pauseCamera");
        

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


        for(i in 0...(#if(debug)Main.loadedTestedState?5:4#else 4#end)) {
            var button:FlxButton = new FlxButton(FlxG.width-85, FlxG.height, [
                Language.getTranslatedKey("pause.resume", buttons[i]),
                Language.getTranslatedKey("pause.settings", buttons[i]),
                "",
                Language.getTranslatedKey("pause.exit", buttons[i]),
                Language.getTranslatedKey("pause.debug.exittestingstate", buttons[i])
            ][i], [
                ()->exit(),
                ()->{
                    var options:FlxSubState = new OptionsMenuSubstate();
                    options.camera = Main.camHUD;
                    openSubState(options);
                },
                ()->{},
                ()->{
                    Main.Trace(INFO, 'Time since player last saved: ${Player.SLS}');
                    if(Player.SLS > Flags.SLS_WARNING_THRESHOLD) {
                        GameState.inGame=false;
                        FlxG.switchState(()->new MainMenuState(false));
                    }else{
                        var popup:Popup = new Popup(
                            Language.getTranslatedKey("pause.exitnosave.popup.title", null),
                            Language.getTranslatedKey("pause.exitnosave.popup.message", null),
                            [
                                {l: Language.getTranslatedKey("pause.exitnosave.popup.options.exitunsafe", null), f:()->{
                                    FlxG.switchState(()->new MainMenuState(false));
                                }, c:true},
                                {l: Language.getTranslatedKey("pause.exitnosave.popup.options.exit", null), f:()->{
                                    Player.instance.SAVED(); //save the player stuff hopefully.
                                    FlxG.switchState(()->new MainMenuState(false));
                                }, c:true},
                                {l: Language.getTranslatedKey("pause.exitnosave.popup.options.cancel", null), c:true}
                            ], false, "", false, FlxPoint.weak(0, 0)
                        );
                        openSubState(popup);
                    }
                },
                ()->{
                    GameState.inGame=false;
                    FlxG.switchState(()->new MainMenuState(false));
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
    private function exit() {
        Music.undoPauseFade();
        FlxTween.tween(menuBG, {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut, onComplete: (_)->{
            Player.instance.velocity.set(playerVelocity.x, playerVelocity.y);
            close();
        }});
        for(i in 0...buttons.length) {
            FlxTween.tween(buttons[i], {y: FlxG.height}, 0.75, {ease:FlxEase.expoOut});
        }
    }

    override public function destroy() {
        if(Player.instance!=null) Player.instance.canFireWeapon=Player.instance.canMove=Player.instance.canOpenInventory=Player.instance.canZoom=true;
        FlxG.cameras.remove(pauseCamera);
        super.destroy();
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(FlxG.keys.anyJustPressed([ESCAPE, BACKSPACE])) exit();
    }
}