package backend;

class SoundTray extends FlxSoundTray {
    var _timeText:TextField;
	var record:Sprite;
    public function new() {
        super();

        _timeText = new TextField();
		_timeText.width = 100;
		// text.height = bg.height;
		_timeText.multiline = true;
		// text.wordWrap = true;
		_timeText.selectable = false;

		var dft:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 4, 0xffffff);
		dft.align = TextFormatAlign.CENTER;
		_timeText.defaultTextFormat = dft;
		addChild(_timeText);
		_timeText.text = "0:00/0:00";
		_timeText.y = 14;
        _timeText.x = _bg.width-60;

		record = new Sprite();
			var bitmap = new Bitmap(BitmapData.fromFile(Paths.image('ui', 'musicpopup')));
			bitmap.scaleX = 1.75;
			bitmap.scaleY = 1.75;
			bitmap.x = -bitmap.width / 2;
			bitmap.y = -bitmap.height / 2;
			record.addChild(bitmap);
		addChild(record);
		record.x = 190;
		record.y = 15;
        fix();
    }
	var expo:Int=0;
	var angle:Int = 0;
    override public function update(MS:Float) {
		if(angle>=360)angle=0;
		else angle+=(8*(FlxG.sound.music!=null?FlxG.sound.music.pitch:1)).floor(); //if the music is null, normal speed. otherwise base this on music pitch.
		if(FlxG.sound.music!=null && FlxG.sound.music.playing) record.rotation = angle;
		record.alpha = FlxG.save.isBound?(FlxG.save.data.volume):1;


		if (_timer > 0){
			_timer -= (MS / 1000);
			expo=1;
		}else if (x > -width) {
			expo+=expo;
			x += (MS / 1000) * width * expo/4;
			if (x >= FlxG.width) {
				visible = false;
				active = false;
			}
		}
		if(FlxG.sound.music!=null) _timeText.text = '${(FlxG.sound.music.time/1000).formatTime()}/${(FlxG.sound.music.length/1000).formatTime()}';
		else _timeText.text = '';
    }
    function fix() {
        for(bar in 0..._bars.length) {
            _bars[bar].bitmapData.dispose();
        }
        _bars = [];
        var tmp:Bitmap;
		for (i in 0...10) {
			tmp = new Bitmap(new BitmapData(2, 1, false, 0xFFFFFF));
			addChild(tmp);
			_bars.push(tmp);
		}
    }
	/**
	 * Shows the volume animation for the desired settings
	 * @param   volume    The volume, 1.0 is full volume
	 * @param   sound     The sound to play, if any
	 * @param   duration  How long the tray will show
	 * @param   label     The test label to display
	 */
	override public function showAnim(volume:Float, ?sound:FlxSoundAsset, duration = 1.0, label:String=""){
        super.showAnim(volume, sound, duration, '${Music.musicInfos.get(Music.currentlyPlayingSong).name}\n${Music.musicInfos.get(Music.currentlyPlayingSong).artist}');
        var dtf:TextFormat = new TextFormat(FlxAssets.FONT_DEFAULT, 10, 0xffffff);
		dtf.align = TextFormatAlign.LEFT;
		_label.defaultTextFormat = dtf;

		#if FLX_SAVE //fuck it, do it instantly.
		// Save sound preferences
		if (FlxG.save.isBound)
		{
			FlxG.save.data.mute = FlxG.sound.muted;
			FlxG.save.data.volume = FlxG.sound.volume;
			FlxG.save.flush();
		}
		#end
	}
    override public function screenCenter():Void
	{
		scaleX = _defaultScale;
		scaleY = _defaultScale;

		x = (1 * (Lib.current.stage.stageWidth - _bg.width * _defaultScale) - FlxG.game.x);
	}
    override function updateSize(){
		if (_label.textWidth + 10 > _bg.width) _label.width = _label.textWidth + 10;
        _label.y = 0;
			
		_bg.width = (_label.textWidth + 10 > _minWidth ? _label.textWidth + 10 : _minWidth) + 75;
		_label.width = _bg.width;
		
		var bx:Int = Std.int(_bg.width - 81);
		for (i in 0..._bars.length)
		{
			_bars[i].x = bx;
			_bars[i].y = 26;
			bx += 3;
		}
		
		screenCenter();
	}
}