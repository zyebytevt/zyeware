// D import file generated from 'source/zyeware/core/translation.d'
module zyeware.core.translation;
import std.string : format, startsWith;
import std.exception : enforce, assumeWontThrow;
import std.conv : to;
import zyeware.common;
alias tr = TranslationManager.translate;
struct TranslationManager
{
	private static
	{
		Translation[string] sLoadedLocales;
		Translation sActiveLocale;
		public static
		{
			nothrow string translate(string key);
			nothrow string remapAssetPath(string origPath);
			nothrow void addLocale(Translation file);
			nothrow void removeLocale(string locale);
			nothrow string[] allLocales();
			nothrow string locale();
			void locale(string locale);
		}
	}
}
@(asset(Yes.cache))class Translation
{
	protected
	{
		string mLocale;
		string[string] mTranslations;
		string[string] mAssetRemaps;
		public
		{
			this(string locale);
			pure nothrow void addTranslation(string key, string translation);
			pure nothrow void removeTranslation(string key);
			pure void addAssetRemap(string origPath, string newPath);
			pure nothrow void removeAssetRemap(string origPath);
			pure nothrow void optimize();
			const pure nothrow string translate(string key);
			const pure nothrow string remapAssetPath(string origPath);
			const nothrow string locale();
			static Translation load(string path);
		}
	}
}
