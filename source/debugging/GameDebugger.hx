package debugging;

import debugging.ui.CreatePopup;
import flixel.group.FlxGroup;
import flixel.FlxBasic;
#if(debug)
class GameDebugger extends FlxSubState {
    public static var isOpen:Bool=false;
    public static var instance:GameDebugger;
    public static var onActionFinished:Void->Void;
    var backgroundOne:FlxUI9SliceSprite;
    var backgroundTwo:FlxUI9SliceSprite;
    var text:FlxUIText;
    var internalArea:ScrollableArea;


    var options:Map<String, Void->Void>=[]; //i swear to god im going to rape this fucking map. WORK DAMNIT.
    public function new(camera:FlxCamera) {
        super();
        instance=this;
        isOpen=true;

        options=[
            "Create Pickup"=>()->{
                openSubState(new CreatePopup());
            },
        ];

        //item>
        //player>
        //map>
        
        backgroundOne = new FlxUI9SliceSprite(FlxG.width-100, FlxG.height-90, Paths.image('ui', 'chrome'), new Rectangle(0, 0, 100, 90), [5,5,8,8]);
        backgroundTwo = new FlxUI9SliceSprite(FlxG.width-95, FlxG.height-75, Paths.image('ui', "chrome_inset"), new Rectangle(0, 0, 90, 70), [5,5,8,8]);
        text = new FlxUIText(backgroundOne.x, backgroundOne.y, backgroundOne.width, Language.getTranslatedKey("game.debugger.label", text), 8, true);
        text.alignment=CENTER;

        internalArea = new ScrollableArea(backgroundTwo.x, backgroundTwo.y, backgroundTwo.width.floor(), backgroundTwo.height.floor(), 1, true);
        Main.addCameraToGame(internalArea, "gamedebuggerScrollableArea");



        add(backgroundOne);
        add(backgroundTwo);
        add(text);
        this.camera=camera;

        var i:Int=0;
        for(label=>func in options) {
            var button:FlxButton = new FlxButton(5, 5+(20*i), label, ()->{
                func();
            });
            add(button);
            internalArea.add(button);
            button.scrollFactor.set(1, 1);
            i++;
        }
    }

    override public function destroy() {
        FlxG.cameras.remove(internalArea);
        isOpen=false;
        super.destroy();
    }
}
#end