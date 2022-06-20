package states;

import base.ChartParser;
import base.Conductor;
import base.Controls;
import base.MusicSynced.CameraEvent;
import base.ScriptHandler;
import dependency.FlxTiledSpriteExt;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import funkin.Character;
import funkin.Note;
import funkin.Stage;
import funkin.Strumline;
import funkin.UI;

using StringTools;

class PlayState extends MusicBeatState
{
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	public static var cameraSpeed:Float = 1;

	public static var camGame:FlxCamera;
	public static var camHUD:FlxCamera;
	public static var ui:UI;

	public var boyfriend:Character;
	public var dad:Character;

	var strumlines:FlxTypedGroup<Strumline>;

	public var dadStrums:Strumline;
	public var bfStrums:Strumline;

	public var controlledStrumlines:Array<Strumline> = [];

	public static var song(default, set):SongFormat;

	static function set_song(value:SongFormat):SongFormat
	{
		// preloading song notes & stuffs
		if (value != null && song != value)
		{
			song = value;

			// song values
			songSpeed = song.speed;

			uniqueNoteStash = [];
			for (i in song.notes)
			{
				if (!uniqueNoteStash.contains(i.type))
					uniqueNoteStash.push(i.type);
			}

			// load in note stashes
			Note.scriptCache = new Map<String, ForeverModule>();
			Note.dataCache = new Map<String, ReceptorData>();
			for (i in uniqueNoteStash)
			{
				Note.scriptCache.set(i, Note.returnNoteScript(i));
				Note.dataCache.set(i, Note.returnNoteData(i));
			}
			song = ChartParser.parseChart(song);
		}
		return song;
	}

	public static var uniqueNoteStash:Array<String> = [];

	public var tiledSprite:FlxTiledSpriteExt;

	override public function create()
	{
		super.create();

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD);

		song = ChartParser.loadChart(this, "bopeebo", 1, FNF_LEGACY);

		Conductor.boundSong.play();
		Conductor.boundVocals.play();

		// add stage
		var stage:Stage = new Stage('stage', FOREVER);
		add(stage);

		boyfriend = new Character(750, 850, PSYCH, 'bf-psych', 'BOYFRIEND', true);
		add(boyfriend);

		dad = new Character(50, 850, PSYCH, 'bf-psych', 'BOYFRIEND', false);
		add(dad);

		// handle UI stuff
		strumlines = new FlxTypedGroup<Strumline>();
		var separation:Float = FlxG.width / 4;
		// dad
		dadStrums = new Strumline((FlxG.width / 2) - separation, FlxG.height / 6, 'default', true, false, [dad], [dad]);
		strumlines.add(dadStrums);
		// bf
		bfStrums = new Strumline((FlxG.width / 2) + separation, FlxG.height / 6, 'default', false, true, [boyfriend], [boyfriend]);
		strumlines.add(bfStrums);
		add(strumlines);
		controlledStrumlines = [bfStrums];
		strumlines.cameras = [camHUD];

		// create the hud
		ui = new UI();
		add(ui);
		ui.cameras = [camHUD];

		// debug shit
		/*
			var myNote:Note = new Note(0, 0, 'default');
			myNote.screenCenter();
			myNote.cameras = [camHUD];
			add(myNote);

			tiledSprite = new FlxTiledSpriteExt(AssetManager.getAsset('NOTE_assets', IMAGE, 'notetypes/default'), 128, 128, true, true);
			tiledSprite.screenCenter();
			tiledSprite.cameras = [camHUD];
			add(tiledSprite);
			// */

		// create the game camera
		var camPos:FlxPoint = new FlxPoint(boyfriend.x + (boyfriend.width / 2), boyfriend.y + (boyfriend.height / 2));

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);

		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		gameCameraZoom = stage.cameraZoom;
		FlxG.camera.zoom = gameCameraZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
	}

	public static var songSpeed:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var lerpVal:Float = (elapsed * 2.4) * cameraSpeed; // cval
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		// control the camera zooming back out
		cameraZoomConverse(elapsed);

		// tiledSprite.scrollX += elapsed / (1 / 60);
		if (FlxG.keys.justPressed.UP)
			songSpeed += 0.1;
		else if (FlxG.keys.justPressed.DOWN)
			songSpeed -= 0.1;

		if (song != null)
		{
			parseEventColumn(song.cameraEvents, function(cameraEvent:CameraEvent)
			{
				// overengineered bullshit
				if (cameraEvent.simple)
				{
					// simple base fnf way
					var characterTo:Character = (cameraEvent.mustPress ? boyfriend : dad);
					camFollow.setPosition(characterTo.getMidpoint().x
						+ (characterTo.cameraOffset.x - 100 * (cameraEvent.mustPress ? 1 : -1)),
						characterTo.getMidpoint().y
						- 100
						+ characterTo.cameraOffset.y);
				}
			});

			// control adding notes
			parseEventColumn(ChartParser.unspawnedNoteList, function(unspawnNote:Note)
			{
				var strumline:Strumline = strumlines.members[unspawnNote.strumline];
				if (strumline != null)
					strumline.notesGroup.add(unspawnNote);
			}, -(16 * Conductor.stepCrochet));

			// control notes
			var downscrollMultiplier:Int = 1;
			for (strumline in strumlines)
			{
				for (receptor in strumline.receptors)
				{
					if (strumline.autoplay && receptor.animation.finished)
						receptor.playAnim('static');
				}

				strumline.notesGroup.forEachAlive(function(strumNote:Note)
				{
					if (Math.floor(strumNote.noteData) >= 0)
					{
						// update speed
						if (strumNote.useCustomSpeed)
							strumNote.noteSpeed = strumNote.customNoteSpeed;
						else
							strumNote.noteSpeed = songSpeed;

						// update position
						var baseY = strumline.receptors.members[Math.floor(strumNote.noteData)].y;
						var baseX = strumline.receptors.members[Math.floor(strumNote.noteData)].x;
						strumNote.x = baseX + strumNote.offsetX;
						var roundedSpeed = FlxMath.roundDecimal(songSpeed, 2);
						strumNote.y = baseY
							+ strumNote.offsetY
							+ (downscrollMultiplier *
								-((Conductor.songPosition - (strumNote.stepTime * Conductor.stepCrochet)) * (0.45 * strumNote.noteSpeed)));
					}

					if (strumline.autoplay)
					{
						if (strumNote.stepTime * Conductor.stepCrochet <= Conductor.songPosition)
							noteHit(strumNote, strumline.receptors.members[Math.floor(strumNote.noteData)], strumline);
					}
				});
			}

			// find the right receptor(s) within the controlled strumlines
			for (strumline in controlledStrumlines)
			{
				// get notes held
				var holdingKeys:Array<Bool> = [];
				for (receptor in strumline.receptors)
				{
					for (key in Controls.keyPressed)
					{
						if (receptor.action == Controls.getActionFromKey(key))
							holdingKeys.push(true);
					}
				}

				// reset animation
				for (character in strumline.singingList)
				{
					if (character != null
						&& (character.holdTimer > (Conductor.stepCrochet * 4) / 1000)
						&& (!holdingKeys.contains(true) || strumline.autoplay))
					{
						if (character.animation.curAnim.name.startsWith('sing') && !character.animation.curAnim.name.endsWith('miss'))
							character.dance();
					}
				}
			}
			//
		}
	}

	// get the beats
	@:isVar
	public static var curBeat(get, never):Int = 0;

	static function get_curBeat():Int
		return Conductor.beatPosition;

	// get the steps
	@:isVar
	public static var curStep(get, never):Int = 0;

	static function get_curStep():Int
		return Conductor.stepPosition;

	override public function beatHit()
	{
		super.beatHit();
		// bopper stuffs
		if (Conductor.stepPosition % 2 == 0)
		{
			for (i in strumlines)
			{
				for (j in i.characterList)
				{
					if (j.animation.curAnim.name.startsWith("idle") // check the idle before dancing
						|| j.animation.curAnim.name.startsWith("dance"))
						j.dance();
				}
			}
		}
		//
		cameraZoom();
	}

	public var camZooming:Bool = true;
	public var gameCameraZoom:Float = 1;
	public var hudCameraZoom:Float = 1;
	public var gameBump:Float = 0;
	public var hudBump:Float = 0;

	public function cameraZoom()
	{
		//
		if (camZooming)
		{
			if (gameBump < 0.35 && Conductor.beatPosition % 4 == 0)
			{
				// trace('bump');
				gameBump += 0.015;
				hudBump += 0.05;
			}
		}
	}

	public function cameraZoomConverse(elapsed:Float)
	{
		// handle the camera zooming
		FlxG.camera.zoom = gameCameraZoom + gameBump;
		camHUD.zoom = hudCameraZoom + hudBump;
		// /*
		if (camZooming)
		{
			var easeLerp = 0.95 * (elapsed / (1 / Main.defaultFramerate));
			gameBump = FlxMath.lerp(0, gameBump, easeLerp);
			hudBump = FlxMath.lerp(0, hudBump, easeLerp);
		}
		//  */
	}

	public function parseEventColumn(eventColumn:Array<Dynamic>, functionToCall:Dynamic->Void, ?timeDelay:Float = 0)
	{
		// check if there even are events to begin with
		if (eventColumn.length > 0)
		{
			while (eventColumn[0] != null && (eventColumn[0].stepTime + timeDelay / Conductor.stepCrochet) <= Conductor.stepPosition)
			{
				if (functionToCall != null)
					functionToCall(eventColumn[0]);
				eventColumn.splice(eventColumn.indexOf(eventColumn[0]), 1);
			}
		}
	}

	// CONTROLS
	public static var receptorActionList:Array<String> = ['left', 'up', 'down', 'right'];

	override public function onActionPressed(action:String)
	{
		super.onActionPressed(action);
		if (receptorActionList.contains(action))
		{
			// find the right receptor(s) within the controlled strumlines
			for (strumline in controlledStrumlines)
			{
				for (receptor in strumline.receptors)
				{
					// if this is the specified action
					if (action == receptor.action)
					{
						// placeholder
						// trace(action);

						var possibleNoteList:Array<Note> = [];
						var pressedNotes:Array<Note> = [];

						strumline.notesGroup.forEachAlive(function(daNote:Note)
						{
							if ((daNote.noteData == receptor.noteData) && !daNote.isSustain && daNote.canBeHit && !daNote.tooLate)
								possibleNoteList.push(daNote);
						});
						possibleNoteList.sort((a, b) -> Std.int(a.stepTime - b.stepTime));

						if (possibleNoteList.length > 0)
						{
							var eligable = true;
							var firstNote = true;
							// loop through the possible notes
							for (coolNote in possibleNoteList)
							{
								for (noteDouble in pressedNotes)
								{
									if (Math.abs(noteDouble.stepTime - coolNote.stepTime) < 0.1)
										firstNote = false;
									else
										eligable = false;
								}

								if (eligable)
								{
									noteHit(coolNote, receptor, strumline);
									// goodNoteHit(coolNote, boyfriend, boyfriendStrums, firstNote); // then hit the note
									pressedNotes.push(coolNote);
								}
								// end of this little check
							}
							//
						}

						if (receptor.animation.curAnim.name != 'confirm')
							receptor.playAnim('pressed');
						// receptor.playAnim('confirm');
					}
				}
			}
		}
		//
	}

	public function noteHit(daNote:Note, receptor:Receptor, strumline:Strumline)
	{
		receptor.playAnim('confirm');
		for (i in strumline.singingList)
			characterPlayDirection(i, receptor);
		daNote.destroy();
	}

	public function characterPlayDirection(character:Character, receptor:Receptor)
	{
		character.playAnim('sing' + receptor.getNoteDirection().toUpperCase(), true);
		character.holdTimer = 0;
	}

	override public function onActionReleased(action:String)
	{
		super.onActionReleased(action);
		if (receptorActionList.contains(action))
		{
			// find the right receptor(s) within the controlled strumlines
			for (strumline in controlledStrumlines)
			{
				for (receptor in strumline.receptors)
				{
					// if this is the specified action
					if (action == receptor.action)
					{
						// placeholder
						// trace(action);
						receptor.playAnim('static');
					}
				}
			}
		}
		//
	}
}
