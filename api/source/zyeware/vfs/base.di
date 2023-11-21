// D import file generated from 'source/zyeware/vfs/base.d'
module zyeware.vfs.base;
abstract class VFSBase
{
	protected
	{
		immutable string mFullname;
		immutable string mName;
		pure nothrow this(string fullname, string name);
		public
		{
			const pure nothrow string fullname();
			const pure nothrow string name();
		}
	}
}
