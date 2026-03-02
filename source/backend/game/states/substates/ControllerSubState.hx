package backend.game.states.substates;
#if android
class ControlStick extends FlxTypedSpriteContainer<FlxSprite> {
    public var output:(x:Float,y:Float)->Void=null;
    public var BG:FlxSprite;
    public var stick:FlxSprite;
    public static final INTERACTION_DISTANCE:Float=0;
    public static final DEADZONE:Float=0;

    public static final MAX_RETURN:Float=0;
    public static final MIN_RETURN:Float=0;
    public function new() {
        super();

        //hehe, heres the fun part! the joystick only needs one graphic since im cool like that :sunglasses:
        BG = new FlxSprite(0, 0).loadGraphic(Paths.image("android", "joystick"));
        stick=new FlxSprite(0, 0).loadGraphic(Paths.image("android", "joystick"));

        stick.scale.set(0.54, 0.54);
        stick.updateHitbox();
        stick.setPosition(BG.x + BG.width/2 - stick.width/2,BG.y + BG.height/2 - stick.height/2);

        add(BG);
        add(stick);
    }

    var moveJoystick:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.touches.getFirst()!=null) {
            if(FlxG.touches.justStarted()[0].overlaps(stick)) {
                moveJoystick=true;
            }else if(FlxG.touches.justReleased()[0].overlaps(stick)) {
                moveJoystick=false;
            }
        }
    }
}
    
class ControllerSubState extends FlxSubState {
    public var output:(x:Float,y:Float)->Void;
    public function new() {
        super();

        var controlStick:ControlStick = new ControlStick();
        add(controlStick);

        output=controlStick.output;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        //TODO: button instead of FlxKeys.
        ////if(FlxG.keys.anyJustPressed(Main.controls.get('pause'))) { //swapped for anyJustPressed so it doesnt run multiple times in a frame
        ////    if(Player.onPlayerPause!=null)Player.onPlayerPause(); //so we can pause enemy and object ai/animations/tweens/everything
        ////    Player.playerPauseRequested = true;
        ////    openSubState(new PauseMenu()); //open the substate IN the substate. simple fix!
        ////}
    }
}
#end