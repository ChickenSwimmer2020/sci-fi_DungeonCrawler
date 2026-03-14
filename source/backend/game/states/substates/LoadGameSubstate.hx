package backend.game.states.substates;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxRect;
import flixel.ui.FlxBar;
import flixel.addons.ui.FlxUIBar;
import flixel.addons.ui.FlxUISprite;
import flixel.addons.ui.FlxUIGroup;
import openfl.geom.Rectangle;

class SaveBox extends FlxTypedSpriteGroup<FlxSprite> {
    public var onSaveDestroyed:Void->Void;
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

        BG=new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_CHROME_LIGHT, new Rectangle(0, 0, 380, 100));
        CUTOUT=new FlxUI9SliceSprite(5, 5, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0, 0, 90, 90));
        text=new FlxUIText(100, 5, BG.width-105, '{NAME} - {DIFFICULTY}\n{H}:{M}:{S} || {DEPTH}\n{LEVEL}', 14, true);
        loadButton=new FlxUIButton(BG.width-85, BG.height-25, Language.getTranslatedKey("menu.save.loadsave"), ()->{
            Main.FILE=text.text.split('-')[0].trim(); //should work?
            #if debug FlxG.switchState(()->new TestingState(true)); #end
        }, false);
        loadButton.loadGraphic("flixel/images/ui/button.png", true, 80, 20); //probably gonna need to fix for android, although this menu is gonna look completely different on android
        loadButton.updateHitbox();
        loadButton.autoCenterLabel();
        deleteButton=new FlxUIButton(BG.width-105, BG.height-25, "", ()->{
            (Main.saveFile.data.saves:Map<String,SaveFile>).remove(text.text.split('-')[0].trim());
            onSaveDestroyed();
        }, false);
        deleteButton.loadGraphic(Paths.image('ui/menu', "button_delete"), true, 20, 20); //probably gonna need to fix for android, although this menu is gonna look completely different on android
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
}

class LoadGameSubstate extends FlxUISubState { //doing this now because i wanna get save resetting working now.
    var BG:FlxUI9SliceSprite;
    var SBG:FlxUI9SliceSprite;

    var scrollCam:FlxCamera;

    private var loadedSaves:Int=0;
    private var saveBoxes:Array<SaveBox>=[];
    
    private var scrollBar:FlxSprite;
    private var scrollIndex:Float=0;
    public function new() {
        super();
        Save.findSaves();

        BG = new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_CHROME, new Rectangle(0, 0, 400, 600));
        add(BG);
        BG.screenCenter();

        add(new FlxSprite(BG.x+BG.width, BG.y).makeGraphic(20, Math.floor(BG.height), 0x69FFFFFF));



        SBG = new FlxUI9SliceSprite(BG.x+5,BG.y+5,FlxUIAssets.IMG_CHROME_INSET,new Rectangle(0, 0, 390, 590));
        add(SBG);

        scrollCam=new FlxCamera(SBG.x, SBG.y, Math.floor(SBG.width), Math.floor(SBG.height), 1);
        scrollCam.bgColor=0x00000000;
        FlxG.cameras.add(scrollCam, false);
    

        for(key => save in (Main.saveFile.data.saves:Map<String,SaveFile>)??([]:Map<String,SaveFile>)) {
            if(save?.meta?.name == key){
                trace('valid save file $key, loading...');
                var box:SaveBox = new SaveBox(5, (5+(105*loadedSaves)), scrollCam);
                add(box);
                saveBoxes.push(box);
                box.setData(save);
                loadedSaves++;
                box.onSaveDestroyed = ()->{
                    var destroyedBox:Int = saveBoxes.indexOf(box);
                    //box.destroy();
                    remove(box, true);
                    for(furtherBox in destroyedBox...saveBoxes.length) {
                        saveBoxes[furtherBox].y-=(5+saveBoxes[furtherBox].height);
                    }
                };
            }
        }
        
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        #if !android
            FlxG.watch.addQuick('mouse', FlxG.mouse.wheel);
            FlxG.watch.addQuick('index', scrollIndex);
            if(scrollIndex>=0)
                scrollIndex-=(FlxG.mouse.wheel*10); //TODO: clamp properly so you cant scroll up at the start of it.
            else
                scrollIndex=0;
            

            scrollCam.scroll.y = scrollIndex;
            if(FlxG.keys.justPressed.ESCAPE) close();
        #else

        #end
    }
}