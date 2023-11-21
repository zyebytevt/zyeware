// D import file generated from 'source/zyeware/pal/display/callbacks.d'
module zyeware.pal.display.callbacks;
import zyeware.common;
import zyeware.rendering;
struct DisplayDriver
{
	public
	{
		NativeHandle function(in DisplayProperties properties, in Display container) createDisplay;
		void function(NativeHandle handle) destroyDisplay;
		void function(NativeHandle handle) update;
		void function(NativeHandle handle) swapBuffers;
		bool function(in NativeHandle handle, KeyCode code) nothrow isKeyPressed;
		bool function(in NativeHandle handle, MouseCode code) nothrow isMouseButtonPressed;
		bool function(in NativeHandle handle, size_t gamepadIndex, GamepadButton button) nothrow isGamepadButtonPressed;
		float function(in NativeHandle handle, size_t gamepadIndex, GamepadAxis axis) nothrow getGamepadAxisValue;
		Vector2i function(in NativeHandle handle) nothrow getCursorPosition;
		void function(NativeHandle handle, bool value) setVSyncEnabled;
		bool function(in NativeHandle handle) nothrow isVSyncEnabled;
		void function(NativeHandle handle, Vector2i value) setPosition;
		Vector2i function(in NativeHandle handle) nothrow getPosition;
		void function(NativeHandle handle, Vector2i value) setSize;
		Vector2i function(in NativeHandle handle) nothrow getSize;
		void function(NativeHandle handle, bool value) setFullscreen;
		bool function(in NativeHandle handle) nothrow isFullscreen;
		void function(NativeHandle handle, bool value) setResizable;
		bool function(in NativeHandle handle) nothrow isResizable;
		void function(NativeHandle handle, bool value) setDecorated;
		bool function(in NativeHandle handle) nothrow isDecorated;
		void function(NativeHandle handle, bool value) setFocused;
		bool function(in NativeHandle handle) nothrow isFocused;
		void function(NativeHandle handle, bool value) setVisible;
		bool function(in NativeHandle handle) nothrow isVisible;
		void function(NativeHandle handle, bool value) setMinimized;
		bool function(in NativeHandle handle) nothrow isMinimized;
		void function(NativeHandle handle, bool value) setMaximized;
		bool function(in NativeHandle handle) nothrow isMaximized;
		void function(NativeHandle handle, in Image image) setIcon;
		const(Image) function(in NativeHandle handle) nothrow getIcon;
		void function(NativeHandle handle, in Cursor cursor) setCursor;
		const(Cursor) function(in NativeHandle handle) nothrow getCursor;
		void function(NativeHandle handle, string title) setTitle;
		string function(in NativeHandle handle) nothrow getTitle;
		void function(NativeHandle handle, bool value) setMouseCursorVisible;
		bool function(in NativeHandle handle) nothrow isMouseCursorVisible;
		void function(NativeHandle handle, bool value) setMouseCursorCaptured;
		bool function(in NativeHandle handle) nothrow isMouseCursorCaptured;
		void function(NativeHandle handle, string value) setClipboardString;
		string function(in NativeHandle handle) getClipboardString;
	}
}
