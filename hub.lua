-- ============================================================
-- DFOXY HUB - Carregador de scripts do GitHub
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════
-- EDITE AQUI (troque pelo seu usuário e repo)
-- ══════════════════════════════════════════════════════
local GITHUB_USER   = "Foxy-Ghost"
local GITHUB_REPO   = "DFoxy.hub"
local GITHUB_BRANCH = "main"
-- ══════════════════════════════════════════════════════

local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"

local SCRIPTS = {
    {
        id   = "animedice",
        name = "Anime Dice",
        file = "animedice.lua",
        desc = "Equip Best, Rebirth, Collect, FPS Boost",
    },
    {
        id   = "runaways",
        name = "Runaways",
        file = "runaways.lua",
        desc = "AutoFarm com god mode e kill aura",
    },
}

-- Tema
local COR_FUNDO     = Color3.fromRGB(18, 22, 38)
local COR_TITULO    = Color3.fromRGB(30, 90, 200)
local COR_LARANJA   = Color3.fromRGB(240, 130, 40)
local COR_BOTAO     = Color3.fromRGB(40, 90, 170)
local COR_BOTAO_OFF = Color3.fromRGB(40, 70, 120)
local COR_TEXTO     = Color3.fromRGB(255, 255, 255)
local COR_SECAO     = Color3.fromRGB(255, 160, 70)
local COR_VERDE     = Color3.fromRGB(70, 180, 110)
local COR_VERMELHO  = Color3.fromRGB(190, 65, 65)

-- Remove UI antiga
local old = playerGui:FindFirstChild("DFoxyHubUI")
if old then old:Destroy() end

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "DFoxyHubUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 500)
main.Position = UDim2.new(0.5, -170, 0.5, -250)
main.BackgroundColor3 = COR_FUNDO
main.BorderSizePixel = 0
main.Active = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 35)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local gradTitle = Instance.new("UIGradient")
gradTitle.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COR_TITULO),
    ColorSequenceKeypoint.new(1, COR_LARANJA),
})
gradTitle.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -45, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "DFoxy Hub"
titleText.TextColor3 = COR_TEXTO
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -32, 0, 3)
closeBtn.BackgroundColor3 = COR_LARANJA
closeBtn.Text = "X"
closeBtn.TextColor3 = COR_TEXTO
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.Parent = titleBar
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

-- Arrastar
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                  startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Minimizar
local minimized = false
local fullSize = main.Size
closeBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        main.Size = UDim2.new(0, 340, 0, 35)
        closeBtn.Text = "+"
    else
        main.Size = fullSize
        closeBtn.Text = "X"
    end
end)

-- Conteúdo
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -50)
content.Position = UDim2.new(0, 10, 0, 45)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = COR_LARANJA
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = content

-- ============================================================
-- Utilitários
-- ============================================================
local function addSection(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 24)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = COR_SECAO
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.Parent = content
end

local function addButton(name, cor, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 34)
    b.BackgroundColor3 = cor or COR_BOTAO
    b.Text = name
    b.TextColor3 = COR_TEXTO
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.Parent = content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

    if not cor then
        local g = Instance.new("UIGradient")
        g.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, COR_BOTAO),
            ColorSequenceKeypoint.new(1, COR_LARANJA),
        })
        g.Rotation = 15
        g.Parent = b
    end

    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(callback)
        if not ok then warn("[DFoxy Hub] erro:", err) end
    end)
end

local function addDesc(text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 14)
    l.BackgroundTransparency = 1
    l.Text = "   " .. text
    l.TextColor3 = Color3.fromRGB(160, 160, 180)
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = content
end

-- ============================================================
-- Log
-- ============================================================
local logLines = {}
local logLabel

local function log(msg)
    local t = os.date("%H:%M:%S")
    table.insert(logLines, "[" .. t .. "] " .. tostring(msg))
    if #logLines > 30 then table.remove(logLines, 1) end
    if logLabel then
        logLabel.Text = table.concat(logLines, "\n")
    end
    print("[DFoxy Hub] " .. tostring(msg))
end

-- ============================================================
-- Carregador
-- ============================================================
local function loadScript(info)
    log("Carregando: " .. info.name)
    local url = BASE_URL .. info.file

    local okFetch, src = pcall(function() return game:HttpGet(url) end)
    if not okFetch then
        log("Falha no download: " .. tostring(src))
        return false
    end
    if type(src) ~= "string" or #src < 10 then
        log("Resposta inválida (arquivo vazio?)")
        return false
    end

    local fn, loadErr = loadstring(src)
    if not fn then
        log("Erro de sintaxe: " .. tostring(loadErr))
        return false
    end

    local okRun, runErr = pcall(fn)
    if not okRun then
        log("Erro na execução: " .. tostring(runErr))
        return false
    end

    log("OK: " .. info.name)
    return true
end

local function unloadAll()
    log("Descarregando...")

    -- Chama unload dos scripts que expõem essa função
    if type(getgenv) == "function" then
        local env = getgenv()
        if type(env.DFoxyUnload) == "function" then
            pcall(env.DFoxyUnload)
            env.DFoxyUnload = nil
            log("DFoxyUnload chamado")
        end
        if env.RunawaysLocalAutoFarm and type(env.RunawaysLocalAutoFarm.Stop) == "function" then
            pcall(function() env.RunawaysLocalAutoFarm:Stop() end)
            log("Runaways parado")
        end
    end

    -- Remove UIs conhecidas
    for _, name in ipairs({ "DFoxyUI", "RUNAWAYS_LocalUI" }) do
        local ui = playerGui:FindFirstChild(name)
        if ui then ui:Destroy() end
    end

    log("Tudo descarregado")
end

-- ============================================================
-- UI
-- ============================================================
addSection("SCRIPTS")
for _, s in ipairs(SCRIPTS) do
    addButton("▶  " .. s.name, COR_VERDE, function() loadScript(s) end)
    addDesc(s.desc)
end

addSection("AÇÕES")
addButton("✕  Descarregar Tudo", COR_VERMELHO, unloadAll)
addButton("🗑  Limpar Log", COR_BOTAO_OFF, function()
    logLines = {}
    if logLabel then logLabel.Text = "" end
end)

addSection("LOG")
logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, 0, 0, 140)
logLabel.BackgroundColor3 = Color3.fromRGB(12, 15, 25)
logLabel.Text = ""
logLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
logLabel.Font = Enum.Font.Code
logLabel.TextSize = 10
logLabel.TextWrapped = true
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.TextYAlignment = Enum.TextYAlignment.Top
logLabel.BorderSizePixel = 0
logLabel.Parent = content
Instance.new("UICorner", logLabel).CornerRadius = UDim.new(0, 6)
local lp = Instance.new("UIPadding")
lp.PaddingLeft = UDim.new(0, 8)
lp.PaddingTop = UDim.new(0, 6)
lp.PaddingRight = UDim.new(0, 8)
lp.Parent = logLabel

-- ============================================================
-- Init
-- ============================================================
log("DFoxy Hub iniciado")
if GITHUB_USER == "Foxy-Ghost" then
    log("⚠ Configure GITHUB_USER e GITHUB_REPO no topo!")
else
    log("Repo: " .. GITHUB_USER .. "/" .. GITHUB_REPO)
end
