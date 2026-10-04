-- ============================================================
-- RUNAWAYS AutoFarm - by DFoxy
-- Baseado nas coordenadas do usuario
-- Auto-execute ready (queue_on_teleport)
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- URL que o auto-execute vai carregar no proximo servidor
local AUTOEXEC_URL = "https://raw.githubusercontent.com/Foxy-Ghost/DFoxy.hub/main/runaways.lua"

-- ANTI-AFK
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- ============================================================
-- COORDENADAS
-- ============================================================
local BUTTON_POS = Vector3.new(502.112976, 2167.731201, 83612.273438)

local EXIT_PATH = {
    Vector3.new(550.677185, 2167.328369, 83624.679688),
    Vector3.new(550.223083, 2167.329590, 83630.226562),
    Vector3.new(548.630432, 2167.325928, 83635.484375),
    Vector3.new(548.813416, 2167.224854, 83643.390625),
    Vector3.new(548.000000, 2167.200000, 83652.000000), -- 5a extrapolada
}

-- ============================================================
-- CONFIG
-- ============================================================
local CONFIG = {
    StartDelay      = 10,
    GateWait        = 120,
    KillRadius      = 500,
    GodMode         = true,
    KillAura        = true,
    AutoReplay      = true,
    AutoExecOnTeleport = true,
    Noclip          = true,
}

-- ============================================================
-- ESTADO
-- ============================================================
local State = {
    Running = false,
    Phase   = "Idle",
}

local function log(msg)
    print("[Runaways-DFoxy] " .. tostring(msg))
end

-- ============================================================
-- HELPERS
-- ============================================================
local function getHumanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function teleportToPos(pos)
    local char = player.Character
    if not char then return false end
    local ok = pcall(function()
        char:PivotTo(CFrame.new(pos))
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
    return ok
end

local function teleportCFrame(cf)
    local char = player.Character
    if not char then return false end
    return pcall(function() char:PivotTo(cf) end)
end

-- ============================================================
-- NOCLIP
-- ============================================================
local noclipOn = false
local noclipConn = nil

local function setNoclip(on)
    noclipOn = on
    if on then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipOn then return end
            local char = player.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect() noclipConn = nil end
    end
end

-- ============================================================
-- GOD MODE (local, sem depender de modulo)
-- ============================================================
local godConn = nil
local godStates = setmetatable({}, { __mode = "k" })

local function applyGodMode(h)
    if not h then return end
    if not godStates[h] then
        godStates[h] = {
            BreakJointsOnDeath = h.BreakJointsOnDeath,
            RequiresNeck = h.RequiresNeck,
            DeadEnabled = h:GetStateEnabled(Enum.HumanoidStateType.Dead),
        }
    end
    h.BreakJointsOnDeath = false
    h.RequiresNeck = false
    pcall(function() h:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    h.Health = h.MaxHealth
    if h:GetAttribute("Downed") == true then
        pcall(function()
            h:SetAttribute("Downed", false)
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
end

local function startGodMode()
    if godConn then return end
    godConn = RunService.Heartbeat:Connect(function()
        if not CONFIG.GodMode then return end
        applyGodMode(getHumanoid())
    end)
end

local function stopGodMode()
    if godConn then godConn:Disconnect() godConn = nil end
    for h, st in pairs(godStates) do
        if h.Parent then
            pcall(function()
                h.BreakJointsOnDeath = st.BreakJointsOnDeath
                h.RequiresNeck = st.RequiresNeck
                h:SetStateEnabled(Enum.HumanoidStateType.Dead, st.DeadEnabled)
            end)
        end
    end
    godStates = setmetatable({}, { __mode = "k" })
end

-- ============================================================
-- FLOW MODULE (opcional, so pra kill aura)
-- ============================================================
local flowModule = nil
do
    local ok, mod = pcall(function()
        return require(ReplicatedStorage:WaitForChild("FlowClient", 8))
    end)
    if ok and type(mod) == "table" then
        flowModule = mod
        log("FlowClient carregado.")
    else
        log("FlowClient NAO carregou (kill aura via modulo indisponivel).")
    end
end

-- ============================================================
-- KILL AURA
-- ============================================================
local killAuraRunning = false

local function killAuraTick()
    local root = getRoot()
    if not root then return end

    local folder = workspace:FindFirstChild("NPCs")
    if not folder then return end

    -- Tentativa 1: modulo FlowClient
    if flowModule and flowModule.NPCs and type(flowModule.NPCs.Damage) == "function" then
        local ok, list = pcall(function() return folder:QueryDescendants("Humanoid") end)
        if ok and list then
            for _, h in ipairs(list) do
                local npc = h:FindFirstAncestorWhichIsA("Model")
                local nr = npc and npc:FindFirstChild("HumanoidRootPart")
                if nr and h.Health > 0
                    and (nr.Position - root.Position).Magnitude <= CONFIG.KillRadius then
                    pcall(flowModule.NPCs.Damage, h, h.Health + 1)
                end
            end
        end
        return
    end

    -- Tentativa 2: remote comum
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("RemoteEvents")
    if remotes then
        local dmg = remotes:FindFirstChild("Damage")
            or remotes:FindFirstChild("TakeDamage")
            or remotes:FindFirstChild("Hit")
        if dmg and dmg:IsA("RemoteEvent") then
            for _, h in ipairs(folder:QueryDescendants("Humanoid")) do
                local npc = h:FindFirstAncestorWhichIsA("Model")
                if npc then
                    pcall(function() dmg:FireServer(npc, h.Health + 1) end)
                end
            end
        end
    end
end

local function startKillAura()
    if killAuraRunning then return end
    killAuraRunning = true
    task.spawn(function()
        while killAuraRunning and State.Running do
            if CONFIG.KillAura then
                pcall(killAuraTick)
            end
            task.wait(0.25)
        end
        killAuraRunning = false
    end)
end

local function stopKillAura()
    killAuraRunning = false
end

-- ============================================================
-- PROMPT / END SCREEN
-- ============================================================
local function findPromptNear(pos, radius)
    radius = radius or 30
    local best, bestDist = nil, math.huge
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local p = d.Parent
            local wp
            if p and p:IsA("Attachment") then wp = p.WorldPosition
            elseif p and p:IsA("BasePart") then wp = p.Position end
            if wp then
                local dist = (wp - pos).Magnitude
                if dist < radius and dist < bestDist then
                    best, bestDist = d, dist
                end
            end
        end
    end
    return best
end

local function isVisible(inst)
    local cur = inst
    while cur and cur ~= playerGui do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return cur == playerGui
end

local function getEndScreen()
    local ef = playerGui:FindFirstChild("EndFrame", true)
    if ef and isVisible(ef) then
        local esc = ef:FindFirstChild("Escaped", true)
        local cap = ef:FindFirstChild("Captured", true)
        if esc and isVisible(esc) then return ef, "Escaped" end
        if cap and isVisible(cap) then return ef, "Captured" end
        return ef, "Ended"
    end
    for _, i in ipairs(playerGui:GetDescendants()) do
        if i:IsA("TextLabel") and isVisible(i) then
            local t = tostring(i.Text):lower()
            if t:find("escaped", 1, true) then return nil, "Escaped" end
            if t:find("captured", 1, true) then return nil, "Captured" end
        end
    end
    return nil, nil
end

local function getReplayButton(ef)
    if not ef then return nil end
    local function isReplay(b)
        if not b:IsA("GuiButton") then return false end
        if b.Name:lower():find("replay", 1, true) then return true end
        if b:IsA("TextButton") and tostring(b.Text or ""):lower():find("replay", 1, true) then
            return true
        end
        return false
    end
    local d = ef:FindFirstChild("Replay", true)
    if d then
        if isReplay(d) then return d end
        local inner = d:FindFirstChildWhichIsA("GuiButton", true)
        if inner and isReplay(inner) then return inner end
    end
    for _, b in ipairs(ef:GetDescendants()) do
        if isReplay(b) then return b end
    end
    return nil
end

local function pressReplay(btn)
    if not btn then return false end
    if type(firesignal) == "function" then
        local ok = pcall(firesignal, btn.MouseButton1Click)
        if ok then return true end
    end
    local ok = pcall(function() btn:Activate() end)
    return ok
end

-- ============================================================
-- QUEUE ON TELEPORT
-- ============================================================
local function queueReload()
    if not CONFIG.AutoExecOnTeleport then return end
    local qf = queue_on_teleport or queueonteleport
    if type(qf) ~= "function" then
        log("queue_on_teleport indisponivel.")
        return
    end
    local payload =
        "if not game:IsLoaded() then game.Loaded:Wait() end\n" ..
        "loadstring(game:HttpGet(\"" .. AUTOEXEC_URL .. "\"))()"
    local ok = pcall(qf, payload)
    log(ok and "Auto-exec armado." or "Falha ao armar auto-exec.")
end

-- ============================================================
-- LOOP
-- ============================================================
local function waitForCharacter()
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return true
    end
    local exp = os.clock() + 30
    repeat task.wait(0.2)
    until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        or os.clock() >= exp
    return player.Character ~= nil
end

local function doCycle()
    State.Phase = "Teleport to button"
    log("Teleportando para o botao do portao...")
    setNoclip(true)
    startGodMode()

    pcall(function() player:RequestStreamAroundAsync(BUTTON_POS, 5) end)
    teleportToPos(BUTTON_POS)
    task.wait(1.5)

    State.Phase = "Find prompt"
    local prompt = nil
    local exp = os.clock() + 15
    repeat
        prompt = findPromptNear(BUTTON_POS, 30)
        if not prompt then task.wait(0.5) end
    until prompt or os.clock() >= exp

    if not prompt then
        log("Prompt nao encontrado em 15s.")
        return false
    end
    log("Prompt: " .. prompt.Name)

    State.Phase = "Press button"
    for _ = 1, 3 do
        if type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
        else
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
        end
        task.wait(1)
    end
    log("Botao apertado.")

    State.Phase = "Wait gate"
    log("Aguardando portao (" .. CONFIG.GateWait .. "s)...")
    local start = os.clock()
    while os.clock() - start < CONFIG.GateWait do
        if not State.Running then return false end
        local root = getRoot()
        if root then
            pcall(function()
                player.Character:PivotTo(CFrame.new(BUTTON_POS))
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end)
        end
        task.wait(0.4)
        local ef, outcome = getEndScreen()
        if ef or outcome then
            log("Fim detectado durante espera: " .. tostring(outcome))
            return true
        end
    end

    State.Phase = "Exit path"
    log("Saindo pelo portao...")
    for i, pos in ipairs(EXIT_PATH) do
        if not State.Running then return false end
        local cf = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
        teleportCFrame(cf)
        log("Passo " .. i .. "/" .. #EXIT_PATH)
        task.wait(0.6)
    end

    State.Phase = "Wait end"
    exp = os.clock() + 30
    repeat
        local ef, outcome = getEndScreen()
        if ef or outcome then
            log("Fim: " .. tostring(outcome))
            break
        end
        task.wait(0.3)
    until os.clock() >= exp

    return true
end

local function pressReplayAndRequeue()
    State.Phase = "Replay"
    log("Procurando botao de replay...")
    local exp = os.clock() + 45
    local pressed = false
    while os.clock() < exp do
        local ef = getEndScreen()
        if ef then
            local btn = getReplayButton(ef)
            if btn then
                pressReplay(btn)
                pressed = true
                log("Replay apertado.")
                break
            end
        end
        task.wait(0.5)
    end
    queueReload()
    if pressed then task.wait(3) end
end

local function mainLoop()
    if CONFIG.StartDelay > 0 then
        log("Aguardando " .. CONFIG.StartDelay .. "s...")
        task.wait(CONFIG.StartDelay)
    end
    if not State.Running then return end

    if not waitForCharacter() then
        log("Personagem nao carregou.")
        return
    end

    startKillAura()

    while State.Running do
        local ok = pcall(doCycle)
        if not ok or not State.Running then break end
        pressReplayAndRequeue()
        if not State.Running then break end
        task.wait(5)
    end

    stopKillAura()
    stopGodMode()
    setNoclip(false)
end

-- ============================================================
-- UI
-- ============================================================
local COR_FUNDO    = Color3.fromRGB(18, 22, 38)
local COR_TITULO   = Color3.fromRGB(30, 90, 200)
local COR_LARANJA  = Color3.fromRGB(240, 130, 40)
local COR_TEXTO    = Color3.fromRGB(255, 255, 255)
local COR_VERDE    = Color3.fromRGB(70, 180, 110)
local COR_VERMELHO = Color3.fromRGB(190, 65, 65)

local old = playerGui:FindFirstChild("RunawaysDFoxyUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "RunawaysDFoxyUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 340)
main.Position = UDim2.new(0, 20, 0, 80)
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

local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, COR_TITULO),
    ColorSequenceKeypoint.new(1, COR_LARANJA),
})
grad.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -40, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Runaways - by DFoxy"
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
layout.Padding = UDim.new(0, 6)
layout.Parent = content

local function addButton(name, color, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = color
    b.Text = name
    b.TextColor3 = COR_TEXTO
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.Parent = content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        local ok, err = pcall(cb)
        if not ok then warn("[Runaways] " .. tostring(err)) end
    end)
end

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true
statusLabel.Parent = content

addButton("▶ INICIAR", COR_VERDE, function()
    if State.Running then return end
    State.Running = true
    log("Iniciado manualmente.")
    task.spawn(mainLoop)
end)

addButton("■ PARAR", COR_VERMELHO, function()
    State.Running = false
    setNoclip(false)
    stopGodMode()
    stopKillAura()
    State.Phase = "Stopped"
    log("Parado.")
end)

task.spawn(function()
    while gui.Parent do
        statusLabel.Text = "Status: " .. State.Phase
        task.wait(0.5)
    end
end)

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

closeBtn.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- ============================================================
-- INIT
-- ============================================================
log("Carregado. Place: " .. tostring(game.PlaceId))
log("Iniciando em " .. CONFIG.StartDelay .. "s...")

State.Running = true
task.spawn(mainLoop)

-- Unload para o hub
getgenv().RunawaysUnload = function()
    State.Running = false
    setNoclip(false)
    stopGodMode()
    stopKillAura()
    local ui = playerGui:FindFirstChild("RunawaysDFoxyUI")
    if ui then ui:Destroy() end
    warn("[Runaways] Unloaded.")
end
