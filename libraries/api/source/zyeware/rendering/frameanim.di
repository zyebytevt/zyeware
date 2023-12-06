// D import file generated from 'source/zyeware/rendering/frameanim.d'
module zyeware.rendering.frameanim;
import std.datetime : dur, Duration;
import std.conv : to;
import std.exception : enforce;
import zyeware;
import zyeware.utils.tokenizer;
@(asset(Yes.cache))class FrameAnimations
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
				const pure nothrow Duration duration();
			}
			pure nothrow void addAnimation(string name, Animation animation);
			pure nothrow void removeAnimation(string name);
			pure Animation* getAnimation(string name);
			static FrameAnimations load(string path);
		}
	}
}
