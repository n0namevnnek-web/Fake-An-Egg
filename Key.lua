--[[
    NNVN HUB - Ophyn + Jnkie key system

    Execution order:
      1. GitHub Key.lua opens Ophyn.
      2. Ophyn validates the entered/saved Jnkie key.
      3. Only the validated callback downloads the protected main script.

    Upload this source as Anime-Dimension/Key.lua.
]]

local PROTECTED_SCRIPT_URL = "https://api.jnkie.com/api/v1/luascripts/public/38082b45aca153fcca5e0ea4aca6f5332cd0af7fc77d137e6f2e36e79b1cf7ce/download"
local OPHYN_INTERFACE_URL = "https://ophyn.space/interface"

local environment = (getgenv and getgenv()) or _G

-- Prevent two queued teleport executions from opening two key windows.
if environment.NNVN_ANIME_KEY_SYSTEM_LOADING then
    return
end
environment.NNVN_ANIME_KEY_SYSTEM_LOADING = true

-- Never let a token left by an older session authorize this execution.
environment.SCRIPT_KEY = nil
environment.NNVN_JnkieValidated = false

local function finishLoading()
    environment.NNVN_ANIME_KEY_SYSTEM_LOADING = nil
end

local function warnAndFinish(message)
    warn("[NNVN HUB] " .. tostring(message))
    finishLoading()
end

local function compile(source, chunkName)
    if type(source) ~= "string" or source == "" then
        return nil, "empty source"
    end
    return loadstring(source, chunkName)
end

local mainStarted = false

local function loadProtectedMainScript(key)
    if mainStarted then
        return
    end
    if type(key) ~= "string" or key == "" then
        warnAndFinish("Jnkie did not return a valid key.")
        return
    end

    -- The Jnkie endpoint is intentionally called only after this callback.
    environment.SCRIPT_KEY = key
    environment.NNVN_JnkieValidated = true

    local downloaded, source = pcall(function()
        return game:HttpGet(PROTECTED_SCRIPT_URL, true)
    end)

    if not downloaded or type(source) ~= "string" or #source < 100 then
        environment.SCRIPT_KEY = nil
        environment.NNVN_JnkieValidated = false
        warnAndFinish("Protected script download failed: " .. tostring(source))
        return
    end

    local chunk, compileError = compile(source, "@NNVN_ANIME_DIMENSIONS_MAIN")
    if not chunk then
        environment.SCRIPT_KEY = nil
        environment.NNVN_JnkieValidated = false
        warnAndFinish("Protected script compile error: " .. tostring(compileError))
        return
    end

    mainStarted = true
    finishLoading()

    local executed, runtimeError = xpcall(chunk, function(message)
        if debug and debug.traceback then
            return debug.traceback(tostring(message), 2)
        end
        return tostring(message)
    end)

    if not executed then
        warn("[NNVN HUB] Main script runtime error: " .. tostring(runtimeError))
    end
end

local interfaceDownloaded, interfaceSource = pcall(function()
    return game:HttpGet(OPHYN_INTERFACE_URL, true)
end)

if not interfaceDownloaded then
    warnAndFinish("Failed to download Ophyn: " .. tostring(interfaceSource))
    return
end

local interfaceChunk, interfaceCompileError = compile(interfaceSource, "@OPHYN_INTERFACE")
if not interfaceChunk then
    warnAndFinish("Ophyn compile error: " .. tostring(interfaceCompileError))
    return
end

local interfaceLoaded, Ophyn = pcall(interfaceChunk)
if not interfaceLoaded or type(Ophyn) ~= "table" or type(Ophyn.new) ~= "function" then
    warnAndFinish("Ophyn initialization failed: " .. tostring(Ophyn))
    return
end

local created, createError = pcall(function()
    Ophyn.new({
        Title = "NNVN HUB",
        Description = "Fake An Egg Key System",
        Logo = "rbxassetid://138952058031836",
        Theme = "Dark",
        Folder = "NNVN_HUB",

        getkey = true,

        Intro = "true",
        startintro_size = 80,
        squareintro_time = 1.2,

        Changelogocolor = true,
        Changeiconscolor = true,
        ChangeTheme = true,
        NotifStyle = "1",
        TabsStyle = "1",

        discord_link = "discord.gg/n4DbXTyNPj",
        Discord = "true",
        Website = "false",

        SupportedGames = {
            [97289366402005] = true,
        },

        KeySystem = {
            SaveKey = true,
            API = {
                {
                    Type = "jnkie",
                    Service = "NNVN Hub",
                    Identifier = "1168483",
                    Provider = "NNVN Hub",
                },
            },
        },

        Callback = function(key)
            loadProtectedMainScript(key)
        end,
    })
end)

if not created then
    warnAndFinish("Could not create the key window: " .. tostring(createError))
end
