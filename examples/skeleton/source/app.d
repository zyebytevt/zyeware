module skeleton.app;

import zyeware.common;
import zyeware.rendering;
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
			size: Vector2i(800, 600)
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

public:
	override void initialize()
	{
		ZyeWare.scaleMode = ZyeWare.ScaleMode.keepAspect;

		VFS.addPackage("skeleton.zpk");

		mSprite = AssetManager.load!Texture2D("core://textures/missing.png");
		mCamera = new OrthographicCamera(0, 800, 600, 0);
		mWaveyMaterial = AssetManager.load!Material("res://waveyChild.mtl");
	}

	override void tick(in FrameTime frameTime)
	{
	}

	override void draw(in FrameTime nextFrameTime)
	{
		Renderer2D.clearScreen(Color.lime);

		Renderer2D.beginScene(mCamera.projectionMatrix, Matrix4f.identity);
		Renderer2D.drawRectangle(Rect2f(60, 60, 100, 100), Matrix4f.identity, Color.white, mSprite);
		Renderer2D.drawRectangle(Rect2f(120, 60, 200, 200), Matrix4f.identity.rotateX(30), Color.white, mSprite);
		Renderer2D.drawRectangle(Rect2f(30, 340, 70, 70), Matrix4f.identity, Color.white, mSprite);
		Renderer2D.drawRectangle(Rect2f(300, 520, 30, 40), Matrix4f.identity, Color.white, mSprite);
		Renderer2D.drawRectangle(Rect2f(0, 0, 70, 50), Matrix4f.identity, Color.white, mSprite, mWaveyMaterial);
		Renderer2D.endScene();
	}
}
