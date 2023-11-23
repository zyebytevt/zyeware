module zyeware.pal.graphics.opengl.init;

import zyeware.pal.graphics.driver;

import api = zyeware.pal.graphics.opengl.api.api;
import r2d = zyeware.pal.graphics.opengl.renderer2d.api;

import zyeware.pal;

public:

shared static this()
{
    Pal.registerGraphicsDriver("opengl", () => GraphicsDriver(
        GraphicsDriver.Api(
            &api.initialize,
            &api.cleanup,
            &api.createMesh,
            &api.createTexture2D,
            &api.createTextureCubeMap,
            &api.createFramebuffer,
            &api.createShader,
            &api.freeMesh,
            &api.freeTexture2D,
            &api.freeTextureCubeMap,
            &api.freeFramebuffer,
            &api.freeShader,
            &api.setShaderUniform1f,
            &api.setShaderUniform2f,
            &api.setShaderUniform3f,
            &api.setShaderUniform4f,
            &api.setShaderUniform1i,
            &api.setShaderUniformMat4f,
            &api.setViewport,
            &api.setRenderFlag,
            &api.getRenderFlag,
            &api.getCapability,
            &api.clearScreen,
            &api.setRenderTarget,
            &api.presentToScreen,
            &api.getTextureFromFramebuffer
        ),
        GraphicsDriver.Renderer2d(
            &r2d.initialize,
            &r2d.cleanup,
            &r2d.beginScene,
            &r2d.endScene,
            &r2d.flush,
            &r2d.drawVertices,
            &r2d.drawRectangle,
            &r2d.drawString,
            &r2d.drawWString,
            &r2d.drawDString
        )
    ));
}