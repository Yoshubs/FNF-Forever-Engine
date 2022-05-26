package;

import base.Controls;
import base.ScriptHandler;
import base.debug.Overlay;
import dependency.Discord;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import states.PlayState;

class Main extends Sprite
{
	public static var initialState:Class<FlxState> = PlayState;
	public static var defaultFramerate:Int = 120;

	public static function main():Void
		Lib.current.addChild(new Main());

	public function new()
	{
		super();

		// initialize the controls of the engine
		Controls.init();
		// initialize the forever scripthandler
		ScriptHandler.initialize();
		// initialize the discord rich presence
		#if Discord
		Discord.initializeRPC();
		Discord.changePresence('WORK IN PROGRESS');
		#end

		var gameCreate:FlxGame;
		gameCreate = new FlxGame(1280, 720, initialState, 1, defaultFramerate, defaultFramerate, true, false);
		addChild(gameCreate);

		var overlay:Overlay;
		overlay = new Overlay(0, 0);
		addChild(overlay);

		// FlxG.autoPause = true;
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start
	}
}
