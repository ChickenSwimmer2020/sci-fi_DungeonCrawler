package backend.game.states.substates;

@:xml('
    <dialog width="500" height="380" title="Options Menu">
        <vbox width="100%" height="90%">
            <tabview width="100%" height="100%">
                <hbox id="generalOptions" width="100%" height="100%">
                    <grid columns="3">
                        <dropdown id="languageDropdown" width="100"/>
                        <dropdown id="audioTrackDropdown" width="100"/>

                        <checkbox id="autoPauseCheck"/>
                    </grid>
                </hbox>

                <hbox id="graphicsOptions" width="100%" height="100%">
                    <grid columns="3">
                        <checkbox id="shadersCheck"/>
                        <checkbox id="shaderCacheCheck"/>
                    </grid>
                </hbox>

                <hbox id="controlsOptions" width="100%" height="100%">
                    <label text="coming soon to ui update lol."/>
                </hbox>
            </tabview>
            <hbox width="100%" height="10%">
                <button id="deleteButton" width="50%" height="100%"/>
                <button id="deleteAllSaves" width="50%" height="100%"/>
            </hbox>
        </vbox>
    </dialog>
')
class OptionsMenu extends Dialog {
    private var total_Controls:Int=0;
    public function new() {
        super();

        generalOptions.text = Language.getTranslatedKey("menu.settings.tabs.general", null);
        graphicsOptions.text = FlxG.random.bool(14)?Language.getTranslatedKey("menu.settings.tabs.graphicsEG", null):Language.getTranslatedKey("menu.settings.tabs.graphics", null);
        controlsOptions.text = Language.getTranslatedKey("menu.settings.tabs.controls", null);


        deleteButton.text = Language.getTranslatedKey("menu.settings.clear.button", null);
        deleteButton.onClick = (_:MouseEvent)->{
            var popup:Popup = new Popup(
                Language.getTranslatedKey("menu.save.delete.popup.title", null),
                Language.getTranslatedKey("menu.settings.clear.message", null),
                [
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.cancel", null), c:true},
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.delete", null), f: ()->{
                        Main.resetGlobalSettings();
                    }, c:true}
                ], false, "", false, FlxPoint.weak(0, 0)
            );
            //openSubState(popup);
        };
        deleteAllSaves.text = "Erase All Data\n(NEEDS LANG KEY)";
        deleteAllSaves.onClick = (_:MouseEvent)->{
            //openSubState(new Popup("Warning!", "This will clear ALL save data\nProceed?", [ //TODO: make popup a Dialog.
            //    {l: "Clear", c:true, f:()->{
            //        Main.saveFile.erase();
            //        close();
            //    }},
            //    {l: "Cancel", c:true},
            //], false, "", false, FlxPoint.weak(0, 0)));
        };

        //controls shit lmao.

        //graphics shit lmao
        shadersCheck.text = "Shaders (NEEDS LANG KEY)";
        shadersCheck.onChange = (_:UIEvent)->{
            Preferences.setPref("shaders", shadersCheck.selected);
        };
        shadersCheck.selected = Preferences.getPref("shaders")??false;

        
        shaderCacheCheck.text = "Shader Cache (NEEDS LANG KEY)";
        shaderCacheCheck.onChange = (_:UIEvent)->{
            Preferences.setPref("precacheShaders", shaderCacheCheck.selected);
        };
        shaderCacheCheck.selected = Preferences.getPref("precacheShaders")??false;

        //general
        languageDropdown.text = Language.getTranslatedKey("menu.settings.general.language", null);
        var i:Int=0;
        for(file in FileSystem.readDirectory('assets/lang')){
            languageDropdown.dataSource.add(Language.getLanguageLable(file.split('.')[0], file.split('.')[0], [false, true][i]));
            i++;
        }
        #if debug languageDropdown.dataSource.add("DEBUG"); #end
        languageDropdown.selectedItem = Language.getLanguageLable(Main.curLanguage, Main.curLanguage, Main.curLanguage==JP?true:false);
        languageDropdown.onChange = (_:UIEvent)->{
            var label:String = languageDropdown.dataSource.get(languageDropdown.selectedIndex);
            trace(label);
            Main.curLanguage=Language.langFromLabel(label); //Lang in Language is a string, so this should work.
            Preferences.setPref("language", Main.curLanguage);
            Application.current.window.title = Language.languageInformation.get(Main.curLanguage).get('application_title'); //change application title to match with the new language setting.
            Main.saveFile.flush(); //upload new default language to save file.
            #if(debug) Main.Trace(INFO, 'Attempting to index language ${Main.curLanguage} and change game target LANG file'); #end
            FlxAssets.FONT_DEFAULT=switch(Main.curLanguage){ //automatically switch the default font depending on language setting.
                case EN_US: "Nokia Cellphone FC Small";
                case JP: "assets/fonts/k8x12L.ttf";
                default: "Nokia Cellphone FC Small";
            }
            if(Language.WIPLanguages.contains(Language.langFromLabel(label))) {
            //    var popup:Popup = new Popup(
            //        Language.getTranslatedKey("warning.unfinishedlanguage.title", null),
            //        Language.getTranslatedKey("warning.unfinishedlanguage.message", null),
            //        [
            //            {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), c:true}
            //        ],
            //    false, "", false, FlxPoint.weak(0, 0));
            //    openSubState(popup);
            }
        };
        audioTrackDropdown.text = Language.getTranslatedKey("menu.settings.general.audiotrack", null);
        for(str in ["Default", "Prototype", "Alpha", "Beta", "Final"]) audioTrackDropdown.dataSource.add(str);
        audioTrackDropdown.selectedItem = ["D"=>"Default", "P"=>"Prototype", "A"=>"Alpha", "B"=>"Beta", "F"=>"Final"][Preferences.getPref('musicPF')];
        audioTrackDropdown.onChange = (_:UIEvent)->{
            var preference:String = ["Default"=>"D", "Prototype"=>"P", "Alpha"=>"A", "Beta"=>"B", "Final"=>"F"][audioTrackDropdown.dataSource.get(audioTrackDropdown.selectedIndex)];
            trace(preference);
            #if(debug) Main.Trace(INFO, 'Changing music postfix to $preference and flushing to save file'); #end
            Preferences.setPref("musicPF", preference);
            Main.musicPostfix = preference;
        };

        autoPauseCheck.text = Language.getTranslatedKey("menu.settings.general.autopause", null);
        autoPauseCheck.onChange = (_:UIEvent)->{
            Preferences.setPref("autoPause", autoPauseCheck.selected);
            FlxG.autoPause = autoPauseCheck.selected; //immediately update the auto-pause setting without needing to restart the game.
        };
        autoPauseCheck.selected = Preferences.getPref("autoPause")??false;
    }

    /**CONTROLS SETTINGS OBJECTS AND FUNCTION**/
    //private var controlsText:FlxUIText; //TODO: controls ui lol.
    //private var ControlsScroll:ScrollableArea;
    //private var SBG:FlxUI9SliceSprite;
    //private var ControlObjects:Array<ControlsAssignmentObject>=[];
    //private var index:Int=0;
    //private var a:Int=0;
    //private function reloadControls() {
    //    if(Player.instance!=null) Player.instance.updateControls();
    //    for(ass in ControlObjects) {
    //        var keys = Main.controls.get(ass.text.text);
    //        if (keys == null) continue;
    //        ass.changeVisuals(Functions.FlxKeyFromInt(keys[0]), 1);
    //        ass.changeVisuals(Functions.FlxKeyFromInt(keys[1]), 2);
    //    }
    //}
    //private function createControlsUI() {
    //    SBG=new FlxUI9SliceSprite(controls.x+5, controls.y+5, Paths.image('ui', "chrome_inset"), new Rectangle(0,0, 490, 370), [5,5,8,8]);
    //    ControlsScroll = new ScrollableArea((FlxG.width/2-250)+5, (FlxG.height/2-200)+25, 490, 370, 1);
    //    Main.addCameraToGame(ControlsScroll, "settingsControlsScroller");
    //    for(control => keys in Main.controls) {
    //        var assigner:ControlsAssignmentObject = new ControlsAssignmentObject(5, 5+(27*index), control, keys);
    //        add(assigner);
    //        ControlsScroll.add(assigner);
    //        assigner.controlSubsateRequest = (obj:ControlsAssignmentObject, ind:Int)->{
    //            var sub:ControlsAssinmentKeyPressSubState = new ControlsAssinmentKeyPressSubState(obj, ind);
    //            openSubState(sub);
    //            sub.onReassignment = (key:FlxKey)->{
    //                Main.Trace(INFO, key);
    //                obj.changeVisuals(key.toString().toUpperCase(), ind); //SO, changing this WILL allow for saving controls, because im cool like that :sunglasses:
//
    //                switch(ind) { //these seem to be reversed for some reason, so ill just reverse the code and hope that works properly.
    //                    case 2: //meaning we're changing firstkey. (obj.input0);
    //                        if(obj.input1.text == obj.input0.text) {
    //                            obj.changeVisuals("NONE", 1);
    //                            Main.Trace(INFO, 'changing input0 to NONE');
    //                        }
    //                    case 1: //meaning we're changing secondKey (obj.input1);
    //                        if(obj.input1.text == obj.input0.text || obj.input0.text == obj.input1.text) { //i guess check both instances?
    //                            obj.changeVisuals("NONE", 2);
    //                            Main.Trace(INFO, 'changing input1 to NONE');
    //                        }
    //                }
    //                onControlsSave();
    //            };
    //        }
    //        assigner.updateControlsRequest=()->onControlsSave();
    //        ControlObjects.push(assigner);
    //        total_Controls++;
    //        index++;
    //    }
//
    //    if(ControlObjects.length==0) {
    //        var pulsingErrorText:ExtendedText = new ExtendedText(0, 0, 0, "", 12, true);
    //        pulsingErrorText.text = Language.getTranslatedKey("menu.settings.controls.nocontrols", pulsingErrorText);
    //        pulsingErrorText.alignment=CENTER;
    //        pulsingErrorText.applyMarkup(pulsingErrorText.text, [
    //            new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, false, null, false), "**"),
    //            new FlxTextFormatMarkerPair(new FlxTextFormat(0xFF0000, false, true, null, false), "&")
    //        ]);
    //        pulsingErrorText.camera = ControlsScroll;
    //        add(pulsingErrorText);
    //        pulsingErrorText.alpha=0;
    //        pulsingErrorText.setPosition(ControlsScroll.width/2-pulsingErrorText.width/2,ControlsScroll.height/2-pulsingErrorText.height/2);
    //        FlxTween.tween(pulsingErrorText, {alpha: 1}, 1.5428, {ease: FlxEase.sineInOut, type: PINGPONG});
    //    }
    //    controls.add(SBG);
//
    //    var popup:Popup = new Popup(
    //        Language.getTranslatedKey("warning.unfinishedlanguage.title", null),
    //        Language.getTranslatedKey("warning.unfinishedlanguage.message", null),
    //        [
    //            {l: Language.getTranslatedKey("warning.unfinishedlanguage.continue", null), c:true}
    //        ], false, "", false, FlxPoint.weak(0, 0)
    //    );
    //    openSubState(popup);
    //}

    //private function onControlsSave() {
    //    var controlsUpload:Array<{c:String, keys:Array<FlxKey>}>=[];
    //    for(i in 0...total_Controls) {
    //        #if(debug) Main.Trace(DEBUG, 'generating control scheme object...'); #end
    //        var ReadObject:ControlsAssignmentObject=ControlObjects[i];
//
    //        final key0:FlxKey=(ReadObject.input0.text==""||(ReadObject.input0.text=="NONE"||ReadObject.input0.text=="null"))?NONE:FlxKey.fromString(ReadObject.input0.text);
    //        final key1:FlxKey=(ReadObject.input1.text==""||(ReadObject.input1.text=="NONE"||ReadObject.input1.text=="null"))?NONE:FlxKey.fromString(ReadObject.input1.text);
    //        controlsUpload.push({c:ReadObject.text.text,keys:[key0,key1]});
    //        Main.Trace(INFO, 'Added: "{c:${ReadObject.text.text}, keys: [$key0, $key1]}" to `controlsUpload`');
    //    }
    //    Main.Trace(DEBUG, controlsUpload);
    //    Preferences.setPref("controls", controlsUpload);
    //    //no more middleman from Save.
    //    Main.controls = Functions.convertFromControlsArray(controlsUpload); //WHOOPS. kinda gotta re-call this each time.
    //    reloadControls();
    //}
}

private final class ControlsAssignmentObject extends FlxTypedSpriteContainer<Dynamic> {
    public var controlSubsateRequest:(ControlsAssignmentObject, Int)->Void;
    public var updateControlsRequest:Void->Void;
    private static final OFFSET_SPACING:Float=8;
    public var reassignButton:FlxUIButton;
    public var clearButton:FlxUIButton;
    public var reassignButton1:FlxUIButton;
    public var clearButton1:FlxUIButton;
    public var text:ExtendedText;
    public var input0:FlxInputText;
    public var input1:FlxInputText;

    public function new(x:Float,y:Float, controlName:String, controlKeys:Array<FlxKey>) {
        super(x, y);
        text = new ExtendedText(0, 0, 142, controlName, 12, true);

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
        super("", "", [], false, "", false, FlxPoint.weak(0, 0));
        ob = object;
        background.visible=background2.visible=header.visible=body.visible=false;
        for(butt in butts) butt.visible=butt.active=false;
        var text:ExtendedText = new ExtendedText(0, 0, 0, Language.getTranslatedKey("menu.settings.controls.reassigncontrol", null, ["[INDEX]"=>'$index', "[CONTROL]"=>'${object.text.text}']), 24);
        text.screenCenter();
        text.alignment=CENTER;
        addT(text);

        var text2:ExtendedText = new ExtendedText(text.x, text.y+text.height, 0, Language.getTranslatedKey("menu.settings.controls.reassigncontrolexitmsg", null), 8);
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
                close(); //close the substate but run the code on reassignment lol.
            }
        }
    }
}