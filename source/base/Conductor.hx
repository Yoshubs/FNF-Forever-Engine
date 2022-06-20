package base;

import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import openfl.media.Sound;
import states.MusicBeatState.MusicHandler;

/**
 * A singleton class that handles the usage and control of songs
 */
typedef Judgement =
{
	var timing:Float;
}

class Conductor
{
	public static var songPosition:Float = 0; // determines the position of the song in milliseconds
	public static var beatPosition:Int = 0; // ditto, but beats
	public static var stepPosition:Int = 0; // ditto, but steps

	public static var bpm:Float = 0; // beats per minute or the tempo of the song

	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var boundSong:FlxSound;
	public static var boundVocals:ForeverSoundGroup;
	public static var boundState:MusicHandler;

	public static final comparisonThreshold:Float = 20; // the amount of milliseconds of difference before resynchronization

	public static var judgementMap:Map<String, Judgement> = ['sick' => {timing: 45}];
	public static var msThreshold:Float = 120;

	public static var bpmMap:Map<Float, Float>;
	public static var soundGroup:FlxTypedGroup<FlxSound>;

	public static function bindSong(newState:MusicHandler, newSong:Sound, songBPM:Float, ?newVocals:Array<Sound>)
	{
		boundSong = new FlxSound().loadEmbedded(newSong);
		if (newVocals != null)
			boundVocals = new ForeverSoundGroup(newVocals);
		boundState = newState;

		soundGroup = new FlxTypedGroup<FlxSound>();
		soundGroup.add(boundSong);
		for (i in boundVocals.sounds)
			soundGroup.add(i);
		boundState.add(soundGroup);

		// recalculate crochets
		bpm = songBPM;
		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;

		// reset last steps
		lastStep = -1;
		lastBeat = -1;

		// call the finish song execution once the song is done
		boundSong.onComplete = function()
		{
			boundState.finishSong();
		};
	}

	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	public static function updateTimePosition(elapsed:Float)
	{
		if (boundSong.playing)
		{
			// update time position
			songPosition += elapsed * 1000;
			// trace('$songPosition');

			// update the bpm
			var lastTime:Float = 0;
			if (bpmMap != null)
			{
				var biggestPosition:Float = 0;
				for (i in bpmMap.keys())
				{
					if ((songPosition >= i) && (i > biggestPosition))
					{
						lastTime = i;
						bpm = bpmMap[i];
					}
				}
			}

			stepPosition = Math.floor(lastTime / stepCrochet) + Math.floor((songPosition - lastTime) / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);
			if (stepPosition > lastStep)
			{
				// trace('bound song time ${boundSong.time}');
				// /* possible resync measure
				if ((Math.abs(boundSong.time - songPosition) > 20)
					|| (boundVocals != null && Math.abs(boundVocals.time - songPosition) > 20))
					resyncTime();
				// */

				boundState.stepHit();
				lastStep = stepPosition;
			}
			if (beatPosition > lastBeat)
			{
				boundState.beatHit();
				lastBeat = beatPosition;
			}
		}
	}

	public static var focused:Bool = true;

	public static function onFocusLost()
	{
		if (focused)
		{
			@:privateAccess
			for (i in soundGroup)
				i.onFocusLost();
		}
		focused = false;
	}

	public static function onFocus()
	{
		if (!focused)
		{
			@:privateAccess
			for (i in soundGroup)
				i.onFocus();
		}
		focused = true;
	}

	public static function resyncTime()
	{
		// resynchronization
		// trace('resyncing song time ${boundSong.time}');
		songPosition = boundSong.time;
		boundSong.play();
		if (boundVocals != null)
		{
			boundVocals.pause();
			boundVocals.time = songPosition;
			boundVocals.play();
		}
		// trace('new song time ${songPosition}');
	}
}
