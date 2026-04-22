package backend.extensions;

class ExtendedCamera extends FlxCamera {
    public var onDestroy:ExtendedCamera->Void;

    
    override public function destroy() {
        if(onDestroy!=null) onDestroy(this);
        super.destroy(); //stil calls the original stuff
    }
}