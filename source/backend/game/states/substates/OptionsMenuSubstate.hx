package backend.game.states.substates;

import openfl.utils.AssetType;
import haxe.io.Error;
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUICheckBox;
import openfl.geom.Rectangle;
import flixel.addons.ui.FlxUISprite;
import backend.ui.WarningPopup;
import flixel.addons.ui.FlxUIGroup.FlxTypedUIGroup;

class OptionsMenuSubstate extends FlxUISubState{
    private var total_Controls:Int=0;
    var tab_menu:FlxUITabMenu;
    var general:FlxUI;
    var graphics:FlxUI;
    var controls:FlxUI;
    var difficulty:FlxUI;
    public function new() {
        super();

        var tabs = [
			{name: "tab_general", label: Language.getTranslatedKey("menu.options.tab.general")},
			{name: "tab_graphics", label: FlxG.random.bool(14)?Language.getTranslatedKey("menu.options.tab.graphicsEG"):Language.getTranslatedKey("menu.options.tab.graphics")},
			#if !android {name: "tab_controls", label: Language.getTranslatedKey("menu.options.tab.controls")}, #end
			{name: "tab_difficulty", label: Language.getTranslatedKey("menu.options.tab.difficulty")},
		];

		// Make the tab menu itself:
		tab_menu = new FlxUITabMenu(null, tabs, true);
        tab_menu.resize(500, 400);
        tab_menu.screenCenter();

        //quickly init the groups and everything
        general=new FlxUI(null, tab_menu, null);
        graphics=new FlxUI(null, tab_menu, null);
        difficulty=new FlxUI(null, tab_menu, null);
        #if(!android)
            controls=new FlxUI(null, tab_menu, null);
            controls.name = "tab_controls";
        #end
        general.name = "tab_general";
        graphics.name = "tab_graphics";
        difficulty.name = "tab_difficulty";


        createGeneralUI();
        createGraphicsUI();
        #if !android createControlsUI(); #end
        createDifficultyUI();
        


        tab_menu.addGroup(general);
        tab_menu.addGroup(graphics);
        #if !android tab_menu.addGroup(controls); #end
        tab_menu.addGroup(difficulty);
        add(tab_menu);
    }

    private function createDifficultyUI() {

    }

    #if !android
        /**CONTROLS SETTINGS OBJECTS AND FUNCTION**/
        private var saveButton:FlxUIButton;
        private var controlsText:FlxUIText;
        private var CONTROLSScrollCamera:FlxCamera;
        private var SBG:FlxUI9SliceSprite;
        private var CONTROLSScrollIndex:Float=0;
        private var ControlObjects:Array<ControlsAssignmentObject>=[];
        private var index:Int=0;
        private var a:Int=0;
        private function reloadControls() {
            for(ass in ControlObjects) {
                var keys = Main.controls.get(ass.text.text);
                if (keys == null) continue;
                ass.input0.text = Functions.FlxKeyFromInt(keys[0]);
                ass.input1.text = Functions.FlxKeyFromInt(keys[1]);
            }
        }
        private function createControlsUI() {
            SBG=new FlxUI9SliceSprite(controls.x+5, controls.y+5, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0,0, 490, 370));
            Save.readSaveFile(Main.FILE); //just in-case. TODO: add posssible dropdown incase a save file isnt loaded, or a deault save file thingy.
            CONTROLSScrollCamera = new FlxCamera((FlxG.width/2-250)+5, (FlxG.height/2-200)+25, 490, 370, 1);
            CONTROLSScrollCamera.bgColor=0x0000FF00;
            FlxG.cameras.add(CONTROLSScrollCamera, false);
            for(control => keys in Main.controls) {
                var assigner:ControlsAssignmentObject = new ControlsAssignmentObject(5, 5+(27*index), control, keys);
                add(assigner);
                assigner.camera=CONTROLSScrollCamera;
                ControlObjects.push(assigner);
                total_Controls++;
                index++;
            }

            if(ControlObjects.length==0) {
                var pulsingErrorText:FlxText = new FlxText(0, 0, 0, "NO CONTROLS FOUND\n**[THIS IS A BAD THING, AND SHOULD &NEVER& HAPPEN]**", 12, true);
                pulsingErrorText.alignment=CENTER;
                pulsingErrorText.applyMarkup(pulsingErrorText.text, [
                    new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, false, null, false), "**"),
                    new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, true, null, false), "&")
                ]);
                pulsingErrorText.camera = CONTROLSScrollCamera;
                add(pulsingErrorText);
                pulsingErrorText.alpha=0;
                pulsingErrorText.setPosition(CONTROLSScrollCamera.width/2-pulsingErrorText.width/2,CONTROLSScrollCamera.height/2-pulsingErrorText.height/2);
                FlxTween.tween(pulsingErrorText, {alpha: 1}, 1.5428, {ease: FlxEase.sineInOut, type: PINGPONG});
            }

            controls.add(SBG);

            saveButton=new FlxUIButton(420, 380, Language.getTranslatedKey("menu.options.tab.save.flush"), ()->{
                var controlsUpload:Array<{c:String, keys:Array<FlxKey>}>=[];
                for(i in 0...total_Controls) {
                    trace('generating control scheme object...');
                    var ReadObject:ControlsAssignmentObject=ControlObjects[i];

                    final key0:FlxKey=(ReadObject.input0.text==""||(ReadObject.input0.text=="NONE"||ReadObject.input0.text=="null"))?NONE:FlxKey.fromString(ReadObject.input0.text);
                    final key1:FlxKey=(ReadObject.input1.text==""||(ReadObject.input1.text=="NONE"||ReadObject.input1.text=="null"))?NONE:FlxKey.fromString(ReadObject.input1.text);
                    controlsUpload.push({c:ReadObject.text.text,keys:[key0,key1]});
                    trace(controlsUpload);
                }
                (Main.saveFile.data.saves:Map<String,SaveFile>).get(Main.FILE.isEmptySTR()?Flags.DEFAULT_SAVE:Main.FILE).controls=controlsUpload;
                Main.saveFile.flush();
                @:privateAccess Save.loadControls(Main.FILE); //WHOOPS. kinda gotta re-call this each time.
                reloadControls();
            }, false);
            saveButton.loadGraphic("flixel/images/ui/button.png", true, 80, 20); //probably gonna need to fix for android, although this menu is gonna look completely different on android
            saveButton.updateHitbox();
            saveButton.autoCenterLabel();
            controls.add(saveButton);
        }
    #end

    /**GRAPHICS SETTINGS OBJECTS AND FUNCTION**/
    private var shadersCheck:FlxUICheckBox;
    private function createGraphicsUI() {
        openSubState(new WarningPopup(Language.getTranslatedKey("warning.unfinishedlanguage"), Language.getTranslatedKey("warning.unfinishedlanguage.message"), [
                {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue"), f:()->{}, c:true}
            ]));
        shadersCheck=new FlxUICheckBox(5, 5, null, null, "Shaders", 100, null, ()->{
            Main.saveFile.data.shaders=shadersCheck.checked;
            Main.saveFile.flush(); //automatically save the update
            trace(Main.saveFile.data);
        });
        shadersCheck.checked = Main.saveFile.data.shaders??false; //if null, default to false. else pull the value from the save file.

        
        graphics.add(shadersCheck);
    }

    /**GENERAL SETTINGS OBJECTS AND FUNCTION**/
    private var languageDropdown:FlxUIDropDownMenu;
    private function createGeneralUI() {
        #if (android||html5)
            final availableLanguages:Array<String>=[
                "EN_US", "JP"
            ];
            final availableLanguagesLables:Array<String>=[
                "English (US)", "Japanese" //TODO: lanugages show what they are in the target language.
            ];
        #end
        var languages:Array<StrNameLabel>=[];
        #if (hl||windows)
            for(file in FileSystem.readDirectory(Paths.langPath)) {
                trace('found lang file $file');
                languages.push(new StrNameLabel(file.split('.')[0].toUpperCase(), Language.getLanguageLable(file.split('.')[0])));
            }
        #else
            for(language in 0...availableLanguages.length) {
                if(Assets.exists('assets/lang/${availableLanguages[language]}.lang', AssetType.TEXT) && Assets.exists('assets/ui/fonts/${Main.curLanguage}.png', AssetType.IMAGE)) //validate that the assets for the language exist before even THINKING of adding them to the selectable dropdown.
                    languages.push(new StrNameLabel(availableLanguages[language], availableLanguagesLables[language]));
                else Main.showError("MISSINGFONTORLANGUAGEASSET", availableLanguages[language]);
            }
            //TODO: language swap logic for android/html5
        #end
        languageDropdown=new FlxUIDropDownMenu(5, 5, languages, (_)->{
            Main.curLanguage=_; //Lang in Language is a string, so this should work.
            Main.saveFile.data.language=Main.curLanguage;
            Application.current.window.title = Language.applicationTitles.get(Main.curLanguage); //change application title to match with the new language setting.
            Main.saveFile.flush(); //upload new default language to save file.
            trace('attempting to index language $_ and change game target LANG file');
            if(Language.WIPLanguages.contains(_)) openSubState(new WarningPopup(Language.getTranslatedKey("warning.unfinishedlanguage"), Language.getTranslatedKey("warning.unfinishedlanguage.message"), [
                {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue"), f:()->{}, c:true}
            ]));

        });
        for(languageOption in languageDropdown.list) {
            if(Main.curLanguage==languageOption.name) languageDropdown.selectedLabel=Main.curLanguage;
        }
        general.add(languageDropdown);
    }

    override public function update(elapsed:Float){
        super.update(elapsed);
        
        #if !android
            switch(tab_menu.selected_tab) {
                case 0:
                    CONTROLSScrollIndex-=(FlxG.mouse.wheel*10);
                    CONTROLSScrollCamera.scroll.y=CONTROLSScrollIndex;
                default:
            }
            CONTROLSScrollCamera.visible = tab_menu.selected_tab==0;

            if(FlxG.keys.justPressed.ESCAPE) close(); //TODO: make act like a real internal window because fun
        #else
            //TODO: this.
        #end
    }
}

private final class ControlsAssignmentObject extends FlxTypedSpriteContainer<Dynamic> {
    private static final OFFSET_SPACING:Float=8;
    public var text:FlxText;
    public var input0:FlxInputText;
    public var input1:FlxInputText;

    public function new(x:Float,y:Float, controlName:String, controlKeys:Array<FlxKey>) {
        super(x, y);
        text = new FlxText(0, 0, 142, controlName, 12, true);

        var inputText0:String = controlKeys[0]=="null"?"":controlKeys[0];
        var inputText1:String = controlKeys[1]=="null"?"":controlKeys[1];
        input0 = new FlxInputText((text.x+text.width)+OFFSET_SPACING, 0, 160, inputText0, 12);
        input1 = new FlxInputText((input0.x+input0.width)+OFFSET_SPACING, 0, 160, inputText1, 12);

        add(text);
        add(input0);
        add(input1);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
    }
}