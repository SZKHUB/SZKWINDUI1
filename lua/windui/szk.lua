-- ═══════════════════════════════════════════════════════════════
--  FLUID UI v2.2 — By SZK
--  Modal de confirmación de cierre + notificación
-- ═══════════════════════════════════════════════════════════════
local SZK = { Themes = {}, Windows = {}, Flags = {}, Icons = {}, CurrentTheme = nil, ConfigFolder = "SZK_Configs" }

local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local HttpService        = game:GetService("HttpService")
local Players            = game:GetService("Players")
local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer and LocalPlayer:GetMouse()

SZK.IconSources = {
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS/refs/heads/main/WINDUI/ICON1",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS1/refs/heads/main/ICONS/WINDUI2",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/ICONS2/refs/heads/main/SZK/WINDUI/ICONS3",
    "https://raw.githubusercontent.com/ONYXHUB-X-SZK/SZKICONS3/refs/heads/main/SZK/ICONS4",
}

function SZK:LoadIcons()
    for _, url in ipairs(SZK.IconSources) do
        local ok, data = pcall(function() return loadstring(game:HttpGet(url))() end)
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
        for _, a in ipairs(allowed) do if a == ext then return ext end end
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
                local assetOk, assetId = pcall(function() return getcustomasset(cachePath) end)
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
        if string.match(key, "^https?://") then return NormalizeImageSource(key), true end
        if SZK.Icons[key] then return NormalizeImageSource(SZK.Icons[key]), true end
        return key, false
    end
    return "", false
end

local function Round(radius, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function Outline(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60, 60, 65)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function Tween(obj, t, props, style, dir)
    local anim = TweenService:Create(obj, TweenInfo.new(t or 0.3, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
    anim:Play()
    return anim
end

local function Shade(color, amount)
    if typeof(color) ~= "Color3" then return Color3.fromRGB(20, 20, 24) end
    amount = amount or 0.07
    local lum = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
    if lum > 0.5 then
        return Color3.new(math.max(0, color.R - amount), math.max(0, color.G - amount), math.max(0, color.B - amount))
    end
    return Color3.new(math.min(1, color.R + amount), math.min(1, color.G + amount), math.min(1, color.B + amount))
end

local function Ripple(button, color)
    button.ClipsDescendants = true
    button.MouseButton1Click:Connect(function()
        local mx, my = Mouse and Mouse.X or 0, Mouse and Mouse.Y or 0
        local circle = Instance.new("Frame")
        circle.BackgroundColor3 = color or Color3.new(1, 1, 1)
        circle.BackgroundTransparency = 0.7
        circle.BorderSizePixel = 0
        circle.AnchorPoint = Vector2.new(0.5, 0.5)
        circle.ZIndex = (button.ZIndex or 1) + 5
        circle.Size = UDim2.fromOffset(0, 0)
        circle.Position = UDim2.fromOffset(mx - button.AbsolutePosition.X, my - button.AbsolutePosition.Y)
        circle.Parent = button
        Round(200, circle)
        local target = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.8
        Tween(circle, 0.5, { Size = UDim2.fromOffset(target, target), BackgroundTransparency = 1 })
        task.delay(0.5, function() if circle.Parent then circle:Destroy() end end)
    end)
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
    if img and not img:GetAttribute("SZKCustomIcon") then img.ImageColor3 = color end
end

local function BuildTheme(name, accent, outline, toggle, slider, text, placeholder, bg, elemBg, icon)
    return {
        Name = name,
        Accent = Color3.fromHex(accent),
        Outline = Color3.fromHex(outline or accent),
        Text = Color3.fromHex(text or "#EBEBEB"),
        Placeholder = Color3.fromHex(placeholder or "#919191"),
        Icon = Color3.fromHex(icon or outline or accent),
        Toggle = Color3.fromHex(toggle or accent),
        Slider = Color3.fromHex(slider or accent),
        ElementBackground = Color3.fromHex(elemBg or "#16161C"),
        Background = Color3.fromHex(bg or "#0A0A0C"),
        Background2 = Color3.fromHex(elemBg or "#16161C"),
    }
end

SZK.Themes.SZK = {
    Name = "SZK",
    Accent = Color3.fromRGB(255, 255, 255),
    Accent2 = Color3.fromRGB(20, 20, 20),
    Outline = Color3.fromRGB(60, 60, 70),
    Text = Color3.fromRGB(250, 250, 255),
    Placeholder = Color3.fromRGB(150, 150, 160),
    Icon = Color3.fromRGB(255, 255, 255),
    Toggle = Color3.fromRGB(255, 255, 255),
    Slider = Color3.fromRGB(255, 255, 255),
    ElementBackground = Color3.fromRGB(22, 22, 28),
    Background = Color3.fromRGB(8, 8, 10),
    Background2 = Color3.fromRGB(16, 16, 20),
    Animated = true,
}

SZK.Themes["AMBIENT"]        = BuildTheme("AMBIENT",        "#E8B4B8", "#F4C2C6", "#E8B4B8", "#F4C2C6", "#F8E8E9", "#D8A8A9", "#000000", "#0A0A0A", "#F4C2C6")
SZK.Themes["SOFT MIST"]      = BuildTheme("SOFT MIST",      "#D4E0E6", "#E8EEF0", "#D4E0E6", "#E8EEF0", "#F5F8F9", "#B8C0C4", "#000000", "#0A0A0A", "#E8EEF0")
SZK.Themes["WARM BLUSH"]     = BuildTheme("WARM BLUSH",     "#F5D0C5", "#F8E0D6", "#F5D0C5", "#F8E0D6", "#FFF5F2", "#E8B4B0", "#000000", "#0A0A0A", "#F8E0D6")
SZK.Themes["SUNSET HUE"]     = BuildTheme("SUNSET HUE",     "#E8A87C", "#F4C19A", "#E8A87C", "#F4C19A", "#FFF9E6", "#D4A88A", "#000000", "#0A0A0A", "#F4C19A")
SZK.Themes["SOFT GOLDEN"]    = BuildTheme("SOFT GOLDEN",    "#E8D5B7", "#F4E0C8", "#E8D5B7", "#F4E0C8", "#FFF8E1", "#D8C0A0", "#000000", "#0A0A0A", "#F4E0C8")
SZK.Themes["PEACH BLOSSOM"]  = BuildTheme("PEACH BLOSSOM",  "#F4C1A8", "#F8D9C4", "#F4C1A8", "#F8D9C4", "#FFF8F0", "#E8B4A8", "#000000", "#0A0A0A", "#F8D9C4")
SZK.Themes["LAVENDER MIST"]  = BuildTheme("LAVENDER MIST",  "#E8D0E8", "#F4E0F0", "#E8D0E8", "#F4E0F0", "#FAF5FF", "#D8B8D0", "#000000", "#0A0A0A", "#F4E0F0")
SZK.Themes["SEAFOAM SOFT"]   = BuildTheme("SEAFOAM SOFT",   "#C8E8E0", "#D8F0E8", "#C8E8E0", "#D8F0E8", "#F0F8F5", "#A8C8B8", "#000000", "#0A0A0A", "#D8F0E8")
SZK.Themes["SOFT LEMON"]     = BuildTheme("SOFT LEMON",     "#F4E8B8", "#F8F4C8", "#F4E8B8", "#F8F4C8", "#FFF8E1", "#D8D0A8", "#000000", "#0A0A0A", "#F8F4C8")
SZK.Themes["SOFT ROSE"]      = BuildTheme("SOFT ROSE",      "#F4B8C8", "#F8D0D8", "#F4B8C8", "#F8D0D8", "#FFF0F5", "#D8A8B8", "#000000", "#0A0A0A", "#F8D0D8")
SZK.Themes["PEACH"]          = BuildTheme("PEACH",          "#FFDAB9", "#FFCBA4", "#FFDAB9", "#FFCBA4", "#FFF5EE", "#FFB6C1", "#000000", "#0A0A0A", "#FFCBA4")
SZK.Themes["VENOM"]          = BuildTheme("VENOM",          "#228B22", "#32CD32", "#228B22", "#32CD32", "#E8F5E9", "#8BC34A", "#000000", "#0A0A0A", "#32CD32")
SZK.Themes["CYBER"]          = BuildTheme("CYBER",          "#00D4FF", "#4ECFFF", "#00D4FF", "#4ECFFF", "#E0F7FA", "#81D4FA", "#000000", "#0A0A0A", "#4ECFFF")
SZK.Themes["PURPLE"]         = BuildTheme("PURPLE",         "#9B59B6", "#DDA0DD", "#9B59B6", "#DDA0DD", "#F5F0FF", "#BCA3D3", "#000000", "#0A0A0A", "#DDA0DD")
SZK.Themes["GOLD"]           = BuildTheme("GOLD",           "#FFD700", "#FFF44F", "#FFD700", "#FFF44F", "#FFF8E1", "#DAA520", "#000000", "#0A0A0A", "#FFF44F")
SZK.Themes["NEON"]           = BuildTheme("NEON",           "#FF00FF", "#FF69B4", "#FF00FF", "#FF69B4", "#F0F0FF", "#BA55D3", "#000000", "#0A0A0A", "#FF69B4")
SZK.Themes["OCEAN"]          = BuildTheme("OCEAN",          "#1E90FF", "#87CEEB", "#1E90FF", "#87CEEB", "#E6F3FF", "#4682B4", "#000000", "#0A0A0A", "#87CEEB")
SZK.Themes["ROSE"]           = BuildTheme("ROSE",           "#E91E63", "#F48FB1", "#E91E63", "#F48FB1", "#FCE4EC", "#F06292", "#000000", "#0A0A0A", "#F48FB1")
SZK.Themes["FOREST"]         = BuildTheme("FOREST",         "#228B22", "#2E8B57", "#228B22", "#2E8B57", "#F0FFF0", "#3CB371", "#000000", "#0A0A0A", "#2E8B57")
SZK.Themes["EMERALD"]        = BuildTheme("EMERALD",        "#50C878", "#7FFF00", "#50C878", "#7FFF00", "#F0FFF0", "#32CD32", "#000000", "#0A0A0A", "#7FFF00")
SZK.Themes["CORAL"]          = BuildTheme("CORAL",          "#FF7F50", "#FF6347", "#FF7F50", "#FF6347", "#FFF0F0", "#FA8072", "#000000", "#0A0A0A", "#FF6347")
SZK.Themes["LAVENDER"]       = BuildTheme("LAVENDER",       "#E6E6FA", "#DDA0DD", "#E6E6FA", "#DDA0DD", "#F8F1FF", "#BA55D3", "#000000", "#0A0A0A", "#DDA0DD")
SZK.Themes["COPPER"]         = BuildTheme("COPPER",         "#B87333", "#CD853F", "#B87333", "#CD853F", "#FFF8DC", "#DAA520", "#000000", "#0A0A0A", "#CD853F")
SZK.Themes["SAPPHIRE"]       = BuildTheme("SAPPHIRE",       "#0F52BA", "#4169E1", "#0F52BA", "#4169E1", "#F0F8FF", "#1E90FF", "#000000", "#0A0A0A", "#4169E1")
SZK.Themes["LIME"]           = BuildTheme("LIME",           "#32CD32", "#ADFF2F", "#32CD32", "#ADFF2F", "#F0FFF0", "#7CFC00", "#000000", "#0A0A0A", "#ADFF2F")
SZK.Themes["INDIGO"]         = BuildTheme("INDIGO",         "#4B0082", "#6A0DAD", "#4B0082", "#6A0DAD", "#F0F0FF", "#9370DB", "#000000", "#0A0A0A", "#6A0DAD")
SZK.Themes["AMBER"]          = BuildTheme("AMBER",          "#FFBF00", "#FFC000", "#FFBF00", "#FFC000", "#FFF8E1", "#FFA500", "#000000", "#0A0A0A", "#FFC000")
SZK.Themes["DARK"]           = BuildTheme("DARK",           "#2C2C2C", "#555555", "#2C2C2C", "#555555", "#1C1C1C", "#3A3A3A", "#FFFFFF", "#111111", "#555555")
SZK.Themes["SLATE"]          = BuildTheme("SLATE",          "#2F2F2F", "#4A4A4A", "#2F2F2F", "#4A4A4A", "#F5F5F5", "#696969", "#000000", "#0A0A0A", "#4A4A4A")
SZK.Themes["MIDNIGHT"]       = BuildTheme("MIDNIGHT",       "#1C1C1C", "#2F2F2F", "#1C1C1C", "#2F2F2F", "#E8E8E8", "#4A4A4A", "#FFFFFF", "#0A0A0A", "#2F2F2F")
SZK.Themes["BLOOD"]          = BuildTheme("BLOOD",          "#8B0000", "#A52A2A", "#8B0000", "#A52A2A", "#FFEBEE", "#CD5C5C", "#FFFFFF", "#0A0A0A", "#A52A2A")
SZK.Themes["COCOA"]          = BuildTheme("COCOA",          "#8B4513", "#A0522D", "#8B4513", "#A0522D", "#FAF0E6", "#CD853F", "#FFFFFF", "#0A0A0A", "#A0522D")
SZK.Themes["LIGHT"]          = BuildTheme("LIGHT",          "#FFFFFF", "#F0F0F0", "#FFFFFF", "#F0F0F0", "#FAFAFA", "#E0E0E0", "#000000", "#FFFFFF", "#F0F0F0")

SZK.ThemeOrder = {
    "SZK",
    "AMBIENT", "SOFT MIST", "WARM BLUSH", "SUNSET HUE", "SOFT GOLDEN",
    "PEACH BLOSSOM", "LAVENDER MIST", "SEAFOAM SOFT", "SOFT LEMON", "SOFT ROSE", "PEACH",
    "VENOM", "CYBER", "PURPLE", "GOLD", "NEON", "OCEAN", "ROSE", "FOREST",
    "EMERALD", "CORAL", "LAVENDER", "COPPER", "SAPPHIRE", "LIME", "INDIGO", "AMBER",
    "DARK", "SLATE", "MIDNIGHT", "BLOOD", "COCOA",
    "LIGHT",
}

local Theme = SZK.Themes.SZK
SZK.CurrentTheme = Theme

local ThemedElements = { Strokes = {}, Fills = {}, Labels = {}, Buttons = {}, Gradients = {}, Scans = {}, Knobs = {} }
local function registerStroke(s) table.insert(ThemedElements.Strokes, s) end
local function registerFill(f) table.insert(ThemedElements.Fills, f) end
local function registerLabel(l) table.insert(ThemedElements.Labels, l) end
local function registerButton(b) table.insert(ThemedElements.Buttons, b) end
local function registerGradient(g) table.insert(ThemedElements.Gradients, g) end
local function registerKnob(k) table.insert(ThemedElements.Knobs, k) end

local animPhase = 0
local accum = 0
local RATE = 1 / 60

local function applyBWColors(phase)
    if Theme.Name ~= "SZK" then return end
    local t = (math.sin(phase) + 1) / 2
    local c1 = Color3.fromRGB(math.floor(60 + t * 195), math.floor(60 + t * 195), math.floor(60 + t * 195))
    local c2 = Color3.fromRGB(math.floor(255 - t * 195), math.floor(255 - t * 195), math.floor(255 - t * 195))

    Theme.Accent = c1
    Theme.Accent2 = c2
    Theme.Toggle = c1
    Theme.Slider = c1
    Theme.Icon = c1

    for _, s in ipairs(ThemedElements.Strokes) do s.Color = c1 end
    for _, f in ipairs(ThemedElements.Fills) do f.BackgroundColor3 = c1 end
    for _, l in ipairs(ThemedElements.Labels) do l.TextColor3 = c1 end
    for _, b in ipairs(ThemedElements.Buttons) do
        b.BackgroundColor3 = c1
        b.TextColor3 = c2
    end
    for _, g in ipairs(ThemedElements.Gradients) do g.Color = ColorSequence.new(c1, c2) end
    for _, s in ipairs(ThemedElements.Scans) do
        s.scan.BackgroundColor3 = c1
        if s.grad then
            s.grad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, c1),
                ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
                ColorSequenceKeypoint.new(1, c1),
            })
        end
    end
    for _, k in ipairs(ThemedElements.Knobs) do
        k.BackgroundColor3 = c2
    end
end

RunService.Heartbeat:Connect(function(dt)
    accum = accum + dt
    if accum < RATE then return end
    local frameDt = accum
    accum = 0
    animPhase = animPhase + frameDt * 1.6
    applyBWColors(animPhase)
end)

local parent = (gethui and gethui()) or game:GetService("CoreGui")

local MainGui = Instance.new("ScreenGui")
MainGui.Name = "SZKLibrary"
MainGui.ResetOnSpawn = false
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
MainGui.DisplayOrder = 999
MainGui.Parent = parent

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Size = UDim2.new(0, 340, 1, -20)
NotificationHolder.Position = UDim2.new(1, -350, 0, 10)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.ZIndex = 100
NotificationHolder.Parent = MainGui

local NotifList = Instance.new("UIListLayout")
NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifList.Padding = UDim.new(0, 10)
NotifList.Parent = NotificationHolder

function SZK:Notify(config)
    config = config or {}
    local title    = config.Title or "Notificación"
    local content  = config.Content or config.Text or ""
    local duration = config.Duration or 4
    local ntype    = config.Type or "Info"
    local buttons  = config.Buttons
    local iconKey  = config.Icon

    local colors = {
        Success = Color3.fromRGB(70, 220, 140),
        Error   = Color3.fromRGB(255, 80, 80),
        Warning = Color3.fromRGB(255, 176, 32),
        Info    = Color3.fromRGB(90, 150, 255),
    }
    local accent = colors[ntype] or colors.Info

    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(1, 0, 0, 0)
    slot.BackgroundTransparency = 1
    slot.ClipsDescendants = false
    slot.Parent = NotificationHolder

    local frame = Instance.new("Frame")
    frame.Position = UDim2.new(1, 60, 0, 0)
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Theme.ElementBackground
    frame.BackgroundTransparency = 0.05
    frame.ClipsDescendants = true
    frame.Parent = slot
    Round(14, frame)
    local stroke = Outline(frame, accent, 1.4, 0.25)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 3, 1, -20)
    bar.Position = UDim2.new(0, 0, 0, 10)
    bar.BackgroundColor3 = accent
    bar.ZIndex = 2
    bar.BorderSizePixel = 0
    bar.Parent = frame
    Round(2, bar)

    local iconImg
    local resolvedCheck = iconKey and ResolveIcon(iconKey) or ""
    if resolvedCheck ~= "" then
        local iconBadge = Instance.new("Frame")
        iconBadge.Size = UDim2.fromOffset(40, 40)
        iconBadge.Position = UDim2.new(0, 14, 0, 14)
        iconBadge.BackgroundColor3 = accent
        iconBadge.BackgroundTransparency = 0.82
        iconBadge.ZIndex = 3
        iconBadge.Parent = frame
        Round(10, iconBadge)
        Outline(iconBadge, accent, 1, 0.6)

        iconImg = Img(iconBadge, iconKey, UDim2.fromOffset(22, 22), accent, 0, 4)
        if iconImg then
            iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
            iconImg.Position = UDim2.fromScale(0.5, 0.5)
        end
    end

    local textLeft = iconImg and 66 or 22

    local tLbl = Instance.new("TextLabel")
    tLbl.Text = title
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 18
    tLbl.TextColor3 = Theme.Text
    tLbl.Position = UDim2.new(0, textLeft, 0, 16)
    tLbl.Size = UDim2.new(1, -(textLeft + 16), 0, 24)
    tLbl.BackgroundTransparency = 1
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = frame

    local cLbl = Instance.new("TextLabel")
    cLbl.Text = content
    cLbl.Font = Enum.Font.Gotham
    cLbl.TextSize = 18
    cLbl.TextColor3 = Theme.Placeholder
    cLbl.Position = UDim2.new(0, textLeft, 0, 42)
    cLbl.Size = UDim2.new(1, -(textLeft + 16), 0, 40)
    cLbl.BackgroundTransparency = 1
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.TextYAlignment = Enum.TextYAlignment.Top
    cLbl.TextWrapped = true
    cLbl.Parent = frame

    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 2)
    progressBg.Position = UDim2.new(0, 0, 1, -2)
    progressBg.BackgroundColor3 = accent
    progressBg.BackgroundTransparency = 0.75
    progressBg.BorderSizePixel = 0
    progressBg.ZIndex = 4
    progressBg.Parent = frame

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = accent
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 5
    progressFill.Parent = progressBg

    if buttons and #buttons > 0 then
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -34, 0, 32)
        row.Position = UDim2.new(0, textLeft, 0, 84)
        row.BackgroundTransparency = 1
        row.Parent = frame
        local rl = Instance.new("UIListLayout")
        rl.FillDirection = Enum.FillDirection.Horizontal
        rl.Padding = UDim.new(0, 6)
        rl.Parent = row
        for _, b in ipairs(buttons) do
            local nb = Instance.new("TextButton")
            nb.Size = UDim2.fromOffset(0, 30)
            nb.AutomaticSize = Enum.AutomaticSize.X
            nb.BackgroundColor3 = b.Primary and accent or Shade(Theme.ElementBackground, 0.1)
            nb.Text = "  " .. (b.Text or "Ok") .. "  "
            nb.Font = Enum.Font.GothamBold
            nb.TextSize = 18
            nb.TextColor3 = Theme.Text
            nb.AutoButtonColor = false
            nb.Parent = row
            Round(12, nb)
            nb.MouseButton1Click:Connect(function()
                if b.Callback then pcall(b.Callback) end
                if b.CloseOnClick ~= false and slot.Parent then slot:Destroy() end
            end)
        end
    end

    local cardHeight = (buttons and #buttons > 0) and 126 or 96
    Tween(slot, 0.35, { Size = UDim2.new(1, 0, 0, cardHeight) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(frame, 0.4, { Position = UDim2.new(0, 0, 0, 0) })

    if not (buttons and #buttons > 0) then
        Tween(progressFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)
        task.delay(duration, function()
            if not slot.Parent then return end
            Tween(frame, 0.3, { Position = UDim2.new(1, 60, 0, 0) }, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            local out = Tween(slot, 0.3, { Size = UDim2.new(1, 0, 0, 0) })
            out.Completed:Connect(function() slot:Destroy() end)
        end)
    end
end

function SZK:Success(t, c, d) return SZK:Notify({Title = t or "Success", Content = c or "", Type = "Success", Duration = d or 3.5, Icon = "badge-check"}) end
function SZK:Error(t, c, d)   return SZK:Notify({Title = t or "Error", Content = c or "", Type = "Error", Duration = d or 4, Icon = "alert-circle"}) end
function SZK:Warn(t, c, d)    return SZK:Notify({Title = t or "Warning", Content = c or "", Type = "Warning", Duration = d or 3.5, Icon = "alert-triangle"}) end
function SZK:Info(t, c, d)    return SZK:Notify({Title = t or "Info", Content = c or "", Type = "Info", Duration = d or 3.5, Icon = "info"}) end

function SZK:CreateWindow(config)
    config = config or {}
    local title        = config.Title or "FLUID"
    local description  = config.Description or "AUTHOR SZK"
    local size         = config.Size or Vector2.new(480, 420)
    if typeof(size) == "UDim2" then size = Vector2.new(size.X.Offset, size.Y.Offset) end
    local toggleKey    = config.ToggleKey or Enum.KeyCode.RightShift
    local themeName    = config.Theme or "SZK"
    local logoKey      = config.Logo or config.Icon
    local bgImage      = config.BackgroundImage
    local bgTrans      = math.clamp(config.BackgroundImageTransparency or 0.4, 0, 1)
    local showThemeSel = config.ThemeSelector ~= false
    local openBtnIcon  = config.OpenButtonIcon
    local openBtnText  = config.OpenButtonText or "RysHub"

    local MIN_SIZE = Vector2.new(380, 300)
    local MAX_SIZE = Vector2.new(1200, 800)
    if config.MinSize then MIN_SIZE = config.MinSize end
    if config.MaxSize then MAX_SIZE = config.MaxSize end

    Theme = SZK.Themes[themeName] or SZK.Themes.SZK
    SZK.CurrentTheme = Theme

    local resolvedBg = bgImage and NormalizeImageSource(bgImage) or ""
    local hasBg = resolvedBg ~= ""

    local Registered = {}
    local OpenPopups = {}
    local Connections = {}

    local function Track(conn) table.insert(Connections, conn); return conn end

    local function CloseAllPopups(except)
        for _, p in ipairs(OpenPopups) do
            if p.Frame.Visible and p.Trigger ~= except then p.Frame.Visible = false end
        end
    end
    local function RegisterPopup(frame, trigger)
        table.insert(OpenPopups, { Frame = frame, Trigger = trigger })
    end

    local WindowGui = Instance.new("ScreenGui")
    WindowGui.Name = "SZKWindow"
    WindowGui.ResetOnSpawn = false
    WindowGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    WindowGui.DisplayOrder = MainGui.DisplayOrder
    WindowGui.Parent = parent

    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.fromOffset(size.X, size.Y)
    MainFrame.Position = UDim2.fromScale(0.5, 0.5)
    MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.Visible = false
    MainFrame.Parent = WindowGui
    Round(14, MainFrame)

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
        local target = math.clamp(math.min(scaleX, scaleY, 1), 0.5, 1)
        WindowScale.Scale = target
    end
    RecalculateScale()
    Track(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(RecalculateScale))

    local OuterGlow = Instance.new("Frame")
    OuterGlow.Size = UDim2.new(1, 0, 1, 0)
    OuterGlow.BackgroundColor3 = Theme.Accent
    OuterGlow.BackgroundTransparency = 0.94
    OuterGlow.BorderSizePixel = 0
    OuterGlow.ZIndex = 0
    OuterGlow.Parent = MainFrame
    Round(16, OuterGlow)

    local MainStroke = Outline(MainFrame, Theme.Accent, 1.5, 0.35)
    registerStroke(MainStroke)

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
    local OverlayGrad = Instance.new("UIGradient")
    OverlayGrad.Color = ColorSequence.new(Shade(Theme.Background, 0.06), Theme.Background)
    OverlayGrad.Rotation = 135
    OverlayGrad.Parent = Overlay

    -- ═══════════════════════════════════════════════════════════
    --  SCAN EFFECT
    -- ═══════════════════════════════════════════════════════════
    local scansEnabled = true

    local function CreateScan(orientation, startPos, endPos, length, travelTime, thickness, delayOffset)
        local scan = Instance.new("Frame")
        scan.BorderSizePixel = 0
        scan.BackgroundColor3 = Theme.Accent
        scan.ZIndex = 8
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
            ColorSequenceKeypoint.new(0, Theme.Accent),
            ColorSequenceKeypoint.new(0.5, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Theme.Accent),
        })
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.15, 0),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(0.85, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        grad.Parent = scan

        local glow = Instance.new("Frame")
        glow.BorderSizePixel = 0
        glow.BackgroundColor3 = Theme.Accent
        glow.BackgroundTransparency = 0.6
        glow.ZIndex = 7
        glow.Parent = MainFrame

        if orientation == "h" then
            glow.Size = UDim2.new(0, length, 0, thickness * 3)
            glow.Position = startPos
        else
            glow.Size = UDim2.new(0, thickness * 3, 0, length)
            glow.Position = startPos
        end

        local glowGrad = Instance.new("UIGradient")
        glowGrad.Rotation = orientation == "h" and 0 or 90
        glowGrad.Color = ColorSequence.new(Theme.Accent, Theme.Accent)
        glowGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        })
        glowGrad.Parent = glow

        registerFill(scan)
        registerFill(glow)
        table.insert(ThemedElements.Scans, { scan = scan, grad = grad })

        task.spawn(function()
            if delayOffset and delayOffset > 0 then task.wait(delayOffset) end
            while scan and scan.Parent and scansEnabled do
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

    CreateScan("h", UDim2.new(0, 0, 0, 0),        UDim2.new(1, -140, 0, 0), 140, 1.6, 3, 0)
    CreateScan("h", UDim2.new(1, -140, 0, 0),     UDim2.new(0, 0, 0, 0),     140, 1.8, 3, 0.4)
    CreateScan("h", UDim2.new(0, 0, 1, -3),       UDim2.new(1, -140, 1, -3), 140, 1.7, 3, 0.8)
    CreateScan("h", UDim2.new(1, -140, 1, -3),    UDim2.new(0, 0, 1, -3),    140, 1.9, 3, 1.2)
    CreateScan("h", UDim2.new(0, 0, 0.5, -1.5),   UDim2.new(1, -160, 0.5, -1.5), 160, 2.4, 2, 0.6)

    CreateScan("v", UDim2.new(0, 0, 0, 0),        UDim2.new(0, 0, 1, -110),   110, 1.7, 3, 0.2)
    CreateScan("v", UDim2.new(0, 0, 1, -110),     UDim2.new(0, 0, 0, 0),      110, 1.9, 3, 0.7)
    CreateScan("v", UDim2.new(1, -3, 0, 0),       UDim2.new(1, -3, 1, -110),  110, 1.8, 3, 1.1)
    CreateScan("v", UDim2.new(1, -3, 1, -110),    UDim2.new(1, -3, 0, 0),     110, 2.0, 3, 0.3)
    CreateScan("v", UDim2.new(0.5, -1.5, 0, 0),   UDim2.new(0.5, -1.5, 1, -130), 130, 2.5, 2, 0.9)

    -- ═══ HEADER ═══
    local HeaderBar = Instance.new("Frame")
    HeaderBar.Size = UDim2.new(1, 0, 0, 52)
    HeaderBar.BackgroundColor3 = Theme.Background2
    HeaderBar.BackgroundTransparency = 0.15
    HeaderBar.BorderSizePixel = 0
    HeaderBar.ZIndex = 5
    HeaderBar.Parent = MainFrame
    Round(14, HeaderBar)

    local headerGrad = Instance.new("UIGradient")
    headerGrad.Color = ColorSequence.new(Shade(Theme.Background2, 0.08), Shade(Theme.Background2, -0.04))
    headerGrad.Rotation = 90
    headerGrad.Parent = HeaderBar

    local AvatarHolder = Instance.new("Frame")
    AvatarHolder.Size = UDim2.fromOffset(36, 36)
    AvatarHolder.Position = UDim2.new(0, 12, 0.5, -18)
    AvatarHolder.BackgroundColor3 = Theme.ElementBackground
    AvatarHolder.ClipsDescendants = true
    AvatarHolder.ZIndex = 6
    AvatarHolder.Parent = HeaderBar
    Round(10, AvatarHolder)

    local AvStroke = Outline(AvatarHolder, Theme.Accent, 1.5, 0.3)
    registerStroke(AvStroke)

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

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Text = title
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 18
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.Position = UDim2.new(0, 60, 0, 8)
    TitleLabel.Size = UDim2.new(0, 220, 0, 22)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 6
    TitleLabel.Parent = HeaderBar

    local DescLabel = Instance.new("TextLabel")
    DescLabel.Text = description
    DescLabel.Font = Enum.Font.Gotham
    DescLabel.TextSize = 18
    DescLabel.TextColor3 = Theme.Placeholder
    DescLabel.Position = UDim2.new(0, 60, 0, 28)
    DescLabel.Size = UDim2.new(0, 220, 0, 18)
    DescLabel.BackgroundTransparency = 1
    DescLabel.TextXAlignment = Enum.TextXAlignment.Left
    DescLabel.ZIndex = 6
    DescLabel.Parent = HeaderBar

    -- ═══════════════════════════════════════════════════════════
    --  BOTONES DE VENTANA
    -- ═══════════════════════════════════════════════════════════
    local ctrlBtnSize = 26
    local ctrlBtnSpacing = 6

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.fromOffset(ctrlBtnSize, ctrlBtnSize)
    CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(240, 75, 75)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 18
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.AutoButtonColor = false
    CloseBtn.ZIndex = 8
    CloseBtn.Parent = HeaderBar
    Round(7, CloseBtn)
    CloseBtn.MouseEnter:Connect(function()
        Tween(CloseBtn, 0.15, { BackgroundTransparency = 0 })
        Tween(CloseBtn, 0.15, { TextColor3 = Color3.fromRGB(255, 255, 255) })
    end)
    CloseBtn.MouseLeave:Connect(function()
        Tween(CloseBtn, 0.15, { BackgroundTransparency = 1 })
        Tween(CloseBtn, 0.15, { TextColor3 = Theme.Text })
    end)

    local MaxBtn = Instance.new("TextButton")
    MaxBtn.Size = UDim2.fromOffset(ctrlBtnSize, ctrlBtnSize)
    MaxBtn.Position = UDim2.new(1, -34 - (ctrlBtnSize + ctrlBtnSpacing), 0.5, -13)
    MaxBtn.BackgroundColor3 = Theme.ElementBackground
    MaxBtn.BackgroundTransparency = 1
    MaxBtn.Text = "⧉"
    MaxBtn.Font = Enum.Font.GothamBold
    MaxBtn.TextSize = 18
    MaxBtn.TextColor3 = Theme.Placeholder
    MaxBtn.AutoButtonColor = false
    MaxBtn.ZIndex = 8
    MaxBtn.Parent = HeaderBar
    Round(7, MaxBtn)
    MaxBtn.MouseEnter:Connect(function()
        Tween(MaxBtn, 0.15, { BackgroundTransparency = 0.3 })
        Tween(MaxBtn, 0.15, { TextColor3 = Theme.Text })
    end)
    MaxBtn.MouseLeave:Connect(function()
        Tween(MaxBtn, 0.15, { BackgroundTransparency = 1 })
        Tween(MaxBtn, 0.15, { TextColor3 = Theme.Placeholder })
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Size = UDim2.fromOffset(ctrlBtnSize, ctrlBtnSize)
    MinBtn.Position = UDim2.new(1, -34 - (ctrlBtnSize + ctrlBtnSpacing) * 2, 0.5, -13)
    MinBtn.BackgroundColor3 = Theme.ElementBackground
    MinBtn.BackgroundTransparency = 1
    MinBtn.Text = "−"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 18
    MinBtn.TextColor3 = Theme.Placeholder
    MinBtn.AutoButtonColor = false
    MinBtn.ZIndex = 8
    MinBtn.Parent = HeaderBar
    Round(7, MinBtn)
    MinBtn.MouseEnter:Connect(function()
        Tween(MinBtn, 0.15, { BackgroundTransparency = 0.3 })
        Tween(MinBtn, 0.15, { TextColor3 = Theme.Text })
    end)
    MinBtn.MouseLeave:Connect(function()
        Tween(MinBtn, 0.15, { BackgroundTransparency = 1 })
        Tween(MinBtn, 0.15, { TextColor3 = Theme.Placeholder })
    end)

    local ThemeBtn
    if showThemeSel then
        ThemeBtn = Instance.new("TextButton")
        ThemeBtn.Size = UDim2.fromOffset(ctrlBtnSize, ctrlBtnSize)
        ThemeBtn.Position = UDim2.new(1, -34 - (ctrlBtnSize + ctrlBtnSpacing) * 3, 0.5, -13)
        ThemeBtn.BackgroundColor3 = Theme.ElementBackground
        ThemeBtn.BackgroundTransparency = 0.4
        ThemeBtn.Text = "◐"
        ThemeBtn.Font = Enum.Font.GothamBold
        ThemeBtn.TextSize = 18
        ThemeBtn.TextColor3 = Theme.Text
        ThemeBtn.AutoButtonColor = false
        ThemeBtn.ZIndex = 8
        ThemeBtn.Parent = HeaderBar
        Round(7, ThemeBtn)
        local themeStroke = Outline(ThemeBtn, Theme.Outline, 1, 0.5)
        ThemeBtn.MouseEnter:Connect(function()
            Tween(ThemeBtn, 0.15, { BackgroundTransparency = 0.1 })
            Tween(themeStroke, 0.15, { Transparency = 0.2 })
        end)
        ThemeBtn.MouseLeave:Connect(function()
            Tween(ThemeBtn, 0.15, { BackgroundTransparency = 0.4 })
            Tween(themeStroke, 0.15, { Transparency = 0.5 })
        end)
    end

    -- ═══════════════════════════════════════════════════════════
    --  MODAL DE CONFIRMACIÓN DE CIERRE (estilo RysHub)
    -- ═══════════════════════════════════════════════════════════
    local ConfirmModal = Instance.new("Frame")
    ConfirmModal.Size = UDim2.fromOffset(300, 170)
    ConfirmModal.Position = UDim2.fromScale(0.5, 0.5)
    ConfirmModal.AnchorPoint = Vector2.new(0.5, 0.5)
    ConfirmModal.BackgroundColor3 = Theme.ElementBackground
    ConfirmModal.BackgroundTransparency = 0.02
    ConfirmModal.Visible = false
    ConfirmModal.ZIndex = 500
    ConfirmModal.Parent = WindowGui
    Round(14, ConfirmModal)
    Outline(ConfirmModal, Color3.fromRGB(180, 40, 40), 1.5, 0.2)

    local ModalTitle = Instance.new("TextLabel")
    ModalTitle.Size = UDim2.new(1, -32, 0, 28)
    ModalTitle.Position = UDim2.new(0, 16, 0, 16)
    ModalTitle.BackgroundTransparency = 1
    ModalTitle.Text = "Close Window"
    ModalTitle.Font = Enum.Font.GothamBold
    ModalTitle.TextSize = 18
    ModalTitle.TextColor3 = Theme.Text
    ModalTitle.TextXAlignment = Enum.TextXAlignment.Left
    ModalTitle.ZIndex = 501
    ModalTitle.Parent = ConfirmModal

    local ModalMsg = Instance.new("TextLabel")
    ModalMsg.Size = UDim2.new(1, -32, 0, 50)
    ModalMsg.Position = UDim2.new(0, 16, 0, 48)
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

    local BtnRow = Instance.new("Frame")
    BtnRow.Size = UDim2.new(1, -32, 0, 38)
    BtnRow.Position = UDim2.new(0, 16, 1, -54)
    BtnRow.BackgroundTransparency = 1
    BtnRow.ZIndex = 501
    BtnRow.Parent = ConfirmModal

    local CancelBtn = Instance.new("TextButton")
    CancelBtn.Size = UDim2.new(0.5, -6, 1, 0)
    CancelBtn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.1)
    CancelBtn.BackgroundTransparency = 0.1
    CancelBtn.Text = "Cancel"
    CancelBtn.Font = Enum.Font.GothamBold
    CancelBtn.TextSize = 18
    CancelBtn.TextColor3 = Theme.Text
    CancelBtn.AutoButtonColor = false
    CancelBtn.ZIndex = 502
    CancelBtn.Parent = BtnRow
    Round(10, CancelBtn)
    Outline(CancelBtn, Theme.Outline, 1, 0.5)

    local ConfirmBtn = Instance.new("TextButton")
    ConfirmBtn.Size = UDim2.new(0.5, -6, 1, 0)
    ConfirmBtn.Position = UDim2.new(0.5, 6, 0, 0)
    ConfirmBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    ConfirmBtn.BackgroundTransparency = 0
    ConfirmBtn.Text = "Close Window"
    ConfirmBtn.Font = Enum.Font.GothamBold
    ConfirmBtn.TextSize = 18
    ConfirmBtn.TextColor3 = Color3.new(1, 1, 1)
    ConfirmBtn.AutoButtonColor = false
    ConfirmBtn.ZIndex = 502
    ConfirmBtn.Parent = BtnRow
    Round(10, ConfirmBtn)

    CancelBtn.MouseEnter:Connect(function() Tween(CancelBtn, 0.15, { BackgroundTransparency = 0 }) end)
    CancelBtn.MouseLeave:Connect(function() Tween(CancelBtn, 0.15, { BackgroundTransparency = 0.1 }) end)
    ConfirmBtn.MouseEnter:Connect(function() Tween(ConfirmBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(210, 50, 50) }) end)
    ConfirmBtn.MouseLeave:Connect(function() Tween(ConfirmBtn, 0.15, { BackgroundColor3 = Color3.fromRGB(180, 40, 40) }) end)

    -- ═══ SIDEBAR ═══
    local SIDEBAR_W = 135
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -72)
    Sidebar.Position = UDim2.new(0, 8, 0, 60)
    Sidebar.BackgroundTransparency = 1
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 3
    Sidebar.ScrollBarImageColor3 = Theme.Accent
    Sidebar.ScrollBarImageTransparency = 0.3
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.ZIndex = 5
    Sidebar.Parent = MainFrame
    Round(10, Sidebar)

    local SidebarPad = Instance.new("UIPadding")
    SidebarPad.PaddingTop = UDim.new(0, 4)
    SidebarPad.PaddingBottom = UDim.new(0, 8)
    SidebarPad.PaddingLeft = UDim.new(0, 4)
    SidebarPad.PaddingRight = UDim.new(0, 4)
    SidebarPad.Parent = Sidebar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 4)
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = Sidebar

    local PageHost = Instance.new("Frame")
    PageHost.Size = UDim2.new(1, -(SIDEBAR_W + 24), 1, -72)
    PageHost.Position = UDim2.new(0, SIDEBAR_W + 16, 0, 60)
    PageHost.BackgroundTransparency = 1
    PageHost.ZIndex = 5
    PageHost.Parent = MainFrame

    -- ═══ BOTÓN FLOTANTE ═══
    local FB_W, FB_H = 150, 48

    local FloatBtn = Instance.new("TextButton")
    FloatBtn.Size = UDim2.fromOffset(FB_W, FB_H)
    FloatBtn.Position = UDim2.new(0, 24, 0.5, -FB_H/2)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    FloatBtn.BackgroundTransparency = 0
    FloatBtn.Text = ""
    FloatBtn.AutoButtonColor = false
    FloatBtn.Visible = false
    FloatBtn.ClipsDescendants = false
    FloatBtn.ZIndex = 10
    FloatBtn.Parent = WindowGui
    Round(FB_H / 2, FloatBtn)

    local fbOutlineColor = Color3.fromRGB(255, 140, 0)
    local fbStroke = Outline(FloatBtn, fbOutlineColor, 2, 0.05)
    fbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    local fbInnerStroke = Instance.new("UIStroke")
    fbInnerStroke.Color = Color3.fromRGB(255, 200, 80)
    fbInnerStroke.Thickness = 1
    fbInnerStroke.Transparency = 0.6
    fbInnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    fbInnerStroke.Parent = FloatBtn

    local DragIcon = Instance.new("Frame")
    DragIcon.Size = UDim2.fromOffset(26, 26)
    DragIcon.Position = UDim2.new(0, 12, 0.5, -13)
    DragIcon.BackgroundTransparency = 1
    DragIcon.ZIndex = 12
    DragIcon.Parent = FloatBtn

    local crossH = Instance.new("Frame")
    crossH.Size = UDim2.fromOffset(16, 2)
    crossH.Position = UDim2.new(0.5, -8, 0.5, -1)
    crossH.BackgroundColor3 = fbOutlineColor
    crossH.BorderSizePixel = 0
    crossH.ZIndex = 13
    crossH.Parent = DragIcon
    Round(1, crossH)

    local crossV = Instance.new("Frame")
    crossV.Size = UDim2.fromOffset(2, 16)
    crossV.Position = UDim2.new(0.5, -1, 0.5, -8)
    crossV.BackgroundColor3 = fbOutlineColor
    crossV.BorderSizePixel = 0
    crossV.ZIndex = 13
    crossV.Parent = DragIcon
    Round(1, crossV)

    local FBLabel = Instance.new("TextLabel")
    FBLabel.Size = UDim2.new(1, -48, 1, 0)
    FBLabel.Position = UDim2.new(0, 44, 0, 0)
    FBLabel.BackgroundTransparency = 1
    FBLabel.Text = openBtnText
    FBLabel.Font = Enum.Font.GothamBold
    FBLabel.TextSize = 18
    FBLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    FBLabel.TextXAlignment = Enum.TextXAlignment.Center
    FBLabel.ZIndex = 12
    FBLabel.Parent = FloatBtn

    if openBtnIcon then
        local resolvedOpenIcon = ResolveIcon(openBtnIcon)
        if resolvedOpenIcon ~= "" then
            DragIcon.Visible = false
            local iconImg = Instance.new("ImageLabel")
            iconImg.Size = UDim2.fromOffset(26, 26)
            iconImg.Position = UDim2.new(0, 12, 0.5, -13)
            iconImg.BackgroundTransparency = 1
            iconImg.Image = resolvedOpenIcon
            iconImg.ScaleType = Enum.ScaleType.Fit
            iconImg.ImageColor3 = fbOutlineColor
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
                        Tween(MainFrame, 0.4, {
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
        Tween(FloatBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(28, 28, 34) })
    end))
    Track(FloatBtn.MouseLeave:Connect(function()
        Tween(fbStroke, 0.2, { Transparency = 0.05, Thickness = 2 })
        Tween(FloatBtn, 0.2, { BackgroundColor3 = Color3.fromRGB(20, 20, 24) })
    end))

    -- ═══ RESIZE GRIP ═══
    local RESIZE_HIT = 32
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
    gripVisual.Size = UDim2.fromOffset(12, 12)
    gripVisual.BackgroundTransparency = 1
    gripVisual.ZIndex = 25
    gripVisual.Parent = ResizeGrip

    local gripLines = {}
    for i = 1, 3 do
        local line = Instance.new("Frame")
        line.AnchorPoint = Vector2.new(1, 1)
        line.Position = UDim2.new(1, -((i - 1) * 3.5), 1, -((i - 1) * 3.5))
        line.Size = UDim2.fromOffset(9 - (i - 1) * 3, 2)
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

    -- ═══ MINIMIZAR / MAXIMIZAR / CERRAR ═══
    local isMaximized = false
    local savedSize = size
    local savedPos = MainFrame.Position

    local function CloseWindow()
        Tween(MainFrame, 0.28, { Size = UDim2.fromOffset(size.X * 0.75, size.Y * 0.75) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.28, function()
            MainFrame.Visible = false
            FloatBtn.Visible = true
        end)
    end

    local function OpenWindow()
        MainFrame.Visible = true
        MainFrame.Size = UDim2.fromOffset(size.X * 0.7, size.Y * 0.7)
        MainFrame.BackgroundTransparency = 0.3
        Tween(MainFrame, 0.35, { Size = UDim2.fromOffset(size.X, size.Y), BackgroundTransparency = 0 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        FloatBtn.Visible = false
    end

    local function Minimize()
        Tween(MainFrame, 0.25, { Size = UDim2.fromOffset(size.X * 0.7, size.Y * 0.7) }, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.delay(0.25, function()
            MainFrame.Visible = false
            FloatBtn.Visible = true
        end)
    end

    local function Maximize()
        if isMaximized then
            Tween(MainFrame, 0.3, {
                Size = UDim2.fromOffset(savedSize.X, savedSize.Y),
                Position = savedPos
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            isMaximized = false
            MaxBtn.Text = "⧉"
        else
            savedSize = size
            savedPos = MainFrame.Position
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            Tween(MainFrame, 0.3, {
                Size = UDim2.fromOffset(vp.X * 0.75, vp.Y * 0.75),
                Position = UDim2.fromScale(0.5, 0.5)
            }, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            isMaximized = true
            MaxBtn.Text = "❐"
        end
    end

    -- ═══════════════════════════════════════════════════════════
    --  LÓGICA DE CIERRE REAL (destruye el UI + notificación)
    -- ═══════════════════════════════════════════════════════════
    local function ReallyClose()
        -- 1. Notificación
        SZK:Info("UI Closed", "The interface has been closed successfully.", 3)

        -- 2. Detener scans
        scansEnabled = false

        -- 3. Desconectar conexiones
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end

        -- 4. Remover de la lista
        for i, w in ipairs(SZK.Windows) do
            if w == Window then table.remove(SZK.Windows, i) break end
        end

        -- 5. Animar cierre
        Tween(MainFrame, 0.3, {
            Size = UDim2.fromOffset(size.X * 0.6, size.Y * 0.6),
            BackgroundTransparency = 0.6
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)

        Tween(ConfirmModal, 0.25, {
            Size = UDim2.fromOffset(200, 100),
            BackgroundTransparency = 0.6
        }, Enum.EasingStyle.Back, Enum.EasingDirection.In)

        -- 6. Destruir todo
        task.delay(0.32, function()
            pcall(function() WindowGui:Destroy() end)
        end)
    end

    CancelBtn.MouseButton1Click:Connect(function()
        Tween(ConfirmModal, 0.15, { BackgroundTransparency = 1 })
        task.delay(0.15, function()
            ConfirmModal.Visible = false
            ConfirmModal.BackgroundTransparency = 0.02
        end)
    end)

    ConfirmBtn.MouseButton1Click:Connect(ReallyClose)

    CloseBtn.MouseButton1Click:Connect(function()
        ConfirmModal.Visible = true
        ConfirmModal.BackgroundTransparency = 1
        ConfirmModal.Size = UDim2.fromOffset(200, 100)
        Tween(ConfirmModal, 0.25, {
            Size = UDim2.fromOffset(300, 170),
            BackgroundTransparency = 0.02
        }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)

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
        ThemePopup.Size = UDim2.fromOffset(200, 320)
        ThemePopup.BackgroundColor3 = Theme.ElementBackground
        ThemePopup.BackgroundTransparency = 0.05
        ThemePopup.Visible = false
        ThemePopup.ZIndex = 200
        ThemePopup.ClipsDescendants = true
        ThemePopup.Parent = WindowGui
        Round(12, ThemePopup)
        Outline(ThemePopup, Theme.Outline, 1, 0.2)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
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
        listLayout.Padding = UDim.new(0, 5)
        listLayout.Parent = scroll

        for _, tName in ipairs(SZK.ThemeOrder) do
            local tData = SZK.Themes[tName]
            if tData then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 38)
                btn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.02)
                btn.BackgroundTransparency = 0.3
                btn.AutoButtonColor = false
                btn.Text = ""
                btn.ZIndex = 202
                btn.Parent = scroll
                Round(6, btn)

                local swatch = Instance.new("Frame")
                swatch.Size = UDim2.fromOffset(22, 22)
                swatch.Position = UDim2.new(0, 8, 0.5, -11)
                swatch.BackgroundColor3 = tData.Accent
                swatch.ZIndex = 203
                swatch.Parent = btn
                Round(6, swatch)
                Outline(swatch, Color3.fromRGB(255, 255, 255), 1, 0.7)

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(1, -38, 1, 0)
                label.Position = UDim2.new(0, 36, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = tName
                label.Font = Enum.Font.GothamSemibold
                label.TextSize = 18
                label.TextColor3 = Theme.Text
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.ZIndex = 203
                label.Parent = btn

                btn.MouseEnter:Connect(function() Tween(btn, 0.15, { BackgroundTransparency = 0 }) end)
                btn.MouseLeave:Connect(function() Tween(btn, 0.15, { BackgroundTransparency = 0.3 }) end)
                btn.MouseButton1Click:Connect(function()
                    Theme = tData
                    SZK.CurrentTheme = Theme
                    ThemePopup.Visible = false
                    MainFrame.BackgroundColor3 = Theme.Background
                    Overlay.BackgroundColor3 = Theme.Background
                    HeaderBar.BackgroundColor3 = Theme.Background2
                    TitleLabel.TextColor3 = Theme.Text
                    DescLabel.TextColor3 = Theme.Placeholder
                    MainStroke.Color = Theme.Accent
                    OuterGlow.BackgroundColor3 = Theme.Accent
                    ThemePopup.BackgroundColor3 = Theme.ElementBackground
                    for _, l in ipairs(gripLines) do l.BackgroundColor3 = Theme.Accent end
                    for _, k in ipairs(ThemedElements.Knobs) do k.BackgroundColor3 = Theme.Background end
                end)
            end
        end

        RegisterPopup(ThemePopup, ThemeBtn)
        ThemeBtn.MouseButton1Click:Connect(function()
            if ThemePopup.Visible then ThemePopup.Visible = false; return end
            CloseAllPopups(ThemeBtn)
            local abs = ThemeBtn.AbsolutePosition
            local asz = ThemeBtn.AbsoluteSize
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local x = math.clamp(abs.X - 174, 6, math.max(6, viewport.X - 206))
            local belowY = abs.Y + asz.Y + 6
            local y = belowY + 320 <= viewport.Y - 6 and belowY or math.max(6, abs.Y - 326)
            ThemePopup.Position = UDim2.fromOffset(x, y)
            ThemePopup.Visible = true
        end)
    end

    local Window = { Tabs = {}, Connections = Connections }

    local function RegisterRow(parent, height)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, height or 54)
        frame.BackgroundColor3 = Theme.ElementBackground
        frame.BackgroundTransparency = 0.1
        frame.ClipsDescendants = true
        frame.ZIndex = 6
        frame.Parent = parent
        Round(10, frame)

        local rowGrad = Instance.new("UIGradient")
        rowGrad.Color = ColorSequence.new(Shade(Theme.ElementBackground, 0.05), Theme.ElementBackground)
        rowGrad.Rotation = 135
        rowGrad.Parent = frame

        local stroke = Outline(frame, Theme.Outline, 1, 0.4)
        registerStroke(stroke)

        local accentBar = Instance.new("Frame")
        accentBar.Size = UDim2.new(0, 3, 1, -18)
        accentBar.Position = UDim2.new(0, 0, 0, 9)
        accentBar.BackgroundColor3 = Theme.Accent
        accentBar.BorderSizePixel = 0
        accentBar.ZIndex = 7
        accentBar.Parent = frame
        Round(2, accentBar)
        registerFill(accentBar)

        local hoverGlow = Outline(frame, Theme.Accent, 1.5, 1)
        registerStroke(hoverGlow)

        frame.MouseEnter:Connect(function()
            Tween(frame, 0.2, { BackgroundTransparency = 0.02 })
            Tween(hoverGlow, 0.25, { Transparency = 0.5 })
        end)
        frame.MouseLeave:Connect(function()
            Tween(frame, 0.2, { BackgroundTransparency = 0.1 })
            Tween(hoverGlow, 0.25, { Transparency = 1 })
        end)

        return frame, stroke, accentBar
    end

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
        page.ScrollBarImageTransparency = 0.3
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.ZIndex = 5
        page.Parent = PageHost

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        local pagePad = Instance.new("UIPadding")
        pagePad.PaddingBottom = UDim.new(0, 10)
        pagePad.PaddingRight = UDim.new(0, 6)
        pagePad.Parent = page

        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 38)
        tabBtn.BackgroundColor3 = Theme.ElementBackground
        tabBtn.BackgroundTransparency = 1
        tabBtn.Text = ""
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 6
        tabBtn.Parent = Sidebar
        Round(8, tabBtn)

        local tabStroke = Outline(tabBtn, Theme.Accent, 1, 1)
        registerStroke(tabStroke)

        local activeBar = Instance.new("Frame")
        activeBar.Size = UDim2.new(0, 3, 0, 0)
        activeBar.Position = UDim2.new(0, 0, 0.5, 0)
        activeBar.AnchorPoint = Vector2.new(0, 0.5)
        activeBar.BackgroundColor3 = Theme.Accent
        activeBar.BorderSizePixel = 0
        activeBar.ZIndex = 9
        activeBar.Parent = tabBtn
        Round(2, activeBar)
        registerFill(activeBar)

        local tabIconImg
        local resolvedTabIcon = ResolveIcon(tabIcon)
        if resolvedTabIcon ~= "" then
            tabIconImg = Img(tabBtn, tabIcon, UDim2.fromOffset(16, 16), Theme.Placeholder, 0, 8)
            if tabIconImg then tabIconImg.Position = UDim2.new(0, 10, 0.5, -8) end
        end

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, tabIconImg and -36 or -16, 1, 0)
        tLabel.Position = UDim2.new(0, tabIconImg and 34 or 12, 0, 0)
        tLabel.BackgroundTransparency = 1
        tLabel.Text = tabName
        tLabel.Font = Enum.Font.GothamSemibold
        tLabel.TextSize = 18
        tLabel.TextColor3 = Theme.Placeholder
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.TextTruncate = Enum.TextTruncate.AtEnd
        tLabel.ZIndex = 8
        tLabel.Parent = tabBtn

        local tabData = { Type = "TabBtn", Instance = tabBtn, Stroke = tabStroke, Label = tLabel, Icon = tabIconImg, Active = false, Page = page, Bar = activeBar }
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
            Tween(tabBtn, 0.15, { BackgroundTransparency = 0.88, BackgroundColor3 = Theme.Accent })
            Tween(tabStroke, 0.15, { Transparency = 0.4 })
            Tween(activeBar, 0.25, { Size = UDim2.new(0, 3, 0, 22) }, Enum.EasingStyle.Back)
            if tabIconImg then TintIfAllowed(tabIconImg, Theme.Accent) end
        end

        tabBtn.MouseButton1Click:Connect(Activate)
        Ripple(tabBtn, Theme.Accent)

        tabBtn.MouseEnter:Connect(function()
            if not tabData.Active then
                Tween(tabBtn, 0.15, { BackgroundTransparency = 0.7, BackgroundColor3 = Theme.ElementBackground })
                Tween(tLabel, 0.15, { TextColor3 = Theme.Text })
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not tabData.Active then
                Tween(tabBtn, 0.15, { BackgroundTransparency = 1 })
                Tween(tLabel, 0.15, { TextColor3 = Theme.Placeholder })
            end
        end)

        if #Window.Tabs == 0 then task.defer(Activate) end

        local Tab = {}
        Window.Tabs[tabName] = Tab

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
            layout.Padding = UDim.new(0, 6)
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = container

            if secName ~= "" then
                local header = Instance.new("Frame")
                header.Size = UDim2.new(1, 0, 0, 26)
                header.BackgroundTransparency = 1
                header.ZIndex = 6
                header.Parent = container

                local secIconImg
                local resolvedSec = ResolveIcon(secIcon)
                if resolvedSec ~= "" then
                    secIconImg = Img(header, secIcon, UDim2.fromOffset(14, 14), Theme.Icon, 0, 8)
                    if secIconImg then secIconImg.Position = UDim2.new(0, 2, 0.5, -7) end
                end

                local hLabel = Instance.new("TextLabel")
                hLabel.Size = UDim2.new(1, secIconImg and -24 or -12, 1, 0)
                hLabel.Position = UDim2.new(0, secIconImg and 22 or 2, 0, 0)
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
                local image = Img(row, icon, UDim2.fromOffset(16, 16), Theme.Icon, 0, 8)
                if not image then return nil end
                image.AnchorPoint = Vector2.new(position == "Right" and 1 or 0, 0.5)
                image.Position = position == "Right" and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 14, 0.5, 0)
                if label and position == "Left" then
                    label.Position = UDim2.new(0, 38, label.Position.Y.Scale, label.Position.Y.Offset)
                    label.Size = UDim2.new(label.Size.X.Scale, label.Size.X.Offset - 30, label.Size.Y.Scale, label.Size.Y.Offset)
                end
                return image
            end

            function Section:CreateToggle(tConfig)
                local c = tConfig or {}
                local name     = c.Name or c.Title or "Toggle"
                local desc     = c.Desc or c.Description or ""
                local default  = c.Default or c.Value or false
                local callback = c.Callback or function() end
                local flag     = c.Flag

                local rowH = (desc ~= "" and 82 or 54)
                local row, stroke, accentBar = RegisterRow(container, rowH)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -80, 0, 22)
                lbl.Position = UDim2.new(0, 16, 0, 12)
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
                    dLbl.Size = UDim2.new(1, -22, 0, 32)
                    dLbl.Position = UDim2.new(0, 16, 0, 38)
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

                local switchW, switchH, knobSize, inset = 46, 26, 20, 3
                local track = Instance.new("TextButton")
                track.AnchorPoint = Vector2.new(1, 0)
                track.Position = UDim2.new(1, -16, 0, 14)
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
                registerKnob(knob)

                local state = default
                if flag then SZK.Flags[flag] = state end

                local function refresh(animate)
                    local kp = state and UDim2.new(1, -(inset + knobSize), 0.5, 0) or UDim2.new(0, inset, 0.5, 0)
                    local tc = state and Theme.Toggle or Color3.fromRGB(55, 55, 65)
                    if animate then
                        Tween(knob, 0.25, { Position = kp }, Enum.EasingStyle.Back)
                        Tween(track, 0.2, { BackgroundColor3 = tc })
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

                table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon, SubColor = track, State = function() return state end })

                local obj = {}
                function obj:Set(v) state = v; if flag then SZK.Flags[flag] = state end; refresh(true); callback(state) end
                function obj:Get() return state end
                return obj
            end

            function Section:CreateSlider(sConfig)
                local c = sConfig or {}
                local name     = c.Name or c.Title or "Slider"
                local min      = c.Min or 0
                local max      = c.Max or 100
                local default  = c.Default or c.Value or min
                local callback = c.Callback or function() end
                local suffix   = c.Suffix or ""

                local row, stroke, accentBar = RegisterRow(container, 62)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -20, 0, 22)
                lbl.Position = UDim2.new(0, 16, 0, 6)
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
                valLbl.Size = UDim2.fromOffset(70, 22)
                valLbl.Position = UDim2.new(1, -86, 0, 6)
                valLbl.BackgroundTransparency = 1
                valLbl.Text = tostring(default) .. suffix
                valLbl.Font = Enum.Font.GothamBold
                valLbl.TextSize = 18
                valLbl.TextColor3 = Theme.Accent
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.ZIndex = 7
                valLbl.Parent = row
                registerLabel(valLbl)

                local track = Instance.new("Frame")
                track.Size = UDim2.new(1, -32, 0, 4)
                track.Position = UDim2.new(0, 16, 0, 44)
                track.BackgroundColor3 = Shade(Theme.ElementBackground, 0.06)
                track.ZIndex = 7
                track.Parent = row
                Round(2, track)

                local fill = Instance.new("Frame")
                local t0 = (default - min) / math.max(max - min, 1)
                fill.Size = UDim2.new(t0, 0, 1, 0)
                fill.BackgroundColor3 = Theme.Slider
                fill.ZIndex = 8
                fill.Parent = track
                Round(2, fill)
                registerFill(fill)

                local handle = Instance.new("Frame")
                handle.Size = UDim2.fromOffset(14, 14)
                handle.AnchorPoint = Vector2.new(0.5, 0.5)
                handle.Position = UDim2.new(t0, 0, 0.5, 0)
                handle.BackgroundColor3 = Theme.Background
                handle.ZIndex = 9
                handle.Parent = track
                Round(7, handle)
                local handleStroke = Outline(handle, Theme.Slider, 2, 0)
                registerStroke(handleStroke)
                registerKnob(handle)

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
                        Tween(handle, 0.15, { Size = UDim2.fromOffset(16, 16) }, Enum.EasingStyle.Back)
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
                        Tween(handle, 0.15, { Size = UDim2.fromOffset(14, 14) })
                    end
                end))

                table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

                local obj = {}
                function obj:Set(v) apply(v) end
                function obj:Get() return tonumber(string.gsub(valLbl.Text, "[^%d%.%-]", "")) end
                return obj
            end

            function Section:CreateButton(bConfig)
                local c = bConfig or {}
                local name     = c.Name or c.Title or "Button"
                local desc     = c.Desc or c.Description
                local callback = c.Callback or function() end
                local customColor = c.Color

                local totalHeight = desc and 62 or 48

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, totalHeight)
                btn.BackgroundColor3 = customColor or Theme.ElementBackground
                btn.BackgroundTransparency = 0.1
                btn.Text = ""
                btn.AutoButtonColor = false
                btn.ClipsDescendants = true
                btn.ZIndex = 6
                btn.Parent = container
                Round(10, btn)

                local btnGrad = Instance.new("UIGradient")
                btnGrad.Color = ColorSequence.new(Shade(customColor or Theme.ElementBackground, 0.06), customColor or Theme.ElementBackground)
                btnGrad.Rotation = 135
                btnGrad.Parent = btn

                local stroke = Outline(btn, Theme.Outline, 1, 0.4)
                registerStroke(stroke)

                local accentBar = Instance.new("Frame")
                accentBar.Size = UDim2.new(0, 3, 1, -18)
                accentBar.Position = UDim2.new(0, 0, 0, 9)
                accentBar.BackgroundColor3 = Theme.Accent
                accentBar.BorderSizePixel = 0
                accentBar.ZIndex = 7
                accentBar.Parent = btn
                Round(2, accentBar)
                registerFill(accentBar)

                local elementIcon = c.Icon and Img(btn, c.Icon, UDim2.fromOffset(16, 16), Theme.Icon, 0, 8) or nil
                local textLeft = 18
                if elementIcon then
                    elementIcon.Position = UDim2.new(0, 16, 0.5, -8)
                    textLeft = 42
                end

                local titleLbl = Instance.new("TextLabel")
                titleLbl.Position = UDim2.new(0, textLeft, 0, desc and 8 or 0)
                titleLbl.Size = UDim2.new(1, -(textLeft + 14), 0, desc and 22 or totalHeight)
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
                    dLbl.Position = UDim2.new(0, textLeft, 0, 32)
                    dLbl.Size = UDim2.new(1, -(textLeft + 14), 0, 20)
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
                    Tween(btn, 0.18, { BackgroundTransparency = 0 })
                    Tween(stroke, 0.18, { Transparency = 0.15, Color = Theme.Accent })
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn, 0.18, { BackgroundTransparency = 0.1 })
                    Tween(stroke, 0.18, { Transparency = 0.4, Color = Theme.Outline })
                end)
                btn.MouseButton1Click:Connect(function() callback() end)
                Ripple(btn, Theme.Accent)

                table.insert(Registered, { Type = "Element", Instance = btn, Stroke = stroke, AccentBar = accentBar, Label = titleLbl, Icon = elementIcon })
            end

            function Section:CreateInput(iConfig)
                local c = iConfig or {}
                local name        = c.Name or c.Title or "Input"
                local placeholder = c.Placeholder or "Escribir..."
                local default     = c.Default or c.Value or ""
                local callback    = c.Callback or function() end

                local row, stroke, accentBar = RegisterRow(container, 48)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.Position = UDim2.new(0, 16, 0, 0)
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
                boxFrame.Size = UDim2.new(0.55, -14, 0, 32)
                boxFrame.Position = UDim2.new(0.42, 0, 0.5, -16)
                boxFrame.BackgroundColor3 = Shade(Theme.ElementBackground, 0.06)
                boxFrame.ZIndex = 7
                boxFrame.Parent = row
                Round(8, boxFrame)
                local boxStroke = Outline(boxFrame, Theme.Outline, 1, 0.4)

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -16, 1, 0)
                box.Position = UDim2.new(0, 8, 0, 0)
                box.BackgroundTransparency = 1
                box.Text = default
                box.PlaceholderText = placeholder
                box.PlaceholderColor3 = Theme.Placeholder
                box.TextColor3 = Theme.Text
                box.Font = Enum.Font.Gotham
                box.TextSize = 18
                box.ClearTextOnFocus = false
                box.ZIndex = 8
                box.Parent = boxFrame

                box.Focused:Connect(function() Tween(boxStroke, 0.2, { Color = Theme.Accent, Transparency = 0.2 }) end)
                box.FocusLost:Connect(function(enter)
                    Tween(boxStroke, 0.2, { Color = Theme.Outline, Transparency = 0.4 })
                    callback(box.Text, enter)
                end)

                table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

                local obj = {}
                function obj:Set(t) box.Text = t end
                function obj:Get() return box.Text end
                return obj
            end

            function Section:CreateDropdown(dConfig)
                local c = dConfig or {}
                local name     = c.Name or c.Title or "Dropdown"
                local options  = c.Options or {}
                local default  = c.Default or c.Value
                local callback = c.Callback or function() end
                local flag     = c.Flag

                local selected = default
                if flag then SZK.Flags[flag] = selected end

                local row, stroke, accentBar = RegisterRow(container, 48)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(0.4, 0, 1, 0)
                lbl.Position = UDim2.new(0, 16, 0, 0)
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
                sel.Size = UDim2.new(0.55, -14, 0, 32)
                sel.Position = UDim2.new(0.42, 0, 0.5, -16)
                sel.BackgroundColor3 = Shade(Theme.ElementBackground, 0.06)
                sel.Text = ""
                sel.AutoButtonColor = false
                sel.ZIndex = 7
                sel.Parent = row
                Round(8, sel)
                Outline(sel, Theme.Outline, 1, 0.4)

                local selLbl = Instance.new("TextLabel")
                selLbl.Size = UDim2.new(1, -34, 1, 0)
                selLbl.Position = UDim2.new(0, 10, 0, 0)
                selLbl.BackgroundTransparency = 1
                selLbl.Text = selected ~= nil and tostring(selected) or "Seleccionar..."
                selLbl.Font = Enum.Font.Gotham
                selLbl.TextSize = 18
                selLbl.TextColor3 = Theme.Text
                selLbl.TextXAlignment = Enum.TextXAlignment.Left
                selLbl.TextTruncate = Enum.TextTruncate.AtEnd
                selLbl.ZIndex = 8
                selLbl.Parent = sel

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.fromOffset(24, 24)
                arrow.Position = UDim2.new(1, -28, 0.5, -12)
                arrow.BackgroundTransparency = 1
                arrow.Text = "▾"
                arrow.Font = Enum.Font.GothamBold
                arrow.TextSize = 18
                arrow.TextColor3 = Theme.Placeholder
                arrow.ZIndex = 8
                arrow.Parent = sel

                local list = Instance.new("ScrollingFrame")
                list.BackgroundColor3 = Theme.ElementBackground
                list.Visible = false
                list.ZIndex = 100
                list.ClipsDescendants = true
                list.BorderSizePixel = 0
                list.ScrollBarThickness = 3
                list.ScrollBarImageColor3 = Theme.Accent
                list.CanvasSize = UDim2.new(0, 0, 0, #options * 36 + 8)
                list.Parent = WindowGui
                Round(8, list)
                Outline(list, Theme.Accent, 1, 0.3)

                local listPad = Instance.new("UIPadding")
                listPad.PaddingTop = UDim.new(0, 4)
                listPad.PaddingBottom = UDim.new(0, 4)
                listPad.PaddingLeft = UDim.new(0, 4)
                listPad.PaddingRight = UDim.new(0, 4)
                listPad.Parent = list

                for i, opt in ipairs(options) do
                    local txt = type(opt) == "table" and (opt.Text or opt.Value) or tostring(opt)
                    local val = type(opt) == "table" and (opt.Value or opt.Text) or opt
                    local ob = Instance.new("TextButton")
                    ob.Size = UDim2.new(1, 0, 0, 32)
                    ob.BackgroundColor3 = Shade(Theme.ElementBackground, 0.08)
                    ob.BackgroundTransparency = 1
                    ob.Text = "  " .. txt
                    ob.Font = Enum.Font.Gotham
                    ob.TextSize = 18
                    ob.TextColor3 = Theme.Text
                    ob.TextXAlignment = Enum.TextXAlignment.Left
                    ob.AutoButtonColor = false
                    ob.ZIndex = 101
                    ob.Parent = list
                    Round(5, ob)
                    ob.MouseEnter:Connect(function() Tween(ob, 0.12, { BackgroundTransparency = 0 }) end)
                    ob.MouseLeave:Connect(function() Tween(ob, 0.12, { BackgroundTransparency = 1 }) end)
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
                    local listH = math.clamp(#options * 36 + 8, 48, 260)
                    list.Size = UDim2.fromOffset(asz.X, listH)
                    list.Position = UDim2.fromOffset(abs.X, abs.Y + asz.Y + 4)
                    list.Visible = true
                end)

                table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

                local obj = {}
                function obj:Set(v) selected = v; selLbl.Text = tostring(v); if flag then SZK.Flags[flag] = v end end
                function obj:Get() return selected end
                return obj
            end

            function Section:CreateKeybind(kConfig)
                local c = kConfig or {}
                local name     = c.Name or c.Title or "Keybind"
                local default  = c.Default or c.Value
                local callback = c.Callback or function() end

                local row, stroke, accentBar = RegisterRow(container, 48)

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, -100, 1, 0)
                lbl.Position = UDim2.new(0, 16, 0, 0)
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
                keyBtn.Size = UDim2.fromOffset(86, 30)
                keyBtn.Position = UDim2.new(1, -102, 0.5, -15)
                keyBtn.BackgroundColor3 = Shade(Theme.ElementBackground, 0.06)
                keyBtn.Text = default and default.Name or "Ninguno"
                keyBtn.Font = Enum.Font.GothamBold
                keyBtn.TextSize = 18
                keyBtn.TextColor3 = Theme.Text
                keyBtn.AutoButtonColor = false
                keyBtn.ZIndex = 7
                keyBtn.Parent = row
                Round(8, keyBtn)
                local keyStroke = Outline(keyBtn, Theme.Outline, 1, 0.4)

                local current = default
                local listening = false
                local conn
                keyBtn.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true
                    keyBtn.Text = "..."
                    Tween(keyStroke, 0.2, { Color = Theme.Accent, Transparency = 0.2 })
                    if conn then conn:Disconnect() end
                    conn = Track(UserInputService.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            current = input.KeyCode
                            keyBtn.Text = current.Name
                            listening = false
                            Tween(keyStroke, 0.2, { Color = Theme.Outline, Transparency = 0.4 })
                            if conn then conn:Disconnect() end
                            callback(current)
                        end
                    end))
                end)

                table.insert(Registered, { Type = "Element", Instance = row, Stroke = stroke, AccentBar = accentBar, Label = lbl, Icon = elementIcon })

                local obj = {}
                function obj:Set(k) current = k; keyBtn.Text = k and k.Name or "Ninguno" end
                function obj:Get() return current end
                return obj
            end

            function Section:CreateLabel(text, iconKey)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundTransparency = 1
                row.ZIndex = 6
                row.Parent = container

                local iconImg
                if iconKey then
                    iconImg = Img(row, iconKey, UDim2.fromOffset(16, 16), Theme.Placeholder, 0, 8)
                    if iconImg then iconImg.Position = UDim2.new(0, 4, 0.5, -8) end
                end

                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, iconImg and -28 or -12, 1, 0)
                lbl.Position = UDim2.new(0, iconImg and 28 or 4, 0, 0)
                lbl.BackgroundTransparency = 1
                lbl.Text = tostring(text)
                lbl.Font = Enum.Font.GothamMedium
                lbl.TextSize = 18
                lbl.TextColor3 = Theme.Placeholder
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = row
            end

            function Section:CreateParagraph(text)
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 0)
                row.AutomaticSize = Enum.AutomaticSize.Y
                row.BackgroundColor3 = Theme.ElementBackground
                row.BackgroundTransparency = 0.3
                row.ZIndex = 6
                row.Parent = container
                Round(10, row)
                Outline(row, Theme.Outline, 1, 0.5)

                local pad = Instance.new("UIPadding")
                pad.PaddingTop = UDim.new(0, 14)
                pad.PaddingBottom = UDim.new(0, 14)
                pad.PaddingLeft = UDim.new(0, 16)
                pad.PaddingRight = UDim.new(0, 14)
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

            function Section:CreateDivider()
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 12)
                row.BackgroundTransparency = 1
                row.Parent = container
                local line = Instance.new("Frame")
                line.Size = UDim2.new(0.4, 0, 0, 1)
                line.Position = UDim2.new(0.3, 0, 0.5, 0)
                line.BackgroundColor3 = Theme.Outline
                line.BackgroundTransparency = 0.5
                line.BorderSizePixel = 0
                line.ZIndex = 7
                line.Parent = row
            end

            return Section
        end

        function Tab:CreateToggle(...)   return Tab:CreateSection(""):CreateToggle(...) end
        function Tab:CreateSlider(...)   return Tab:CreateSection(""):CreateSlider(...) end
        function Tab:CreateButton(...)   return Tab:CreateSection(""):CreateButton(...) end
        function Tab:CreateInput(...)    return Tab:CreateSection(""):CreateInput(...) end
        function Tab:CreateDropdown(...) return Tab:CreateSection(""):CreateDropdown(...) end
        function Tab:CreateKeybind(...)  return Tab:CreateSection(""):CreateKeybind(...) end
        function Tab:CreateLabel(...)    return Tab:CreateSection(""):CreateLabel(...) end
        function Tab:CreateParagraph(...)return Tab:CreateSection(""):CreateParagraph(...) end
        function Tab:CreateDivider()     return Tab:CreateSection(""):CreateDivider() end

        return Tab
    end

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
        if typeof(v) == "Vector2" then MIN_SIZE = v; SizeConstraint.MinSize = v end
    end

    function Window:SetMaxSize(v)
        if typeof(v) == "Vector2" then MAX_SIZE = v; SizeConstraint.MaxSize = v end
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
            for _, l in ipairs(gripLines) do l.BackgroundColor3 = t.Accent end
            for _, k in ipairs(ThemedElements.Knobs) do k.BackgroundColor3 = t.Background end
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
        for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
        for i, w in ipairs(SZK.Windows) do
            if w == self then table.remove(SZK.Windows, i) break end
        end
        pcall(function() ConfirmModal:Destroy() end)
        pcall(function() WindowGui:Destroy() end)
    end

    MainFrame.Visible = true
    table.insert(SZK.Windows, Window)
    return Window
end

SZK.New = SZK.CreateWindow

function SZK:GetFlag(name) return SZK.Flags[name] end
function SZK:SetFlag(name, v) SZK.Flags[name] = v end
function SZK:Get(name) return SZK.Flags[name] end
function SZK:Set(name, val) SZK.Flags[name] = val end

return SZK
