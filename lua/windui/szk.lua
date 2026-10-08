-- ═══════════════════════════════════════════════════════════════════
--  ███████╗██╗     ██╗   ██╗██╗██████╗     ██╗   ██╗██╗
--  ██╔════╝██║     ██║   ██║██║██╔══██╗    ██║   ██║██║
--  █████╗  ██║     ██║   ██║██║██║  ██║    ██║   ██║██║
--  ██╔══╝  ██║     ██║   ██║██║██║  ██║    ╚██╗ ██╔╝██║
--  ██║     ███████╗╚██████╔╝██║██████╔╝     ╚████╔╝ ██║
--  ╚═╝     ╚══════╝ ╚═════╝ ╚═╝╚═════╝       ╚═══╝  ╚═╝
--
--  FLUID UI v1.0.0 — By SZK
-- ═══════════════════════════════════════════════════════════════════

local SZK = {
    Themes = {}, Windows = {}, Flags = {}, Icons = {},
    CurrentTheme = nil, ConfigFolder = "SZK_Configs",
    Version = "1.0.0",
    _connections = {},
}

-- ═══════════════════════════════════════════════════════════════
--  SERVICIOS
-- ═══════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local Mouse            = LocalPlayer and LocalPlayer:GetMouse()
local CoreGui          = game:GetService("CoreGui")

-- ═══════════════════════════════════════════════════════════════
--  UTILIDADES
-- ═══════════════════════════════════════════════════════════════

local function SafeParent(gui)
    local parent = (gethui and gethui()) or CoreGui
    gui.Parent = parent
    return gui
end

local function Round(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function Outline(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 70)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Gradient(parent, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function MultiGradient(parent, colors, rotation)
    local g = Instance.new("UIGradient")
    local keypoints = {}
    for i, c in ipairs(colors) do
        table.insert(keypoints, ColorSequenceKeypoint.new((i-1)/(#colors-1), c))
    end
    g.Color = ColorSequence.new(keypoints)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function Tween(obj, t, props, style, dir)
    local anim = TweenService:Create(
        obj,
        TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props
    )
    anim:Play()
    return anim
end

local function Spring(obj, t, props)
    local info = TweenInfo.new(t or 0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0.5)
    local anim = TweenService:Create(obj, info, props)
    anim:Play()
    return anim
end

local function Shade(color, amount)
    if typeof(color) ~= "Color3" then return Color3.fromRGB(20, 20, 24) end
    amount = amount or 0.07
    local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    if lum > 0.5 then
        return Color3.new(
            math.max(0, color.R - amount),
            math.max(0, color.G - amount),
            math.max(0, color.B - amount)
        )
    end
    return Color3.new(
        math.min(1, color.R + amount),
        math.min(1, color.G + amount),
        math.min(1, color.B + amount)
    )
end

local function Blend(c1, c2, t)
    t = math.clamp(t or 0.5, 0, 1)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function PressFeedback(btn, scale)
    scale = scale or 0.96
    local origSize = btn.Size
    btn.MouseButton1Down:Connect(function()
        Tween(btn, 0.1, { Size = UDim2.new(origSize.X.Scale * scale, origSize.X.Offset * scale, origSize.Y.Scale * scale, origSize.Y.Offset * scale) }, Enum.EasingStyle.Quad)
    end)
    btn.MouseButton1Up:Connect(function()
        Spring(btn, 0.4, { Size = origSize })
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, 0.15, { Size = origSize }, Enum.EasingStyle.Quad)
    end)
end

local function Ripple(button, color, zIndexOffset)
    button.ClipsDescendants = true
    button.MouseButton1Click:Connect(function()
        local mx = Mouse and Mouse.X or 0
        local my = Mouse and Mouse.Y or 0
        local circle = Instance.new("Frame")
        circle.BackgroundColor3 = color or Color3.new(1, 1, 1)
        circle.BackgroundTransparency = 0.6
        circle.BorderSizePixel = 0
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.ZIndex = (button.ZIndex or 1) + (zIndexOffset or 5)
        circle.Size = UDim2.fromOffset(0, 0)
        circle.Position = UDim2.fromOffset(
            mx - button.AbsolutePosition.X,
            my - button.AbsolutePosition.Y
        )
        circle.Parent = button
        Round(200, circle)
        local target = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        Tween(circle, 0.6, {
            Size = UDim2.fromOffset(target, target),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Quart)
        task.delay(0.6, function()
            if circle.Parent then circle:Destroy() end
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  ICONOS
-- ═══════════════════════════════════════════════════════════════
SZK.IconSources = {
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS/refs/heads/main/WINDUI/ICON1",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS1/refs/heads/main/ICONS/WINDUI2",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/ICONS2/refs/heads/main/SZK/WINDUI/ICONS3",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS3/refs/heads/main/SZK/ICONS4",
}

function SZK:LoadIcons()
    for _, url in ipairs(SZK.IconSources) do
        local ok, data = pcall(function()
            return loadstring(game:HttpGet(url))()
        end)
        if ok and type(data) == "table" then
            for name, id in pairs(data) do SZK.Icons[name] = id end
        end
    end
    return SZK.Icons
end
pcall(SZK.LoadIcons, SZK)

local function GetUrlExtension(url, allowed, fallback)
    local clean = string.match(url, "^[^%?#]+") or url
    local ext = string.match(clean, "%.([%a%d]+)$")
    if ext then
        ext = string.lower(ext)
        for _, a in ipairs(allowed) do
            if a == ext then return ext end
        end
    end
    return fallback
end

local function NormalizeImageSource(input)
    if input == nil then return "" end
    if type(input) == "number" then return "rbxassetid://" .. tostring(input) end
    if type(input) ~= "string" or input == "" then return "" end
    if string.match(input, "^rbxassetid://") or string.match(input, "^rbxthumb://") or string.match(input, "^rbxasset://") then
        return input
    end
    if string.match(input, "^%d+$") then return "rbxassetid://" .. input end
    if string.match(input, "^https?://") then
        if writefile and isfile and getcustomasset and makefolder and isfolder then
            local ext = GetUrlExtension(input, {"png","jpg","jpeg","gif","webp","bmp"}, "png")
            local safeName = string.gsub(input, "[^%w]", "_")
            local cacheFolder = "SZK_Cache"
            local cachePath = cacheFolder .. "/" .. safeName .. "." .. ext
            local ok = pcall(function()
                if not isfolder(cacheFolder) then makefolder(cacheFolder) end
                if not isfile(cachePath) then writefile(cachePath, game:HttpGet(input)) end
            end)
            if ok then
                local assetOk, assetId = pcall(function()
                    return getcustomasset(cachePath)
                end)
                if assetOk and assetId then return assetId end
            end
        end
        return ""
    end
    return input
end

local function ResolveIcon(key)
    if not key then return "", false end
    if type(key) == "number" then return "rbxassetid://" .. tostring(key), true end
    if type(key) == "string" then
        if string.match(key, "^rbxassetid://") or string.match(key, "^%d+$") then
            return NormalizeImageSource(key), true
        end
        if string.match(key, "^https?://") then
            return NormalizeImageSource(key), true
        end
        if SZK.Icons[key] then
            return NormalizeImageSource(SZK.Icons[key]), true
        end
        return key, false
    end
    return "", false
end

local function Img(parent, source, size, color, transparency, z)
    local resolved, isCustom = ResolveIcon(source)
    if resolved == "" then return nil end
    local image = Instance.new("ImageLabel")
    image.Size = size or UDim2.fromOffset(16, 16)
    image.BackgroundTransparency = 1
    image.Image = resolved
    image.ScaleType = isCustom and Enum.ScaleType.Crop or Enum.ScaleType.Stretch
    image.ImageColor3 = isCustom and Color3.new(1, 1, 1) or (color or Color3.new(1, 1, 1))
    image.ImageTransparency = transparency or 0
    image.ZIndex = z or 8
    image.Parent = parent
    if isCustom then image:SetAttribute("SZKCustomIcon", true) end
    return image
end

local function TintIfAllowed(img, color)
    if img and not img:GetAttribute("SZKCustomIcon") then
        img.ImageColor3 = color
    end
end

-- ═══════════════════════════════════════════════════════════════
--  TEMAS
-- ═══════════════════════════════════════════════════════════════

local function BuildTheme(name, cfg)
    return {
        Name = name,
        Accent = Color3.fromHex(cfg.accent or "#FFFFFF"),
        Accent2 = Color3.fromHex(cfg.accent2 or cfg.accent or "#CCCCCC"),
        Outline = Color3.fromHex(cfg.outline or "#3C3C46"),
        Text = Color3.fromHex(cfg.text or "#EBEBEB"),
        TextDim = Color3.fromHex(cfg.textDim or "#B0B0B8"),
        Placeholder = Color3.fromHex(cfg.placeholder or "#7A7A85"),
        Icon = Color3.fromHex(cfg.icon or cfg.accent or "#FFFFFF"),
        Toggle = Color3.fromHex(cfg.toggle or cfg.accent or "#FFFFFF"),
        Slider = Color3.fromHex(cfg.slider or cfg.accent or "#FFFFFF"),
        ElementBackground = Color3.fromHex(cfg.elemBg or "#16161C"),
        ElementBackground2 = Color3.fromHex(cfg.elemBg2 or "#1A1A22"),
        Background = Color3.fromHex(cfg.bg or "#0A0A0C"),
        Background2 = Color3.fromHex(cfg.bg2 or "#101014"),
        Background3 = Color3.fromHex(cfg.bg3 or "#15151A"),
        Success = Color3.fromHex(cfg.success or "#46DC8C"),
        Danger = Color3.fromHex(cfg.danger or "#FF5050"),
        Warning = Color3.fromHex(cfg.warning or "#FFB020"),
        Info = Color3.fromHex(cfg.info or "#5A96FF"),
    }
end

SZK.Themes.SZK = BuildTheme("SZK", {
    accent = "#FFFFFF", accent2 = "#141414",
    outline = "#3C3C46", text = "#FAFAFF",
    placeholder = "#9696A0", icon = "#FFFFFF",
    toggle = "#FFFFFF", slider = "#FFFFFF",
    elemBg = "#16161C", elemBg2 = "#1A1A22",
    bg = "#08080A", bg2 = "#101014", bg3 = "#15151A",
})

SZK.Themes["AMBIENT"]        = BuildTheme("AMBIENT",        {accent = "#E8B4B8", accent2 = "#F4C2C6", outline = "#F4C2C6", toggle = "#E8B4B8", slider = "#F4C2C6", text = "#F8E8E9", placeholder = "#D8A8A9", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F4C2C6"})
SZK.Themes["SOFT MIST"]      = BuildTheme("SOFT MIST",      {accent = "#D4E0E6", accent2 = "#E8EEF0", outline = "#E8EEF0", toggle = "#D4E0E6", slider = "#E8EEF0", text = "#F5F8F9", placeholder = "#B8C0C4", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#E8EEF0"})
SZK.Themes["WARM BLUSH"]     = BuildTheme("WARM BLUSH",     {accent = "#F5D0C5", accent2 = "#F8E0D6", outline = "#F8E0D6", toggle = "#F5D0C5", slider = "#F8E0D6", text = "#FFF5F2", placeholder = "#E8B4B0", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F8E0D6"})
SZK.Themes["SUNSET HUE"]     = BuildTheme("SUNSET HUE",     {accent = "#E8A87C", accent2 = "#F4C19A", outline = "#F4C19A", toggle = "#E8A87C", slider = "#F4C19A", text = "#FFF9E6", placeholder = "#D4A88A", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F4C19A"})
SZK.Themes["SOFT GOLDEN"]    = BuildTheme("SOFT GOLDEN",    {accent = "#E8D5B7", accent2 = "#F4E0C8", outline = "#F4E0C8", toggle = "#E8D5B7", slider = "#F4E0C8", text = "#FFF8E1", placeholder = "#D8C0A0", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F4E0C8"})
SZK.Themes["PEACH BLOSSOM"]  = BuildTheme("PEACH BLOSSOM",  {accent = "#F4C1A8", accent2 = "#F8D9C4", outline = "#F8D9C4", toggle = "#F4C1A8", slider = "#F8D9C4", text = "#FFF8F0", placeholder = "#E8B4A8", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F8D9C4"})
SZK.Themes["LAVENDER MIST"]  = BuildTheme("LAVENDER MIST",  {accent = "#E8D0E8", accent2 = "#F4E0F0", outline = "#F4E0F0", toggle = "#E8D0E8", slider = "#F4E0F0", text = "#FAF5FF", placeholder = "#D8B8D0", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F4E0F0"})
SZK.Themes["SEAFOAM SOFT"]   = BuildTheme("SEAFOAM SOFT",   {accent = "#C8E8E0", accent2 = "#D8F0E8", outline = "#D8F0E8", toggle = "#C8E8E0", slider = "#D8F0E8", text = "#F0F8F5", placeholder = "#A8C8B8", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#D8F0E8"})
SZK.Themes["SOFT LEMON"]     = BuildTheme("SOFT LEMON",     {accent = "#F4E8B8", accent2 = "#F8F4C8", outline = "#F8F4C8", toggle = "#F4E8B8", slider = "#F8F4C8", text = "#FFF8E1", placeholder = "#D8D0A8", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F8F4C8"})
SZK.Themes["SOFT ROSE"]      = BuildTheme("SOFT ROSE",      {accent = "#F4B8C8", accent2 = "#F8D0D8", outline = "#F8D0D8", toggle = "#F4B8C8", slider = "#F8D0D8", text = "#FFF0F5", placeholder = "#D8A8B8", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F8D0D8"})
SZK.Themes["PEACH"]          = BuildTheme("PEACH",          {accent = "#FFDAB9", accent2 = "#FFCBA4", outline = "#FFCBA4", toggle = "#FFDAB9", slider = "#FFCBA4", text = "#FFF5EE", placeholder = "#FFB6C1", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#FFCBA4"})
SZK.Themes["VENOM"]          = BuildTheme("VENOM",          {accent = "#32CD32", accent2 = "#228B22", outline = "#32CD32", toggle = "#32CD32", slider = "#32CD32", text = "#E8F5E9", placeholder = "#8BC34A", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#32CD32"})
SZK.Themes["CYBER"]          = BuildTheme("CYBER",          {accent = "#00D4FF", accent2 = "#4ECFFF", outline = "#4ECFFF", toggle = "#00D4FF", slider = "#4ECFFF", text = "#E0F7FA", placeholder = "#81D4FA", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#4ECFFF"})
SZK.Themes["PURPLE"]         = BuildTheme("PURPLE",         {accent = "#9B59B6", accent2 = "#DDA0DD", outline = "#DDA0DD", toggle = "#9B59B6", slider = "#DDA0DD", text = "#F5F0FF", placeholder = "#BCA3D3", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#DDA0DD"})
SZK.Themes["GOLD"]           = BuildTheme("GOLD",           {accent = "#FFD700", accent2 = "#FFF44F", outline = "#FFF44F", toggle = "#FFD700", slider = "#FFF44F", text = "#FFF8E1", placeholder = "#DAA520", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#FFF44F"})
SZK.Themes["NEON"]           = BuildTheme("NEON",           {accent = "#FF00FF", accent2 = "#FF69B4", outline = "#FF69B4", toggle = "#FF00FF", slider = "#FF69B4", text = "#F0F0FF", placeholder = "#BA55D3", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#FF69B4"})
SZK.Themes["OCEAN"]          = BuildTheme("OCEAN",          {accent = "#1E90FF", accent2 = "#87CEEB", outline = "#87CEEB", toggle = "#1E90FF", slider = "#87CEEB", text = "#E6F3FF", placeholder = "#4682B4", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#87CEEB"})
SZK.Themes["ROSE"]           = BuildTheme("ROSE",           {accent = "#E91E63", accent2 = "#F48FB1", outline = "#F48FB1", toggle = "#E91E63", slider = "#F48FB1", text = "#FCE4EC", placeholder = "#F06292", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#F48FB1"})
SZK.Themes["FOREST"]         = BuildTheme("FOREST",         {accent = "#2E8B57", accent2 = "#3CB371", outline = "#2E8B57", toggle = "#228B22", slider = "#2E8B57", text = "#F0FFF0", placeholder = "#3CB371", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#2E8B57"})
SZK.Themes["EMERALD"]        = BuildTheme("EMERALD",        {accent = "#50C878", accent2 = "#7FFF00", outline = "#7FFF00", toggle = "#50C878", slider = "#7FFF00", text = "#F0FFF0", placeholder = "#32CD32", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#7FFF00"})
SZK.Themes["CORAL"]          = BuildTheme("CORAL",          {accent = "#FF7F50", accent2 = "#FF6347", outline = "#FF6347", toggle = "#FF7F50", slider = "#FF6347", text = "#FFF0F0", placeholder = "#FA8072", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#FF6347"})
SZK.Themes["LAVENDER"]       = BuildTheme("LAVENDER",       {accent = "#DDA0DD", accent2 = "#E6E6FA", outline = "#DDA0DD", toggle = "#E6E6FA", slider = "#DDA0DD", text = "#F8F1FF", placeholder = "#BA55D3", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#DDA0DD"})
SZK.Themes["COPPER"]         = BuildTheme("COPPER",         {accent = "#B87333", accent2 = "#CD853F", outline = "#CD853F", toggle = "#B87333", slider = "#CD853F", text = "#FFF8DC", placeholder = "#DAA520", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#CD853F"})
SZK.Themes["SAPPHIRE"]       = BuildTheme("SAPPHIRE",       {accent = "#0F52BA", accent2 = "#4169E1", outline = "#4169E1", toggle = "#0F52BA", slider = "#4169E1", text = "#F0F8FF", placeholder = "#1E90FF", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#4169E1"})
SZK.Themes["LIME"]           = BuildTheme("LIME",           {accent = "#32CD32", accent2 = "#ADFF2F", outline = "#ADFF2F", toggle = "#32CD32", slider = "#ADFF2F", text = "#F0FFF0", placeholder = "#7CFC00", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#ADFF2F"})
SZK.Themes["INDIGO"]         = BuildTheme("INDIGO",         {accent = "#4B0082", accent2 = "#6A0DAD", outline = "#6A0DAD", toggle = "#4B0082", slider = "#6A0DAD", text = "#F0F0FF", placeholder = "#9370DB", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#6A0DAD"})
SZK.Themes["AMBER"]          = BuildTheme("AMBER",          {accent = "#FFBF00", accent2 = "#FFC000", outline = "#FFC000", toggle = "#FFBF00", slider = "#FFC000", text = "#FFF8E1", placeholder = "#FFA500", elemBg = "#0A0A0A", elemBg2 = "#101010", bg = "#000000", bg2 = "#050505", bg3 = "#080808", icon = "#FFC000"})
SZK.Themes["DARK"]           = BuildTheme("DARK",           {accent = "#3A3A42", accent2 = "#555555", outline = "#555555", toggle = "#3A3A42", slider = "#555555", text = "#E0E0E0", placeholder = "#6A6A72", elemBg = "#141418", elemBg2 = "#18181E", bg = "#08080A", bg2 = "#0C0C10", bg3 = "#101014", icon = "#555555"})
SZK.Themes["SLATE"]          = BuildTheme("SLATE",          {accent = "#4A4A4A", accent2 = "#696969", outline = "#4A4A4A", toggle = "#4A4A4A", slider = "#696969", text = "#F5F5F5", placeholder = "#696969", elemBg = "#1A1A1A", elemBg2 = "#1E1E1E", bg = "#0A0A0A", bg2 = "#101010", bg3 = "#151515", icon = "#4A4A4A"})
SZK.Themes["MIDNIGHT"]       = BuildTheme("MIDNIGHT",       {accent = "#2F2F2F", accent2 = "#4A4A4A", outline = "#2F2F2F", toggle = "#2F2F2F", slider = "#4A4A4A", text = "#E8E8E8", placeholder = "#5A5A5A", elemBg = "#141414", elemBg2 = "#181818", bg = "#0A0A0A", bg2 = "#0E0E0E", bg3 = "#121212", icon = "#2F2F2F"})
SZK.Themes["BLOOD"]          = BuildTheme("BLOOD",          {accent = "#A52A2A", accent2 = "#CD5C5C", outline = "#A52A2A", toggle = "#8B0000", slider = "#A52A2A", text = "#FFEBEE", placeholder = "#CD5C5C", elemBg = "#1A0A0A", elemBg2 = "#200C0C", bg = "#080000", bg2 = "#0E0505", bg3 = "#140808", icon = "#A52A2A", danger = "#FF2020"})
SZK.Themes["COCOA"]          = BuildTheme("COCOA",          {accent = "#A0522D", accent2 = "#CD853F", outline = "#A0522D", toggle = "#8B4513", slider = "#A0522D", text = "#FAF0E6", placeholder = "#CD853F", elemBg = "#1A120C", elemBg2 = "#20160E", bg = "#0A0604", bg2 = "#100A06", bg3 = "#160E08", icon = "#A0522D"})
SZK.Themes["LIGHT"]          = BuildTheme("LIGHT",          {accent = "#2A2A2A", accent2 = "#505050", outline = "#E0E0E0", toggle = "#2A2A2A", slider = "#2A2A2A", text = "#1A1A1A", textDim = "#404040", placeholder = "#808080", elemBg = "#F5F5F5", elemBg2 = "#FFFFFF", bg = "#FAFAFA", bg2 = "#F0F0F0", bg3 = "#E8E8E8", icon = "#2A2A2A"})

SZK.ThemeOrder = {
    "SZK",
    "AMBIENT", "SOFT MIST", "WARM BLUSH", "SUNSET HUE", "SOFT GOLDEN",
    "PEACH BLOSSOM", "LAVENDER MIST", "SEAFOAM SOFT", "SOFT LEMON", "SOFT ROSE", "PEACH",
    "VENOM", "CYBER", "PURPLE", "GOLD", "NEON", "OCEAN", "ROSE", "FOREST",
    "EMERALD", "CORAL", "LAVENDER", "COPPER", "SAPPHIRE", "LIME", "INDIGO", "AMBER",
    "DARK", "SLATE", "MIDNIGHT", "BLOOD", "COCOA", "LIGHT",
}

-- ═══════════════════════════════════════════════════════════════
--  THEMED ELEMENTS REGISTRY
-- ═══════════════════════════════════════════════════════════════
local ThemedElements = {
    Strokes = {}, Fills = {}, Labels = {}, Buttons = {},
    Gradients = {}, Scans = {}, Knobs = {}, Backgrounds = {},
}

local function register(kind, obj)
    if ThemedElements[kind] then
        table.insert(ThemedElements[kind], obj)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  MAIN GUI + NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════

local MainGui = SafeParent(Instance.new("ScreenGui"))
MainGui.Name = "SZKLibrary"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.DisplayOrder = 999
MainGui.IgnoreGuiInset = true

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Size = UDim2.new(0, 360, 1, -20)
NotificationHolder.Position = UDim2.new(1, -370, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 9999
NotificationHolder.Parent = MainGui

local NotifList = Instance.new("UIListLayout")
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding = UDim.new(0, 10)
NotifList.Parent = NotificationHolder

-- ═══════════════════════════════════════════════════════════════
--  NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════
function SZK:Notify(config)
    config = config or {}
    local title    = config.Title or "Notification"
    local content  = config.Content or config.Text or ""
    local duration = config.Duration or 4
    local ntype    = config.Type or "Info"
    local buttons  = config.Buttons
    local iconKey  = config.Icon
    local theme    = SZK.CurrentTheme or SZK.Themes.SZK

    local typeColors = {
        Success = theme.Success,
        Error   = theme.Danger,
        Warning = theme.Warning,
        Info    = theme.Info,
    }
    local accent = typeColors[ntype] or theme.Info

    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(1, 0, 0, 0)
    slot.BackgroundTransparency = 1
    slot.ClipsDescendants = false
    slot.Parent = NotificationHolder

    local frame = Instance.new("Frame")
    frame.Position = UDim2.new(1, 80, 0, 0)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = theme.ElementBackground
    frame.BackgroundTransparency = 0.02
    frame.ClipsDescendants = true
    frame.Parent = slot
    Round(16, frame)

    local shadow = Instance.new("Frame")
    shadow.BackgroundColor3 = Color3.new(0, 0, 0)
    shadow.BackgroundTransparency = 0.65
    shadow.BorderSizePixel = 0
    shadow.Size = UDim2.new(1, 12, 1, 12)
    shadow.Position = UDim2.new(0, -6, 0, -6)
    shadow.ZIndex = -1
    shadow.Parent = frame
    Round(20, shadow)

    local stroke = Outline(frame, accent, 1.5, 0.15)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -24)
    bar.Position = UDim2.new(0, 0, 0, 12)
    bar.BackgroundColor3 = accent
    bar.ZIndex = 2
    bar.BorderSizePixel = 0
    bar.Parent = frame
    Round(2, bar)
    Gradient(bar, accent, Shade(accent, 0.2), 90)

    local iconImg
    local resolvedCheck = iconKey and ResolveIcon(iconKey) or ""
    if resolvedCheck ~= "" then
        local badge = Instance.new("Frame")
        badge.Size = UDim2.fromOffset(44, 44)
        badge.Position = UDim2.new(0, 16, 0, 16)
        badge.BackgroundColor3 = accent
        badge.BackgroundTransparency = 0.85
        badge.ZIndex = 3
        badge.Parent = frame
        Round(12, badge)
        Outline(badge, accent, 1, 0.5)
        Gradient(badge, Blend(accent, Color3.new(0,0,0), 0.3), Blend(accent, Color3.new(1,1,1), 0.3), 135)

        iconImg = Img(badge, iconKey, UDim2.fromOffset(24, 24), accent, 0, 4)
        if iconImg then
            iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
            iconImg.Position = UDim2.fromScale(0.5, 0.5)
        end
    end

    local textLeft = iconImg and 72 or 24

    local tLbl = Instance.new("TextLabel")
    tLbl.Text = title
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 18
    tLbl.TextColor3 = theme.Text
    tLbl.Position = UDim2.new(0, textLeft, 0, 18)
    tLbl.Size = UDim2.new(1, -(textLeft + 20), 0, 24)
    tLbl.BackgroundTransparency = 1
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = frame

    local cLbl = Instance.new("TextLabel")
    cLbl.Text = content
    cLbl.Font = Enum.Font.Gotham
    cLbl.TextSize = 18
    cLbl.TextColor3 = theme.Placeholder
    cLbl.Position = UDim2.new(0, textLeft, 0, 46)
    cLbl.Size = UDim2.new(1, -(textLeft + 20), 0, 44)
    cLbl.BackgroundTransparency = 1
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.TextYAlignment = Enum.TextYAlignment.Top
    cLbl.TextWrapped = true
    cLbl.Parent = frame

    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, -4, 0, 3)
    progressBg.Position = UDim2.new(0, 2, 1, -4)
    progressBg.BackgroundColor3 = accent
    progressBg.BackgroundTransparency = 0.85
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 4
    progressBg.Parent = frame
    Round(2, progressBg)

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = accent
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 5
    progressFill.Parent = progressBg
    Round(2, progressFill)

    if buttons and #buttons > 0 then
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -40, 0, 34)
        row.Position = UDim2.new(0, textLeft, 0, 96)
        row.BackgroundTransparency = 1
        row.Parent = frame
        local rl = Instance.new("UIListLayout")
        rl.FillDirection = Enum.FillDirection.Horizontal
        rl.Padding = UDim.new(0, 8)
        rl.Parent = row

        for _, b in ipairs(buttons) do
            local nb = Instance.new("TextButton")
            nb.Size = UDim2.fromOffset(0, 32)
            nb.AutomaticSize = Enum.AutomaticSize.X
            nb.BackgroundColor3 = b.Primary and accent or Shade(theme.ElementBackground, 0.1)
            nb.Text = "  " .. (b.Text or "Ok") .. "  "
            nb.Font = Enum.Font.GothamBold
            nb.TextSize = 18
            nb.TextColor3 = b.Primary and Color3.new(1,1,1) or theme.Text
            nb.AutoButtonColor = false
            nb.Parent = row
            Round(10, nb)
            Outline(nb, b.Primary and Blend(accent, Color3.new(1,1,1), 0.3) or theme.Outline, 1, 0.6)

            nb.MouseEnter:Connect(function()
                Tween(nb, 0.15, { BackgroundColor3 = b.Primary and Blend(accent, Color3.new(1,1,1), 0.15) or Shade(theme.ElementBackground, 0.18) })
            end)
            nb.MouseLeave:Connect(function()
                Tween(nb, 0.15, { BackgroundColor3 = b.Primary and accent or Shade(theme.ElementBackground, 0.1) })
            end)
            nb.MouseButton1Click:Connect(function()
                if b.Callback then pcall(b.Callback) end
                if b.CloseOnClick ~= false and slot.Parent then
                    Tween(frame, 0.25, { Position = UDim2.new(1, 80, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
                    local out = Tween(slot, 0.25, { Size = UDim2.new(1, 0, 0, 0) })
                    out.Completed:Connect(function() slot:Destroy() end)
                end
            end)
        end
    end

    local cardHeight = (buttons and #buttons > 0) and 140 or 106
    Tween(slot, 0.4, { Size = UDim2.new(1, 0, 0, cardHeight) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(frame, 0.45, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    if not (buttons and #buttons > 0) then
        Tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
        task.delay(duration, function()
            if not slot.Parent then return end
            Tween(frame, 0.3, { Position = UDim2.new(1, 80, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            local out = Tween(slot, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
            out.Completed:Connect(function() slot:Destroy() end)
        end)
    end
end

function SZK:Success(t, c, d)
    return SZK:Notify({Title = t or "Success", Content = c or "", Type = "Success", Duration = d or 3.5, Icon = "badge-check"})
end
function SZK:Error(t, c, d)
    return SZK:Notify({Title = t or "Error", Content = c or "", Type = "Error", Duration = d or 4, Icon = "alert-circle"})
end
function SZK:Warn(t, c, d)
    return SZK:Notify({Title = t or "Warning", Content = c or "", Type = "Warning", Duration = d or 3.5, Icon = "alert-triangle"})
end
function SZK:Info(t, c, d)
    return SZK:Notify({Title = t or "Info", Content = c or "", Type = "Info", Duration = d or 3.5, Icon = "info"})
end

-- ═══════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ═══════════════════════════════════════════════════════════════
function SZK:CreateWindow(config)
    config = config or {}
    local title        = config.Title or "FLUID"
    local description  = config.Description or "AUTHOR SZK"
    local size         = config.Size or Vector2.new(520, 460)
    if typeof(size) == "UDim2" then
        size = Vector2.new(size.X.Offset, size.Y.Offset)
    end
    local toggleKey    = config.ToggleKey or Enum.KeyCode.RightShift
    local themeName    = config.Theme or "SZK"
    local logoKey      = config.Logo or config.Icon
    local bgImage      = config.BackgroundImage
    local bgTrans      = math.clamp(config.BackgroundImageTransparency or 0.4, 0, 1)
    local showThemeSel = config.ThemeSelector ~= false
    local openBtnIcon  = config.OpenButtonIcon
    local openBtnText  = config.OpenButtonText or "RysHub"
    local showFooter   = config.ShowFooter ~= false

    local MIN_SIZE = Vector2.new(400, 320)
    local MAX_SIZE = Vector2.new(1400, 1000)
    if config.MinSize then MIN_SIZE = config.MinSize end
    if config.MaxSize then MAX_SIZE = config.MaxSize end

    local Theme = SZK.Themes[themeName] or SZK.Themes.SZK
    SZK.CurrentTheme = Theme

    local resolvedBg = bgImage and NormalizeImageSource(bgImage) or ""
    local hasBg = resolvedBg ~= ""

    local Registered = {}
    local OpenPopups = {}
    local Connections = {}

    local function Track(conn)
        table.insert(Connections, conn)
        return conn
    end

    local function CloseAllPopups(except)
        for _, p in ipairs(OpenPopups) do
            if p.Frame.Visible and p.Trigger ~= except then
                p.Frame.Visible = false
            end
        end
    end

    local function RegisterPopup(frame, trigger)
        table.insert(OpenPopups, { Frame = frame, Trigger = trigger })
    end

    local WindowGui = SafeParent(Instance.new("ScreenGui"))
    WindowGui.Name = "SZKWindow"
    WindowGui.ResetOnSpawn = false
    WindowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WindowGui.DisplayOrder = MainGui.DisplayOrder
    WindowGui.IgnoreGuiInset = true

    -- ═══ MAIN FRAME ═══
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.Parent = WindowGui
    Round(16, MainFrame)

    local SizeConstraint = Instance.new("UISizeConstraint")
    SizeConstraint.MinSize = MIN_SIZE
    SizeConstraint.MaxSize = MAX_SIZE
    SizeConstraint.Parent = MainFrame

    local WindowScale = Instance.new("UIScale")
    WindowScale.Parent = MainFrame

    local function GetViewport()
        local cam = workspace.CurrentCamera
        return cam and cam.ViewportSize or Vector2.new(1280, 720)
    end

    local function RecalculateScale()
        local viewport = GetViewport()
        local marginX = math.max(viewport.X * 0.9, 1)
        local marginY = math.max(viewport.Y * 0.85, 1)
        local scaleX = marginX / size.X
        local scaleY = marginY / size.Y
        local target = math.clamp(math.min(scaleX, scaleY, 1), 0.45, 1)
        WindowScale.Scale = target
    end
    RecalculateScale()
    Track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(RecalculateScale))

    -- ═══ SOMBRA MULTICAPA ═══
    for i = 1, 3 do
        local s = Instance.new("Frame")
        s.Name = "Shadow_" .. i
        s.BackgroundColor3 = Color3.new(0, 0, 0)
        s.BackgroundTransparency = 0.95 - (i * 0.01)
        s.BorderSizePixel = 0
        s.Size = UDim2.new(1, i * 8, 1, i * 8)
        s.Position = UDim2.new(0, -i * 4, 0, -i * 4)
        s.ZIndex = -i
        s.Parent = MainFrame
        Round(16 + i * 4, s)
    end

    -- ═══ GLOW EXTERIOR ═══
    local OuterGlow = Instance.new("Frame")
    OuterGlow.Size = UDim2.new(1, 4, 1, 4)
    OuterGlow.Position = UDim2.new(0, -2, 0, -2)
    OuterGlow.BackgroundColor3 = Theme.Accent
    OuterGlow.BackgroundTransparency = 0.9
    OuterGlow.BorderSizePixel = 0
    OuterGlow.ZIndex = -4
    OuterGlow.Parent = MainFrame
    Round(18, OuterGlow)

    -- ═══ BORDE PRINCIPAL ═══
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Theme.Accent
    MainStroke.Thickness = 1.5
    MainStroke.Transparency = 0.25
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = MainFrame

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Accent),
        ColorSequenceKeypoint.new(0.5, Blend(Theme.Accent, Color3.new(1,1,1), 0.4)),
        ColorSequenceKeypoint.new(1, Theme.Accent),
    })
    strokeGradient.Rotation = 135
    strokeGradient.Parent = MainStroke

    -- ═══ BACKGROUND ═══
    local BgImage = Instance.new("ImageLabel")
    BgImage.Size = UDim2.fromScale(1, 1)
    BgImage.BackgroundTransparency = 1
    BgImage.Image = resolvedBg
    BgImage.ImageTransparency = hasBg and bgTrans or 1
    BgImage.ScaleType = Enum.ScaleType.Crop
    BgImage.ZIndex = 0
    BgImage.Parent = MainFrame

    local Overlay = Instance.new("Frame")
    Overlay.Size = UDim2.fromScale(1, 1)
    Overlay.BackgroundColor3 = Theme.Background
    Overlay.BackgroundTransparency = hasBg and 0.35 or 0.02
    Overlay.BorderSizePixel = 0
    Overlay.ZIndex = 1
    Overlay.Parent = MainFrame
    MultiGradient(Overlay, {
        Shade(Theme.Background, 0.08),
        Theme.Background,
        Shade(Theme.Background, -0.02),
    }, 135)

    -- ═══════════════════════════════════════════════════════════
    --  SCAN EFFECTS — 12 líneas cruzando, más visibles y rápidas
    -- ═══════════════════════════════════════════════════════════
    local scansEnabled = true
    local activeScans = {}

    local function CreateScan(orientation, startPos, endPos, length, travelTime, thickness, delayOffset, color)
        color = color or Theme.Accent

        local scan = Instance.new("Frame")
        scan.BorderSizePixel = 0
        scan.BackgroundColor3 = color
        scan.ZIndex = 10
        scan.Parent = MainFrame

        if orientation == "h" then
            scan.Size = UDim2.new(0, length, 0, thickness)
        else
            scan.Size = UDim2.new(0, thickness, 0, length)
        end
        scan.Position = startPos

        local grad = Instance.new("UIGradient")
        grad.Rotation = orientation == "h" and 0 or 90
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, color),
        })
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        grad.Parent = scan

        -- Glow
        local glow = Instance.new("Frame")
        glow.BorderSizePixel = 0
        glow.BackgroundColor3 = color
        glow.BackgroundTransparency = 0.5
        glow.ZIndex = 9
        glow.Parent = MainFrame

        if orientation == "h" then
            glow.Size = UDim2.new(0, length, 0, thickness * 4)
            glow.Position = startPos
        else
            glow.Size = UDim2.new(0, thickness * 4, 0, length)
            glow.Position = startPos
        end

        local glowGrad = Instance.new("UIGradient")
        glowGrad.Rotation = orientation == "h" and 0 or 90
        glowGrad.Color = ColorSequence.new(color, color)
        glowGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        glowGrad.Parent = glow

        register("Fills", scan)
        register("Fills", glow)
        table.insert(ThemedElements.Scans, {
            scan = scan, grad = grad,
            glow = glow, glowGrad = glowGrad,
        })

        local scanObj = { scan = scan, glow = glow, enabled = true }
        table.insert(activeScans, scanObj)

        task.spawn(function()
            if delayOffset and delayOffset > 0 then task.wait(delayOffset) end
            while scan and scan.Parent and scansEnabled and scanObj.enabled do
                local t1 = TweenService:Create(scan, TweenInfo.new(travelTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = endPos })
                local g1 = TweenService:Create(glow, TweenInfo.new(travelTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = endPos })
                t1:Play(); g1:Play()
                t1.Completed:Wait()
                if not scan or not scan.Parent or not scansEnabled then break end

                local t2 = TweenService:Create(scan, TweenInfo.new(travelTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = startPos })
                local g2 = TweenService:Create(glow, TweenInfo.new(travelTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = startPos })
                t2:Play(); g2:Play()
                t2.Completed:Wait()
            end
        end)

        return scan
    end

    -- ═══ HORIZONTALES ═══
    CreateScan("h", UDim2.new(0, 0, 0, 0),         UDim2.new(1, -180, 0, 0),       180, 1.4, 3, 0)
    CreateScan("h", UDim2.new(1, -180, 0, 0),      UDim2.new(0, 0, 0, 0),          180, 1.5, 3, 0.4)
    CreateScan("h", UDim2.new(0, 0, 1, -3),        UDim2.new(1, -180, 1, -3),      180, 1.45, 3, 0.8)
    CreateScan("h", UDim2.new(1, -180, 1, -3),     UDim2.new(0, 0, 1, -3),         180, 1.55, 3, 1.2)

    -- Horizontales al medio
    CreateScan("h", UDim2.new(0, 0, 0.5, -1.5),    UDim2.new(1, -220, 0.5, -1.5),  220, 2.0, 2, 0.6)
    CreateScan("h", UDim2.new(1, -220, 0.5, -1.5), UDim2.new(0, 0, 0.5, -1.5),     220, 2.2, 2, 1.4)

    -- ═══ VERTICALES ═══
    CreateScan("v", UDim2.new(0, 0, 0, 0),         UDim2.new(0, 0, 1, -140),       140, 1.4, 3, 0.2)
    CreateScan("v", UDim2.new(0, 0, 1, -140),      UDim2.new(0, 0, 0, 0),          140, 1.5, 3, 0.7)
    CreateScan("v", UDim2.new(1, -3, 0, 0),        UDim2.new(1, -3, 1, -140),      140, 1.45, 3, 1.05)
    CreateScan("v", UDim2.new(1, -3, 1, -140),     UDim2.new(1, -3, 0, 0),         140, 1.55, 3, 0.35)

    -- Verticales al medio
    CreateScan("v", UDim2.new(0.5, -1.5, 0, 0),    UDim2.new(0.5, -1.5, 1, -180),  180, 2.1, 2, 0.9)
    CreateScan("v", UDim2.new(0.5, -1.5, 1, -180), UDim2.new(0.5, -1.5, 0, 0),     180, 2.3, 2, 1.6)

    -- ═══ HEADER ═══
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, 0, 0, 58)
    HeaderBar.BackgroundColor3 = Theme.Background2
    HeaderBar.BackgroundTransparency = 0.1
    HeaderBar.BorderSizePixel = 0
    HeaderBar.ZIndex = 5
    HeaderBar.Parent = MainFrame
    Round(16, HeaderBar)

    MultiGradient(HeaderBar, {
        Shade(Theme.Background2, 0.1),
        Theme.Background2,
        Shade(Theme.Background2, -0.05),
    }, 90)

    local headerDivider = Instance.new("Frame")
    headerDivider.Size = UDim2.new(1, -32, 0, 1)
    headerDivider.Position = UDim2.new(0, 16, 1, -1)
    headerDivider.BackgroundColor3 = Theme.Outline
    headerDivider.BackgroundTransparency = 0.6
    headerDivider.BorderSizePixel = 0
    headerDivider.ZIndex = 6
    headerDivider.Parent = HeaderBar

    -- ═══ AVATAR ═══
    local AvatarHolder = Instance.new("Frame")
    AvatarHolder.Size = UDim2.fromOffset(40, 40)
    AvatarHolder.Position = UDim2.new(0, 14, 0.5, -20)
    AvatarHolder.BackgroundColor3 = Theme.ElementBackground
    AvatarHolder.ClipsDescendants = true
    AvatarHolder.ZIndex = 6
    AvatarHolder.Parent = HeaderBar
    Round(11, AvatarHolder)

    local AvStroke = Outline(AvatarHolder, Theme.Accent, 1.5, 0.25)
    register("Strokes", AvStroke)

    local logoResolved = logoKey and ResolveIcon(logoKey) or ""
    if logoResolved ~= "" then
        local logoImg = Img(AvatarHolder, logoKey, UDim2.fromScale(0.72, 0.72), Color3.new(1,1,1), 0, 7)
        if logoImg then
            logoImg.AnchorPoint = Vector2.new(0.5, 0.5)
            logoImg.Position = UDim2.fromScale(0.5, 0.5)
        end
    elseif LocalPlayer then
        local avatarImg = Instance.new("ImageLabel")
        avatarImg.Size = UDim2.fromScale(1, 1)
        avatarImg.BackgroundTransparency = 1
        avatarImg.ScaleType = Enum.ScaleType.Crop
        avatarImg.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", LocalPlayer.UserId)
        avatarImg.ZIndex = 7
        avatarImg.Parent = AvatarHolder
    end

    local onlineDot = Instance.new("Frame")
    onlineDot.Size = UDim2.fromOffset(10, 10)
    onlineDot.Position = UDim2.new(1, -10, 1, -10)
    onlineDot.BackgroundColor3 = Theme.Success
    onlineDot.BorderSizePixel = 0
    onlineDot.ZIndex = 8
    onlineDot.Parent = AvatarHolder
    Round(5, onlineDot)
    Outline(onlineDot, Theme.Background2, 2, 0)

    -- ═══ TITLE ═══
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Position = UDim2.new(0, 64, 0, 10)
    TitleLabel.Size = UDim2.new(0, 240, 0, 22)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 6
    TitleLabel.Parent = HeaderBar

    local versionBadge = Instance.new("Frame")
    versionBadge.Size = UDim2.fromOffset(68, 18)
    versionBadge.Position = UDim2.new(0, 64, 0, 32)
    versionBadge.BackgroundColor3 = Theme.Accent
    versionBadge.BackgroundTransparency = 0.85
    versionBadge.ZIndex = 7
    versionBadge.Parent = HeaderBar
    Round(5, versionBadge)
    Outline(versionBadge, Theme.Accent, 1, 0.6)

    local versionLbl = Instance.new("TextLabel")
    versionLbl.Size = UDim2.fromScale(1, 1)
    versionLbl.BackgroundTransparency = 1
    versionLbl.Text = "v" .. SZK.Version
    versionLbl.Font = Enum.Font.GothamBold
    versionLbl.TextSize = 18
    versionLbl.TextColor3 = Theme.Accent
    versionLbl.ZIndex = 8
    versionLbl.Parent = versionBadge

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Text = description
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 18
    DescLabel.TextColor3 = Theme.Placeholder
    DescLabel.Position = UDim2.new(0, 140, 0, 32)
    DescLabel.Size = UDim2.new(0, 180, 0, 18)
    DescLabel.BackgroundTransparency = 1
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.TextTruncate = Enum.TextTruncate.AtEnd
    DescLabel.ZIndex = 6
    DescLabel.Parent = HeaderBar

    -- ═══ BOTONES DE VENTANA ═══
    local ctrlSize = 28
    local ctrlSpacing = 6

    local function MakeCtrlBtn(symbol, color, posX, hoverColor)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(ctrlSize, ctrlSize)
        btn.Position = UDim2.new(1, posX, 0.5, -ctrlSize/2)
        btn.BackgroundColor3 = color or Theme.ElementBackground
        btn.BackgroundTransparency = 1
        btn.Text = symbol
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 18
        btn.TextColor3 = Theme.Placeholder
        btn.AutoButtonColor = false
        btn.ZIndex = 8
        btn.Parent = HeaderBar
        Round(8, btn)

        btn.MouseEnter:Connect(function()
            Tween(btn, 0.15, { BackgroundTransparency = 0, BackgroundColor3 = hoverColor or Shade(Theme.ElementBackground, 0.15) })
            Tween(btn, 0.15, { TextColor3 = Theme.Text })
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, 0.15, { BackgroundTransparency = 1 })
            Tween(btn, 0.15, { TextColor3 = Theme.Placeholder })
        end)
        return btn
    end

    local CloseBtn = MakeCtrlBtn("✕", Color3.fromRGB(240, 75, 75), -42, Color3.fromRGB(240, 75, 75))
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, 0.15, { TextColor3 = Color3.new(1,1,1) })
    end)

    local MaxBtn = MakeCtrlBtn("⧉", nil, -42 - (ctrlSize + ctrlSpacing))
    local MinBtn = MakeCtrlBtn("−", nil, -42 - (ctrlSize + ctrlSpacing) * 2)

    local ThemeBtn
    if showThemeSel then
        ThemeBtn = MakeCtrlBtn("◐", nil, -42 - (ctrlSize + ctrlSpacing) * 3)
        local themeStroke = Outline(ThemeBtn, Theme.Outline, 1, 0.5)
        ThemeBtn.MouseEnter:Connect(function()
            Tween(themeStroke, 0.15, { Transparency = 0.2, Color = Theme.Accent })
        end)
        ThemeBtn.MouseLeave:Connect(function()
            Tween(themeStroke, 0.15, { Transparency = 0.5, Color = Theme.Outline })
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    --  MODAL DE CONFIRMACIÓN
    -- ═══════════════════════════════════════════════════════════
    local ModalBackdrop = Instance.new("TextButton")
    ModalBackdrop.Size = UDim2.fromScale(1, 1)
    ModalBackdrop.BackgroundColor3 = Color3.new(0, 0, 0)
    ModalBackdrop.BackgroundTransparency = 0.5
    ModalBackdrop.Text = ""
    ModalBackdrop.AutoButtonColor = false
    ModalBackdrop.Visible = false
    ModalBackdrop.ZIndex = 499
    ModalBackdrop.Parent = WindowGui

    local ConfirmModal = Instance.new("Frame")
    ConfirmModal.Size = UDim2.fromOffset(340, 190)
    ConfirmModal.Position = UDim2.fromScale(0.5, 0.5)
    ConfirmModal.AnchorPoint = Vector2.new(0.5, 0.5)
    ConfirmModal.BackgroundColor3 = Theme.ElementBackground
    ConfirmModal.BackgroundTransparency = 0
    ConfirmModal.Visible = false
    ConfirmModal.ZIndex = 500
    ConfirmModal.Parent = WindowGui
    Round(16, ConfirmModal)
    Outline(ConfirmModal, Color3.fromRGB(220, 60, 60), 1.5, 0.15)
    MultiGradient(ConfirmModal, {
        Shade(Theme.ElementBackground, 0.05),
        Theme.ElementBackground,
    }, 135)

    local ModalShadow = Instance.new("Frame")
    ModalShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    ModalShadow.BackgroundTransparency = 0.7
    ModalShadow.BorderSizePixel = 0
    ModalShadow.Size = UDim2.new(1, 16, 1, 16)
    ModalShadow.Position = UDim2.new(0, -8, 0, -8)
    ModalShadow.ZIndex = -1
    ModalShadow.Parent = ConfirmModal
    Round(22, ModalShadow)

    local warnBadge = Instance.new("Frame")
    warnBadge.Size = UDim2.fromOffset(38, 38)
    warnBadge.Position = UDim2.new(0, 20, 0, 18)
    warnBadge.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    warnBadge.BackgroundTransparency = 0.85
    warnBadge.ZIndex = 502
    warnBadge.Parent = ConfirmModal
    Round(10, warnBadge)
    Outline(warnBadge, Color3.fromRGB(220, 60, 60), 1, 0.4)

    local warnIcon = Instance.new("TextLabel")
    warnIcon.Size = UDim2.fromScale(1, 1)
    warnIcon.BackgroundTransparency = 1
    warnIcon.Text = "!"
    warnIcon.Font = Enum.Font.GothamBlack
    warnIcon.TextSize = 18
    warnIcon.TextColor3 = Color3.fromRGB(255, 100, 100)
    warnIcon.ZIndex = 503
    warnIcon.Parent = warnBadge

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Size = UDim2.new(1, -80, 0, 26)
    ModalTitle.Position = UDim2.new(0, 68, 0, 18)
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Text = "Close Window?"
    ModalTitle.Font = Enum.Font.GothamBold
    ModalTitle.TextSize = 18
    ModalTitle.TextColor3 = Theme.Text
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
    ModalTitle.ZIndex = 501
    ModalTitle.Parent = ConfirmModal

    local ModalMsg = Instance.new("TextLabel")
    ModalMsg.Size = UDim2.new(1, -40, 0, 50)
    ModalMsg.Position = UDim2.new(0, 20, 0, 62)
    ModalMsg.BackgroundTransparency = 1
    ModalMsg.Text = "Do you want to close this window?\nYou will not be able to open it again."
    ModalMsg.Font = Enum.Font.Gotham
    ModalMsg.TextSize = 18
    ModalMsg.TextColor3 = Theme.Placeholder
    ModalMsg.TextXAlignment = Enum.TextXAlignment.Left
    ModalMsg.TextYAlignment = Enum.TextYAlignment.Top
    ModalMsg.TextWrapped = true
    ModalMsg.ZIndex = 501
    ModalMsg.Parent = ConfirmModal

    local ModalBtnRow = Instance.new("Frame")
    ModalBtnRow.Size = UDim2.new(1, -40, 0, 40)
    ModalBtnRow.Position = UDim2.new(0, 20, 1, -56)
    ModalBtnRow.BackgroundTransparency = 1
    ModalBtnRow.ZIndex = 501
    ModalBtnRow.Parent = ConfirmModal

    local CancelBtn = Instance.new("TextButton")
    CancelBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CancelBtn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.12)
    CancelBtn.BackgroundTransparency = 0
    CancelBtn.Text = "Cancel"
    CancelBtn.Font = Enum.Font.GothamBold
    CancelBtn.TextSize = 18
    CancelBtn.TextColor3 = Theme.Text
    CancelBtn.AutoButtonColor = false
    CancelBtn.ZIndex = 502
    CancelBtn.Parent = ModalBtnRow
    Round(10, CancelBtn)
    Outline(CancelBtn, Theme.Outline, 1, 0.5)

    local ConfirmBtn = Instance.new("TextButton")
    ConfirmBtn.Size = UDim2.new(0.5, -6, 1, 0)
    ConfirmBtn.Position = UDim2.new(0.5, 6, 0, 0)
    ConfirmBtn.BackgroundColor3 = Color3.fromRGB(200, 45, 45)
    ConfirmBtn.BackgroundTransparency = 0
    ConfirmBtn.Text = "Close Window"
    ConfirmBtn.Font = Enum.Font.GothamBold
    ConfirmBtn.TextSize = 18
    ConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
    ConfirmBtn.AutoButtonColor = false
    ConfirmBtn.ZIndex = 502
    ConfirmBtn.Parent = ModalBtnRow
    Round(10, ConfirmBtn)
    Outline(ConfirmBtn, Color3.fromRGB(255, 100, 100), 1.5, 0.3)

    CancelBtn.MouseEnter:Connect(function()
        Tween(CancelBtn, 0.15, { BackgroundColor3 = Shade(Theme.ElementBackground, 0.2) })
    end)
    CancelBtn.MouseLeave:Connect(function()
        Tween(CancelBtn, 0.15, { BackgroundColor3 = Shade(Theme.ElementBackground, 0.12) })
    end)
    ConfirmBtn.MouseEnter:Connect(function()
        Tween(ConfirmBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(230, 55, 55) })
    end)
    ConfirmBtn.MouseLeave:Connect(function()
        Tween(ConfirmBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(200, 45, 45) })
    end)

    -- ═══ SIDEBAR ═══
    local SIDEBAR_W = 145
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -78)
    Sidebar.Position = UDim2.new(0, 8, 0, 66)
    Sidebar.BackgroundTransparency = 1
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 3
    Sidebar.ScrollBarImageColor3 = Theme.Accent
    Sidebar.ScrollBarImageTransparency = 0.4
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.ZIndex = 5
    Sidebar.Parent = MainFrame
    Round(10, Sidebar)

    local SidebarPad = Instance.new("UIPadding")
    SidebarPad.PaddingTop = UDim.new(0, 6)
    SidebarPad.PaddingBottom = UDim.new(0, 10)
    SidebarPad.PaddingLeft = UDim.new(0, 4)
    SidebarPad.PaddingRight = UDim.new(0, 4)
    SidebarPad.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = Sidebar

    local PageHost = Instance.new("Frame")
    PageHost.Size = UDim2.new(1, -(SIDEBAR_W + 26), 1, -78)
    PageHost.Position = UDim2.new(0, SIDEBAR_W + 16, 0, 66)
    PageHost.BackgroundTransparency = 1
    PageHost.ZIndex = 5
    PageHost.Parent = MainFrame

    -- ═══ FOOTER ═══
    if showFooter then
        local footer = Instance.new("Frame")
        footer.Size = UDim2.new(1, 0, 0, 22)
        footer.Position = UDim2.new(0, 0, 1, -22)
        footer.BackgroundColor3 = Theme.Background2
        footer.BackgroundTransparency = 0.3
        footer.BorderSizePixel = 0
        footer.ZIndex = 5
        footer.Parent = MainFrame
        Round(16, footer)

        local footLbl = Instance.new("TextLabel")
        footLbl.Size = UDim2.new(1, 0, 1, 0)
        footLbl.BackgroundTransparency = 1
        footLbl.Text = "FLUID UI v" .. SZK.Version .. "  •  RightShift to toggle"
        footLbl.Font = Enum.Font.Gotham
        footLbl.TextSize = 18
        footLbl.TextColor3 = Theme.Placeholder
        footLbl.TextTransparency = 0.4
        footLbl.ZIndex = 6
        footLbl.Parent = footer
    end

    -- ═══════════════════════════════════════════════════════════
    --  BOTÓN FLOTANTE (color del theme)
    -- ═══════════════════════════════════════════════════════════
    local FB_W, FB_H = 155, 50

    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Size = UDim2.fromOffset(FB_W, FB_H)
    FloatBtn.Position = UDim2.new(0, 24, 0.5, -FB_H/2)
    FloatBtn.BackgroundColor3 = Theme.Background2
    FloatBtn.BackgroundTransparency = 0
    FloatBtn.Text = ""
    FloatBtn.AutoButtonColor = false
    FloatBtn.Visible = false
    FloatBtn.ClipsDescendants = false
    FloatBtn.ZIndex = 10
    FloatBtn.Parent = WindowGui
    Round(FB_H / 2, FloatBtn)
    Gradient(FloatBtn,
        Blend(Theme.Background2, Theme.Accent, 0.12),
        Theme.Background2,
        135
    )

    local fbShadow = Instance.new("Frame")
    fbShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    fbShadow.BackgroundTransparency = 0.6
    fbShadow.BorderSizePixel = 0
    fbShadow.Size = UDim2.new(1, 8, 1, 8)
    fbShadow.Position = UDim2.new(0, -4, 0, -4)
    fbShadow.ZIndex = -1
    fbShadow.Parent = FloatBtn
    Round(FB_H / 2 + 4, fbShadow)

    local fbStroke = Outline(FloatBtn, Theme.Accent, 2, 0.1)
    fbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local fbInnerStroke = Instance.new("UIStroke")
    fbInnerStroke.Color = Blend(Theme.Accent, Color3.new(1, 1, 1), 0.4)
    fbInnerStroke.Thickness = 1
    fbInnerStroke.Transparency = 0.7
    fbInnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    fbInnerStroke.Parent = FloatBtn

    local DragIcon = Instance.new("Frame")
    DragIcon.Size = UDim2.fromOffset(26, 26)
    DragIcon.Position = UDim2.new(0, 14, 0.5, -13)
    DragIcon.BackgroundTransparency = 1
    DragIcon.ZIndex = 12
    DragIcon.Parent = FloatBtn

    local crossH = Instance.new("Frame")
    crossH.Size = UDim2.fromOffset(16, 2)
    crossH.Position = UDim2.new(0.5, -8, 0.5, -1)
    crossH.BackgroundColor3 = Theme.Accent
    crossH.BorderSizePixel = 0
    crossH.ZIndex = 13
    crossH.Parent = DragIcon
    Round(1, crossH)

    local crossV = Instance.new("Frame")
    crossV.Size = UDim2.fromOffset(2, 16)
    crossV.Position = UDim2.new(0.5, -1, 0.5, -8)
    crossV.BackgroundColor3 = Theme.Accent
    crossV.BorderSizePixel = 0
    crossV.ZIndex = 13
    crossV.Parent = DragIcon
    Round(1, crossV)

    local FBLabel = Instance.new("TextLabel")
    FBLabel.Size = UDim2.new(1, -50, 1, 0)
    FBLabel.Position = UDim2.new(0, 46, 0, 0)
    FBLabel.BackgroundTransparency = 1
    FBLabel.Text = openBtnText
    FBLabel.Font = Enum.Font.GothamBold
    FBLabel.TextSize = 18
    FBLabel.TextColor3 = Theme.Text
    FBLabel.TextXAlignment = Enum.TextXAlignment.Center
    FBLabel.ZIndex = 12
    FBLabel.Parent = FloatBtn

    if openBtnIcon then
        local resolvedOpenIcon = ResolveIcon(openBtnIcon)
        if resolvedOpenIcon ~= "" then
            DragIcon.Visible = false
            local iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.fromOffset(26, 26)
            iconImg.Position = UDim2.new(0, 14, 0.5, -13)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = resolvedOpenIcon
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.ImageColor3 = Theme.Accent
            iconImg.ZIndex = 12
            iconImg.Parent = FloatBtn
        end
    end

    local fbDragging, fbStart, fbInputStart, fbMoved = false, nil, nil, false
    Track(FloatBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            fbDragging = true; fbMoved = false
            fbStart = FloatBtn.Position
            fbInputStart = i.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    fbDragging = false
                    if not fbMoved then
                        MainFrame.Visible = true
                        MainFrame.Size = UDim2.fromOffset(size.X * 0.7, size.Y * 0.7)
                        MainFrame.BackgroundTransparency = 0.4
                        Tween(MainFrame, 0.45, {
                            Size = UDim2.fromOffset(size.X, size.Y),
                            BackgroundTransparency = 0
                        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        FloatBtn.Visible = false
                    end
                end
            end)
        end
    end))

    Track(UserInputService.InputChanged:Connect(function(i)
        if fbDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - fbInputStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then fbMoved = true end
            FloatBtn.Position = UDim2.new(fbStart.X.Scale, fbStart.X.Offset + delta.X, fbStart.Y.Scale, fbStart.Y.Offset + delta.Y)
        end
    end))

    Track(FloatBtn.MouseEnter:Connect(function()
        Tween(fbStroke, 0.2, { Transparency = 0, Thickness = 2.5 })
        Tween(FloatBtn, 0.2, { BackgroundColor3 = Blend(Theme.Background2, Theme.Accent, 0.18) })
    end))
    Track(FloatBtn.MouseLeave:Connect(function()
        Tween(fbStroke, 0.2, { Transparency = 0.1, Thickness = 2 })
        Tween(FloatBtn, 0.2, { BackgroundColor3 = Theme.Background2 })
    end))

    -- ═══ RESIZE GRIP ═══
    local RESIZE_HIT = 36
    local ResizeGrip = Instance.new("TextButton")
    ResizeGrip.AnchorPoint = Vector2.new(1, 1)
    ResizeGrip.Position = UDim2.new(1, 0, 1, 0)
    ResizeGrip.Size = UDim2.fromOffset(RESIZE_HIT, RESIZE_HIT)
    ResizeGrip.BackgroundTransparency = 1
    ResizeGrip.Text = ""
    ResizeGrip.AutoButtonColor = false
    ResizeGrip.ZIndex = 25
    ResizeGrip.Parent = MainFrame

    local gripVisual = Instance.new("Frame")
    gripVisual.AnchorPoint = Vector2.new(1, 1)
    gripVisual.Position = UDim2.new(1, -6, 1, -6)
    gripVisual.Size = UDim2.fromOffset(14, 14)
    gripVisual.BackgroundTransparency = 1
    gripVisual.ZIndex = 25
    gripVisual.Parent = ResizeGrip

    local gripLines = {}
    for i = 1, 3 do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(1, 1)
        line.Position = UDim2.new(1, -((i - 1) * 4), 1, -((i - 1) * 4))
        line.Size = UDim2.fromOffset(11 - (i - 1) * 3.5, 2)
        line.BackgroundColor3 = Theme.Accent
        line.BackgroundTransparency = 0.4
        line.BorderSizePixel = 0
        line.ZIndex = 26
        line.Parent = gripVisual
        Round(1, line)
        table.insert(gripLines, line)
    end

    local gripHover = false
    local isResizing = false

    local function SetGripAlpha(alpha)
        for _, l in ipairs(gripLines) do
            l.BackgroundTransparency = alpha
        end
    end

    local function EnableResize(handle)
        local startSize, startInput
        Track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = true
                startSize = size
                startInput = input.Position
                SetGripAlpha(0)
            end
        end))
        Track(UserInputService.InputChanged:Connect(function(input)
            if not isResizing then return end
            if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
            local delta = input.Position - startInput
            local sc = WindowScale.Scale
            if sc <= 0 then sc = 1 end
            local newX = math.clamp(startSize.X + delta.X / sc, MIN_SIZE.X, MAX_SIZE.X)
            local newY = math.clamp(startSize.Y + delta.Y / sc, MIN_SIZE.Y, MAX_SIZE.Y)
            size = Vector2.new(newX, newY)
            MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
            RecalculateScale()
        end))
        Track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if isResizing then
                    isResizing = false
                    SetGripAlpha(gripHover and 0 or 0.4)
                end
            end
        end))
        Track(handle.MouseEnter:Connect(function()
            gripHover = true
            if not isResizing then
                Tween(gripLines[1], 0.12, { BackgroundTransparency = 0 })
                Tween(gripLines[2], 0.12, { BackgroundTransparency = 0.1 })
                Tween(gripLines[3], 0.12, { BackgroundTransparency = 0.2 })
            end
        end))
        Track(handle.MouseLeave:Connect(function()
            gripHover = false
            if not isResizing then SetGripAlpha(0.4) end
        end))
    end
    EnableResize(ResizeGrip)

    local function EnableDrag(handle, target)
        local dragging, startPos, startInput
        Track(handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                startPos = target.Position
                startInput = input.Position
            end
        end))
        Track(UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - startInput
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end))
        Track(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))
    end
    EnableDrag(HeaderBar, MainFrame)

    -- ═══ MIN/MAX/CLOSE ═══
    local isMaximized = false
    local savedSize = size
    local savedPos = MainFrame.Position

    local function CloseWindow()
        Tween(MainFrame, 0.3, { Size = UDim2.fromOffset(size.X * 0.75, size.Y * 0.75) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.3, function()
            MainFrame.Visible = false
            FloatBtn.Visible = true
        end)
    end

    local function OpenWindow()
        MainFrame.Visible = true
        MainFrame.Size = UDim2.fromOffset(size.X * 0.7, size.Y * 0.7)
        MainFrame.BackgroundTransparency = 0.3
        Tween(MainFrame, 0.4, { Size = UDim2.fromOffset(size.X, size.Y), BackgroundTransparency = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        FloatBtn.Visible = false
    end

    local function Minimize()
        Tween(MainFrame, 0.28, { Size = UDim2.fromOffset(size.X * 0.7, size.Y * 0.7) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.28, function()
            MainFrame.Visible = false
            FloatBtn.Visible = true
        end)
    end

    local function Maximize()
        if isMaximized then
            Tween(MainFrame, 0.35, {
                Size = UDim2.fromOffset(savedSize.X, savedSize.Y),
                Position = savedPos
            }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            isMaximized = false
            MaxBtn.Text = "⧉"
        else
            savedSize = size
            savedPos = MainFrame.Position
            local vp = GetViewport()
            Tween(MainFrame, 0.35, {
                Size = UDim2.fromOffset(vp.X * 0.85, vp.Y * 0.8),
                Position = UDim2.fromScale(0.5, 0.5)
            }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            isMaximized = true
            MaxBtn.Text = "❐"
        end
    end

    local function ReallyClose()
        SZK:Info("UI Closed", "The interface has been closed successfully.", 3)
        scansEnabled = false
        for _, s in ipairs(activeScans) do s.enabled = false end
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        for i, w in ipairs(SZK.Windows) do
            if w == Window then table.remove(SZK.Windows, i) break end
        end
        Tween(MainFrame, 0.35, {
            Size = UDim2.fromOffset(size.X * 0.5, size.Y * 0.5),
            BackgroundTransparency = 0.7
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(ConfirmModal, 0.3, {
            Size = UDim2.fromOffset(200, 100),
            BackgroundTransparency = 0.6
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        Tween(ModalBackdrop, 0.3, { BackgroundTransparency = 1 })
        task.delay(0.36, function()
            pcall(function() WindowGui:Destroy() end)
        end)
    end

    local function ShowConfirmModal()
        ModalBackdrop.Visible = true
        ModalBackdrop.BackgroundTransparency = 1
        ConfirmModal.Visible = true
        ConfirmModal.BackgroundTransparency = 1
        ConfirmModal.Size = UDim2.fromOffset(240, 130)
        Tween(ModalBackdrop, 0.25, { BackgroundTransparency = 0.5 })
        Tween(ConfirmModal, 0.35, {
            Size = UDim2.fromOffset(340, 190),
            BackgroundTransparency = 0
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    local function HideConfirmModal()
        Tween(ModalBackdrop, 0.2, { BackgroundTransparency = 1 })
        Tween(ConfirmModal, 0.2, {
            Size = UDim2.fromOffset(240, 130),
            BackgroundTransparency = 1
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.22, function()
            ModalBackdrop.Visible = false
            ConfirmModal.Visible = false
        end)
    end

    CancelBtn.MouseButton1Click:Connect(HideConfirmModal)
    ConfirmBtn.MouseButton1Click:Connect(ReallyClose)
    ModalBackdrop.MouseButton1Click:Connect(HideConfirmModal)
    CloseBtn.MouseButton1Click:Connect(ShowConfirmModal)
    MinBtn.MouseButton1Click:Connect(Minimize)
    MaxBtn.MouseButton1Click:Connect(Maximize)

    Track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == toggleKey then
            if MainFrame.Visible then CloseWindow() else OpenWindow() end
        end
    end))

    Track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        task.defer(function()
            local pos = input.Position
            for _, p in ipairs(OpenPopups) do
                if p.Frame.Visible then
                    local a, s = p.Frame.AbsolutePosition, p.Frame.AbsoluteSize
                    local inF = pos.X >= a.X and pos.X <= a.X + s.X and pos.Y >= a.Y and pos.Y <= a.Y + s.Y
                    local inT = false
                    if p.Trigger then
                        local ta, ts = p.Trigger.AbsolutePosition, p.Trigger.AbsoluteSize
                        inT = pos.X >= ta.X and pos.X <= ta.X + ts.X and pos.Y >= ta.Y and pos.Y <= ta.Y + ts.Y
                    end
                    if not inF and not inT then p.Frame.Visible = false end
                end
            end
        end)
    end))

    -- ═══ THEME POPUP ═══
    local ThemePopup
    if showThemeSel then
        ThemePopup = Instance.new("Frame")
        ThemePopup.Size = UDim2.fromOffset(220, 340)
        ThemePopup.BackgroundColor3 = Theme.ElementBackground
        ThemePopup.BackgroundTransparency = 0.02
        ThemePopup.Visible = false
        ThemePopup.ZIndex = 200
        ThemePopup.ClipsDescendants = true
        ThemePopup.Parent = WindowGui
        Round(14, ThemePopup)
        Outline(ThemePopup, Theme.Outline, 1.5, 0.3)

        local popupShadow = Instance.new("Frame")
        popupShadow.BackgroundColor3 = Color3.new(0, 0, 0)
        popupShadow.BackgroundTransparency = 0.7
        popupShadow.BorderSizePixel = 0
        popupShadow.Size = UDim2.new(1, 12, 1, 12)
        popupShadow.Position = UDim2.new(0, -6, 0, -6)
        popupShadow.ZIndex = -1
        popupShadow.Parent = ThemePopup
        Round(18, popupShadow)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 8)
        pad.PaddingBottom = UDim.new(0, 8)
        pad.PaddingLeft = UDim.new(0, 8)
        pad.PaddingRight = UDim.new(0, 8)
        pad.Parent = ThemePopup

        local scroll = Instance.new("ScrollingFrame")
        scroll.Size = UDim2.new(1, 0, 1, 0)
        scroll.BackgroundTransparency = 1
        scroll.ScrollBarThickness = 3
        scroll.ScrollBarImageColor3 = Theme.Accent
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ZIndex = 201
        scroll.Parent = ThemePopup

        local listLayout = Instance.new("UIListLayout")
        listLayout.Padding = UDim.new(0, 4)
        listLayout.Parent = scroll

        for _, tName in ipairs(SZK.ThemeOrder) do
            local tData = SZK.Themes[tName]
            if tData then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 40)
                btn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.02)
                btn.BackgroundTransparency = 0.4
                btn.AutoButtonColor = false
                btn.Text = ""
                btn.ZIndex = 202
                btn.Parent = scroll
                Round(8, btn)

                local swatch = Instance.new("Frame")
                swatch.Size = UDim2.fromOffset(24, 24)
                swatch.Position = UDim2.new(0, 8, 0.5, -12)
                swatch.BackgroundColor3 = tData.Accent
                swatch.ZIndex = 203
                swatch.Parent = btn
                Round(7, swatch)
                Outline(swatch, Color3.fromRGB(255, 255, 255), 1, 0.75)
                Gradient(swatch, Blend(tData.Accent, Color3.new(1,1,1), 0.2), Blend(tData.Accent, Color3.new(0,0,0), 0.15), 135)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -42, 1, 0)
                label.Position = UDim2.new(0, 40, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = tName
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 18
                label.TextColor3 = Theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.ZIndex = 203
                label.Parent = btn

                btn.MouseEnter:Connect(function()
                    Tween(btn, 0.15, { BackgroundTransparency = 0 })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, 0.15, { BackgroundTransparency = 0.4 })
                end)
                btn.MouseButton1Click:Connect(function()
                    Theme = tData
                    SZK.CurrentTheme = Theme
                    ThemePopup.Visible = false

                    -- Actualizar ventana
                    MainFrame.BackgroundColor3 = Theme.Background
                    Overlay.BackgroundColor3 = Theme.Background
                    HeaderBar.BackgroundColor3 = Theme.Background2
                    TitleLabel.TextColor3 = Theme.Text
                    DescLabel.TextColor3 = Theme.Placeholder
                    MainStroke.Color = Theme.Accent
                    strokeGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Theme.Accent),
                        ColorSequenceKeypoint.new(0.5, Blend(Theme.Accent, Color3.new(1,1,1), 0.4)),
                        ColorSequenceKeypoint.new(1, Theme.Accent),
                    })
                    OuterGlow.BackgroundColor3 = Theme.Accent
                    ThemePopup.BackgroundColor3 = Theme.ElementBackground
                    versionBadge.BackgroundColor3 = Theme.Accent
                    versionLbl.TextColor3 = Theme.Accent
                    for _, l in ipairs(gripLines) do l.BackgroundColor3 = Theme.Accent end
                    for _, k in ipairs(ThemedElements.Knobs) do k.BackgroundColor3 = Theme.Background end

                    -- Actualizar botón flotante
                    FloatBtn.BackgroundColor3 = Theme.Background2
                    fbStroke.Color = Theme.Accent
                    fbInnerStroke.Color = Blend(Theme.Accent, Color3.new(1, 1, 1), 0.4)
                    crossH.BackgroundColor3 = Theme.Accent
                    crossV.BackgroundColor3 = Theme.Accent
                    FBLabel.TextColor3 = Theme.Text

                    -- Actualizar scans
                    for _, s in ipairs(ThemedElements.Scans) do
                        s.scan.BackgroundColor3 = Theme.Accent
                        s.glow.BackgroundColor3 = Theme.Accent
                        if s.grad then
                            s.grad.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Theme.Accent),
                                ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                                ColorSequenceKeypoint.new(1, Theme.Accent),
                            })
                        end
                        if s.glowGrad then
                            s.glowGrad.Color = ColorSequence.new(Theme.Accent, Theme.Accent)
                        end
                    end
                end)
            end
        end

        RegisterPopup(ThemePopup, ThemeBtn)
        ThemeBtn.MouseButton1Click:Connect(function()
            if ThemePopup.Visible then ThemePopup.Visible = false; return end
            CloseAllPopups(ThemeBtn)
            local abs = ThemeBtn.AbsolutePosition
            local asz = ThemeBtn.AbsoluteSize
            local viewport = GetViewport()
            local x = math.clamp(abs.X - 194, 6, math.max(6, viewport.X - 226))
            local belowY = abs.Y + asz.Y + 6
            local y = belowY + 340 <= viewport.Y - 6 and belowY or math.max(6, abs.Y - 346)
            ThemePopup.Position = UDim2.fromOffset(x, y)
            ThemePopup.Visible = true
        end)
    end

    local Window = { Tabs = {}, Connections = Connections }

    -- ═══ ROW BUILDER ═══
    local function RegisterRow(parent, height)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, height or 58)
        frame.BackgroundColor3 = Theme.ElementBackground
        frame.BackgroundTransparency = 0.05
        frame.ClipsDescendants = true
        frame.ZIndex = 6
        frame.Parent = parent
        Round(12, frame)

        MultiGradient(frame, {
            Shade(Theme.ElementBackground, 0.06),
            Theme.ElementBackground,
            Shade(Theme.ElementBackground, -0.02),
        }, 135)

        local stroke = Outline(frame, Theme.Outline, 1, 0.5)
        register("Strokes", stroke)

        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 1, -20)
        accentBar.Position = UDim2.new(0, 0, 0, 10)
        accentBar.BackgroundColor3 = Theme.Accent
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 7
        accentBar.Parent = frame
        Round(2, accentBar)
        Gradient(accentBar, Theme.Accent, Blend(Theme.Accent, Color3.new(1,1,1), 0.3), 90)
        register("Fills", accentBar)

        local hoverGlow = Outline(frame, Theme.Accent, 1.5, 1)
        register("Strokes", hoverGlow)

        frame.MouseEnter:Connect(function()
            Tween(frame, 0.2, { BackgroundTransparency = 0 })
            Tween(hoverGlow, 0.25, { Transparency = 0.4 })
            Tween(stroke, 0.25, { Transparency = 0.6 })
        end)
        frame.MouseLeave:Connect(function()
            Tween(frame, 0.2, { BackgroundTransparency = 0.05 })
            Tween(hoverGlow, 0.25, { Transparency = 1 })
            Tween(stroke, 0.25, { Transparency = 0.5 })
        end)

        return frame, stroke, accentBar
    end

    -- ═══════════════════════════════════════════════════════════
    --  CREATE TAB
    -- ═══════════════════════════════════════════════════════════
    function Window:CreateTab(tabConfig)
        local cfg = type(tabConfig) == "table" and tabConfig or {}
        local tabName = cfg.Name or cfg.Title or (type(tabConfig) == "string" and tabConfig) or "Tab"
        local tabIcon = cfg.Icon

        local page = Instance.new("ScrollingFrame")
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.Visible = false
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.Accent
        page.ScrollBarImageTransparency = 0.4
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ZIndex = 5
        page.Parent = PageHost

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 10)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingBottom = UDim.new(0, 12)
        pagePad.PaddingRight = UDim.new(0, 8)
        pagePad.Parent = page

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 42)
        tabBtn.BackgroundColor3 = Theme.ElementBackground
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 6
        tabBtn.Parent = Sidebar
        Round(9, tabBtn)

        local tabStroke = Outline(tabBtn, Theme.Accent, 1, 1)
        register("Strokes", tabStroke)

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0, 0)
        activeBar.Position = UDim2.new(0, 0, 0.5, 0)
        activeBar.AnchorPoint = Vector2.new(0, 0.5)
        activeBar.BackgroundColor3 = Theme.Accent
        activeBar.BorderSizePixel = 0
        activeBar.ZIndex = 9
        activeBar.Parent = tabBtn
        Round(2, activeBar)
        register("Fills", activeBar)

        local tabIconImg
        local resolvedTabIcon = ResolveIcon(tabIcon)
        if resolvedTabIcon ~= "" then
            tabIconImg = Img(tabBtn, tabIcon, UDim2.fromOffset(18, 18), Theme.Placeholder, 0, 8)
            if tabIconImg then tabIconImg.Position = UDim2.new(0, 12, 0.5, -9) end
        end

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, tabIconImg and -42 or -20, 1, 0)
        tLabel.Position = UDim2.new(0, tabIconImg and 40 or 14, 0, 0)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = tabName
        tLabel.Font = Enum.Font.GothamSemibold
        tLabel.TextSize = 18
        tLabel.TextColor3 = Theme.Placeholder
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.TextTruncate = Enum.TextTruncate.AtEnd
        tLabel.ZIndex = 8
        tLabel.Parent = tabBtn

        local tabData = {
            Type = "TabBtn", Instance = tabBtn, Stroke = tabStroke,
            Label = tLabel, Icon = tabIconImg, Active = false,
            Page = page, Bar = activeBar,
        }
        table.insert(Registered, tabData)

        local function Activate()
            for _, item in ipairs(Registered) do
                if item.Type == "TabBtn" then
                    item.Active = false
                    item.Page.Visible = false
                    item.Label.TextColor3 = Theme.Placeholder
                    Tween(item.Instance, 0.15, { BackgroundTransparency = 1 })
                    Tween(item.Stroke, 0.15, { Transparency = 1 })
                    Tween(item.Bar, 0.2, { Size = UDim2.new(0, 3, 0, 0) })
                    if item.Icon then TintIfAllowed(item.Icon, Theme.Placeholder) end
                end
            end
            tabData.Active = true
            page.Visible = true
            tLabel.TextColor3 = Theme.Text
            Tween(tabBtn, 0.2, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Accent })
            Tween(tabStroke, 0.2, { Transparency = 0.4, Color = Theme.Accent })
            Tween(activeBar, 0.3, { Size = UDim2.new(0, 3, 0, 26) }, Enum.EasingStyle.Back)
            if tabIconImg then TintIfAllowed(tabIconImg, Theme.Accent) end
        end

        tabBtn.MouseButton1Click:Connect(Activate)
        Ripple(tabBtn, Theme.Accent)

        tabBtn.MouseEnter:Connect(function()
            if not tabData.Active then
                Tween(tabBtn, 0.15, { BackgroundTransparency = 0.75, BackgroundColor3 = Theme.ElementBackground })
                Tween(tLabel, 0.15, { TextColor3 = Theme.Text })
                if tabIconImg then TintIfAllowed(tabIconImg, Theme.Text) end
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not tabData.Active then
                Tween(tabBtn, 0.15, { BackgroundTransparency = 1 })
                Tween(tLabel, 0.15, { TextColor3 = Theme.Placeholder })
                if tabIconImg then TintIfAllowed(tabIconImg, Theme.Placeholder) end
            end
        end)

        if #Window.Tabs == 0 then task.defer(Activate) end

        local Tab = {}
        Window.Tabs[tabName] = Tab

        -- ═══ CREATE SECTION ═══
        function Tab:CreateSection(secConfig)
            local secCfg = type(secConfig) == "table" and secConfig or {}
            local secName = secCfg.Name or secCfg.Title or (type(secConfig) == "string" and secConfig) or ""
            local secIcon = secCfg.Icon

            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, 0)
            container.AutomaticSize = Enum.AutomaticSize.Y
            container.BackgroundTransparency = 1
            container.ZIndex = 6
            container.Parent = page

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 7)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = container

            if secName ~= "" then
                local header = Instance.new("Frame")
                header.Size = UDim2.new(1, 0, 0, 30)
                header.BackgroundTransparency = 1
                header.ZIndex = 6
                header.Parent = container

                local secIconImg
                local resolvedSec = ResolveIcon(secIcon)
                if resolvedSec ~= "" then
                    secIconImg = Img(header, secIcon, UDim2.fromOffset(16, 16), Theme.Icon, 0, 8)
                    if secIconImg then secIconImg.Position = UDim2.new(0, 2, 0.5, -8) end
                end

                local hLabel = Instance.new("TextLabel")
                hLabel.Size = UDim2.new(1, secIconImg and -26 or -12, 1, 0)
                hLabel.Position = UDim2.new(0, secIconImg and 24 or 2, 0, 0)
                hLabel.BackgroundTransparency = 1
                hLabel.Text = string.upper(tostring(secName))
                hLabel.Font = Enum.Font.GothamBold
                hLabel.TextSize = 18
                hLabel.TextColor3 = Theme.Placeholder
                hLabel.TextXAlignment = Enum.TextXAlignment.Left
                hLabel.ZIndex = 7
                hLabel.Parent = header
            end

            local Section = {}

            local function AttachIcon(row, cfg, label)
                local icon = cfg and cfg.Icon
                if not icon then return nil end
                local position = cfg.IconPosition or "Left"
                local image = Img(row, icon, UDim2.fromOffset(18, 18), Theme.Icon, 0, 8)
                if not image then return nil end
                image.AnchorPoint = Vector2.new(position == "Right" and 1 or 0, 0.5)
                image.Position = position == "Right" and UDim2.new(1, -16, 0.5, 0) or UDim2.new(0, 16, 0.5, 0)
                if label and position == "Left" then
                    label.Position = UDim2.new(0, 42, label.Position.Y.Scale, label.Position.Y.Offset)
                    label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 36, label.Size.Y.Scale, label.Size.Y.Offset)
                end
                return image
            end

            -- ─── TOGGLE ───
            function Section:CreateToggle(tConfig)
                local c = tConfig or {}
                local name     = c.Name or c.Title or "Toggle"
                local desc     = c.Desc or c.Description or ""
                local default  = c.Default or c.Value or false
                local callback = c.Callback or function() end
                local flag     = c.Flag

                local rowH = (desc ~= "" and 88 or 58)
                local row, stroke, accentBar = RegisterRow(container, rowH)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -90, 0, 24)
                lbl.Position = UDim2.new(0, 18, 0, 12)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
                local elementIcon = AttachIcon(row, c, lbl)

                if desc ~= "" then
                    local dLbl = Instance.new("TextLabel")
                    dLbl.Size = UDim2.new(1, -22, 0, 36)
                    dLbl.Position = UDim2.new(0, 18, 0, 40)
                    dLbl.BackgroundTransparency = 1
                    dLbl.Text = desc
                    dLbl.Font = Enum.Font.Gotham
                    dLbl.TextSize = 18
                    dLbl.TextColor3 = Theme.Placeholder
                    dLbl.TextXAlignment = Enum.TextXAlignment.Left
                    dLbl.TextYAlignment = Enum.TextYAlignment.Top
                    dLbl.TextWrapped = true
                    dLbl.ZIndex = 7
                    dLbl.Parent = row
                end

                local switchW, switchH, knobSize, inset = 50, 28, 22, 3
                local track = Instance.new("TextButton")
                track.AnchorPoint = Vector2.new(1, 0)
                track.Position = UDim2.new(1, -18, 0, 15)
                track.Size = UDim2.fromOffset(switchW, switchH)
                track.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(55, 55, 65)
                track.Text = ""
                track.AutoButtonColor = false
                track.ZIndex = 8
                track.Parent = row
                Round(switchH, track)

                local trackStroke = Outline(track, Color3.new(1,1,1), 1, 0.85)

                local knob = Instance.new("Frame")
                knob.AnchorPoint = Vector2.new(0, 0.5)
                knob.Position = default and UDim2.new(1, -(inset + knobSize), 0.5, 0) or UDim2.new(0, inset, 0.5, 0)
                knob.Size = UDim2.fromOffset(knobSize, knobSize)
                knob.BackgroundColor3 = Theme.Background
                knob.BorderSizePixel = 0
                knob.ZIndex = 9
                knob.Parent = track
                Round(knobSize, knob)
                register("Knobs", knob)

                local state = default
                if flag then SZK.Flags[flag] = state end

                local function refresh(animate)
                    local kp = state and UDim2.new(1, -(inset + knobSize), 0.5, 0) or UDim2.new(0, inset, 0.5, 0)
                    local tc = state and Theme.Toggle or Color3.fromRGB(55, 55, 65)
                    if animate then
                        Spring(knob, 0.5, { Position = kp })
                        Tween(track, 0.25, { BackgroundColor3 = tc })
                    else
                        knob.Position = kp
                        track.BackgroundColor3 = tc
                    end
                end
                refresh(false)

                track.MouseButton1Click:Connect(function()
                    state = not state
                    if flag then SZK.Flags[flag] = state end
                    refresh(true)
                    callback(state)
                end)

                table.insert(Registered, {
                    Type = "Element", Instance = row, Stroke = stroke,
                    AccentBar = accentBar, Label = lbl, Icon = elementIcon,
                    SubColor = track, State = function() return state end,
                })

                local obj = {}
                function obj:Set(v)
                    state = v
                    if flag then SZK.Flags[flag] = state end
                    refresh(true)
                    callback(state)
                end
                function obj:Get() return state end
                return obj
            end

            -- ─── SLIDER ───
            function Section:CreateSlider(sConfig)
                local c = sConfig or {}
                local name     = c.Name or c.Title or "Slider"
                local min      = c.Min or 0
                local max      = c.Max or 100
                local default  = c.Default or c.Value or min
                local callback = c.Callback or function() end
                local suffix   = c.Suffix or ""

                local row, stroke, accentBar = RegisterRow(container, 68)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -20, 0, 24)
                lbl.Position = UDim2.new(0, 18, 0, 8)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
                local elementIcon = AttachIcon(row, c, lbl)

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.fromOffset(78, 24)
                valLbl.Position = UDim2.new(1, -94, 0, 8)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(default) .. suffix
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextSize = 18
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.ZIndex = 7
                valLbl.Parent = row
                register("Labels", valLbl)

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -36, 0, 5)
                track.Position = UDim2.new(0, 18, 0, 48)
                track.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
                track.ZIndex = 7
                track.Parent = row
                Round(3, track)

                local fill = Instance.new("Frame")
                local t0 = (default - min) / math.max(max - min, 1)
                fill.Size = UDim2.new(t0, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Slider
                fill.ZIndex = 8
                fill.Parent = track
                Round(3, fill)
                Gradient(fill, Theme.Slider, Blend(Theme.Slider, Color3.new(1,1,1), 0.3), 0)
                register("Fills", fill)

                local handle = Instance.new("Frame")
                handle.Size = UDim2.fromOffset(16, 16)
                handle.AnchorPoint = Vector2.new(0.5, 0.5)
                handle.Position = UDim2.new(t0, 0, 0.5, 0)
                handle.BackgroundColor3 = Color3.new(1, 1, 1)
                handle.ZIndex = 9
                handle.Parent = track
                Round(8, handle)

                local handleStroke = Outline(handle, Theme.Slider, 2, 0)
                register("Strokes", handleStroke)
                register("Knobs", handle)

                local dragging = false
                local function apply(v)
                    v = math.clamp(math.floor(v + 0.5), min, max)
                    valLbl.Text = tostring(v) .. suffix
                    local t = (v - min) / math.max(max - min, 1)
                    fill.Size = UDim2.new(t, 0, 1, 0)
                    handle.Position = UDim2.new(t, 0, 0.5, 0)
                    callback(v)
                end
                local function fromX(x)
                    local abs = track.AbsolutePosition.X
                    local sz = track.AbsoluteSize.X
                    if sz <= 0 then return end
                    local t = math.clamp((x - abs) / sz, 0, 1)
                    apply(min + t * (max - min))
                end

                track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        fromX(i.Position.X)
                        Spring(handle, 0.4, { Size = UDim2.fromOffset(20, 20) })
                    end
                end)
                Track(UserInputService.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                        fromX(i.Position.X)
                    end
                end))
                Track(UserInputService.InputEnded:Connect(function()
                    if dragging then
                        dragging = false
                        Tween(handle, 0.2, { Size = UDim2.fromOffset(16, 16) })
                    end
                end))

                table.insert(Registered, {
                    Type = "Element", Instance = row, Stroke = stroke,
                    AccentBar = accentBar, Label = lbl, Icon = elementIcon,
                })

                local obj = {}
                function obj:Set(v) apply(v) end
                function obj:Get()
                    return tonumber(string.gsub(valLbl.Text, "[^%d%.%-]", ""))
                end
                return obj
            end

            -- ─── BUTTON ───
            function Section:CreateButton(bConfig)
                local c = bConfig or {}
                local name     = c.Name or c.Title or "Button"
                local desc     = c.Desc or c.Description
                local callback = c.Callback or function() end
                local customColor = c.Color

                local totalHeight = desc and 66 or 52

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, totalHeight)
                btn.BackgroundColor3 = customColor or Theme.ElementBackground
                btn.BackgroundTransparency = 0.05
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.ClipsDescendants = true
                btn.ZIndex = 6
                btn.Parent = container
                Round(12, btn)

                MultiGradient(btn, {
                    Shade(customColor or Theme.ElementBackground, 0.08),
                    customColor or Theme.ElementBackground,
                    Shade(customColor or Theme.ElementBackground, -0.03),
                }, 135)

                local stroke = Outline(btn, Theme.Outline, 1, 0.5)
                register("Strokes", stroke)

                local accentBar = Instance.new("Frame")
                accentBar.Size = UDim2.new(0, 3, 1, -20)
                accentBar.Position = UDim2.new(0, 0, 0, 10)
                accentBar.BackgroundColor3 = Theme.Accent
                accentBar.BorderSizePixel = 0
                accentBar.ZIndex = 7
                accentBar.Parent = btn
                Round(2, accentBar)
                register("Fills", accentBar)

                local elementIcon = c.Icon and Img(btn, c.Icon, UDim2.fromOffset(18, 18), Theme.Icon, 0, 8) or nil
                local textLeft = 20
                if elementIcon then
                    elementIcon.Position = UDim2.new(0, 18, 0.5, -9)
                    textLeft = 46
                end

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Position = UDim2.new(0, textLeft, 0, desc and 10 or 0)
                titleLbl.Size = UDim2.new(1, -(textLeft + 16), 0, desc and 24 or totalHeight)
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = name
                titleLbl.Font = Enum.Font.GothamBold
                titleLbl.TextSize = 18
                titleLbl.TextColor3 = Theme.Text
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.ZIndex = 7
                titleLbl.Parent = btn

                if desc then
                    local dLbl = Instance.new("TextLabel")
                    dLbl.Position = UDim2.new(0, textLeft, 0, 34)
                    dLbl.Size = UDim2.new(1, -(textLeft + 16), 0, 22)
                    dLbl.BackgroundTransparency = 1
                    dLbl.Text = desc
                    dLbl.Font = Enum.Font.Gotham
                    dLbl.TextSize = 18
                    dLbl.TextColor3 = Theme.Placeholder
                    dLbl.TextXAlignment = Enum.TextXAlignment.Left
                    dLbl.ZIndex = 7
                    dLbl.Parent = btn
                end

                btn.MouseEnter:Connect(function()
                    Tween(btn, 0.2, { BackgroundTransparency = 0 })
                    Tween(stroke, 0.2, { Transparency = 0.1, Color = Theme.Accent })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, 0.2, { BackgroundTransparency = 0.05 })
                    Tween(stroke, 0.2, { Transparency = 0.5, Color = Theme.Outline })
                end)
                btn.MouseButton1Click:Connect(function() callback() end)
                Ripple(btn, Theme.Accent)
                PressFeedback(btn, 0.98)

                table.insert(Registered, {
                    Type = "Element", Instance = btn, Stroke = stroke,
                    AccentBar = accentBar, Label = titleLbl, Icon = elementIcon,
                })

                local obj = {}
                obj.Instance = btn
                return obj
            end

            -- ─── INPUT ───
            function Section:CreateInput(iConfig)
                local c = iConfig or {}
                local name        = c.Name or c.Title or "Input"
                local placeholder = c.Placeholder or "Type..."
                local default     = c.Default or c.Value or ""
                local callback    = c.Callback or function() end
                local multiline   = c.Multiline or false

                local rowH = multiline and 88 or 54
                local row, stroke, accentBar = RegisterRow(container, rowH)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 24, 0)
                lbl.Position = UDim2.new(0, 18, 0, multiline and 12 or 15)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
                local elementIcon = AttachIcon(row, c, lbl)

                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(multiline and 0.9 or 0.55, -14, 0, multiline and 60 or 36)
                boxFrame.Position = multiline and UDim2.new(0, 18, 0, 24) or UDim2.new(0.42, 0, 0.5, -18)
                boxFrame.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
                boxFrame.ZIndex = 7
                boxFrame.Parent = row
                Round(9, boxFrame)
                local boxStroke = Outline(boxFrame, Theme.Outline, 1, 0.5)

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -20, 1, 0)
                box.Position = UDim2.new(0, 10, 0, 0)
                box.BackgroundTransparency = 1
                box.Text = default
                box.PlaceholderText = placeholder
                box.PlaceholderColor3 = Theme.Placeholder
                box.TextColor3 = Theme.Text
                box.Font = Enum.Font.Gotham
                box.TextSize = 18
                box.ClearTextOnFocus = false
                box.TextWrapped = multiline
                box.TextXAlignment = Enum.TextXAlignment.Left
                box.TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
                box.MultiLine = multiline
                box.ZIndex = 8
                box.Parent = boxFrame

                box.Focused:Connect(function()
                    Tween(boxStroke, 0.2, { Color = Theme.Accent, Transparency = 0.1, Thickness = 1.5 })
                end)
                box.FocusLost:Connect(function(enter)
                    Tween(boxStroke, 0.2, { Color = Theme.Outline, Transparency = 0.5, Thickness = 1 })
                    callback(box.Text, enter)
                end)

                table.insert(Registered, {
                    Type = "Element", Instance = row, Stroke = stroke,
                    AccentBar = accentBar, Label = lbl, Icon = elementIcon,
                })

                local obj = {}
                function obj:Set(t) box.Text = t end
                function obj:Get() return box.Text end
                return obj
            end

            -- ─── DROPDOWN ───
            function Section:CreateDropdown(dConfig)
                local c = dConfig or {}
                local name     = c.Name or c.Title or "Dropdown"
                local options  = c.Options or {}
                local default  = c.Default or c.Value
                local callback = c.Callback or function() end
                local flag     = c.Flag

                local selected = default
                if flag then SZK.Flags[flag] = selected end

                local row, stroke, accentBar = RegisterRow(container, 54)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.Position = UDim2.new(0, 18, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
                local elementIcon = AttachIcon(row, c, lbl)

                local sel = Instance.new("TextButton")
                sel.Size = UDim2.new(0.55, -14, 0, 36)
                sel.Position = UDim2.new(0.42, 0, 0.5, -18)
                sel.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
                sel.Text = ""
                sel.AutoButtonColor = false
                sel.ZIndex = 7
                sel.Parent = row
                Round(9, sel)
                local selStroke = Outline(sel, Theme.Outline, 1, 0.5)

                local selLbl = Instance.new("TextLabel")
                selLbl.Size = UDim2.new(1, -40, 1, 0)
                selLbl.Position = UDim2.new(0, 12, 0, 0)
                selLbl.BackgroundTransparency = 1
                selLbl.Text = selected ~= nil and tostring(selected) or "Select..."
                selLbl.Font = Enum.Font.Gotham
                selLbl.TextSize = 18
                selLbl.TextColor3 = Theme.Text
                selLbl.TextXAlignment = Enum.TextXAlignment.Left
                selLbl.TextTruncate = Enum.TextTruncate.AtEnd
                selLbl.ZIndex = 8
                selLbl.Parent = sel

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.fromOffset(26, 26)
                arrow.Position = UDim2.new(1, -30, 0.5, -13)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▾"
                arrow.Font = Enum.Font.GothamBold
                arrow.TextSize = 18
                arrow.TextColor3 = Theme.Placeholder
                arrow.ZIndex = 8
                arrow.Parent = sel

                sel.MouseEnter:Connect(function()
                    Tween(selStroke, 0.15, { Color = Theme.Accent, Transparency = 0.2 })
                end)
                sel.MouseLeave:Connect(function()
                    Tween(selStroke, 0.15, { Color = Theme.Outline, Transparency = 0.5 })
                end)

                local list = Instance.new("ScrollingFrame")
                list.BackgroundColor3 = Theme.ElementBackground
                list.Visible = false
                list.ZIndex = 100
                list.ClipsDescendants = true
                list.BorderSizePixel = 0
                list.ScrollBarThickness = 3
                list.ScrollBarImageColor3 = Theme.Accent
                list.CanvasSize = UDim2.new(0, 0, 0, #options * 36 + 10)
                list.Parent = WindowGui
                Round(10, list)
                Outline(list, Theme.Accent, 1.5, 0.3)

                local listShadow = Instance.new("Frame")
                listShadow.BackgroundColor3 = Color3.new(0, 0, 0)
                listShadow.BackgroundTransparency = 0.65
                listShadow.BorderSizePixel = 0
                listShadow.Size = UDim2.new(1, 10, 1, 10)
                listShadow.Position = UDim2.new(0, -5, 0, -5)
                listShadow.ZIndex = -1
                listShadow.Parent = list
                Round(14, listShadow)

                local listPad = Instance.new("UIPadding")
                listPad.PaddingTop = UDim.new(0, 5)
                listPad.PaddingBottom = UDim.new(0, 5)
                listPad.PaddingLeft = UDim.new(0, 5)
                listPad.PaddingRight = UDim.new(0, 5)
                listPad.Parent = list

                for i, opt in ipairs(options) do
                    local txt = type(opt) == "table" and (opt.Text or opt.Value) or tostring(opt)
                    local val = type(opt) == "table" and (opt.Value or opt.Text) or opt
                    local ob = Instance.new("TextButton")
                    ob.Size = UDim2.new(1, 0, 0, 34)
                    ob.BackgroundColor3 = Shade(Theme.ElementBackground, 0.1)
                    ob.BackgroundTransparency = 1
                    ob.Text = "  " .. txt
                    ob.Font = Enum.Font.Gotham
                    ob.TextSize = 18
                    ob.TextColor3 = Theme.Text
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.AutoButtonColor = false
                    ob.ZIndex = 101
                    ob.Parent = list
                    Round(6, ob)

                    ob.MouseEnter:Connect(function()
                        Tween(ob, 0.12, { BackgroundTransparency = 0 })
                    end)
                    ob.MouseLeave:Connect(function()
                        Tween(ob, 0.12, { BackgroundTransparency = 1 })
                    end)
                    ob.MouseButton1Click:Connect(function()
                        selected = val
                        selLbl.Text = txt
                        list.Visible = false
                        if flag then SZK.Flags[flag] = selected end
                        callback(val)
                    end)
                end

                RegisterPopup(list, sel)
                sel.MouseButton1Click:Connect(function()
                    if list.Visible then list.Visible = false; return end
                    CloseAllPopups(sel)
                    task.wait()
                    local abs = sel.AbsolutePosition
                    local asz = sel.AbsoluteSize
                    local listH = math.clamp(#options * 36 + 10, 48, 280)
                    list.Size = UDim2.fromOffset(asz.X, listH)
                    list.Position = UDim2.fromOffset(abs.X, abs.Y + asz.Y + 4)
                    list.Visible = true
                end)

                table.insert(Registered, {
                    Type = "Element", Instance = row, Stroke = stroke,
                    AccentBar = accentBar, Label = lbl, Icon = elementIcon,
                })

                local obj = {}
                function obj:Set(v)
                    selected = v
                    selLbl.Text = tostring(v)
                    if flag then SZK.Flags[flag] = v end
                end
                function obj:Get() return selected end
                return obj
            end

            -- ─── KEYBIND ───
            function Section:CreateKeybind(kConfig)
                local c = kConfig or {}
                local name     = c.Name or c.Title or "Keybind"
                local default  = c.Default or c.Value
                local callback = c.Callback or function() end

                local row, stroke, accentBar = RegisterRow(container, 54)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -110, 1, 0)
                lbl.Position = UDim2.new(0, 18, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
                local elementIcon = AttachIcon(row, c, lbl)

                local keyBtn = Instance.new("TextButton")
                keyBtn.Size = UDim2.fromOffset(96, 34)
                keyBtn.Position = UDim2.new(1, -114, 0.5, -17)
                keyBtn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
                keyBtn.Text = default and default.Name or "None"
                keyBtn.Font = Enum.Font.GothamBold
                keyBtn.TextSize = 18
                keyBtn.TextColor3 = Theme.Text
                keyBtn.AutoButtonColor = false
                keyBtn.ZIndex = 7
                keyBtn.Parent = row
                Round(9, keyBtn)
                local keyStroke = Outline(keyBtn, Theme.Outline, 1, 0.5)

                local current = default
                local listening = false
                local conn

                keyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    keyBtn.Text = "..."
                    Tween(keyStroke, 0.2, { Color = Theme.Accent, Transparency = 0.1 })
                    if conn then conn:Disconnect() end
                    conn = Track(UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            current = input.KeyCode
                            keyBtn.Text = current.Name
                            listening = false
                            Tween(keyStroke, 0.2, { Color = Theme.Outline, Transparency = 0.5 })
                            if conn then conn:Disconnect() end
                            callback(current)
                        end
                    end))
                end)

                table.insert(Registered, {
                    Type = "Element", Instance = row, Stroke = stroke,
                    AccentBar = accentBar, Label = lbl, Icon = elementIcon,
                })

                local obj = {}
                function obj:Set(k)
                    current = k
                    keyBtn.Text = k and k.Name or "None"
                end
                function obj:Get() return current end
                return obj
            end

            -- ─── LABEL ───
            function Section:CreateLabel(text, iconKey)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 32)
                row.BackgroundTransparency = 1
                row.ZIndex = 6
                row.Parent = container

                local iconImg
                if iconKey then
                    iconImg = Img(row, iconKey, UDim2.fromOffset(18, 18), Theme.Placeholder, 0, 8)
                    if iconImg then iconImg.Position = UDim2.new(0, 4, 0.5, -9) end
                end

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, iconImg and -30 or -12, 1, 0)
                lbl.Position = UDim2.new(0, iconImg and 30 or 4, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = tostring(text)
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Placeholder
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
            end

            -- ─── PARAGRAPH ───
            function Section:CreateParagraph(text)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = Theme.ElementBackground
                row.BackgroundTransparency = 0.2
                row.ZIndex = 6
                row.Parent = container
                Round(12, row)
                Outline(row, Theme.Outline, 1, 0.5)
                MultiGradient(row, {
                    Shade(Theme.ElementBackground, 0.04),
                    Theme.ElementBackground,
                }, 135)

                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 16)
                pad.PaddingBottom = UDim.new(0, 16)
                pad.PaddingLeft = UDim.new(0, 18)
                pad.PaddingRight = UDim.new(0, 16)
                pad.Parent = row

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.BackgroundTransparency = 1
                lbl.Text = tostring(text)
                lbl.Font = Enum.Font.Gotham
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextWrapped = true
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
            end

            -- ─── DIVIDER ───
            function Section:CreateDivider()
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 16)
                row.BackgroundTransparency = 1
                row.Parent = container

                local line = Instance.new("Frame")
                line.Size = UDim2.new(1, -20, 0, 1)
                line.Position = UDim2.new(0, 10, 0.5, 0)
                line.BackgroundColor3 = Theme.Outline
                line.BackgroundTransparency = 0.5
                line.BorderSizePixel = 0
                line.ZIndex = 7
                line.Parent = row

                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Theme.Outline),
                    ColorSequenceKeypoint.new(0.5, Theme.Accent),
                    ColorSequenceKeypoint.new(1, Theme.Outline),
                })
                grad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.5, 0.3),
                    NumberSequenceKeypoint.new(1, 1),
                })
                grad.Parent = line
            end

            -- ─── PROGRESS BAR ───
            function Section:CreateProgressBar(pConfig)
                local c = pConfig or {}
                local name     = c.Name or c.Title or "Progress"
                local default  = c.Default or c.Value or 0
                local callback = c.Callback

                local row, stroke, accentBar = RegisterRow(container, 62)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -20, 0, 24)
                lbl.Position = UDim2.new(0, 18, 0, 8)
                lbl.BackgroundTransparency = 1
                lbl.Text = name
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Text
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row

                local valLbl = Instance.new("TextLabel")
                valLbl.Size = UDim2.fromOffset(78, 24)
                valLbl.Position = UDim2.new(1, -94, 0, 8)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(default) .. "%"
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextSize = 18
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.ZIndex = 7
                valLbl.Parent = row
                register("Labels", valLbl)

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -36, 0, 6)
                track.Position = UDim2.new(0, 18, 0, 42)
                track.BackgroundColor3 = Shade(Theme.ElementBackground, 0.1)
                track.ZIndex = 7
                track.Parent = row
                Round(3, track)

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new(default / 100, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Accent
                fill.ZIndex = 8
                fill.Parent = track
                Round(3, fill)
                Gradient(fill, Theme.Accent, Blend(Theme.Accent, Color3.new(1,1,1), 0.3), 0)
                register("Fills", fill)

                local obj = {}
                function obj:Set(v)
                    v = math.clamp(v, 0, 100)
                    valLbl.Text = tostring(math.floor(v)) .. "%"
                    Tween(fill, 0.3, { Size = UDim2.new(v / 100, 0, 1, 0) })
                    if callback then callback(v) end
                end
                function obj:Get()
                    return tonumber(string.match(valLbl.Text, "(%d+)"))
                end
                return obj
            end

            -- ─── BADGE ───
            function Section:CreateBadge(bConfig)
                local c = bConfig or {}
                local text  = c.Text or "Badge"
                local color = c.Color or Theme.Accent
                local icon  = c.Icon

                local badge = Instance.new("TextButton")
                badge.Size = UDim2.new(0, 0, 0, 32)
                badge.AutomaticSize = Enum.AutomaticSize.X
                badge.BackgroundColor3 = color
                badge.BackgroundTransparency = 0.85
                badge.Text = ""
                badge.AutoButtonColor = false
                badge.Parent = container
                Round(8, badge)
                Outline(badge, color, 1, 0.4)

                local bIcon = icon and Img(badge, icon, UDim2.fromOffset(14, 14), color, 0, 8) or nil

                local lbl = Instance.new("TextLabel")
                lbl.AutomaticSize = Enum.AutomaticSize.X
                lbl.Size = UDim2.new(0, 0, 1, 0)
                lbl.Position = UDim2.new(0, bIcon and 28 or 12, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = text
                lbl.Font = Enum.Font.GothamBold
                lbl.TextSize = 18
                lbl.TextColor3 = color
                lbl.ZIndex = 8
                lbl.Parent = badge

                if bIcon then
                    bIcon.Position = UDim2.new(0, 10, 0.5, -7)
                end

                local pad = Instance.new("UIPadding")
                pad.PaddingRight = UDim.new(0, 12)
                pad.Parent = badge
            end

            return Section
        end

        function Tab:CreateToggle(...)      return Tab:CreateSection(""):CreateToggle(...) end
        function Tab:CreateSlider(...)      return Tab:CreateSection(""):CreateSlider(...) end
        function Tab:CreateButton(...)      return Tab:CreateSection(""):CreateButton(...) end
        function Tab:CreateInput(...)       return Tab:CreateSection(""):CreateInput(...) end
        function Tab:CreateDropdown(...)    return Tab:CreateSection(""):CreateDropdown(...) end
        function Tab:CreateKeybind(...)     return Tab:CreateSection(""):CreateKeybind(...) end
        function Tab:CreateLabel(...)       return Tab:CreateSection(""):CreateLabel(...) end
        function Tab:CreateParagraph(...)   return Tab:CreateSection(""):CreateParagraph(...) end
        function Tab:CreateDivider()        return Tab:CreateSection(""):CreateDivider() end
        function Tab:CreateProgressBar(...) return Tab:CreateSection(""):CreateProgressBar(...) end
        function Tab:CreateBadge(...)       return Tab:CreateSection(""):CreateBadge(...) end

        return Tab
    end

    -- ═══ API DE WINDOW ═══
    function Window:SetSize(newSize)
        if typeof(newSize) == "Vector2" then
            size = Vector2.new(
                math.clamp(newSize.X, MIN_SIZE.X, MAX_SIZE.X),
                math.clamp(newSize.Y, MIN_SIZE.Y, MAX_SIZE.Y)
            )
            MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
            RecalculateScale()
        end
    end

    function Window:SetMinSize(v)
        if typeof(v) == "Vector2" then
            MIN_SIZE = v
            SizeConstraint.MinSize = v
        end
    end

    function Window:SetMaxSize(v)
        if typeof(v) == "Vector2" then
            MAX_SIZE = v
            SizeConstraint.MaxSize = v
        end
    end

    function Window:SetTheme(name)
        local t = SZK.Themes[name]
        if t then
            Theme = t
            SZK.CurrentTheme = t
            MainFrame.BackgroundColor3 = t.Background
            Overlay.BackgroundColor3 = t.Background
            HeaderBar.BackgroundColor3 = t.Background2
            TitleLabel.TextColor3 = t.Text
            DescLabel.TextColor3 = t.Placeholder
            MainStroke.Color = t.Accent
            OuterGlow.BackgroundColor3 = t.Accent
            versionBadge.BackgroundColor3 = t.Accent
            versionLbl.TextColor3 = t.Accent
            for _, l in ipairs(gripLines) do l.BackgroundColor3 = t.Accent end
            for _, k in ipairs(ThemedElements.Knobs) do k.BackgroundColor3 = t.Background end

            -- Botón flotante
            FloatBtn.BackgroundColor3 = t.Background2
            fbStroke.Color = t.Accent
            fbInnerStroke.Color = Blend(t.Accent, Color3.new(1, 1, 1), 0.4)
            crossH.BackgroundColor3 = t.Accent
            crossV.BackgroundColor3 = t.Accent
            FBLabel.TextColor3 = t.Text

            -- Scans
            for _, s in ipairs(ThemedElements.Scans) do
                s.scan.BackgroundColor3 = t.Accent
                s.glow.BackgroundColor3 = t.Accent
                if s.grad then
                    s.grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, t.Accent),
                        ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, t.Accent),
                    })
                end
                if s.glowGrad then
                    s.glowGrad.Color = ColorSequence.new(t.Accent, t.Accent)
                end
            end
        end
    end

    function Window:SetBackgroundImage(src, transparency)
        local resolved = NormalizeImageSource(src or "")
        BgImage.Image = resolved
        BgImage.Visible = resolved ~= ""
        hasBg = resolved ~= ""
        if transparency then BgImage.ImageTransparency = transparency end
        Overlay.BackgroundTransparency = hasBg and 0.35 or 0.02
    end

    function Window:Minimize() CloseWindow() end
    function Window:Restore() OpenWindow() end

    function Window:Destroy()
        scansEnabled = false
        for _, s in ipairs(activeScans) do s.enabled = false end
        for _, c in ipairs(Connections) do
            pcall(function() c:Disconnect() end)
        end
        for i, w in ipairs(SZK.Windows) do
            if w == self then
                table.remove(SZK.Windows, i)
                break
            end
        end
        pcall(function() WindowGui:Destroy() end)
    end

    MainFrame.Visible = true
    MainFrame.BackgroundTransparency = 0.3
    MainFrame.Size = UDim2.fromOffset(size.X * 0.9, size.Y * 0.9)
    Tween(MainFrame, 0.45, {
        Size = UDim2.fromOffset(size.X, size.Y),
        BackgroundTransparency = 0
    }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    table.insert(SZK.Windows, Window)
    return Window
end

SZK.New = SZK.CreateWindow

function SZK:GetFlag(name) return SZK.Flags[name] end
function SZK:SetFlag(name, v) SZK.Flags[name] = v end
function SZK:Get(name) return SZK.Flags[name] end
function SZK:Set(name, val) SZK.Flags[name] = val end

return SZK
