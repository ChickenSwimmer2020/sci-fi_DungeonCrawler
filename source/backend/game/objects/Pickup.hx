package backend.game.objects;

class Pickup extends FlxSprite {
    public var onPickup:Item->Void; //void to void, can be overridden for whatever logic we want, but also returns the item definition we have.
    public var interactionSprite:FlxSprite;
    public var data:Item=null;
    public function new(x:Float, y:Float, dat:Item) {
        super(x, y);
        data=dat;
        if(data==null){
            Main.showError('NULLITEM');
            destroy();
        }
        makeGraphic(10, 10, 0xFF00FF00);
        camera=Main.camGame; //just gonna do this automatically.
        //TODO: graphic loading system
    }
    var sin:Float=0;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(interactionSprite!=null) {
            sin+=0.005;
            interactionSprite.x = FlxMath.lerp(Player.instance.getGraphicMidpoint().x-interactionSprite.width/2, interactionSprite.x, Math.exp(-elapsed * 3.125 * 4 * 1));
            interactionSprite.y = FlxMath.lerp(Player.instance.getGraphicMidpoint().y-interactionSprite.height, interactionSprite.y, Math.exp(-elapsed * 3.125 * 4 * 1));
            interactionSprite.y+=Math.sin(sin)/4;
        }
        if(Player.instance.overlaps(this)) {
            interactionPopup(true);
            if(#if android true #else FlxG.keys.anyJustPressed(Main.controls.get('interact'))#end) {
                if(!inventoryFull()){
                    if(onPickup!=null&&data!=null) onPickup(data);
                    sendToInventory(data);
                    destroy();
                    interactionPopup(false);
                }else{
                    trace('TODO: logic for showing the text telling you that your inventory is full');
                }
            }
        }else{
            interactionPopup(false);
        }
    }
    private function inventoryFull():Bool return (Player.instance.inventory.inventory.length<Player.INVENTORY_SLOTS);
    private function sendToInventory(item:Item) {
        var inv:Array<OneOfTwo<String, Item>> = Player.instance.inventory.inventory;
        var it:Item = item;
        if(Paths.weaponExists(item.item))it=WeaponParser.buildWeaponItemPointer(WeaponParser.parse(item.item));
        if(inv[inv.getFirstEmpty()]!=null && ((inv[inv.getFirstEmpty()] is String) && inv[inv.getFirstEmpty()]=="EMPTY")){
            inv[inv.getFirstEmpty()] = it;
        }
    }

    public static function ExternalsendToInventory(item:Item) {
        var inv:Array<OneOfTwo<String, Item>> = Player.instance.inventory.inventory;
        var it:Item = item;
        if(Paths.weaponExists(item.item))it=WeaponParser.buildWeaponItemPointer(WeaponParser.parse(item.item));
        if(inv[inv.getFirstEmpty()]!=null && ((inv[inv.getFirstEmpty()] is String) && inv[inv.getFirstEmpty()]=="EMPTY")){
            inv[inv.getFirstEmpty()] = it;
        }
    }

    var ranonce:Bool=false;
    private function interactionPopup(enable:Bool) {
        if(interactionSprite==null) {
            interactionSprite = new FlxSprite(x, y)#if (debug) .loadGraphic(Paths.DEBUG('pickupinteraction', 'png'));#else.makeGraphic(16, 16, 0xFF00FFFF);#end
            FlxG.state.add(interactionSprite);
            interactionSprite.camera=Main.camGame;
        }else{
            interactionSprite.visible=enable;
            if(!enable){
                ranonce=false;
            }else{
                if(!ranonce){
                    interactionSprite.x = Player.instance.getGraphicMidpoint().x-interactionSprite.width/2;
                    interactionSprite.y = Player.instance.getGraphicMidpoint().y-interactionSprite.height;
                    sin=0;
                    ranonce=true;
                }
            }
        }
    }
}