package debugging;

import lime.text.Font;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.containers.windows.WindowManager;
import debugging.ui.MainView.DebuggerMainView;

/**
 * every. single. debugger.
 * minus of course: CutsceneMaker, GameDebugger
 * CutsceneMaker is its own thing, and GameDebugger requires GameState access.
 */
class Debugger extends FlxState {
    var mainView:DebuggerMainView;
    var mang:WindowManager;
    public function new() {
        super();
        add(mainView = new DebuggerMainView());
        mainView.mapEditorOpen.onClick = (_:MouseEvent)->FlxG.switchState(MapDebugger.new);
        mainView.cutsceneEditorOpen.onClick = (_:MouseEvent)->FlxG.switchState(CutsceneMaker.new);

        getErrorsTester(); //populate the errors tester dropdown with the errors from Main.
        
        mang = new WindowManager();
        mang.container = mainView;
        mainView.windowListA.windowManager = mang;
        mainView.saveReader = ()->{
            var window = new SaveDebuggerWindow(Main.saveFiles);
            window.left = 10;
            window.top = 80;
            mang.addWindow(window);
        };
        //mainView.saveWriter = ()->{
        //    var window = new SaveDebuggerEditorWindow(Main.saveFiles);
        //    window.left = 10;
        //    window.top = 80;
        //    mang.addWindow(window);
        //};
        mainView.alphabetViewer = ()->{
            var window = new AlphabetViewerWindow();
            window.left = 10;
            window.top = 80;
            mang.addWindow(window);
        };
    }

    private function getErrorsTester() {
        var em:Menu = mainView.errorMenu;
        var errorTextinout:HUITextField = new HUITextField();
        errorTextinout.id = "errInOut";
        errorTextinout.placeholder=Language.getTranslatedKey("debugger.menubar.error.reftext", null);
        errorTextinout.text="DEBUG";
        em.addComponent(errorTextinout);
        var errorShouldFollowTags:MenuCheckBox = new MenuCheckBox();
        errorShouldFollowTags.text = Language.getTranslatedKey("debugger.menubar.error.followtags", null);
        em.addComponent(errorShouldFollowTags);
        for(name => errorDatas in Main.ErrorType) { //this is dynamic based on how many errors are actually implemented.
            var i:MenuItem = new MenuItem();
            i.id = name;
            i.text = Language.getTranslatedKey(errorDatas[0], null);
            em.addComponent(i);
        }
        em.addComponent(new MenuSeparator()); //should work?
        em.onMenuSelected = (e:MenuEvent)->{
            var targetError:String = e.menuItem.id; //yeah the ID is the error's internal register. bite me.
            if(targetError==null||targetError=="null"){
                //Functions.wait(0.01, (_)->{ TODO: find way to make this not close when the checkbox is clicked.
                //    em.show(); //should re-open it
                //    em._menu.dispatch(new UIEvent(UIEvent.CLOSE));
                //});
                //em.dispatch(new MouseEvent(MouseEvent.CLICK)); //automatically drop it back down, because the only thing that can be selected is a checkbox.
                return; //doesnt matter, shouldnt do anything in the first place lol.
            }
            if(Main.ErrorType.get(targetError)!=null) {
                Main.showError(targetError, errorTextinout.text==""?"NULL":errorTextinout.text, null, "", (errorShouldFollowTags.value is Bool)?errorShouldFollowTags.value:false); //validation to make sure the checkbox is actually a bool.
            }else{
                NotificationManager.instance.addNotification({
                    title: Language.getTranslatedKey("debugger.notif.error.title", null),
                    body: Language.getTranslatedKey("debugger.notif.error.nullerr", null, ["[T]"=>targetError]),
                    type: NotificationType.Error
                });
            }
        };
    }

    var textBoxSelected:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        textBoxSelected = Functions.anyTrue([mainView.errorMenu.findComponent("errInOut", HUITextField, true, "id").focus]);

        if(!textBoxSelected && FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(MainMenuState.new);
        }
    }
}

//------------------------------------------
//              SAVE DEBUGGING
//------------------------------------------
@:xml('
<window title="Save Reader" width="350">
    <window-title width="100%">
        <dropdown id="savesDropdown" width="100"/>
    </window-title>

    <tree-view id="properties" width="100%" height="100%" styleName="full-width">
        <item-renderer layout="horizontal" width="100%">
            <label id="text" verticalAlign="center" width="100%" />
        </item-renderer>
    </tree-view>    
</window>
')
class SaveDebuggerWindow extends haxe.ui.containers.windows.Window {
    public function new(saves:Array<String>){
        super();
        title=Language.getTranslatedKey("debugger.windows.save.reader", null);
        for(save in saves) {
            savesDropdown.dataSource.add(save);
        }
        savesDropdown.onChange = (_:UIEvent)->{
            Main.Trace(INFO, 'Selected: ${savesDropdown.selectedItem}');
            properties.clearNodes();

            var targetSave:SaveFile;
            #if(windows||hl)
                targetSave = Main.saveFile.data;
            #else
                targetSave = (Main.saveFile.data.saves:Map<String,SaveFile>).get(savesDropdown.selectedItem);
            #end
            for(field in Reflect.fields(targetSave)) { //maps are handled WAY differently between HTML5 and windows.
                switch(field) {
                    default: properties.addNode({text: '$field => ${Reflect.getProperty(targetSave, field)}'});
                }
            }
        }
    }
}
//@:xml('
//<window title="Save Editor" width="350">
//    <window-title width="100%">
//        <dropdown id="savesDropdown" width="100"/>
//    </window-title>
//
//    <tree-view id="properties" width="100%" height="100%" styleName="full-width">
//        <item-renderer layout="horizontal" width="100%">
//            <label id="text" verticalAlign="center" width="100%" />
//            <image resource="assets/ui/menu/icon_reassign" id="butt" verticalAlign="right" width="15%" />
//        </item-renderer>
//    </tree-view>    
//</window>
//')
//class SaveDebuggerEditorWindow extends haxe.ui.containers.windows.Window {
//    public function new(saves:Array<String>) {
//        super();
//        title=Language.getTranslatedKey("debugger.windows.save.editor", null);
//        for(save in saves) {
//            savesDropdown.dataSource.add(save);
//        }
//        savesDropdown.onChange = (_:UIEvent)->{
//            Main.Trace(DEBUG, 'Selected: ${savesDropdown.selectedItem}');
//            properties.clearNodes();
//
//            var targetSave:SaveFile;
//            #if(windows||hl)
//                targetSave = Main.saveFile.data;
//            #else
//                targetSave = (Main.saveFile.data.saves:Map<String,SaveFile>).get(savesDropdown.selectedItem);
//            #end
//            final targetFields:Array<String>=[
//                "meta", "health", "stamina", "xp", "position", "inventory"
//            ];
//            for(property in targetFields) {
//                var node:TreeViewNode = properties.addNode({text: '$property => ${Reflect.getProperty(targetSave, property)}'});
//                node.onClick = (_:MouseEvent)->{
//                    var dialog = new SaveDebuggerEditorEditPopup(savesDropdown.selectedItem, property);
//                    dialog.onDialogClosed = function(e:DialogEvent) {
//                        if(e.button.toString().toUpperCase()=="{{APPLY}}") {
//                            var propertyToChange:Dynamic = Reflect.getProperty(targetSave, property);
//                            if(propertyToChange is Int) {
//                                Reflect.setProperty(targetSave, property, dialog.toChange.text.toInt());
//                            }else if(propertyToChange is Float) {
//                                Reflect.setProperty(targetSave, property, dialog.toChange.text.toFloat());
//                            }else if(propertyToChange is String) {
//                                Reflect.setProperty(targetSave, property, dialog.toChange.text);
//                            }else{
//                                Main.Trace(WARN, 'no clue what the property class is :/ $property]');
//                            }
//                            #if(windows||hl)
//                                Main.saveFile.flush();
//                            #else
//                                Save.writeSaveFile(); //should automatically save everything properly, hopefully.
//                            #end
//                            savesDropdown.dispatch(new UIEvent(UIEvent.CHANGE, false, null)); //actually, i think thisll work.
//                        }
//                    }
//                    dialog.showDialog();
//                    Main.Trace(INFO, 'hehehehaw! ($property)');
//                };
//            }
//            var node = properties.addNode({text: 'maps => ${if(targetSave.maps!=null)"populated"else"empty"}'});  
//            node.onClick = (_:MouseEvent)->{
//                Main.Trace(INFO, 'hehehehaw! (maps)');
//            };
//        }
//    }
//}
//@:xml('
//  <dialog id="diaroot" width="500" height="200" title="DEBUG LOLZ">
//      <textfield id="toChange" width="100%" height="100%" placeholder="Value" />
//  </dialog>
//')
//class SaveDebuggerEditorEditPopup extends Dialog {
//    var o:String;
//    var p:String;
//    public function new(obj:String, property:String) {
//        super();
//        buttons = DialogButton.CANCEL | DialogButton.APPLY;
//        title = '"$obj": Enter New Value for: $property';
//
//        o = obj;
//        p = property;
//    }
//}
//------------------------------------------
//                ALPHABET
//------------------------------------------
@:xml('
    <window title="AlphabetViewer" width="350" height="500">
        <window-title width="100%">
            <dropdown id="langdropdown" width="100"/>
        </window-title>

        <!--<scrollview width="100%" height="100%">-->
            <label id="fontShower" width="100%" height="100%"/>
        <!--</scrollview>-->
    </window>
')
class AlphabetViewerWindow extends haxe.ui.containers.windows.Window {
    public function new() {
        super();
        title = Language.getTranslatedKey("debugger.windows.alphabet.title", null);
        final availableLanguages:Array<String>=[ //yeah we're just gonna do it like this regardless of platform, unlike how the settings substate does it.
            "EN_US", "JP"
        ];
        final availableLanguagesLables:Array<String>=[
            "English (US)", "Japanese"
        ];
        for(lang in availableLanguagesLables){
            langdropdown.dataSource.add(lang);
        }
        var targetFont:String=FlxAssets.FONT_DEFAULT;
        langdropdown.onChange = (e:UIEvent)->{
            fontShower.text="";
            Main.Trace(INFO, 'Chose Language: ${langdropdown.dataSource.get(langdropdown.selectedIndex)}');
            switch(langdropdown.dataSource.get(langdropdown.selectedIndex)) {
                case "English (US)": targetFont=FlxAssets.FONT_DEFAULT; //should load default flixl font?
                case "Japanese": targetFont=Paths.font('k8x12L.ttf');
                default: //donothing.
            }
            //fontShower.getTextDisplay().tf.font = targetFont; //should actually hopefully work.
            var i:Int = 0;
            var t:String = Language.getTranslatedKey("debugger.windows.alphabet.charmap", null);
            var tt:String="";

            final CHARSPERLINE:Int=26;
            for(c in 0...t.length){
                var char:String = t.charAt(c);
                tt+=char;
                if(i==CHARSPERLINE-1){
                    tt+='\n';
                    i=0;
                }else i++;
            }
            fontShower.applyStyle({
                fontName: targetFont
            });
            fontShower.text=tt;
        }
    }
}