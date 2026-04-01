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
            "up"=>12,
            "down"=>13,
            "left"=>14,
            "right"=>15,
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
    private function checkNeighbors(tiles:Array<Array<Tile>>, row:Int, col:Int) {
        var x = Math.floor(row / 16);
        var y = Math.floor(col / 16);

        inline function solid(dx:Int, dy:Int):Bool return checkTile(tiles, x + dx, y + dy).a;

        var up    = solid( 0, -1);
        var down  = solid( 0,  1);
        var left  = solid(-1,  0);
        var right = solid( 1,  0);
        var key = (up?"U":"") + (down?"D":"") + (left?"L":"") + (right?"R":"");

        suround = switch(key) {
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

        frame=frames.getByIndex(mapTiles.get(curImage==""?"placeholder":curImage).get(suround??"none"));
    }
    
    private function initTileGraphic(image:String) {
        curImage=image;
        frames = FlxTileFrames.fromGraphic(FlxG.bitmap.add(Paths.tiles(curImage)), FlxPoint.get(16, 16), null, FlxPoint.weak(1, 1));
    }
}