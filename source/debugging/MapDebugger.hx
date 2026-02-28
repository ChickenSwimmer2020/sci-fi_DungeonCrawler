package debugging;

#if debug
import flixel.addons.ui.FlxUINumericStepper;
import flixel.text.FlxText;
import states.MainMenuState;
import backend.Language;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIState;

class MapDebugger extends FlxUIState{
    var widthStepper:FlxUINumericStepper;
    var heightStepper:FlxUINumericStepper;
    var GenerateButton:FlxUIButton;
    public function new() {
        super();
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.map.exit"), 24, true);
        add(text);

        // Define the tabs:
		var tabs = [
			{name: "tab_1", label: Language.getTranslatedKey(Main.curLanguage, "debugger.map.generatemenu")},
		];

		// Make the tab menu itself:
		var tab_menu = new FlxUITabMenu(null, tabs, true);
		tab_menu.y = 40;

        var tab_group_1 = new FlxUI(null, tab_menu, null);
		tab_group_1.name = "tab_1";

        tab_menu.addGroup(tab_group_1);
        add(tab_menu);

        widthStepper = new FlxUINumericStepper(5, 5, 1, 50, 3, 100, 0, 0);
        heightStepper = new FlxUINumericStepper(5+widthStepper.width, 5, 1, 50, 3, 100, 0, 0);
        tab_group_1.add(widthStepper);
        tab_group_1.add(heightStepper);

        GenerateButton = new FlxUIButton(5 + (widthStepper.width + heightStepper.width), 5, Language.getTranslatedKey(Main.curLanguage, "debugger.map.generate"), ()->{
            trace('generate map');
        });

		// Now make some content for it:

		/***TAB GROUP 1***/
	    //tabs_radio_1 = new FlxUIRadioGroup(10, 10, ["HEALTH", "STAMINA", "XP", "INVENTORY", "OTHER"], [
		//	Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Health"),
		//	Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Stamina"),
		//	Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Experience"),
		//	Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Inventory"),
        //    Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Custom")
		//]);
        //READING_button_read = new FlxUIButton(0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.save.parse"), ()->{
        //    returnText.text='${Language.getTranslatedKey(Main.curLanguage, "debugger.save.returned")}: ${Save.readFieldFromSave(READING_saveDropdown.selectedId, tabs_radio_1.selectedId, READING_textInputOther.text)}';
        //});
//
        //returnText = new FlxUIText(0, 0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.save.returned"), 8, true);
//
        //var dropdownList:Array<StrNameLabel>=[];
        //for(save in Main.saveFiles) {
        //    dropdownList.push(new StrNameLabel(save.remove('.sav'), save));
        //}
//
        //
//
        //READING_saveDropdown = new FlxUIDropDownMenu(0, 0, dropdownList??[new StrNameLabel("", Language.getTranslatedKey(Main.curLanguage, "debugger.save.nosaves"))]);
        //

//
		//tab_group_1.add(tabs_radio_1);
		//tab_group_1.add(READING_button_read);
        //READING_textInputOther = new FlxUIInputText(0, 0, Math.floor(tabs_radio_1.width), "", 12);
		//tab_group_1.add(READING_textInputOther);
		//tab_group_1.add(READING_saveDropdown);
        //tab_group_1.add(returnText);
//
//
        

        //READING_button_read.setPosition(tab_menu.x + (tab_menu.width-READING_button_read.width), tab_menu.y + (tab_menu.height-READING_button_read.height));
        //READING_textInputOther.setPosition(tabs_radio_1.x, tabs_radio_1.y+tabs_radio_1.height);
        //READING_saveDropdown.setPosition(tab_menu.x+tab_menu.width-READING_saveDropdown.width,tab_menu.y+20);
        //returnText.setPosition(tab_menu.x,tab_menu.y+(tab_menu.height-returnText.height));
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        //READING_textInputOther.visible = READING_textInputOther.active = (tabs_radio_1.selectedId=="OTHER"||tabs_radio_1.selectedId=="INVENTORY");

        if(FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(MainMenuState.new);
            openSubState(new DebuggerChooser());
        }
    }
}
#end