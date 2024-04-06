// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.pal.display.sdl.utils;
version (ZW_PAL_SDL)  : import bindbc.sdl;

import zyeware;

package:

SDL_Surface* createSurfaceFromImage(in Image image) nothrow
{
    uint rmask, gmask, bmask, amask;
    version (BigEndian)
    {
        int shift = (image.channels == 4) ? 8 : 0;
        rmask = 0xff000000 >> shift;
        gmask = 0x00ff0000 >> shift;
        bmask = 0x0000ff00 >> shift;
        amask = 0x000000ff >> shift;
    }
    else
    {
        rmask = 0x000000ff;
        gmask = 0x0000ff00;
        bmask = 0x00ff0000;
        amask = (image.channels == 4) ? 0xff000000 : 0;
    }

    int depth = image.channels * 8;
    int pitch = image.channels * cast(int) image.size.x;

    return SDL_CreateRGBSurfaceFrom(cast(void*)&image.pixels[0],
        cast(int) image.size.x, cast(int) image.size.y, depth, pitch, rmask, gmask, bmask, amask);
}
