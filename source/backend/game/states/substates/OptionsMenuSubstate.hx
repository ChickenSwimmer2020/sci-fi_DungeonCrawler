package backend.game.states.substates;

import backend.ui.ScrollableArea;
import openfl.utils.AssetType;

class OptionsMenuSubstate extends FlxUISubState{
    private var total_Controls:Int=0;
    var tab_menu:FlxUITabMenu;
    var general:FlxUI;
    var graphics:FlxUI;
    var controls:FlxUI;
    var difficulty:FlxUI;
    var tabs:Array<{name:String, label:String}>=[];
    public function new() {
        super();

        tabs=[
			{name: "tab_general", label: Language.getTranslatedKey("menu.options.tab.general", null)},
			{name: "tab_graphics", label: FlxG.random.bool(14)?Language.getTranslatedKey("menu.options.tab.graphicsEG", null):Language.getTranslatedKey("menu.options.tab.graphics", null)},
			{name: "tab_controls", label: Language.getTranslatedKey("menu.options.tab.controls", null)},
			{name: "tab_difficulty", label: Language.getTranslatedKey("menu.options.tab.difficulty", null)},
		];

		// Make the tab menu itself:
		tab_menu = new FlxUITabMenu(null, tabs, true);
        tab_menu.resize(500, 400);
        tab_menu.screenCenter();

        //quickly init the groups and everything
        general=new FlxUI(null, tab_menu, null);
        graphics=new FlxUI(null, tab_menu, null);
        difficulty=new FlxUI(null, tab_menu, null);
        controls=new FlxUI(null, tab_menu, null);
        controls.name = "tab_controls";
        general.name = "tab_general";
        graphics.name = "tab_graphics";
        difficulty.name = "tab_difficulty";


        createGeneralUI();
        createGraphicsUI();
        createControlsUI();
        createDifficultyUI();
        


        tab_menu.addGroup(general);
        tab_menu.addGroup(graphics);
        tab_menu.addGroup(controls);
        tab_menu.addGroup(difficulty);
        add(tab_menu);
    }

    private function createDifficultyUI() {

    }

    /**CONTROLS SETTINGS OBJECTS AND FUNCTION**/
    private var saveButton:FlxUIButton;
    private var controlsText:FlxUIText;
    private var ControlsScroll:ScrollableArea;
    private var SBG:FlxUI9SliceSprite;
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
        Save.readSaveFile(Main.FILE); //just in-case. //TODO: add posssible dropdown incase a save file isnt loaded, or a deault save file thingy.
        ControlsScroll = new ScrollableArea((FlxG.width/2-250)+5, (FlxG.height/2-200)+25, 490, 370, 1);
        FlxG.cameras.add(ControlsScroll, false);
        #if(debug&&(windows||hl)) Main.LOG(Main.controls); #end
        for(control => keys in Main.controls) {
            var assigner:ControlsAssignmentObject = new ControlsAssignmentObject(5, 5+(27*index), control, keys);
            add(assigner);
            assigner.camera=ControlsScroll;
            ControlObjects.push(assigner);
            total_Controls++;
            index++;
        }

        if(ControlObjects.length==0) {
            var pulsingErrorText:FlxText = new FlxText(0, 0, 0, "", 12, true);
            pulsingErrorText.text = Language.getTranslatedKey("menu.options.controls.nocontrols", pulsingErrorText);
            pulsingErrorText.alignment=CENTER;
            pulsingErrorText.applyMarkup(pulsingErrorText.text, [
                new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, false, null, false), "**"),
                new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, true, null, false), "&")
            ]);
            pulsingErrorText.camera = ControlsScroll;
            add(pulsingErrorText);
            pulsingErrorText.alpha=0;
            pulsingErrorText.setPosition(ControlsScroll.width/2-pulsingErrorText.width/2,ControlsScroll.height/2-pulsingErrorText.height/2);
            FlxTween.tween(pulsingErrorText, {alpha: 1}, 1.5428, {ease: FlxEase.sineInOut, type: PINGPONG});
        }
        controls.add(SBG);

        saveButton=new FlxUIButton(420, 380, Language.getTranslatedKey("menu.options.tab.save.flush", saveButton), ()->{
            var controlsUpload:Array<{c:String, keys:Array<FlxKey>}>=[];
            for(i in 0...total_Controls) {
                #if(debug&&(windows||hl)) Main.LOG('generating control scheme object...'); #end
                var ReadObject:ControlsAssignmentObject=ControlObjects[i];

                final key0:FlxKey=(ReadObject.input0.text==""||(ReadObject.input0.text=="NONE"||ReadObject.input0.text=="null"))?NONE:FlxKey.fromString(ReadObject.input0.text);
                final key1:FlxKey=(ReadObject.input1.text==""||(ReadObject.input1.text=="NONE"||ReadObject.input1.text=="null"))?NONE:FlxKey.fromString(ReadObject.input1.text);
                controlsUpload.push({c:ReadObject.text.text,keys:[key0,key1]});
                #if(debug&&(windows||hl)) Main.LOG(controlsUpload); #end
            }
            Main.saveFile.data.controls=controlsUpload;
            Main.saveFile.flush();
            @:privateAccess Save.loadControls(); //WHOOPS. kinda gotta re-call this each time.
            reloadControls();
        }, false);
        saveButton.loadGraphic("flixel/images/ui/button.png", true, 80, 20);
        saveButton.updateHitbox();
        saveButton.autoCenterLabel();
        controls.add(saveButton);

        openSubState(new WarningPopup(Language.getTranslatedKey("warning.unfinishedlanguage", null), Language.getTranslatedKey("warning.unfinishedlanguage.message", null), [
            {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), f:()->{}, c:true}
        ]));
    }

    /**GRAPHICS SETTINGS OBJECTS AND FUNCTION**/
    private var shadersCheck:FlxUICheckBox;
    private function createGraphicsUI() {
        shadersCheck=new FlxUICheckBox(5, 5, null, null, "Shaders", 100, null, ()->{
            Main.saveFile.data.shaders=shadersCheck.checked;
            Main.saveFile.flush(); //automatically save the update
            #if(debug&&(windows||hl)) Main.LOG(Main.saveFile.data); #end
        }); 
        shadersCheck.checked = Main.saveFile.data.shaders??false; //if null, default to false. else pull the value from the save file.

        
        graphics.add(shadersCheck);
    }

    /**GENERAL SETTINGS OBJECTS AND FUNCTION**/
    private var labels:Array<FlxUIText>=[];
    private var languageDropdown:FlxUIDropDownMenu;
    private var audioTrackDropdown:FlxUIDropDownMenu;
    private var autoPauseCheck:FlxUICheckBox;
    private function createGeneralUI() {
        #if (html5)
            final availableLanguages:Array<String>=[
                "EN_US", "JP"
            ];
            final availableLanguagesLables:Array<String>=[
                "English (US)", "Japanese"
            ];
        #end
        var languages:Array<StrNameLabel>=[];
        #if (hl||windows)
            for(file in FileSystem.readDirectory(Paths.langPath)) {
                #if(debug&&(windows||hl)) Main.LOG('found lang file $file'); #end
                languages.push(new StrNameLabel(file.split('.')[0].toUpperCase(), Language.getLanguageLable(file.split('.')[0])));
            }
        #else
            for(language in 0...availableLanguages.length) {
                if(Assets.exists('assets/lang/${availableLanguages[language]}.lang', AssetType.TEXT)) //validate that the assets for the language exist before even THINKING of adding them to the selectable dropdown.
                    languages.push(new StrNameLabel(availableLanguages[language], availableLanguagesLables[language]));
                else Main.showError("MISSINGFONTORLANGUAGEASSET", availableLanguages[language]);
            }
        #end
        var languageLabel:FlxUIText=new FlxUIText(5, 5, 0, "", 12, true);
        languageLabel.text = Language.getTranslatedKey("menu.options.general.language", languageLabel);
        labels.push(languageLabel);
        general.add(languageLabel);

        languageDropdown=new FlxUIDropDownMenu(5, 30, languages, (_)->{
            Main.curLanguage=_; //Lang in Language is a string, so this should work.
            Main.saveFile.data.language=Main.curLanguage;
            Application.current.window.title = Language.applicationTitles.get(Main.curLanguage); //change application title to match with the new language setting.
            Main.saveFile.flush(); //upload new default language to save file.
            #if(debug&&(windows||hl)) Main.LOG('attempting to index language $_ and change game target LANG file'); #end
            FlxAssets.FONT_DEFAULT=switch(Main.curLanguage){ //automatically switch the default font depending on language setting.
                case EN_US: "Nokia Cellphone FC Small";
                case JP: "assets/ui/fonts/k8x12L.ttf";
                default: "Nokia Cellphone FC Small";
            }
            @:privateAccess{
                for(i in 0...tab_menu._tabs.length){
                    var tab:FlxUIButton=cast(tab_menu.getTab(null, i));
                    tab.label.text = [
                        Language.getTranslatedKey("menu.options.tab.general", null),FlxG.random.bool(14)?Language.getTranslatedKey("menu.options.tab.graphicsEG", null):Language.getTranslatedKey("menu.options.tab.graphics", null),
                        Language.getTranslatedKey("menu.options.tab.controls", null), Language.getTranslatedKey("menu.options.tab.difficulty", null )
                    ][i];

                    tab.label.font = FlxAssets.FONT_DEFAULT;
                    tab.label.size=switch(Main.curLanguage){ //automatically switch the default font depending on language setting.
                        case EN_US: 8;
                        case JP: 12;
                        case ES: 8;
                    }
                }
            }
            if(Language.WIPLanguages.contains(_)) openSubState(new WarningPopup(Language.getTranslatedKey("warning.unfinishedlanguage", null), Language.getTranslatedKey("warning.unfinishedlanguage.message", null), [
                {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), f:()->{}, c:true}
            ]));

        });
        for(languageOption in languageDropdown.list) {
            switch(languageOption.name) {
                case 'Japanese', "JP", "にほんご": languageOption.label.font = "assets/ui/fonts/k8x12L.ttf";
                case 'English (US)', "EN_US", "English": languageOption.label.font = "Nokia Cellphone FC Small";
            }
            switch(languageDropdown.header.text.text) {
                case "English (US)", 'EN_US', "English": languageDropdown.header.text.font = "Nokia Cellphone FC Small";
                case 'Japanese', "JP", "にほんご": languageOption.label.font = "assets/ui/fonts/k8x12L.ttf";
            }
            if(Main.curLanguage==languageOption.name) languageDropdown.selectedLabel=Main.curLanguage;
        }
        general.add(languageDropdown);

        var audioLabel:FlxUIText = new FlxUIText(125, 5, 0, "", 12, true);
        audioLabel.text = Language.getTranslatedKey("menu.options.general.audiotrack", audioLabel);
        labels.push(audioLabel);
        general.add(audioLabel);
        audioTrackDropdown=new FlxUIDropDownMenu(125, 30, [
            new StrNameLabel("D", "Default"),
            new StrNameLabel("P", "Prototype"),
            new StrNameLabel("A", "Alpha"),
            new StrNameLabel("B", "Beta"),
            new StrNameLabel("F", "Final"),
            //new StrNameLabel("R", "Remaster")
        ], (_)->{
            #if(debug&&(windows||hl)) Main.LOG('changing music postfix to $_ and flushing to save file'); #end
            Main.saveFile.data.musicPF = _;
            Main.saveFile.flush();
            Main.musicPostfix = _;
        });
        general.add(audioTrackDropdown);

        autoPauseCheck=new FlxUICheckBox(245, 5, null, null, Language.getTranslatedKey("menu.options.general.autopause", autoPauseCheck), 100, null, ()->{
            Main.saveFile.data.autoPause=autoPauseCheck.checked;
            Main.saveFile.flush(); //automatically save the update
            FlxG.autoPause = autoPauseCheck.checked; //immediately update the auto-pause setting without needing to restart the game.
            #if(debug&&(windows||hl)) Main.LOG(Main.saveFile.data); #end
        }); 
        autoPauseCheck.checked = Main.saveFile.data.autoPause??false; //if null, default to false. else pull the value from the save file.
        general.add(autoPauseCheck);
    }

    override public function update(elapsed:Float){
        super.update(elapsed);
        ControlsScroll.visible = tab_menu.selected_tab==0;

        if(FlxG.keys.justPressed.ESCAPE) close();
    }

    override public function destroy() {
        FlxG.cameras.remove(ControlsScroll);
        super.destroy();
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