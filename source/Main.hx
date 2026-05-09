package;

import haxe.PosInfos;
import haxe.CallStack;
import haxe.ui.Toolkit;
import backend.extensions.ExtendedCamera;

#if(debug)
    enum TRACETYPES {
        INFO;
        ERROR;
        WARN;
        DEBUG;
        TODO;

        //special circumstances.
        EG; //ONLY used for Relocation_Failed Easter eggs.
    }
#end

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
        #if html5 stage.showDefaultContextMenu = false; #end
        //i hope this works.
        #if (debug)
            //yeah this probably works better.
            #if(windows||hl)Application.current.window.onClose.add(()->discord!=null?discord.close():null);#end
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
        
        #if (html5) //if an Assets. call is null, it wont crash the program.
            Log.throwErrors = false;
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
        #else
            saveFile.readSaveFile("testSave");
        #end
        musicPostfix = #if(windows||hl)saveFile.data.preferences.musicPF??"D"#else saveFile.data.musicPF??"D"#end; //default to default if the musicPF is null.
        Application.current.window.title = Language.languageInformation.get(curLanguage).get("application_title");
        FlxAssets.FONT_DEFAULT=switch(curLanguage){ //automatically switch the default font depending on language setting.
            case EN_US: "Nokia Cellphone FC Small";
            case JP: "assets/fonts/k8x12L.ttf";
            case ES: "Nokia Cellphone FC Small";
        }

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
        ShaderCache.preload(); //preload shaders before loading everything to HOPEFULLY make the game run faster when shaders compile.
        //by not compiling during runtime.
        var game:flixel.FlxGame;
        game = new flixel.FlxGame(0, 0, IntroState, 60, 60, false, false);
        @:privateAccess game._customSoundTray = SoundTray;
        addChild(game);
        #if (windows||hl)
            //discord = new Discord("1487613766077120724"); //TODO: fix this.
            //discord.setActivity("IPC RICH PRESENCE TEST 01");
        #end
        initDefaultSaveParemeters();
        #if (debug&&!html5) initDebugWindows(); #end

        #if(windows||hl) //default to true if not specified.
            FlxG.autoPause = saveFile.data.preferences.autoPause??true;
        #else
            FlxG.autoPause = saveFile.data.autoPause??true; 
        #end
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
    public static inline function flashCameras(color:Int, time:Float) for(cam in FlxG.cameras.list) if(#if(windows||hl)saveFile.data.preferences.flashingLights#else saveFile.data.flashingLights#end) cam.flash(color, time);

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

        public static function Trace(type:TRACETYPES, message:Dynamic, ?p:PosInfos) {
            #if html5
                var label:String;
                var style:String;
                var resetStyle = "color: unset; background: unset; font-weight: normal;";
                switch(type) {
                    case INFO:  label = "[- INFO -]:";  style = "color: #4488ff; font-weight: bold;";
                    case ERROR: label = "[- ERROR -]:"; style = "color: #ff4444; font-weight: bold;";
                    case WARN:  label = "[- WARN -]:";  style = "color: #ffcc00; font-weight: bold;";
                    case DEBUG: label = "[- DEBUG -]:"; style = "color: #44ff44; font-weight: bold;";
                    case TODO:  label = "[- TODO -]:";  style = "color: #000000; background: #ffa500; font-weight: bold;";
                    case EG:    label = "[- R_F--EASTER EGG!!! -]:"; style = "color: #0000ff; background: #ff0000; font-weight: bold;";
                    default:    js.Syntax.code("console.log({0})", message); return;
                }
                js.Syntax.code("console.log('%c' + {0} + '%c ' + {1} + ' (' + {2} + ' line ' + {3} + ')', {4}, {5})",
                    label, message, p.fileName, p.lineNumber, style, resetStyle);
            #else
                switch(type) {
                    case INFO:  trace('\x1b[34m[- INFO -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    case ERROR: trace('\x1b[31m[- ERROR -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    case WARN:  trace('\x1b[33m[- WARN -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    case DEBUG: trace('\x1b[32m[- DEBUG -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    case TODO:  trace('\033[48;2;255;165;0m[- TODO -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    case EG:    trace('\033[38;2;0;0;255m\033[48;2;255;0;0m[- R_F--EASTER EGG!!! -]:\x1b[0m $message (${p.fileName} line ${p.lineNumber})');
                    default:    trace(message);
                }
            #end
        }

        #if(windows||hl)

        #else //uses old system.
            public static function DEBUG_updateSaveInfo(save:String) {
                var file:SaveFile = Save.readSaveFile(save);
                curSaveLoaded.text = save;
                healthTxt.text = 'Health: ${file.health}';
                staminaTxt.text = 'Stamina: ${file.stamina}';
                xpTxt.text = 'XP: ${file.xp}';
                inventoryTxt.text = 'Inventory: ${file.inventory}';
            }
        #end
    #end

    public static function set_curLanguage(value:Lang) {
        curLanguage = value;

        for(key => object in Language.activeLanguageObject) {
            Trace(DEBUG, Type.getClass(object));
            //if(Std.isOfType(object, FlxText) || Std.isOfType(object, FlxUIText)) {
            //    var textObject:FlxText = cast object;
            //    textObject.text = Language.getTranslatedKey(key, null);
            //    textObject.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/fonts/k8x12L.ttf";
            //        case ES: "Nokia Cellphone FC Small";
            //    }
            //}else if(Std.isOfType(object, FlxUIButton)) {
            //    var buttonObject:FlxButton = cast object;
            //    buttonObject.text = Language.getTranslatedKey(key, null);
            //    buttonObject.label.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/fonts/k8x12L.ttf";
            //        case ES: "Nokia Cellphone FC Small";
            //    }
            //}else if(Std.isOfType(object, FlxButton)) {
            //    var buttonObject:FlxButton = cast object;
            //    buttonObject.text = Language.getTranslatedKey(key, null);
            //    buttonObject.label.font = switch(curLanguage){
            //        case EN_US: "Nokia Cellphone FC Small";
            //        case JP: "assets/fonts/k8x12L.ttf";
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
        if(close) #if(html5)js.Browser.window.close();#else Sys.exit(1);#end
        if(gotomenu) FlxG.switchState(MainMenuState.new);
    }
    
    public static var saveFile:#if(windows||hl)Save = new Save(); #else FlxSave = new FlxSave();#end
    public static var lastLoadedSaveName:Null<String>;
    public static var FILE:Null<String>;

    public static var targetCamGameZoom:Float=1.0;
    public static var camGameZoomIncrement:Float=0.0;
    #if(windows||hl) public static var discord:Discord; #end
    public static function resetGlobalSettings() {
        for(setting in Reflect.fields(saveFile.data)) {
            switch(setting) {
                case "saves","lastLoadedSave","language","controls": //donothing
                default: Reflect.setField(saveFile.data, setting, null);
            }
        }
        initDefaultSaveParemeters();
    }
    private static function initDefaultSaveParemeters() {
        #if(windows||hl) 
            saveFile.initDefaults();
        #else
            if(saveFile.data.flashingLights==null)saveFile.data.flashingLights=true;
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
        #end
    }
}