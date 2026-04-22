package;

//flixel (never changes)
import flixel.FlxSprite;
import flixel.math.FlxPoint;
#if(debug)
    import flixel.system.debug.DebuggerUtil;
    import flixel.system.debug.Window;
#end
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.ui.FlxBar;
import flixel.addons.ui.FlxUIBar;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxHorizontalAlign;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.math.FlxRect;
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
import flixel.system.ui.FlxSoundTray;
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
import haxe.io.Error;

//js
#if html5
    import js.html.FileSystem;
    import js.html.File;
    import js.Browser;
#end

//sys (does change depending on platform.)
#if sys
    import sys.FileSystem;
    import backend.parsing.File; //extends sys.io.File, but gives me my custom functions & shit.
    import sys.thread.Mutex;
    import sys.thread.Thread;
#end

//openfl (never changes)
import openfl.events.UncaughtErrorEvent;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;
#if(html5)
    import openfl.Assets;
    import openfl.utils.AssetType;
#end


//lime
#if(html5)import lime.utils.Log;#end
import lime.utils.Resource;
import lime.ui.FileDialog;
import lime.app.Application;

//game (never changes)
import backend.game.states.GameState;
import backend.save.Save;
import backend.Paths;
import backend.parsing.Json; //dont use *, we cant include File since thats a sys thing.
import backend.generation.MapGenerator;
import backend.game.states.substates.OptionsMenuSubstate;
import backend.extensions.ExtendedCamera;
import backend.Language;
import backend.game.states.substates.HUDSubstate;
import states.MainMenuState;
import backend.shaders.RailFire;
import backend.ShaderCache;
import backend.game.objects.Pickup;
import backend.game.objects.tiles.Tile;
import backend.game.objects.Weapon;
import backend.game.GameMap;
import Flags;
import backend.Conductor;
import backend.SoundTray;
import backend.Music;
import states.IntroState;
import backend.ui.Popup;
import backend.game.states.substates.LoadGameSubstate;
import backend.shaders.ScreenShake;
import backend.game.objects.tiles.Breaker;
import backend.ai.BaseEnemy;
import backend.ui.ScrollableArea;
import backend.game.objects.tiles.SpecialTile;
import debugging.CutSceneCreator.KFDocument;
import debugging.CutSceneCreator.KFCutscene; //this actually isnt used for just debugging, AS ITS THE ACTUAL CUTSCENE TOO!!
#if (debug)
    import debugging.SaveDebugger;
    import debugging.MapDebugger;
    import debugging.AlphabetDebugger;
    import debugging.ErrorDebugger;
    import debugging.CutSceneCreator;
#end
import backend.Discord;

using StringTools;
using backend.Additions;
using flixel.util.FlxSpriteUtil;
using flixel.util.FlxStringUtil;