package backend.game;

class GameMap extends FlxTypedGroup<Dynamic> {
    public static var instance:GameMap;
    public static final TILE_SIZE:Int = 16; //we can avvoid MAGIC numbers
    public static final COLLISION_RADIUS:Int=2;

    public var tiles:Array<Array<TilePointer>> = []; //quick access to each tile without problems.
    public var tileObjects:Array<Array<Tile>> = [];
    public var plr:Player;
    public var enemies:Array<BaseEnemy>=[];
   
    
    public function new(file:MapFile) {
        super();
        instance=this;
        if(file!=null) tiles = file.tiles;
    }
    var playerSpawnPoint:FlxPoint=new FlxPoint();
    public function generate(?testingState:Bool=false){
        for (y in 0...tiles.length){
            tileObjects[y] = [];
            for (x in 0...tiles[y].length){
                add(generateObjectViaTile(tiles[y][x], x, y));
            }
        }
        if(!testingState){
            add(plr = new Player());
            add(new Pickup(0, 0, { //for testing.
                type: RANGED,
                item: "pistol",
                damage: []
            }));

            //var testEnemy:BaseEnemy = new BaseEnemy(playerSpawnPoint.x-32, playerSpawnPoint.y);
            //add(testEnemy);
            //testEnemy.camera=Main.camGame;

            add(generateObjectViaTile({
                type: "",
                collides: true,
                special: true,
                specialType: BREAKER
            }, Math.floor((playerSpawnPoint.x/TILE_SIZE) + 1), Math.floor((playerSpawnPoint.y/TILE_SIZE))));
            
            add(new Pickup(playerSpawnPoint.x, playerSpawnPoint.y-50, {type: RANGED,item: "pistol",damage: []}));
            add(new Pickup(playerSpawnPoint.x+50, playerSpawnPoint.y-50, {type: RANGED,item: "railgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+100, playerSpawnPoint.y-50, {type: RANGED,item: "shotgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+150, playerSpawnPoint.y-50, {type: RANGED,item: "rifle",damage: []}));
            add(new Pickup(playerSpawnPoint.x+200, playerSpawnPoint.y-50, {type: RANGED,item: "burstgun",damage: []}));
            add(new Pickup(playerSpawnPoint.x+250, playerSpawnPoint.y-50, {type: RANGED,item: "minigun",damage: []}));

            //test pickup for consumables and right clickable items.
            add(new Pickup(playerSpawnPoint.x, playerSpawnPoint.y, {type: CONSUMABLE, item: "DEBUGCONSUMABLE", consumable: true, consumableType: CRUMB}));
            plr.setPosition(playerSpawnPoint.x, playerSpawnPoint.y);
            plr.camera = Main.camGame;
        }
        
        for(row in tileObjects){
            for(tile in row){
                if(tile==null) continue;
                else @:privateAccess tile.checkNeighbors(tileObjects, Math.floor(tile.x), Math.floor(tile.y));
            }
        }
    }
    var tileToBeAdded:Tile;
    private inline function generateObjectViaTile(type:TilePointer, x:Int, y:Int):Tile{
        if(type==null) { //:3
            tileObjects[y][x] = null;
            return null;
        }
        tileToBeAdded = new Tile(0 + (TILE_SIZE*x), 0+(TILE_SIZE*y), tileObjects, type.type);
        if(type.special==true){
            switch(type.specialType) {
                case SPAWN:
                    #if (debug)
                        tileToBeAdded.loadGraphic(Paths.DEBUG('entry'));
                        tileToBeAdded.color=0x7100FF00;
                    #end
                    playerSpawnPoint=FlxPoint.weak(tileToBeAdded.x, tileToBeAdded.y);
                    //createElevator() //TODO: elevator & stuff.
                case WALKABLEAREA: #if (debug) tileToBeAdded.color = 0xFF00FF00; #end
                case BREAKER:
                    tileToBeAdded = new Breaker(0+(TILE_SIZE*x), 0+(TILE_SIZE*y), tileObjects);
                    tileToBeAdded.immovable = true;
                    tileToBeAdded.allowCollisions = type.collides?ANY:NONE;
                    tileObjects[y][x] = tileToBeAdded;
                    tileToBeAdded.camera=Main.camGame;
                default: //for special types that dont really do anything. like hallway, since thats only used during generation itself.
            }
        }
        tileToBeAdded.immovable = true;
        tileToBeAdded.allowCollisions = type.collides?ANY:NONE;
        if(tileToBeAdded.allowCollisions==NONE) tileToBeAdded.alpha = 0.25;
        tileObjects[y][x] = tileToBeAdded;
        tileToBeAdded.camera=Main.camGame;
        return tileToBeAdded;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        FlxG.watch.addQuick('player position:', plr?.getPosition());
        FlxG.watch.addQuick('word boundries:', FlxG.worldBounds);
        for(row in tileObjects){
            for(tile in row){
                if(tile!=null){
                    //the tile's active, alive, and visible state all corrispond to if they are on screen or not. good for optimization!
                    tile.active=tile.alive=tile.visible=tile.isOnScreen(Main.camGame);
                }
                if(tile!=null && tile.allowCollisions == ANY){
                    for(enemy in enemies) {
                        var vx = Math.abs(Math.floor(enemy.x/TILE_SIZE) - Math.floor(tile.x/TILE_SIZE));
                        var vy = Math.abs(Math.floor(enemy.y/TILE_SIZE) - Math.floor(tile.y/TILE_SIZE));
                        if(vx <= COLLISION_RADIUS && vy <= COLLISION_RADIUS){
                            FlxG.collide(enemy??null, tile);
                        }
                    }

                    if ((Math.abs(Math.floor(plr?.x/TILE_SIZE) - Math.floor(tile.x/TILE_SIZE))) <= COLLISION_RADIUS && (Math.abs(Math.floor(plr.y/TILE_SIZE) - Math.floor(tile.y/TILE_SIZE))) <= COLLISION_RADIUS){
                        FlxG.collide(plr??null, tile);
                        FlxG.collide(plr?.weapon, tile); //to hopefully move the weapon so it doesnt shoot through blocks
                    }
                    for(bullet in plr?.weapon.activeProjectiles) {
                        var vx = Math.abs(Math.floor(bullet.x/TILE_SIZE) - Math.floor(tile.x/TILE_SIZE));
                        var vy = Math.abs(Math.floor(bullet.y/TILE_SIZE) - Math.floor(tile.y/TILE_SIZE));
                        if(vx <= COLLISION_RADIUS && vy <= COLLISION_RADIUS){
                            //TODO: fix bullets clipping through walls
                            FlxG.collide(bullet, tile, (d1, d2)->{
                                bullet.forceRemoval();
                                var effect:FlxSprite = new FlxSprite(bullet.x, bullet.y).loadGraphic(Paths.image('fx', 'Bullet_impact'), true, 16, 16); //TODO: real graphic
                                effect.animation.add('hit', [0,1,2,3,4,5], 24, false, false, false);
                                effect.animation.play('hit');
                                effect.animation.onFinish.add((_)->{
                                    if(_=='hit') effect.destroy();
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