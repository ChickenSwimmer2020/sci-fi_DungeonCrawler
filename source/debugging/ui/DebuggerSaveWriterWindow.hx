package debugging.ui;

@:xml('
<window title="Save Editor" width="350">
    <window-title width="100%">
        <dropdown id="savesDropdown" width="100"/>
    </window-title>

    <tree-view id="properties" width="100%" height="100%"/>
</window>
')
class DebuggerSaveWriterWindow extends haxe.ui.containers.windows.Window {
    public function new(saves:Array<String>) {
        super();
        title=Language.getTranslatedKey("debugger.windows.save.editor", null);
        for(save in saves) {
            savesDropdown.dataSource.add(save);
        }
        savesDropdown.onChange = (_:UIEvent)->{
            Main.Trace(INFO, 'Selected: ${savesDropdown.selectedItem}');
            properties.clearNodes();

            var targetSave:SaveFile = Main.saveFile.data;
            for(field in Reflect.fields(targetSave)) { //maps are handled WAY differently between HTML5 and windows.
                if(field == "maps"){
                    properties.addNode({text: '$field => ${(Reflect.getProperty(targetSave, field):Array<Dynamic>).length>0?"populated (this is good)":"[] (this is bad.)"}'});
                    continue; //skip it.
                }

                if(Reflect.getProperty(targetSave, field) is Dynamic) { //make dropdown
                    var rootNode = properties.addNode({text: '$field'});
                    rootNode.expanded = true;
                    for(property in Reflect.fields(Reflect.getProperty(targetSave, field))   ) {
                        var subNode = rootNode.addNode({text: '$property: ${Reflect.getProperty(Reflect.getProperty(targetSave, field), property)}'});
                        subNode.onClick = (_:MouseEvent)->{
                            var dialog = new DebuggerSaveWriterWindowPopup(savesDropdown.selectedItem, property, Reflect.getProperty(Reflect.getProperty(targetSave, field), property));
                            dialog.onDialogClosed = function(e:DialogEvent) {
                                if(e.button.toString().toUpperCase()=="{{APPLY}}") {
                                    trace(dialog.typeDropdown.selectedItem.id);
                                    switch(dialog.typeDropdown.selectedItem.id){
                                        case 'int': Reflect.setProperty(Reflect.getProperty(targetSave, field), property, dialog.toChange.text.toInt());
                                        case 'float': Reflect.setProperty(Reflect.getProperty(targetSave, field), property, dialog.toChange.text.toFloat());
                                        case 'string': Reflect.setProperty(Reflect.getProperty(targetSave, field), property, dialog.toChange.text);
                                        case 'dynamic': Reflect.setProperty(Reflect.getProperty(targetSave, field), property, dialog.toChange.text);
                                        default: Reflect.setProperty(Reflect.getProperty(targetSave, field), property, dialog.toChange.text);
                                    }
                                    Main.saveFile.flush();
                                    savesDropdown.dispatch(new UIEvent(UIEvent.CHANGE, false, null)); //actually, i think thisll work.
                                }
                            }
                            dialog.showDialog();
                            Main.Trace(INFO, 'hehehehaw! ($property)');
                        };
                    }
                }else properties.addNode({text: '$field => ${Reflect.getProperty(targetSave, field)}'});
            }
        }
    }
}

@:xml('
<dialog id="diaroot" width="500" height="200" title="DEBUG LOLZ">
    <hbox width="100%" height="100%">
        <vbox width="50%" height="100%">
            <label id="ogText" text="Original Varible:" width="100%" height="20%"/>
            <textfield id="toChange" width="100%" height="80%" placeholder="Value" />
        </vbox>
        <dropdown id="typeDropdown" width="50%">
            <data>
                <item id="int" text="Int" />
                <item id="float" text="Float" />
                <item id="string" text="String" />
                <item id="dynamic" text="Dynamic" />
            </data>
        </dropdown>
    </hbox>
</dialog>
')
private class DebuggerSaveWriterWindowPopup extends Dialog {
    var o:String;
    var p:String;
    var v:Dynamic;
    public function new(obj:String, property:String, value:Dynamic) {
        super();
        buttons = DialogButton.CANCEL | DialogButton.APPLY;
        title = '"$obj": Enter New Value for: "$property"';
        ogText.text = 'Original Value: "$value"';

        o = obj;
        p = property;
        v = value;
    }
}