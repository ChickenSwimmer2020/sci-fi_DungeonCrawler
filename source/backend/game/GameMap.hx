package backend.game;

class GameMap extends FlxTypedGroup<Dynamic> {
    public static function reset() {
        isDying=false;
    }
    public static var isDying:Bool=false;

    public static var instance:GameMap;
    public static final TILE_SIZE:Int = 16; //we can avvoid MAGIC numbers
    public static final COLLISION_RADIUS:Int=2;

    public var tiles:Array<TileData> = []; //quick access to each tile without problems.
    public var tileObjects:Array<Tile> = [];
    public var plr:Player;
    public var enemies:Array<BaseEnemy>=[];
   
    public static var file:MapFile;
    public function new(f:MapFile) {
        super();
        file = f;
        instance=this;
        if(file!=null) tiles = file.tiles;
    }
    var playerSpawnPoint:FlxPoint=new FlxPoint();
    var targetSparnLocation:FlxPoint = FlxPoint.weak();

    var gameFlash:FlxSprite;
    public function generate(testingState:Bool=false) {
        if(GameState.instance!=null && !GameState.instance.generatedCameras) GameState.generateCameras(); //force gameState to regenerate cameras before anything. because the game likes to throw a fit if these cameras dont exist.
        for(tile in tiles){
            add(generateObjectViaTile(tile));
        }

        GameState.inGame=!testingState;
        add(plr = new Player());
        plr.setPosition(targetSparnLocation.x, targetSparnLocation.y);
        plr.camera = Main.camGame;
        plr.testingMode = testingState;
        plr.onFinishLoading = ()->{
            Player.loadFromFile(); //load all the shtuff from the current save file.
        };

        Player.onDeath = ()->{
            Conductor.bopCamera=false;
            isDying=true;

            for(group in ([tiles, tileObjects, enemies, plr]:Array<Dynamic>)) {
                //TODO: freeze all logic
                if(group is Array) {
                    var a:Array<Dynamic>=cast(group); //because i have to do this.
                    for(object in a) {
                        if(Reflect.hasField(object, 'frozen'))
                            object.frozen=true;
                        else{
                            if(Reflect.hasField(object, 'velocity')) {
                                object.velocity = FlxPoint.weak(0, 0);
                            }
                        }
                    }
                }else{
                    if(Reflect.hasField(group, 'velocity'))
                        group.velocity = FlxPoint.weak(0, 0);
                    if(group is Player) {
                        var s:Player = cast(group);
                        s.freeze();
                    }
                }
            }

            if(Preferences.getPref("shaders")){
                for(cam in [Main.camGame, Main.camHUD, Main.camOther]) {
                    cam.filters.push(new ShaderFilter(new Invert()));
                }
            }
            Music.doDeathGlitch();

            gameFlash = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
            add(gameFlash);
            gameFlash.camera = Main.camOther;
            gameFlash.alpha = 0.2;

            Functions.wait(0.1, (_)->{
                gameFlash.destroy();
                
                Functions.wait(0.5, (_)->{ //wait for two times the thing, this is for the death sound :3
                    Player.overrideCameraZoom=true;
                    Music.stopMusic();
                    Music.stopLoops(true);
                    FlxG.switchState(DeathState.new);
                });
            });
        };
        if(testingState){
            add(new Pickup(0, 0, { //for testing.
                type: RANGED,
                item: "pistol",
                damage: []
            }));

            //var testEnemy:BaseEnemy = new BaseEnemy(playerSpawnPoint.x-32, playerSpawnPoint.y);
            //add(testEnemy);
            //testEnemy.camera=Main.camGame;

            add(generateObjectViaTile({
                pos: {
                    row: 5,
                    colum: 0
                },
                set: "",
                collides: true,
                isSpecial: true,
                specialType: BREAKER
            }));
            
            add(new Pickup(playerSpawnPoint.x, playerSpawnPoint.y-50, {type: RANGED,item: "pistol",damage: []}));
            add(new Pickup(playerSpawnPoint.x+50, playerSpawnPoint.y-50, {type: RANGED,item: "railgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+100, playerSpawnPoint.y-50, {type: RANGED,item: "shotgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+150, playerSpawnPoint.y-50, {type: RANGED,item: "rifle",damage: []}));
            add(new Pickup(playerSpawnPoint.x+200, playerSpawnPoint.y-50, {type: RANGED,item: "burstgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+250, playerSpawnPoint.y-50, {type: RANGED,item: "minigun",damage: []}));

            //test pickup for consumables and right clickable items.
            add(new Pickup(playerSpawnPoint.x, playerSpawnPoint.y, {type: CONSUMABLE, item: "DEBUGCONSUMABLE", consumable: true, consumableType: CRUMB}));
        }

        for(t in tileObjects){
            if(t==null) continue; //skip over null entries.
            t.checkNeighbors();
            if(testingState) t.editorMode(); //allow to click for information.
        }
        FlxG.worldBounds.set(0, 0, 0+(TILE_SIZE*file.size.w), 0+(TILE_SIZE*file.size.h));
        //#if (debug) Main.DEBUG_updateMapsInfo(file.size.w, file.size.h, file.tiles); #end
    }
    var tileToBeAdded:Tile;
    private inline function generateObjectViaTile(type:TileData):Tile{
        if(type==null) { //:3
            tileObjects[tileObjects.length]=null;
            return null;
        }
        tileToBeAdded = new Tile(0 + (TILE_SIZE*type.pos.row), 0+(TILE_SIZE*type.pos.colum), type.set);
        if(type.isSpecial==true){
            switch(type.specialType) {
                case SPAWN:
                    #if (debug)
                        tileToBeAdded.loadGraphic(Paths.DEBUG('entry'));
                        tileToBeAdded.color=0x7100FF00;
                    #end
                    playerSpawnPoint=FlxPoint.weak(tileToBeAdded.x, tileToBeAdded.y);
                    
                    //if the player save file dictates a different position, go there instead.
                    if(Main.saveFile.data.playerState.position.x == -1 || Main.saveFile.data.playerState.position.y == -1) {
                        targetSparnLocation = playerSpawnPoint;
                    }else{
                        targetSparnLocation = FlxPoint.weak(Main.saveFile.data.playerState.position.x, Main.saveFile.data.playerState.position.y);
                    }
                    //createElevator() 
                case WALKABLEAREA: #if (debug) tileToBeAdded.color = 0xFF00FF00; #end
                case BREAKER:
                    tileToBeAdded = new Breaker(0+(TILE_SIZE*type.pos.row), 0+(TILE_SIZE*type.pos.colum));
                    tileObjects[tileObjects.length] = tileToBeAdded;
                    tileToBeAdded.immovable = true;
                    tileToBeAdded.allowCollisions = type.collides?ANY:NONE;
                    tileToBeAdded.camera=Main.camGame;
                default: //for special types that dont really do anything. like hallway, since thats only used during generation itself.
            }
        }
        tileToBeAdded.immovable = true;
        tileToBeAdded.allowCollisions = type.collides?ANY:NONE;
        if(tileToBeAdded.allowCollisions==NONE) tileToBeAdded.alpha = 0.25;
        tileObjects[tileObjects.length]=tileToBeAdded;
        tileToBeAdded.camera=Main.camGame;
        return tileToBeAdded;
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        FlxG.watch.addQuick('player position:', plr?.getPosition());
        FlxG.watch.addQuick('word boundries:', FlxG.worldBounds);

        for(tile in tileObjects) {
            if(tile!=null) {
                tile.active=tile.alive=tile.visible=tile.isOnScreen(Main.camGame);

                if(tile.allowCollisions==ANY) {
                    for(enemy in enemies) {
                        var vx = Math.abs((enemy.x/TILE_SIZE).floor() - (tile.x/TILE_SIZE).floor());
                        var vy = Math.abs((enemy.y/TILE_SIZE).floor() - (tile.y/TILE_SIZE).floor());
                        if(vx<=COLLISION_RADIUS || vy<=COLLISION_RADIUS) FlxG.collide(enemy??null, tile);
                    }

                    var pvx = Math.abs((plr?.x/TILE_SIZE).floor() - (tile?.x/TILE_SIZE).floor());
                    var pvy = Math.abs((plr?.y/TILE_SIZE).floor() - (tile?.y/TILE_SIZE).floor());
                    if(pvx<=COLLISION_RADIUS || pvy<=COLLISION_RADIUS) {
                        FlxG.collide(plr??null, tile);
                        FlxG.collide(plr?.weapon??null, tile);
                    }

                    for(bullet in plr?.weapon.activeProjectiles) {
                        var bvx = Math.abs(Math.floor(bullet.x/TILE_SIZE) - Math.floor(tile.x/TILE_SIZE));
                        var bvy = Math.abs(Math.floor(bullet.y/TILE_SIZE) - Math.floor(tile.y/TILE_SIZE));

                        if((bvx<=COLLISION_RADIUS || bvy<=COLLISION_RADIUS) || bullet.overlaps(tile)) {
                            FlxG.collide(bullet, tile, (d1, d2)->{
                                bullet.forceRemoval();
                                var effect:FlxSprite = new FlxSprite(bullet.x, bullet.y).loadGraphic(Paths.image('fx', 'Bullet_impact'), true, 16, 16);
                                effect.animation.add('hit', [for(i in 0...5) i], 24, false, false, false);
                                effect.animation.play('hit');
                                effect.animation.onFinish.add((_)->{
                                    if(_=="hit") {
                                        effect.visible=false;
                                        Functions.wait(0.05, (_)->{
                                            remove(effect);
                                            effect.destroy();
                                            effect=null;
                                        });
                                    }
                                });
                                effect.setPosition(bullet.x-effect.width/2, bullet.y-effect.height/2);
                                FlxG.state.add(effect);
                                effect.camera=plr?.camera;
                            });
                        }
                    }
                }
            }
        }
    }
}