package backend.game.objects;

class Tile extends FlxSprite {
    public static var curImage:String="";
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
        ]
    ];
    public function new(x:Int, y:Int, tiles:Array<Array<Tile>>, tileMap:String) {
        super(x, y);
        makeGraphic(1, 1, 0x00FFFFFF); //forgot to make the graphic before overriding it.
        if(tileMap!="") initTileGraphic(tileMap); //just dont make any graphic if its empty, because it probably gets overridden with a proper graphic somewhere else
    }
    private function checkTile(tiles:Array<Array<Tile>>, x:Int, y:Int):{a:Bool, t:Tile}{
        if(tiles[y]==null) return {a:false, t:null};
        return tiles[y][x]!=null?{a: true, t:tiles[y][x]}:{a:false, t:null};
    }
    public var suround:String="";
    //soo, i wanted to fix this. and i think claude might have cooked.
    private function checkNeighbors(tiles:Array<Array<Tile>>, row:Int, col:Int) {
        var x = Math.floor(row / 16);
        var y = Math.floor(col / 16);

        // Helper to check if a tile is solid
        inline function solid(dx:Int, dy:Int):Bool
            return checkTile(tiles, x + dx, y + dy).a;

        // Cardinal neighbors
        var up    = solid( 0, -1);
        var down  = solid( 0,  1);
        var left  = solid(-1,  0);
        var right = solid( 1,  0);

        // Corners only count if BOTH adjacent cardinals are solid
        var tl = (up && left)  && solid(-1, -1);
        var tr = (up && right) && solid( 1, -1);
        var bl = (down && left)  && solid(-1,  1);
        var br = (down && right) && solid( 1,  1);

        // Encode as bitmask: up=1, down=2, left=4, right=8, tl=16, tr=32, bl=64, br=128
        var mask:Int = 0;
        if (up)    mask |= 1;
        if (down)  mask |= 2;
        if (left)  mask |= 4;
        if (right) mask |= 8;
        if (tl)    mask |= 16;
        if (tr)    mask |= 32;
        if (bl)    mask |= 64;
        if (br)    mask |= 128;

        suround = switch(mask) {
            case 0xFF:          "all";
            case 0x0C:          "left/right";
            case 0x03:          "up/down";
            case 0x06:          "left/down";
            case 0x0A:          "right/down";
            case 0x05:          "left/up";
            case 0x09:          "right/up";
            case 0x0D:          "left/right/up";
            case 0x0E:          "left/right/down";
            case 0x07:          "up/down/left";
            case 0x0B:          "up/down/right";
            default:            "none";
        }

        frame = frames.getByIndex(
            mapTiles.get(curImage == "" ? "placeholder" : curImage)
                    .get(suround ?? "none")
        );
    }
    
    private function initTileGraphic(image:String) {
        curImage=image;
        frames = FlxTileFrames.fromGraphic(FlxG.bitmap.add(Paths.tiles(curImage)), FlxPoint.get(16, 16), null, FlxPoint.weak(1, 1));
    }
}