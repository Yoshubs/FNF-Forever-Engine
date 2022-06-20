package base;

import AssetManager.EngineImplementation;
import base.MusicSynced;
import funkin.Note;
import haxe.Json;
import states.MusicBeatState;
import states.PlayState;

typedef SongFormat =
{
	var name:String;
	var bpm:Float;
	var events:Array<TimedEvent>;
	var cameraEvents:Array<CameraEvent>;
	var notes:Array<UnspawnedNote>;
	var speed:Float;
}

typedef LegacySection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var typeOfSection:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef LegacySong =
{
	var song:String;
	var notes:Array<LegacySection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var stage:String;
	var noteSkin:String;
	var validScore:Bool;
}

class ChartParser
{
	public static var unspawnedNoteList:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static function loadChart(state:MusicHandler, songName:String = 'test', difficulty:Int, songType:EngineImplementation = FNF_LEGACY):SongFormat
	{
		switch (songType)
		{
			case FNF:
			// placeholder until new chart type 0.3
			case FOREVER:

			default:
				var startTime:Float = Sys.time();
				// pre 0.3 chart loader
				var rawChart = AssetManager.getAsset(songName + difficultyMap[difficulty][0], JSON, 'songs/$songName');
				var legacySong:LegacySong = cast Json.parse(rawChart).song;

				// convert to standard format
				var returnSong:SongFormat;
				returnSong = {
					name: legacySong.song,
					bpm: legacySong.bpm,
					events: [],
					cameraEvents: [],
					notes: [],
					speed: legacySong.speed,
				};

				// load songs
				var rawDirectory:String = AssetManager.getPath(songName, 'songs', DIRECTORY);
				Conductor.bindSong(state, AssetManager.returnSound('$rawDirectory/Inst.ogg'), returnSong.bpm,
					[AssetManager.returnSound('$rawDirectory/Voices.ogg')]);

				// parse camera, note and events from legacy chart
				for (i in 0...legacySong.notes.length)
				{
					// add it to the return song stuff
					var cameraEvent:CameraEvent = {
						stepTime: i * 16,
						simple: true,
						mustPress: legacySong.notes[i].mustHitSection
					}
					returnSong.cameraEvents.push(cameraEvent);

					// push individual notes lmfao
					for (j in legacySong.notes[i].sectionNotes)
					{
						if (j[1] >= 0)
						{
							var newNote:UnspawnedNote = {
								stepTime: (j[0] / Conductor.stepCrochet),
								// this formula sucks lmfao the base game format is ew
								strumline: ((legacySong.notes[i].mustHitSection && j[1] <= 3 || !legacySong.notes[i].mustHitSection && j[1] > 3) ? 1 : 0),
								index: Std.int(j[1] % 4),
								type: 'default',
								holdStep: (j[2] / Conductor.stepCrochet),
								animationString: '',
							}
							returnSong.notes.push(newNote);
						}
						else
						{
							//
						}
					}
				}

				haxe.ds.ArraySort.sort(returnSong.notes, function(a, b):Int
				{
					return Std.int(a.stepTime - b.stepTime);
				});

				// psych events LOL
				if (songType == PSYCH) {}

				var endTime:Float = Sys.time();
				trace('end chart parse time ${endTime - startTime}');
				return returnSong;
		}
		return null;
	}

	/**
	 * [Returns the events and notes of a loaded chart]
	 * @param song The song to parse (in song format from loadChart)
	 */
	public static function parseChart(song:SongFormat):SongFormat
	{
		unspawnedNoteList = [];
		for (unspawnNote in song.notes)
		{
			var newNote:Note = new Note(unspawnNote.stepTime, unspawnNote.index, unspawnNote.type, unspawnNote.strumline);
			unspawnedNoteList.push(newNote);
			if (unspawnNote.holdStep > 0)
			{
				for (i in 1...Std.int(unspawnNote.holdStep))
				{
					var newSustain:Note = new Note(unspawnNote.stepTime + i, unspawnNote.index, unspawnNote.type, unspawnNote.strumline, true,
						unspawnedNoteList[Std.int(unspawnedNoteList.length - 1)]);
					unspawnedNoteList.push(newSustain);
				}
			}
			song.notes.splice(song.notes.indexOf(unspawnNote), 0);
		}

		// hold note bullshit

		// sort notes
		// /*
		haxe.ds.ArraySort.sort(unspawnedNoteList, function(a, b):Int
		{
			return Std.int(a.stepTime - b.stepTime);
		});
		//  */
		return song;
	}
}
