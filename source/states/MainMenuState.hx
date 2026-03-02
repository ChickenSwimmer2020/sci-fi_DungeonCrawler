package states;

import lime.system.System;
#if android
class MenuButton extends FlxSprite {
    var f:Void->Void=null;
    public function new(x:Float, y:Float, image:String, onClick:Void->Void) {
        super(x, y);
        loadGraphic(Paths.image('android/ui', image));

        f=onClick;
    }

    override public function update(elapsed:Float){
        super.update(elapsed);

        if(FlxG.touches.justStarted()[0]?.overlaps(this) && FlxG.touches.justStarted()[0]?.justPressed){
            f(); //run function once clicked.
        }
    }
}
#end

class MainMenuState extends FlxState {
    var logo:FlxSprite;
    var buttons:Array<#if(android)MenuButton #else FlxButton #end>=[];
    public function new() {
        super();
        logo=new FlxSprite(FlxG.width-500, 0).makeGraphic(500, 200, 0xFFFF0000);
        add(logo); //TODO: placeholder graphic
    
        final strings:Array<String>=[
            Language.getTranslatedKey(Main.curLanguage, "menu.new_game"),
            Language.getTranslatedKey(Main.curLanguage, "menu.load_game"),
            Language.getTranslatedKey(Main.curLanguage, "menu.config"),
            Language.getTranslatedKey(Main.curLanguage, "menu.art"),
            Language.getTranslatedKey(Main.curLanguage, "menu.awards"),
            Language.getTranslatedKey(Main.curLanguage, "menu.quit")
        ];
        #if android
            for(i in 0...strings.length) {
                var button:MenuButton = new MenuButton([
                    FlxG.width/2-128, FlxG.width/2+128, FlxG.width/2-128, FlxG.width/2+128, FlxG.width/2-128, FlxG.width/2+128
                ][i], [
                    0, 0, 108, 108, 216, 216
                ][i], strings[i], [
                    ()->{trace('new game');},
                    ()->{trace('load game');},
                    ()->{
                        openSubState(new OptionsMenuSubstate());
                    },
                    ()->{trace('gallery');},
                    ()->{trace('achivements');},
                    ()->{System.exit(0);} //TODO: make android app actually close.
                ][i]);
                buttons.push(button);
                add(button);
            }
        #else
            for(i in 0...strings.length) {
                var button:FlxButton = new FlxButton(FlxG.width-80, logo.height+(20*i), strings[i], [
                    ()->{trace('new game');},
                    ()->{trace('load game');},
                    ()->{
                        openSubState(new OptionsMenuSubstate());
                    },
                    ()->{trace('gallery');},
                    ()->{trace('achivements');},
                    ()->{
                        #if html5
                            js.Browser.window.close();
                        #else
                            Sys.exit(1);
                        #end
                    }
                ][i]);
                buttons.push(button);
                add(button);
            }
        #end

        //TODO: cool bg art
        //TODO: menu theme


        #if (debug)
            var debuggerButton:FlxButton = new FlxButton(FlxG.width-(logo.width+80), 0, Language.getTranslatedKey(Main.curLanguage, "menu.debug.debugger"), ()->{
                openSubState(new DebuggerChooser());
            });
            add(debuggerButton);
        #end
    }
}

#if (debug)
class DebuggerChooser extends FlxSubState {
    final debuggerOptions:Map<String, Void->Void>=[
        Language.getTranslatedKey(Main.curLanguage, "debugger.map") => ()->{
            FlxG.switchState(MapDebugger.new);
        },
        Language.getTranslatedKey(Main.curLanguage, "debugger.testing")=>()->{
            FlxG.switchState(TestingState.new);
        },
        Language.getTranslatedKey(Main.curLanguage, "debugger.save")=>()->{
            FlxG.switchState(SaveDebugger.new);
        }
    ];
    public function new() {
        super();

        var bg = add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF000000));
        Reflect.setField(bg, "alpha", 0); //stupid that i have to do this but OKAY.
        FlxTween.tween(bg, {alpha: 0.25}, 0.54212, {ease: FlxEase.expoOut});

        var i:Int=0;
        for(lable => func in debuggerOptions) {
            var button = add(new FlxButton(0, 0+(40*i), lable, func));
            add(button);
            Reflect.setField(button, "x", FlxG.width/2-40);
            i++;
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.keys.justPressed.ESCAPE) close();
    }
}
#end