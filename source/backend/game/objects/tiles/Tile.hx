package backend.game.objects.tiles;

class Tile extends FlxSprite {
    public var checkedNeighbors:Bool=false;
    public var bulletCollisionRect:FlxRect;
    public var curImage:String="";
    final mapTiles:Map<String, Map<String, Int>> = [
        "fuck" => [
            "debug"=>0,
            "debug2"=>1,
            "fuck"=>2,
            "cock"=>3,
            "penis :3"=>4
        ],
        "placeholder"=>[
            "none"=>0,
            "all"=>1,
            "left/right"=>2,
            "up/down"=>3,
            "left/down"=>4,
            "right/down"=>5,
            "left/up"=>6,
            "right/up"=>7,
            "left/right/up"=>8,
            "left/right/down"=>9,
            "up/down/left"=>10,
            "up/down/right"=>11,
            "up"=>12,
            "down"=>13,
            "left"=>14,
            "right"=>15,
        ]
    ];

    private var inEditorMode:Bool = false;
    public inline function editorMode() inEditorMode = !inEditorMode;
    public function new(x:Int, y:Int, tileMap:String) {
        super(x, y);
        makeGraphic(1, 1, 0x00FFFFFF); //forgot to make the graphic before overriding it.
        if(tileMap!=null && tileMap!="") initTileGraphic(tileMap); //just dont make any graphic if its empty, because it probably gets overridden with a proper graphic somewhere else
    }
    public function checkNeighbors() {
        var allTiles:Array<Tile> = GameMap.instance.tileObjects;

        function solid(x:Int, y:Int):Bool {
            var allTiles = GameMap.instance.tileObjects;
            var mapW = GameMap.file.size.w;
            var mapH = GameMap.file.size.h;

            // Compute this tile's grid position from world position
            var col = Std.int(this.x / GameMap.TILE_SIZE);
            var row = Std.int(this.y / GameMap.TILE_SIZE);

            var newCol = col + x;
            var newRow = row + y;

            // Bounds check
            if (newCol < 0 || newCol >= mapW) return false;
            if (newRow < 0 || newRow >= mapH) return false;

            // Convert back to index
            var newIndex = newRow * mapW + newCol;

            var neighbor = allTiles[newIndex];

            // Only connect to same-type tiles
            return neighbor != null && neighbor.curImage == this.curImage;
        }


        var k:String = '${(solid(0, -1)?"U":"")}${(solid(0, 1)?"D":"")}${(solid(-1, 0)?"L":"")}${(solid(1, 0)?"R":"")}';
        var suround:String = switch(k) {
            case "UDLR": "all";
            case "U": "up";
            case "L": "left";
            case "R": "right";
            case "D": "down";
            case "LR": "left/right";
            case "UD": "up/down";
            case "DL": "left/down";
            case "DR": "right/down";
            case "UL": "left/up";
            case "UR": "right/up";
            case "ULR": "left/right/up";
            case "DLR": "left/right/down";
            case "UDL": "up/down/left";
            case "UDR": "up/down/right";
            default: "none";
        }

        if(mapTiles.get(curImage)==null) {
            Main.Trace(ERROR, 'tile at index ${allTiles.indexOf(this)} has no tile map for image $curImage');
            animation.add(k, [mapTiles.get("placeholder").get("none")], 30);
            animation.play(k);
            checkedNeighbors = true;
            return;
        }

        animation.add(k, [mapTiles.get(curImage==""?"placeholder":curImage).get(suround??"none")], 30);
        animation.play(k);
        checkedNeighbors = true;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(inEditorMode && !Main.loadedTestedState) {
            if(FlxG.mouse.overlaps(this, Main.camGame) && FlxG.mouse.justPressedRight) {
                var myNotif:Notification = new Notification();
                myNotif.notificationData = {
                    title: "Info",
                    body: 'Tile at X/Y ${x}/${y} with surround: ${animation.name}',
                    type: NotificationType.Info,
                    expiryMs: 3000
                };
                @:privateAccess NotificationManager.instance.pushNotification(myNotif);
                Timer.delay(function () {
                    myNotif.left = 20;
                    myNotif.top = (Screen.instance.height-20) - myNotif.height;
                }, 15);
            }
        }
    }
    
    private function initTileGraphic(image:String) {
        curImage=image;
        loadGraphic(Paths.tiles(curImage), true, 16, 16);
        if(bulletCollisionRect!=null){
            bulletCollisionRect.destroy();
            bulletCollisionRect = new FlxRect(width/2, height/2, width/2, height/2); //not sure if thisll work
        }else{
            bulletCollisionRect = new FlxRect(width/2, height/2, width/2, height/2);
        }
    }
}