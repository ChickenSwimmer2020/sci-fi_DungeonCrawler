package backend.ui;

class InspectPopup extends FlxSubState {
    private var background:FlxUI9SliceSprite;
    private var background2:FlxUI9SliceSprite;
    private var background3:FlxUI9SliceSprite;
    private var header:FlxText;
    private var body:FlxText;
    private var group:FlxSpriteGroup;
    private var popupCamera:FlxCamera;
    public function new(title:String, b:String, object:#if(html5)BitmapData#else String#end, objectIsAnimated:Bool=false, frameSize:FlxPoint) {
        super();
        Main.InspectPopupVisible = true;
        popupCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        popupCamera.bgColor=0x00000000; //darkens stuff behind it :3
        FlxG.cameras.add(popupCamera, false);
        group=new FlxSpriteGroup(0, 0);
        add(group);

        background=new FlxUI9SliceSprite(0, 0, Paths.image('ui', 'chrome_inspect'), new Rectangle(0, 0, FlxG.width/4, FlxG.height/4));
        background2=new FlxUI9SliceSprite(5, 15, FlxUIAssets.IMG_BOX, new Rectangle(0, 0, FlxG.width/4-10, FlxG.height/4-30));
        background2.color = 0xFFFFCA;
        background3=new FlxUI9SliceSprite(5, 20, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0, 0, 100, 100));
        background3.x = background2.x+background2.width-105;
        header = new FlxText(2, 0, background.width, title, 12); //8
        header.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
        header.alignment=CENTER;

        var objectPreview:FlxSprite = new FlxSprite(background3.x, background3.y);
        objectPreview.loadGraphic(object, objectIsAnimated, frameSize.x.floor(), frameSize.y.floor()); //DEFAULT VALUES.
        if(objectIsAnimated){
            objectPreview.animation.add("a", [0], 0);
            objectPreview.animation.play('a');
        }
        objectPreview.setGraphicSize(75, 75);
        objectPreview.updateHitbox();
        objectPreview.center(background3);

        body=new FlxText(5, background2.y, background2.width, b, 12);
        body.color = 0xFF000000;
        group.add(background);
        group.add(background2);
        group.add(background3);
        group.add(objectPreview);
        group.add(header);
        group.add(body);

        group.screenCenter();
        group.camera = popupCamera;
        popupCamera.zoom = 0.95;

        var button:FlxButton = new FlxButton(0, 0, Language.getTranslatedKey("game.inspect.popup.close", null), ()->{
            FlxTween.tween(popupCamera, {y: -100}, 0.75, {ease: FlxEase.expoOut, onComplete: (_)->close()});
            FlxTween.tween(group, {alpha: 0}, 0.5, {ease: FlxEase.expoOut});
        });
        group.add(button);
        button.y = (background2.y+background2.height);

        group.alpha = 0;
        popupCamera.y = 100;
        FlxTween.tween(popupCamera, {y: 0}, 0.75, {ease: FlxEase.expoOut});
        FlxTween.tween(group, {alpha: 1}, 0.5, {ease: FlxEase.expoOut});
    }

    override public function destroy() {
        FlxG.cameras.remove(popupCamera);
        Main.InspectPopupVisible = false;
        popupCamera=null;
        super.destroy();
    }
}