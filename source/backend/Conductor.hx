package backend;

class Conductor {
    public static var pitch:Float=1.0;
    public static var BPM:Int=120;

    public static var bopCamera:Bool=true;
    public static var cameraBopRate:Int=4;
    public static var cameraBopStrength:Float=0.005;
    public static var additionalBopOnSection:Bool=true;

    public static var targetAudioObject:FlxSound;

    public static var onMeasureHit:Array<(Int)->Void>=[
        
    ];
    public static var onBeatHit:Array<(Int)->Void>=[
        
    ];
    public static var onStepHit:Array<(Int)->Void>=[
        
    ];
    public static var curMeasure:Int=0;
    public static var lastMeasure:Int=-1;
    public static var curBeat:Int=0;
    private static var lastBeat:Int=-1;
    public static var curStep:Int=0;
    public static var lastStep:Int=-1;
    public static inline function reset(){
        curMeasure=curBeat=curStep=0;
        lastMeasure=lastBeat=curStep=-1;
    }
    public static function update(elapsed:Float) {
        if(targetAudioObject==null) targetAudioObject=FlxG.sound.music;
        pitch = Math.round(pitch * 100)/100;
        targetAudioObject.pitch = pitch;
        //cant call super because we dont extend anything. MUST CALL MANUALLY.
        curStep = Math.floor(FlxMath.roundDecimal((clamp(Math.min(0, 0), targetAudioObject.time, targetAudioObject.length))/((((60/BPM)*1000)*(4/4))/4), 4));
        curBeat = Math.floor((Math.floor(Math.floor(FlxMath.roundDecimal((clamp(Math.min(0, 0), targetAudioObject.time, targetAudioObject.length))/((((60/BPM)*1000)*(4/4))/4), 4)))/4));
        curMeasure = Math.floor((Math.floor(Math.floor(FlxMath.roundDecimal((clamp(Math.min(0, 0), targetAudioObject.time, targetAudioObject.length))/((((60/BPM)*1000)*(4/4))/4), 4)))/16));

        if(bopCamera) {
            if(Main.camGame != null){
                Main.camGameZoomIncrement = FlxMath.lerp(0, Main.camGameZoomIncrement, Math.exp(-elapsed * 3.125 * 1 * 1));
                Main.camHUD.zoom = FlxMath.lerp(1, Main.camHUD.zoom, Math.exp(-elapsed * 3.125 * 1 * 1));
            }else{
                FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, Math.exp(-elapsed * 3.125 * 1 * 1));
            }
        }

        if(curBeat!=lastBeat){
            lastBeat=curBeat;
            if(onBeatHit!=null){
                for(func in onBeatHit) {
                    func(curBeat);
                }
                if(bopCamera) {
                    if(curBeat % cameraBopRate == 0) {
                        if(Main.camGame != null){
                            Main.camGameZoomIncrement += (cameraBopStrength * (Main.camGame.zoom*2));
                            Main.camHUD.zoom += (cameraBopStrength*Main.camGame.zoom)/4;
                        }else{
                            FlxG.camera.zoom += cameraBopStrength;
                        }
                    }
                }
            }
        }
        if(curStep!=lastStep){
            lastStep=curStep;
            if(onStepHit!=null){
                for(func in onStepHit) {
                    func(curStep);
                }
            }
        }
        if(curMeasure!=lastMeasure){
            lastMeasure=curMeasure;
            if(onMeasureHit!=null){
                for(func in onMeasureHit) {
                    func(curMeasure);
                }
            }
        }
    }
    private static function clamp(v:Float,mi:Float,ma:Float):Float return v<mi?mi:v>ma?ma:v;
}