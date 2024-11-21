Locales = {}

local translationCache = {} -- Cache for translations

function _(str, ...) -- Translate string
    -- Check cache first
    if translationCache[str] and select("#", ...) > 0 then
        -- Use cached translation with formatting
        return string.format(translationCache[str], ...)
    elseif translationCache[str] then
        -- Use cached translation without formatting
        return translationCache[str]
    end

    local lang = Config.defaultlang
    local defaultLang = "en" -- Set your fallback language here (e.g., 'en')

    if Locales[lang] ~= nil then
        if Locales[lang][str] ~= nil then
            translationCache[str] = Locales[lang][str] -- Cache the translation for faster future access
            if select("#", ...) > 0 then
                return string.format(Locales[lang][str], ...)
            else
                return Locales[lang][str]
            end
        elseif Locales[defaultLang] ~= nil and Locales[defaultLang][str] ~= nil then
            translationCache[str] = Locales[defaultLang][str]
            if select("#", ...) > 0 then
                return string.format(Locales[defaultLang][str], ...)
            else
                return Locales[defaultLang][str]
            end
        else
            return 'Translation [' .. lang .. '][' .. str .. '] and fallback [' .. defaultLang .. '] do not exist'
        end
    else
        return 'Locale [' .. lang .. '] does not exist'
    end
end

function _U(str, ...) -- Translate string with first character uppercase
    -- Use cached translation if available
    local translation = _(str, ...)
    return translation:sub(1, 1):upper() .. translation:sub(2)
end