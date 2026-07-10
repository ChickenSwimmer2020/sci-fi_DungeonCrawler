package debugging.ui;

@:xml('
<window title="Save Reader" width="350">
    <window-title width="100%">
        <dropdown id="savesDropdown" width="100"/>
    </window-title>

    <tree-view id="properties" width="100%" height="100%"/>
</window>
')
class DebuggerSaveReaderWindow extends haxe.ui.containers.windows.Window {
    public function new(saves:Array<String>){
        super();
        title=Language.getTranslatedKey("debugger.windows.save.reader", null);
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
                        rootNode.addNode({text: '$property: ${Reflect.getProperty(Reflect.getProperty(targetSave, field), property)}'});
                    }
                }else properties.addNode({text: '$field => ${Reflect.getProperty(targetSave, field)}'});
            }
        }
    }
}