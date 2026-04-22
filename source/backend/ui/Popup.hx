package backend.ui;

import backend.extensions.ExtendedCamera;
import flixel.FlxBasic;

class Popup extends FlxSubState {
    public var background:FlxUI9SliceSprite;
    public var background2:FlxUI9SliceSprite;
    public var background3:FlxUI9SliceSprite;
    public var butts:Array<FlxUIButton>=[];
    public var header:FlxText;
    public var body:FlxText;
    public var group:FlxSpriteGroup;

    public var popupCam:ExtendedCamera;

    public function new(title:String, b:String, buttons:Array<{l:String,?f:Null<Void->Void>,c:Bool}>, ?itemPreview:Bool=false, object:#if(html5)BitmapData#else String#end, objectIsAnimated:Bool=false, frameSize:FlxPoint, ?skipIntroTween:Bool=false, colorable:Bool=false) {
        super();
        if(buttons.length>4){
            throw Error.Custom("Value outside of bounds. (4 buttons max!)");
            return;
        }
        popupCam = new ExtendedCamera(0,0,FlxG.width,FlxG.height,1);
        popupCam.bgColor=0x00000000;
        Main.addCameraToGame(popupCam, "popupCamera");


        group=new FlxSpriteGroup(0, 0);
        var blurDarkenSprite:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
        blurDarkenSprite.alpha=0.75;
        addT(blurDarkenSprite);
        blurDarkenSprite.scrollFactor.set();
        addT(group);

        background=new FlxUI9SliceSprite(0, 0, itemPreview?Paths.image('ui', colorable?'chrome_inspect_C':'chrome_inspect'):Paths.image('ui', colorable?'chrome_light_C':'chrome_light'), new Rectangle(0, 0, FlxG.width/4, FlxG.height/4), [5,5,8,8]);
        background2=new FlxUI9SliceSprite(5, 15, itemPreview?FlxUIAssets.IMG_BOX:Paths.image('ui', colorable?"chrome_inset_C":"chrome_inset"), new Rectangle(0, 0, FlxG.width/4-10, FlxG.height/4-30), [5,5,8,8]);
        if(itemPreview && !colorable) background2.color = 0xFFFFCA;



        header = new FlxText(2, 0, background.width, title, 12); //8
        header.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
        header.alignment=CENTER;

        body=new FlxText(5, background2.y, background2.width, b, 12);
        group.add(background);
        group.add(background2);
        if(itemPreview) { //to mimic the add order of bg3.
            Main.InspectPopupVisible = true;
            body.color=0xFF000000;

            background3=new FlxUI9SliceSprite(5, 20, Paths.image('ui', colorable?"chrome_inset_C":"chrome_inset"), new Rectangle(0, 0, 100, 100), [5,5,8,8]);
            background3.x = background2.x+background2.width-(background3.width+5);

            var objectPreview:FlxSprite = new FlxSprite(background3.x, background3.y);
            objectPreview.loadGraphic(object, objectIsAnimated, frameSize.x.floor(), frameSize.y.floor()); //DEFAULT VALUES.
            if(objectIsAnimated){
                objectPreview.animation.add("a", [0], 0);
                objectPreview.animation.play('a');
            }
            objectPreview.setGraphicSize(background3.width-25, background3.height-25);
            objectPreview.updateHitbox();
            objectPreview.center(background3);

            group.add(background3);
            group.add(objectPreview);
        }
        group.add(header);
        group.add(body);

        for(object in buttons) {
            var butt:FlxUIButton=new FlxUIButton(0, 0, object.l, ()->{
                if(object.f!=null) object.f();
                if(object.c && !itemPreview) close(); //dont close instantly if itemPreview is true, as we do that AFTER the tweens.
                if(itemPreview){ //inspect popups will only ever have one button, and so this actually does work well.
                    FlxTween.tween(popupCam.scroll, {y: 100}, 0.75, {ease: FlxEase.expoOut, onComplete: (_)->close()});
                    FlxTween.tween(group, {alpha: 0}, 0.5, {ease: FlxEase.expoOut});
                    FlxTween.tween(blurDarkenSprite, {alpha: 0}, 0.75, {ease: FlxEase.expoOut});
                }
            });
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
        for(object in group.members) {
            if(Reflect.hasField(object, "scrollFactor")) Reflect.setField(object, "scrollFactor", FlxPoint.weak(1, 1));
        }
        group.scrollFactor.set(1, 1);

        if(!skipIntroTween){
            if(itemPreview){
                group.alpha = 0;
                popupCam.scroll.y = -100;
                FlxTween.tween(popupCam.scroll, {y: 0}, 0.75, {ease: FlxEase.expoOut});
                FlxTween.tween(group, {alpha: 1}, 0.5, {ease: FlxEase.expoOut});
            }else{
                popupCam.zoom = 0.95;
                blurDarkenSprite.alpha = 0;
                FlxTween.tween(popupCam, {zoom: 1}, 0.75, {ease: FlxEase.expoOut});
                FlxTween.tween(blurDarkenSprite, {alpha: 0.75}, 0.75, {ease: FlxEase.expoOut});
            }
        }
    }

    public function addT(basic:FlxBasic):FlxBasic {
        basic.camera=popupCam;
        if(Reflect.hasField(basic, "scrollFactor")) Reflect.setField(basic, "scrollFactor", FlxPoint.weak(1, 1));
        add(basic);
        return basic;
    }

    override public function destroy() {
        if(Main.InspectPopupVisible) Main.InspectPopupVisible = false; //automatic.
        popupCam.destroy();
        super.destroy();
    }
}