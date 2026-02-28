package backend.game.objects;

import flixel.util.typeLimit.OneOfTwo;
import backend.game.objects.Weapon.WeaponParser;
import backend.game.states.substates.HUDSubstate.Item;
import flixel.math.FlxMath;

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
    var sin:Int=0;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(interactionSprite!=null) {
            sin++;
            interactionSprite.x = FlxMath.lerp(Player.instance.x, interactionSprite.x, Math.exp(-elapsed * 3.125 * 4 * 1));
            interactionSprite.y = FlxMath.lerp(Player.instance.y, interactionSprite.y, Math.exp(-elapsed * 3.125 * 4 * 1));
            
            interactionSprite.y+=Math.sin(sin);
        }
        if(Player.instance.overlaps(this)) {
            interactionPopup(true);
            if(FlxG.keys.anyJustPressed(Main.controls.get('interact'))) {
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

    var ranonce:Bool=false;
    private function interactionPopup(enable:Bool) {
        if(interactionSprite==null) {
            interactionSprite = new FlxSprite(x, y).loadGraphic(Paths.DEBUG('pickupinteraction', 'png'));
            FlxG.state.add(interactionSprite);
            interactionSprite.camera=Main.camGame;
        }else{
            if(!enable){
                ranonce=false;
                interactionSprite.destroy(); //get rid of it if we dont want it. saves memory i think.
            }else{
                if(interactionSprite.visible != enable)
                    interactionSprite.visible=enable;
                if(!ranonce){
                    interactionSprite.x = Player.instance.x;
                    interactionSprite.y = Player.instance.y;
                    sin=0;
                    ranonce=true;
                }
            }
        }
    }
}