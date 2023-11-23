// D import file generated from 'modules/pal/display/sdl/source/types.d'
module zyeware.pal.display.sdl_opengl.types;
import std.typecons : Rebindable;
import bindbc.sdl;
import zyeware.rendering;
import zyeware.common;
struct WindowData
{
	public
	{
		string title;
		Vector2i size;
		Vector2i position;
		bool isFullscreen;
		bool isVSyncEnabled;
		bool isCursorCaptured;
		Rebindable!(const(Image)) icon;
		Rebindable!(const(Cursor)) cursor;
		SDL_Cursor*[const(Cursor)] sdlCursors;
		SDL_Window* handle;
		SDL_GLContext glContext;
		ubyte[] keyboardState;
		SDL_GameController*[32] gamepads;
		Rebindable!(const(Display)) container;
	}
}
