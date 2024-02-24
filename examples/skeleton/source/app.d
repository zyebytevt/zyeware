module skeleton.app;

import std.traits : fullyQualifiedName;

import zyeware;

import zyeware.core.application;
import zyeware.core.main;

extern (C) ProjectProperties getProjectProperties() {
	ProjectProperties properties = {
		authorName: "ZyeByte",
		projectName: "Skeleton",
		scaleMode: ScaleMode.keepAspect,

		mainDisplayProperties: {
			title: "Skeleton Application",
			size: vec2i(800, 600)
		},

		mainApplication: fullyQualifiedName!SkeletonApplication
	};

	return properties;
}

class SkeletonApplication : Application {
protected:
	Texture2d mSprite;
	//Material mWaveyMaterial;
	BitmapFont mFont;
	Camera2d mCamera;

public:
	override void initialize() {
		mSprite = AssetManager.load!Texture2d("core:textures/missing.png");
		mCamera = new Camera2d(vec2(800, 600));
		//mWaveyMaterial = AssetManager.load!Material("res:waveyChild.mtl");
		mFont = AssetManager.load!BitmapFont("core:fonts/internal.zfnt");

		ZyeWare.events.quitRequested += () { ZyeWare.quit(); };
	}

	override void tick() {
	}

	override void draw() {
		Renderer2d.clearScreen(color.lime);

		Renderer2d.beginScene(mCamera);
		//Renderer2d.drawRectangle(rect(60, 60, 100, 100), mat4.identity, color.white, mSprite);
		//Renderer2d.drawRectangle(rect(120, 60, 200, 200), mat4.identity.rotateX(30), color.white, mSprite);
		//Renderer2d.drawRectangle(rect(30, 340, 70, 70), mat4.identity, color.white, mSprite);
		//Renderer2d.drawRectangle(rect(300, 520, 30, 40), mat4.identity, color.white, mSprite);
		//Renderer2d.drawRectangle(rect(0, 0, 70, 50), mat4.identity, color.white, mSprite, mWaveyMaterial);

		Renderer2d.drawString("Hello world!", mFont, vec2(0, 0), color.white);
		Renderer2d.endScene();
	}
}
