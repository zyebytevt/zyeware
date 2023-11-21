// D import file generated from 'source/zyeware/pal/display/opengl/utils.d'
module zyeware.pal.display.opengl.utils;
version (ZW_OpenGL)
{
	import bindbc.sdl;
	import zyeware.common;
	import zyeware.rendering;
	nothrow SDL_Surface* createSurfaceFromImage(in Image image);
}
