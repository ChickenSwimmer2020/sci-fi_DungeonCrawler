package states;

class AwardsGalleryState extends FlxState {
    public static final GALLERY_TRANSITION_TIME:Float = 1.2;

    final GALLERY_MAX_SHELVES:Int = 5; // how many shelves of achivements are ther.
    final GALLERY_SHELF_SPACING:Int = 100; //how much space between each shelf of achivements. (on the Z axis, so scrolling is forward and backwards >:3)
    public function new() {
        super();
        FlxG.camera.y = FlxG.height;
        FlxG.camera.angle = 180;
        FlxTween.tween(FlxG.camera, {y: 0}, GALLERY_TRANSITION_TIME, {ease: FlxEase.expoOut});
        Functions.wait((GALLERY_TRANSITION_TIME/8), (_)->{
            FlxTween.tween(FlxG.camera, {angle: 0}, GALLERY_TRANSITION_TIME, {ease: FlxEase.expoInOut});
        });

        Music.playLoopingMusic("HallOfHeros");
        Music.deathFadeIn(GALLERY_TRANSITION_TIME+(GALLERY_TRANSITION_TIME/2)); //hehe, fades!

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFF00FF)); //this is just a test.


        for(i in 0...GALLERY_MAX_SHELVES) {
            for(j in 0...2) {
                var truss:FlxSprite = new FlxSprite([(159*2-(25*(i*2))), (FlxG.width-(159*2)-(25*(i*2)))][j], 0).loadGraphic(Paths.image('ui/awards/gallery', 'truss')); //TODO: base the x and y on scale as well.
                add(truss);
                truss.scale.set(1.0-(((i%2*0.1)+(j%2*0.1))*GALLERY_SHELF_SPACING/50)*2, 1.0-(((i%2*0.1)+(j%2*0.1))*GALLERY_SHELF_SPACING/50)*2);
                truss.updateHitbox();
                truss.alpha = 1.0-(((i%2*0.1)+(j%2*0.1))*GALLERY_SHELF_SPACING/50)/1000;
            }
        }

    }


    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(FlxG.keys.justPressed.ESCAPE) {
            Music.deathFadeOut(GALLERY_TRANSITION_TIME+(GALLERY_TRANSITION_TIME/2), false);
            FlxTween.tween(FlxG.camera, {angle: 180}, GALLERY_TRANSITION_TIME, {ease: FlxEase.expoOut});
            Functions.wait((GALLERY_TRANSITION_TIME/2), (_)->{
                FlxTween.tween(FlxG.camera, {y: FlxG.height}, GALLERY_TRANSITION_TIME, {ease: FlxEase.expoIn, onComplete:(_)->{
                    FlxG.switchState(()->new MainMenuState(true));
                }});
            });
        }
    }
}