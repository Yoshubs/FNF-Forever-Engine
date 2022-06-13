package funkin;

import base.ForeverDependencies.OffsettedSprite;
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

		notesGroup = new FlxTypedSpriteGroup<Note>();

		// load receptor data
		receptorData = Note.returnNoteData(strumlineType);
		this.keyAmount = receptorData.keyAmount;

		// set up groups
		receptors = new FlxTypedSpriteGroup<Receptor>();
		for (i in 0...keyAmount)
		{
			var receptor:Receptor = new Receptor(receptorData, i);
			receptorData.separation = 160;
			receptorData.size = 0.7;

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
		add(notesGroup);
	}
}

typedef ReceptorData =
{
	var keyAmount:Int;
	var actions:Array<String>;
	var colors:Array<String>;
	var separation:Float;
	var size:Float;
	var antialiasing:Bool;
}

class Receptor extends OffsettedSprite
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

	public function getNoteDirection()
		return receptorData.actions[noteData];

	public function getNoteColor()
		return receptorData.colors[noteData];
}
