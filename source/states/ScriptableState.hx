package states;

import base.Controls;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUISubState;

class ScriptableState extends FlxUIState
{
	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Controls.update();
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}

class ScriptableSubState extends FlxUISubState
{
	override function create()
	{
		super.create();
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Controls.update();
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}
