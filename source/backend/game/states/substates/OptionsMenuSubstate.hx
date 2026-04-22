package backend.game.states.substates;

import flixel.addons.ui.interfaces.IFlxUIButton;

class OptionsMenuSubstate extends FlxUISubState{
    private var total_Controls:Int=0;
    var tab_menu:FlxUITabMenu;
    var general:FlxUI;
    var graphics:FlxUI;
    var controls:FlxUI;
    var difficulty:FlxUI;
    var tabs:Array<{name:String, label:String}>=[];
    private var deleteButton:FlxUIButton;
    public function new() {
        super();

        tabs=[
            {name: "tab_general", label: Language.getTranslatedKey("menu.settings.tabs.general", null)},
            {name: "tab_graphics", label: FlxG.random.bool(14)?Language.getTranslatedKey("menu.settings.tabs.graphicsEG", null):Language.getTranslatedKey("menu.settings.tabs.graphics", null)},
            {name: "tab_controls", label: Language.getTranslatedKey("menu.settings.tabs.controls", null)}
        ];

		// Make the tab menu itself:
		tab_menu = new FlxUITabMenu(new FlxUI9SliceSprite(0, 0, Paths.image('ui', 'chrome'), new Rectangle(0, 0, 500, 380), [5,5,8,8]), tabs, true);
        tab_menu.screenCenter();
        var neededX:Float=0;
        for(tab in 0...tab_menu.numTabs) { //now the tabs should use MY graphics instead of the original ones.
            var targetTab:IFlxUIButton = tab_menu.getTab(null, tab);
            var graphic_names:Array<FlxGraphicAsset>=[
                Paths.image("ui", "tab_back"),
                Paths.image("ui", "tab_back"),
                Paths.image("ui", "tab_back"),
                Paths.image("ui", "tab"),
                Paths.image("ui", "tab"),
                Paths.image("ui", "tab")
            ];
            var slice9tab:Array<Int> = FlxStringUtil.toIntArray(FlxUIAssets.SLICE9_TAB);
            var slice9_names:Array<Array<Int>> = [slice9tab, slice9tab, slice9tab, slice9tab, slice9tab, slice9tab];
            targetTab.loadGraphicSlice9(graphic_names, 0, 0, slice9_names, FlxUI9SliceSprite.TILE_NONE, -1, true);
            if(tab==0){
                targetTab.x=tab_menu.x;
            }else{
                targetTab.x=tab_menu.getTab(null, tab-1).x+tab_menu.getTab(null, tab-1).width;
            }
            neededX+=tab_menu.getTab(null, tab).width;
        }

        //quickly init the groups and everything
        general=new FlxUI(null, tab_menu, null);
        graphics=new FlxUI(null, tab_menu, null);
        controls=new FlxUI(null, tab_menu, null);
        controls.name = "tab_controls";
        general.name = "tab_general";
        graphics.name = "tab_graphics";


        createGeneralUI();
        createGraphicsUI();
        createControlsUI();



        tab_menu.addGroup(general);
        tab_menu.addGroup(graphics);
        tab_menu.addGroup(controls); //dont even ADD difficulty if we're in gamestate.
        add(tab_menu);

        trace(neededX);
        deleteButton=new FlxUIButton(tab_menu.x+neededX, tab_menu.y, Language.getTranslatedKey("menu.settings.clear.button", null), ()->{
            var popup:Popup = new Popup(
                Language.getTranslatedKey("menu.save.delete.popup.title", null),
                Language.getTranslatedKey("menu.settings.clear.message", null),
                [
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.cancel", null), c:true},
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.delete", null), f: ()->{
                        Main.resetGlobalSettings();
                    }, c:true}
                ], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0)
            );
            openSubState(popup);
        }, false);
        deleteButton.loadGraphic(Paths.image('ui/menu', 'button_wide'), true, 100, 20);
        deleteButton.updateHitbox();
        deleteButton.autoCenterLabel();
        deleteButton.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_delete")), 0, 0, false);
        add(deleteButton);
        deleteButton.label.alignment=RIGHT;
        deleteButton.labelOffsets = [FlxPoint.weak(-5, 0), FlxPoint.weak(-5, 0), FlxPoint.weak(-5, 1), FlxPoint.weak(-5, 0)];
    }

    /**CONTROLS SETTINGS OBJECTS AND FUNCTION**/
    private var controlsText:FlxUIText;
    private var ControlsScroll:ScrollableArea;
    private var SBG:FlxUI9SliceSprite;
    private var ControlObjects:Array<ControlsAssignmentObject>=[];
    private var index:Int=0;
    private var a:Int=0;
    private function reloadControls() {
        if(Player.instance!=null) Player.instance.updateControls();
        for(ass in ControlObjects) {
            var keys = Main.controls.get(ass.text.text);
            if (keys == null) continue;
            ass.changeVisuals(Functions.FlxKeyFromInt(keys[0]), 1);
            ass.changeVisuals(Functions.FlxKeyFromInt(keys[1]), 2);
        }
    }
    private function createControlsUI() {
        SBG=new FlxUI9SliceSprite(controls.x+5, controls.y+5, Paths.image('ui', "chrome_inset"), new Rectangle(0,0, 490, 370), [5,5,8,8]);
        Save.readSaveFile(Main.FILE); //just in-case.
        ControlsScroll = new ScrollableArea((FlxG.width/2-250)+5, (FlxG.height/2-200)+25, 490, 370, 1);
        Main.addCameraToGame(ControlsScroll, "settingsControlsScroller");
        #if(debug&&(windows||hl)) Main.LOG(Main.controls); #end
        for(control => keys in Main.controls) {
            var assigner:ControlsAssignmentObject = new ControlsAssignmentObject(5, 5+(27*index), control, keys);
            add(assigner);
            ControlsScroll.add(assigner);
            assigner.controlSubsateRequest = (obj:ControlsAssignmentObject, index:Int)->{
                var sub:ControlsAssinmentKeyPressSubState = new ControlsAssinmentKeyPressSubState(obj, index);
                openSubState(sub);
                sub.onReassignment = (key:FlxKey)->{
                    trace(key);
                    obj.changeVisuals(key.toString().toUpperCase(), index); //SO, changing this WILL allow for saving controls, because im cool like that :sunglasses:
                    onControlsSave();
                };
            }
            assigner.updateControlsRequest=()->onControlsSave();
            ControlObjects.push(assigner);
            total_Controls++;
            index++;
        }

        if(ControlObjects.length==0) {
            var pulsingErrorText:FlxText = new FlxText(0, 0, 0, "", 12, true);
            pulsingErrorText.text = Language.getTranslatedKey("menu.settings.controls.nocontrols", pulsingErrorText);
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

        var popup:Popup = new Popup(
            Language.getTranslatedKey("warning.unfinishedlanguage.title", null),
            Language.getTranslatedKey("warning.unfinishedlanguage.message", null),
            [
                {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), c:true}
            ], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0)
        );
        openSubState(popup);
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
            for(file in FileSystem.readDirectory(Paths.paths.get('lang'))) {
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
        languageLabel.text = Language.getTranslatedKey("menu.settings.general.language", languageLabel);
        labels.push(languageLabel);
        general.add(languageLabel);

        languageDropdown=new FlxUIDropDownMenu(5, 30, languages, (_)->{
            Main.curLanguage=_; //Lang in Language is a string, so this should work.
            Main.saveFile.data.language=Main.curLanguage;
            Application.current.window.title = Language.languageInformation.get(Main.curLanguage).get('application_title'); //change application title to match with the new language setting.
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
                        Language.getTranslatedKey("menu.settings.tabs.general", null),FlxG.random.bool(14)?Language.getTranslatedKey("menu.settings.tabs.graphicsEG", null):Language.getTranslatedKey("menu.settings.tabs.graphics", null),
                        Language.getTranslatedKey("menu.settings.tabs.controls", null), Language.getTranslatedKey("menu.settings.tabs.difficulty", null )
                    ][i];

                    tab.label.font = FlxAssets.FONT_DEFAULT;
                    tab.label.size=switch(Main.curLanguage){ //automatically switch the default font depending on language setting.
                        case EN_US: 8;
                        case JP: 12;
                        case ES: 8;
                    }
                }
            }
            if(Language.languageInformation.get("WIPLanguages").contains(_)) {
                var popup:Popup = new Popup(
                    Language.getTranslatedKey("warning.unfinishedlanguage", null),
                    Language.getTranslatedKey("warning.unfinishedlanguage.message", null),
                    [
                        {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), c:true}
                    ],
                false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0));
                openSubState(popup);
            }
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
        audioLabel.text = Language.getTranslatedKey("menu.settings.general.audiotrack", audioLabel);
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

        autoPauseCheck=new FlxUICheckBox(245, 5, null, null, Language.getTranslatedKey("menu.settings.general.autopause", autoPauseCheck), 100, null, ()->{
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


    private function onControlsSave() {
        var controlsUpload:Array<{c:String, keys:Array<FlxKey>}>=[];
        for(i in 0...total_Controls) {
            //#if(debug&&(windows||hl)) Main.LOG('generating control scheme object...'); #end
            var ReadObject:ControlsAssignmentObject=ControlObjects[i];

            final key0:FlxKey=(ReadObject.input0.text==""||(ReadObject.input0.text=="NONE"||ReadObject.input0.text=="null"))?NONE:FlxKey.fromString(ReadObject.input0.text);
            final key1:FlxKey=(ReadObject.input1.text==""||(ReadObject.input1.text=="NONE"||ReadObject.input1.text=="null"))?NONE:FlxKey.fromString(ReadObject.input1.text);
            controlsUpload.push({c:ReadObject.text.text,keys:[key0,key1]});
            trace({c:ReadObject.text.text,keys:[Functions.FlxKeyFromInt(key0).toString(),Functions.FlxKeyFromInt(key1).toString()]});
            //#if(debug&&(windows||hl)) Main.LOG(controlsUpload); #end
        }
        trace(controlsUpload);
        Main.saveFile.data.controls=controlsUpload;
        Main.saveFile.flush();
        Main.controls = Save.loadControls(); //WHOOPS. kinda gotta re-call this each time.
        reloadControls();
    }
}

private final class ControlsAssignmentObject extends FlxTypedSpriteContainer<Dynamic> {
    public var controlSubsateRequest:(ControlsAssignmentObject, Int)->Void;
    public var updateControlsRequest:Void->Void;
    private static final OFFSET_SPACING:Float=8;
    public var reassignButton:FlxUIButton;
    public var clearButton:FlxUIButton;
    public var reassignButton1:FlxUIButton;
    public var clearButton1:FlxUIButton;
    public var text:FlxText;
    public var input0:FlxInputText;
    public var input1:FlxInputText;

    public function new(x:Float,y:Float, controlName:String, controlKeys:Array<FlxKey>) {
        super(x, y);
        text = new FlxText(0, 0, 142, controlName, 12, true);

        var inputText0:String = controlKeys[0]=="null"?"":controlKeys[0];
        var inputText1:String = controlKeys[1]=="null"?"":controlKeys[1];
        input0 = new FlxInputText(((text.x+text.width)+OFFSET_SPACING)-40, 0, 160, inputText0, 12);
        input1 = new FlxInputText((input0.x+input0.width)+OFFSET_SPACING, 0, 160, inputText1, 12);
        input0.selectable=input1.selectable=false;

        reassignButton=new FlxUIButton(input0.x+input0.width-40, input0.y, "", ()->{
            controlSubsateRequest(this, 1);
        }, false);
        reassignButton.loadGraphic(Paths.image('ui/menu', "button_reassign"), true, 20, 20);
        reassignButton.updateHitbox();
        reassignButton.autoCenterLabel();
        reassignButton.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_reassign")), 0, 0, false);

        clearButton=new FlxUIButton(input0.x+input0.width-20, input0.y, "", ()->{
            input0.text = "NONE"; //reset the key
            updateControlsRequest();
        }, false);
        clearButton.loadGraphic(Paths.image('ui/menu', "button_reassign"), true, 20, 20);
        clearButton.updateHitbox();
        clearButton.autoCenterLabel();
        clearButton.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_delete")), 0, 0, false);

        reassignButton1=new FlxUIButton(input1.x+input1.width-40, input1.y, "", ()->{
            controlSubsateRequest(this, 2);
        }, false);
        reassignButton1.loadGraphic(Paths.image('ui/menu', "button_reassign"), true, 20, 20);
        reassignButton1.updateHitbox();
        reassignButton1.autoCenterLabel();
        reassignButton1.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_reassign")), 0, 0, false);

        clearButton1=new FlxUIButton(input1.x+input1.width-20, input1.y, "", ()->{
            input1.text = "NONE";
            updateControlsRequest();
        }, false);
        clearButton1.loadGraphic(Paths.image('ui/menu', "button_reassign"), true, 20, 20);
        clearButton1.updateHitbox();
        clearButton1.autoCenterLabel();
        clearButton1.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_delete")), 0, 0, false);

        add(text);
        add(input0);
        add(input1);
        add(clearButton);
        add(clearButton1);
        add(reassignButton);
        add(reassignButton1);
    }

    public inline function changeVisuals(t:String, i:Int) (i==1?input0:input1).text = t;
}


private final class ControlsAssinmentKeyPressSubState extends Popup {
    public var onReassignment:FlxKey->Void;
    private var bg:FlxSprite;
    private var ob:ControlsAssignmentObject;
    private var ind:Int=0;
    public function new(object:ControlsAssignmentObject, index:Int) {
        super("", "", [], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0));
        ob = object;
        background.visible=background2.visible=header.visible=body.visible=false;
        for(butt in butts) butt.visible=butt.active=false;
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey("menu.settings.controls.reassigncontrol", null, ["[INDEX]"=>'$index', "[CONTROL]"=>'${object.text.text}']), 24);
        text.screenCenter();
        text.alignment=CENTER;
        addT(text);

        var text2:FlxText = new FlxText(text.x, text.y+text.height, 0, Language.getTranslatedKey("menu.settings.controls.reassigncontrolexitmsg", null), 8);
        text2.alignment=LEFT;
        addT(text2);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed); 
        if(FlxG.mouse.justPressed || (FlxG.mouse.justPressedRight || FlxG.mouse.justPressedMiddle)) close();
        
        var key:FlxKey = Functions.FlxKeyFromInt(FlxG.keys.firstJustPressed());
        switch(key){
            case NONE: return; //nothing is pressed.
            default:{
                onReassignment(key);
                //TODO: prevent assining the same key to both inputs of a control.
                close(); //close the substate but run the code on reassignment lol.
            }
        }
    }
}