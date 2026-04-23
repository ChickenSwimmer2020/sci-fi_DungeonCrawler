package debugging;

import flixel.group.FlxGroup;
import haxe.ui.Toolkit;
import haxe.ui.core.Screen;
import haxe.ui.containers.VBox;
import haxe.ui.containers.ListView;
import haxe.ui.containers.HBox;
#if debug
/**
 * so im using this class to test HAXEUI stuff, so that we can really get everytihng set in-stone about how these editors will work
 * i kinda wanna lean into the HAXEUI for the backend debugging thingies because it feels more debuggy if that makes sense.
 * 
 * this is ALSO a ***NONFUNCTIONAL*** test of what i somewhat want the NEW cutscene editor to look like, SOLAR PLEASE TAKE NOTES, ALSO MAKE MY CODE BETTER PLEASE
 */
class UIDebugger extends FlxState {
    var test:UI;
    public function new() {
        super();

        test = new UI();
        add(test);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        test.update(elapsed);
    }
}
@:build(haxe.ui.macros.ComponentMacros.build("assets/views/editorTest.xml"))
private class UI extends VBox {
    public function new() {
        super();

        var testButton = testbutton;
        testButton.onClick = (_)->{
            trace('IM A WITCH');
        };

        var root1 = tv2.addNode({ text: "root A", icon: "haxeui-core/styles/default/haxeui_tiny.png", count: 5 });
        root1.expanded = true;
            var child = root1.addNode({ text: "child A-1", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 3, checked: Std.random(2) == 0 });
            child.expanded = true;
                var node = child.addNode({ text: "child A-1-1", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-1-2", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-1-3", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
            var child = root1.addNode({ text: "child A-2", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 2, checked: Std.random(2) == 0 });
            child.expanded = true;
                var node = child.addNode({ text: "child A-2-1", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-2-2", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
            var child = root1.addNode({ text: "child A-3", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 4, checked: Std.random(2) == 0 });
            child.expanded = true;
                var node = child.addNode({ text: "child A-3-1", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-3-2", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-3-3", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
                var node = child.addNode({ text: "child A-3-4", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), checked: Std.random(2) == 0 });
            var child = root1.addNode({ text: "child A-4", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 3, checked: Std.random(2) == 0 });
            var child = root1.addNode({ text: "child A-5", icon: "haxeui-core/styles/default/haxeui_tiny.png", progress: Std.random(100), count: 3, checked: Std.random(2) == 0 });
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
    }
}
#end