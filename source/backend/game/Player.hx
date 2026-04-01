package backend.game;

class Player extends FlxSprite {
    public static var instance:Player;
    public static var health:Float = 100;
    public static var stamina:Float = 100;
    public static var xp:Float = 0;

    public var curHotbarSlot(default, set):Int=0;
    public function set_curHotbarSlot(value:Int):Int {
        curHotbarSlot=value;
        @:privateAccess if(inventory.slots[curHotbarSlot]?.curItem?.type==RANGED || (inventory.slots[curHotbarSlot]?.curItem?.type==MEELEE || inventory.slots[curHotbarSlot]?.curItem?.type==MAGIC)){
            if(weapon.name != inventory.slots[curHotbarSlot].curItem?.item) WeaponParser.recycleWeapon(weapon, inventory.slots[curHotbarSlot].curItem?.item); //only do it once IF we need to.
        }
        return curHotbarSlot;
    }
    public var inventory:HUDSubstate; //for easy access without a bunch of extra stuff.
    public var weapon:Weapon;
    public static var INVENTORY_SLOTS:Int = 50; //default to ten for like, idk (CAN BE CHANGED BY SAVE FILE)


    public static var playerPauseRequested:Bool = false; //for easier pausing since i cant just do like FlxG.pause.
    public static var onPlayerPause:Void->Void = null; //JUST in-case i ever need it.
    public static var MOVE_SPEED:Float=50; // or whatever your speed is
    public static var MAX_MOVE_SPEED:Float=50; //for some reason always has 50 added while moving??

    private static final MAX_ZOOM:Float=10;
    private static final MIN_ZOOM:Float=1;
    private static final WEAPON_OFFSET:Map<String, FlxPoint> = [
        "DEBUG"=>FlxPoint.weak(0, 0)
    ];
    var targetWeaponPosition:FlxPoint;
    var mousePosition:FlxPoint=new FlxPoint(0, 0);

    private var ctrlUp:Array<FlxKey>;    
    private var ctrlDown:Array<FlxKey>;  
    private var ctrlLeft:Array<FlxKey>;  
    private var ctrlRight:Array<FlxKey>; 
    private var ctrlZoomIn:Array<FlxKey>;  
    private var ctrlZoomOut:Array<FlxKey>; 
    private var ctrlInv:Array<FlxKey>;   
    public function new() {
        super(0, 0);
        targetWeaponPosition=new FlxPoint(x, y);
        makeGraphic(4, 4, 0xFFFF0000);
        instance=this;

        ctrlUp = Main.controls.get('moveUP');
        ctrlDown = Main.controls.get('moveDOWN');
        ctrlLeft = Main.controls.get('moveLEFT');
        ctrlRight = Main.controls.get('moveRIGHT');
        ctrlZoomIn = Main.controls.get('zoomIN');
        ctrlZoomOut = Main.controls.get('zoomOUT');
        ctrlInv = Main.controls.get('inventory');
    }
    #if (debug)
        function addWatchObjects() {
            FlxG.watch.addQuick("camera zoom: ", Main.camGame?.zoom); //i forgot i can do this!
            FlxG.watch.addQuick("inventory open: ", inventory?.fullOpen);
            FlxG.watch.addQuick("inventory selected hotbar item: ", inventory?.selectedItem);
            FlxG.watch.addQuick("inventory hotbar slot ", curHotbarSlot);

            FlxG.watch.addQuick("velocity", velocity);
            FlxG.watch.addQuick("health", health??0);
            FlxG.watch.addQuick("stamina", stamina??0);
            FlxG.watch.addQuick("xp", xp??0);
        }
    #end
    public var weaponKickback:FlxPoint=FlxPoint.weak(0, 0);
    var isWeapon:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        mousePosition=FlxG.mouse.getWorldPosition(Main.camGame);
        //lerp velocity to mimic friction (THE MIMICCCCCCCCCCC)
        if(weaponKickback.x > 0 || weaponKickback.x < 0) weaponKickback.x=FlxMath.lerp(0, weaponKickback.x, Math.exp(-elapsed * 3.126 * 4 * 1));
        if(weaponKickback.y > 0 || weaponKickback.y < 0) weaponKickback.y=FlxMath.lerp(0, weaponKickback.y, Math.exp(-elapsed * 3.126 * 4 * 1));
        if(axis(ctrlRight, ctrlLeft)==0 && (velocity.x > 0 || velocity.x < 0)) velocity.x = FlxMath.lerp(0, velocity.x, Math.exp(-elapsed * 3.126 * 2 * 1));
        if(axis(ctrlDown, ctrlUp)== 0 && (velocity.y > 0 || velocity.y < 0)) velocity.y = FlxMath.lerp(0, velocity.y, Math.exp(-elapsed * 3.126 * 2 * 1));
        #if (debug)
            addWatchObjects();
            if(FlxG.keys.pressed.LBRACKET) health--;
            if(FlxG.keys.pressed.RBRACKET) health++;

            if(FlxG.keys.pressed.SEMICOLON) stamina--;
            if(FlxG.keys.pressed.QUOTE) stamina++;

            if(FlxG.keys.pressed.COMMA) xp--;
            if(FlxG.keys.pressed.PERIOD) xp++;
        #end
        if(inventory==null) {
            inventory=new HUDSubstate();
            FlxG.state.persistentUpdate=true;
            FlxG.state.openSubState(inventory); //open the inventory. (which is also technically the hotbar)
        }
        if(weapon==null) {
            weapon=new Weapon(0, 0, null); //we dont want to parse a weapon yet, idk if this will crash.
            weapon.camera=camera; //move the weapn to the player camera;
            FlxG.state.add(weapon);
            weapon.setActions(
                ()->{weapon.shoot();},
                ()->{}
            );
            weapon.visible=weapon.active=false;
        }else{
            isWeapon=((inventory.selectedItem.type==RANGED||inventory.selectedItem.type==MEELEE)||inventory.selectedItem.type==MAGIC);
            weapon.active=weapon.visible=isWeapon;
            if(((weapon.frMode==RAIL||weapon.frMode==FULLAUTO)?FlxG.mouse.pressed:FlxG.mouse.justPressed) && (weapon.visible && weapon.active)) weapon.onLeftClick();
            if(FlxG.mouse.justPressedRight && (weapon.visible && weapon.active)) weapon.onRightClick();
            if((FlxG.mouse.justPressedMiddle && weapon.onMiddleClick!=null) && (weapon.visible && weapon.active)) weapon.onMiddleClick();

            if(weapon.visible && weapon.active){
                targetWeaponPosition.set(x+WEAPON_OFFSET.get(weapon.name)?.x,y+WEAPON_OFFSET.get(weapon.name)?.y);
                weapon.x=FlxMath.lerp(targetWeaponPosition.x, weapon.x, Math.exp(-elapsed*3.125*4*1)); //this should make it that the weapon can collide with the blocks too, HOPEFULLY to prevent hsooting through blocks.
                weapon.y=FlxMath.lerp(targetWeaponPosition.y, weapon.y, Math.exp(-elapsed*3.125*4*1));
                weapon.angle = Math.atan2(mousePosition.y-weapon.y, mousePosition.x-weapon.x) * 180 / Math.PI;
            }
        }
        Main.camGame.follow(this, FlxCameraFollowStyle.LOCKON, 0.25);


        
        curHotbarSlot+=Math.floor(FlxG.mouse.wheel#if(html5).clamp(-1, 1)#end); //so windows doesnt require normailzation, but html5 does. wtf.
        curHotbarSlot = FlxMath.wrap(curHotbarSlot, 0, 9);
        curHotbarSlot=curHotbarSlot.clamp(0, 9); //actually 1-10;
        for (i in 0...[ONE,TWO,THREE,FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,ZERO].length)
            if(FlxG.keys.anyJustPressed([[ONE,TWO,THREE,FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,ZERO][i]])){
                curHotbarSlot=i;
                break;
            }else continue;

        //HORRIBLE way to do it, but good enough.
        if(inventory.weaponText.text!='${Language.getTranslatedKey('${inventory.selectedItem?.weaponType==NULL?"":"weapon."}${inventory.selectedItem?.item}', null)}\n${inventory.selectedItem?.charges}/{M}|${inventory.selectedItem?.durability}'){
            inventory.weaponText.text='${Language.getTranslatedKey('${inventory.selectedItem?.weaponType==NULL?"":"weapon."}${inventory.selectedItem?.item}', null)}\n${inventory.selectedItem?.charges}/{M}|${inventory.selectedItem?.durability}';
        }

        
        velocity.x = ((velocity.x = velocity.x.clampf(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)) += (weaponKickback.x+(axis(ctrlRight, ctrlLeft) * MOVE_SPEED))); //add kickback on-top of the normal velocity based movement
        velocity.y = ((velocity.y = velocity.y.clampf(-MAX_MOVE_SPEED, MAX_MOVE_SPEED)) += (weaponKickback.y+(axis(ctrlDown, ctrlUp) * MOVE_SPEED))); //make sure to clamp these to the maximum move speed or else it just speeds up infinitely
        Main.camGame.zoom = (Main.camGame.zoom + axis(ctrlZoomIn, ctrlZoomOut) * 0.25).clampf(MIN_ZOOM, MAX_ZOOM);

        if (Functions.checkJustPressedSafe(ctrlInv)) inventory.fullOpen = !inventory.fullOpen;
    }
    inline function axis(pos:Array<FlxKey>, neg:Array<FlxKey>):Float return (FlxG.keys.anyPressed(pos) ? 1 : 0) - (FlxG.keys.anyPressed(neg) ? 1 : 0);
}