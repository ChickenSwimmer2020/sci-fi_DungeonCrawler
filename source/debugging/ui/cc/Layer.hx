package debugging.ui.cc;

@:build(haxe.ui.macros.ComponentMacros.build("assets/views/Cutscene_TLLayer.xml"))
class Layer extends HBox {
    public function new(i:String) {
        super();
        id = i; //for dynamic setting.
    }
}