package backend.game.objects.tiles;

class SpecialTile extends Tile {
    public static var optionsMenuOpenOnAnyTile:Bool=false;
    public var tileName:String="";
    public static final INTERACTION_RANGE:Int = 4; //in tiles.
    public var playerWithinRange:Bool=false;
    public var options:Map<String, Void->Void>=[];

    private var rightclickOptionsOpen:Bool=true;
    private static var specialTileTextHoverbox:FlxText;
    public function new(x:Int,y:Int,tiles:Array<Array<Tile>>) {
        super(x, y, tiles, "");
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        optionsMenuOpenOnAnyTile = rightclickOptionsOpen;

        if(specialTileTextHoverbox == null && FlxG.state!=null) {
            specialTileTextHoverbox = new FlxText(0, 0, 0, "", 12, true);
            specialTileTextHoverbox.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
            specialTileTextHoverbox.visible=false;
            specialTileTextHoverbox.camera = Main.camOther;
            FlxG.state.add(specialTileTextHoverbox);
        }

        playerWithinRange=(
            (Math.abs(Math.floor(GameMap.instance.plr?.x/GameMap.TILE_SIZE) - Math.floor(x/GameMap.TILE_SIZE))) <= INTERACTION_RANGE
            &&(Math.abs(Math.floor(GameMap.instance.plr?.y/GameMap.TILE_SIZE) - Math.floor(y/GameMap.TILE_SIZE))) <= INTERACTION_RANGE);

        if(rightclickOptionsOpen){
            if(specialTileTextHoverbox.visible) specialTileTextHoverbox.visible = false;
            if(buttonsOverlapRect!=null && !buttonsOverlapRect.containsPoint(FlxG.mouse.getViewPosition(Main.camOther)) || FlxG.keys.justPressed.ANY){ 
                openOptions(); //close if ANY input happens.
            }
        }else{
            if(playerWithinRange && FlxG.mouse.overlaps(this, Main.camGame)) {
                if(!specialTileTextHoverbox.visible) specialTileTextHoverbox.visible = true;
                specialTileTextHoverbox.setPosition(FlxG.mouse.x, FlxG.mouse.y);
                specialTileTextHoverbox.text = tileName;
                if(FlxG.mouse.justPressedRight) {
                    openOptions();
                }
            }else {
                if(specialTileTextHoverbox.visible) specialTileTextHoverbox.visible = false;
            }
        }
        FlxG.mouse.visible = !specialTileTextHoverbox.visible;
    }
    var buttonsOverlapRect:FlxRect;
    var buttons:Array<FlxButton>=[];
    var counter:Int=0;
    private function openOptions() {
        rightclickOptionsOpen=!rightclickOptionsOpen;
        counter=0;
        if(rightclickOptionsOpen) {
            buttonsOverlapRect = new FlxRect(FlxG.mouse.x, FlxG.mouse.y, 80, 0);
            for(label => func in options) {
                var button:FlxButton = new FlxButton(FlxG.mouse.x, FlxG.mouse.y+(20*counter), label, ()->{
                    func();
                    openOptions(); //auto-close.
                });
                buttons.push(button);
                button.camera = Main.camOther;
                FlxG.state.add(button);
                counter++;
                buttonsOverlapRect.height += 20;
            }
        }else{  
            for(button in buttons) {
                FlxG.state.members.remove(button);
                button.destroy();
                button = null;
            }
            if(buttonsOverlapRect!=null){
                buttonsOverlapRect.destroy();
                buttonsOverlapRect = null;
            }
        }
    }

    override public function destroy() {
        for(button in buttons) {
            FlxG.state.members.remove(button);
            button.destroy();
            button = null;
        }
        if(buttonsOverlapRect!=null){
            buttonsOverlapRect.destroy();
            buttonsOverlapRect = null;
        }
        FlxG.state.members.remove(specialTileTextHoverbox);
        specialTileTextHoverbox.destroy();
        specialTileTextHoverbox = null;
        super.destroy();
    }
}