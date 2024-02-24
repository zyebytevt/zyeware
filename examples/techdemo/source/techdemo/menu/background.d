module techdemo.menu.background;

import std.container.slist;
import std.container.dlist;
import std.datetime;
import std.math : sin, cos, fmod, PI;
import std.random : uniform;

import zyeware;

private static immutable vec2 screenCenter = vec2(320, 240);

class MenuBackground {
protected:
    struct Star {
        vec2 position;
        Duration lifeTime;
    }

    Texture2d mStarTexture;
    Texture2d mBackdrop;

    Star[2000] mStars;
    DList!size_t mFreeStars;
    SList!size_t mActiveStars;

    void processStarPattern(Duration frameTime) {
        static size_t currentPattern = 0;
        static Duration currentPatternDuration;

        while (!frameTime.isNegative) {
            immutable Duration stepDur = dur!"msecs"(10);
            currentPatternDuration += stepDur;
            immutable float patternSecs = currentPatternDuration.total!"msecs" / 1000f;

            final switch (currentPattern) {
            case 0: // Morphing circle
                static int timer;

                immutable float distance = 100f;
                immutable float morphValueX = 0.7 + sin(patternSecs) * 0.3;
                immutable float morphValueY = 0.7 + cos(patternSecs) * 0.3;

                timer -= stepDur.total!"msecs";

                if (timer <= 0) {
                    for (float angle = 0f; angle < PI * 2; angle += 0.08)
                        spawn(screenCenter.x + cos(angle) * distance * morphValueX,
                            screenCenter.y + sin(angle) * distance * morphValueY);

                    timer = 150;
                }
                break;

            case 1: // Weird
                static immutable float[][] data = [
                    [4f, 150f, 7f, 50f],
                    [6f, 50f, 3f, 150f],
                    [9f, 90f, 6f, 110f],
                    [7f, 20f, 1f, 200f],
                    [1f, 40f, 4f, 130f],
                    [2f, 120f, 3f, 170f],
                    [3f, 110f, 2f, 90f],
                    [4f, 200f, 1f, 180f],
                ];

                for (size_t i; i < data.length; ++i)
                    spawn(
                        screenCenter.x + cos(patternSecs + sin(patternSecs) * data[i][0]) * data[i][1],
                        screenCenter.y + sin(patternSecs + cos(patternSecs) * data[i][2]) * data[i][3]
                    );
                break;

            case 2: // Starfield
                float rand() {
                    return uniform(-0.5f, 0.5f) * uniform(0f, 1f);
                }

                for (size_t i; i < 3; ++i)
                    spawn(screenCenter.x + rand() * 640f, screenCenter.y + rand() * 480f);
                break;

            case 3:
                immutable float angle = patternSecs * 2f + sin(patternSecs * 5f);
                immutable float distance = 100f + cos(patternSecs) * 25f;
                immutable vec2 spawnPos = screenCenter + vec2(cos(patternSecs * 2f) * 100f, sin(
                        patternSecs) * 50f);

                for (int i; i < 4; ++i)
                    spawn(
                        spawnPos.x + cos(angle + (PI / 2) * i) * distance,
                        spawnPos.y + sin(angle + (PI / 2) * i) * distance
                    );
                break;
            }

            frameTime -= stepDur;
        }

        if (currentPatternDuration > dur!"seconds"(10)) {
            if (++currentPattern >= 4)
                currentPattern = 0;

            currentPatternDuration = Duration.zero;
        }
    }

public:
    this() {
        mStarTexture = AssetManager.load!Texture2d("res:menu/menuStar.png");
        mBackdrop = AssetManager.load!Texture2d("res:menu/background.png");

        for (size_t i; i < mStars.length; ++i)
            mFreeStars.insertBack(i);
    }

    void spawn(float x, float y) {
        if (mFreeStars.empty)
            return;

        immutable size_t nextFreeStar = mFreeStars.front;
        mFreeStars.removeFront();

        mStars[nextFreeStar].position = vec2(x, y);
        mStars[nextFreeStar].lifeTime = Duration.zero;
        mActiveStars.insertFront(nextFreeStar);
    }

    void tick(Duration frameTime) {
        processStarPattern(frameTime);

        immutable float delta = frameTime.toFloatSeconds;

        size_t[] starIndicesToRemove;

        foreach (size_t starIndex; mActiveStars) {
            vec2* position = &mStars[starIndex].position;

            mStars[starIndex].lifeTime += frameTime;

            immutable float lifeTimeSecs = mStars[starIndex].lifeTime.toFloatSeconds;
            immutable float alpha = 1 - lifeTimeSecs / 10f;

            position.x += (position.x - screenCenter.x) * 1.5 * delta;
            position.y += (position.y - screenCenter.y) * 1.5 * delta;

            if (position.x < 0 || position.x > screenCenter.x * 2 || position.y < 0
                || position.y > screenCenter.y * 2 || alpha <= 0)
                starIndicesToRemove ~= starIndex;
        }

        foreach (size_t starIndex; starIndicesToRemove) {
            mActiveStars.linearRemoveElement(starIndex);
            mFreeStars.insertBack(starIndex);
        }
    }

    void draw() {
        immutable float upTime = ZyeWare.upTime.toFloatSeconds;
        Renderer2d.drawRectangle(rect(-10, -10, 660, 500), vec2(cos(upTime * 0.5f) * 10f, sin(
                upTime) * 10f),
            vec2(1), color.white, mBackdrop);

        foreach (size_t starIndex; mActiveStars) {
            immutable float lifeTimeSecs = mStars[starIndex].lifeTime.toFloatSeconds;
            immutable float alpha = 1 - lifeTimeSecs / 10f;

            Renderer2d.drawRectangle(rect(-4, -4, 8, 8), mStars[starIndex].position, vec2(1),
                color(fmod(lifeTimeSecs, 1), 1, 1, alpha).toRgb(), mStarTexture);
        }
    }
}
