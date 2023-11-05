module zyeware.pal.pal;

import zyeware.pal;

struct PAL
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    GraphicsPALCallbacks sGraphicsCallbacks;
    DisplayPALCallbacks sDisplayCallbacks;
    Renderer2DCallbacks sRenderer2DCallbacks;
    Renderer3DCallbacks sRenderer3DCallbacks;

public static:
    ref GraphicsPALCallbacks graphics() nothrow
    {
        return sGraphicsCallbacks;
    }

    ref DisplayPALCallbacks display() nothrow
    {
        return sDisplayCallbacks;
    }

    ref Renderer2DCallbacks renderer2D() nothrow
    {
        return sRenderer2DCallbacks;
    }

    ref Renderer3DCallbacks renderer3D() nothrow
    {
        return sRenderer3DCallbacks;
    }
}