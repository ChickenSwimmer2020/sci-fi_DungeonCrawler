package backend.game.objects.tiles;

class Breaker extends SpecialTile {
    var loopedMusicObject:FlxSound;
    var screenShakeShader:ScreenShake;
    public function new(x:Int,y:Int, tiles:Array<Array<Tile>>) {
        super(x,y, tiles);
        tileName = "Breaker";
        options = [
            Language.getTranslatedKey("game.specialtile.generic.options.inspect", null)=>()->{
                HUDSubstate.instance.openSubState(new InspectPopup(Language.getTranslatedKey('game.specialtile.breaker.title', null), Language.getTranslatedKey('game.specialtile.breaker.message', null), Paths.image('tiles', 'breaker'), true, FlxPoint.weak(16, 16)));
            },
            Language.getTranslatedKey("game.specialtile.breaker.interact", null)=>()->{
                FlxG.sound.play('${Paths.soundPath}/breakerpull.${#if(html5)'mp3'#else'ogg'#end}');
                animation.play('pull');
            }
        ];


        Music.playLooping(false, "ProtocolValidation", "BreakerLoop", "introloop", "hitcutscene");
        loopedMusicObject = Music.activeMusicObjects.get('BreakerLoop');
        loopedMusicObject.pitch = 0.85;


        loadGraphic(Paths.image('tiles', 'breaker'), true, GameMap.TILE_SIZE, GameMap.TILE_SIZE);
        animation.add("default", [0], 0, true);
        animation.add("pull", [1,2,3], 36, false);
        animation.add("pulled", [4], 0, true);
        animation.play('default');
        updateHitbox();

        animation.onFinish.add((_)->{
            switch(_) {
                case "pull":
                    
                    screenShakeShader=new ScreenShake();
                    screenShakeShader.intensity.value=[0.01];
                    screenShakeShader.speed.value=[120.0];
                    if(Main.camGame.filters==null)Main.camGame.filters=[];
                    if(Main.camHUD.filters==null)Main.camHUD.filters=[];
                    if(Main.camOther.filters==null)Main.camOther.filters=[];
                    Main.camGame.filters.push(new ShaderFilter(screenShakeShader));
                    Main.camHUD.filters.push(new ShaderFilter(screenShakeShader));
                    Main.camOther.filters.push(new ShaderFilter(screenShakeShader));

                    Functions.wait(5, (_)->{
                        Main.camGame.filters.remove(Main.camGame.filters[0]);
                        Main.camHUD.filters.remove(Main.camHUD.filters[0]);
                        Main.camOther.filters.remove(Main.camOther.filters[0]);
                    });

                    FlxG.sound.music.volume = 1;
                    loopedMusicObject.kill();
                    FlxG.sound.music.kill();
                    Music.playOnce("ProtocolValidation", "HitCutscene", "hitcutscene", "mainloop", ()->{
                        Music.playLoopingMusic("ProtocolValidation", "mainloop", "looptense1min");
                        Conductor.targetAudioObject = FlxG.sound.music;
                        Conductor.cameraBopRate = 2;
                        GameState.beginCountdown();
                    });

                    Conductor.targetAudioObject = Music.activeMusicObjects.get('HitCutscene');
                    Conductor.BPM = Music.musicInfos.get('ProtocolValidation').BPM;

                    Conductor.pitch = 0.85;
                    FlxTween.tween(Conductor, {pitch: 1}, 2.412, {ease:FlxEase.expoIn});

                    options.remove(Language.getTranslatedKey("game.specialtile.breaker.interact", null)); //get rid of the option so it cant be pulled again.
                    GameState.pulledBreaker = true;
                    animation.play('pulled');
            }
        });
    }
    var shaderTime:Float=0;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(screenShakeShader!=null){
            shaderTime+=FlxG.elapsed;
            screenShakeShader.iTime.value = [shaderTime];
            screenShakeShader.intensity.value=[FlxMath.lerp(0.0, screenShakeShader.intensity.value[0], Math.exp(-elapsed * 3.125 * 1 * 0.5))];
        }                        

        #if debug
            FlxG.watch.addQuick("DistanceBetween Value:", FlxMath.distanceToPoint(this, GameMap.instance.plr?.getGraphicMidpoint()).clampf(0, 100));
            FlxG.watch.addQuick("Target Volume:", ((FlxMath.distanceToPoint(this, GameMap.instance.plr?.getGraphicMidpoint()).clampf(0, 100))/100).toPositive());
        #end

        if(playerWithinRange && !GameState.pulledBreaker) {
            FlxG.sound.music.volume = ((FlxMath.distanceToPoint(GameMap.instance.plr, getGraphicMidpoint()).clampf(0, 100))/100).toPositive()-0.33;
            loopedMusicObject.volume = 1-((FlxMath.distanceToPoint(GameMap.instance.plr, getGraphicMidpoint()).clampf(0, 100))/100).toPositive()+0.33;
        }else FlxG.sound.music.volume=1.0;
    }

    override public function destroy() {
        loopedMusicObject.destroy();
        super.destroy();
    }
}