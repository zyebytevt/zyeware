module techdemo.menu.vmenu;

import std.typecons : Tuple;

import zyeware;



class VerticalMenu
{
protected:
    const BitmapFont mFont;
    Entry[] mEntries;
    int mCursor;

    AudioBuffer mCursorUp, mCursorDown, mAccept;
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

    this(Entry[] entries, in BitmapFont font)
    {
        mEntries = entries;
        mFont = font;

        mCursorUp = AssetManager.load!AudioBuffer("res:menu/up.ogg");
        mCursorDown = AssetManager.load!AudioBuffer("res:menu/down.ogg");
        mAccept = AssetManager.load!AudioBuffer("res:menu/accept.ogg");

        mSource = new AudioSource(AudioBus.get("master"));
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

            mSource.buffer = mCursorUp;
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

            mSource.buffer = mCursorDown;
            mSource.play();
            break;

        case "ui_accept":
            if (mEntries[mCursor].onActivated)
                mEntries[mCursor].onActivated();

            mSource.buffer = mAccept;
            mSource.play();
            break;

        default:
        }
    }

    void draw(vec2 topCenterPos)
    {
        for (size_t i; i < mEntries.length; ++i)
        {
            col color;
            if (mEntries[i].disabled)
                color = col.darkgray;
            else
                color = mCursor == i ? col.yellow : col.white;

            Renderer2D.drawString(mEntries[i].text, mFont, topCenterPos + vec2(0, i * mFont.bmFont.common.lineHeight + 4), color, Font.Alignment.center);
        }
    }
}
