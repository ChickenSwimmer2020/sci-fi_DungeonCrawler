package states;

typedef GalleryShelf = {
    var truss:Array<FlxSprite>;
    var shelfs:Array<FlxSprite>;
    var awards:Array<Dynamic>; //TODO: award class.
    var tweens:Array<FlxTween>;
    var baseX:Array<Float>;
};

class AwardsGalleryState extends FlxState {
    var GalleryIndex(default, set):Int = 0;
    var previousGalleryIndex:Int = 0;
    var scrollDirection:Int = 1;
    function set_GalleryIndex(value:Int):Int {
        previousGalleryIndex = GalleryIndex;
        GalleryIndex = value;

        var order:Array<Int> = [for (i in 0...shelves.length) i];
        order.sort((a, b) -> {
            var slotA = ((a - GalleryIndex) % shelves.length + shelves.length) % shelves.length;
            var slotB = ((b - GalleryIndex) % shelves.length + shelves.length) % shelves.length;
            return slotB - slotA;
        });

        for (i in order) {
            var shelf:GalleryShelf = shelves[i];

            for (t in shelf.tweens) {
                if (t != null) t.cancel();
            }
            shelf.tweens = [];

            var slot:Int = ((i - GalleryIndex) % shelves.length + shelves.length) % shelves.length;
            var previousSlot:Int = ((i - previousGalleryIndex) % shelves.length + shelves.length) % shelves.length;

            if (scrollDirection == 1) {
                var prevScale:Float = 1.0 - (previousSlot * 0.1);
                if (prevScale < 0.1) prevScale = 0.1;
                var prevAlpha:Float = 1.0 - (previousSlot * 0.25);
                if (prevAlpha < 0.0) prevAlpha = 0.0;
                if (previousSlot == 0) prevAlpha = 1;
                var prevCenterShift:Float = previousSlot * 25;

                for (j in 0...shelf.truss.length) {
                    var truss = shelf.truss[j];
                    var prevLeftX:Float = (159 * 1.2) + prevCenterShift*2;
                    var prevRightX:Float = FlxG.width - (159 * 1.2) - prevCenterShift;
                    var prevTargetX:Float = [prevLeftX-159, prevRightX][j];

                    truss.x = prevTargetX;
                    truss.scale.set(prevScale, prevScale);
                    truss.alpha = prevAlpha;
                    truss.updateHitbox();
                }
                for (shelfSprite in shelf.shelfs) {
                    shelfSprite.scale.set(prevScale, prevScale);
                    shelfSprite.alpha = prevAlpha;
                    shelfSprite.updateHitbox();
                }
            }

            var leavingFront:Bool = (previousSlot == 0 && slot != 0);
            var enteringFront:Bool = (previousSlot != 0 && slot == 0);

            var doOvershootOut:Bool = leavingFront && scrollDirection == 1;
            var doOvershootIn:Bool = enteringFront && scrollDirection == -1;

            var targetScale:Float = 1.0 - (slot * 0.1); 
            if (targetScale < 0.1) targetScale = 0.1;
            var targetAlpha:Float = 1.0 - (slot * 0.25);
            if (targetAlpha < 0.0) targetAlpha = 0.0;
            var centerShift:Float = slot * 25;

            if(slot == 0) {
                targetAlpha = 1;
            }else{
                
            }

            var overshootScale:Float = 1.0 + 0.25;
            var overshootCenterShift:Float = -25;
            var overshootLeftX:Float = (159 * 1.2) + overshootCenterShift*2;
            var overshootRightX:Float = FlxG.width - (159 / 2) - overshootCenterShift;

            for (j in 0...shelf.truss.length) {
                var truss = shelf.truss[j];

                remove(truss);
                add(truss);

                var leftX:Float = (159 * 1.2) + centerShift*2;
                var rightX:Float = FlxG.width - (159 * 1.2) - centerShift;
                var targetX:Float = [leftX-159, rightX][j];
                var overshootTargetX:Float = [overshootLeftX-(159*2), overshootRightX][j];

                if (doOvershootOut) {
                    var t1 = FlxTween.tween(truss.scale, {x: overshootScale, y: overshootScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> truss.updateHitbox()
                    });
                    var tX = FlxTween.tween(truss, {x: overshootTargetX}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut
                    });
                    var tAlpha = FlxTween.tween(truss, {alpha: 0}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onComplete: (_) -> {
                            truss.x = targetX;
                            truss.scale.set(targetScale, targetScale);
                            truss.updateHitbox();

                            var tAlpha2 = FlxTween.tween(truss, {alpha: targetAlpha}, GALLERY_SHELF_TIME * 0.65, {ease: FlxEase.expoOut});
                            shelf.tweens.push(tAlpha2);
                        }
                    });
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tX);
                    shelf.tweens.push(tAlpha);
                } else if (doOvershootIn) {
                    truss.x = overshootTargetX;
                    truss.scale.set(overshootScale, overshootScale);
                    truss.alpha = 0;
                    truss.updateHitbox();

                    var t1 = FlxTween.tween(truss.scale, {x: targetScale, y: targetScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> truss.updateHitbox()
                    });
                    var tX = FlxTween.tween(truss, {x: targetX}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    var tAlpha = FlxTween.tween(truss, {alpha: targetAlpha}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tX);
                    shelf.tweens.push(tAlpha);
                } else {
                    var t1 = FlxTween.tween(truss.scale, {x: targetScale, y: targetScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> truss.updateHitbox()
                    });
                    var tAlpha = FlxTween.tween(truss, {alpha: targetAlpha}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    var tX = FlxTween.tween(truss, {x: targetX}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tAlpha);
                    shelf.tweens.push(tX);
                }
            }

            for (shelfSprite in shelf.shelfs) {
                remove(shelfSprite);
                add(shelfSprite);

                if (doOvershootOut) {
                    var t1 = FlxTween.tween(shelfSprite.scale, {x: overshootScale, y: overshootScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> shelfSprite.updateHitbox()
                    });
                    var tAlpha = FlxTween.tween(shelfSprite, {alpha: 0}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onComplete: (_) -> {
                            shelfSprite.scale.set(targetScale, targetScale);
                            shelfSprite.updateHitbox();

                            var tAlpha2 = FlxTween.tween(shelfSprite, {alpha: targetAlpha}, GALLERY_SHELF_TIME * 0.65, {ease: FlxEase.expoOut});
                            shelf.tweens.push(tAlpha2);
                        }
                    });
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tAlpha);
                } else if (doOvershootIn) {
                    shelfSprite.scale.set(overshootScale, overshootScale);
                    shelfSprite.alpha = 0;
                    shelfSprite.updateHitbox();

                    var t1 = FlxTween.tween(shelfSprite.scale, {x: targetScale, y: targetScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> shelfSprite.updateHitbox()
                    });
                    var tAlpha = FlxTween.tween(shelfSprite, {alpha: targetAlpha}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tAlpha);
                } else {
                    var t1 = FlxTween.tween(shelfSprite.scale, {x: targetScale, y: targetScale}, GALLERY_SHELF_TIME, {
                        ease: FlxEase.expoOut,
                        onUpdate: (_) -> shelfSprite.updateHitbox()
                    });
                    var tAlpha = FlxTween.tween(shelfSprite, {alpha: targetAlpha}, GALLERY_SHELF_TIME, {ease: FlxEase.expoOut});
                    shelf.tweens.push(t1);
                    shelf.tweens.push(tAlpha);
                }
            }
        }
        return value;
    }

    public static final GALLERY_TRANSITION_TIME:Float = 1.2; //state enter/exit time.
    public static final GALLERY_SHELF_TIME:Float = 0.86456; //shelf transition time
    final GALLERY_MAX_SHELVES:Int = 5;

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
        Music.deathFadeIn(GALLERY_TRANSITION_TIME+(GALLERY_TRANSITION_TIME/2));

        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFFFF00FF));


        for(i in 0...GALLERY_MAX_SHELVES) {
            var centerShift:Float = i * 25;
            
            var targetScale:Float = 1.0 - (i * 0.1); 
            if (targetScale < 0.1) targetScale = 0.1;
            
            var targetAlpha:Float = 1.0 - (i * 0.25);
            if (targetAlpha < 0.0) targetAlpha = 0.0;

            var trusses:Array<FlxSprite> = [];
            var awardShelves:Array<FlxSprite> = [];
            var baseXs:Array<Float> = [];

            for(j in 0...2) {
                var leftX:Float = (159 * 1.2) + centerShift*2;
                var rightX:Float = FlxG.width - (159 * 1.2) - centerShift;
                var targetX:Float = [leftX-159, rightX][j];

                var truss:FlxSprite = new FlxSprite(targetX, 0).loadGraphic(Paths.image('ui/awards/gallery', 'truss'));
                add(truss);
                
                truss.scale.set(targetScale, targetScale);
                truss.updateHitbox();
                
                truss.alpha = targetAlpha;
                trusses.push(truss);
                baseXs.push(targetX);
            }

            for(s in 0...3) {
                var shelf:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('ui/awards/gallery', 'shelf'));
                shelf.scale.set(targetScale, targetScale);
                shelf.updateHitbox();
                shelf.x = (FlxG.width/2) - (shelf.width/2);

                var topMargin:Float = FlxG.height * 0.15;
                var bottomMargin:Float = FlxG.height * 0.15;
                var usableHeight:Float = FlxG.height - topMargin - bottomMargin - shelf.height;
                var spacing:Float = usableHeight / 2;

                shelf.y = topMargin + (s * spacing);
                shelf.alpha = targetAlpha;
                //add(shelf);
                awardShelves.push(shelf);
            }

            shelves.push({
                truss: trusses,
                shelfs: [],//awardShelves,
                awards: [],
                tweens: [],
                baseX: baseXs
            });
        }

    }


    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(FlxG.keys.justPressed.DOWN) {
            scrollDirection = -1;
            if(GalleryIndex>0) {
                GalleryIndex--;
            }else GalleryIndex=GALLERY_MAX_SHELVES-1;
        }
        if(FlxG.keys.justPressed.UP) {
            scrollDirection = 1;
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