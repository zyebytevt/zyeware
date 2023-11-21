module zyeware.pal.graphicsDriver.types;

enum RenderFlag
{
    depthTesting, /// Whether to use depth testing or not.
    depthBufferWriting, /// Whether to write to the depth buffer when drawing.
    culling, /// Whether culling is enabled or not.
    stencilTesting, /// Whether to use stencil testing or not.
    wireframe /// Whether to render in wireframe or not.
}

enum RenderCapability
{
    maxTextureSlots /// How many texture slots are available to use. 
}