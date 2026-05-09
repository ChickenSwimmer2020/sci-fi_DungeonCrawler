package debugging.ui;

@:xml('<!--yeah, we\'re hardcoding this shite. LOL-->
    <vbox width="100%" height="100%">
        <hbox width="100%" height="30">
            <menubar id="menuBar" width="50%">
                <menu id="saveMenu" text="Save">
                    <menuitem id="SVE_Reader" text="Reader" shortcutText="Ctrl+Shift+S+R"/>
                    <menuitem id="SVE_Writer" text="Writer" shortcutText="Ctrl+Shift+S+W"/>
                    <!-- <menuseparator /> -->
                </menu>
                <button id="ALP_Viewer" height="100%" text="Alphabet" />
                <menu id="errorMenu" text="Error"/>
                <button id="mapEditorOpen" height="100%" text="Map" />
                <button id="cutsceneEditorOpen" height="100%" text="Cutscene" />
            </menubar>
            <window-list id="windowListA" width="50%" height="30" /> <!--beacuse we use windows for basically everything >:3-->
        </hbox>
        <label style="top:30px;font-size:20px;" id="leaveText" width="100%"/>
    </vbox>
')
class DebuggerMainView extends VBox {
    private static var keyCodes:Map<Array<FlxKey>, Void->Void>=[];
    public var saveReader:Void->Void;
    public var saveWriter:Void->Void;
    public var alphabetViewer:Void->Void;
    public function new() {
        super();
        keyCodes = [ //man fuck varible initilization.
            [CONTROL, SHIFT, S, R]=>()->saveReader(),
            [CONTROL, SHIFT, S, W]=>()->saveWriter()
            //[CONTROL, Q]=>()->FlxG.switchState(MainMenuState.new)
        ];
        mapEditorOpen.text = Language.getTranslatedKey("debugger.menuBar.mapeditor", null);
        cutsceneEditorOpen.text = Language.getTranslatedKey("debugger.menuBar.cutsceneeditor", null);
        errorMenu.text = Language.getTranslatedKey("debugger.menubar.error.menutitle", null);
        saveMenu.text = Language.getTranslatedKey("debugger.menubar.save.menutitle", null);
        SVE_Reader.text = Language.getTranslatedKey("debugger.menubar.save.reader", null);
        SVE_Writer.text = Language.getTranslatedKey("debugger.menubar.save.writer", null);
        ALP_Viewer.text = Language.getTranslatedKey("debugger.menubar.alphabet", null);
        leaveText.text = Language.getTranslatedKey("debugger.genericexit", null, ["[EXITKEY]"=>"BACKSPACE"]);

        percentWidth=percentHeight=100;

        SVE_Reader.onClick = (_:MouseEvent)->saveReader();
        SVE_Writer.onClick = (_:MouseEvent)->saveWriter();
        ALP_Viewer.onClick = (_:MouseEvent)->alphabetViewer();
    }
    var commandJustRan:Bool=false;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        for(controls => command in keyCodes){
            if(!commandJustRan && Functions.allKeysPressed(controls)){
                command();
                commandJustRan=true;
            }else{
                if(Functions.allKeysPressed(controls, true)) commandJustRan=false; //commands shoud no longer chain infinitely.
            }
        }
    }
}