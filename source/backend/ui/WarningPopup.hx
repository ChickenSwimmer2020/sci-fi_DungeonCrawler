package backend.ui;

import openfl.geom.Rectangle;
import haxe.io.Error;

class WarningPopup extends FlxSubState {
    private var background:FlxUI9SliceSprite;
    private var background2:FlxUI9SliceSprite;
    private var butts:Array<FlxUIButton>=[];
    private var header:Alphabet;
    private var body:Alphabet;
    public function new(title:String, b:String, buttons:Array<{l:String,f:Void->Void,c:Bool}>) {
        super();
        if(buttons.length>4){
            throw Error.Custom("Value outside of bounds. (4 buttons max!)");
            return;
        }

        background=new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_CHROME_LIGHT, new Rectangle(0, 0, FlxG.width/4, FlxG.height/4));
        background2=new FlxUI9SliceSprite(5, 15, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0, 0, FlxG.width/4-10, FlxG.height/4-30));
        header = new Alphabet(2, 2, background.width, title, 12); //8
        //header.setBorderStyle(OUTLINE, 0xFF000000, 1, 1); //TODO: outline support
        header.alignment=CENTER;

        body=new Alphabet(background2.x, background2.y, background2.width, b, 12);

        add(background);
        add(background2);
        add(header);
        add(body);

        for(object in buttons) {
            var butt:FlxUIButton=new FlxUIButton(0, 0, object.l, ()->{object.f(); if(object.c) close();});
            butts.push(butt);
            add(butt);
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
    }
}