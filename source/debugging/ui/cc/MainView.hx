package debugging.ui.cc;

import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.containers.SideBar;

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/CutsceneEditor.xml"))
class MainView extends VBox {
    public var onObjectCreate:(type:Class<Dynamic>,x:Float,y:Float,name:String,path:String,isNested:Bool,grpName:String)->Void;
    public function new() {
        super();

        menuBar.onMenuSelected = (e:MenuEvent)->{
            switch(e.menuItem.id) {
                case "QuitEditor": FlxG.switchState(()->new MainMenuState(false));

                case "ToggleUIDarkMode": Flags.CC_DARKMODE=!Flags.CC_DARKMODE; //toggle it
                default: trace('unkown id type: ${e.menuItem.id}');
            }
        };
        addNewCutsceneObject.onClick=(_)->ObjectCreationDialogObject();





    }

    private function ObjectCreationDialogObject(?item:Dynamic, ?forceType:Int=null) {
        var dialog = new MyCustomDialog();
        dialog.onDialogClosed=(e:DialogEvent)->{
            trace(e.button);
            switch(e.button.toString().toUpperCase()) {
                case "ADD":
                    if (item == null) item = ActiveCutsceneObjects;
                    switch(forceType!=null?forceType:dialog.tabs.pageIndex) {
                        case 0: //Sprite
                            if(!FileSystem.exists(dialog.findComponent("SPR_Path", HUITextField, true, "id").text)) {
                                NotificationManager.instance.addNotification({
                                    title: "Error!",
                                    body: '${dialog.findComponent("SPR_Path", HUITextField, true, "id").text}\nDoes not exist!',
                                    type: NotificationType.Error
                                });
                                return; //prolly gonna close it :/
                            }else{
                                item.addNode(
                                    {
                                        name: dialog.findComponent("SPR_Name", HUITextField, true, "id").text,
                                        path: dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                        icon: "assets/debug/cc_spriteObject.png"
                                    }
                                );
                                if(onObjectCreate!=null) onObjectCreate(
                                    FlxSprite, Std.parseFloat(dialog.findComponent("SPR_X", HUITextField, true, "id").text), //class, x
                                    Std.parseFloat(dialog.findComponent("SPR_Y", HUITextField, true, "id").text), //y
                                    dialog.findComponent("SPR_Name", HUITextField, true, "id").text, //name
                                    dialog.findComponent("SPR_Path", HUITextField, true, "id").text,
                                    false, ""
                                );
                            }
                        case 1: //Text
                            item.addNode(
                                {
                                    name: dialog.findComponent("TXT_Name", HUITextField, true, "id").text,
                                    path: dialog.findComponent("TXT_Text", HUITextField, true, "id").text,
                                    icon: "assets/debug/cc_textObject.png"
                                }
                            );
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
                            trace('${tItem.screenTop} && ${tItem.height}');
                            var toAdd:Dynamic={};

                            switch(dialog.findComponent("GRP_IOT", DropDown, true, "id").text) {
                                case "Sprite":
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
                                case "Text":
                                    toAdd =
                                        {
                                            name: dialog.findComponent("GRP_IO_Name", HUITextField, true, "id").text,
                                            path: dialog.findComponent("GRP_IO_TextPath", HUITextField, true, "id").text,
                                            icon: "assets/debug/cc_textObject.png"
                                        };
                                default: trace('unknown type ${dialog.findComponent("GRP_IOT", DropDown, true, "id").text}, this is a bad thing.');
                            }


                            var i:TreeViewNode = item.addNode({text: 'Group: ${dialog.tabs.getPageById("tab_groupmode").getComponentAt(0).text}', icon: "haxeui-core/styles/default/haxeui_tiny.png", count: 0});
                            i.addNode(toAdd);
                            //TODO: button that opens the properties sidebar
                            item.onRightClick = (e:MouseEvent)->{ //TODO: find way to only apply to the header.
                                var obj = new FlxObject(tItem.screenLeft, tItem.screenTop, 300, 600);
                                if (FlxG.mouse.overlaps(obj)) {
                                    var menu = new MyMenu();
                                    menu.left = e.screenX + 1;
                                    menu.top = e.screenY + 1;
                                    Screen.instance.addComponent(menu);
                                    menu.onSelect=(_:String)->{
                                        switch(_) {
                                            case "addToGroup": ObjectCreationDialogObject(item);
                                            case "delete": trace("FUCKR, NOOOOOOOOOO!!!!!");
                                            default: trace('no');
                                        }
                                    };
                                }
                                obj.destroy();
                            }

                        default: trace('unknown tab, this is a bad thing.');
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
            trace(e.menuItem.id);
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