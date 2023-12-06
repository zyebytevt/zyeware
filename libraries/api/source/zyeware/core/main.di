// D import file generated from 'source/zyeware/core/main.d'
module zyeware.core.main;
import core.stdc.stdlib;
import core.runtime : Runtime;
import core.thread : rt_moduleTlsCtor, rt_moduleTlsDtor;
import std.stdio : stderr;
import bindbc.loader;
import zyeware;
import zyeware.core.application;
version (unittest)
{
}
else
{
	int main(string[] args);
}
