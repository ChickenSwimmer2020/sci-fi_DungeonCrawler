package states;

typedef GalleryShelf = {
    var truss:Array<FlxSprite>;
    var shelfs:Array<FlxSprite>;
    var awards:Array<Dynamic>; //TODO: award class.
};

class AwardsGalleryState extends FlxState {
    var GalleryIndex(default, set):Int = 0;
    function set_GalleryIndex(value:Int):Int {
        GalleryIndex = value;
        for(i in 0...shelves.length) {
            var shelf:GalleryShelf = shelves[i];
            var targetScale:Float = 1.0 - (i * 0.1); 
            if (targetScale < 0.1) targetScale = 0.1; // Prevent inversion/negative scale
            var targetAlpha:Float = 1.0 - (i * 0.25);
            if (targetAlpha < 0.0) targetAlpha = 0.0;

            if(shelf == shelves[GalleryIndex]) {
                targetAlpha = 1;
            }else{
                
            }

            for(truss in shelf.truss) {
                truss.scale.set(targetScale, targetScale);
                truss.updateHitbox();
                truss.alpha = targetAlpha;
            }
            for(shelfSprite in shelf.shelfs) {
                shelfSprite.scale.set(targetScale, targetScale);
                shelfSprite.updateHitbox();
                shelfSprite.alpha = targetAlpha;
            }
        }
        return value;
    }
    public static final GALLERY_TRANSITION_TIME:Float = 1.2;
    final GALLERY_MAX_SHELVES:Int = 5; // how many shelves of achivements are ther.
    final GALLERY_SHELF_SPACING:Int = 100; //how much space between each shelf of achivements. (on the Z axis, so scrolling is forward and backwards >:3)

    var shelves:Array<GalleryShelf> = [];
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
            // 1. Calculate the progressive modifiers based on the current row
            var centerShift:Float = i * 25; // Moves 25 pixels closer to center per row
            
            // Smoothly scale down (e.g., loses 10% scale per row)
            var targetScale:Float = 1.0 - (i * 0.1); 
            if (targetScale < 0.1) targetScale = 0.1; // Prevent inversion/negative scale
            
            // Smoothly drop alpha (e.g., loses 15% opacity per row)
            var targetAlpha:Float = 1.0 - (i * 0.25);
            if (targetAlpha < 0.0) targetAlpha = 0.0;

            var trusses:Array<FlxSprite> = [];
            var awardShelves:Array<FlxSprite> = [];

            for(j in 0...1) { //2
                // 2. Apply the centerShift to the X coordinates
                // Left side moves RIGHT (+ centerShift), Right side moves LEFT (- centerShift)
                var leftX:Float = (159 * 1.2) + centerShift*2;
                var rightX:Float = FlxG.width - (159 * 1.2) - centerShift;
                var targetX:Float = [leftX-159, rightX][j];

                // 3. Create the sprite
                var truss:FlxSprite = new FlxSprite(targetX, 0).loadGraphic(Paths.image('ui/awards/gallery', 'truss'));
                add(truss);
                
                // 4. Apply the visual transformations
                truss.scale.set(targetScale, targetScale);
                truss.updateHitbox(); // Update hitbox immediately after scaling so positioning calculations stay accurate
                
                truss.alpha = targetAlpha;
                trusses.push(truss);
            }

            //for(s in 0...3) {
            //    var shelf:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/awards/gallery', 'shelf'));
            //    shelf.scale.set(targetScale, targetScale);
            //    shelf.updateHitbox();
            //    shelf.x = (FlxG.width/2) - (shelf.width/2); // Center the shelf horizontally
            //    shelf.y = (FlxG.height - (shelf.height * targetScale)) - (i * GALLERY_SHELF_SPACING)-(s*250); // Position based on row and spacing
            //    shelf.alpha = targetAlpha;
            //    add(shelf);
            //    awardShelves.push(shelf);
            //}

            shelves.push({
                truss: trusses, // Assuming one truss per shelf for now
                shelfs: awardShelves, // Assuming one shelf per row for now
                awards: [] // Placeholder for awards, to be populated later
            });
        }

    }


    override public function update(elapsed:Float) {
        super.update(elapsed);
        trace(GalleryIndex);
        if(FlxG.keys.justPressed.UP) {
            if(GalleryIndex>0) {
                GalleryIndex--;
            }else GalleryIndex=GALLERY_MAX_SHELVES-1;
        }
        if(FlxG.keys.justPressed.DOWN) {
            if(GalleryIndex<GALLERY_MAX_SHELVES-1) {
                GalleryIndex++;
            }else GalleryIndex=0;
        }

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