// D import file generated from 'source/zyeware/vfs/loader.d'
module zyeware.vfs.loader;
import zyeware;
interface VfsLoader
{
	public
	{
		const VfsDirectory load(string diskPath, string scheme);
		const bool eligable(string diskPath);
	}
}
