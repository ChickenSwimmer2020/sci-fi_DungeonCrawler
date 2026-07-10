package;

//haxeui
import haxe.ui.components.DropDown;
import haxe.ui.events.UIEvent;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.events.MenuEvent;
import haxe.ui.events.MouseEvent;
import haxe.ui.containers.menus.Menu;
import haxe.ui.components.TextField as HUITextField;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.Toolkit;
import haxe.ui.core.Screen;
import haxe.ui.containers.VBox;
import haxe.ui.containers.ListView;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TreeView;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.util.Timer;
import haxe.ui.notifications.Notification;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.containers.windows.WindowManager;
import haxe.ui.components.Label;
import haxe.ui.dragdrop.DragManager;
import haxe.ui.components.Image;
import haxe.ui.containers.SideBar;

//flixel (never changes)
import flixel.FlxSprite;
import flixel.math.FlxPoint;
#if(debug)
    import flixel.system.debug.DebuggerUtil;
    import flixel.system.debug.Window;
#end
import flixel.util.FlxGradient;
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.ui.FlxBar;
import flixel.addons.ui.FlxUIBar;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxHorizontalAlign;
import flixel.FlxObject;
import flixel.sound.FlxSound;
import flixel.FlxG;
import flixel.math.FlxRect;
import flixel.util.typeLimit.OneOfTwo;
import flixel.util.typeLimit.NextState.InitialState;
import flixel.util.FlxSave;
import flixel.group.FlxGroup;
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
import flixel.addons.ui.interfaces.IFlxUIButton;
import flixel.system.ui.FlxSoundTray;
import flixel.system.FlxAssets;
import flixel.FlxBasic;
import flixel.addons.display.FlxRuntimeShader;

//flixel ui stuff
import flixel.addons.ui.*;
import flixel.ui.FlxButton;

//haxe (never changes)
import haxe.io.Error;
import haxe.PosInfos;
import haxe.io.Bytes;
import haxe.zip.Entry;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import haxe.DynamicAccess;

//sys (does change depending on platform.)
import sys.FileSystem;
import sys.thread.Mutex;
import sys.thread.Thread;

//openfl (never changes)
import openfl.events.UncaughtErrorEvent;
import openfl.events.Event;
import openfl.geom.Matrix;
import openfl.text.TextField;
import openfl.display.BitmapData;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;
import openfl.filesystem.File as OpenFLFile;


//lime
import lime.utils.Resource;
import lime.ui.FileDialog;
import lime.app.Application;
import lime.text.Font;

//game (never changes)
import Flags;
//backend (why the fuck do i have to do each folder individually??)
import backend.Conductor;
import backend.Discord;
import backend.Language;
import backend.Music;
import backend.Paths;
import backend.Preferences;
import backend.ShaderCache;
import backend.SoundTray;
import backend.ai.BaseEnemy;
import backend.extensions.ExtendedCamera;
import backend.extensions.ExtendedText;
import backend.generation.MapAssembler;
import backend.generation.MapAssemblerLoader;
import backend.generation.MapGenerator;
import backend.parsing.File;
import backend.parsing.Json;
import backend.save.Save;
import backend.shaders.*;
import backend.ui.Popup;
import backend.ui.ScrollableArea;
//game backend
import backend.game.GameMap;
import backend.game.Player;
import backend.game.cutscenes.*;
import backend.game.objects.Pickup;
import backend.game.objects.Weapon;
import backend.game.objects.tiles.Breaker;
import backend.game.objects.tiles.SpecialTile;
import backend.game.objects.tiles.Tile;
import backend.game.states.DeathState;
import backend.game.states.GameState;
import backend.game.states.substates.LoadGameSubstate;
import backend.game.states.substates.OptionsMenuSubstate;
import backend.game.states.substates.PauseMenu;
import backend.game.states.substates.HUDSubstate;
import states.AwardsGalleryState;
import states.GameIntroState;
import states.IntroState;
import states.MainMenuState;
#if (debug)
    import debugging.CutsceneMaker;
    import debugging.Debugger;
    import debugging.GameDebugger;
    import debugging.MapDebugger;
    import debugging.ui.CreatePopup;
    import debugging.ui.DebuggerMainView;
    import debugging.ui.cc.Layer;
    import debugging.ui.cc.MainView as CutsceneMakerMainView;
#end

using StringTools;
using backend.Additions;
using flixel.util.FlxSpriteUtil;
using flixel.util.FlxStringUtil;
using haxe.ui.animation.AnimationTools;