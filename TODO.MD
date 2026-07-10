# TODO

* awards menu
* make settings not stutter on window open
* swap all game uis minus in-game to HaxeUI
* make cutscene maker function properly.

* Make sure [build.sh](./build.sh) works >`check if this actually works ig.`
* Expand lore [Lore.MD](./Lore.MD) >`expand on.`
* Figure out why crashes occur [CutsceneEditor.xml](assets\views\CutsceneEditor.xml#L94) >`figure out why and when this crashes.`
* make this work [CutsceneEditor.xml](assets\views\CutsceneEditor.xml#L96) > `make this properly only show when the list is empty`
* make spinner smaller [CutsceneEditor.xml](assets\views\CutsceneEditor.xml#L97) > `replace with spinner when possible`
* find automatic way [Additions.hx](source\backend\Additions.hx#L195) > `find automatic way to do this.`
* find way to fix crash if closed while thread is running [Discord.hx](source\backend\Discord.hx#L16) > `fix crash when trying to close while discord is attempting to connect`
* elevator [GameMap.hx](source\backend\game\GameMap.hx#L122)
* bullets clipping through walls [GameMap.hx](source\backend\game\GameMap.hx#L178)
* graphics system [Weapon.hx](source/backend/game/objects/Weapon.hx#L22)
* somehow load from inventory save file. (NOT SEPRATE) [Weapon.hx](source/backend/game/objects/Weapon.hx#L226)
* somehow load from inventory save file. [Weapon.hx](source/backend/game/objects/Weapon.hx#L230)
* bubble particles here [DeathState.hx](source/backend/game/states/DeathState.hx#L15)
* improve the way this renders [DeathState.hx](source/backend/game/states/DeathState.hx#L36)
* make text move properly because it fucking doesnt. [DeathState.hx](source/backend/game/states/DeathState.hx#L45)
* non loading logic. (FOR NEW GAME SYSTEM) [GameState.hx](source/backend/game/states/GameState.hx#L35)
* find way to update this properly. [CutsceneMaker.hx](source/debugging/CutsceneMaker.hx#L35)
* layers [MainView.hx](source/debugging/ui/cc/MainView.hx#L28)
* when clicked, flash the object corrispondant on the cutscene preview. [MainView.hx](source/debugging/ui/cc/MainView.hx#L143) {half done}
* button that opens the properties sidebar [MainView.hx](source/debugging/ui/cc/MainView.hx#L144)
* find way to only apply to the header. [MainView.hx](source/debugging/ui/cc/MainView.hx#L145)


# BUGS
* Sometimes when pressing 0 in debug menu, game crashes.
Uncaught exception: Access violation
Called from lime.media.$AudioBuffer.fromBytes(lime/media/AudioBuffer.hx:176)
Called from lime.utils.AssetLibrary.getAudioBuffer(lime/utils/AssetLibrary.hx:198)
Called from lime.utils.AssetLibrary.getAsset(lime/utils/AssetLibrary.hx:177)
Called from lime.utils.$Assets.getAsset(lime/utils/Assets.hx:122)
Called from lime.utils.$Assets.getAudioBuffer(lime/utils/Assets.hx:158)
Called from openfl.utils.$Assets.getSound(openfl/utils/Assets.hx:344)
Called from flixel.system.frontEnds.AssetFrontEnd.getOpenflAssetUnsafe(flixel/system/frontEnds/AssetFrontEnd.hx:161)
Called from flixel.system.frontEnds.AssetFrontEnd.getAssetUnsafe(flixel/system/frontEnds/AssetFrontEnd.hx:107)
Called from flixel.system.frontEnds.AssetFrontEnd.getAsset(flixel/system/frontEnds/AssetFrontEnd.hx:186)
Called from flixel.system.ui.FlxSoundTray.showAnim(flixel/system/ui/FlxSoundTray.hx:157)
Called from flixel.system.frontEnds.AssetFrontEnd.getAsset(flixel/system/frontEnds/AssetFrontEnd.hx:186)
Called from flixel.system.ui.FlxSoundTray.showAnim(flixel/system/ui/FlxSoundTray.hx:157)
Called from backend.SoundTray.showAnim(backend/SoundTray.hx:81)
Called from flixel.system.ui.FlxSoundTray.showIncrement(flixel/system/ui/FlxSoundTray.hx:188)
Called from flixel.system.frontEnds.SoundFrontEnd.showSoundTray(flixel/system/frontEnds/SoundFrontEnd.hx:376)
Called from flixel.system.frontEnds.SoundFrontEnd.toggleMuted(flixel/system/frontEnds/SoundFrontEnd.hx:353)
Called from flixel.system.frontEnds.SoundFrontEnd.update(flixel/system/frontEnds/SoundFrontEnd.hx:434)
Called from flixel.FlxGame.update(flixel/FlxGame.hx:689)
Called from flixel.FlxGame.step(flixel/FlxGame.hx:628)
Called from flixel.FlxGame.onEnterFrame(flixel/FlxGame.hx:501)
Called from openfl.display._internal.$FlashRenderer.~register.0(lime/app/Module.hx:0)
Called from openfl.events.EventDispatcher.__dispatchEvent(openfl/events/EventDispatcher.hx:477)
Called from openfl.display.DisplayObject.__dispatch(openfl/display/DisplayObject.hx:1498)
Called from openfl.display.Stage.__broadcastEvent(openfl/display/Stage.hx:1363)
Called from openfl.display.Stage.__onLimeRender(openfl/display/Stage.hx:2433)
Called from lime.app._Event_lime_graphics_RenderContext_Void.dispatch(lime/_internal/macros/EventMacro.hx:91)
Called from lime._internal.backend.native.NativeApplication.handleRenderEvent(lime/_internal/backend/native/NativeApplication.hx:418)
Called from lime._internal.backend.native.NativeApplication.exec(lime/_internal/backend/native/NativeApplication.hx:163)
Called from lime.app.Application.exec(lime/app/Application.hx:169)
Called from openfl.display.Application.exec(openfl/display/Application.hx:138)
Called from $ApplicationMain.create(ApplicationMain.hx:137)
Called from $ApplicationMain.main(ApplicationMain.hx:26)
Called from .init(?:1)