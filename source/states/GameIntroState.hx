package states;

import backend.game.cutscenes.CDocument;
import backend.game.cutscenes.Cutscene;


class GameIntroState extends FlxState {
    public function new() {
        super();
        Music.playOnceMusic("PowerCells", "start", "loop", ()->{
            Music.playLoopingMusic("PowerCells", "loop", null);
        });
        Music.deathFadeIn(1.24);
        FlxG.camera.fade(0xFF000000, 1.24, true);
        
        
        openSubState(new Cutscene(Paths.getPath('cutscenes', 'intro', 'cutscene')).play().setCompleteFunc(()->{
            FlxG.camera.fade(0xFF000000, 1.24, false, ()->{
                //TODO: tutorial area
                FlxG.switchState(()->new GameState(false));
            });
        }));
    }
}