module zyeware.pal.pal;

import zyeware.pal.graphics.callbacks;
import zyeware.pal.display.callbacks;
import zyeware.pal.renderer.callbacks;

struct PAL
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    GraphicsPALCallbacks sGraphicsCallbacks;
    DisplayPALCallbacks sDisplayCallbacks;
    Renderer2DCallbacks sRenderer2DCallbacks;
    Renderer3DCallbacks sRenderer3DCallbacks;

    pragma(inline, true)
    ref Renderer2DCallbacks renderer2D() nothrow
    {
        return sRenderer2DCallbacks;
    }

    pragma(inline, true)
    ref Renderer3DCallbacks renderer3D() nothrow
    {
        return sRenderer3DCallbacks;
    }

public static:
    pragma(inline, true)
    ref GraphicsPALCallbacks graphics() nothrow
    {
        return sGraphicsCallbacks;
    }

    pragma(inline, true)
    ref DisplayPALCallbacks display() nothrow
    {
        return sDisplayCallbacks;
    }
}