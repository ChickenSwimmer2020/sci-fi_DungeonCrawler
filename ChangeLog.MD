# ChangeLog

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
