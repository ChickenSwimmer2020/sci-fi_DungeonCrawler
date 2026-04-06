package debugging;
#if (debug)
class SaveDebugger extends FlxUIState{
    var READING_button_read:FlxUIButton;
    var READING_textInputOther:FlxUIInputText;
    var READING_saveDropdown:FlxUIDropDownMenu;
    var tabs_radio_1:FlxUIRadioGroup;
    var returnText:FlxUIText;
    public function new() {
        super();
        Save.findSaves(); //just because its smart to do this everytime we load the state.
        var text:FlxText = new FlxText(0, 0, 0, Language.getTranslatedKey("debugger.save.exit", null), 24, true);
        add(text);

        // Define the tabs:
		var tabs = [
			{name: "tab_1", label: Language.getTranslatedKey("debugger.save.readmenu", null)},
		];

		// Make the tab menu itself:
		var tab_menu = new FlxUITabMenu(null, tabs, true);
		tab_menu.x = 500;
		tab_menu.y = 212;

		// Now make some content for it:

		/***TAB GROUP 1***/
	    tabs_radio_1 = new FlxUIRadioGroup(10, 10, ["HEALTH", "STAMINA", "XP", "INVENTORY", "OTHER"], [
			Language.getTranslatedKey("debugger.save.radio.health", null),
			Language.getTranslatedKey("debugger.save.radio.stamina", null),
			Language.getTranslatedKey("debugger.save.radio.experience", null),
			Language.getTranslatedKey("debugger.save.radio.inventory", null),
            Language.getTranslatedKey("debugger.save.radio.custom", null)
		]);
        READING_button_read = new FlxUIButton(0, 0, Language.getTranslatedKey("debugger.save.parse", null), ()->{
            returnText.text='${Language.getTranslatedKey("debugger.save.returned", null)}: ${Save.readFieldFromSave(READING_saveDropdown.selectedId, READING_textInputOther.text)}';
        });

        returnText = new FlxUIText(0, 0, 0, Language.getTranslatedKey("debugger.save.returned", null), 8, true);

        var dropdownList:Array<StrNameLabel>=[];
        for(save in Main.saveFiles) {
            dropdownList.push(new StrNameLabel(save.remove('.sav'), save));
        }
        if(dropdownList[0]==null) //fallback.
            dropdownList[0]=new StrNameLabel("", Language.getTranslatedKey("debugger.save.nosaves", null));


        READING_saveDropdown = new FlxUIDropDownMenu(0, 0, dropdownList);
        
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

        if(!READING_textInputOther.hasFocus && FlxG.keys.justPressed.BACKSPACE) {
            FlxG.switchState(MainMenuState.new);
            openSubState(new DebuggerChooser());
        }
    }
}
#end