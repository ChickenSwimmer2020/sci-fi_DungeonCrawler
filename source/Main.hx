package;

enum TRACETYPES {
    INFO;
    ERROR;
    WARN;
    DEBUG;
    TODO;

    //special circumstances.
    EG; //ONLY used for Relocation_Failed Easter eggs.
}

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
        Toolkit.theme = "dark";
        FlxSprite.defaultAntialiasing=false;
        //i hope this works.
        #if (debug)
            //yeah this probably works better.
            //Application.current.window.onClose.add(()->discord!=null?discord.close():null);
            Application.current.window.onClose.add(
                ()->{
                    trace('closing lol.');
                }
            );
            
            Application.current.window.stage.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, (event:UncaughtErrorEvent) -> { //TODO: make this work, tis supposed to be a "crash handler".
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
            });
        #end
        Preferences.readPrefsFile();

        if(FileSystem.exists(Paths.save(Preferences.getPref("lastLoadedSave")))) {
            saveFile.readSaveFile(Preferences.getPref("lastLoadedSave"));
        }
        
        curLanguage = Preferences.getPref('language');
        musicPostfix = Preferences.getPref('musicPF');// saveFile.data.preferences.musicPF??"D"; //default to default if the musicPF is null.
        controls = Preferences.getControls();
        Application.current.window.title = Language.languageInformation.get(curLanguage).get("application_title");
        

        addEventListener(Event.ENTER_FRAME, (_)->{
            Music.manualUpdate(FlxG.elapsed??0);
            Conductor.update(FlxG.elapsed??0);
            for(target => camera in cameras) {
                camera.update(FlxG.elapsed??0); //kinda forgot i have to call this manually.
                //switch(target) {
                //    case "game","hud","other": continue; //donothing
                //    default:
                //        camera.zoom = FlxMath.lerp(1, camera.zoom, Math.exp(-FlxG.elapsed??0 * 3.125 * 1 * 1));
                //}
            }
        });

        Save.findSaves(); //find the save files within SAVES
        MapGenerator.findMaps(); //find the maps within SAVES
        var startState:InitialState = IntroState;
        //by not compiling during runtime.
        var game:flixel.FlxGame;
        if(Preferences.getPref("precacheShaders")) startState = ShaderCache;
        game = new flixel.FlxGame(0, 0, startState, 60, 60, false, false);
        @:privateAccess game._customSoundTray = SoundTray;
        addChild(game);
        #if(windows)
            
        #end
        #if (windows||hl)
            //discord = new Discord("1487613766077120724"); //TODO: fix this.
            //discord.setActivity("IPC RICH PRESENCE TEST 01");
        #end
        #if (debug) initDebugWindows(); #end

        FlxG.autoPause = Preferences.getPref('autoPause')??true;
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
    public static inline function flashCameras(color:Int, time:Float) for(cam in FlxG.cameras.list) if(Preferences.getPref('flashingLights')) cam.flash(color, time);

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
        public static function DEBUG_updateMapsInfo(w:Int, h:Int, tiles:Array<TileData>) {
            mapwidthText.text = 'width: $w';
            mapheightText.text = 'height: $h';
            if(w<100){
                var tilesString:String = "";

                for(tile in tiles) {
                    if(i==10) {
                        i=0;
                        tilesString+='\n';
                    }
                    tilesString += '{${tile?.set}, ${tile?.collides}}';
                    i++;
                }
                mapArrayText.text = 'tiles: "{type, collisions}"\n$tilesString';
                
                mapWindow.height = (mapwidthText.textHeight + mapheightText.textHeight + mapArrayText.textHeight);
                mapWindow.width = mapArrayText.textWidth;
            }else mapArrayText.text = "feature disabled for performance reasons.";
        }

        public static function DEBUG_updateSaveInfo(save:String) {
            Trace(WARN, "This function is in the process of being rewritten");
            //var file:SaveFile = Save.readSaveFile(save);
            //curSaveLoaded.text = save;
            //healthTxt.text = 'Health: ${file.health}';
            //staminaTxt.text = 'Stamina: ${file.stamina}';
            //xpTxt.text = 'XP: ${file.xp}';
            //inventoryTxt.text = 'Inventory: ${file.inventory}';
        }
    #end

    public static function set_curLanguage(value:Lang) {
        curLanguage = value;
        FlxAssets.FONT_DEFAULT=switch(curLanguage){ //automatically switch the default font depending on language setting.
            case EN_US: "Nokia Cellphone FC Small";
            case JP: "assets/fonts/k8x12L.ttf";
            case ES: "Nokia Cellphone FC Small";
            default: "Nokia Cellphone FC Small";
        }
        ExtendedText.globalFont = FlxAssets.FONT_DEFAULT;

        Flags.VERSION_PREFIX = Language.getTranslatedKey("menu.vprefix", null);
        return value;
    }

    //hehe we can store static varibles here to be accessed EVERYWHERE.
    public static function Trace(type:TRACETYPES, message:Dynamic, ?p:PosInfos) {
        switch(type) {
            case INFO:  Sys.println('\x1b[34m[- INFO -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            case ERROR: Sys.println('\033[48;2;255;0;0m[- ERROR -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            case WARN:  Sys.println('\x1b[33m[- WARN -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            case DEBUG: Sys.println('\x1b[32m[- DEBUG -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            case TODO:  Sys.println('\033[48;2;255;165;0m[- TODO -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            case EG:    Sys.println('\033[38;2;0;0;255m\033[48;2;255;0;0m[- R_F--EASTER EGG!!! -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
            default:    Sys.println(message);
        }
    }

    public static function showLanguageError(lang:Lang, stack:String) {
        showError("MISSINGLANG", lang, Flags.DEFAULT_LANGUAGE, stack);
    }
    public static function showError(input:String,?missingObject:Dynamic=null, ?forceLanguage:Lang=null, stack:String, followTags:Bool=true) {
        @:bypassAccessor if(forceLanguage!=null)curLanguage=forceLanguage; //since we dont have language input on Language.getTranslatedKey anymore.
        var type:Array<String> = ErrorType.get(input);
        var Message:String=Language.getTranslatedKey(type[1], null, ["{OBJ}"=>missingObject, "{STK}"=>stack.toString()]);
        var Title:String=Language.getTranslatedKey(type[0], null);
        var close:Bool=false;
        var gotomenu:Bool=false;
        if(Message.indexOf('[SHUTDOWN]')!=-1){
            if(followTags){
                close=true;
                Message = Message.remove('[SHUTDOWN]');
            }else{
                Message = Message.replace('[SHUTDOWN]', '\nGame should shut down');
            }
        }
        if(Message.indexOf('[MENU]')!=-1) {
            if(followTags){
                gotomenu=true;
                Message = Message.remove('[MENU]');
            }else{
                Message = Message.replace('[MENU]', '\nGame should go to MainMenuState');
            }
        }

        
        Application.current.window.alert(Message, Title);
        if(close) Sys.exit(1);
        if(gotomenu) FlxG.switchState(()->new MainMenuState(false));
    }
    
    public static var saveFile:Save = new Save();
    public static var lastLoadedSaveName:Null<String>;
    public static var FILE:Null<String>;

    public static var targetCamGameZoom:Float=1.0;
    public static var camGameZoomIncrement:Float=0.0;
    public static var discord:Discord;
    public static function resetGlobalSettings() {
        return false; //TODO: this
    }
}