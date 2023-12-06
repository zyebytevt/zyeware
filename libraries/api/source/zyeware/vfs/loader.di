// D import file generated from 'source/zyeware/vfs/loader.d'
module zyeware.vfs.loader;
import zyeware;
import zyeware.vfs;
interface VFSLoader
{
	public
	{
		const VFSDirectory load(string diskPath, string name);
		const bool eligable(string diskPath);
	}
}
