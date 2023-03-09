module techdemo.menu.vmenu;

import std.typecons : Tuple;

import zyeware.common;
import zyeware.rendering;
import zyeware.audio;

class VerticalMenu
{
protected:
    const Font mFont;
    Entry[] mEntries;
    int mCursor;

    Sound mCursorUp, mCursorDown, mAccept;
    AudioSource mSource;

public:
    struct Entry
    {
        alias Callback = void delegate();

        string text;
        bool disabled;
        Callback onActivated;
        Callback onSelected;
    }

    this(Entry[] entries, in Font font)
    {
        mEntries = entries;
        mFont = font;

        mCursorUp = AssetManager.load!Sound("res://menu/up.ogg");
        mCursorDown = AssetManager.load!Sound("res://menu/down.ogg");
        mAccept = AssetManager.load!Sound("res://menu/accept.ogg");

        mSource = AudioSource.create(null);
    }

    void handleActionEvent(InputEventAction action)
    {
        if (action.isPressed) switch (action.action)
        {
        case "ui_up":
            do
            {
                mCursor -= 1;
                if (mCursor < 0)
                    mCursor += mEntries.length;
            }
            while (mEntries[mCursor].disabled);

            if (mEntries[mCursor].onSelected)
                mEntries[mCursor].onSelected();

            mSource.sound = mCursorUp;
            mSource.play();
            break;

        case "ui_down":
            do
            {
                mCursor += 1;
                if (mCursor >= mEntries.length)
                    mCursor -= mEntries.length;
            }
            while (mEntries[mCursor].disabled);

            if (mEntries[mCursor].onSelected)
                mEntries[mCursor].onSelected();

            mSource.sound = mCursorDown;
            mSource.play();
            break;

        case "ui_accept":
            if (mEntries[mCursor].onActivated)
                mEntries[mCursor].onActivated();

            mSource.sound = mAccept;
            mSource.play();
            break;

        default:
        }
    }

    void draw(Vector2f topCenterPos)
    {
        for (size_t i; i < mEntries.length; ++i)
        {
            Color color;
            if (mEntries[i].disabled)
                color = Color.darkgray;
            else
                color = mCursor == i ? Color.yellow : Color.white;

            Renderer2D.drawString(mEntries[i].text, mFont, topCenterPos + Vector2f(0, i * mFont.bmFont.common.lineHeight + 4), color, Font.Alignment.center);
        }
    }
}
