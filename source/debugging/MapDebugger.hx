package debugging;

#if (debug)
class MapDebugger extends FlxUIState{
    var mainView:MapEditorView;
    var map:GameMap;
    var uiCam:ExtendedCamera;

    var posText:FlxText;
    var MapPreview:FlxRect;

    var crosshair:FlxText;
    public function new() {
        super();
        GameState.generateCameras(); //give us the Main.camGame cameras access so that we can actually do testing of the map without worrying about cameras failure.
        Main.camGame.width = Main.camHUD.width = Main.camOther.width = (FlxG.width.getPercentage(75)).floor();
        Main.camGame.x = Main.camHUD.x = Main.camOther.x = (FlxG.width.getPercentage(25));
        Main.camGame.bgColor = 0x59FF00FF;
        uiCam = new ExtendedCamera(0, 0, (FlxG.width.getPercentage(25)).floor(), FlxG.height, 1);
        FlxG.cameras.add(uiCam, false);
        add(mainView = new MapEditorView());
        mainView.camera = uiCam;
        MapPreview = new FlxRect(Main.camGame.x, Main.camGame.y, Main.camGame.width, Main.camGame.height);

        Main.Trace(DEBUG, 'Main.camGame: ${Main.camGame.width}/${Main.camGame.height} -- ${Main.camGame.x}/${Main.camGame.y}');
        Main.Trace(DEBUG, 'Main.camHUD: ${Main.camHUD.width}/${Main.camHUD.height} -- ${Main.camHUD.x}/${Main.camHUD.y}');
        Main.Trace(DEBUG, 'Main.camOther: ${Main.camOther.width}/${Main.camOther.height} -- ${Main.camOther.x}/${Main.camOther.y}');
        

        map = new GameMap(null);
        map.camera = Main.camGame;
        add(map);

        mainView.focusonplr.onClick = (_)->Main.camGame.focusOn(FlxPoint.weak(map.plr.x, map.plr.y));

        mainView.generate_btn.onClick = (_)->{
            remove(map);
            map.destroy();
            map = MapGenerator.createMap("", MapGenerator.generateMap(mainView.wstepper.value, mainView.hstepper.value, 0, true), true);
            add(map);
            Player.instance.testingMode = true;
            crosshair.x = ((((FlxG.width.getPercentage(75).floor()))/2)-(crosshair.width/2));
            crosshair.y = ((FlxG.height/2)-(crosshair.height/2));
        };

        posText = new FlxText(0, 0, 0, "X/Y: [X], [Y]");
        add(posText);
        posText.camera = Main.camOther;

        crosshair = new FlxText(0, 0, 15, "+", 8, true);
        crosshair.camera = Main.camOther;
        crosshair.x = ((((FlxG.width.getPercentage(75).floor()))/2)-(crosshair.width/2));
        crosshair.y = ((FlxG.height/2)-(crosshair.height/2));
        add(crosshair);
        Main.Trace(INFO, 'crosshair: ${crosshair.x}/${crosshair.y}');
    }
    private var offsetX:Float = 0;
    private var offsetY:Float = 0;
    private var isDragging:Bool = false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        //READING_textInputOther.visible = READING_textInputOther.active = (tabs_radio_1.selectedId=="OTHER"||tabs_radio_1.selectedId=="INVENTORY");
        if (Main.camGame != null && (FlxG.mouse.justPressed && MapPreview.containsPoint(FlxG.mouse.getPosition()))) 
        {
            isDragging = true;
            offsetX = FlxG.mouse.viewX;
            offsetY = FlxG.mouse.viewY;
        }
        crosshair.visible = mainView.editor_crosshair_toggle.selected;
        // Stop dragging
        if (FlxG.mouse.justReleased) isDragging = false;

        if (isDragging) {
            var dx = FlxG.mouse.viewX - offsetX;
            var dy = FlxG.mouse.viewY - offsetY;

            Main.camGame.scroll.x -= dx / Main.camGame.zoom;
            Main.camGame.scroll.y -= dy / Main.camGame.zoom;

            offsetX = FlxG.mouse.viewX;
            offsetY = FlxG.mouse.viewY;
        }

        
        Main.camGame.follow(mainView.editor_camera_followplayer.selected?map.plr:null, LOCKON);
        Main.camGame.zoom+=(FlxG.mouse.wheel/10); //mouse wheel zoom control.
        Main.camGame.zoom = ((Main.camGame.zoom/100)*100); //floating point precision fix.

        posText.text = 'X/Y: ${Main.camGame.scroll.x}, ${Main.camGame.scroll.y}\nOFFSET: $offsetX, $offsetY\nZOOM: ${Main.camGame.zoom}';
        

        if(FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(Debugger.new);
    }

    override public function destroy() {
        FlxG.cameras.remove(uiCam);
        Player.instance.testingMode = false; //since it wants to be dumb.
        GameState.degenerateCameras();
        super.destroy();
    }
}
@:xml('
    <hbox width="25%" height="100%">
        <vbox width="100%" height="100%">
            <hbox width="100%" height="5%">
                <label style="font-size:20px;" id="labelText" width="85%"/>
                <button width="15%" height="100%" id="helpBtn" text="?"/>
            </hbox>
            <label style="font-size:20px;" id="leaveText" width="100%"/>

            <frame text="Camera" collapsible="true" width="100%" height="5%">
                <hbox width="100%" height="100%">
                    <button width="100%" height="100%" id="focusonplr" text="focus on player"/>
                </hbox>
            </frame>
            <frame text="Generation" width="100%" collapsible="true" height="10%">
            <vbox width="100%" height="100%">
                <hbox width="100%" height="50%">
                    <number-stepper id="wstepper" pos="30" width="33%" height="100%"/>
                    <number-stepper id="hstepper" pos="30" width="33%" height="100%"/>
                    <button id="generate_btn" text="generate" width="33%" height="100%"/>
                </hbox> 

                <hbox width="100%" height="50%">
                    <label text="width: [NUM]" width="33%" height="100%"/>
                    <label text="height: [NUM]" width="33%" height="100%"/>
                    <label text="tiles: [NUM]" width="33%" height="100%"/>
                </hbox> 
            </vbox>


            </frame>
            <frame text="Settings" width="100%" collapsible="true" height="90%">
                <vbox width="100%" height="100%">
                    <frame text="Editor" collapsible="true" width="100%" height="50%">
                        <vbox width="100%" height="100%">
                            <checkbox id="editor_crosshair_toggle" text="CrossHair" selected="true" tooltip="Toggle wether to show the crosshair.\nHelps with zooming the map preview."/>
                            <checkbox id="editor_camera_followplayer" text="Follow Player" tooltip="Toggle wether the camera should follow the player."/>
                            <checkbox text="Checkbox 3A"/>
                            <checkbox text="Checkbox 4A"/>
                        </vbox>
                    </frame>
                    <frame text="Generator" collapsible="true" width="100%" height="50%">
                        <vbox width="100%" height="100%">
                            <checkbox text="Checkbox 1B"/>
                            <checkbox text="Checkbox 2B"/>
                            <checkbox text="Checkbox 3B"/>
                            <checkbox text="Checkbox 4B"/>
                        </vbox>
                    </frame>
                </vbox> 
            </frame>
        </vbox>
    </hbox>
')
private class MapEditorView extends HBox {
    public function new() {
        super();

        labelText.text = Language.getTranslatedKey("debugger.map.title", null, []);
        leaveText.text = Language.getTranslatedKey("debugger.genericexit", null, ["[EXITKEY]"=>"BACKSPACE"]);
    }
}
#end