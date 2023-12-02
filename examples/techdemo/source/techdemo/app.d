module techdemo.app;

import zyeware.common;
import zyeware.core.application;
import zyeware.rendering;

import techdemo.menu.menu;

extern(C) ProjectProperties getProjectProperties()
{
	ProjectProperties props = {
		authorName: "ZyeByte",
		projectName: "ZyeWare Sandbox",

		mainDisplayProperties: {
			title: "ZyeWare Tech Demo",
			size: Vector2i(640, 480),
			icon: Image.load(cast(ubyte[]) import("icon.png"))
		},

		mainApplication: new TechDemoApplication()
	};

    return props;
}

class EmptyApplication : Application
{
public:
	override void initialize()
	{
	}

	override void tick()
	{
	}

	override void draw()
	{
	}
}

class TechDemoApplication : GameStateApplication
{
public:
	override void initialize()
	{
		ZyeWare.scaleMode = ZyeWare.ScaleMode.keepAspect;

		VFS.addPackage("techdemo.zpk");

		VFSDirectory locales = VFS.getDirectory("res:locales");
		foreach (string localeFile; locales.files)
			TranslationManager.addLocale(AssetManager.load!Translation(locales.fullname ~ "/" ~ localeFile));

		TranslationManager.locale = "en";

		InputManager.addAction("ui_up", 0.2f)
			.addInput(new InputEventKey(KeyCode.up))
			.addInput(new InputEventGamepadButton(0, GamepadButton.dpadUp));
		
		InputManager.addAction("ui_left", 0.2f)
			.addInput(new InputEventKey(KeyCode.left))
			.addInput(new InputEventGamepadButton(0, GamepadButton.dpadLeft));
		
		InputManager.addAction("ui_right", 0.2f)
			.addInput(new InputEventKey(KeyCode.right))
			.addInput(new InputEventGamepadButton(0, GamepadButton.dpadRight));
		
		InputManager.addAction("ui_down", 0.2f)
			.addInput(new InputEventKey(KeyCode.down))
			.addInput(new InputEventGamepadButton(0, GamepadButton.dpadDown));
		
		InputManager.addAction("ui_cancel")
			.addInput(new InputEventKey(KeyCode.escape))
			.addInput(new InputEventGamepadButton(0, GamepadButton.b));
		
		InputManager.addAction("ui_accept")
			.addInput(new InputEventKey(KeyCode.enter))
			.addInput(new InputEventGamepadButton(0, GamepadButton.a));

		ZyeWare.mainDisplay.cursor = AssetManager.load!Cursor("core:cursors/arrow.cursor");

        changeState(new DemoMenu(this));
	}
}