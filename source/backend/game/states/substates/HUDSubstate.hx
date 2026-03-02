package backend.game.states.substates;

enum abstract ItemType(String) from String to String {
    var ITEM="ITEM";
    var CONSUMABLE="CONSUMABLE";
    var MEELEE="MEELEE";
    var RANGED="RANGED";
    var MAGIC="MAGIC";
    var NULL="NULL";
}
enum abstract ConsumableType(String) from String to String {
    var POTION="POTION"; //TODO: implement
    
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
    @:optional var durability:Float;
    var damage:Map<String, Float>; //so we can apply MANY damage types to anything. //TODO: list damage types
    @:optional var consumable:Bool;
    @:optional var consumableType:ConsumableType;
    @:optional var charges:Float; //also affects guns
}

class InventorySlot extends FlxSprite {
    public var onItemMoveStart:Void->Void;
    public var onItemMoveEnd:Void->Void;
    public static final SIZE:Int = 64;
    public var hasItem:Bool=false;
    public var curItem:Null<Item>;
    public var locked:Bool=false;

    public function new(x:Float,y:Float) {
        super(x, y);
        loadGraphic(Paths.image('ui/inventory', 'slot'));
        setGraphicSize(SIZE, SIZE);
        updateHitbox();
        scrollFactor.set();
        camera=Main.camHUD;
    }
    private function loadItemGraphic(item:String) {
        if(#if (android || html5) Paths.image('ui/items', item)!=null #else FileSystem.exists(Paths.image('ui/items', item))#end) {
            var outputBitmapData:BitmapData = new BitmapData(Math.floor(width), Math.floor(height), true, 0xFFFFFF);
            var scaleMatrix:Matrix = new Matrix(1, 0, 0, 1, 0, 0);
            scaleMatrix.scale(2, 2);
            outputBitmapData.draw(pixels, scaleMatrix);
            scaleMatrix.scale(1.5, 1.5);
            outputBitmapData.draw(#if (android||html5) Paths.image('ui/items', item) #else BitmapData.fromFile(Paths.image('ui/items', item)) #end, scaleMatrix);
            loadGraphic(outputBitmapData); //hehehehaw! now we *hopefully* can update the hitbox
            setGraphicSize(SIZE, SIZE);
            updateHitbox();
        }else{
            makeGraphic(SIZE, SIZE, 0xFFFF00FF);
            setGraphicSize(SIZE, SIZE);
            updateHitbox();
            Main.showError("RENDERFAILURE", item);
        }
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        FlxG.watch.addQuick('held item', Main.curHeldItem);

        //pickup logic
        if(FlxG.mouse.overlaps(this) && FlxG.mouse.justPressed) {
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
    }
    public function unloadItem() {
        curItem=null;
        hasItem=false;
        graphic.bitmap.fillRect(graphic.bitmap.rect, 0x00000000);
        loadGraphic(Paths.image('ui/inventory', 'slot'));
        setGraphicSize(SIZE, SIZE);
        updateHitbox();
    }
    public function setItem(item:Item) {
        hasItem=true;
        curItem=item;
        loadItemGraphic(item?.item);
    }
}

//health object stuff, really cool design!
class HealthFlask extends FlxTypedSpriteContainer<FlxSprite> {
    var outline:FlxSprite;
    var innerHealth:FlxSprite;
    var outerXP:FlxSprite;
    
    var innerHealthShader:MaskShader;
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
        innerHealth.shader = innerHealthShader = new MaskShader(#if (android || html5) Paths.image('ui/health', "flask_inner-MASK")#else BitmapData.fromFile(Paths.image('ui/health', "flask_inner-MASK"))#end);
        //outerXP.shader = new MaskShader(BitmapData.fromFile("assets/ui/health/flask_outer-MASK.png"));
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        innerHealthShader.maskValue.value=[1-Math.max(0,Math.min(1,Player.health/100))];
    }
}

class HUDSubstate extends FlxSubState {
    public var healthFlask:HealthFlask;
    public var weaponText:FlxText;
    public var fullOpen:Bool=false; //so that we can have the hotbar
    private static final MAX_SLOTS:Int = 10;
    public var inventory:Null<Array<OneOfTwo<String, Item>>>;
    public var slots:Array<InventorySlot> = [];

    public var selectedItem:Item;
    public function new(?items:Array<Item>) {
        super();
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
            index++;
        }

        weaponText=new FlxText(0+(InventorySlot.SIZE*index), 0, 150, "[WEAPONNAME]\n{C}/{M}|{P}", 12, true);
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
        @:privateAccess weaponText.visible=Player.instance.isWeapon;
        selectedItem=slots[Player.curHotbarSlot]?.curItem??{
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
            if(slots[Player.curHotbarSlot]!=null) slots[Player.curHotbarSlot].color = 0xFF00FF00; //override the color then just after setting it.
            if(fullOpen){
                if(slots[i].visible==false)slots[i].visible=true;
            }else{
                if(i>MAX_SLOTS-1)slots[i].visible = false;
            }
        }
        
        if(FlxG.keys.anyJustPressed(Main.controls.get('pause'))) { //swapped for anyJustPressed so it doesnt run multiple times in a frame
            if(Player.onPlayerPause!=null)Player.onPlayerPause(); //so we can pause enemy and object ai/animations/tweens/everything
            Player.playerPauseRequested = true;
            openSubState(new PauseMenu()); //open the substate IN the substate. simple fix!
        }
    }
}