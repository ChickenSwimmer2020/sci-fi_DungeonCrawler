package debugging.ui;

import backend.game.Player;
#if debug
class CreatePopup extends Popup {
    var textInput:FlxUIInputText;
    var typeDropdown:FlxUIDropDownMenu;
    var potionDropdown:FlxUIDropDownMenu;
    var gunTypeDropdown:FlxUIDropDownMenu;
    var isPotion:FlxUICheckBox;
    var durabilityThingy:FlxUINumericStepper;
    var weaponTypeDropdown:FlxUIDropDownMenu;
    var magicTypeDropdown:FlxUIDropDownMenu;
    var consumableTypeDropdown:FlxUIDropDownMenu;
    var createButton:FlxButton;
    var scrolling:ScrollableArea;
    var hintText:FlxText;
    public function new() {
        super(Language.getTranslatedKey("game.debugger.create.pickup.title", null), "", [], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0), true);
        body.visible=body.active=false; //no body text, because everything is getting moved around n shtuff.
        for(butt in butts) butt.visible=butt.active=false; //also no buttons, because we need to manually make the button.
        header.alignment=RIGHT;
        Player.instance.canMove=Player.instance.canOpenInventory=false;

        var blurDarkenSprite:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width+200, FlxG.height+200, 0xFF000000);
        blurDarkenSprite.alpha=0.75;
        add(blurDarkenSprite);


        hintText=new FlxText(5, background2.y+background2.height, 0, "HINT", 8, true);
        hintText.color = 0xFF000000;
        group.add(hintText);

        scrolling = new ScrollableArea(background2.x+5, background2.y+5, background2.width.floor()-10, background2.height.floor()-10, 1, false);
        Main.addCameraToGame(scrolling, "createpopupscrollablearea");

        textInput = new FlxUIInputText(0, 0, scrolling.width-120, "testitem", 12);
        add(textInput);
        textInput.scrollFactor.set(1, 1);
        textInput.camera = scrolling;
        textInput.fieldHeight = 20;

        typeDropdown = new FlxUIDropDownMenu(scrolling.width-120, 0, [
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

        potionDropdown = new FlxUIDropDownMenu(0, 20, [
            new StrNameLabel("HEALTH", "HEALTH"),
            new StrNameLabel("NONE", "NONE"),
        ]);
        insert(members.indexOf(typeDropdown)-1, potionDropdown);
        potionDropdown.scrollFactor.set(1, 1);
        potionDropdown.camera = scrolling;

        gunTypeDropdown = new FlxUIDropDownMenu(0, 40, [
            new StrNameLabel("LASER", "LASER"),
            new StrNameLabel("EXPLOSIVE", "EXPLOSIVE"),
            new StrNameLabel("BALLISTIC", "BALLISTIC"),
            new StrNameLabel("PLASMA", "PLASMA")
        ]);
        insert(members.indexOf(potionDropdown)-1, gunTypeDropdown);
        gunTypeDropdown.scrollFactor.set(1, 1);
        gunTypeDropdown.camera = scrolling;




        isPotion=new FlxUICheckBox(potionDropdown.x+potionDropdown.width, 20, null, null, "is Potion", 100, null, ()->{}); 
        insert(members.indexOf(gunTypeDropdown)-1, isPotion);
        isPotion.scrollFactor.set(1, 1);
        isPotion.camera = scrolling;


        durabilityThingy = new FlxUINumericStepper(0, 20, 1, 100, 0, 100, 0, 1);
        insert(members.indexOf(typeDropdown)-1, durabilityThingy);
        durabilityThingy.scrollFactor.set(1, 1);
        durabilityThingy.camera = scrolling;
        durabilityThingy.x=scrolling.width-durabilityThingy.width;

        weaponTypeDropdown = new FlxUIDropDownMenu(scrolling.width-120, 40, [
            new StrNameLabel("GUN","GUN"),
            new StrNameLabel("STAFF","STAFF"),
            new StrNameLabel("WAND","WAND"),
            new StrNameLabel("SWORD","SWORD"),
            new StrNameLabel("DAGGER","DAGGER"),
            new StrNameLabel("LONGSWORD","LONGSWORD")
        ]);
        insert(members.indexOf(typeDropdown)-2, weaponTypeDropdown);
        weaponTypeDropdown.scrollFactor.set(1, 1);
        weaponTypeDropdown.camera = scrolling;

        magicTypeDropdown = new FlxUIDropDownMenu(0, 60, [
            new StrNameLabel("FIRE","FIRE"),
            new StrNameLabel("WATER","WATER"),
            new StrNameLabel("AIR","AIR"),
            new StrNameLabel("DARK","DARK"),
            new StrNameLabel("EARTH","EARTH"),
            new StrNameLabel("ARCANE","ARCANE"),
            new StrNameLabel("OTHER","OTHER")
        ]);
        insert(members.indexOf(gunTypeDropdown)-2, magicTypeDropdown);
        magicTypeDropdown.scrollFactor.set(1, 1);
        magicTypeDropdown.camera = scrolling;

        consumableTypeDropdown = new FlxUIDropDownMenu(scrolling.width-120, 60, [
            new StrNameLabel("CRUMB","CRUMB"),
            new StrNameLabel("SNACK","SNACK"),
            new StrNameLabel("MEAL","MEAL"),
            new StrNameLabel("SHOT","SHOT"),
            new StrNameLabel("GLASS","GLASS"),
            new StrNameLabel("BOTTLE","BOTTLE")
        ]);
        insert(members.indexOf(weaponTypeDropdown)-2, consumableTypeDropdown);
        consumableTypeDropdown.scrollFactor.set(1, 1);
        consumableTypeDropdown.camera = scrolling;

        createButton = new FlxButton(0, 0, Language.getTranslatedKey("game.debugger.create.pickup.button", null), ()->{
            GameMap.instance.add(new Pickup(GameMap.instance.plr.x, GameMap.instance.plr.y, {
                type: ItemType.fromString(typeDropdown.selectedLabel),
                item: textInput.text,
                damage: [],
                durability: durabilityThingy.value,
                gunType: gunTypeDropdown.selectedLabel,
                potionType: potionDropdown.selectedLabel,
                isPotion: isPotion.checked,
                MagicType: magicTypeDropdown.selectedLabel,
                weaponType: weaponTypeDropdown.selectedLabel,
                consumableType: consumableTypeDropdown.selectedLabel,
            }));


            GameDebugger.instance.close();
            close();
        });
        var cancelButton:FlxUIButton=new FlxUIButton(80, 0, "x", ()->{
            close();
        }, false);
        cancelButton.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
        cancelButton.updateHitbox();
        cancelButton.autoCenterLabel();
        group.add(createButton);
        group.add(cancelButton);
    }

    private var hoveredKey:String = null;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        final hints:Array<{obj:FlxObject, key:String}> = [
            {obj: textInput,                    key: 'game.debugger.create.hint.pickupname'},
            {obj: typeDropdown.header,          key: 'game.debugger.create.hint.pickuptype'},
            {obj: potionDropdown.header,        key: 'game.debugger.create.hint.pickuppotiontype'},
            {obj: gunTypeDropdown.header,       key: 'game.debugger.create.hint.pickupguntype'},
            {obj: isPotion,                     key: 'game.debugger.create.hint.pickupispotion'},
            {obj: durabilityThingy,             key: 'game.debugger.create.hint.pickupdurability'},
            {obj: weaponTypeDropdown.header,    key: 'game.debugger.create.hint.pickupweapontype'},
            {obj: magicTypeDropdown.header,     key: 'game.debugger.create.hint.pickupmagictype'},
            {obj: consumableTypeDropdown.header,key: 'game.debugger.create.hint.pickupconsumabletype'},
            {obj: createButton,                 key: 'game.debugger.create.hint.insert'},
        ];

        for (hint in hints) {
            if (FlxG.mouse.overlaps(hint.obj, hint.obj!=createButton?scrolling:FlxG.camera)) {
                hoveredKey = hint.key;
                break;
            }
        }

        if (hoveredKey != null) {
            hintText.visible = true;
            var translated = Language.getTranslatedKey(hoveredKey, null);
            if (hintText.text != translated) hintText.text = translated;
        } else {
            hintText.visible = false;
        }

        if(FlxG.mouse.justPressed){
            if(FlxG.mouse.overlaps(textInput, scrolling)){
                textInput.hasFocus=true;
            }else{
                textInput.hasFocus=false;
            }
        }
    }

    override public function destroy() {
        Player.instance.canMove=Player.instance.canOpenInventory=true;
        super.destroy();
    }
}
#end