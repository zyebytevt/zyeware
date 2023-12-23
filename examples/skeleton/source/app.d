module skeleton.app;

import zyeware;

import zyeware.core.application;
import zyeware.core.main;
import zyeware.pal;

extern(C) ProjectProperties getProjectProperties()
{
	ProjectProperties properties = {
		authorName: "ZyeByte",
		projectName: "Skeleton",

		mainDisplayProperties: {
			title: "Skeleton Application",
			size: vec2i(800, 600)
		},

		mainApplication: new SkeletonApplication()
	};

	return properties;
}

class SkeletonApplication : Application
{
protected:
	Texture2D mSprite;
	OrthographicCamera mCamera;
	Material mWaveyMaterial;
	BitmapFont mFont;

public:
	override void initialize()
	{
		ZyeWare.scaleMode = ZyeWare.ScaleMode.keepAspect;

		Vfs.addPackage("skeleton.zpk");

		mSprite = AssetManager.load!Texture2D("core:textures/missing.png");
		mCamera = new OrthographicCamera(0, 800, 600, 0);
		mWaveyMaterial = AssetManager.load!Material("res:waveyChild.mtl");
		mFont = AssetManager.load!BitmapFont("core:fonts/internal.zfnt");
	}

	override void tick()
	{
	}

	override void draw()
	{
		Renderer2D.clearScreen(color.lime);

		Renderer2D.beginScene(mCamera.projectionMatrix, mat4.identity);
		//Renderer2D.drawRectangle(rect(60, 60, 100, 100), mat4.identity, color.white, mSprite);
		//Renderer2D.drawRectangle(rect(120, 60, 200, 200), mat4.identity.rotateX(30), color.white, mSprite);
		//Renderer2D.drawRectangle(rect(30, 340, 70, 70), mat4.identity, color.white, mSprite);
		//Renderer2D.drawRectangle(rect(300, 520, 30, 40), mat4.identity, color.white, mSprite);
		//Renderer2D.drawRectangle(rect(0, 0, 70, 50), mat4.identity, color.white, mSprite, mWaveyMaterial);
		
		Renderer2D.drawString("Hello world!", mFont, vec2(20, 20), color.white);
		Renderer2D.endScene();
	}
}
