package backend.game.states.substates;

enum abstract ItemType(String) from String to String {
    var ITEM="ITEM";
    var CONSUMABLE="CONSUMABLE";
    var MEELEE="MEELEE";
    var RANGED="RANGED";
    var MAGIC="MAGIC";
    var NULL="NULL";
}
enum abstract PotionType(String) from String to String {
    var HEALTH="HEALTH";
    
    public static function getPotionEffect(type:String) {
        switch(type) {
            case HEALTH: trace('used health potion');
            default: trace("test");
        }
    }
}
enum abstract ConsumableType(String) from String to String {
    var CRUMB="CRUMB";
    var SNACK="SNACK";
    var MEAL="MEAL";
    var SHOT="SHOT";
    var GLASS="GLASS";
    var BOTTLE="BOTTLE";
    var NULL="NULL";
}
enum abstract GunType(String) from String to String {
    var LASER="LASER";
    var EXPLOSIVE="EXPLOSIVE";
    var BALLISTIC="BALLISTIC";
    var PLASMA="PLASMA";
    var OTHER="OTHER";
    var NULL="NULL";
}
enum abstract GunFireMode(String) from String to String {
    var FULLAUTO="FULLAUTO";
    var SEMI="SEMI";
    var SHOTGUN="SHOTGUN";
    var BURST="BURST";
    var RAIL="RAIL";
    var NULL="NULL";
}
enum abstract MagicType(String) from String to String {
    var FIRE="FIRE";
    var WATER="WATER";
    var AIR="AIR";
    var DARK="DARK";
    var EARTH="EARTH";
    var ARCANE="ARCANE";
    var OTHER="OTHER";
    var NULL="NULL";
}
enum abstract WeaponType(String) from String to String{
    var GUN="GUN";
    var STAFF="STAFF";
    var WAND="WAND";
    var SWORD="SWORD";
    var DAGGER="DAGGER";
    var LONGSWORD="LONGSWORD";
    var NULL="NULL";
}
typedef Item = {
    var type:ItemType;
    @:optional var weaponType:WeaponType;
    @:optional var gunType:GunType;
    @:optional var MagicType:MagicType;
    var item:String;
    @:optional var isPotion:Bool;
    @:optional var potionType:PotionType;
    @:optional var durability:Float;
    @:optional var damage:Map<String, Float>; //so we can apply MANY damage types to anything.
    @:optional var consumable:Bool;
    @:optional var consumableType:ConsumableType;
    @:optional var charges:Float; //also affects guns
}

class InventorySlot extends FlxTypedSpriteGroup<FlxSprite> {
    public var onItemUsed:(String, Item)->Void; //action, item
    public var onItemMoveStart:Void->Void;
    public var onItemMoveEnd:Void->Void;
    public static final SIZE:Int = 64;
    public var hasItem:Bool=false;
    public var curItem:Null<Item>;
    public var locked:Bool=false;
    public var interactable:Bool=true;

    private var slot:FlxSprite;
    private var object:Null<FlxSprite>;

    public function new(x:Float,y:Float, ?item:Item) {
        super(x, y);
        slot=new FlxSprite(0, 0).loadGraphic(Paths.image('ui/inventory', 'slot'));
        slot.setGraphicSize(SIZE, SIZE);
        slot.updateHitbox();
        add(slot);

        scrollFactor.set();
        camera=Main.camHUD;
        RightClickOptions=[];
        RightClickFunctions=[];
        if(item!=null){
            if(item.consumable==true){
                if(((item.consumableType==SHOT||(item.consumableType==GLASS||item.consumableType==BOTTLE)||item.isPotion))){
                    RightClickOptions.push("Drink");
                    RightClickFunctions.push( //TODO: checks to see if player is in hardmode and decrease hunger otherwise increase health by a small ammount (hunger and thirst are a hard difficulty exclusive)
                        ()->{
                            #if(debug&&(windows||hl)) Main.LOG('player has drank something.'); #end
                            onItemUsed("drink", curItem);
                            unloadItem();
                        }
                    );
                }
                if((item.consumableType==CRUMB||(item.consumableType==SNACK||item.consumableType==MEAL))){
                    RightClickOptions.push("Eat");
                    RightClickFunctions.push( //TODO: checks to see if player is in hardmode and decrease hunger otherwise increase health by a small ammount (hunger and thirst are a hard difficulty exclusive)
                        ()->{
                            #if(debug&&(windows||hl)) Main.LOG('player has eaten something.'); #end
                            onItemUsed("consume", curItem);
                            unloadItem();
                        }
                    );
                }
            }
        }
        

        //always at the bottom.
        RightClickOptions.push("Drop");
        RightClickFunctions.push(
            ()->{
                GameMap.instance.add(new Pickup(GameMap.instance.plr.x, GameMap.instance.plr.y, curItem)); //place a pickup at the player location containing the item we just had.
                onItemUsed("drop", curItem);
                unloadItem();
            }
        );
    }
    private function loadItemGraphic(item:String) {
        var file:#if(html5)BitmapData#else String#end = Paths.image('ui/items', item);
        if(#if(html5)file==null#else !FileSystem.exists(file)#end) file = Paths.image('items/images', item); //fallback check.
        if(#if(html5)file!=null#else FileSystem.exists(file)#end) {
            if(object==null) object = new FlxSprite(0, 0);
            object.loadGraphic(file);
            object.visible=true;
            object.setGraphicSize(SIZE);
            object.updateHitbox();
            add(object);
            object.setPosition(slot.x+slot.width/2-object.width/2, slot.y+slot.height/2-object.height/2);
        }else{
            if(object==null) object = new FlxSprite(0, 0).makeGraphic(SIZE, SIZE, 0xFFFF00FF);
            object.visible=true;
            object.setGraphicSize(SIZE, SIZE);
            object.updateHitbox();
            add(object);
            Main.showError("RENDERFAILURE", item);
        }
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        FlxG.watch.addQuick('held item', Main.curHeldItem);
        //pickup logic
        if(interactable){
            if(((FlxG.mouse.overlaps(this)&&FlxG.mouse.justPressed)) && !optionsOpen //if the options menu is open we dont wanna try and grab the item.
            ) {
                if(curItem!=null && (Main.curHeldItem==null && hasItem)) {
                    Main.curHeldItem=curItem;
                    unloadItem();
                    onItemMoveStart();
                }else if(Main.curHeldItem!=null){
                    setItem(Main.curHeldItem);
                    onItemMoveEnd();
                    Main.curHeldItem=null;
                }
            }
            if(((FlxG.mouse.overlaps(this)&&FlxG.mouse.justPressedRight)) && hasItem==true
            ) {
                openRightClickMenu();
                #if(debug&&(windows||hl)) Main.LOG('attempting right click menu'); #end
            }
        }



        if(optionsOpen && (optionsGroup!=null)){
            if(!FlxG.mouse.overlaps(optionsGroup, camera)) openRightClickMenu();
        }
    }
    public function unloadItem() {
        curItem=null;
        hasItem=false;
        object.visible=false;
    }
    public function setItem(item:Item) {
        hasItem=true;
        curItem=item;
        loadItemGraphic(item?.item);
        RightClickOptions=[];
        RightClickFunctions=[];

        if(item?.consumable==true){ //null safety hopefully.
            if(((item?.consumableType==SHOT||(item?.consumableType==GLASS||item?.consumableType==BOTTLE)||item?.isPotion))){
                RightClickOptions.push("Drink");
                RightClickFunctions.push( //TODO: checks to see if player is in hardmode and decrease hunger otherwise increase health by a small ammount (hunger and thirst are a hard difficulty exclusive)
                    ()->{
                        #if(debug&&(windows||hl)) Main.LOG('player has drank something.'); #end
                        onItemUsed("drink", curItem);
                        unloadItem();
                    }
                );
            }
            if((item?.consumableType==CRUMB||(item?.consumableType==SNACK||item?.consumableType==MEAL))){
                RightClickOptions.push("Eat");
                RightClickFunctions.push( //TODO: checks to see if player is in hardmode and decrease hunger otherwise increase health by a small ammount (hunger and thirst are a hard difficulty exclusive)
                    ()->{
                        #if(debug&&(windows||hl)) Main.LOG('player has eaten something.'); #end
                        onItemUsed("consume", curItem);
                        unloadItem();
                    }
                );
            }
        }
        

        //always at the bottom.
        RightClickOptions.push("Drop");
        RightClickFunctions.push(
            ()->{
                GameMap.instance.add(new Pickup(GameMap.instance.plr.x, GameMap.instance.plr.y, curItem)); //place a pickup at the player location containing the item we just had.
                onItemUsed("drop", curItem);
                unloadItem();
            }
        );
    }

    var optionsGroup:FlxSpriteGroup=new FlxSpriteGroup();
    var optionsOpen:Bool=false;
    var RightClickOptions:Array<String>=[];
    var RightClickFunctions:Array<Void->Void>=[];
    var rightClickButtons:Array<FlxButton>=[];
    private function openRightClickMenu() {
        optionsOpen=!optionsOpen;
        if(!optionsOpen) {
            for(button in rightClickButtons) button.destroy();
            rightClickButtons=[];
            if(optionsGroup!=null) optionsGroup.destroy();
        }else{
            optionsGroup=new FlxSpriteGroup(FlxG.mouse.viewX, FlxG.mouse.viewY);
            optionsGroup.camera=camera;
            HUDSubstate.instance.add(optionsGroup);
            for(i in 0...RightClickOptions.length) {
                var button:FlxButton = new FlxButton(0, 0+(20*i), RightClickOptions[i], ()->{
                    RightClickFunctions[i]();
                    openRightClickMenu();
                });
                optionsGroup.add(button);
                rightClickButtons.push(button);
            }
        }
    }
}

//health object stuff, really cool design!
class HealthFlask extends FlxTypedSpriteContainer<FlxSprite> {
    var outline:FlxSprite;
    var innerHealth:FlxSprite;
    var outerXP:FlxSprite;
    
    public function new(x:Float, y:Float) {
        super(x, y);
        outline = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/health', 'flask_outline'));

        innerHealth = new FlxSprite(0, 0);
        innerHealth.makeGraphic(32, 32, 0xFFFF0000);
        innerHealth.setPosition(outline.getGraphicMidpoint().x-32/2, outline.getGraphicMidpoint().y-32/2);

        outerXP = new FlxSprite(0, 0).makeGraphic(32, 32, 0xFFFFFF00);
        outerXP.setPosition(outline.getGraphicMidpoint().x-32/2, outline.getGraphicMidpoint().y-32/2);
        

        //keep at top for stuff.
        add(innerHealth);
        //add(outerXP);
        add(outline);
        scale.set(2, 2);
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
    }
}

class HUDSubstate extends FlxSubState {
    public static var instance:HUDSubstate;
    public var healthFlask:HealthFlask;
    public var weaponText:FlxText;
    public var fullOpen:Bool=false; //so that we can have the hotbar
    private static final MAX_SLOTS:Int = 10;
    public var inventory:Null<Array<OneOfTwo<String, Item>>>;
    public var slots:Array<InventorySlot> = [];

    public var selectedItem:Item;
    public function new(?items:Array<Item>) {
        super();
        instance=this;
        inventory=items??[];
        var index:Int=0;
        for(i in 0...Player.INVENTORY_SLOTS) {
            if(i%MAX_SLOTS==0)index=0;
            var slot:InventorySlot=new InventorySlot(0+(InventorySlot.SIZE*index), 0+(InventorySlot.SIZE*(Math.floor(i/MAX_SLOTS))));
            slots.push(slot);
            add(slot);
            slot.onItemMoveStart = ()->{
                inventory[slots.indexOf(slot)] = "EMPTY";
            };
            slot.onItemMoveEnd = ()->{
                inventory[slots.indexOf(slot)] = Main.curHeldItem;
            };
            slot.onItemUsed = (action, item)->{
                switch(action){
                    case "consume": inventory[slots.indexOf(slot)] = "EMPTY";
                    case "drink": inventory[slots.indexOf(slot)] = "EMPTY";

                    case "drop": inventory[slots.indexOf(slot)] = "EMPTY"; //so the slot doesnt get IMMEDIATELY overwritten by inventory reloading items constantly.
                    default: #if(debug&&(windows||hl)) Main.LOG('unknown action tyep $action on $item'); #end
                }
            }
            index++;
        }

        PotionType.getPotionEffect(PotionType.HEALTH);

        weaponText=new FlxText(0+(InventorySlot.SIZE*index), 0, 0, "[WEAPONNAME]\n{C}/{M}|{P}", 12);
        add(weaponText);
        weaponText.camera=Main.camHUD;
        
        healthFlask=new HealthFlask(0, 0+InventorySlot.SIZE);
        add(healthFlask);
        healthFlask.camera=Main.camHUD;

        for(i in 0...Player.INVENTORY_SLOTS){ //fill the inventory with empty slots
            inventory[i]="EMPTY";
        }
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        for(i in 0...inventory.length) {
            if(!(inventory[i] is String)){ //only do the item writing IF the inventory slot isnt a string.
                if(slots[i].curItem != inventory[i]) {
                    slots[i].setItem(inventory[i]);
                }
            }
        }
        if(Main.curHeldItem!=null) {
            //create the small graphic that follows the cursor when holding an item
            if(Main.heldItemGraphic==null) {
                Main.heldItemGraphic = new FlxSprite(FlxG.mouse.viewX, FlxG.mouse.viewY);
                #if(debug&&(windows||hl)) Main.LOG(Main.curHeldItem); #end
                if(#if (html5) Paths.image('ui/items', Main.curHeldItem.item)!=null #else FileSystem.exists(Paths.image('ui/items', Main.curHeldItem.item))#end) {
                    Main.heldItemGraphic.loadGraphic(Paths.image('ui/items', Main.curHeldItem.item));
                    Main.heldItemGraphic.setGraphicSize(32, 32);
                    Main.heldItemGraphic.updateHitbox();
                }else Main.heldItemGraphic.makeGraphic(16, 16, 0xFFFF00FF);
                Main.heldItemGraphic.camera=Main.camHUD;
                add(Main.heldItemGraphic);
            }else{
                Main.heldItemGraphic.setPosition(FlxG.mouse.viewX+16, FlxG.mouse.viewY);
                if(!fullOpen) {
                    //TODO: make the item move back to the last slot it was in instead of the first available slot.
                    Pickup.ExternalsendToInventory(Main.curHeldItem); //send to the first available slot in the inventory.
                    Main.curHeldItem=null; //doing this should automatically destroy the graphic, if im correct.
                }
            }
        }else if(Main.heldItemGraphic!=null) {
            Main.heldItemGraphic.destroy();
            Main.heldItemGraphic=null;
        }
        @:privateAccess weaponText.visible=Player.instance.isWeapon;
        selectedItem=slots[Player.instance.curHotbarSlot]?.curItem??{
            type: NULL,
            weaponType: NULL,
            gunType: NULL,
            item: "",
            durability: 0.0,
            damage: [],
            charges: 0.0,
        };
        healthFlask.y=(fullOpen?(InventorySlot.SIZE*(slots.length/10)):0+InventorySlot.SIZE)+10;
        for(i in 0...slots.length){ //im going to make sure i only have ONE for loop in the update function, since these get out of hand QUICKLY.
            slots[i].color=0xFFFFFFFF;
            if(slots[Player.instance.curHotbarSlot]!=null) slots[Player.instance.curHotbarSlot].color = 0xFF00FF00; //override the color then just after setting it.
            if(fullOpen){
                if(slots[i].visible==false || slots[i].interactable==false){
                    slots[i].visible=slots[i].active=slots[i].alive=slots[i].interactable=true;
                }
            }else{
                if(i>MAX_SLOTS-1)slots[i].visible=slots[i].active=slots[i].alive=false;
                else slots[i].interactable=false;
            }
        }
    
        if(FlxG.keys.anyJustPressed(Main.controls.get('pause'))) { //swapped for anyJustPressed so it doesnt run multiple times in a frame
            if(Player.onPlayerPause!=null)Player.onPlayerPause(); //so we can pause enemy and object ai/animations/tweens/everything
            Player.playerPauseRequested = true;
            openSubState(new PauseMenu()); //open the substate IN the substate. simple fix!
        }
    }
}