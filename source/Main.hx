package;

import haxe.macro.Context.Message;
import backend.Language;
import states.MainMenuState;
import lime.app.Application;
import backend.ShaderCache;
import flixel.FlxCamera;

//enum abstract ErrorType(String) from String to String{
//    var TEST="window title###message box";
//    var IOERROR="error.nullio###The object{OBJ}couldnt be loaded.";
//    var RENDERFAILURE="error.renderfailure###error.renderfailure.message";
//    var SAVENOTCACHED="error.cachefault###The save file{OBJ}could not be loaded as it was not found in memory.\nTo fix this error, please plase the .SAV in assets/saves\nand restart the game.";
//    var MISSINGLANG="error.languagemissing###The language file for{OBJ}could not be loaded.\nLanguage files are essential for game execution.\nThe program will close shortly.[SHUTDOWN]";
//}

class Main extends openfl.display.Sprite {
    public static var curLanguage:Lang=EN_US;
    public static final ErrorType:Map<String, Array<String>>=[
        "TEST"=>["window title", "message box"],
        "IOERROR"=>["error.nullio", "error.nullio.message"],
        "RENDERFAILURE"=>["error.renderfailure", "error.renderfailure.message"],
        "SAVENOTCACHED"=>["error.cachefault", "error.cachefault.message"],
        "MISSINGLANG"=>["error.languagemissing", "error.languagemissing.mesage"],
        "MISSINGMAP"=>["error.mapnotfound", "error.mapnotfound.message"],
        "NULLITEM"=>["error.nullitem", "error.nullitem.message"],
    ];
    //hehe we can store static varibles here to be accessed EVERYWHERE.
    public static var foundMaps:Array<String> = []; //we can store all the currently found maps from the game files and mods (if implemented.)
    public static var saveFiles:Array<String> = [];

    #if debug public static var loadedTestedState:Bool=false; #end
    public static var camGame:FlxCamera; //access from everywhere!
    public static var camHUD:FlxCamera; //access from everywhere!
    public static var camOther:FlxCamera; //access from everywhere!
    #if debug
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
    #end

    public static function showLanguageError(lang:Lang) {
        showError("MISSINGLANG", lang, EN_US);
    }
    public static function showError(input:String,?missingObject:Dynamic=null, ?forceLanguage:Lang=null) {
        var type:Array<String> = ErrorType.get(input);
        var Message:String=Language.getTranslatedErrorMessage(forceLanguage??Main.curLanguage, missingObject, type[1]);
        var Title:String=Language.getTranslatedKey(forceLanguage??Main.curLanguage, type[0]);
        var close:Bool=false;
        var gotomenu:Bool=false;
        if(Message.indexOf('[SHUTDOWN]')!=-1){
            close=true;
            Message.graft('[SHUTDOWN]');
        }
        if(Message.indexOf('[MENU]')!=-1) {
            gotomenu=true;
            Message.graft('[SHUTDOWN]');
        }

        
        Application.current.window.alert(Message, Title);
        if(close) Sys.exit(1);
        if(gotomenu) FlxG.switchState(MainMenuState.new);
    }

    public function new() {
        super();
        trace('checking for missing filepaths and generating missing paths...');
        if(!FileSystem.exists('${Paths.savePath}')) FileSystem.createDirectory(Paths.savePath);

        Save.findSaves(); //load save files located into memory.
        MapGenerator.findMaps(); //load map files into memory.

        
        ShaderCache.preload(); //preload shaders before loading everything to HOPEFULLY make the game run faster when shaders compile.
        //by not compiling during runtime.
        addChild(new flixel.FlxGame(0, 0, MainMenuState, 60, 60, false, false));
        #if debug initDebugWindows(); #end
    }
}