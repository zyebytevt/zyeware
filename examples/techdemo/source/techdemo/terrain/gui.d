module techdemo.terrain.gui;

import std.string : format;

import zyeware.ecs;
import zyeware.rendering;
import zyeware.common;
import zyeware.core.debugging.profiler;

version(none):

class GUISystem : System
{
protected:
    OrthographicCamera mUICamera;
    Font mFont;

public:
    this()
    {
        mUICamera = new OrthographicCamera(0, 640, 480, 0);
        mFont = AssetManager.load!Font("core://fonts/internal.fnt");
    }

    override void draw(EntityManager entities, in FrameTime nextFrameTime)
    {
        Renderer2D.beginScene(mUICamera.projectionMatrix, Matrix4f.identity);
        Renderer2D.drawString(tr("SPOOKY 3D TERRAIN DEMO\nPress arrow keys to move around.\nOptionally, you can use a controller!"),
            mFont, Vector2f(4));

        version (Profiling)
        {
            auto renderData = Profiler.currentReadData.renderData;
            Renderer2D.drawString(format!"2D rects: %d\nDraw calls: %d\nPolygons: %d"(renderData.rectCount,
                renderData.drawCalls, renderData.polygonCount),
                mFont, Vector2f(640, 0), Color.white, Font.Alignment.right);
        }
        
        Renderer2D.endScene();
    }
}