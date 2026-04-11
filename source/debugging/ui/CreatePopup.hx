package debugging.ui;

import backend.game.Player;

class CreatePopup extends FlxSubState {
    private var background:FlxUI9SliceSprite;
    private var background2:FlxUI9SliceSprite;
    private var header:FlxText;
    private var group:FlxSpriteGroup;
    private var popupCamera:FlxCamera;

    var textInput:FlxUIInputText;
    var scrolling:ScrollableArea;
    public function new() {
        super();
        Player.instance.canMove=Player.instance.canOpenInventory=false;
        popupCamera = new FlxCamera(0, 0, FlxG.width, FlxG.height);
        popupCamera.bgColor=0x00000000; //darkens stuff behind it :3
        FlxG.cameras.add(popupCamera, false);

        group=new FlxSpriteGroup(0, 0);
        var blurDarkenSprite:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width+200, FlxG.height+200, 0xFF000000);
        blurDarkenSprite.alpha=0.75;
        add(blurDarkenSprite);
        blurDarkenSprite.camera = popupCamera;
        add(group);

        background=new FlxUI9SliceSprite(0, 0, FlxUIAssets.IMG_CHROME_LIGHT, new Rectangle(0, 0, FlxG.width/4, FlxG.height/4));
        background2=new FlxUI9SliceSprite(5, 15, FlxUIAssets.IMG_CHROME_INSET, new Rectangle(0, 0, FlxG.width/4-10, FlxG.height/4-30));
        header = new FlxText(2, 0, background.width, Language.getTranslatedKey('game.debugger.create.pickup.title', null), 12); //8
        header.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
        header.alignment=RIGHT;

        group.add(background);
        group.add(background2);
        group.add(header);

 





        group.screenCenter();
        group.camera = popupCamera;
        blurDarkenSprite.alpha = 0.75;

        scrolling = new ScrollableArea(background2.x+5, background2.y+5, background2.width.floor()-10, background2.height.floor()-10, 1, false);
        FlxG.cameras.add(scrolling, false);

        textInput = new FlxUIInputText(0, 0, scrolling.width, "testitem", 8);
        add(textInput);
        textInput.scrollFactor.set(1, 1);
        textInput.camera = scrolling;

        var typeDropdown:FlxUIDropDownMenu = new FlxUIDropDownMenu(0, textInput.y+textInput.height, [
            new StrNameLabel("ITEM", "ITEM"),
            new StrNameLabel("CONSUMABLE", "CONSUMABLE"),
            new StrNameLabel("MEELEE", "MEELEE"),
            new StrNameLabel("RANGED", "RANGED"),
            new StrNameLabel("MAGIC", "MAGIC"),
            new StrNameLabel("NULL", "NULL")
        ]);
        add(typeDropdown);
        typeDropdown.scrollFactor.set(1, 1);
        typeDropdown.camera = scrolling;

        var gunTypeDropdown:FlxUIDropDownMenu = new FlxUIDropDownMenu(typeDropdown.x+typeDropdown.width, textInput.y+textInput.height, [
            new StrNameLabel("LASER", "LASER"),
            new StrNameLabel("EXPLOSIVE", "EXPLOSIVE"),
            new StrNameLabel("BALLISTIC", "BALLISTIC"),
            new StrNameLabel("PLASMA", "PLASMA"),
            new StrNameLabel("OTHER", "OTHER")
        ]);
        add(gunTypeDropdown);
        gunTypeDropdown.scrollFactor.set(1, 1);
        gunTypeDropdown.camera = scrolling;

        var potionDropdown:FlxUIDropDownMenu = new FlxUIDropDownMenu(0, gunTypeDropdown.y+textInput.height, [
            new StrNameLabel("HEALTH", "HEALTH"),
            new StrNameLabel("NONE", "NONE"),
        ]);
        add(potionDropdown);
        potionDropdown.scrollFactor.set(1, 1);
        potionDropdown.camera = scrolling;


        var isPotion:FlxUICheckBox=new FlxUICheckBox(potionDropdown.x+potionDropdown.width, potionDropdown.y, null, null, "is Potion", 100, null, ()->{}); 
        add(isPotion);
        isPotion.scrollFactor.set(1, 1);
        isPotion.camera = scrolling;
        


        var durabilityThingy:FlxUINumericStepper = new FlxUINumericStepper(gunTypeDropdown.x+gunTypeDropdown.width, gunTypeDropdown.y, 1, 100, 0, 100, 0, 1);
        add(durabilityThingy);
        durabilityThingy.scrollFactor.set(1, 1);
        durabilityThingy.camera = scrolling;


        var createButton:FlxButton = new FlxButton(0, 0, Language.getTranslatedKey("game.debugger.create.pickup.create", null), ()->{
            GameMap.instance.add(new Pickup(GameMap.instance.plr.x, GameMap.instance.plr.y, {
                type: ItemType.fromString(typeDropdown.selectedLabel),
                item: textInput.text,
                damage: [],
                durability: durabilityThingy.value,
                gunType: gunTypeDropdown.selectedLabel,
                potionType: potionDropdown.selectedLabel,
                isPotion: isPotion.checked,
                
                MagicType: FIRE,
                weaponType: GUN,
                consumableType: CRUMB,
            }));


            GameDebugger.instance.close();
            close();
        });
        var cancelButton:FlxUIButton=new FlxUIButton(80, 0, "x", ()->{
            close();
        }, false);
        cancelButton.loadGraphic(Paths.image('ui/menu', "button_delete"), true, 20, 20);
        cancelButton.updateHitbox();
        cancelButton.autoCenterLabel();
        group.add(createButton);
        group.add(cancelButton);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        if(FlxG.mouse.justPressed){
            if(FlxG.mouse.overlaps(textInput, scrolling)){
                textInput.hasFocus=true;
            }else{
                textInput.hasFocus=false;
            }
        }
    }

    override public function destroy() {
        FlxG.cameras.remove(popupCamera);
        popupCamera=null;
        Player.instance.canMove=Player.instance.canOpenInventory=true;
        super.destroy();
    }
}