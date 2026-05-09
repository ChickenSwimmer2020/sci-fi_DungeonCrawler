package debugging.ui.cc;

import haxe.ui.core.Component;
import haxe.ui.components.Label;
import haxe.ui.components.Image;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.SideBar;
using haxe.ui.animation.AnimationTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/CutsceneEditor.xml"))
class MainView extends VBox {
    public var onObjectCreate:(type:Class<Dynamic>,x:Float,y:Float,name:String,path:String,isNested:Bool,grpName:String)->Void;
    public function new() {
        super();
        doLanguageStuff();

        menuBar.onMenuSelected = (e:MenuEvent)->{
            switch(e.menuItem.id) {
                case "QuitEditor": FlxG.switchState(Debugger.new);

                case "ToggleUIDarkMode": Flags.CC_DARKMODE=!Flags.CC_DARKMODE; //toggle it
                default: Main.Trace(WARN, 'unkown id type: ${e.menuItem.id}');
            }
        };
        addNewCutsceneObject.onClick=(_)->ObjectCreationDialogObject();

        TL_AddLayer.onClick = (_:MouseEvent)->{
            var idInput:String = "text";
            var labl:Label = new Label();
            labl.text = idInput;
            labl.percentWidth=100;
            labl.height=20;
            var l:Layer = new Layer(idInput); //we can always do stuff with this later.

            TL_LayerNamesList.addComponent(labl);
            TL_KFArea.addComponent(l);
        };
        
        menuBar.onMenuClosed = (_:MenuEvent)->{ //assign that when the menuBar is closed to relaod all the total frames properly
            Main.Trace(DEBUG, _.menu.text);
            if(_.menu.text=="Meta"){
                reloadFramesTotal(menuBar.findComponent("TOTALFRAMESINPUT", HUITextField, true, "id").text.toInt());
                menuBarOpen=false;
            }
        };
        menuBar.onMenuOpened=(_:MenuEvent)->{menuBarOpen=true;};
        reloadFramesTotal(menuBar.findComponent("TOTALFRAMESINPUT", HUITextField, true, "id").text.toInt()); //then just run this anyways.
        //TimeLineKFScroller.isScrollableHorizontally=false; //dont allow for the main scroll that shows layers to horizontally scroll.
    }
    var menuBarOpen:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(menuBarOpen && menuBar.findComponent('TOTALFRAMESINPUT', HUITextField, true, "id").focus) { //if the textfield is focused, and the menuBar is opened, if enter is pressed, automatically update the total frames of the cutscene.
            if(FlxG.keys.justPressed.ENTER) {
                reloadFramesTotal(menuBar.findComponent("TOTALFRAMESINPUT", HUITextField, true, "id").text.toInt());
            }
        }
    }

    public function reloadFramesTotal(f:Int) {
        var display:HBox = TL_FrameRuler;
        display.removeAllComponents(); //get rid of all the current labels.
        for(i in 0...f) {
            var l:Label = new Label();
            l.text = '${i+1}|    '; //technically, its 0-{f-1}, but we can fix that right up!
            display.addComponent(l);
        }
    }

    private function ObjectCreationDialogObject(?item:Dynamic, ?forceType:Int=null) {
        var dialog = new MyCustomDialog();
        dialog.onDialogClosed=(e:DialogEvent)->{
            Main.Trace(INFO, e.button);
            switch(e.button.toString().toUpperCase()) {
                case "ADD":
                    if (item == null) item = ActiveCutsceneObjects;
                    switch(forceType!=null?forceType:dialog.tabs.pageIndex) {
                        case 0: //Sprite
                        #if(!html5)
                            if(!FileSystem.exists(dialog.findComponent("SPR_Path", HUITextField, true, "id").text)) {
                                NotificationManager.instance.addNotification({
                                    title: "Error!",
                                    body: '${dialog.findComponent("SPR_Path", HUITextField, true, "id").text}\nDoes not exist!',
                                    type: NotificationType.Error
                                });
                                return; //prolly gonna close it :/
                            }else{
                                var n:TreeViewNode = item.addNode(
                                    {
                                        name: dialog.findComponent("SPR_Name", HUITextField, true, "id").text,
                                        path: dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                        icon: "assets/debug/cc_spriteObject.png"
                                    }
                                );
                                n.onClick = (_:MouseEvent)->{
                                    Main.Trace(INFO, 'to add name: ${n.data.name} returned: ${CutsceneMaker.instance.trackedUIObjects.get(n.data.name)}');
                                    if(CutsceneMaker.instance.trackedUIObjects.get(n.data.name)!=null) {
                                        CutsceneMaker.instance.trackedUIObjects.get(n.data.name).flash(0xFF7D7DFF);
                                    }
                                };
                                if(onObjectCreate!=null) onObjectCreate(
                                    FlxSprite, Std.parseFloat(dialog.findComponent("SPR_X", HUITextField, true, "id").text), //class, x
                                    Std.parseFloat(dialog.findComponent("SPR_Y", HUITextField, true, "id").text), //y
                                    dialog.findComponent("SPR_Name", HUITextField, true, "id").text, //name
                                    dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                    false, ""
                                );
                            }
                        #else
                            if(!Assets.exists(dialog.findComponent('SPR_Path', HUITextField, true, "id").text)) {
                                NotificationManager.instance.addNotification({
                                    title: "Error!",
                                    body: '${dialog.findComponent("SPR_Path", HUITextField, true, "id").text}\nDoes not exist!',
                                    type: NotificationType.Error
                                });
                                return; //prolly gonna close it :/
                            }else{
                                var n:TreeViewNode = item.addNode(
                                    {
                                        name: dialog.findComponent("SPR_Name", HUITextField, true, "id").text,
                                        path: dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                        icon: "assets/debug/cc_spriteObject.png"
                                    }
                                );
                                n.onClick = (_:MouseEvent)->{
                                    Main.Trace(INFO, 'to add name: ${n.data.name} returned: ${CutsceneMaker.instance.trackedObjects.get(n.data.name)}');
                                    if(CutsceneMaker.instance.trackedObjects.get(n.data.name)!=null) {
                                        CutsceneMaker.instance.trackedUIObjects.get(n.data.name).flash(0xFF7D7DFF);
                                    }
                                };
                                if(onObjectCreate!=null) onObjectCreate(
                                    FlxSprite, Std.parseFloat(dialog.findComponent("SPR_X", HUITextField, true, "id").text), //class, x
                                    Std.parseFloat(dialog.findComponent("SPR_Y", HUITextField, true, "id").text), //y
                                    dialog.findComponent("SPR_Name", HUITextField, true, "id").text, //name
                                    dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                    false, ""
                                );
                            }
                        #end
                        case 1: //Text
                            var n:TreeViewNode = item.addNode(
                                {
                                    name: dialog.findComponent("TXT_Name", HUITextField, true, "id").text,
                                    path: dialog.findComponent("TXT_Text", HUITextField, true, "id").text,
                                    icon: "assets/debug/cc_textObject.png"
                                }
                            );
                            n.onClick = (_:MouseEvent)->{
                                Main.Trace(INFO, 'to add name: ${n.data.name} returned: ${CutsceneMaker.instance.trackedUIObjects.get(n.data.name)}');
                                //if(CutsceneMaker.instance.trackedUIObjects.get(n.data.name)!=null) {
                                    CutsceneMaker.instance.trackedUIObjects.get(n.data.name).flash(0xFF7D7DFF);
                                //}
                            };
                            if(onObjectCreate!=null) onObjectCreate(
                                FlxText, Std.parseFloat(dialog.findComponent("TXT_X", HUITextField, true, "id").text), //class, x
                                Std.parseFloat(dialog.findComponent("TXT_Y", HUITextField, true, "id").text), //y
                                dialog.findComponent("TXT_Name", HUITextField, true, "id").text, //name
                                dialog.findComponent("TXT_Text", HUITextField, true, "id").text,
                                false, ""
                            );
                        case 2: //Group
                            // pre-set up stuff, so that we can account for errors before trying to make something that shouldnt exist.
                            var tItem:haxe.ui.core.Component = cast item;
                            Main.Trace(DEBUG, '${tItem.screenTop} && ${tItem.height}');
                            var toAdd:Dynamic={};

                            switch(dialog.findComponent("GRP_IOT", DropDown, true, "id").text) {
                                case "Sprite":
                                    #if(!html5)
                                        if(!FileSystem.exists(dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").text)) {
                                            NotificationManager.instance.addNotification({
                                                title: "Error!",
                                                body: '${dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").text}\nDoes not exist!',
                                                type: NotificationType.Error
                                            });
                                            return; //prolly gonna close it :/
                                        }else{
                                            toAdd =
                                                {
                                                    name: dialog.findComponent("GRP_IO_Name", HUITextField, true, "id").text,
                                                    path: dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").text,
                                                    icon: "assets/debug/cc_spriteObject.png"
                                                };
                                        }
                                    #end
                                case "Text":
                                    toAdd =
                                        {
                                            name: dialog.findComponent("GRP_IO_Name", HUITextField, true, "id").text,
                                            path: dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").text,
                                            icon: "assets/debug/cc_textObject.png"
                                        };
                                default: Main.Trace(WARN, 'unknown type ${dialog.findComponent("GRP_IOT", DropDown, true, "id").text}, this is a bad thing.');
                            }


                            var i:TreeViewNode = item.addNode({text: 'Group: ${dialog.tabs.getPageById("tab_groupmode").getComponentAt(0).text}', icon: "haxeui-core/styles/default/haxeui_tiny.png", count: 0});
                            var internal = i.addNode(toAdd);

                            //item.onClick = (_:MouseEvent)->{
                            //    trace('to add name: ${toAdd.name} returned: ${CutsceneMaker.instance.trackedObjects.get(toAdd.name)}');
                            //    if(CutsceneMaker.instance.trackedObjects.get(toAdd.name)!=null) {
                            //        CutsceneMaker.instance.trackedUIObjects.get(toAdd.name).flash(0xFF7D7DFF);
                            //    }
                            //};
                            item.onRightClick = (e:MouseEvent)->{
                                var obj = new FlxObject(tItem.screenLeft, tItem.screenTop, 300, 600);
                                if (FlxG.mouse.overlaps(obj)) {
                                    var menu = new MyMenu();
                                    menu.left = e.screenX + 1;
                                    menu.top = e.screenY + 1;
                                    Screen.instance.addComponent(menu);
                                    menu.onSelect=(_:String)->{
                                        switch(_) {
                                            case "addToGroup": ObjectCreationDialogObject(item);
                                            case "delete": Main.Trace(DEBUG, "FUCKR, NOOOOOOOOOO!!!!!");
                                            default: Main.Trace(DEBUG, 'no');
                                        }
                                    };
                                }
                                obj.destroy();
                            }

                        default: Main.Trace(ERROR, 'unknown tab, this is a bad thing.');
                    }



                    //var root1 = ActiveCutsceneObjects.addNode({ text: "root A", icon: "haxeui-core/styles/default/haxeui_tiny.png", count: 5 });
                    //var child = root1.addNode({ text: "child A-4", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 3, checked: Std.random(2) == 0 });
                default: return;
            }
        }
        //var typedropdown:DropDown = cast ;
        dialog.findComponent("GRP_IOT", DropDown, true, "id").onChange = function(e:UIEvent) {
            switch(dialog.findComponent("GRP_IOT", DropDown, true, "id").selectedItem.id) {
                case "SPR": dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").placeholder = "Path";
                case "TXT": dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").placeholder = "Text";
                default: dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").placeholder = "Error!";
            }
        };
        dialog.showDialog();
    }

    private function doLanguageStuff() {
        //-------------
        //   menubar
        //-------------
        File.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.title", null); 
        NewCutscene.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.newcutscene", null);
        LoadCutscene.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.loadcutscene", null);
        SaveCutscene.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.savecutscene", null);
        SaveCutsceneSEPERATE.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.savecutsceneas", null);
        QuitEditor.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.file.quiteditor", null);

        Meta.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.meta.title", null);
        MetaFPS.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.meta.fps", null);
        MetaTF.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.meta.tf", null);

        Os.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.onionskinning.title", null);
        OnionSkinToggle.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.onionskinning.enabled", null);
        OsPreFrames.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.onionskinning.preframes", null);
        OsPostFrames.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.onionskinning.postframes", null);

        View.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.view.title", null);
        ToggleUIDarkMode.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.view.tdarkmode", null);

        
        PlayCutscene.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.play", null);
        TestCutscene.text = Language.getTranslatedKey("debugger.cutscenemaker.menubar.test", null);

        //-------------
        //   objects
        //-------------
        objectsFrame.text = Language.getTranslatedKey("debugger.cutscenemaker.objects.frame.label", null);
        addNewCutsceneObject.text = Language.getTranslatedKey("debugger.cutscenemaker.objects.frame.button", null);

        //-------------
        //   timeline
        //-------------
        TL_Label.text = Language.getTranslatedKey("debugger.cutscenemaker.timeline.label", null);
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/Cutscene_PropertiesEditor.xml"))
class MySideBar1 extends SideBar {
    public function new() {
        super();
        width = 250;
        percentHeight = 100;
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/Cutscene_ObjectContextMenu.xml"))
class MyMenu extends Menu {
    public var onSelect:String->Void; //for actually making this menu do stuff properly.
    public function new() {
        super();

        onMenuSelected = (e:MenuEvent)->{
            Main.Trace(INFO, e.menuItem.id);
            if(onSelect!=null) onSelect(e.menuItem.id);
        };
    }
}

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/Cutscene_AddNewObject.xml"))
class MyCustomDialog extends Dialog {
    public function new() {
        super();
        buttons = DialogButton.CANCEL | "Add";
    }
}