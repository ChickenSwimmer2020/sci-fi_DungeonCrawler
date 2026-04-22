package states;


class GameIntroState extends FlxState {
    public function new() {
        super();
        Music.playOnceMusic("PowerCells", "start", "loop", ()->{
            Music.playLoopingMusic("PowerCells", "loop", null);
        });
        Music.deathFadeIn(1.24);
        FlxG.camera.fade(0xFF000000, 1.24, true);
        
        openSubState(new KFCutscene(KFDocument.fromXml(Xml.parse(File.getContent('${Paths.paths.get('cutscene')}/intro.cutscene')))).play()); //TODO: support on HTML5
    }
}