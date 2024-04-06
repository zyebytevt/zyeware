module zyeware.core.project;

import std.conv : to;
import std.system : OS;

import zyeware;
import zyeware.core.application;

/// Struct that holds information about the project.
/// Note that the author name and project name are used to determine the save data directory.
struct ProjectProperties
{
    string authorName = "Anonymous"; /// The author of the game. Can be anything, from a person to a company.
    string projectName = "ZyeWare Project"; /// The name of the project.

    string mainApplication; /// The fully qualified name of the main application.
    DisplayProperties mainDisplayProperties; /// The properties of the main display.
    ScaleMode scaleMode = ScaleMode.center; /// How the main framebuffer should be scaled on resizing.

    uint targetFrameRate = 60; /// The frame rate the project should target to hold. This is not a guarantee.
}
