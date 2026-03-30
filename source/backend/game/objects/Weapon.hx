package backend.game.objects;

typedef WeaponData = {
    var weaponType:ItemType;
    var name:String;
    var damage:Map<String, Float>;
    var format:WeaponType;
    var gunType:GunType;
    var fireMode:GunFireMode;
    var magicType:MagicType;
    var sprite:{n:String,a:Bool,f:{w:Int,h:Int}};
    var animations:Array<{n:String, f:Array<Int>, fr:Int, l:Bool, fl:{x:Bool,y:Bool}}>;
};

class Bullet extends FlxSprite {
    public static final BULLET_HANGTIME:Float=5.2;
    public var onRemove:Void->Void;
    public var damages:Map<String,Float>=[];
    public var endTimer:FlxTimer=new FlxTimer();
    public function new(x:Float, y:Float, dmg:Map<String,Float>) { //TODO: graphics system
        super(x, y);
        makeGraphic(2, 2, 0xFFFFFF00);
        damages=dmg;

        endTimer.start(BULLET_HANGTIME, (_)->{
            onRemove();
            _.destroy();
            destroy();
        });
    }

    public function forceRemoval() {
        endTimer.cancel();
        endTimer.destroy();
        onRemove();
        destroy();
    }
}

class Weapon extends FlxSprite{
    public static final BULLET_SPEED:Float = 500.0;
    public static final MAX_BULLETSPREAD:Float = 25.2;
    public static final POWER_INCREMENT:Float = 0.5;
    public static final KICKBACK_STRENGTH:Float=30; //reversed, higher value means less kickback. TODO: possibly make this weaponfile dependant
    public var activeProjectiles:Array<Bullet>=[]; // for tracking, editing, and removal purposes.
    public var onLeftClick:Void->Void;
    public var onRightClick:Void->Void;
    public var onMiddleClick:Void->Void; //for special use-cases only. snipers maybe?
    public var name:String="";
    public var damageTypes:Map<String, Float>=[];
    public var shoot_time:Float=0;
    public var charge_time:Float=0;
    public var frMode:GunFireMode=SEMI; //for default

    public var charges:Int=1000; //ammo
    
    private var justShotFail:Bool=false;
    private var coolDownTimer:FlxTimer=new FlxTimer();
    public function new(x:Float, y:Float, data:WeaponData) {
        super(x, y);
        setUpWeapon(data);
        coolDownTimer.start(0); //force set finished to true for the shooting logic
    }
    public function playAnimation(anim:String, ?force:Bool=false, ?reverse:Bool=false, ?frame:Int=0) if(animation.exists(anim)) animation.play(anim, force, reverse, frame);
    public function setActions(olc:Void->Void,orc:Void->Void,?omc:Void->Void) {
        onLeftClick=olc;
        onRightClick=orc;
        onMiddleClick=omc??null;
    }
    var increment:Int=0;
    var power:Float=0;
    public function shoot() {
        if(FlxG.mouse.overlaps(Player.instance.inventory)&&Player.instance.inventory.fullOpen) return; //cancel if holding an item. much simpler fix than anything else honestly.
        if(charges<=0)return; //cancel if we have no ammo.
        increment=0;
        if(coolDownTimer.finished){
            switch(frMode) {
                case SEMI: fire(); charges--;
                case BURST: for(i in 0...3)Functions.wait(shoot_time*(0.15*i), (_)->{charges--;fire(_);});
                case FULLAUTO:increment++;Functions.wait(shoot_time*(0.15*increment), (_)->{charges--;fire(_);});
                case RAIL: power+=POWER_INCREMENT; power=Math.max(0, Math.min(power, 100));
                case SHOTGUN: for(i in 0...9){fire(1, true, i);charges--;}
                case NULL:
            }
            if(frMode!=RAIL) coolDownTimer.start(frMode==BURST?shoot_time*3:shoot_time);
        }
    }
    private function fire(?_timer:FlxTimer,?railPower:Float=1,?shotgun:Bool=false,?shotgunIndex:Int=0) {
        if(_timer!=null)_timer.destroy();
        var bullet:Bullet = new Bullet(x, y, damageTypes);
        bullet.onRemove=()->{
            activeProjectiles.remove(bullet);
        };
        activeProjectiles.push(bullet);
        FlxG.state.add(bullet);
        bullet.camera=camera;

        bullet.angle=angle; //give the bullet hte same angle as the weapon.
        final cos:Float=Math.cos(angle*Math.PI/180)*BULLET_SPEED*railPower;
        final sin:Float=Math.sin(angle*Math.PI/180)*BULLET_SPEED*railPower;
        final shotgunSpreads:Array<Float>=[-15,-12,-6,-2,0,2,6,12,15];
        bullet.velocity.set(FlxG.random.float(-MAX_BULLETSPREAD, MAX_BULLETSPREAD)+cos+shotgunSpreads[shotgunIndex], FlxG.random.float(-MAX_BULLETSPREAD, MAX_BULLETSPREAD)+sin+shotgunSpreads[shotgunIndex]); //yay, math!
        //if we're firing the shotgun we want to times KICKBACK_STRENGTH by the number of pellets, because otherwise it jumps back WAY to far.
        setPosition(x-(cos/(shotgun?(KICKBACK_STRENGTH*9):KICKBACK_STRENGTH)), y-(sin/(shotgun?(KICKBACK_STRENGTH*9):KICKBACK_STRENGTH))); //do this **after** we set the velocity to hopefuly prevent bullets from spawning behind the player
        Player.instance.velocity.set( //should add some kickback to the player. hopefully.
            Player.instance.weaponKickback.x-cos/(shotgun?(KICKBACK_STRENGTH*9):KICKBACK_STRENGTH),
            Player.instance.weaponKickback.y-sin/(shotgun?(KICKBACK_STRENGTH*9):KICKBACK_STRENGTH)
        );
    }
    private function setUpWeapon(data:WeaponData) { 
        animation.destroy();
        animation = new FlxAnimationController(this);
        damageTypes = [];
        if(data==null){ //so we still *make* the weapon, it just doesnt actually load a real weapon until we get one.
            var internal:WeaponData = Flags.FALLBACK_WEAPON;
            name=internal.name;
            frMode=internal.fireMode;
            shoot_time=switch(internal.fireMode){case SEMI: 0.25; case FULLAUTO: 0.1; case SHOTGUN: 1.5; case BURST: 0.4; case RAIL: 5.2; case NULL:0.0;};
            if(internal.fireMode==RAIL) charge_time=0.5;
            loadGraphic(internal.sprite.n, internal.sprite.a, internal.sprite.f.w, internal.sprite.f.h);
            for(anim in internal.animations) animation.add(anim.n, anim.f, anim.fr, anim.l, anim.fl.x, anim.fl.y);
            for(damnType => damnDamage in internal.damage) damageTypes.set(damnType, damnDamage);
            updateHitbox();
        }else{
            name=data.name;
            frMode=data.fireMode;
            shoot_time=switch(data.fireMode){case SEMI: 0.25; case FULLAUTO: 0.1; case SHOTGUN: 1.5; case BURST: 0.4; case RAIL: 5.2; case NULL:0.0;};
            if(data.fireMode==RAIL) charge_time=0.5;
            loadGraphic(data.sprite.n, data.sprite.a, data.sprite.f.w, data.sprite.f.h);
            for(anim in data.animations) animation.add(anim.n, anim.f, anim.fr, anim.l, anim.fl.x, anim.fl.y);
            for(damnType => damnDamage in data.damage) damageTypes.set(damnType, damnDamage);
            updateHitbox();
        }
    }
    var shaderTime:Float=0;
    var railFireShader:RailFire;
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(coolDownTimer.finished){
            if(frMode==RAIL&&FlxG.mouse.justReleased){
                if(power<25) justShotFail=true; //failure if under 25%
                else{
                    railFireShader=new RailFire();
                    railFireShader.intensity.value=[0.01];
                    railFireShader.speed.value=[120.0];
                    if(Main.camGame.filters==null)Main.camGame.filters=[];
                    if(Main.camHUD.filters==null)Main.camHUD.filters=[];
                    if(Main.camOther.filters==null)Main.camOther.filters=[];
                    Main.camGame.filters.push(new ShaderFilter(railFireShader));
                    Main.camHUD.filters.push(new ShaderFilter(railFireShader));
                    Main.camOther.filters.push(new ShaderFilter(railFireShader));
                    charges-=10; //railgun has higher max ammo, but it drains faster to compensate.
                    fire(power/100);
                    power=0;
                    coolDownTimer.start(shoot_time, (_)->{
                        Main.camGame.filters.remove(Main.camGame.filters[0]);
                        Main.camHUD.filters.remove(Main.camHUD.filters[0]);
                        Main.camOther.filters.remove(Main.camOther.filters[0]);
                        railFireShader=null;
                    });
                }
            }else if(frMode==RAIL && justShotFail){
                justShotFail=false;
                power=0;
                coolDownTimer.start(shoot_time/2);
            }
        }
        if(railFireShader!=null){
            shaderTime+=FlxG.elapsed;
            railFireShader.iTime.value = [shaderTime];
            railFireShader.intensity.value=[FlxMath.lerp(0.0, railFireShader.intensity.value[0], Math.exp(-elapsed * 3.125 * 1 * 1))];
        }

        FlxG.watch.addQuick("cooldown timer", coolDownTimer.timeLeft);
        FlxG.watch.addQuick("rail power", power);
    }
}
class WeaponParser {
    public static function buildWeaponItemPointer(data:WeaponData):Item{
        //if(data.weaponType!=RANGED||(data.weaponType!=MEELEE||data.weaponType!=MAGIC)) return null;
        return {
            type: data.weaponType,
            weaponType: data.format,
            gunType: data.gunType,
            MagicType: data.magicType,
            item: data.name,
            durability: 100, //TODO: somehow load from inventory save file. (NOT SEPRATE)
            damage: data.damage,
            consumable: false,
            consumableType: NULL,
            charges: 100, //TODO: somehow load from inventory save file.
        };
    }
    public static function recycleWeapon(weapon:Weapon, path:String) {
        @:privateAccess
        if(path!=""&&(weapon!=null&&#if (html5) Assets.getText(Paths.weapon(path))!=null#else FileSystem.exists(Paths.weapon(path)) #end)) weapon.setUpWeapon(parse(path));
        else if(weapon==null||#if(html5) Assets.getText(Paths.weapon(path))==null#else !FileSystem.exists(Paths.weapon(path))#end) Main.showError("IOERROR", Paths.weapon(path));
    }
    public static function parse(path:String):WeaponData {
        if(path==null) return null; //simple as that.
        if(#if(html5) Assets.getText(Paths.weapon(path))!=null#else FileSystem.exists(Paths.weapon(path))#end)return parseXML(Paths.weapon(path));
        else Main.showError("IOERROR", Paths.weapon(path));
        return null;
    }
    private static function parseXML(path:String):WeaponData {
        trace('Parsing weapon file: $path');
        if(#if(html5) Assets.getText(path)!=null #else FileSystem.exists(path)#end){
            var xmlToParse:Xml = Xml.parse(#if(html5) Assets.getText(path) #else File.getContent(path)#end);
            var damge:Map<String, Float>=[];
            var anims:Array<{n:String, f:Array<Int>, fr:Int, l:Bool, fl:{x:Bool,y:Bool}}>=[];
            final root:Xml = xmlToParse.firstChild();
            var returnedWeapon:WeaponData = {
                weaponType: root.get('type'),
                name: root.get('name'),
                format: root.get('format'),
                gunType: root.get('gunType'),
                fireMode: root.get('fireMode'),
                magicType: root.get('magicType'),
                sprite: {
                    n: root.get('spriteName'),
                    a: root.get('spriteAnimated').toBool(),
                    f: {
                        w: root.get('spriteFrameWidth').toInt(),
                        h: root.get('spriteFrameHeight').toInt()
                    }
                },
                animations:[],
                damage:[]
            };
            trace(returnedWeapon); //WHAT THE FUCK IS BROKEN.
            for(element in root.elements()) {
                if(element.nodeName=="Animation") anims.push({n:element.get('name'),f:element.get('frames').contains('...')?element.get('frames').StringToArray():element.get('frames').StringToArray(true),fr:Std.parseInt(element.get('frameRate')),l:element.get('loop').toBool(),fl:{x:element.get('flipX').toBool(),y:element.get('flipY').toBool()}});
                else if(element.nodeName=="Damage") damge.set(element.get('type'), Std.parseFloat(element.get('value')));
            }
            returnedWeapon.damage=damge;
            returnedWeapon.animations=anims;
            return returnedWeapon;
        }else Main.showError("IOERROR", path);
        return null;
    }
}