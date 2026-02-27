package;

//flixel (never changes)
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.debug.DebuggerUtil;
import flixel.system.debug.Window;
import flixel.util.FlxHorizontalAlign;
import flixel.FlxG;

//haxe (never changes)
import haxe.Json;

//sys (does change depending on platform.)
import sys.io.File;
import sys.FileSystem;
import sys.io.File;


//openfl (never changes)
import openfl.text.TextField;
import openfl.display.BitmapData;



//game (never changes)
import backend.save.Save;
import backend.Paths;
import backend.generation.MapGenerator.MapFile;
import backend.generation.MapGenerator;

using StringTools;
using backend.Additions;