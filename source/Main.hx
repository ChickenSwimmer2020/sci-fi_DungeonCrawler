package;

import haxe.ui.Toolkit;
import backend.extensions.ExtendedCamera;

class Main extends openfl.display.Sprite {
    //VARIBLES
        //Flagged
            public static var controls:Map<String, Array<Int>>=Flags.DEFAULT_CONTROLS;
            public static var curLanguage(default, set):Lang=Flags.DEFAULT_LANGUAGE;
            public static final ErrorType:Map<String, Array<String>>=Flags.ERROR_MESSAGES;
        //null
            public static var curHeldItem:Null<Item>=null;
            public static var heldItemGraphic:Null<FlxSprite>=null;

    public static var InspectPopupVisible:Bool=false;
    public static var musicPostfix:String=""; //for the proto, alpha, beta, and final song version mixes.
    public static var foundMaps:Array<String> = []; //we can store all the currently found maps from the game files and mods (if implemented.)
    public static var saveFiles:Array<String> = [];

    //VARIBLES
    public function new() {
        super();
        Toolkit.init(); //init haxe-ui, this is important i think.
        FlxSprite.defaultAntialiasing=false;
        #if html5 stage.showDefaultContextMenu = false; #end
        //i hope this works.
        #if (debug)
            //yeah this probably works better.
            Application.current.window.onClose.add(()->{
                #if sys if(discord!=null){
                    discord.close();
                }#end
                #if (debug&&(windows||hl)) BUILDDEBUGLOGFILE(); #end
            });
            Application.current.window.stage.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (event:UncaughtErrorEvent) -> {
                var errorMessage:String = "An unexpected error has occurred:\n";
                if (Std.isOfType(event.error, Error)) {
                    var error:Error = cast event.error;
                    errorMessage += "${error.message}\n${error.stack}";
                } else if (Std.isOfType(event.error, String)) {
                    errorMessage += cast event.error;
                } else {
                    errorMessage += "Unknown error type.";
                }
                Application.current.window.alert(errorMessage, "Unexpected Error");
                #if (debug&&(windows||hl)) BUILDDEBUGLOGFILE(); #end
            });
        #end
        
        #if (html5) Log.throwErrors = false; #end //if an Assets. call is null, it wont crash the program.
        saveFile.bind("SAVES");
        if(saveFile.data.saves == null) { //should fix it?
            saveFile.data.saves=new Map<String, SaveFile>();
        }
        curLanguage=saveFile.data.language??EN_US; //default to EN_US if no language is specified in the save file.
        if(saveFile.data.lastLoadedSave==null) saveFile.data.lastLoadedSave=Flags.DEFAULT_SAVE;
        if(saveFile.data.lastLoadedSave!=null){
            lastLoadedSaveName=saveFile.data.lastLoadedSave;
            FILE=lastLoadedSaveName;
            saveFile.flush();
        }else FILE=Flags.DEFAULT_SAVE;
        musicPostfix = saveFile.data.musicPF??"D"; //default to default if the musicPF is null.
        Application.current.window.title = Language.languageInformation.get(curLanguage).get("application_title");
        FlxAssets.FONT_DEFAULT=switch(curLanguage){ //automatically switch the default font depending on language setting.
            case EN_US: "Nokia Cellphone FC Small";
            case JP: "assets/ui/fonts/k8x12L.ttf";
            case ES: "Nokia Cellphone FC Small";
        }

        addEventListener(Event.ENTER_FRAME, (_)->{
            Music.manualUpdate(FlxG.elapsed??0);
            Conductor.update(FlxG.elapsed??0);
            for(target => camera in cameras) {
                camera.update(FlxG.elapsed??0); //kinda forgot i have to call this manually.
                switch(target) {
                    case "game","hud","other": continue; //donothing
                    default:
                        camera.zoom = FlxMath.lerp(1, camera.zoom, Math.exp(-FlxG.elapsed??0 * 3.125 * 1 * 1));
                }
            }
        });

        Save.findSaves(); //find the save files within SAVES
        MapGenerator.findMaps(); //find the maps within SAVES
        ShaderCache.preload(); //preload shaders before loading everything to HOPEFULLY make the game run faster when shaders compile.
        //by not compiling during runtime.
        var game:flixel.FlxGame;
        game = new flixel.FlxGame(0, 0, IntroState, 60, 60, false, false);
        @:privateAccess game._customSoundTray = SoundTray;
        addChild(game);
        #if (windows||hl)
            discord = new Discord("1487613766077120724");
            discord.setActivity("IPC RICH PRESENCE TEST 01");
        #end
        initDefaultSaveParemeters();
        #if (debug&&!html5) initDebugWindows(); #end

        FlxG.autoPause = saveFile.data.autoPause??true; //default to true if not specified.
    }
    //CAMERA STUFF
    public static var cameras:Map<String,ExtendedCamera>=[];
    public static var camGame:ExtendedCamera; //access from everywhere!
    public static var camHUD:ExtendedCamera; //access from everywhere!
    public static var camOther:ExtendedCamera; //access from everywhere!
    public static function addCameraToGame(cam:ExtendedCamera, name:String, ddt:Bool=false) {
        cam.onDestroy = (camera:ExtendedCamera)->{
            cameras.remove(name);
            FlxG.cameras.remove(camera);
        };
        cameras.set(name, cam);
        FlxG.cameras.add(cam, ddt);
    }
    public static inline function clearCameraFilters(cam:FlxCamera) if(cam!=null && cam.filters!=null) for(filter in cam.filters) cam.filters.remove(filter);
    public static inline function clearAllCameraFilters() for(cam in FlxG.cameras.list) if(cam.filtersEnabled) clearCameraFilters(cam);


    //DEBUGGING
    #if (debug)
        public static var loadedTestedState:Bool=false;

        static var playerSaveWindow:Window;
        static var curSaveLoaded:TextField;
        static var healthTxt:TextField;
        static var staminaTxt:TextField;
        static var xpTxt:TextField;
        static var inventoryTxt:TextField;

        static var mapWindow:Window;
        static var saveFilesText:TextField;
        static var mapsFilesText:TextField;

        static var mapwidthText:TextField;
        static var mapheightText:TextField;
        static var mapArrayText:TextField;

        private static function initDebugWindows() {
            //map window
                mapWindow = new Window("Map", BitmapData.fromFile("assets/debug/mapWindow.png"), 500, 100, true, null, false, true);
                FlxG.debugger.windows.add(mapWindow);
                FlxG.debugger.addButton(FlxHorizontalAlign.LEFT, BitmapData.fromFile("assets/debug/mapWindow.png"), ()->{
                    mapWindow.visible = !mapWindow.visible;
                }, true);
                mapwidthText = DebuggerUtil.createTextField(0, 12 + (12*0), 0xFFFFFFFF, 12);
                mapwidthText.text = "[MAP IS NULL!]";
                mapheightText = DebuggerUtil.createTextField(0, 12 + (12*1), 0xFFFFFFFF, 12);
                mapheightText.text = "[MAP IS NULL!]";
                mapArrayText = DebuggerUtil.createTextField(0, 12 + (12*2), 0xFFFFFFFF, 12);
                mapArrayText.text = "[MAP IS NULL!]";
                mapWindow.addChild(mapwidthText);
                mapWindow.addChild(mapheightText);
                mapWindow.addChild(mapArrayText);
        
            //stored assets window.
                var storedAssetsWindow:Window;
                storedAssetsWindow = new Window("Stored Assets", BitmapData.fromFile("assets/debug/storedAssets.png"), 500, 100, true, null, false, true);
                FlxG.debugger.windows.add(storedAssetsWindow);
                FlxG.debugger.addButton(FlxHorizontalAlign.LEFT, BitmapData.fromFile("assets/debug/storedAssets.png"), ()->{
                    storedAssetsWindow.visible = !storedAssetsWindow.visible;
                }, true);
                saveFilesText = DebuggerUtil.createTextField(0, 12, 0xFFFFFFFF, 12);
                saveFilesText.text = "[NONE]";
                mapsFilesText = DebuggerUtil.createTextField(0, saveFilesText.y+saveFilesText.textHeight, 0xFFFFFFFF, 12);
                mapsFilesText.text = "[NONE]";
                storedAssetsWindow.addChild(saveFilesText);
                storedAssetsWindow.addChild(mapsFilesText);

                mapsFilesText.text = 'Maps: ${foundMaps.toString()}';
                saveFilesText.text = 'Saves: ${saveFiles.toString()}';

            //player save window
                playerSaveWindow = new Window("Player Save", BitmapData.fromFile("assets/debug/plrWindow.png"), 500, 100, true, null, false, true);
                FlxG.debugger.windows.add(playerSaveWindow);
                FlxG.debugger.addButton(FlxHorizontalAlign.LEFT, BitmapData.fromFile("assets/debug/plrWindow.png"), ()->{
                    playerSaveWindow.visible = !playerSaveWindow.visible;
                }, true);
                curSaveLoaded = DebuggerUtil.createTextField(0, 12 + (12*0), 0xFFFFFFFF, 12);
                curSaveLoaded.text = "NO SAVE LOADED!!";


                healthTxt = DebuggerUtil.createTextField(0, 12 + (12*2), 0xFFFFFFFF, 12);
                staminaTxt = DebuggerUtil.createTextField(0, 12 + (12*3), 0xFFFFFFFF, 12);
                xpTxt = DebuggerUtil.createTextField(0, 12 + (12*4), 0xFFFFFFFF, 12);
                inventoryTxt = DebuggerUtil.createTextField(0, 12 + (12*5), 0xFFFFFFFF, 12);
                //mapheightText = DebuggerUtil.createTextField(0, 12 + (12*1), 0xFFFFFFFF, 12);
                //mapheightText.text = "[MAP IS NULL!]";
                //mapArrayText = DebuggerUtil.createTextField(0, 12 + (12*2), 0xFFFFFFFF, 12);
                //mapArrayText.text = "[MAP IS NULL!]";
                playerSaveWindow.addChild(curSaveLoaded);
                playerSaveWindow.addChild(healthTxt);
                healthTxt.text = "Health: NULL";
                playerSaveWindow.addChild(staminaTxt);
                staminaTxt.text = "Stamina: NULL";
                playerSaveWindow.addChild(xpTxt);
                xpTxt.text = "XP: NULL";
                playerSaveWindow.addChild(inventoryTxt);
                inventoryTxt.text = "Inventory: [NULL]";
        }

        static var i:Int = 0;
        public static function DEBUG_updateMapsInfo(w:Int, h:Int, tiles:Array<Array<TilePointer>>) {
            mapwidthText.text = 'width: $w';
            mapheightText.text = 'height: $h';
            if(w<100){
                var tilesString:String = "";

                for(row in tiles) {
                    for(tile in row){
                        if(i==10){
                            i=0;
                            tilesString += "\n";
                        }
                        tilesString += '{${tile?.type}, ${tile?.collides}}';
                        i++;
                    }
                }
                mapArrayText.text = 'tiles: "{type, collisions}"\n$tilesString';
                
                mapWindow.height = (mapwidthText.textHeight + mapheightText.textHeight + mapArrayText.textHeight);
                mapWindow.width = mapArrayText.textWidth;
            }else mapArrayText.text = "feature disabled for performance reasons.";
        }

        public static function DEBUG_updateSaveInfo(save:String) {
            var file:SaveFile = Save.readSaveFile(save);
            curSaveLoaded.text = save;
            healthTxt.text = 'Health: ${file.health}';
            staminaTxt.text = 'Stamina: ${file.stamina}';
            xpTxt.text = 'XP: ${file.xp}';
            inventoryTxt.text = 'Inventory: ${file.inventory}';
        }
        #if(windows||hl)
            private static var OutputThread:Thread;
            public static function LOG(str:Dynamic) {
                //this is just to make it so that the console isnt freezing the game when we try to trace a fucking save file.
                if(Std.string(str).length>100) {
                    if(FlxG.log.redirectTraces) FlxG.log.add("log is longer than 100 chars. outputting directly to file."); //still fully functional.
                    else trace("log is longer than 100 chars. outputting directly to file.");
                    OutputThread = Thread.create(() -> { //apparently this auto-kills after it finishes.
                        DEBUGLOG.push(str);
                    });
                }else{
                    if(FlxG.log.redirectTraces) FlxG.log.add(str); //still fully functional.
                    else trace(str);
                    DEBUGLOG.push(str);
                }
            }
            public static var DEBUGLOG:Array<Dynamic>=[];
            public static function BUILDDEBUGLOGFILE() {
                var content:String="";
                for(line in DEBUGLOG) {
                    content += line + "\n";
                }

                var dateString:String = '${Date.now()}';
                dateString = dateString.replace(':', '-'); //replace colons with dashes to avoid issues with file naming on windows.

                
                if(!FileSystem.exists('DebugLogs')) FileSystem.createDirectory('DebugLogs');
                File.saveContent('DebugLogs/debuglog$dateString.txt', content);
            }
        #end
    #end

    //TODO: make this work, it already SOMEWHAT works, but its fucky.
    public static function set_curLanguage(value:Lang) {
        curLanguage = value;

        for(key => object in Language.activeLanguageObject) {
            trace(Type.getClass(object));
            //if(Std.isOfType(object, FlxText) || Std.isOfType(object, FlxUIText)) {
            //    var textObject:FlxText = cast object;
            //    textObject.text = Language.getTranslatedKey(key, null);
            //    textObject.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/ui/fonts/k8x12L.ttf";
            //        case ES: "Nokia Cellphone FC Small";
            //    }
            //}else if(Std.isOfType(object, FlxUIButton)) {
            //    var buttonObject:FlxButton = cast object;
            //    buttonObject.text = Language.getTranslatedKey(key, null);
            //    buttonObject.label.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/ui/fonts/k8x12L.ttf";
            //        case ES: "Nokia Cellphone FC Small";
            //    }
            //}else if(Std.isOfType(object, FlxButton)) {
            //    var buttonObject:FlxButton = cast object;
            //    buttonObject.text = Language.getTranslatedKey(key, null);
            //    buttonObject.label.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/ui/fonts/k8x12L.ttf";
            //        case ES: "Nokia Cellphone FC Small";
            //    }
            //}
            //if(Std.isOfType(object, FlxText) || (Reflect.hasField(object, "text") || (Reflect.hasField(object, "text") && Reflect.hasField(object.text, "text")))) { //if it has a text field, we can assume its a FlxText or something similar and update the text.
            //    trace(Type.getClass(object));
            //    var textObject:FlxText = cast object;
            //    textObject.text = Language.getTranslatedKey(key, null);
            //}
        }

        return value;
    }

    //hehe we can store static varibles here to be accessed EVERYWHERE.


    public static function showLanguageError(lang:Lang) {
        showError("MISSINGLANG", lang, Flags.DEFAULT_LANGUAGE);
    }
    public static function showError(input:String,?missingObject:Dynamic=null, ?forceLanguage:Lang=null) {
        @:bypassAccessor if(forceLanguage!=null)curLanguage=forceLanguage; //since we dont have language input on Language.getTranslatedKey anymore.
        var type:Array<String> = ErrorType.get(input);
        var Message:String=Language.getTranslatedKey(type[1], null, ["{OBJ}"=>missingObject]);
        var Title:String=Language.getTranslatedKey(type[0], null);
        var close:Bool=false;
        var gotomenu:Bool=false;
        if(Message.indexOf('[SHUTDOWN]')!=-1){
            close=true;
            Message = Message.remove('[SHUTDOWN]');
        }
        if(Message.indexOf('[MENU]')!=-1) {
            gotomenu=true;
            Message = Message.remove('[MENU]');
        }

        
        Application.current.window.alert(Message, Title);
        if(close){
            #if html5
                js.Browser.window.close();
            #else
                Sys.exit(1);
            #end
        }
        if(gotomenu) FlxG.switchState(()->new MainMenuState(#if(debug)false#end));
    }
    
    public static var saveFile:FlxSave = new FlxSave();
    public static var lastLoadedSaveName:Null<String>;
    public static var FILE:Null<String>;

    public static var targetCamGameZoom:Float=1.0;
    public static var camGameZoomIncrement:Float=0.0;
    #if sys public static var discord:Discord; #end
    public static function resetGlobalSettings() {
        for(setting in Reflect.fields(saveFile.data)) {
            switch(setting) {
                case "saves","lastLoadedSave","language": //donothing
                default: Reflect.setField(saveFile.data, setting, null);
            }
        }
        initDefaultSaveParemeters();
    }
    private static function initDefaultSaveParemeters() {
        if((saveFile.data.saves:Map<String,SaveFile>).get(Flags.DEFAULT_SAVE)==null){
            (saveFile.data.saves:Map<String,SaveFile>).set(Flags.DEFAULT_SAVE, Flags.DEFAULT_SAVEFILE);
        }
        if(saveFile.data.shaders==null)saveFile.data.shaders=true;
        if(saveFile.data.autoPause==null)saveFile.data.autoPause=true;
        if(saveFile.data.controls==null)saveFile.data.controls=([
            {c:"moveUP", keys:["UP", "W"]},
            {c:"moveDOWN", keys:["DOWN", "S"]},
            {c:"moveRIGHT", keys:["RIGHT", "D"]},
            {c:"moveLEFT", keys:["LEFT", "A"]},
            {c:"zoomIN", keys:["PLUS", "NONE"]},
            {c:"zoomOUT", keys:["MINUS", "NONE"]},
            {c:"pause", keys:["ESCAPE", "BACKSPACE"]},
            {c:"inventory", keys:["I", "NONE"]},
            {c:"interact", keys:["E", "ENTER"]},
            {c:"sprint", keys:["SHIFT", "NONE"]}
        ]:Array<{c:String, keys:Array<FlxKey>}>); //default init.
        if(saveFile.data.language==null)saveFile.data.language="EN_US";
    }
}