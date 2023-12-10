// D import file generated from 'source/zyeware/core/locale.d'
module zyeware.core.locale;
import std.variant : Variant;
import std.array : Appender;
import std.string : format, startsWith, join, indexOf;
import std.exception : enforce, assumeWontThrow;
import std.conv : to;
import zyeware;
alias tr = LocaleManager.translate;
struct LocaleManager
{
	private static
	{
		Locale[string] sLoadedLocales;
		Locale sActiveLocale;
		public static
		{
			nothrow string translate(string key, Variant[string] = null);
			nothrow void addLocale(Locale file);
			nothrow void removeLocale(string locale);
			nothrow string[] allLocales();
			nothrow string locale();
			void locale(string locale);
		}
	}
}
@(asset(Yes.cache))class Locale
{
	protected
	{
		string mLocale;
		Translation[string] mTranslations;
		public
		{
			this(string locale);
			nothrow void addTranslation(string key, Translation translation);
			nothrow void removeTranslation(string key);
			nothrow void optimize();
			const nothrow string translate(string key, Variant[string] args = null);
			const nothrow string locale();
			static Locale load(string path);
		}
	}
}
enum Plurality
{
	zero,
	one,
	two,
	few,
	many,
	other,
}
private
{
	abstract class Translation
	{
		public abstract const nothrow string get(Variant[string] args);
	}
	final class SimpleTranslation : Translation
	{
		private
		{
			string mText;
			public
			{
				this(string text);
				override const nothrow string get(Variant[string] args);
			}
		}
	}
	final class PlaceholderTranslation : Translation
	{
		private
		{
			struct TextNode
			{
				bool isPlaceholder;
				string value;
			}
			TextNode[] mNodes;
			nothrow void parse(string text);
			public
			{
				this(string text);
				override const nothrow string get(Variant[string] args);
			}
		}
	}
	final class PluralTranslation : Translation
	{
		private
		{
			Translation[Plurality] mTranslations;
			public
			{
				this(Translation[Plurality] translations);
				override const nothrow string get(Variant[string] args);
			}
		}
	}
}
