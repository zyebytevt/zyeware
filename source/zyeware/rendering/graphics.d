module zyeware.rendering.graphics;

import zyeware.rendering.api;
import zyeware.rendering.renderer2d;
import zyeware.rendering.renderer3d;

struct Graphics
{
package(zyeware):
    GraphicsAPI api;
    
public:
    Renderer2D renderer2D;
    Renderer3D renderer3D;
}