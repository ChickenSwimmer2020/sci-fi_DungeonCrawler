package backend.game.states.substates;

class OptionsMenuSubstate extends FlxUISubState{
    public function new() {
        super();

        var tabs = [
			{name: "tab_general", label: Language.getTranslatedKey(Main.curLanguage, "menu.options.tab.general")},
			{name: "tab_graphics", label: Language.getTranslatedKey(Main.curLanguage, "menu.options.tab.graphics")},
			#if !android {name: "tab_controls", label: Language.getTranslatedKey(Main.curLanguage, "menu.options.tab.controls")}, #end
			{name: "tab_difficulty", label: Language.getTranslatedKey(Main.curLanguage, "menu.options.tab.difficulty")},
		];

		// Make the tab menu itself:
		var tab_menu = new FlxUITabMenu(null, tabs, true);
		tab_menu.y = 40;
        tab_menu.resize(500, 400);
        tab_menu.screenCenter();


        //quickly init the groups and everything
        var general = new FlxUI(null, tab_menu, null); general.name = "tab_general";
        var graphics = new FlxUI(null, tab_menu, null); general.name = "tab_graphics";
        #if !android var controls = new FlxUI(null, tab_menu, null); general.name = "tab_controls"; #end
        var difficulty = new FlxUI(null, tab_menu, null); general.name = "tab_difficulty";


        tab_menu.addGroup(general);
        tab_menu.addGroup(graphics);
        #if !android tab_menu.addGroup(controls); #end
        tab_menu.addGroup(difficulty);
        add(tab_menu);
    }

    override public function update(elapsed:Float){
        super.update(elapsed);

        #if !android
            if(FlxG.keys.justPressed.ESCAPE) close(); //TODO: make act like a real internal window because fun
        #else
            //TODO: this.
        #end
    }
}