package states;

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

                Save.createNewFile("fucker", { //would be inline but apparently this isnt constant?
                    meta:{
                        name: "Fucker",
                        playTime:{H:0,M:0,S:0},
                        difficulty: "NONE",
                        depth: 0,
                        level: 0,
                        money: 0
                    },
                    playerState:{
                        health: 100,
                        stamina: 100,
                        xp: 0,
                        position:{x:-1, y:-1, curLevel: ""},
                    },
                    inventory: [],
                    maps: [],
                }, ()->{
                    MapGenerator.generateMap(10, 10, 0); //since the file was JUST SET to "fucker", we should just be able to make the map and make this work.
                    FlxG.switchState(()->new GameState(true, false, "fucker"));
                });
            });
        }));
    }
}