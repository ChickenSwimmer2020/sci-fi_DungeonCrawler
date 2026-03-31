package backend.ui;

import flixel.graphics.frames.FlxFrame;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import openfl.filters.BlurFilter;
import openfl.geom.Point;

class WarningPopup extends FlxSubState {
    private var background:FlxUI9SliceSprite;
    private var background2:FlxUI9SliceSprite;
    private var butts:Array<FlxUIButton>=[];
    private var header:FlxText;
    private var body:FlxText;
    private var group:FlxSpriteGroup;
    private var popupCamera:FlxCamera;
    public function new(title:String, b:String, buttons:Array<{l:String,f:Void->Void,c:Bool}>) {
        super();
        popupCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        popupCamera.bgColor=0x00000000; //darkens stuff behind it :3 //TODO: maybe make blur through a filter if shaders are enabled.
        FlxG.cameras.add(popupCamera, false);



        if(buttons.length>4){
            throw Error.Custom("Value outside of bounds. (4 buttons max!)");
            return;
        }
        group=new FlxSpriteGroup(0, 0);

        var backgroundCapture:BitmapData = new BitmapData(FlxG.width, FlxG.height);
        backgroundCapture.draw(FlxG.camera.canvas);

        //TODO: make not lag.
        var smallRect = new openfl.geom.Rectangle(0, 0, 1280, 720);
        var dest:BitmapData = new BitmapData(1280, 720, false);
        dest.draw(backgroundCapture, null, null, null, smallRect, true);
        var bmp = new Bitmap(dest);
        bmp.filters = [new BlurFilter(8, 8, 2)];
        var blurred:BitmapData = new BitmapData(1280, 720, false);
        blurred.draw(bmp);
        
        var blurDarkenSprite:FlxSprite = new FlxSprite(0, 0).loadGraphic(blurred);
        blurDarkenSprite.alpha=0.5;
        //add(blurDarkenSprite); //TODO: fix.
        

        add(group);

        background=new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_CHROME_LIGHT, new Rectangle(0, 0, FlxG.width/4, FlxG.height/4));
        background2=new FlxUI9SliceSprite(5, 15, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0, 0, FlxG.width/4-10, FlxG.height/4-30));
        header = new FlxText(2, 2, background.width, title, 12); //8
        header.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
        header.alignment=CENTER;

        body=new FlxText(5, background2.y, background2.width, b, 12);
        group.add(background);
        group.add(background2);
        group.add(header);
        group.add(body);

        for(object in buttons) {
            var butt:FlxUIButton=new FlxUIButton(0, 0, object.l, ()->{object.f(); if(object.c) close();});
            butts.push(butt);
            group.add(butt);
            butt.loadGraphic("flixel/images/ui/button.png", true, 80, 20);
            butt.updateHitbox();
            butt.autoCenterLabel();
            butt.y = (background2.y+background2.height);
        }

        switch(butts.length) {
            case 1:butts[0].x=(background.width/2-butts[0].width/2);
            case 2:butts[0].x=(background.width/2-butts[0].width/2)/2;butts[1].x=(background.width/2-butts[1].width/2)+((background.width/2-butts[1].width/2)/2);
            case 3:butts[0].x=0;butts[1].x=(background.width/2-butts[1].width/2);butts[2].x=(background.width/2-butts[2].width/2)+((background.width/2-butts[2].width/2));
            case 4:butts[0].x=0;butts[1].x=80;butts[2].x=160;butts[3].x=240;
        }

        group.screenCenter();
        group.camera = popupCamera;
    }

    override public function destroy() {
        FlxG.cameras.remove(popupCamera);
        popupCamera=null;
        super.destroy();
    }
}