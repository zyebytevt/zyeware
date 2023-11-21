// D import file generated from 'source/zyeware/pal/pal.d'
module zyeware.pal.pal;
import zyeware.pal.graphics.callbacks;
import zyeware.pal.display.callbacks;
import zyeware.pal.renderer.callbacks;
import zyeware.pal.audio.callbacks;
struct Pal
{
	@disable this();
	@disable this(this);
	private static
	{
		GraphicsDriver sGraphics;
		DisplayDriver sDisplay;
		Renderer2dDriver sRenderer2D;
		Renderer3dDriver sRenderer3D;
		AudioDriver sAudio;
		GraphicsPalLoader[string] sGraphicsLoaders;
		DisplayPalLoader[string] sDisplayLoaders;
		Renderer2dPalLoader[string] sRenderer2dLoaders;
		Renderer3dPalLoader[string] sRenderer3dLoaders;
		AudioPalLoader[string] sAudioLoaders;
		package(zyeware.pal) static
		{
			alias GraphicsPalLoader = GraphicsDriver function() nothrow;
			alias DisplayPalLoader = DisplayDriver function() nothrow;
			alias Renderer2dPalLoader = Renderer2dDriver function() nothrow;
			alias Renderer3dPalLoader = Renderer3dDriver function() nothrow;
			alias AudioPalLoader = AudioDriver function() nothrow;
			nothrow void registerGraphics(string name, GraphicsPalLoader callbacksGenerator);
			nothrow void registerDisplay(string name, DisplayPalLoader callbacksGenerator);
			nothrow void registerRenderer2d(string name, Renderer2dPalLoader callbacksGenerator);
			nothrow void registerRenderer3d(string name, Renderer3dPalLoader callbacksGenerator);
			nothrow void registerAudio(string name, AudioPalLoader callbacksGenerator);
			package(zyeware) static
			{
				nothrow void loadGraphics(string name);
				nothrow void loadDisplay(string name);
				nothrow void loadRenderer2d(string name);
				nothrow void loadRenderer3d(string name);
				nothrow void loadAudio(string name);
				nothrow string[] registeredGraphics();
				nothrow string[] registeredDisplay();
				nothrow string[] registeredRenderer2d();
				nothrow string[] registeredRenderer3d();
				nothrow string[] registeredAudio();
				pragma (inline, true)nothrow ref Renderer2dDriver renderer2d()
				{
					return sRenderer2D;
				}
				pragma (inline, true)nothrow ref Renderer3dDriver renderer3d()
				{
					return sRenderer3D;
				}
				public static
				{
					pragma (inline, true)nothrow ref GraphicsDriver graphics()
					{
						return sGraphics;
					}
					pragma (inline, true)nothrow ref DisplayDriver display()
					{
						return sDisplay;
					}
					pragma (inline, true)nothrow ref AudioDriver audio()
					{
						return sAudio;
					}
				}
			}
		}
	}
}
