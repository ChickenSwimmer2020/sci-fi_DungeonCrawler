package backend.game;

import flixel.input.touch.FlxTouch;

class Player extends FlxSprite {
    public static var instance:Player;
    public static var health:Float = 100;
    public static var stamina:Float = 100;
    public static var xp:Float = 0;

    public static var curHotbarSlot:Int=0;
    public var inventory:HUDSubstate; //for easy access without a bunch of extra stuff.
    public var weapon:Weapon;
    public static var INVENTORY_SLOTS:Int = 50; //default to ten for like, idk (CAN BE CHANGED BY SAVE FILE)


    public static var playerPauseRequested:Bool = false; //for easier pausing since i cant just do like FlxG.pause.
    public static var onPlayerPause:Void->Void = null; //JUST in-case i ever need it.

    private static final MAX_ZOOM:Float=10;
    private static final MIN_ZOOM:Float=1;
    private static final WEAPON_OFFSET:Map<String, FlxPoint> = [
        "DEBUG"=>FlxPoint.weak(0, 0)
    ];
    var targetWeaponPosition:FlxPoint;
    var mousePosition:FlxPoint=new FlxPoint(0, 0); //funny thing, we can actually re-use this for android!
    public function new() {
        super(0, 0);
        targetWeaponPosition=new FlxPoint(x, y);
        makeGraphic(4, 4, 0xFFFF0000);
        instance=this;
    }
    //#if (debug)
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
    //#end
    var isWeapon:Bool=false;
    //TODO: implement support for using the scroll wheel to change items in the hotbar
    override public function update(elapsed:Float) {
        super.update(elapsed);
        mousePosition = #if android
            FlxG.touches.getFirst()?.getWorldPosition(Main.camGame);
        #else
            FlxG.mouse.getWorldPosition(Main.camGame);
        #end
        //lerp velocity to mimic friction (THE MIMICCCCCCCCCCC)
        if(velocity.x > 0 || velocity.x < 0)velocity.x = FlxMath.lerp(0, velocity.x, Math.exp(-elapsed * 3.126 * 4 * 1));
        if(velocity.y > 0 || velocity.y < 0)velocity.y = FlxMath.lerp(0, velocity.y, Math.exp(-elapsed * 3.126 * 4 * 1));
        #if (debug&&!android) //these are useless on the android build (debugger and FlxKey doesnt exist on the android build).
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
            weapon=new Weapon(0, 0, WeaponParser.parse('DEBUG'));
            weapon.camera=camera; //move the weapn to the player camera;
            FlxG.state.add(weapon);
            weapon.setActions(
                ()->{weapon.playAnimation('a', true); weapon.shoot();},
                ()->{weapon.playAnimation('b', true);}
            );
            weapon.visible=weapon.active=false;
        }else{
            isWeapon=((inventory.selectedItem.type==RANGED||inventory.selectedItem.type==MEELEE)||inventory.selectedItem.type==MAGIC);
            weapon.active=weapon.visible=isWeapon;
            if(((weapon.frMode==RAIL||weapon.frMode==FULLAUTO)?#if(android)FlxG.touches.getFirst()?.pressed#else FlxG.mouse.pressed#end:#if(android)FlxG.touches.justStarted()[0]?.justPressed #else FlxG.mouse.justPressed#end) && (weapon.visible && weapon.active)) weapon.onLeftClick();
            if(#if(android) false #else FlxG.mouse.justPressedRight#end && (weapon.visible && weapon.active)) weapon.onRightClick(); //TODO: android support for advanced weapon functions. other buttons maybe that freeze the game until you select a position to fire twoards?
            if((#if(android) false #else FlxG.mouse.justPressedMiddle#end && weapon.onMiddleClick!=null) && (weapon.visible && weapon.active)) weapon.onMiddleClick();

            if(weapon.visible && weapon.active){
                targetWeaponPosition.set(x+WEAPON_OFFSET.get(weapon.name)?.x,y+WEAPON_OFFSET.get(weapon.name)?.y);
                weapon.x=FlxMath.lerp(targetWeaponPosition.x, weapon.x, Math.exp(-elapsed*3.125*4*1)); //this should make it that the weapon can collide with the blocks too, HOPEFULLY to prevent hsooting through blocks.
                weapon.y=FlxMath.lerp(targetWeaponPosition.y, weapon.y, Math.exp(-elapsed*3.125*4*1));
                weapon.angle = Math.atan2(mousePosition.y-weapon.y, mousePosition.x-weapon.x) * 180 / Math.PI;
            }
        }
        Main.camGame.follow(this, FlxCameraFollowStyle.LOCKON, 0.25);


        curHotbarSlot.clamp(0, 9); //actually 1-10;
        for (i in 0...[ONE,TWO,THREE,FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,ZERO].length)
            if(FlxG.keys.anyJustPressed([[ONE,TWO,THREE,FOUR,FIVE,SIX,SEVEN,EIGHT,NINE,ZERO][i]])){
                curHotbarSlot=i;
                @:privateAccess
                    if(inventory.slots[curHotbarSlot]?.curItem?.type==RANGED || (inventory.slots[curHotbarSlot]?.curItem?.type==MEELEE || inventory.slots[curHotbarSlot]?.curItem?.type==MAGIC))
                        WeaponParser.recycleWeapon(weapon, inventory.slots[curHotbarSlot].curItem?.item);
                break;
            }else continue;

        //HORRIBLE way to do it, but good enough.
        if(inventory.weaponText.text!='${Language.getTranslatedKey('weapon.${inventory.selectedItem?.item}')}\n${inventory.selectedItem?.charges}/{M}|${inventory.selectedItem?.durability}'){
            inventory.weaponText.text='${Language.getTranslatedKey('weapon.${inventory.selectedItem?.item}')}\n${inventory.selectedItem?.charges}/{M}|${inventory.selectedItem?.durability}';
        }

        //TODO: make these better
        #if !android
            if(FlxG.keys.anyPressed(Main.controls.get('moveUP'))) y-=1;
            if(FlxG.keys.anyPressed(Main.controls.get('moveDOWN'))) y+=1;
            if(FlxG.keys.anyPressed(Main.controls.get('moveRIGHT'))) x+=1;
            if(FlxG.keys.anyPressed(Main.controls.get('moveLEFT'))) x-=1;

            Main.camGame.zoom.clamp(MIN_ZOOM, MAX_ZOOM);
            if(FlxG.keys.anyPressed(Main.controls.get('zoomOUT'))){
                if(Main.camGame.zoom>MIN_ZOOM)Main.camGame.zoom-=0.25;
            }
            if(FlxG.keys.anyPressed(Main.controls.get('zoomIN'))){
                if(Main.camGame.zoom<MAX_ZOOM)Main.camGame.zoom+=0.25;
            }

            //MOVED PAUSING LOGIC TO INVENTORY
            if(Functions.checkJustPressedSafe(Main.controls.get('inventory'))) { //stupid that i need safe check functions. :/
                inventory.fullOpen=!inventory.fullOpen;
            }
        #else
            //TODO: controls substate (part of inventory substate because it has to be) actually controlling player.
        #end
    }
}