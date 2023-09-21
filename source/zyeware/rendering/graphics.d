module zyeware.rendering.graphics;

import zyeware.rendering.api;
import zyeware.rendering.renderer2d;
import zyeware.rendering.renderer3d;

struct Graphics
{
package(zyeware) static:
    GraphicsAPI sApi;
    Renderer2D sRenderer2D;
    Renderer3D sRenderer3D;
    
public static:
    Renderer2D renderer2D()
    {
        return sRenderer2D;
    }

    Renderer3D renderer3D()
    {
        return sRenderer3D;
    }
}