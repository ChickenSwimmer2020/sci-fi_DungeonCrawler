package debugging;


import flixel.text.FlxText;
import states.MainMenuState;
import backend.Language;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIRadioGroup;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIState;

class SaveDebugger extends FlxUIState{
    var READING_button_read:FlxUIButton;
    var READING_textInputOther:FlxUIInputText;
    var READING_saveDropdown:FlxUIDropDownMenu;
    var tabs_radio_1:FlxUIRadioGroup;
    var returnText:FlxUIText;
    public function new() {
        super();
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.save.exit"), 24, true);
        add(text);

        // Define the tabs:
		var tabs = [
			{name: "tab_1", label: Language.getTranslatedKey(Main.curLanguage, "debugger.save.readmenu")},
		];

		// Make the tab menu itself:
		var tab_menu = new FlxUITabMenu(null, tabs, true);
		tab_menu.x = 500;
		tab_menu.y = 212;

		// Now make some content for it:

		/***TAB GROUP 1***/
	    tabs_radio_1 = new FlxUIRadioGroup(10, 10, ["HEALTH", "STAMINA", "XP", "INVENTORY", "OTHER"], [
			Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Health"),
			Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Stamina"),
			Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Experience"),
			Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Inventory"),
            Language.getTranslatedKey(Main.curLanguage, "debugger.save.radio.Custom")
		]);
        READING_button_read = new FlxUIButton(0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.save.parse"), ()->{
            returnText.text='${Language.getTranslatedKey(Main.curLanguage, "debugger.save.returned")}: ${Save.readFieldFromSave(READING_saveDropdown.selectedId, tabs_radio_1.selectedId, READING_textInputOther.text)}';
        });

        returnText = new FlxUIText(0, 0, 0, Language.getTranslatedKey(Main.curLanguage, "debugger.save.returned"), 8, true);

        var dropdownList:Array<StrNameLabel>=[];
        for(save in Main.saveFiles) {
            dropdownList.push(new StrNameLabel(save.remove('.sav'), save));
        }

        

        READING_saveDropdown = new FlxUIDropDownMenu(0, 0, dropdownList??[new StrNameLabel("", Language.getTranslatedKey(Main.curLanguage, "debugger.save.nosaves"))]);
        
		var tab_group_1 = new FlxUI(null, tab_menu, null);
		tab_group_1.name = "tab_1";

		tab_group_1.add(tabs_radio_1);
		tab_group_1.add(READING_button_read);
        READING_textInputOther = new FlxUIInputText(0, 0, Math.floor(tabs_radio_1.width), "", 12);
		tab_group_1.add(READING_textInputOther);
		tab_group_1.add(READING_saveDropdown);
        tab_group_1.add(returnText);


        tab_menu.addGroup(tab_group_1);

        add(tab_menu);
        READING_button_read.setPosition(tab_menu.x + (tab_menu.width-READING_button_read.width), tab_menu.y + (tab_menu.height-READING_button_read.height));
        READING_textInputOther.setPosition(tabs_radio_1.x, tabs_radio_1.y+tabs_radio_1.height);
        READING_saveDropdown.setPosition(tab_menu.x+tab_menu.width-READING_saveDropdown.width,tab_menu.y+20);
        returnText.setPosition(tab_menu.x,tab_menu.y+(tab_menu.height-returnText.height));
    }
    override public function update(elapsed:Float) {
        super.update(elapsed);
        READING_textInputOther.visible = READING_textInputOther.active = (tabs_radio_1.selectedId=="OTHER"||tabs_radio_1.selectedId=="INVENTORY");

        if(FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(MainMenuState.new);
            openSubState(new DebuggerChooser());
        }
    }
    
}
