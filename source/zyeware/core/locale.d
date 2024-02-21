// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.locale;

import std.variant : Variant;
import std.array : Appender;
import std.string : format, startsWith, join, indexOf;
import std.exception : enforce, assumeWontThrow;
import std.conv : to;

import zyeware;

/// Translates a key.
alias tr = LocaleManager.translate;

/// Responsible for managing loaded locales and translating requests.
struct LocaleManager
{
private static:
    Locale[string] sLoadedLocales;
    Locale sActiveLocale;

public static:
    /// Translates a key.
    ///
    /// Params:
    ///     key = The key to translate.
    ///
    /// Returns: The translated string, or `key` if it couldn't be translated.
    string translate(string key, Variant[string] args = null) nothrow
        in (key, "Key cannot be null.")
    {
        if (sActiveLocale)
            return sActiveLocale.translate(key, args);

        Logger.core.warning("Tried to translate '%s' without active locale.", key);
        return key;
    }

    /// Registers a locale to the manager. If the given locale is already registered, then
    /// the new translation gets merged into the existing one.
    ///
    /// Params:
    ///     file = The translation file to register. The locale is stored inside of it.
    ///
    /// See_Also: Translation
    void addLocale(Locale file) nothrow
        in (file, "Translation cannot be null.")
    {
        import std.range : chain, byPair, assocArray;

        Locale locale = sLoadedLocales.get(file.mLocale, null).assumeWontThrow;

        if (!locale)
        {
            sLoadedLocales[file.mLocale] = file;
            file.optimize();
            Logger.core.info("Added locale '%s' and optimized translation.", file.mLocale);
        }
        else
        {
            locale.mTranslations = locale.mTranslations.byPair.chain(file.mTranslations.byPair).assocArray;
            locale.optimize();
            Logger.core.info("Merged new translations into locale '%s' and optimized translation.",
                file.mLocale);
        }
    }

    /// Unregisters a locale from the manager.
    ///
    /// Params:
    ///     locale = The locale name to unregister.
    void removeLocale(string locale) nothrow
        in (locale, "Locale cannot be null.")
    {
        if (sLoadedLocales.remove(locale))
            Logger.core.debug_("Removed locale '%s'.", locale);
    }

    /// All currently loaded locales.
    string[] allLocales() nothrow
    {
        return sLoadedLocales.keys;
    }

    /// The currently active locale.
    string locale() nothrow
    {
        if (!sActiveLocale)
            return null;

        return sActiveLocale.mLocale;
    }

    /// ditto
    void locale(string locale)
        in (locale, "Locale cannot be null.")
    {
        Locale* file = locale in sLoadedLocales;
        enforce(file, format!"Locale '%s' doesn't have a file loaded."(locale));

        sActiveLocale = *file;
        Logger.core.debug_("Changed locale to '%s'.", locale);
    }
}

@asset(Yes.cache)
class Locale
{
protected:
    string mLocale;
    Translation[string] mTranslations;

public:
    /// Params:
    ///     locale = The ISO 639-1 name for the language.
    ///     translations = Key-to-language translations in an AA.
    ///     assetRemaps = The resource remaps in an AA.
    this(string locale)
        in (locale, "Locale cannot be null.")
    {
        mLocale = locale;
    }

    /// Adds a key with the corresponding translation to the locale.
    ///
    /// Params:
    ///     key = The key.
    ///     translation = The translation it should correspond to.
    void addTranslation(string key, Translation translation) nothrow
        in (key, "Key cannot be null.")
        in (translation, "Translation cannot be null.")
    {
        mTranslations[key] = translation;
    }

    /// Removes a translation from the locale.
    ///
    /// Params:
    ///     key = The key of the translation to remove.
    void removeTranslation(string key) nothrow
        in (key, "Key cannot be null.")
    {
        mTranslations.remove(key);
    }

    /// Tries to optimize all further key lookups.
    void optimize() nothrow
    {
        mTranslations = mTranslations.rehash;
    }

    /// Translates a key to it's specified translation.
    ///
    /// Params:
    ///     key = The key of the translation to fetch.
    ///
    /// Returns: The translation, or `key` if it doesn't exist.
    string translate(string key, Variant[string] args = null) const nothrow
        in (key, "Key cannot be null.")
    {
        const(Translation)* translation = key in mTranslations;
        if (!translation)
            return "[" ~ key ~ " NOT FOUND]";

        return translation.get(args);
    }

    /// The ISO 639-1 name of this locale.
    string locale() const nothrow
    {
        return mLocale;
    }

    /// Loads and returns a `Translation` instance from the given file.
    ///
    /// Params:
    ///     path = The path of the file to load.
    static Locale load(string path)
        in (path, "Path cannot be null.")
    {
        SDLNode* root = loadSdlDocument(path);

        immutable string localeName = root.expectChildValue!string("locale");

        auto locale = new Locale(localeName);

        void parseGroup(SDLNode* current, string[] path)
        {
            for (size_t i; i < current.children.length; ++i)
            {
                SDLNode* child = &current.children[i];
                if (child.qualifiedName == "locale")
                    continue;

                Translation translation;
                
                switch (child.getAttributeValue!string("type", "simple"))
                {
                case "plural":
                    Translation[Plurality] translations;

                    for (size_t j; j < child.children.length; ++j)
                    {
                        SDLNode* pluralNode = &child.children[j];

                        Plurality plurality = pluralNode.name.to!Plurality;
                        immutable string value = pluralNode.expectValue!string();

                        if (value.indexOf('{') != -1)
                            translations[plurality] = new PlaceholderTranslation(value);
                        else
                            translations[plurality] = new LiteralTranslation(value);    
                    }

                    enforce!ResourceException(Plurality.other in translations, "Plural translations must contain 'other'.");

                    translation = new PluralTranslation(translations);
                    break;

                default:
                    // This child is a sub-group
                    if (child.values.length == 0 && child.children.length > 0)
                    {
                        path ~= child.name;
                        parseGroup(child, path);
                        path = path[0 .. $ - 1];
                        continue;
                    }

                    immutable string value = child.expectValue!string();

                    if (value.indexOf('{') != -1)
                        translation = new PlaceholderTranslation(value);
                    else
                        translation = new LiteralTranslation(value);
                    break;
                }

                path ~= child.name;
                immutable string pathString = path.join(".");
                locale.addTranslation(pathString, translation);
                Logger.core.verbose("Added '%s' to locale %s.", pathString, localeName);
                path = path[0 .. $ - 1];
            }
        }

        parseGroup(root, []);

        return locale;
    }
}

enum Plurality
{
    zero,
    one,
    two,
    few,
    many,
    other
}

private:

abstract class Translation
{
public:
    abstract string get(Variant[string] args) const nothrow;
}

final class LiteralTranslation : Translation
{
private:
    string mText;

public:
    this(string text)
        in (text, "Text cannot be null.")
    {
        mText = text;
    }

    override string get(Variant[string] args) const nothrow
    {
        return mText;
    }
}

final class PlaceholderTranslation : Translation
{
private:
    struct TextNode
    {
        bool isPlaceholder;
        string value;
    }

    TextNode[] mNodes;

    void parse(string text) nothrow
    {
        size_t index = 0;
        
        while (index < text.length)
        {
            if (text[index] == '{')
            {
                immutable size_t start = index + 1;
                while (index < text.length && text[index] != '}')
                    ++index;

                TextNode node;
                node.isPlaceholder = true;
                node.value = text[start .. index++];
                mNodes ~= node;
            }
            else
            {
                immutable size_t start = index;
                while (index < text.length && text[index] != '{')
                    ++index;

                TextNode node;
                node.isPlaceholder = false;
                node.value = text[start .. index];
                mNodes ~= node;
            }
        }
    }

public:
    this(string text)
        in (text, "Text cannot be null.")
    {
        parse(text);
    }

    override string get(Variant[string] args) const nothrow
    {
        Appender!string result;

        foreach (const ref node; mNodes)
        {
            if (!node.isPlaceholder)
                result ~= node.value;
            else
            {
                Variant* value = args ? node.value in args : null;
                if (!value)
                    result ~= "[" ~ node.value ~ " PLACEHOLDER NOT FOUND]";
                else
                {
                    try result ~= value.toString();
                    catch (Exception) result ~= "[" ~ node.value ~ " ERRORED OUT]";
                }
            }
        }

        return result[];
    }
}

final class PluralTranslation : Translation
{
private:
    Translation[Plurality] mTranslations;

public:
    this(Translation[Plurality] translations)
        in (translations, "Translations cannot be null.")
        in (Plurality.other in translations, "Translations must contain 'other'.")
    {
        mTranslations = translations;
    }

    override string get(Variant[string] args) const nothrow
    {
        Variant* value = args ? "count" in args : null;
        if (!value)
            return "[count PLACEHOLDER NOT GIVEN]";

        try
        {
            int count = value.coerce!int;
            Plurality plurality;

            if (count == 0)
                plurality = Plurality.zero;
            else if (count == 1)
                plurality = Plurality.one;
            else if (count == 2)
                plurality = Plurality.two;
            else if (count >= 3 && count <= 10)
                plurality = Plurality.few;
            else if (count >= 11 && count <= 99)
                plurality = Plurality.many;
            else
                plurality = Plurality.other;

            const(Translation)* translation = plurality in mTranslations;
            if (!translation)
                return mTranslations[Plurality.other].get(args);

            return translation.get(args);
        }
        catch (Exception)
        {
            return "[count ERROR]";
        }
    }
}