// D import file generated from 'source/zyeware/rendering/spriteframes.d'
module zyeware.rendering.spriteframes;
import std.datetime : dur, Duration;
import std.conv : to;
import zyeware.common;
import zyeware.rendering;
@(asset(Yes.cache))class SpriteFrames
{
	protected
	{
		Animation[string] mAnimations;
		public
		{
			struct Animation
			{
				size_t startFrame;
				size_t endFrame;
				Duration frameInterval;
				bool isLooping;
				bool hFlip;
				bool vFlip;
			}
			pure nothrow void addAnimation(string name, Animation animation);
			pure nothrow void removeAnimation(string name);
			pure Animation* getAnimation(string name);
			static SpriteFrames load(string path);
		}
	}
}
