package funkin;

import AssetManager.EngineImplementation;
import base.Conductor;
import base.ForeverDependencies.OffsettedSprite;
import base.ScriptHandler;
import flixel.math.FlxPoint;
import funkin.compat.PsychCharacter;
import haxe.Json;
import haxe.ds.StringMap;

using StringTools;

class Character extends OffsettedSprite
{
	public var cameraOffset:FlxPoint;
	public var characterOffset:FlxPoint;
	public var holdTimer:Float = 0;
	public var isPlayer:Bool = false;

	public function new(x:Float, y:Float, ?engineImplementation:EngineImplementation, ?character:String = 'bf', ?characterAtlas:String = 'BOYFRIEND',
			isPlayer:Bool = false)
	{
		super(x, y);
		setCharacter(x, y, engineImplementation, character, characterAtlas, isPlayer);
	}

	public var psychAnimationsArray:Array<PsychAnimArray> = [];

	public function setCharacter(x:Float, y:Float, ?engineImplementation:EngineImplementation, ?character:String = 'bf', ?characterAtlas:String = 'BOYFRIEND',
			isPlayer:Bool = false):Character
	{
		frames = AssetManager.getAsset('$characterAtlas', SPARROW, 'characters/$character');
		antialiasing = true;
		this.isPlayer = isPlayer;

		cameraOffset = new FlxPoint(0, 0);
		characterOffset = new FlxPoint(0, 0);

		switch (engineImplementation)
		{
			case FOREVER:
				frames = AssetManager.getAsset('$characterAtlas', SPARROW, 'characters/$character');
				var exposure:StringMap<Dynamic> = new StringMap<Dynamic>();
				exposure.set('character', this);
				var character:ForeverModule = ScriptHandler.loadModule(character, 'characters/$character', exposure);
				if (character.exists("loadAnimations"))
					character.get("loadAnimations")();
			case PSYCH:
				/**
				 * @author Shadow_Mario_
				 */
				var json:PsychCharacterFile = cast Json.parse(AssetManager.getAsset('$character', JSON, 'characters/$character'));

				psychAnimationsArray = json.animations;
				for (anim in psychAnimationsArray)
				{
					var animAnim:String = '' + anim.anim;
					var animName:String = '' + anim.name;
					var animFps:Int = anim.fps;
					var animLoop:Bool = !!anim.loop; // Bruh
					var animIndices:Array<Int> = anim.indices;
					if (animIndices != null && animIndices.length > 0)
						animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
					else
						animation.addByPrefix(animAnim, animName, animFps, animLoop);

					if (anim.offsets != null && anim.offsets.length > 1)
						addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
				flipX = json.flip_x;

			default:
		}

		// reverse player flip
		if (isPlayer)
			flipX = !flipX;

		dance();

		// x += characterData.offsetX;
		// trace('character ${curCharacter} scale ${scale.y}');
		// y += (characterData.offsetY - (frameHeight * scale.y));

		setPosition(x, y);
		this.y -= (frameHeight * scale.y);

		return this;
	}

	override public function update(elapsed:Float)
	{
		if (!isPlayer)
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			if (holdTimer >= (Conductor.stepCrochet * 4) / 1000)
			{
				dance();
				holdTimer = 0;
			}
		}
		else
		{
			if (animation.curAnim.name.startsWith('sing'))
				holdTimer += elapsed;
			else
				holdTimer = 0;
		}

		super.update(elapsed);
	}

	public function dance(?forced:Bool = false)
	{
		playAnim('idle', forced);
	}
}
