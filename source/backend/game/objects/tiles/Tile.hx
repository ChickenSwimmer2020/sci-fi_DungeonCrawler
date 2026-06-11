package backend.game.objects.tiles;

class Tile extends FlxSprite {
    public var bulletCollisionRect:FlxRect;
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
    public function new(x:Int, y:Int, tileMap:String) {
        super(x, y);
        makeGraphic(1, 1, 0x00FFFFFF); //forgot to make the graphic before overriding it.
        if(tileMap!=null && tileMap!="") initTileGraphic(tileMap); //just dont make any graphic if its empty, because it probably gets overridden with a proper graphic somewhere else
    }
    private function checkNeighbors() {
        //donothing for now. TODO: make this work
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