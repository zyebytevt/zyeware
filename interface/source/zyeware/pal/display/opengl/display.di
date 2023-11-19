// D import file generated from 'source/zyeware/pal/display/opengl/display.d'
module zyeware.pal.display.opengl.display;
import zyeware.core.native;
import zyeware.rendering.display;
import zyeware.pal.display.opengl.utils;
version (ZW_OpenGL)
{
	import core.stdc.string : memcpy;
	import std.string : fromStringz, toStringz, format;
	import std.exception : enforce;
	import std.typecons : scoped, Rebindable;
	import std.math : isClose;
	import std.utf : decode;
	import bindbc.sdl;
	import bindbc.opengl;
	import zyeware.common;
	import zyeware.rendering;
	import zyeware.pal.display.callbacks;
	import zyeware.pal;
	import std.numeric;
	public
	{
		DisplayPALCallbacks generateDisplayPALCallbacks();
		private
		{
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
			extern size_t pWindowCount;
			extern (C) static nothrow void sdlLogFunctionCallback(void* userdata, int category, SDL_LogPriority priority, const char* message);
			nothrow void addGamepad(WindowData* windowData, size_t joyIdx);
			nothrow void removeGamepad(WindowData* windowData, size_t instanceId);
			nothrow ptrdiff_t getGamepadIndex(in WindowData* windowData, SDL_GameController* pad);
			nothrow ptrdiff_t getGamepadIndex(in WindowData* windowData, int instanceId);
			public
			{
				NativeHandle createDisplay(in DisplayProperties properties, in Display container);
				void destroyDisplay(NativeHandle handle);
				void update(NativeHandle handle);
				void swapBuffers(NativeHandle handle);
				nothrow bool isKeyPressed(in NativeHandle handle, KeyCode code);
				nothrow bool isMouseButtonPressed(in NativeHandle handle, MouseCode code);
				nothrow bool isGamepadButtonPressed(in NativeHandle handle, size_t gamepadIdx, GamepadButton button);
				nothrow float getGamepadAxisValue(in NativeHandle handle, size_t gamepadIdx, GamepadAxis axis);
				nothrow Vector2i getCursorPosition(in NativeHandle handle);
				nothrow void setVSyncEnabled(NativeHandle handle, bool value);
				nothrow bool isVSyncEnabled(in NativeHandle handle);
				nothrow Vector2i getPosition(in NativeHandle handle);
				nothrow void setPosition(NativeHandle handle, Vector2i value);
				nothrow Vector2i getSize(in NativeHandle handle);
				nothrow void setSize(NativeHandle handle, Vector2i value);
				nothrow void setFullscreen(NativeHandle handle, bool value);
				nothrow bool isFullscreen(in NativeHandle handle);
				nothrow void setResizable(NativeHandle handle, bool value);
				nothrow bool isResizable(in NativeHandle handle);
				nothrow void setDecorated(NativeHandle handle, bool value);
				nothrow bool isDecorated(in NativeHandle handle);
				nothrow void setFocused(NativeHandle handle, bool value);
				nothrow bool isFocused(in NativeHandle handle);
				nothrow void setVisible(NativeHandle handle, bool value);
				nothrow bool isVisible(in NativeHandle handle);
				nothrow void setMinimized(NativeHandle handle, bool value);
				nothrow bool isMinimized(in NativeHandle handle);
				nothrow void setMaximized(NativeHandle handle, bool value);
				nothrow bool isMaximized(in NativeHandle handle);
				void setIcon(NativeHandle handle, in Image image);
				nothrow const(Image) getIcon(in NativeHandle handle);
				void setCursor(NativeHandle handle, in Cursor cursor);
				nothrow const(Cursor) getCursor(in NativeHandle handle);
				void setTitle(NativeHandle handle, in string value);
				nothrow string getTitle(in NativeHandle handle);
				nothrow void setMouseCursorVisible(NativeHandle handle, bool value);
				nothrow bool isMouseCursorVisible(in NativeHandle handle);
				nothrow bool isMouseCursorCaptured(in NativeHandle handle);
				nothrow void setMouseCursorCaptured(NativeHandle handle, bool value);
				nothrow void setClipboardString(NativeHandle handle, in string value);
				nothrow string getClipboardString(in NativeHandle handle);
			}
		}
	}
}
