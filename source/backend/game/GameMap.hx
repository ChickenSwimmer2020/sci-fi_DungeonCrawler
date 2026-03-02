package backend.game;

class GameMap extends FlxTypedGroup<Dynamic> {
    public static final TILE_SIZE:Int = 16; //we can avvoid MAGIC numbers
    public static final COLLISION_RADIUS:Int=2;

    public var tiles:Array<Array<TilePointer>>; //quick access to each tile without problems.
    public var tileObjects:Array<Array<Tile>> = [];
    public var plr:Player;
   
    
    public function new(file:MapFile) {
        super();
        tiles = file.tiles;
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
    private inline function generateObjectViaTile(type:TilePointer, x:Int, y:Int){
        if(type==null) { //:3
            tileObjects[y][x] = null;
            return null;
        }
        var tile:Tile = new Tile(0 + (TILE_SIZE*x), 0+(TILE_SIZE*y), tileObjects, type.type);
        tile.immovable = true;
        tile.allowCollisions = type.collides?ANY:NONE;
        if(tile.allowCollisions==NONE) tile.alpha = 0.25;
        tileObjects[y][x] = tile;
        tile.camera=Main.camGame;

        if(type.special==true){
            switch(type.specialType) {
                case SPAWN:
                    #if (debug)
                        tile.loadGraphic(Paths.DEBUG('entry'));
                        tile.color=0x7100FF00;
                    #end
                    playerSpawnPoint=FlxPoint.weak(tile.x, tile.y);
                    //createElevator() //TODO: elevator & stuff.
                case WALKABLEAREA: #if (debug) tile.color = 0xFF00FF00; #end
                default: //for special types that dont really do anything. like hallway, since thats only used during generation itself.
            }

        }
        return tile;
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
                                var effect:FlxSprite = new FlxSprite(bullet.x, bullet.y).makeGraphic(5, 5, 0xFFFFFFFF); //TODO: real graphic
                                effect.setPosition(bullet.x-effect.width/2, bullet.y-effect.height/2);
                                FlxG.state.add(effect);
                                effect.camera=plr?.camera;
                                new FlxTimer().start(0.5, (_)->{ //TODO until animation length
                                    effect.destroy();
                                    _.destroy();
                                });
                            });
                        }
                    }
                }
            }
        }
    }
}