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
			struct Frame
			{
				size_t index;
				Duration duration;
			}
			struct Animation
			{
				string name;
				Frame[] frames;
				bool isLooping;
				bool hFlip;
				bool vFlip;
				Duration duration() pure const nothrow;
			}
			pure nothrow void addAnimation(string name, Animation animation);
			pure nothrow void removeAnimation(string name);
			pure Animation* getAnimation(string name);
			static SpriteFrames load(string path);
		}
	}
}
