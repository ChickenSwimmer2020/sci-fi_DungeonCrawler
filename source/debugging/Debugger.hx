package debugging;

/**
 * every. single. debugger.
 * minus of course: CutsceneMaker, GameDebugger
 * CutsceneMaker is its own thing, and GameDebugger requires GameState access.
 */
class Debugger extends FlxState {
    var mainView:DebuggerMainView;
    var mang:WindowManager;
    public function new() {
        super();
        add(mainView = new DebuggerMainView());
        mainView.mapEditorOpen.onClick = (_:MouseEvent)->FlxG.switchState(MapDebugger.new);
        mainView.cutsceneEditorOpen.onClick = (_:MouseEvent)->FlxG.switchState(CutsceneMaker.new);

        getErrorsTester(); //populate the errors tester dropdown with the errors from Main.
        
        mang = new WindowManager();
        mang.container = mainView;
        mainView.windowListA.windowManager = mang;
        mainView.saveReader = ()->{
            var window = new DebuggerSaveReaderWindow(Main.saveFiles);
            window.left = 10;
            window.top = 80;
            mang.addWindow(window);
        };
        mainView.saveWriter = ()->{
            var window = new DebuggerSaveWriterWindow(Main.saveFiles);
            window.left = 10;
            window.top = 80;
            mang.addWindow(window);
        };
        mainView.alphabetViewer = ()->{
            var window = new AlphabetViewerWindow();
            window.left = 10;
            window.top = 80;
            mang.addWindow(window);
        };
    }

    private function getErrorsTester() {
        var em:Menu = mainView.errorMenu;
        var errorTextinout:HUITextField = new HUITextField();
        errorTextinout.id = "errInOut";
        errorTextinout.placeholder=Language.getTranslatedKey("debugger.menubar.error.reftext", null);
        errorTextinout.text="DEBUG";
        em.addComponent(errorTextinout);
        var errorShouldFollowTags:MenuCheckBox = new MenuCheckBox();
        errorShouldFollowTags.text = Language.getTranslatedKey("debugger.menubar.error.followtags", null);
        em.addComponent(errorShouldFollowTags);
        for(name => errorDatas in Main.ErrorType) { //this is dynamic based on how many errors are actually implemented.
            var i:MenuItem = new MenuItem();
            i.id = name;
            i.text = Language.getTranslatedKey(errorDatas[0], null);
            em.addComponent(i);
        }
        em.addComponent(new MenuSeparator()); //should work?
        em.onMenuSelected = (e:MenuEvent)->{
            var targetError:String = e.menuItem.id; //yeah the ID is the error's internal register. bite me.
            if(targetError==null||targetError=="null"){
                //Functions.wait(0.01, (_)->{ TODO: find way to make this not close when the checkbox is clicked.
                //    em.show(); //should re-open it
                //    em._menu.dispatch(new UIEvent(UIEvent.CLOSE));
                //});
                //em.dispatch(new MouseEvent(MouseEvent.CLICK)); //automatically drop it back down, because the only thing that can be selected is a checkbox.
                return; //doesnt matter, shouldnt do anything in the first place lol.
            }
            if(Main.ErrorType.get(targetError)!=null) {
                Main.showError(targetError, errorTextinout.text==""?"NULL":errorTextinout.text, null, "", (errorShouldFollowTags.value is Bool)?errorShouldFollowTags.value:false); //validation to make sure the checkbox is actually a bool.
            }else{
                NotificationManager.instance.addNotification({
                    title: Language.getTranslatedKey("debugger.notif.error.title", null),
                    body: Language.getTranslatedKey("debugger.notif.error.nullerr", null, ["[T]"=>targetError]),
                    type: NotificationType.Error
                });
            }
        };
    }

    var textBoxSelected:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        textBoxSelected = Functions.anyTrue([
            mainView.errorMenu.findComponent("errInOut", HUITextField, true, "id").focus,
        ].concat([for(window in mang.windows) window.active])); //if any windows are active, dont let you close.

        if(!textBoxSelected && FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(()->new MainMenuState(false));
        }
    }
}
//------------------------------------------
//                ALPHABET
//------------------------------------------
@:xml('
    <window title="AlphabetViewer" width="350" height="500">
        <window-title width="100%">
            <dropdown id="langdropdown" width="100"/>
        </window-title>

        <!--<scrollview width="100%" height="100%">-->
            <label id="fontShower" width="100%" height="100%"/>
        <!--</scrollview>-->
    </window>
')
class AlphabetViewerWindow extends haxe.ui.containers.windows.Window {
    var targetFont(default, set):String = FlxAssets.FONT_DEFAULT;
    var targetLang:String = "EN_US";
    function set_targetFont(s:String):String {
        targetFont = s;

        var i:Int = 0;
        var t:String = Language.getTranslatedKey("debugger.windows.alphabet.charmap", null, null, targetLang);
        var tt:String="";

        final CHARSPERLINE:Int=26;
        for(c in 0...t.length){
            var char:String = t.charAt(c);
            tt+=char;
            if(i==CHARSPERLINE-1){
                tt+='\n';
                i=0;
            }else i++;
        }
        fontShower.getTextDisplay().tf.font = targetFont;
        fontShower.text=tt;

        return s;
    }

    public function new() {
        super();
        this.onMouseOver = (_)->{ //the text font should ALWAYS go back to target.
            fontShower.getTextDisplay().tf.font = targetFont;
        };

        title = Language.getTranslatedKey("debugger.windows.alphabet.title", null);
        final availableLanguages:Array<String>=[ //yeah we're just gonna do it like this regardless of platform, unlike how the settings substate does it.
            "EN_US", "JP"
        ];
        final availableLanguagesLables:Array<String>=[
            "English (US)", "Japanese"
        ];
        for(lang in availableLanguagesLables){
            langdropdown.dataSource.add(lang);
        }

        langdropdown.onChange = (e:UIEvent)->{
            fontShower.text="";
            Main.Trace(INFO, 'Chose Language: ${langdropdown.dataSource.get(langdropdown.selectedIndex)}');
            switch(langdropdown.dataSource.get(langdropdown.selectedIndex)) {
                case "English (US)":
                    targetLang = "EN_US";
                    targetFont=FlxAssets.FONT_DEFAULT; //should load default flixl font?
                case "Japanese":
                    targetLang = "JP";
                    targetFont=Paths.font('k8x12L.ttf');
                default: //donothing.
            }
            //fontShower.getTextDisplay().tf.font = targetFont; //should actually hopefully work.
        }
    }
}