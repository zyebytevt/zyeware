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

        properties.authorName = root.expectChildValue!string("author");
        properties.projectName = root.expectChildValue!string("name");

        properties.scaleMode = root.getChildValue!string("scale-mode", "center").to!ScaleMode;

        // Load display properties

        SDLNode* displayNode = root.expectChild("display");

        properties.mainDisplayProperties.title = displayNode.expectChildValue!string("title");
        properties.mainDisplayProperties.resizable = cast(Flag!"resizable") displayNode.getChildValue!bool("resizable", false);
        
        properties.mainDisplayProperties.size = Vector2i(displayNode.expectChildValue!int("width"), displayNode.expectChildValue!int("height"));

        if (auto iconNode = displayNode.getChild("icon"))
            properties.mainDisplayProperties.icon = AssetManager.load!Image(iconNode.expectValue!string());

        return properties;
    }
}