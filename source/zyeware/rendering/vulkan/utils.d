module zyeware.rendering.vulkan.utils;

version (ZW_Vulkan):
package(zyeware.rendering.vulkan):

import bindbc.sdl;
import erupted;

import zyeware.common;
import zyeware.rendering;

/*VkResult vkCreateDebugUtilsMessengerEXT(VkInstance instance, const VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pDebugMessenger) {
    auto func = cast(PFN_vkCreateDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");

    if (func)
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    else
        return VK_ERROR_EXTENSION_NOT_PRESENT;
}

void vkDestroyDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerEXT debugMessenger, const VkAllocationCallbacks* pAllocator) {
    auto func = cast(PFN_vkDestroyDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if (func)
        func(instance, debugMessenger, pAllocator);
}*/

SDL_Surface* createSurfaceFromImage(const Image image) nothrow
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

    return SDL_CreateRGBSurfaceFrom(cast(void*) &image.pixels[0], cast(int) image.size.x, cast(int) image.size.y,
        depth, pitch, rmask, gmask, bmask, amask);
}