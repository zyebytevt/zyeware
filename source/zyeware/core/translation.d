// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.translation;

import std.string : format;
import std.exception : enforce, assumeWontThrow;

import sdlang;

import zyeware.common;

/// Translates a key.
alias tr = TranslationManager.translate;

/// Responsible for managing loaded locales and translating requests.
struct TranslationManager
{
private static:
    Translation[string] sLoadedLocales;
    Translation sActiveLocale;

public static:
    /// Translates a key.
    ///
    /// Params:
    ///     key = The key to translate.
    ///
    /// Returns: The translated string, or `key` if it couldn't be translated.
    string translate(string key) nothrow
        in (key, "Key cannot be null.")
    {
        if (sActiveLocale)
            return sActiveLocale.translate(key);

        Logger.core.log(LogLevel.warning, "Tried to translate '%s' without active locale.", key);
        return key;
    }

    /// Registers a locale to the manager. If the given locale is already registered, then
    /// the new translation gets merged into the existing one.
    ///
    /// Params:
    ///     file = The translation file to register. The locale is stored inside of it.
    ///
    /// See_Also: Translation
    void addLocale(Translation file) nothrow
        in (file, "Translation cannot be null.")
    {
        import std.range : chain, byPair, assocArray;

        Translation locale = sLoadedLocales.get(file.mLocale, null).assumeWontThrow;

        if (!locale)
        {
            sLoadedLocales[file.mLocale] = file;
            file.optimize();
            Logger.core.log(LogLevel.debug_, "Added locale '%s' and optimized translation.", file.mLocale);
        }
        else
        {
            locale.mTranslations = locale.mTranslations.byPair.chain(file.mTranslations.byPair).assocArray;
            locale.optimize();
            Logger.core.log(LogLevel.debug_, "Merged new translations into locale '%s' and optimized translation.",
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
            Logger.core.log(LogLevel.debug_, "Removed locale '%s'.", locale);
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

    void locale(string locale)
        in (locale, "Locale cannot be null.")
    {
        Translation* file = locale in sLoadedLocales;
        enforce(file, format!"Locale '%s' doesn't have a file loaded."(locale));

        sActiveLocale = *file;
        Logger.core.log(LogLevel.debug_, "Changed locale to '%s'.", locale);
    }
}

/// `Translation` holds a loaded locale. You can translate strings with it,
/// but it is better suited for usage with `TranslationManager`.
///
/// See_Also: TranslationManager
@asset(Yes.cache)
class Translation
{
protected:
    string mLocale;
    string[string] mTranslations;

public:
    /// Params:
    ///     locale = The ISO 639-1 name for the language.
    ///     translations = Key-to-language translations in a AA.
    this(string locale, string[string] translations)
        in (locale, "Locale cannot be null.")
        in (translations, "Translation AA cannot be null.")
    {
        mLocale = locale;
        mTranslations = translations;
    }

    /// Adds a key with the corresponding translation to the locale.
    ///
    /// Params:
    ///     key = The key.
    ///     translation = The translation it should correspond to.
    void addTranslation(string key, string translation) pure nothrow
        in (key, "Key cannot be null.")
        in (translation, "Translation cannot be null.")
    {
        mTranslations[key] = translation;
    }

    /// Removes a translation from the locale.
    ///
    /// Params:
    ///     key = The key of the translation to remove.
    void removeTranslation(string key) pure nothrow
        in (key, "Key cannot be null.")
    {
        mTranslations.remove(key);
    }

    /// Tries to optimize all further key lookups.
    void optimize() pure nothrow
    {
        mTranslations = mTranslations.rehash;
    }

    /// Translates a key to it's specified translation.
    ///
    /// Params:
    ///     key = The key of the translation to fetch.
    ///
    /// Returns: The translation, or `key` if it doesn't exist.
    string translate(string key) pure const nothrow
        in (key, "Key cannot be null.")
    {
        return mTranslations.get(key, key).assumeWontThrow;
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
    static Translation load(string path)
        in (path, "Path cannot be null.")
    {
        import std.algorithm : filter;

        VFSFile file = VFS.getFile(path);
        Tag root = parseSource(file.readAll!string);
        file.close();

        immutable string locale = root.expectTagValue!string("locale");
        
        string[string] translations;

        foreach (Tag translationTag; root.all.tags.filter!(a => a.name == "translate"))
        {
            immutable string old = translationTag.expectTag("old").expectValue!string;
            immutable string new_ = translationTag.expectTag("new").expectValue!string;

            translations[old] = new_;
        } 

        return new Translation(locale, translations);
    }
}