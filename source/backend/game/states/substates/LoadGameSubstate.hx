package backend.game.states.substates;

class SaveBox extends FlxTypedSpriteGroup<FlxSprite> {
    public var requestSubstateOpen:(String,String,Array<{l:String,?f:Void->Void,c:Bool}>)->Void;
    public var onSaveDestroyed:(String)->Void;
    private var BG:FlxUI9SliceSprite;
    private var CUTOUT:FlxUI9SliceSprite;
    private var loadButton:FlxUIButton;
    private var deleteButton:FlxUIButton;
    private var text:FlxUIText;
    private var healthBar:FlxUIBar;
    private var staminaBar:FlxUIBar;
    private var xpBar:FlxUIBar;
    public function new(x:Float,y:Float,cam:FlxCamera) {
        super(x,y);

        BG=new FlxUI9SliceSprite(0, 0, Paths.image('ui', 'chrome_light'), new Rectangle(0, 0, 380, 100), [5,5,8,8]);
        CUTOUT=new FlxUI9SliceSprite(5, 5, Paths.image('ui', 'chrome_inset'), new Rectangle(0, 0, 90, 90), [5,5,8,8]);
        text=new FlxUIText(100, 5, BG.width-105, '{NAME} - {DIFFICULTY}\n{H}:{M}:{S} || {DEPTH}\n{LEVEL}', 14, true);
        loadButton=new FlxUIButton(BG.width-85, BG.height-25, Language.getTranslatedKey("menu.save.loadsave", loadButton), ()->{
            Main.FILE=text.text.split('-')[0].trim(); //should work?
            FlxG.switchState(()->new GameState(true));
        }, false);
        loadButton.loadGraphic("flixel/images/ui/button.png", true, 80, 20);
        loadButton.updateHitbox();
        loadButton.autoCenterLabel();
        deleteButton=new FlxUIButton(BG.width-105, BG.height-25, "", ()->{
            if(FlxG.keys.pressed.SHIFT){ //just straight up delete the save if you hold shift.
                onSaveDestroyed(text.text.split('-')[0].trim());
                (Main.saveFile.data.saves:Map<String,SaveFile>).remove(text.text.split('-')[0].trim());
                trace('attempted to get save file: ${text.text.split('-')[0].trim()} and got: ${(Main.saveFile.data.saves:Map<String,SaveFile>).get(text.text.split('-')[0].trim())} (this should be null.)');
            }else{
                requestSubstateOpen(Language.getTranslatedKey("menu.save.delete.popup.title", null), Language.getTranslatedKey("menu.save.delete.popup.message", null, ["SVE"=>text.text.split('-')[0].trim()]), [
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.cancel", null), c:true},
                    {l:Language.getTranslatedKey("menu.save.delete.popup.options.delete", null), f: ()->{
                        onSaveDestroyed(text.text.split('-')[0].trim());
                        (Main.saveFile.data.saves:Map<String,SaveFile>).remove(text.text.split('-')[0].trim());
                        trace('attempted to get save file: ${text.text.split('-')[0].trim()} and got: ${(Main.saveFile.data.saves:Map<String,SaveFile>).get(text.text.split('-')[0].trim())} (this should be null.)');
                    }, c:true}
                ]);
            }
        }, false);
        deleteButton.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
        deleteButton.updateHitbox();
        deleteButton.autoCenterLabel();
        deleteButton.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_delete")), 0, 0, true);
        add(BG);
        add(CUTOUT);
        add(text);
        healthBar = new FlxUIBar(100, BG.height-25, FlxBarFillDirection.LEFT_TO_RIGHT, 169, 7, null, "", 0, 100, true);
        healthBar.set_style({filledColors:[0xFFFF0000],emptyColors:[0xFF670000],borderColor:0xFF000000,filledColor:null,emptyColor:null,chunkSize:null,gradRotation:null,filledImgSrc:"",emptyImgSrc:""});
        add(healthBar);
        staminaBar = new FlxUIBar(100, BG.height-18, FlxBarFillDirection.LEFT_TO_RIGHT, 169, 7, null, "", 0, 100, true);
        staminaBar.set_style({filledColors:[0xFF00FFFF],emptyColors:[0xFF006767],borderColor:0xFF000000,filledColor:null,emptyColor:null,chunkSize:null,gradRotation:null,filledImgSrc:"",emptyImgSrc:""});
        add(staminaBar);
        xpBar = new FlxUIBar(100, BG.height-11, FlxBarFillDirection.LEFT_TO_RIGHT, 169, 7, null, "", 0, 100, true);
        xpBar.set_style({filledColors:[0xFFFFFF00],emptyColors:[0xFF676700],borderColor:0xFF000000,filledColor:null,emptyColor:null,chunkSize:null,gradRotation:null,filledImgSrc:"",emptyImgSrc:""});
        add(xpBar);

        add(loadButton);
        add(deleteButton);
        for(thing in this.members){
            thing.camera=cam;
        }
    }

    public function setData(save:SaveFile) {
        text.text = '${save.meta.name} - ${save.meta.difficulty}\n${save.meta.playtime.H}:${save.meta.playtime.M}:${save.meta.playtime.s} || ${save.meta.depth}\n${save.meta.level}';
        healthBar.value = save.health;
        staminaBar.value = save.stamina;
        xpBar.value = save.xp;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(FlxG.keys.pressed.SHIFT) deleteButton.color=0xFFFF0000;
        else deleteButton.color=0xFFFFFFFF;
    }
}

class LoadGameSubstate extends FlxUISubState { //doing this now because i wanna get save resetting working now.
    var BG:FlxUI9SliceSprite;
    var SBG:FlxUI9SliceSprite;

    var scrollCam:ScrollableArea;

    private var loadedSaves:Int=0;
    private var saveBoxes:Array<SaveBox>=[];
    
    private var scrollBar:FlxSprite;
    private var scrollIndex:Float=0;
    public function new() {
        super();
        Save.findSaves();

        BG = new FlxUI9SliceSprite(0, 0, Paths.image('ui', 'chrome'), new Rectangle(0, 0, 400, 600), [5,5,8,8]);
        add(BG);
        BG.screenCenter();

        add(new FlxSprite(BG.x+BG.width, BG.y).makeGraphic(20, Math.floor(BG.height), 0x69FFFFFF));



        SBG = new FlxUI9SliceSprite(BG.x+5,BG.y+5,Paths.image('ui', "chrome_inset"),new Rectangle(0, 0, 390, 590), [5,5,8,8]);
        add(SBG);

        scrollCam=new ScrollableArea(SBG.x, SBG.y, Math.floor(SBG.width), Math.floor(SBG.height), 1);
        Main.addCameraToGame(scrollCam, "loadGameScroller");
    

        for(save in (Main.saveFile.data.saves:Map<String,SaveFile>)??([]:Map<String,SaveFile>)) {
            if(Save.isValid(save)) {
                #if(debug&&(windows||hl)) Main.LOG('valid save file, ${save?.meta?.name} loading...'); #end
                var box:SaveBox = new SaveBox(5, (5+(105*loadedSaves)), scrollCam);
                add(box);
                saveBoxes.push(box);
                box.setData(save);
                loadedSaves++;
                box.onSaveDestroyed = (saveName:String)->{
                    var destroyedBox:Int = saveBoxes.indexOf(box);
                    //box.destroy();
                    remove(box, true);
                    for(furtherBox in destroyedBox...saveBoxes.length) {
                        saveBoxes[furtherBox].y-=(5+saveBoxes[furtherBox].height);
                    }
                };
                box.requestSubstateOpen = (title:String, message:String, buttons:Array<{l:String,?f:Void->Void,c:Bool}>)->{
                    var popup:Popup = new Popup(
                        title, message, buttons, false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0)
                    );
                    openSubState(popup);
                }
            }else{
                trace('attempted to load invalid save "${save?.meta?.name}". skipping...'); //this shouldnt happen but just in case.
            }
        }
        
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if(FlxG.keys.justPressed.ESCAPE) close();
    }
}