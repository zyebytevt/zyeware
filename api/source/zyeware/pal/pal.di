// D import file generated from 'source/zyeware/pal/pal.d'
module zyeware.pal.pal;
import zyeware.pal.graphics.driver;
import zyeware.pal.display.driver;
import zyeware.pal.audio.driver;
struct Pal
{
	@disable this();
	@disable this(this);
	private static
	{
		GraphicsDriver sGraphics;
		DisplayDriver sDisplay;
		AudioDriver sAudio;
		GraphicsDriverLoader[string] sGraphicsLoaders;
		DisplayDriverLoader[string] sDisplayLoaders;
		AudioDriverLoader[string] sAudioLoaders;
		package(zyeware.pal) static
		{
			alias GraphicsDriverLoader = GraphicsDriver function() nothrow;
			alias DisplayDriverLoader = DisplayDriver function() nothrow;
			alias AudioDriverLoader = AudioDriver function() nothrow;
			nothrow void registerGraphicsDriver(string name, GraphicsDriverLoader callbacksGenerator);
			nothrow void registerDisplayDriver(string name, DisplayDriverLoader callbacksGenerator);
			nothrow void registerAudioDriver(string name, AudioDriverLoader callbacksGenerator);
			package(zyeware) static
			{
				nothrow void loadGraphicsDriver(string name);
				nothrow void loadDisplayDriver(string name);
				nothrow void loadAudioDriver(string name);
				nothrow string[] registeredGraphicsDrivers();
				nothrow string[] registeredDisplayDrivers();
				nothrow string[] registeredAudioDrivers();
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
