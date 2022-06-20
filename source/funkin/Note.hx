package funkin;

import base.Conductor;
import base.ForeverDependencies.OffsettedSprite;
import base.ScriptHandler.ForeverModule;
import base.ScriptHandler;
import funkin.Strumline.ReceptorData;
import haxe.Json;
import states.PlayState;

class Note extends OffsettedSprite
{
	public var noteData:Int;
	public var stepTime:Float;
	public var strumline:Int = 0;
	public var isSustain:Bool = false;
	//
	public var prevNote:Note;

	// values
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var useCustomSpeed:Bool = false;
	public var customNoteSpeed:Float;
	public var noteSpeed(default, set):Float;

	public function set_noteSpeed(value:Float):Float
	{
		if (noteSpeed != value)
		{
			noteSpeed = value;
			updateSustainScale();
		}
		return noteSpeed;
	}

	public var tooLate:Bool = false;
	public var canBeHit:Bool = false;

	public static var scriptCache:Map<String, ForeverModule> = [];
	public static var dataCache:Map<String, ReceptorData> = [];

	public var receptorData:ReceptorData;
	public var noteModule:ForeverModule;

	public function new(stepTime:Float, index:Int, noteType:String, strumline:Int, ?isSustain:Bool = false, ?prevNote:Note)
	{
		noteData = index;
		this.stepTime = stepTime;
		this.strumline = strumline;
		this.isSustain = isSustain;
		this.prevNote = prevNote;

		super();

		loadNote(noteType);
	}

	public function loadNote(noteType:String)
	{
		receptorData = returnNoteData(noteType);
		noteModule = returnNoteScript(noteType);

		noteModule.interp.variables.set('note', this);
		// truncated loading functions by a ton
		noteModule.interp.variables.set('getNoteDirection', getNoteDirection);
		noteModule.interp.variables.set('getNoteColor', getNoteColor);

		var generationScript:String = isSustain ? 'generateSustain' : 'generateNote';
		if (noteModule.exists(generationScript))
			noteModule.get(generationScript)();

		// set note data stuffs
		antialiasing = receptorData.antialiasing;
		setGraphicSize(Std.int(frameWidth * receptorData.size));
		updateHitbox();
	}

	public function updateSustainScale()
	{
		if (isSustain)
		{
			alpha = 0.6;
			if (prevNote != null && prevNote.exists)
			{
				if (prevNote.isSustain)
				{
					// listen I dont know what i was doing but I was onto something
					prevNote.scale.y = (prevNote.width / prevNote.frameWidth) * ((Conductor.stepCrochet / 100) * (1.07 / prevNote.receptorData.size)) * noteSpeed;
					prevNote.updateHitbox();
					offsetX = prevNote.offsetX;
				}
				else
					offsetX = ((prevNote.width / 2) - (width / 2));
			}
		}
	}

	public static function returnNoteData(noteType:String):ReceptorData
	{
		// load up the note data
		if (!dataCache.exists(noteType))
		{
			// trace('setting note data $noteType');
			dataCache.set(noteType, cast Json.parse(AssetManager.getAsset(noteType, JSON, 'notetypes/$noteType')));
		}
		return dataCache.get(noteType);
	}

	public static function returnNoteScript(noteType:String):ForeverModule
	{
		// load up the note script
		if (!scriptCache.exists(noteType))
		{
			// trace('setting note script $noteType');
			scriptCache.set(noteType, ScriptHandler.loadModule(noteType, 'notetypes/$noteType'));
		}
		return scriptCache.get(noteType);
	}

	function getNoteDirection()
		return receptorData.actions[noteData];

	function getNoteColor()
		return receptorData.colors[noteData];

	override public function update(elapsed:Float)
	{
		if (stepTime > Conductor.stepPosition - (Conductor.msThreshold / Conductor.stepCrochet) //
			&& stepTime < Conductor.stepPosition + (Conductor.msThreshold / Conductor.stepCrochet))
			canBeHit = true;
		else
			canBeHit = false;

		super.update(elapsed);
	}
}
