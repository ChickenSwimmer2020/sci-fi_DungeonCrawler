package backend.game.objects;

import flixel.graphics.frames.FlxTileFrames;
import backend.generation.MapGenerator.TilePointer; //because important.

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
    private function checkNeighbors(tiles:Array<Array<Tile>>, row:Int, colum:Int){
        var xPosition:Int=0;
        var yPosition:Int=0;
        xPosition=Math.floor(row/16);
        yPosition=Math.floor(colum/16);
        

        var checkCorners:Bool = ((checkTile(tiles, xPosition-1, yPosition-1).a && checkTile(tiles, xPosition+1, yPosition-1).a) && (checkTile(tiles, xPosition-1, yPosition+1).a && checkTile(tiles, xPosition+1, yPosition+1).a));
        var surroundedBy:{TPL:Bool,TP:Bool,TPR:Bool,BTL:Bool,BT:Bool,BTR:Bool,LFT:Bool,RGT:Bool}={
            TPL: checkCorners?checkTile(tiles, xPosition-1, yPosition-1).a:false,
            TP:  checkTile(tiles, xPosition, yPosition-1).a,
            TPR: checkCorners?checkTile(tiles, xPosition+1, yPosition-1).a:false,

            LFT: checkTile(tiles, xPosition-1, yPosition).a,
            RGT: checkTile(tiles, xPosition+1, yPosition).a,

            BTL: checkCorners?checkTile(tiles, xPosition-1, yPosition+1).a:false,
            BT:  checkTile(tiles, xPosition, yPosition+1).a,
            BTR: checkCorners?checkTile(tiles, xPosition+1, yPosition+1).a:false,
        };
        switch(surroundedBy) {
            case {TPL:true,TP:true,TPR:true,BTL:true,BT:true,BTR:true,LFT:true,RGT:true}:suround="all";
            default: suround="none";

            case {TPL:false,TP:false,TPR:false,BTL:false,BT:false,BTR:false,LFT:true,RGT:true}:suround="left/right";

            case {TPL:false,TP:true,TPR:false,BTL:false,BT:true,BTR:false,LFT:false,RGT:false}:suround="up/down";

            case {TPL:false,TP:false,TPR:false,BTL:false,BT:true,BTR:false,LFT:true,RGT:false}:suround="left/down";
            case {TPL:false,TP:false,TPR:false,BTL:false,BT:true,BTR:false,LFT:false,RGT:true}:suround="right/down";

            case {TPL:false,TP:true,TPR:false,BTL:false,BT:false,BTR:false,LFT:true,RGT:false}:suround="left/up";
            case {TPL:false,TP:true,TPR:false,BTL:false,BT:false,BTR:false,LFT:false,RGT:true}:suround="right/up";

            case {TPL:false,TP:true,TPR:false,BTL:false,BT:false,BTR:false,LFT:true,RGT:true}:suround="left/right/up";
            case {TPL:false,TP:false,TPR:false,BTL:false,BT:true,BTR:false,LFT:true,RGT:true}:suround="left/right/down";

            case {TPL:false,TP:true,TPR:false,BTL:false,BT:true,BTR:false,LFT:true,RGT:false}:suround="up/down/left";
            case {TPL:false,TP:true,TPR:false,BTL:false,BT:true,BTR:false,LFT:false,RGT:true}:suround="up/down/right";
        }
        if(checkTile(tiles, xPosition, yPosition+1).t?.suround.contains('/up') && checkTile(tiles, xPosition, yPosition-1).t?.suround.contains('/down')) suround="up/down"; //if im correct, i can force states like this!
        frame = frames.getByIndex(mapTiles.get(curImage==""?"placeholder":curImage).get(suround??"none"));
        //trace(tiles); //will take forever, but i just want to make sure that the tile gets the tiles around it.
    }
    
    private function initTileGraphic(image:String) {
        curImage=image;
        frames = FlxTileFrames.fromGraphic(FlxG.bitmap.add(Paths.tiles(curImage)), FlxPoint.get(16, 16), null, FlxPoint.weak(1, 1));
    }
}