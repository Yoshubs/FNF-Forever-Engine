package funkin;

import flixel.math.FlxMath;
import states.PlayState;
import base.Conductor;
import base.ScriptHandler.ForeverModule;
import base.ScriptHandler;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import haxe.Json;
import haxe.ds.StringMap;
import sys.io.File;

class Strumline extends FlxSpriteGroup
{
	public var receptors:FlxTypedSpriteGroup<Receptor>;
	public var keyAmount:Int = 4;

	public var characterList:Array<Character> = [];
	public var singingList:Array<Character> = [];

	public var autoplay:Bool = true;
	public var displayJudgement:Bool = false;

	public var allNotes:FlxTypedSpriteGroup<Note>;
	public var holdsGroup:FlxTypedSpriteGroup<Note>;
	public var notesGroup:FlxTypedSpriteGroup<Note>;
	public var receptorData:ReceptorData;

	public function new(?x_position:Float = 0, ?y_position:Float = 0, ?strumlineType:String = 'default', ?autoplay:Bool = true,
			?displayJudgement:Bool = false, ?characterList:Array<Character>, ?singingList:Array<Character>)
	{
		super();
		this.characterList = characterList;
		this.singingList = singingList;

		this.autoplay = autoplay;
		this.displayJudgement = displayJudgement;

		allNotes = new FlxTypedSpriteGroup<Note>();
		holdsGroup = new FlxTypedSpriteGroup<Note>();
		notesGroup = new FlxTypedSpriteGroup<Note>();

		// load receptor data
		receptorData = Note.returnNoteData(strumlineType);
		this.keyAmount = receptorData.keyAmount;

		// set up groups
		receptors = new FlxTypedSpriteGroup<Receptor>();
		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(receptorData, i);

			// calculate width
			receptor.setGraphicSize(Std.int(receptor.width * receptorData.size));
			receptor.updateHitbox();
			receptor.swagWidth = receptorData.separation * receptorData.size;
			receptor.setPosition(x_position - receptor.swagWidth / 2, y_position - receptor.swagWidth / 2);
			// define receptor values
			receptor.noteData = i;
			receptor.action = receptorData.actions[i];
			receptor.antialiasing = receptorData.antialiasing;
			//
			receptor.x += (i - ((keyAmount - 1) / 2)) * receptor.swagWidth;
			receptors.add(receptor);
		}
		add(receptors);
		add(holdsGroup);
		add(notesGroup);
	}

	public function createNote(beatTime:Float, index:Int, noteType:String, ?holdLength:Float, isHold:Bool = false, ?prevNote:Note)
	{
		var oldNote:Note;
		if (allNotes.length > 0)
			oldNote = allNotes.members[Std.int(allNotes.length - 1)];
		else
			oldNote = null;

		var newNote:Note = new Note(beatTime, index, noteType, oldNote);

		// make holds from the note
		if (holdLength != null && holdLength > 0)
		{
			var length:Int = Math.floor(holdLength / Conductor.stepCrochet);
			if (length > 0)
			{
				// i hate this so much
				var roundedSpeed:Float = FlxMath.roundDecimal(PlayState.song.speed, 2);
				var coolCrochet:Float = Conductor.stepCrochet / 125;
				for (susNote in 0...(length + 1))
				{
					oldNote = allNotes.members[allNotes.length - 1];

					var newHold:Note = new Note(beatTime + coolCrochet * susNote + coolCrochet / roundedSpeed, index, noteType, oldNote, true);
					// best thing i can do for make scroll consistant
					if (susNote > 0)
						newHold.offsetY -= (13 + roundedSpeed / 1.9 * 5) * roundedSpeed * susNote;
					allNotes.add(newHold);
					holdsGroup.add(newHold);
				}
			}
		}

		allNotes.add(newNote);
		notesGroup.add(newNote);
	}
}

typedef ReceptorData =
{
	var keyAmount:Int;
	var actions:Array<String>;
	var colors:Array<String>;
	var ?separation:Float;
	var ?size:Float;
	var ?antialiasing:Bool;
}

class Receptor extends FlxSprite
{
	public var swagWidth:Float;

	public var noteData:Int;
	public var noteType:String;
	public var action:String;

	public var receptorData:ReceptorData;
	public var noteModule:ForeverModule;

	public function new(receptorData:ReceptorData, ?noteData:Int = 0, ?noteType:String = 'default')
	{
		super();
		this.receptorData = receptorData;
		this.noteData = noteData;
		this.noteType = noteType;

		// load the receptor script
		noteModule = Note.returnNoteScript(noteType);
		noteModule.interp.variables.set('receptor', this);
		noteModule.interp.variables.set('getNoteDirection', getNoteDirection);
		noteModule.interp.variables.set('getNoteColor', getNoteColor);
		noteModule.get('generateReceptor')();
	}

	function getNoteDirection()
		return receptorData.actions[noteData];

	function getNoteColor()
		return receptorData.colors[noteData];
}
