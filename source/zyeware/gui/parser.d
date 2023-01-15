// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.gui.parser;

import std.exception : enforce;
import std.string : format;
import std.algorithm : filter;

import sdlang;

import zyeware.common;
import zyeware.gui;

struct GUIParser
{
private static:
    alias CreateFunc = GUINode function(GUINode parent, string name, Sides margin, Sides anchor);
    CreateFunc[string] sCreateFunctions;

    Sides parseSidesTag(Tag tag)
    {
        if (tag.values.length == 1)
        {
            switch (tag.getValue!string)
            {
            case "zero": return Sides.zero;
            case "one": return Sides.one;

            case "fill": return Sides.fill;
            case "center": return Sides.center;

            case "topSide": return Sides.topSide;
            case "rightSide": return Sides.rightSide;
            case "bottomSide": return Sides.bottomSide;
            case "leftSide": return Sides.leftSide;

            default:
                throw new GUIException(format!"Unknown sides constant '%s'."(tag.getValue!string));
            }
        }

        enforce!GUIException(tag.values.length == 4, format!"Invalid number of values for sides tag '%s'."(tag.getFullName().toString()));
        return Sides(tag.values[0].coerce!float,
            tag.values[1].coerce!float,
            tag.values[2].coerce!float,
            tag.values[3].coerce!float);
    }

    GUINode parseNode(Tag rootTag, GUINode parent)
    {
        string name = rootTag.getTagValue!string("prop:name");
        Sides margin = Sides.zero;
        Sides anchor = Sides.fill;

        if (Tag marginTag = rootTag.getTag("prop:margin"))
            margin = parseSidesTag(marginTag);

        if (Tag anchorTag = rootTag.getTag("prop:anchor"))
            anchor = parseSidesTag(anchorTag);

        CreateFunc creator = sCreateFunctions.get(rootTag.name, null);
        enforce!GUIException(creator, format!"GUI node type '%s' unknown."(rootTag.name));

        GUINode root = creator(parent, name, margin, anchor);

        foreach (Tag childTag; rootTag.tags.filter!(t => t.namespace == ""))
            root.addChild(parseNode(childTag, root));

        return root;
    }

public static:
    static this()
    {
        sCreateFunctions["node"] = (parent, name, margin, anchor) {
            return new GUINode(parent, anchor, margin, name);
        };

        sCreateFunctions["button"] = (parent, name, margin, anchor) {
            return new GUIButton(parent, anchor, margin, name);
        };
    }

    GUINode parseFile(string path)
    {
        VFSFile file = VFS.getFile(path, VFSFile.Mode.read);
        immutable string source = file.readAll!string();
        file.close();

        Tag root = parseSource(source, path);
        enforce!GUIException(root.tags.length == 1, "Either no or more than one root node was defined.");
        return parseNode(root.tags[0], null);
    }
}