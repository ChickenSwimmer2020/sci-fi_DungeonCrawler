package debugging;

/**
 *! KNOWN BUGS
 *! Timeline has to be resized at least ONCE for scrolling to work internally: Unknown
 *! Draggable components all reset to 0, 0 in preview when resized: Unknown
 *! Draggable components dont update internal x, y position when moved in preview: Unknown.
 */
#if debug
class CutsceneMaker extends FlxState {  
    public static var instance:CutsceneMaker;
    private final keyCodes:Map<Array<FlxKey>, Void->Void>=[
        [CONTROL, Q]=>()->FlxG.switchState(Debugger.new)
    ];

    public var trackedObjects:Map<String, {?obj:Dynamic, type:Class<Dynamic>,x:Float,y:Float,name:String,path:String,isNested:Bool,grpName:String}>=[];
    public var trackedUIObjects:Map<String, OneOfTwo<Image, Label>>=[];
    var ViewPort:CutsceneMakerMainView;
    public function new() {
        super();
        instance = this;
        add(ViewPort = new CutsceneMakerMainView()); //lets inline this shit
        //make it so draggable sprites will automatically scale and fit to the current thingy.
        ViewPort.PreviewSplitter.registerEvent(UIEvent.RESIZE, function(e:UIEvent) { //this will allow us to both re-size objects, but also to fix scaling problems.
            Main.Trace(INFO, 'SPLITTER_PREVIEW: x | y | width | height\n ${ViewPort.PreviewSplitter.x} | ${ViewPort.PreviewSplitter.y} | ${ViewPort.PreviewSplitter.width} | ${ViewPort.PreviewSplitter.height}');

            ViewPort.PreviewRenderArea.walkComponents((_)->{
                Main.Trace(DEBUG, _);
                
                //DragManager.instance.unregisterDraggable(_);
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
                    var spriteComponentImage:Image = new Image();
                    spriteComponentImage.resource=path;
                    
                    spriteComponentImage.onMouseOver = (_:MouseEvent)->{
                        Main.Trace(INFO, 'moved sprite $name!!\n${spriteComponentImage.getPosition().x}|${spriteComponentImage.getPosition().y}');
                    };
                    ViewPort.PreviewRenderArea.addComponent(spriteComponentImage);

                    //only make it have bounds IF its less than the screensize.
                    DragManager.instance.registerDraggable(spriteComponentImage);
                    trackedObjects.set(name, {obj:spriteComponentImage,type:type,x:x,y:y,name:name,path:path,isNested:isNested,grpName:grpName});
                    trackedUIObjects.set(name, spriteComponentImage);
                case FlxText:
                    var spriteComponentText:Label = new Label();
                    spriteComponentText.text=path;
                    
                    spriteComponentText.onMouseOver = (_:MouseEvent)->{
                        Main.Trace(INFO, 'moved sprite $name!!\n${spriteComponentText.getPosition().x}|${spriteComponentText.getPosition().y}');
                    };
                    ViewPort.PreviewRenderArea.addComponent(spriteComponentText);
                    DragManager.instance.registerDraggable(spriteComponentText);
                    trackedObjects.set(name, {obj:spriteComponentText,type:type,x:x,y:y,name:name,path:path,isNested:isNested,grpName:grpName});
                    trackedUIObjects.set(name, spriteComponentText);
                default: Main.Trace(WARN, "unknown class, unable to add to preview.");
            }
            Main.Trace(DEBUG, trackedObjects);
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