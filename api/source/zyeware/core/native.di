// D import file generated from 'source/zyeware/core/native.d'
module zyeware.core.native;
alias NativeHandle = void*;
interface NativeObject
{
	const pure nothrow const(NativeHandle) handle();
}
