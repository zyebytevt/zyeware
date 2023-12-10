module zyeware.core.properties;

import std.conv : to;

import zyeware;

/// Struct that holds information about the project.
/// Note that the author name and project name are used to determine the save data directory.
struct ProjectProperties
{
    string authorName = "Anonymous"; /// The author of the game. Can be anything, from a person to a company.
    string projectName = "ZyeWare Project"; /// The name of the project.

    DisplayProperties mainDisplayProperties; /// The properties of the main display.
    ScaleMode scaleMode = ScaleMode.center; /// How the main framebuffer should be scaled on resizing.

    uint targetFrameRate = 60; /// The frame rate the project should target to hold. This is not a guarantee.

    static ProjectProperties load(string path)
    {
        SDLNode* root = loadSdlDocument(path);

        ProjectProperties properties;

        properties.authorName = cast(string) root.expectChild("author").expectValue();
        properties.projectName = cast(string) root.expectChild("name").expectValue();
        
        if (auto scaleModeNode = root.getChild("scaleMode"))
            properties.scaleMode = (cast(string) scaleModeNode.expectValue()).to!ScaleMode;

        // Load display properties

        SDLNode* displayNode = root.expectChild("display");

        properties.mainDisplayProperties.title = cast(string) displayNode.expectChild("title").expectValue();

        if (auto resizableNode = displayNode.getChild("resizable"))
            properties.mainDisplayProperties.resizable = cast(Flag!"resizable") resizableNode.expectValue();
        
        immutable int width = cast(int) displayNode.expectChild("width").expectValue();
        immutable int height = cast(int) displayNode.expectChild("height").expectValue();
        properties.mainDisplayProperties.size = Vector2i(width, height);

        if (auto iconNode = displayNode.getChild("icon"))
            properties.mainDisplayProperties.icon = AssetManager.load!Image(cast(string) iconNode.expectValue());

        return properties;
    }
}