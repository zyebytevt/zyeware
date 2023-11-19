// D import file generated from 'source/zyeware/rendering/display.d'
module zyeware.rendering.display;
import zyeware.common;
import zyeware.rendering;
import zyeware.pal;
import zyeware.pal.display.opengl.display;
struct DisplayProperties
{
	string title = "ZyeWare Engine";
	Flag!"resizable" resizable = Yes.resizable;
	Vector2i size = Vector2i(1280, 720);
	Image icon;
}
class Display : NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		DisplayProperties mProperties;
		public
		{
			this(DisplayProperties properties);
			~this();
			void update();
			void swapBuffers();
			nothrow bool isKeyPressed(KeyCode code);
			nothrow bool isMouseButtonPressed(MouseCode code);
			nothrow bool isGamepadButtonPressed(size_t gamepadIdx, GamepadButton button);
			nothrow float getGamepadAxisValue(size_t gamepadIdx, GamepadAxis axis);
			const nothrow Vector2i cursorPosition();
			void isVSyncEnabled(bool value);
			const nothrow bool isVSyncEnabled();
			const pure nothrow const(NativeHandle) handle();
			const nothrow Vector2i position();
			void position(Vector2i value);
			const nothrow Vector2i size();
			void size(Vector2i value);
			const nothrow bool isFullscreen();
			void isFullscreen(bool value);
			const nothrow bool isResizable();
			void isResizable(bool value);
			const nothrow bool isDecorated();
			void isDecorated(bool value);
			const nothrow bool isFocused();
			void isFocused(bool value);
			const nothrow bool isVisible();
			void isVisible(bool value);
			const nothrow bool isMinimized();
			void isMinimized(bool value);
			const nothrow bool isMaximized();
			void isMaximized(bool value);
			const nothrow bool isMouseCursorVisible();
			void isMouseCursorVisible(bool value);
			const nothrow string title();
			void title(string value);
			const nothrow bool isMouseCursorCaptured();
			void isMouseCursorCaptured(bool value);
			const nothrow const(Image) icon();
			void icon(in Image value);
			string clipboardString();
			void clipboardString(string value);
			void cursor(in Cursor value);
			const const(Cursor) cursor();
		}
	}
}
