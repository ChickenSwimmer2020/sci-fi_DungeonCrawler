# ChangeLog

<!--
STYLE GUIDE!! (mostly for me) -ChickenSwimmer2020
**emphasize**
*enunciate*
>> comment
> update notes
`Class`
**`VARIABLE`**

start every "*" with a Capital letter, and end with a period

** Prototype Update {add "_MAJOR" or "_HOTFIX" as needed} [VERSION] ([GENERAL NAME])
-->

## Prototype Update 0.04.1.05 (fixes and moves)

> trying to actually start fixing features and whatnot, trying to get some stuff working properly that was implemented
> a WHILE ago lmao.

* Moved all imports to Import.hx, wondering if we can put typedefs/enums in there to move some clutter away from other files
* `TestingState` is functional again. finally.
* `Breaker`'s audio no longer plays at half volume when first loading into a map
* `Tile`'s info notif now only works in map editor and when right clicked
* `Player` overrides **`testingMode`** if `Main.loadedTestingState` is true.
* `GameState` no longer makes two instances of maps and players if loading into `TestingState`
* Removed some "#if(sys)#else" conditionals from `Music`
* `DynamicMusic` is fucked.
* * Solar please fix.
* Removed an old unused map from `Paths`
* `Preferences` now properly loads controls from last game session
* Changed `Popup`'s old **`throw`** error to use `Main.Trace()`
* Renamed `source\debugging\ui\MainView.hx` to `source\debugging\ui\DebuggerMainView.hx`.
* Client now loads controls from uPrefs file instead of defaulting every session.
* Attempted updated to `AwardsGalleryState` to make cool transitions
* * Solar please fix
* `TestingState` was made functional again.
* When moving an item in the inventory, the graphic will now load correctly.
* `SpecialTile` no longer hides cursor while the inspect popup is visible.

## Prototype Update 0.04.1.04.1 (save error type) -- ZSolarDev

> Added new error type if a save fails to save correctly
> CurruptSave

* Added Error type for if a save fails to save like a save should save.
* * yes that is gramatically correct.
* * * no do not fact check me.
* Changed a bunch of Reflect calls so that windows doesnt have explosive diarrhea and fucking die.

## Prototype Update 0.04.1.04 (general fixes & shiz)

> Trying to make a lot of stuff actually work, mostly saves. but yeah its uhhh.
> fucky to say the least.

* Removed a bunch of traces when validating save files to **hopefully** make validation *slightly* faster.
* Updated `build.bat` to only install lime 8.3.1, instead of trying to rebuild binaries. since only android would need that, and it breaks trying to build.
* Added "SUBSYSTEM" mechanic idea to `Mechanics.MD`.
* Removed AutoBuild system in-favor of `build.bat`.
* Bumped version.
* `GameMap.generate()` now returns `GameMap`.
* GameState logic update.
* GameState now *trys* to load `depth_0` as a map, or at least the last level of the player.
* Save now CORRECTLY makes the `curLevel` playerState varible, which still isnt functional.
* `MapGenerator` now searches for maps correctly, and actually uses `Main.foundMaps`
* Fixed crash when trying to change volume without music playing.
* Save generates `curLevel` into meta properly
* Began adding framework for override popup when making saves with the same name.
* `Save.readMapsFile` now returns `Array<MapFile>` instead of `Dynamic`
* Sound Tray Record now responds to music volume(alpha) and music pitch(spins faster).
* `GameIntroState` now makes a new save file named `Fucker` when finished

>> save *reads* as `testSave` in-game though, gotta find out why the fuck it is.

* Removed some TODO's.
* `MainMenuState` pods now react to **`POD_SPACING`** variable again.
* Removed Gallery.
* Added "Style Guide" to `ChangeLog.MD`.
* Added `AwardsGallery` placeholder.
* Map loading works
* Shader cache screen can FINALLY be toggled on and off
* MapGenerator works correctly to a degree
* Added Hall Of Heros song
* GameIntroState now PROPERLY takes you to game state. correctly.

## Prototype Update 0.04.1.03 (language improvements)

> Tried to improve some language stuff, most of it doesnt work annoyingly, gonna need a lot of ui overhauling.

* Japanese Translation is FINALLY updated, needs checking on if its accurate though.
* Added `ExtendedText` which can automatically update its font and rerender when needed
* Almost Every instance of FlxText was replaced with ExtendedText.
* Loading a save now sets it as the last loaded save, making that save auto-load on game startup.
* Added TODO to OptionsMenuSubstate to remind us to change it into a HaxeUI window.
* `MapGenerator` no longer crashes game on startup if a save file isnt loaded.
* Added ability to override language per key-attain in getTranslatedKey.
* Alphabet Debugger is functional again, finally.
* Updated uPrefs defaults to include `lastLoadedSave` field.
* Removed TODO pertaining to sprint bug on web.
* Finally bumped `project.xml` game version.

## Prototype Update 0.04.1.02 (Shader Compiler)

> basic changes i guess, trying to make stuff work i suppose.

* Finally Bumped `ChangeLog.MD` up to proper version (0.04->0.04.1.02)
* Save now correctly generates save files.
* Conductor will now shut the fuck up if it cant init after one warning message
* Preferences are now stored globally instead of per-save.
* 75% of all 4 shaders were converted to FlxRuntimeShaders over FlxShader for better paremeter setting.
* New Preferences System
* Shader Cache is FINALLY functional after being implemented all the way back in 0.03
* Added new flag for default preferences

## Prototype Update 0.04.1.01

> nothing notable really.

* Death sequence is slightly different
* Tile Connection was somewhat fixed.

## Prototype Update 0.04.1 (Map Debugger implementation)

> FINALLY the map debugger works.

* Updated `debugger.map.title` EN_US language key.
* `TestingState` should read maps properly now.
* Added `DynamicToMapFle` to `Additions`.
* `GameMap` now "generates" maps correctly.
* `Player` has new varible to disable many controls in the Map Debugger
* `generatedCameras` and `generateCameras` in `GameState` are now static.
* `MapGenerator` now properly loads map files.
* `Save` now CORRECTLY checks save file validity.
* Removed `AlphabetDebugger`.
* Save Reader Debugger no longer outputs the entire array of maps files in the window.
* `MapDebugger` was overhauled and now functional
* Updated `MainMenuState` new menu layout.

## Prototype Update 0.04.01

> no more html, we need to focus on windows.

* Added error to trying to build html5
* Removed html5 compile support
* Updated `ShaderCache` slightly, trying to make it functional.
* Removed Tiles ability to connect to others for the time being.

## Prototype Update_MAJOR 0.04 (Overhaul of a bunch of shit)

> Saves are getting rewritten for specifically windows and hashlink, because FlxSave is a slow grandma.

* Added `dump` folder to .gitignore
* Moved `k8x12.ttf` to assets/fonts
* Moved `k8x12L.ttf` to assets/fonts
* Added `terminus.ttf` to assets/fonts
* Updated `EN_US.lang`
* Started making the new save system for Windows and Hashlink
* Added lab BG for death screen
* Added placeholder Menu Char
* Added placeholder Menu Pod
* Cutscene Editor is NO LONGER made with AI, it also doesnt work anymore.
* Added Lithium Degredation
* Added Miscalculation
* Added typing sounds and terminal clicking for death screen
* moved TODO's to the TODO.hx file.
* bumped version number
* added some stuff to additions.
* bunch of other changes im too tired to put these in here, fight me.

## Prototype Update 0.03.9 (Starting work on maps)

> Starting work on the new map system!

* Added `MapAssembler` and `MapAssemblerLoader.loadAssembler`
* `MapAssemblerLoader` now supports loading a `MapAssembler` from file data.
* Added an almost full `TestMap` in `assets/maps/testmap/`
* Optimized `FlxKeyFromInt`

> PLANNED

* HScript(via Rulescript) for custom map generation if anything dynamic is needed in a structure
* Schematic system for storing structures
* * Schematic loader
* * Schematic editor
* New tileset system via `assets/maps/tilesets` including `.set` files with info about the tileset
* * Map specific tilesets

## Prototype Update 0.03.8 (Autobuild and UI)

> im lazy af, i cant be fucked into finishing this right now
>
> just go and actually look at the changelogs in github itself.

* AutoBuild system was reformatted slightly to allow for linux building and automatic HAXE installation.
* Added new graphics for UI.
* Added new keys to EN_US.
* Began adding death screen.
* Redid reassign buttons for Controls.
* Added new clicking sound for text.
* Attempted to make discord close properly, but failed.

> ADDITIONS

* Additions
* * `getPercentage`
* * `containsAny`
* * `isDataFile`
* * `combine`

* Conductor
* * No longer crashes when starting on non-debug builds
* * `onCameraBop`

* Added `ExtendedCamera`
* Gamemap Big update.
* Pickup updated
* Breaker plays sound properly

## Prototype Update 0.03.7 (Dynamic Music)

> yeah alright, fine. ill do this ~~TWO~~ *THREE* commits after i was supposed ta.

* Created MINIGUN weapon type.
* Weapon names now use real weapon names.
* Added SubLayers.
* Added placeholder breaker pull sound.
* Updated Flags.
* `Functions.wait` now supports infinite looping.
* Dynamic music.
* Added `soundPath` to Paths.
* `SoundTray` was fixed.
* `GameMap` creates a minigun now in testing mode.
* mousePosition no longer crashes game due to null access.
* MainMenuState now properly stops music before playing menu theme.
* Tiles now load through animations because solars pc is better and faster.
* Added Prototype logo.
* COMPLETELY reformated the Language system (JAPANESE IS **NOT** UPDATED YET).
* Added `build.bat` to the autobuild system to install and setup dependencies automatically.
* Set version numbers to project.xml FINALLY.
* Added `DEFAULT_JSON_RECURSION_CHECKS` to Flags. (probably unused lol)
* `Import` was updated.
* `Main.showError` calls ([MENU], [SHUTDOWN]) now function properly.
* Language information was consolodated into one map.
* Player can now have the ability to open the inventory and move removed.
* Fixed a bunch of language calls to work with the new system.
* Added message to GameState reminding to fix logic freeze.
* `HUDSubstate` can now open `GameDebugger` in debug builds for in-game debugging.
* Debuggers now properly re-open the debug chooser on `MainMenuState`.
* Added new Recursive JSON Parser.
* Fixed InspectPopup text positioning.
* `ScrollableArea` now supports horizontal scrolling.
* Added `ErrorDebugger` for debugging application popup errors.
* Added `GameDebugger` for in-game debugging. (HEAVY WIP)
* Added WIP Popup for creating `Pickup` objects for `GameDebugger`.
* ProtocalValidation was changed to ProtocolValidation (typo lol.)

## Prototype Update 0.03.6 (Breaker and placeholder enemy)

* Created debug enemy sprites.
* `burstgun`, `pistol`, `railgun`, `rifle`, and `shotgun.weapon` were given a kickback varible.
* Added new keys to `EN_US`.
* Created Braker placeholder sprites.
* Created `chrome_inspect.png`.
* Created `escapeAlarm.png`. (UNUSED FOR NOW)
* Created `button_clearSettings.png`.
* Created `musicpopup.png`.
* Added `Conductor`.
* Added `BaseEnemy`, more of a placeholder though. (SOLAR FEEL FREE TO TOUCHUP)
* Added `Breaker`.
* Added `SpecialTile` with custom interactions.
* Added (currently unused) field `onPlayerSave` to `Player`.
* Added `updateControls` to `Player`.
* Potions FINALLY exist, albeit unfinished.
* Added dynamic override system to `Language`.
* FINALLY added `GameState`.
* Added `BREAKER` SpecialTileType to `MapGenerator`.
* Fixed looping on ProtocalValidation and CellCompilation.
* Added `ScreenShake` shader.
* Added `SoundTray`.
* Added `InspectPopup`.
* Added `IntroState`.
* Added `SEURITY_SECONDSTILLACTIVATION` to `Flags`.

> Changes

* `Functions.wait` now supports loops.
* Added `Functions.MSCToMS`.
* Moved imports to `Import`
* `GameMap` creates a test enemy and breaker. (enemy is disabled for now)
* `Tile` was moved to `source\backend\game\tiles`.
* `LoadGameSubstate` now loads `GameState` instead of `TestingState`.
* Global settings can now be cleared inside of `OptionsMenuSubstate`.
* `PauseMenu` now lowers volume automatically when open. (BUGGY, SHOULD FIX)
* `MapGenerator` now places spawn point correctly.
* Completely re-wrote the `Music` system.
* Buttons for `WarningPopup` can now have null functions and not crash.
* Made `SaveDebugger`'s language keys not have uppercase.
* Rewrote cam zoom system to be based on lerp and allow for camera bopping.
* `MainMenuState` will now override music correctly.
* `TestingState` no longer initiates cameras.
* `TestingState` now extends `GameState`.

> fixes

* Saves
* * Trying to delete a save now makes a popup warning.
* Weapon
* * Kickback is stored in .weapon files.
* * Shotgun Kickback is functional FINALLY.
* * Weapon no longer fires if `SpecialTile`'s option menu is open at all.
* * Weapon no longer fires if `Main.InspectPopupVisible` is true.
* * Weapon no longer lags behind player when first equipped after dequipping.

## Prototype Update 0.03.5.1 (Tiles repair)

* Updated Tiles placeholder graphics.
* Tiles now connect correctly, minus very specific circumstances that i really dont care about right now

## Prototype Update 0.03.5 (Weapons Fixes)

* Updated `Changelog` to include changes from 0.03.⅘
* Created `Bullet_impact.png`
* `.Weapon` now allows for `fireTime` implementation.
* `Weapon` now plays firing animation automatically when implemented properly.
* Added all missing Lang strings for EN_US.
* Removed ui/item graphics.
* Bullet impact effects are now animated.
* Reworked Tile adjacentcy detection. (NEEDS PROPER TESTING)
* Weapon cooldown timers and ammo ammounts are now tied to weapon name instead of globally.
* `HUDSubstate.InventorySlot` now extends `FlxTypedSpriteGroup<FlxSprite>` and loads items properly
* `HUDSubstate.InventorySlot` now loads Pickup graphics when no ui graphic is found
* `MapGenerator`'s random generation was re-implemented for testing.
* `Flags.FALLBACK_WEAPON` now contains `fireTime` varible
* `Main.LOG` will now open a second thread to save logs over 100 characters to the file.

## Prototype Update 0.03.⅘ (Lore and shtuff)

* Created `Lore.md`.
* `Pickup` will now show an inventory full popup. (NEEDS TESTING)
* Added WIP blur feature for popups, needs to be re-written to work properly.
* Fixed buttons on MainMenuState.
* Removed TODO's from:
* * `Language`
* * `OPtionsMenuSubstate`

## Prototype Update 0.03.4 (Controls Migration)

* Created `Tasks.md` still needs to be filled out.
* Removed `.markdownlint.json` as i found a better way to fix things.
* Removed `assets/android`
* Created pickup graphics for: `burstgun`, `DEBUGCONSUMABLE`, `pistol`, `railgun`, `rifle`, and `burstgun`.
* Updated `EN_US` lang file slightly.
* Finally gave burstgun an inventory graphic.
* Added `Music` system properly, functional on all builds.
* Added `Cellcompilation-p`.
* Updated `Changelog.md`.
* Created system to only include .ogg files on native builds, and mp3 on web builds.
* Updated `README.md` to make markdownlint stop complaining about in-line html tags
* Attempted to fix Discord, but failed.
* The map system can now load no map, will show a warning of a map failing to load.
* Pickups can now load graphics.
* Replaced most traces with Main.LOG, which on debug builds will output to a log file on crash/close.
* `Language` system now attempts to change language of all on-screen object (disabled for now, very buggy.)
* Added new "autopause" setting to settings.
* Options menu can now be opened from the pause menu.
* `MapGenerator` properly saves save file when generating maps.
* `MapGenerator` is broken and doesnt export maps :/
* `Save` now stores controls globally instead of per-save.
* Added `ScrollableArea` class.
* Removed `controls` field from `Flags.DEFAULT_SAVE`
* Added new logging system to generate a log file at program crash/close.
* `MainMenuState` now plays the prototype theme
* BUG FIXES:
* * Player hotbar now properly changes depending on scrollwheel input.
* * Player weapon text will only show `weapon.` if the item is a weapon.
* * Player hotbar scrolling no longer goes at mach 10.
* * `LoadGameSubstate` and `OptionsMenuSubstate` no longer let you scroll below the minimum.

## prototype update 0.03.3 (android removal)

* Android is no longer a supported target.

## Prototype Update 0.03.2 (inventory tomfoolery)

* Updated `.markdownlint.json` so it wont complain about `README.md` anymore
* `.vscode` is now ignored
* Added plrWindow icon (DEBUG)
* `Glock and ball torture.png` was cleaned up (EASTEREGG)
* `burstgun`, `railgun`, `rifle`, and `shotgun`.weapon were fixed
* `EN_US.lang` was updated slightly
* Created `LogoConcept.aseprite`
* `README` was modified
* `Additions` was trimmed
* Added `clamp` and `clampf` to `Additions`
* Discord rich presence support was added (WINDOWS/HL)
* New pickups were added to `GameMap` for testing.
* `GameMap` now has a static instance varible
* `Pickup` had its interaction sprite FINALLY fixed.
* `Weapon` was updated to use proper velocity and now loads null data correctly
* `Player` movement system was overhauled
* `HUDSubstate.InventorySlot` now has rightclick options
* `LoadGameSubstate` needs scrolling fixed
* `OptionsMenuSubstate` was updated
* Removed a TODO message from `PauseMenu`
* Added a TODO to `Language`
* Created `Music` (dont use, not ready yet.)
* Added `musicPath` to `Paths`
* `WarningPopup` now renders on-top of everything properly
* Added a button to `MapDebugger` (nonfunctional)
* Added a default `FALLBACK_WEAPON` flag to `Flags`
* Moved imports to `Import`
* Did some stuff in `Main`
* Added a single line to `MainMenuState`
* Created probably non-functional python script to find unused imports.

## Prototype Update 0.03.1 (swap of alphabet system)

* Removed Alphabet
* Added `Floor` to `Additions`
* Added `invertColor` to `Functions`
* Tab names update properly with language changes (need to fix the order though.)
* `Language.languageNames` now stores each language in its language.

## Prototype Update 0.03 (controls menu and alphabet)

> WE HAVE A NAME!
>
>> Sublevel: Atlas-zero

* Fixed crash from language selector (HTML5)
* added `ChangeLog.md`
* added easter egg file for "Glock and ball torture" (idfk lol)
* updated EN_US language file
* added JP language file (HIGHLY UNFINISHED)
* fonts are now sprite based
* added a Mechanics.MD file for possible game features
* added new class "`Functions`" to `Additions`
* * added `wait` to `Functions`
* * added `checkJustPressedSafe` to `Functions`
* * added `checkPressedSafe` to `Functions`
* * added `checkJustReleasedSafe` to `Functions`
* * added `FlxKeyFromInt` to Functions (unoptimized AF) [solar please fix]
* added `isEmptySTR` to `Additions`
* added `Alphabet`
* swapped from `FlxTimer` to `Functions.wait`
* Weapon now supports android somewhat (someone please test this)
* Pause logic in Player now uses `Functions.checkJustPressedSafe`
* HUDSubstate now has an interactable varible to disaple useage when not open.
* LoadGameSubstate no longer crashes on android due to checking FlxG.mouse.wheel
* OptionsMenuSubstate now has controls, general, and graphics options.
* removed placeholder "KLINGON" language from Language
* added new varible for holding localized titles for the window
* `Language.getTranslatedKey` no longer needs LANG input on function call
* `Save` now stores the last loaded save file for controls in the settings menu

    > DEV NOTE
    >
    > solar please fix `ShaderCache`

* `ShaderCache` now uses `Functions.wait`
* added new `WarningPopup` class
* added new WIP `AlphabetDebugger` state (debug builds only)
* created new `Flags` class
* *slightly* updated `Import`
* `Main.controls` was fixed
* `FlxG.debugger.windows` was disabled (HTML5)
* added `.markdownlint.json` for the markdownlint plugin (VSCODE)

## Prototype Update 0.02.2 (Loading Saves)

>DEV NOTE
>
>the system is a bit fucky, but it gets the job done

* added square button image (HTML5/HL/WINDOWS)
* added delete icon image (HTML5/HL/WINDOWS)
* players touch controls no longer crash (ANDROID)
* removed `ControllerSubState`
* added `FlxVirtualPad` to `HUDSubstate`
* added `LoadGameSubstate`
* MapGenerator now outputs to target save file properly
* added `meta` field to save files to contain data for the loading menu
* updated `SaveDebugger`
* `Main` now contains `FILE` which is the target save File
* `MapGenerator.findMaps` is functional again properly
* `MainMenuState` button functions were standardized
* `TestingState` can now load maps from saves

## Prototype Update 0.02.1.2 (platform improvements)

* added ui button images (ANDROID)
* updated EN_US lang file
* Hashlink can be compiled again
* `MapGenerator.findMaps` is functional again.
* reformatted Paths slightly, again.
* build now closes when the exit button is pressed (HTML5)
* `MainMenuState` has a new ui (ANDROID)

## Prototype Fix 0.02.1.1 (windows compiler disable temp)

* Disabled Windows compilation due to unknown shader error

## Prototype Update 0.02.1 (Platform improvement)

>DEV NOTE
>
>Still working on getting multi-platform working, android is INCREDIBLY buggy
>prone to crashing as my features arent fully implemented there yet.
>
>but it at least opens.

* Added temp joystick image (ANDROID)
* created autobuild system that automatically installs lime for native platforms
* updated `Project` to:
* * embed assets (HTML5/ANDROID)
* * disabled mouse controls (ANDROID)
* * fix windows compilation (WINDOWS)
* Reimplemented debugging features (ANDROID)
* began implementing FlxG.touches (ANDROID)
* began implementing Controls substate (HTML5/HL/WINDOWS)
* Disabled Controls field from `Save` (ANDROID)
* Options menu will no longer add Controls menu (ANDROID)
* Slightly updated Paths.hx to update debugging things
* `Save` is now based on `FlxSave`
* Quit button in `MainMenuState` now closes the game

## Prototype Update_MAJOR 0.02 (Multi-Platform support)

>DEV NOTE
>
>As much as i wanted to wait to commit this until it was actually fully functional,
>i have to push this.
>since onedrive keeps RAPING my god-damn android compiler.
>
>(EG: onedrive is locking shit and breaking compilation/causing errors.)
>> Game can now be build to HTML5
>
>> Game can now be build to Android
---

* Removed maps and saves folder
* Updated language in `Project`
* Moved all imports to `Import`
* Disabled debugging features (ANDROID)
* `Pause` scaling now based on application size
* `MapGenerator` now outputs maps to the save file.
* `Paths.image` now returns `openfl.display.BitmapData` (ANDROID/HTML5)
* `Save` is now dependant on `FlxSave`
* Disabled touchscreen controls (HL/WINDOWS/HTML5)
* Disabled mouse, keyboard, and SoundTray (ANDROID)

## Prototype Hotfix 0.01.5.1 (intellisense fix)

* `Pickup` no longer breaks intellisense (VSCODE)

## Prototype Update 0.01.5 (inventory and keybinds)

* Fixed project version number
* updated `README` slightly
* Added better function for getting the first empty slot in the inventory
* `Pickup` now works properly
* `Weapon` no longer fires when interacting with the inventory
* `Player` no longer checks mouse position twice every frame
* Controlscheme moved to `Main`
* `InventorySlot` can now have items moved between instances
* Disabled bitmap log from paths due to crashes
* `Save` can now read and write save files properly
* `Main` now tracks currently held inventory item
* `TestingState` dynamically loads keybinds based off of "fucker.sav" (DEBUG)

## Prototype Update 0.01.4 (Settings Menu BASE)

* Began implementing `OptionsMenuSubstate`
* Added language keys for `OptionsMenuSubstate`

## Prototype Update 0.01.3.5 (proper inventory check)

* `Pickup` now properly checks if the inventory is full

## Prototype Update 0.01.3.4 (inventory check)

* `Pickup` now checks if the inventory is full

## Prototype Update 0.01.3.3

>No changes of note

## Prototype Update 0.01.3.2 (single change)

* `Pickup` destroys properly if the data is null

## Prototype Update 0.01.3.1 (Slight cleanup)

* Moved all imports to `Import`

## Prototype Update 0.01.3 (basic pickups)

* Added interaction sprite image (DEBUG) [placeholder]
* Added new error keys to EN_US lang file
* Updated version in `Project`
* Added placeholder pickup into `GameMap`
* Added `Pickup` base
* Added controls for Interaction in `Player`
* `InventorySlot` now accurately represents item location.
* Modified some `Paths` functions
* Added `weaponExists` function to `Paths`
* Added new error type: `NULLITEM`

## Prototype Update 0.01.2 (Kickback)

* `Weapon` now has kickback when fired
* `Player` has velocity applied when shooting `Weapon`
* `Project` now properly shows version

## Prototype Update 0.01.1 (Paths BranchOut)

>Dev Note: Paths now does its job properly

* `GameMap` now loads tilegraphics through `Paths`
* `Tile` now loads its frames through `Paths`
* `Weapon` now loads weapon files through `Paths`
* `HUDSubstate` now loads images through `Paths`
* `MapGenerator` now generates map files through `Paths`
* `Language` now loads Lang files through `Paths`
* `Paths` was expanded
* `TestingState` had trace and save modifying removed

## Prototype update: 0.01

* added save debugger language keys
* fixed debug mode being always active even in release builds
* added function for getting first null from arrays (Additions.hx)
* added new bool for `GameMap` to load into map debugger when implemented fully
* added empty class for `Pickup`
* added some slight null detection to hotbar selecting
* added null detection to `HUDSubstate` for the same reason as `Player`
* Fixed option buttons debug varibles in `PauseMenu`
* Added `readFieldFromSaveADV` to Save
* Began implementation of `MapDebugger`
* `SaveDebugger` no longer crashes if no save files are found in the saves folder
* `MainMenuState` debug switcher now loads `MapDebugger` properly
