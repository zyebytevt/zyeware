module zyeware.pal.graphics.opengl.init; version(ZW_PAL_OPENGL):

import zyeware.pal.generic.drivers;

import api = zyeware.pal.graphics.opengl.api.api;
import r2d = zyeware.pal.graphics.opengl.renderer2d.api;

package(zyeware.pal):

void load(ref GraphicsDriver driver) nothrow
{
    driver.api.initialize = &api.initialize;
    driver.api.cleanup = &api.cleanup;
    driver.api.createMesh = &api.createMesh;
    driver.api.createTexture2D = &api.createTexture2D;
    driver.api.createTextureCubeMap = &api.createTextureCubeMap;
    driver.api.createFramebuffer = &api.createFramebuffer;
    driver.api.createShader = &api.createShader;
    driver.api.freeMesh = &api.freeMesh;
    driver.api.freeTexture2D = &api.freeTexture2D;
    driver.api.freeTextureCubeMap = &api.freeTextureCubeMap;
    driver.api.freeFramebuffer = &api.freeFramebuffer;
    driver.api.freeShader = &api.freeShader;
    driver.api.setShaderUniform1f = &api.setShaderUniform1f;
    driver.api.setShaderUniform2f = &api.setShaderUniform2f;
    driver.api.setShaderUniform3f = &api.setShaderUniform3f;
    driver.api.setShaderUniform4f = &api.setShaderUniform4f;
    driver.api.setShaderUniform1i = &api.setShaderUniform1i;
    driver.api.setShaderUniformMat4f = &api.setShaderUniformMat4f;
    driver.api.setViewport = &api.setViewport;
    driver.api.setRenderFlag = &api.setRenderFlag;
    driver.api.getRenderFlag = &api.getRenderFlag;
    driver.api.getCapability = &api.getCapability;
    driver.api.clearScreen = &api.clearScreen;
    driver.api.setRenderTarget = &api.setRenderTarget;
    driver.api.presentToScreen = &api.presentToScreen;
    driver.api.getTextureFromFramebuffer = &api.getTextureFromFramebuffer;

    driver.renderer2d.initialize = &r2d.initialize;
    driver.renderer2d.cleanup = &r2d.cleanup;
    driver.renderer2d.beginScene = &r2d.beginScene;
    driver.renderer2d.endScene = &r2d.endScene;
    driver.renderer2d.flush = &r2d.flush;
    driver.renderer2d.drawVertices = &r2d.drawVertices;
    driver.renderer2d.drawRectangle = &r2d.drawRectangle;
    driver.renderer2d.drawString = &r2d.drawString;
    driver.renderer2d.drawWString = &r2d.drawWString;
    driver.renderer2d.drawDString = &r2d.drawDString;
}