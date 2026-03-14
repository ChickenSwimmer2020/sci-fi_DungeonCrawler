package;

//flixel (never changes)
import flixel.FlxSprite;
import flixel.math.FlxPoint;
#if(debug&&!android)
    import flixel.system.debug.DebuggerUtil;
    import flixel.system.debug.Window;
#end
import flixel.util.FlxHorizontalAlign;
import flixel.FlxG;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.FlxSubState;
import flixel.FlxCamera.FlxCameraFollowStyle;
import flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer;
import flixel.graphics.frames.FlxTileFrames;
import flixel.animation.FlxAnimationController;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;

//flixel ui stuff
import flixel.addons.ui.FlxUIAssets;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUISubState;
import flixel.addons.ui.FlxUI;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIText;
import flixel.addons.ui.StrNameLabel;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUIRadioGroup;

//haxe (never changes)
import haxe.Json;

//sys (does change depending on platform.)
#if !html5
    import sys.io.File;
    import sys.FileSystem;
    import sys.io.File;
#end

//openfl (never changes)
import openfl.text.TextField;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.filters.ShaderFilter;
#if(html5||android)import openfl.Assets;#end

//lime
#if(html5||android)import lime.utils.Log;#end
import lime.app.Application;

//game (never changes)
import backend.save.Save;
import backend.Paths;
import backend.generation.MapGenerator;
import backend.game.states.substates.OptionsMenuSubstate;
import backend.game.states.substates.HUDSubstate.Item;
import backend.Language;
import backend.game.objects.Weapon.WeaponParser;
import backend.game.states.substates.HUDSubstate;
import states.MainMenuState;
import backend.shaders.RailFire;
import backend.shaders.MaskShader;
import backend.ShaderCache;
import backend.game.objects.Pickup;
import backend.game.objects.Tile;
import backend.game.objects.Weapon;
import backend.game.GameMap;
import Flags;
import backend.Additions.Functions;
import backend.Alphabet;
#if (debug)
    import debugging.SaveDebugger;
    import debugging.MapDebugger;
    import debugging.AlphabetDebugger;
#end

using StringTools;
using backend.Additions;
using flixel.util.FlxSpriteUtil;