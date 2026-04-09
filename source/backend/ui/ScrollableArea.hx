package backend.ui;

class ScrollableArea extends FlxCamera {
    public var scrollIndex:Float=0;
    private var detectionObject:FlxObject;
    public function new(x:Float,y:Float,width:Int,height:Int,zoom:Float) {
        super(x, y, width, height, zoom);
        bgColor=0x0000FF00;

        detectionObject = new FlxObject(x, y, width, height);
        FlxG.state.add(detectionObject);
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.mouse.overlaps(detectionObject)) { //cant use FlxG.overlaps(this) because this is not an object.
            FlxG.watch.addQuick('scrollIndex', scrollIndex);
            scrollIndex-=(FlxG.mouse.wheel*10#if(html5)*elapsed#end); //soooo elapsed only fixes the html5 build, but breaks others. lovely.
            if(scrollIndex<0) scrollIndex=0;
            else scroll.y=scrollIndex;
        }
    }

    override public function destroy() {
        detectionObject.destroy();
        detectionObject=null;
        super.destroy();
    }
}