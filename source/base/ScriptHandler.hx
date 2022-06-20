package base;

import AssetManager.AssetType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import haxe.ds.StringMap;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * Handles the Backend and Script interfaces of Forever Engine, as well as exceptions and crashes.
 */
class ScriptHandler
{
	/**
	 * Shorthand for exposure, specifically public exposure. 
	 * All scripts will be able to access these variables globally.
	 */
	public static var exp:StringMap<Dynamic>;

	public static var parser:Parser = new Parser();

	/**
	 * [Initializes the basis of the Scripting system]
	 */
	public static function initialize()
	{
		exp = new StringMap<Dynamic>();

		// Classes (Haxe)
		exp.set("Sys", Sys);
		exp.set("Std", Std);
		exp.set("Math", Math);
		exp.set("StringTools", StringTools);

		// Classes (Flixel)
		exp.set("FlxG", FlxG);
		exp.set("FlxSprite", FlxSprite);
		exp.set("FlxMath", FlxMath);

		// Classes (Forever)
		parser.allowTypes = true;
	}

	public static function loadModule(path:String, ?assetGroup:String, ?extraParams:StringMap<Dynamic>)
	{
		trace('Loading Module $path');
		var modulePath:String = AssetManager.getAsset(path, MODULE, assetGroup);
		return new ForeverModule(parser.parseString(File.getContent(modulePath), modulePath), assetGroup, extraParams);
	}
}

/**
 * The basic module class, for handling externalized scripts individually
 */
class ForeverModule
{
	public var interp:Interp;
	public var assetGroup:String;

	public function new(?contents:Expr, ?assetGroup:String, ?extraParams:StringMap<Dynamic>)
	{
		interp = new Interp();
		// Variable functionality
		for (i in ScriptHandler.exp.keys())
			interp.variables.set(i, ScriptHandler.exp.get(i));
		// Local Variable functionality
		if (extraParams != null)
		{
			for (i in extraParams.keys())
				interp.variables.set(i, extraParams.get(i));
		}
		// Asset functionality
		this.assetGroup = assetGroup;
		interp.variables.set('getAsset', getAsset);
		interp.execute(contents);
	}

	/**
		* [Returns a field from the module]
			 * @param field 
			 * @return Dynamic
		return interp.variables.get(field)
	 */
	public function get(field:String):Dynamic
		return interp.variables.get(field);

	/**
	 * [Sets a field within the module to a new value]
	 * @param field 
	 * @param value 
	 * @return interp.variables.set(field, value)
	 */
	public function set(field:String, value:Dynamic)
		interp.variables.set(field, value);

	/**
		* [Checks the existence of a value or exposure within the module]
		* @param field 
		* @return Bool
				return interp.variables.exists(field)
	 */
	public function exists(field:String):Bool
		return interp.variables.exists(field);

	/**
	 * [Returns an asset from the local module path]
	 * @param directory The local directory of the requested asset 
	 * @param type The type of the requested asset
	 * @return returns the requested asset
	 */
	public function getAsset(directory:String, type:AssetType)
	{
		var path:String = AssetManager.getPath(directory, assetGroup, type);
		// trace('attempting path $path');
		if (FileSystem.exists(path))
			return AssetManager.getAsset(directory, type, assetGroup);
		else
		{
			// trace('path failed');
			return AssetManager.getAsset(directory, type);
		}
	}
}
