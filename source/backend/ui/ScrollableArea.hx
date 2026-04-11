package backend.ui;

class ScrollableArea extends FlxCamera {
    public var scrollIndex:FlxPoint=FlxPoint.weak(0, 0);
    public var scrollable:Bool=true;
    public var sidewaysScrollingAllowed:Bool=false;
    private var detectionObject:FlxObject;
    public function new(x:Float,y:Float,width:Int,height:Int,zoom:Float,?ch:Bool=false) {
        super(x, y, width, height, zoom);
        bgColor=0x0000FF00;

        detectionObject = new FlxObject(x, y, width, height);
        FlxG.state.add(detectionObject);
        if(ch) detectionObject.camera = Main.camHUD;
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(scrollable){
            if(FlxG.mouse.overlaps(detectionObject)) { //cant use FlxG.overlaps(this) because this is not an object.
                FlxG.watch.addQuick('scrollIndex', scrollIndex);

                if(FlxG.keys.pressed.SHIFT) {
                    if(sidewaysScrollingAllowed){
                        scrollIndex.x-=(FlxG.mouse.wheel*10#if(html5)*elapsed#end); //soooo elapsed only fixes the html5 build, but breaks others. lovely.
                        scroll.x=scrollIndex.x;
                    }
                }else{
                    scrollIndex.y-=(FlxG.mouse.wheel*10#if(html5)*elapsed#end); //soooo elapsed only fixes the html5 build, but breaks others. lovely.
                    if(scrollIndex.y<0) scrollIndex.y=0;
                    else scroll.y=scrollIndex.y;
                }
            }
        }
    }

    override public function destroy() {
        detectionObject.destroy();
        detectionObject=null;
        super.destroy();
    }
}