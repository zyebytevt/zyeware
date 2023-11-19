// D import file generated from 'source/zyeware/pal/pal.d'
module zyeware.pal.pal;
import zyeware.pal.graphics.callbacks;
import zyeware.pal.display.callbacks;
import zyeware.pal.renderer.callbacks;
import zyeware.pal.audio.callbacks;
struct PAL
{
	@disable this();
	@disable this(this);
	package(zyeware) static
	{
		GraphicsPALCallbacks sGraphicsCallbacks;
		DisplayPALCallbacks sDisplayCallbacks;
		Renderer2DCallbacks sRenderer2DCallbacks;
		Renderer3DCallbacks sRenderer3DCallbacks;
		AudioPALCallbacks sAudioCallbacks;
		pragma (inline, true)nothrow ref Renderer2DCallbacks renderer2D()
		{
			return sRenderer2DCallbacks;
		}
		pragma (inline, true)nothrow ref Renderer3DCallbacks renderer3D()
		{
			return sRenderer3DCallbacks;
		}
		public static
		{
			pragma (inline, true)nothrow ref GraphicsPALCallbacks graphics()
			{
				return sGraphicsCallbacks;
			}
			pragma (inline, true)nothrow ref DisplayPALCallbacks display()
			{
				return sDisplayCallbacks;
			}
			pragma (inline, true)nothrow ref AudioPALCallbacks audio()
			{
				return sAudioCallbacks;
			}
		}
	}
}
