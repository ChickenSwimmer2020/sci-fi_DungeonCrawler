package debugging;

import haxe.ui.components.Label;
import haxe.ui.dragdrop.DragManager;
import haxe.ui.components.Image;
import debugging.ui.cc.MainView;
#if debug
class CutsceneMaker extends FlxState {
    private final keyCodes:Map<Array<FlxKey>, Void->Void>=[
        [CONTROL, Q]=>()->FlxG.switchState(()->new MainMenuState(false))
    ];

    private var trackedObjects:Map<String, {type:Class<Dynamic>,x:Float,y:Float,name:String,path:String,isNested:Bool,grpName:String}>=[];
    var ViewPort:MainView;
    public function new() {
        super();
        add(ViewPort = new MainView()); //lets inline this shit
        //make it so draggable sprites will automatically scale and fit to the current thingy.
        ViewPort.PreviewSplitter.registerEvent(UIEvent.RESIZE, function(e:UIEvent) { //this will allow us to both re-size objects, but also to fix scaling problems.
            trace('SPLITTER_PREVIEW: x | y | width | height\n ${ViewPort.PreviewSplitter.x} | ${ViewPort.PreviewSplitter.y} | ${ViewPort.PreviewSplitter.width} | ${ViewPort.PreviewSplitter.height}');

            ViewPort.PreviewRenderArea.walkComponents((_)->{
                trace(_);
                
                //DragManager.instance.unregisterDraggable(_); //TODO: find way to update this properly.
                //DragManager.instance.registerDraggable(_, {
                //    dragBounds: new haxe.ui.geom.Rectangle(ViewPort.PreviewRenderArea.x, ViewPort.PreviewRenderArea.y, ViewPort.PreviewRenderArea.width, ViewPort.PreviewRenderArea.height)
                //});
                return true; //this is weird. it stops if i return false. which is odd, but whatever
            });
            
            
            //ViewPort.PreviewSplitter.componentClipRect
            //for(object in )
            //DragManager.instance.registerDraggable(spriteComponentImage, {
            //    dragBounds: new haxe.ui.geom.Rectangle(ViewPort.TimeLine.x, ViewPort.TimeLine.y, ViewPort.TimeLine.width, ViewPort.TimeLine.height)
            //});
        });

        


        ViewPort.onObjectCreate = (type:Class<Dynamic>,x:Float,y:Float,name:String,path:String,isNested:Bool,grpName:String)->{
            switch(type) {
                case FlxSprite:
                    trackedObjects.set(name, {type:type,x:x,y:y,name:name,path:path,isNested:isNested,grpName:grpName});
                    var spriteComponentImage:Image = new Image();
                    spriteComponentImage.resource=path;
                    
                    spriteComponentImage.onMouseOver = (_:MouseEvent)->{
                        trace('moved sprite $name!!\n${spriteComponentImage.getPosition().x}|${spriteComponentImage.getPosition().y}');
                    };
                    ViewPort.PreviewRenderArea.addComponent(spriteComponentImage);

                    //only make it have bounds IF its less than the screensize.
                    DragManager.instance.registerDraggable(spriteComponentImage);
                case FlxText:
                    trackedObjects.set(name, {type:type,x:x,y:y,name:name,path:path,isNested:isNested,grpName:grpName});
                    var spriteComponentText:Label = new Label();
                    spriteComponentText.text=path;
                    
                    spriteComponentText.onMouseOver = (_:MouseEvent)->{
                        trace('moved sprite $name!!\n${spriteComponentText.getPosition().x}|${spriteComponentText.getPosition().y}');
                    };
                    ViewPort.PreviewRenderArea.addComponent(spriteComponentText);
                    DragManager.instance.registerDraggable(spriteComponentText);
                default: trace("unknown class, unable to add to preview.");
            }
            trace(trackedObjects);
        };
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        for(controls => command in keyCodes) {
            if(Functions.allKeysPressed(controls)) command();
        }

        //constantly TRY to update the darkmode status, but only actually do it if needbe.
        if(Toolkit.theme!=(Flags.CC_DARKMODE?"dark":"default")) Toolkit.theme = Flags.CC_DARKMODE?"dark":"default";
    }
}

#end