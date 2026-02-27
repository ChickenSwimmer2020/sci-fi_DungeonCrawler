package backend.game.objects;

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
            destroy();
            Main.showError('NULLITEM');
        }
        makeGraphic(10, 10, 0xFF00FF00); //placeholder
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
            if(FlxG.keys.anyJustPressed(Player.controls.get('interact'))) {
                if(onPickup!=null&&data!=null) onPickup(data);
                sendToInventory(data);
                destroy();
                interactionPopup(false);
            }
        }else{
            interactionPopup(false);
        }
    }
    private function sendToInventory(item:Item) {
        var inv:Array<Item> = Player.instance.inventory.inventory;
        var it:Item = item;
        if(Paths.weaponExists(item.item))it=WeaponParser.buildWeaponItemPointer(WeaponParser.parse(item.item));
        inv.push(it); //TODO: make sure inventory isnt full.
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