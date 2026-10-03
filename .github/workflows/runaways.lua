--[[
    RUNAWAYS AutoFarm — 100% Local, UI própria, Auto-Execute Ready
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

if not game:IsLoaded() then game.Loaded:Wait() end
while not Players.LocalPlayer do task.wait() end

local player = Players.LocalPlayer
local env = getgenv and getgenv() or _G

-- ═══════════════════ PERSISTÊNCIA LOCAL ═══════════════════
local SCRIPT_DIR = "MyScriptHub/RUNAWAYS"
local SCRIPT_PATH = SCRIPT_DIR .. "/autofarm_local.lua"

local hasFileAPI = type(writefile) == "function" and type(readfile) == "function"

local function ensureFolder()
    if type(makefolder) ~= "function" then return end
    if type(isfolder) ~= "function" or not isfolder("MyScriptHub") then
        pcall(makefolder, "MyScriptHub")
    end
    if type(isfolder) ~= "function" or not isfolder(SCRIPT_DIR) then
        pcall(makefolder, SCRIPT_DIR)
    end
end

local function getOwnSource()
    if type(getscriptsource) == "function" then
        local ok, src = pcall(getscriptsource)
        if ok and type(src) == "string" and #src > 200 then return src end
    end
    if type(debug) == "table" and type(debug.info) == "function" then
        local ok, src = pcall(debug.info, 1, "s")
        if ok and type(src) == "string" and #src > 200
            and not src:match("^%[") and not src:match("^=") then
            return src
        end
    end
end

local isRunningFromLocalFile = false
do
    if type(debug) == "table" and type(debug.info) == "function" then
        local ok, src = pcall(debug.info, 1, "s")
        if ok and type(src) == "string" and src:find("autofarm_local", 1, true) then
            isRunningFromLocalFile = true
        end
    end
    if env.RunawaysWallReloading or env.RunawaysAutoFarmLocalReloading then
        isRunningFromLocalFile = true
    end
end

local function saveSelfToDisk()
    if not hasFileAPI then return false end
    if isRunningFromLocalFile then return true end
    local src = getOwnSource()
    if not src then return false end
    ensureFolder()
    local ok = pcall(writefile, SCRIPT_PATH, src)
    if not ok then return false end
    if type(isfile) == "function" and not isfile(SCRIPT_PATH) then return false end
    return true
end

local savedLocally = hasFileAPI and (saveSelfToDisk() or (type(isfile) == "function" and isfile(SCRIPT_PATH)))

env.RunawaysWallReloading = nil
env.RunawaysAutoFarmLocalReloading = nil

-- ═══════════════════ CONFIG ═══════════════════
local Config = {
    LobbyPlaceId = 118418618261207,
    GamePlaceId  = 117311404196294,
    LobbyDelay = 3,
    GateTimeout = 165,
    RetryDelay = 10,
    KillRadius = 500,
    AutoReplay = true,
    SafeGateWait = true,
    HideInWall = true,
    EnabledByDefault = true,
    Keybind = Enum.KeyCode.RightShift,
}

-- ═══════════════════ MÓDULOS DO JOGO ═══════════════════
local dataModule = ReplicatedStorage:WaitForChild("Data")
local flow = require(ReplicatedStorage:WaitForChild("FlowClient"))
local data = require(dataModule)

-- ═══════════════════ UI ═══════════════════
local UI = {}

function UI:Create()
    local gui = Instance.new("ScreenGui")
    gui.Name = "RUNAWAYS_LocalUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset = true

    local parent = (pcall(function() return CoreGui end) and CoreGui) or player:WaitForChild("PlayerGui")
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then
        gui.Parent = player:WaitForChild("PlayerGui")
    end

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.fromOffset(320, 400)
    main.Position = UDim2.new(0, 20, 0, 80)
    main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = main

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 80)
    stroke.Thickness = 1
    stroke.Parent = main

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 34)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar

    local titleMask = Instance.new("Frame")
    titleMask.Size = UDim2.new(1, 0, 0, 17)
    titleMask.Position = UDim2.new(0, 0, 1, -17)
    titleMask.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
    titleMask.BorderSizePixel = 0
    titleMask.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -80, 1, 0)
    titleLabel.Position = UDim2.fromOffset(12, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "RUNAWAYS · LOCAL"
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 240)
    titleLabel.TextSize = 13
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(26, 26)
    minBtn.Position = UDim2.new(1, -62, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    minBtn.Text = "_"
    minBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
    minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 6)
    mc.Parent = minBtn

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(26, 26)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 40)
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 180, 190)
    closeBtn.TextSize = 16
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = titleBar
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 6)
    cc.Parent = closeBtn

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -16, 1, -44)
    content.Position = UDim2.fromOffset(8, 40)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    content.Parent = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = content

    local function newButton(text, color)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 66)
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(230, 230, 240)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamMedium
        btn.BorderSizePixel = 0
        btn.AutoButtonColor = true
        btn.Parent = content
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
        return btn
    end

    local function newToggle(text, default)
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 34)
        row.BackgroundColor3 = Color3.fromRGB(32, 32, 44)
        row.BorderSizePixel = 0
        row.Parent = content
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = row

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.fromOffset(12, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220, 220, 235)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = row

        local state = { Value = default or false, Callback = nil }

        local box = Instance.new("TextButton")
        box.Size = UDim2.fromOffset(40, 20)
        box.Position = UDim2.new(1, -50, 0.5, -10)
        box.BackgroundColor3 = state.Value and Color3.fromRGB(70, 180, 110) or Color3.fromRGB(60, 60, 80)
        box.Text = ""
        box.BorderSizePixel = 0
        box.Parent = row
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = box

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.Position = state.Value and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.fromRGB(240, 240, 250)
        knob.BorderSizePixel = 0
        knob.Parent = box
        local kc = Instance.new("UICorner")
        kc.CornerRadius = UDim.new(1, 0)
        kc.Parent = knob

        local function setValue(v, silent)
            state.Value = v
            box.BackgroundColor3 = v and Color3.fromRGB(70, 180, 110) or Color3.fromRGB(60, 60, 80)
            knob.Position = v and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            if not silent and state.Callback then
                task.spawn(state.Callback, v)
            end
        end

        box.MouseButton1Click:Connect(function()
            setValue(not state.Value)
        end)

        return {
            Value = state.Value,
            SetValue = setValue,
            OnChanged = function(cb) state.Callback = cb end,
            Instance = row,
        }
    end

    local function newLabel(text)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.fromRGB(170, 170, 190)
        lbl.TextSize = 12
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.TextWrapped = true
        lbl.Parent = content
        return lbl
    end

    local function newSection(text)
        local s = Instance.new("TextLabel")
        s.Size = UDim2.new(1, 0, 0, 22)
        s.BackgroundTransparency = 1
        s.Text = text:upper()
        s.TextColor3 = Color3.fromRGB(120, 140, 200)
        s.TextSize = 11
        s.Font = Enum.Font.GothamBold
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.Parent = content
        return s
    end

    local dragging, dragStart, startPos
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local minimized = false
    local fullSize = main.Size
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            main.Size = UDim2.fromOffset(320, 34)
            content.Visible = false
        else
            main.Size = fullSize
            content.Visible = true
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui.Enabled = false
    end)

    return {
        Gui = gui,
        Main = main,
        Content = content,
        newButton = newButton,
        newToggle = newToggle,
        newLabel = newLabel,
        newSection = newSection,
        Show = function() gui.Enabled = true end,
        Hide = function() gui.Enabled = false end,
        Toggle = function() gui.Enabled = not gui.Enabled end,
    }
end

-- ═══════════════════ HELPERS ═══════════════════
local function log(msg) print("[RUNAWAYS-LOCAL] " .. tostring(msg)) end
local function getHumanoid()
    local c = player.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- ═══════════════════ GOD MODE / KILL AURA ═══════════════════
local originalTakeDamage = flow.PlayerDamage and flow.PlayerDamage.TakeDamage
local originalAbandon = flow.Passout and flow.Passout.Abandon
local blockedRemote = function() end
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
    if flow.PlayerDamage and type(originalTakeDamage) == "function" then
        flow.PlayerDamage.TakeDamage = blockedRemote
    end
    if flow.Passout and type(originalAbandon) == "function" then
        flow.Passout.Abandon = blockedRemote
    end
    h.BreakJointsOnDeath = false
    h.RequiresNeck = false
    h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    h.Health = h.MaxHealth
    if h:GetAttribute("Downed") == true then
        h:SetAttribute("Downed", false)
        h:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

local function restoreGodMode()
    if flow.PlayerDamage and type(originalTakeDamage) == "function" then
        flow.PlayerDamage.TakeDamage = originalTakeDamage
    end
    if flow.Passout and type(originalAbandon) == "function" then
        flow.Passout.Abandon = originalAbandon
    end
    for h, st in godStates do
        if h.Parent then
            h.BreakJointsOnDeath = st.BreakJointsOnDeath
            h.RequiresNeck = st.RequiresNeck
            h:SetStateEnabled(Enum.HumanoidStateType.Dead, st.DeadEnabled)
        end
    end
    godStates = setmetatable({}, { __mode = "k" })
end

local function killAllNPCs(radius)
    local folder = workspace:FindFirstChild("NPCs")
    if not folder or not flow.NPCs or type(flow.NPCs.Damage) ~= "function" then return 0 end
    local root = getRoot()
    local killed = 0
    for _, h in folder:QueryDescendants("Humanoid") do
        local npc = h:FindFirstAncestorWhichIsA("Model")
        local nr = npc and npc:FindFirstChild("HumanoidRootPart")
        local inRange = not radius or (root and nr and (nr.Position - root.Position).Magnitude <= radius)
        if h.Health > 0 and inRange then
            local ok = pcall(flow.NPCs.Damage, h, h.Health + 1)
            if ok then killed += 1 end
        end
    end
    return killed
end

-- ═══════════════════ NOCLIP / TELEPORT ═══════════════════
local noclipActive = false
local noclipConn

local function setNoclip(active)
    noclipActive = active
    if active then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(function()
            if not noclipActive then return end
            local c = player.Character
            if not c then return end
            for _, p in c:GetDescendants() do
                if p:IsA("BasePart") and p.CanCollide then p.CanCollide = false end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    end
end

local function teleportTo(dest)
    if typeof(dest) ~= "CFrame" then return false end
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not c or not h or not r or h.Health <= 0 then return false end

    local cam = workspace.CurrentCamera
    local camCF = cam and cam.CFrame
    local camSubj = cam and cam.CameraSubject
    local camType = cam and cam.CameraType
    if cam then
        cam.CameraType = Enum.CameraType.Scriptable
        cam.CFrame = camCF
    end

    local ok = pcall(function()
        if h.SeatPart then
            h.Sit = false
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
            RunService.Heartbeat:Wait()
        end
        c:PivotTo(dest)
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
        RunService.Heartbeat:Wait()
    end)

    if cam and cam.Parent then
        cam.CameraSubject = camSubj
        cam.CameraType = camType
        cam.CFrame = camCF
    end
    return ok
end

local function streamAround(pos)
    pcall(function() player:RequestStreamAroundAsync(pos, 5) end)
end

-- ═══════════════════ LOCALIZAR BOTÃO / PAREDE ═══════════════════
local function getEndZ()
    local flowModule = ReplicatedStorage:FindFirstChild("FlowClient")
    local gui = flowModule and flowModule:FindFirstChild("Gui")
    local distModule = gui and gui:FindFirstChild("DistanceToBorderClient")
    if distModule then
        local ok, mod = pcall(require, distModule)
        if ok and type(mod) == "table" then
            local cb = mod.SetEndPos_event or mod.SetEndPos
            if type(cb) == "function" and debug and type(debug.getupvalues) == "function" then
                local r, uv = pcall(debug.getupvalues, cb)
                if r and type(uv) == "table" then
                    if type(uv[1]) == "number" then return uv[1] end
                    for _, v in uv do
                        if type(v) == "number" and math.abs(v) > 1000 then return v end
                    end
                end
            end
        end
    end
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if pg then
        for _, l in pg:GetDescendants() do
            if l:IsA("TextLabel") and l.Text:find("Mexico", 1, true) then
                local cur = l.Parent
                while cur and cur ~= pg do
                    local v = tonumber(cur.Name:match("^Border_(-?[%d%.]+)$"))
                    if v then return v end
                    cur = cur.Parent
                end
            end
        end
    end
end

local function getStartCFrame()
    local sp = workspace:FindFirstChildOfClass("SpawnLocation")
    if not sp or not sp.Enabled then return end
    local ex = { sp }
    if player.Character then ex[#ex + 1] = player.Character end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = ex
    p.RespectCanCollide = true
    local res = workspace:Raycast(sp.Position + Vector3.yAxis * 6, -Vector3.yAxis * 20, p)
    local y = res and res.Position.Y + 3.5 or sp.Position.Y + 3
    return CFrame.new(sp.Position.X, y, sp.Position.Z) * sp.CFrame.Rotation
end

local function getEndPrompt()
    local map = workspace:FindFirstChild("Map")
    local bld = map and map:FindFirstChild("Buildings")
    local cust = bld and bld:FindFirstChild("CustomsFinal")
    if not cust then return end
    local cb = cust:FindFirstChild("CustomsBuilding")
    local fd = cb and cb:FindFirstChild("FinalDoor")
    local cmd = fd and fd:FindFirstChild("Command")
    local btn = cmd and cmd:FindFirstChild("CommandButton")
    local holder = btn and btn:FindFirstChild("Prompt")
    local pr = holder and (holder:IsA("ProximityPrompt") and holder or holder:FindFirstChildOfClass("ProximityPrompt"))
    if pr then return pr end
    local ok, cands = pcall(cust.QueryDescendants, cust, "ProximityPrompt")
    if ok then
        for _, c in cands do
            if c.ActionText == "Activate" and c:FindFirstAncestor("FinalDoor") then return c end
        end
    end
end

local function getEndPromptDestination(prompt, dir)
    local holder = prompt and prompt.Parent
    local hcf
    if holder and holder:IsA("Attachment") then hcf = holder.WorldCFrame
    elseif holder and holder:IsA("BasePart") then hcf = holder.CFrame end
    if not hcf then return end
    local out = hcf.LookVector
    if out.Z * dir > 0 then out = -out end
    if math.abs(out.Z) < 0.25 then out = Vector3.new(0, 0, -dir) end
    local pos = hcf.Position + out * 4
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    p.FilterDescendantsInstances = player.Character and { player.Character } or {}
    local r = workspace:Raycast(pos + Vector3.yAxis * 20, Vector3.new(0, -60, 0), p)
    if r then pos = Vector3.new(pos.X, r.Position.Y + 3.25, pos.Z) end
    return CFrame.lookAt(pos, Vector3.new(hcf.Position.X, pos.Y, hcf.Position.Z), Vector3.yAxis)
end

local function getWallHideCFrame(prompt)
    local holder = prompt and prompt.Parent
    if not holder then return end
    local base
    if holder:IsA("Attachment") then base = holder.WorldPosition
    elseif holder:IsA("BasePart") then base = holder.Position end
    if not base then return end

    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = player.Character and { player.Character } or {}
    local parts = workspace:GetPartBoundsInBox(CFrame.new(base), Vector3.new(24, 24, 24), params)

    local bestWall, bestDist = nil, math.huge
    for _, part in parts do
        if part:IsA("BasePart") and part.CanCollide and part.Transparency < 0.95 and part.Size.Y > 3 then
            local d = (part.Position - base).Magnitude
            if d > 2 and d < bestDist then bestWall, bestDist = part, d end
        end
    end

    if bestWall then
        local playerRoot = getRoot()
        local targetY = base.Y
        if playerRoot then targetY = playerRoot.Position.Y end
        local hidePos = Vector3.new(bestWall.Position.X, targetY, bestWall.Position.Z)
        return CFrame.new(hidePos), bestWall
    end
    return nil, nil
end

-- ═══════════════════ GATE ═══════════════════
local function getFinalDoor(prompt)
    local fd = prompt and prompt:FindFirstAncestor("FinalDoor")
    if fd then return fd end
    local map = workspace:FindFirstChild("Map")
    local b = map and map:FindFirstChild("Buildings")
    local c = b and b:FindFirstChild("CustomsFinal")
    return c and c:FindFirstChild("FinalDoor", true)
end

local function getGateTimer(prompt)
    local fd = getFinalDoor(prompt)
    if not fd then return end
    local ok, labels = pcall(fd.QueryDescendants, fd, "TextLabel")
    if not ok then
        labels = {}
        for _, i in fd:GetDescendants() do
            if i:IsA("TextLabel") then labels[#labels + 1] = i end
        end
    end
    for _, l in labels do
        local t = l.Text
        local m, s = t:match("(%d+)%s*m%s*(%d+)%s*s")
        if not m then m, s = t:match("(%d+)%s*:%s*(%d+)") end
        if m and s then return tonumber(m) * 60 + tonumber(s), t end
    end
end

local function getGatePassage(prompt, dir, endZ)
    local fd = getFinalDoor(prompt)
    local cmd = fd and fd:FindFirstChild("Command", true)
    local lh = fd and fd:FindFirstChild("DoorL")
    local rh = fd and fd:FindFirstChild("DoorR")
    local ld = lh and lh:FindFirstChild("Door", true)
    local rd = rh and rh:FindFirstChild("Door", true)
    local pos
    if ld and ld:IsA("BasePart") and rd and rd:IsA("BasePart") then
        pos = (ld.Position + rd.Position) * 0.5
    end
    if not pos and fd then
        local ok, parts = pcall(fd.QueryDescendants, fd, "BasePart")
        if ok then
            for _, part in parts do
                if part.CanCollide and part.Transparency < 0.95 and part.Size.Y >= 4
                    and (not cmd or not part:IsDescendantOf(cmd))
                then
                    pos = pos or part.Position
                end
            end
        end
    end
    if not pos then
        local holder = prompt and prompt.Parent
        if holder and holder:IsA("Attachment") then pos = holder.WorldPosition
        elseif holder and holder:IsA("BasePart") then pos = holder.Position end
    end
    if not pos then return end
    local p = RaycastParams.new()
    p.FilterType = Enum.RaycastFilterType.Exclude
    local ex = {}
    if player.Character then ex[#ex + 1] = player.Character end
    if fd then ex[#ex + 1] = fd end
    p.FilterDescendantsInstances = ex
    p.RespectCanCollide = true
    local hit = workspace:Raycast(pos + Vector3.yAxis * 30, -Vector3.yAxis * 80, p)
    if hit then pos = Vector3.new(pos.X, hit.Position.Y + 3.5, pos.Z) end
    return { Position = pos, Direction = dir, FinalDoor = fd, DoorL = ld, DoorR = rd }
end

local function isGatePassageOpen(p)
    if not p or typeof(p.Position) ~= "Vector3" then return false end
    local fd = p.FinalDoor
    if not fd or not fd.Parent then
        fd = getFinalDoor()
        p.FinalDoor = fd
    end
    if fd then
        local lh = fd:FindFirstChild("DoorL")
        local rh = fd:FindFirstChild("DoorR")
        local cl = lh and lh:FindFirstChild("Door", true)
        local cr = rh and rh:FindFirstChild("Door", true)
        if cl and cl:IsA("BasePart") then p.DoorL = cl end
        if cr and cr:IsA("BasePart") then p.DoorR = cr end
    end
    local ld, rd = p.DoorL, p.DoorR
    if ld and ld.Parent and ld:IsA("BasePart") and rd and rd.Parent and rd:IsA("BasePart") then
        local diff = ld.Position - rd.Position
        if diff.Magnitude > 0.1 then
            local ax = diff.Unit
            local lHalf = math.abs(ld.CFrame.RightVector:Dot(ax)) * ld.Size.X * 0.5
                + math.abs(ld.CFrame.UpVector:Dot(ax)) * ld.Size.Y * 0.5
                + math.abs(ld.CFrame.LookVector:Dot(ax)) * ld.Size.Z * 0.5
            local rHalf = math.abs(rd.CFrame.RightVector:Dot(ax)) * rd.Size.X * 0.5
                + math.abs(rd.CFrame.UpVector:Dot(ax)) * rd.Size.Y * 0.5
                + math.abs(rd.CFrame.LookVector:Dot(ax)) * rd.Size.Z * 0.5
            local mid = (ld.Position + rd.Position) * 0.5
            p.Position = Vector3.new(mid.X, p.Position.Y, mid.Z)
            return diff.Magnitude - lHalf - rHalf >= 12
        end
    end
    local pr = RaycastParams.new()
    pr.FilterType = Enum.RaycastFilterType.Exclude
    pr.FilterDescendantsInstances = player.Character and { player.Character } or {}
    pr.RespectCanCollide = true
    local d = Vector3.new(0, 0, p.Direction)
    return workspace:Raycast(p.Position - d * 10, d * 20, pr) == nil
end

local function isGateWindowOpen()
    if flow.CrimesGui and type(flow.CrimesGui.StartEndTimer_event) == "function"
        and debug and type(debug.getupvalues) == "function" then
        local ok, v = pcall(debug.getupvalues, flow.CrimesGui.StartEndTimer_event)
        if ok and type(v) == "table" then
            local o, c = tonumber(v[2]), tonumber(v[3])
            local now = workspace:GetServerTimeNow()
            if o and c and now >= o and now < c then return true end
        end
    end
    local pg = player:FindFirstChildOfClass("PlayerGui")
    local hud = pg and pg:FindFirstChild("HudGui")
    local ev = hud and hud:FindFirstChild("Events")
    local cl = ev and ev:FindFirstChild("Closing")
    if not cl or not cl.Visible then return false end
    local t = cl:FindFirstChild("Timer")
    local txt = t and t.Text or ""
    local m, s = txt:match("(%d+)%s*:%s*(%d+)")
    return not m or tonumber(m) * 60 + tonumber(s) > 0
end

-- ═══════════════════ END SCREEN / REPLAY ═══════════════════
local lastEndScan = 0

local function isVisible(inst)
    local pg = player:FindFirstChildOfClass("PlayerGui")
    local cur = inst
    while cur and cur ~= pg do
        if cur:IsA("GuiObject") and not cur.Visible then return false end
        if cur:IsA("LayerCollector") and not cur.Enabled then return false end
        cur = cur.Parent
    end
    return cur == pg
end

local function getEndScreen()
    local pg = player:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local ef = pg:FindFirstChild("EndFrame", true)
    if ef then
        if not isVisible(ef) then return end
        local esc = ef:FindFirstChild("Escaped", true)
        local cap = ef:FindFirstChild("Captured", true)
        if esc and isVisible(esc) then return ef, "Escaped" end
        if cap and isVisible(cap) then return ef, "Captured" end
        for _, i in ef:GetDescendants() do
            if i:IsA("GuiObject") and isVisible(i) then
                local t = (i:IsA("TextLabel") or i:IsA("TextButton")) and i.Text:lower() or ""
                if t:find("escaped", 1, true) then return ef, "Escaped" end
                if t:find("captured", 1, true) then return ef, "Captured" end
            end
        end
        return ef, "Ended"
    end
    if os.clock() - lastEndScan < 1 then return end
    lastEndScan = os.clock()
    for _, i in pg:GetDescendants() do
        if i:IsA("GuiObject") and isVisible(i) then
            local t = (i:IsA("TextLabel") or i:IsA("TextButton")) and i.Text:lower() or ""
            if t:find("escaped", 1, true) then return nil, "Escaped" end
            if t:find("captured", 1, true) then return nil, "Captured" end
        end
    end
end

local function getReplayButton(ef)
    if not ef then return end
    local function matches(b)
        if not b:IsA("GuiButton") or not isVisible(b) then return false end
        local n = b.Name:lower()
        local t = b:IsA("TextButton") and tostring(b.Text or ""):lower() or ""
        if t == "" then
            local l = b:FindFirstChildWhichIsA("TextLabel", true)
            t = l and tostring(l.Text or ""):lower() or ""
        end
        return n:find("replay", 1, true) ~= nil or t:find("replay", 1, true) ~= nil
    end
    local d = ef:FindFirstChild("Replay", true)
    if d then
        if matches(d) then return d end
        local n = d:FindFirstChildWhichIsA("GuiButton", true)
        if n and matches(n) then return n end
    end
    for _, b in ef:GetDescendants() do
        if matches(b) then return b end
    end
end

local function requestReplay(btn)
    if flow.GameManager and type(flow.GameManager.Replay) == "function" then
        local ok, r = pcall(flow.GameManager.Replay)
        if ok and r ~= false then return true end
    end
    if btn then
        if type(firesignal) == "function" then
            local ok = pcall(firesignal, btn.MouseButton1Click)
            if ok then return true end
        else
            local ok = pcall(btn.Activate, btn)
            if ok then return true end
        end
    end
    return false
end

-- ═══════════════════ QUEUE ON TELEPORT (LOCAL) ═══════════════════
local function getQueueFunction()
    if type(queue_on_teleport) == "function" then return queue_on_teleport end
    if type(queueonteleport) == "function" then return queueonteleport end
    if type(syn) == "table" and type(syn.queue_on_teleport) == "function" then return syn.queue_on_teleport end
    if type(fluxus) == "table" and type(fluxus.queue_on_teleport) == "function" then return fluxus.queue_on_teleport end
end

local function queueReload(reason)
    local qf = getQueueFunction()
    if not qf then
        log("queue_on_teleport indisponível — não vai recarregar")
        return false
    end

    if not savedLocally then
        log("Arquivo local indisponível — reload não funciona")
        return false
    end

    local payload = string.format(
        "if not game:IsLoaded() then game.Loaded:Wait() end\n"
        .. "local e = getgenv and getgenv() or _G\n"
        .. "e.RunawaysWallReloading = true\n"
        .. "local ok, err = pcall(function()\n"
        .. "    loadstring(readfile(%q))()\n"
        .. "end)\n"
        .. "if not ok then\n"
        .. "    warn('[RUNAWAYS] reload failed: ' .. tostring(err))\n"
        .. "end",
        SCRIPT_PATH
    )

    local ok, err = pcall(qf, payload)
    if not ok then
        log("Falha ao armar queue: " .. tostring(err))
        return false
    end
    log("Reload armado (" .. reason .. ")")
    return true
end

-- ═══════════════════ AUTOFARM ═══════════════════
local AutoFarm = {
    Running = false,
    Token = nil,
    RunActive = false,
    ActiveRunToken = nil,
    Teleporting = false,
    Phase = "Idle",
    Detail = "Ready",
    LastError = "None",
    RunStartedAt = 0,
    GateStartedAt = 0,
    ResultBusy = false,
    Stats = {
        Attempts = 0, Completed = 0, Failed = 0,
        GateActivations = 0, NPCAttacks = 0, Retries = 0, Replays = 0,
    },
    Labels = {},
}

function AutoFarm:SetPhase(phase, detail)
    self.Phase = phase
    self.Detail = detail or ""
    log(phase .. (detail and (" | " .. detail) or ""))
    if self.Labels.Status then
        self.Labels.Status.Text = "• " .. phase .. "\n  " .. self.Detail
    end
end

function AutoFarm:UpdateUI()
    if not self.Labels.Runs then return end
    local s = self.Stats
    self.Labels.Runs.Text = string.format(
        "Runs: %d ok / %d start | %d fail",
        s.Completed, s.Attempts, s.Failed
    )
    self.Labels.Extra.Text = string.format(
        "Gates: %d | NPCs: %d | Replays: %d",
        s.GateActivations, s.NPCAttacks, s.Replays
    )
end

local function getContext()
    if game.PlaceId == Config.LobbyPlaceId then return "Lobby" end
    if game.PlaceId == Config.GamePlaceId then return "Game" end
    if flow.LobbyServer and type(flow.LobbyServer.create) == "function" then return "Lobby" end
    if workspace:FindFirstChild("Map") and flow.NPCs then return "Game" end
    return "Unknown"
end

local function getOwnedCar()
    if not flow.PlayerDataClient or type(flow.PlayerDataClient.getObserver) ~= "function" then return end
    local ok, obs = pcall(flow.PlayerDataClient.getObserver, "cars")
    if not ok or not obs or type(obs.get) ~= "function" then return end
    local r, cars = pcall(obs.get, obs)
    if not r or type(cars) ~= "table" then return end
    local names = {}
    for n in cars do names[#names + 1] = tostring(n) end
    table.sort(names)
    return names[1]
end

local function runLobby(token)
    if not flow.LobbyServer
        or type(flow.LobbyServer.play) ~= "function"
        or type(flow.LobbyServer.create) ~= "function"
        or type(flow.LobbyServer.exit) ~= "function"
    then
        return false, "Lobby API indisponível"
    end

    AutoFarm:SetPhase("Lobby", "Aguardando " .. Config.LobbyDelay .. "s")
    local exp = os.clock() + Config.LobbyDelay
    repeat task.wait(0.1) until os.clock() >= exp or not AutoFarm.Running or AutoFarm.Token ~= token
    if not AutoFarm.Running or AutoFarm.Token ~= token then return true end

    local car = getOwnedCar()
    if not car then return false, "Nenhum carro disponível" end

    local pg = player:FindFirstChildOfClass("PlayerGui")
    local cgui = pg and (pg:FindFirstChild("CreateLobbyGui") or pg:WaitForChild("CreateLobbyGui", 10))
    if not cgui then return false, "CreateLobbyGui indisponível" end

    queueReload("game")

    for attempt = 1, 2 do
        if not AutoFarm.Running or AutoFarm.Token ~= token then return true end
        local cf = cgui:FindFirstChild("Frame")
        local ef = cgui:FindFirstChild("Exit")
        if ef and ef.Visible then
            pcall(flow.LobbyServer.exit)
            local exp2 = os.clock() + 5
            repeat task.wait(0.1) until not ef.Visible or os.clock() >= exp2
        end
        if not cf or not cf.Visible then
            pcall(flow.LobbyServer.play)
            local exp3 = os.clock() + 10
            repeat
                if AutoFarm.Teleporting then return true end
                task.wait(0.2)
            until (cf and cf.Visible) or (ef and ef.Visible) or os.clock() >= exp3
        end
        cf = cgui:FindFirstChild("Frame")
        ef = cgui:FindFirstChild("Exit")
        if ef and ef.Visible then
            pcall(flow.LobbyServer.exit)
            task.wait(attempt * 1.5)
            continue
        end
        if not cf or not cf.Visible then
            task.wait(attempt)
            continue
        end
        AutoFarm:SetPhase("Criando", "Carro: " .. car)
        cf.Visible = false
        pcall(flow.LobbyServer.create, { maxPlayers = 1, permissions = "Friends", car = car })
        local exp4 = os.clock() + 20
        repeat task.wait(0.2) until AutoFarm.Teleporting or os.clock() >= exp4
        if AutoFarm.Teleporting then return true end
        task.wait(attempt * 2)
    end
    return false, "Criação falhou"
end

local function runGame(token)
    if getEndScreen() then
        return AutoFarm:HandleEndScreen(token)
    end

    AutoFarm:SetPhase("Aguardando mapa", "")

    local exp = os.clock() + 30
    repeat
        local h = getHumanoid()
        local r = getRoot()
        if h and r and h.Health > 0 and workspace:FindFirstChild("Map") then break end
        task.wait(0.25)
    until not AutoFarm.Running or AutoFarm.Token ~= token or os.clock() >= exp
    if not AutoFarm.Running or AutoFarm.Token ~= token then return true end

    local endZ
    exp = os.clock() + 20
    repeat
        endZ = getEndZ()
        if not endZ then task.wait(0.25) end
    until endZ or not AutoFarm.Running or AutoFarm.Token ~= token or os.clock() >= exp
    if not endZ then return false, "endZ indisponível" end

    local start = getStartCFrame()
    local dir = (not start or endZ >= start.Position.Z) and 1 or -1

    AutoFarm:SetPhase("Teleportando", "endZ=" .. tostring(endZ))
    local prompt = getEndPrompt()
    if not prompt then
        local nearPos = Vector3.new(500, 2000, endZ - dir * 30)
        streamAround(nearPos)
        teleportTo(CFrame.new(nearPos))
        task.wait(0.5)
        exp = os.clock() + 15
        repeat
            prompt = getEndPrompt()
            if not prompt then task.wait(0.3) end
        until prompt or os.clock() >= exp
    end
    if not prompt then return false, "Prompt não encontrado" end

    local dest = getEndPromptDestination(prompt, dir)
    if not dest then return false, "Destino indisponível" end
    streamAround(dest.Position)
    teleportTo(dest)
    task.wait(0.4)

    AutoFarm:SetPhase("Ativando", "Botão do portão")
    local activated = false
    local before = getGateTimer(prompt)
    for attempt = 1, 3 do
        if not AutoFarm.Running or AutoFarm.Token ~= token then return true end
        if type(fireproximityprompt) == "function" then
            pcall(fireproximityprompt, prompt)
        end
        local exp2 = os.clock() + 4
        repeat
            local secs = getGateTimer(prompt)
            if not prompt.Enabled or (secs and before and secs < before) or (secs and secs < 120) then
                activated = true
                break
            end
            task.wait(0.25)
        until os.clock() >= exp2
        if activated then break end
        AutoFarm.Stats.Retries += 1
        task.wait(attempt)
    end
    if not activated then return false, "Ativação falhou" end
    AutoFarm.Stats.GateActivations += 1
    AutoFarm.GateStartedAt = os.time()
    AutoFarm:SetPhase("Portão ativado", "Esperando 2 minutos")

    local hideCF = nil
    if Config.HideInWall then
        hideCF = getWallHideCFrame(prompt)
        if hideCF then
            setNoclip(true)
            teleportTo(hideCF)
            task.wait(0.2)
            local r = getRoot()
            if r then
                r.Anchored = true
                r.CFrame = hideCF
            end
            AutoFarm:SetPhase("Escondido", "Parede + noclip + god mode")
        else
            AutoFarm:SetPhase("Sem parede", "God mode normal")
        end
    else
        AutoFarm:SetPhase("Esperando", "God mode + kill aura")
    end

    local gateStart = os.time()
    exp = os.clock() + Config.GateTimeout
    while AutoFarm.Running and AutoFarm.Token == token and os.clock() < exp do
        local h = getHumanoid()
        if h then applyGodMode(h) end
        AutoFarm.Stats.NPCAttacks += killAllNPCs(Config.KillRadius)

        local r = getRoot()
        if r and hideCF then
            r.CFrame = hideCF
            r.AssemblyLinearVelocity = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            r.Anchored = true
        end

        local ef, outcome = getEndScreen()
        if ef or outcome then
            setNoclip(false)
            return AutoFarm:HandleEndScreen(token)
        end

        local elapsed = os.time() - gateStart
        local passage = getGatePassage(prompt, dir, endZ)
        local passageOK = passage and isGatePassageOpen(passage)
        if passageOK or isGateWindowOpen() or elapsed >= 120 then
            break
        end
        task.wait(0.3)
    end
    setNoclip(false)
    if not AutoFarm.Running or AutoFarm.Token ~= token then return true end

    AutoFarm:SetPhase("Atravessando", "Portão aberto")
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    if not h then return false, "Personagem indisponível" end
    h.Health = h.MaxHealth

    if Config.AutoReplay then
        queueReload("replay")
    else
        queueReload("lobby")
    end

    local passage = getGatePassage(prompt, dir, endZ)
    if passage then
        local finishOffset = math.max(12, (endZ - passage.Position.Z) * dir + 12)
        local savedCollisions = {}
        for _, part in c:GetDescendants() do
            if part:IsA("BasePart") then
                savedCollisions[part] = part.CanCollide
                part.CanCollide = false
            end
        end
        for _, offset in { -10, 6, finishOffset, finishOffset + 40, finishOffset + 90 } do
            local pos = passage.Position + Vector3.new(0, 0, dir * offset)
            teleportTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, dir), Vector3.yAxis))
            task.wait(0.4)
            if AutoFarm.Teleporting then break end
            if getEndScreen() then break end
        end
        for part, cc in savedCollisions do
            if part.Parent then part.CanCollide = cc end
        end
    end

    AutoFarm:SetPhase("Aguardando fim", "")
    exp = os.clock() + 35
    repeat
        if AutoFarm.Teleporting then return true end
        local ef, outcome = getEndScreen()
        if ef or outcome then
            return AutoFarm:HandleEndScreen(token)
        end
        task.wait(0.3)
    until os.clock() >= exp

    return false, "Fim não apareceu"
end

function AutoFarm:HandleEndScreen(token)
    if self.ResultBusy then return false, "Resultado já em processamento" end
    local ef, outcome = getEndScreen()
    if not ef and not outcome then return false, "Sem tela de resultado" end
    self.ResultBusy = true

    if outcome == "Ended" then
        local exp = os.clock() + 2
        repeat
            task.wait(0.1)
            ef, outcome = getEndScreen()
        until outcome ~= "Ended" or not ef or not self.Running or self.Token ~= token or os.clock() >= exp
    end

    if outcome == "Escaped" then
        self.Stats.Completed += 1
    else
        self.Stats.Failed += 1
    end
    self:UpdateUI()

    if Config.AutoReplay and self.Running and self.Token == token then
        self:SetPhase("Replay", "Solicitando")
        local exp2 = os.clock() + 45
        local nextReq = os.clock()
        local requests = 0
        local hiddenAt

        repeat
            if self.Teleporting then self.ResultBusy = false; return true end

            local cur = getEndScreen()
            if not cur then
                hiddenAt = hiddenAt or os.clock()
                if hiddenAt and os.clock() - hiddenAt >= 1 then
                    self.Stats.Replays += 1
                    self.ResultBusy = false
                    self:UpdateUI()
                    task.wait(1)
                    return true, "Replay iniciado"
                end
            else
                hiddenAt = nil
                if os.clock() >= nextReq and requests < 12 then
                    local btn = getReplayButton(cur)
                    if btn or os.clock() >= nextReq + 2 then
                        local ok = requestReplay(btn)
                        requests += 1
                        nextReq = os.clock() + 2
                        if ok and requests == 1 then
                            self.Stats.Replays += 1
                            self:UpdateUI()
                        end
                    end
                end
            end
            task.wait(0.25)
        until not self.Running or self.Token ~= token or os.clock() >= exp2

        self.ResultBusy = false
        return true, "Timeout do replay"
    end

    self.ResultBusy = false
    return true
end

function AutoFarm:ReleaseRun(token)
    if self.ActiveRunToken ~= token then return end
    self.RunActive = false
    self.ActiveRunToken = nil
    if self.Running and self.Token and self.Token ~= token then
        task.spawn(self.Run, self, self.Token)
    end
end

function AutoFarm:Run(token)
    if self.RunActive then return end
    self.RunActive = true
    self.ActiveRunToken = token
    local failures = 0

    while self.Running and self.Token == token do
        local executed, ok, msg = xpcall(function()
            local ctx = getContext()
            if ctx == "Lobby" then return runLobby(token) end
            if ctx == "Game" then return runGame(token) end
            return false, "Place desconhecido: " .. tostring(game.PlaceId)
        end, function(m)
            if type(debug) == "table" and type(debug.traceback) == "function" then
                local r, t = pcall(debug.traceback, tostring(m), 2)
                if r then return t end
            end
            return tostring(m)
        end)

        if not executed then
            msg = ok
            ok = false
            setNoclip(false)
            self.ResultBusy = false
        end

        if ok and msg == "Replay iniciado" and not self.Teleporting
            and self.Running and self.Token == token then
            failures = 0
            task.wait(1)
            continue
        end

        if ok or self.Teleporting or not self.Running or self.Token ~= token then
            self:ReleaseRun(token)
            return
        end

        failures += 1
        self.Stats.Retries += 1
        self.LastError = tostring(msg or "Erro desconhecido")
        self:SetPhase("Retry", self.LastError)
        self:UpdateUI()

        local exp = os.clock() + math.min(Config.RetryDelay * failures, 30)
        repeat task.wait(0.25)
        until not self.Running or self.Token ~= token or os.clock() >= exp
    end
    self:ReleaseRun(token)
end

function AutoFarm:Start()
    if self.Running then return end
    self.Running = true
    self.RunActive = false
    self.Teleporting = false
    self.ResultBusy = false
    self.Token = {}
    self.Stats.Attempts += 1
    self:SetPhase("Iniciando", "Contexto: " .. getContext())

    task.spawn(function()
        local token = self.Token
        while self.Running and self.Token == token do
            local ctx = getContext()
            if ctx == "Game" then
                local h = getHumanoid()
                if h then applyGodMode(h) end
                self.Stats.NPCAttacks += killAllNPCs(Config.KillRadius)
            end
            task.wait(ctx == "Game" and 0.4 or 1)
        end
    end)

    task.spawn(function()
        local token = self.Token
        while self.Running and self.Token == token do
            local ctx = getContext()
            if ctx == "Game" and not self.ResultBusy and not self.RunActive then
                local ef = getEndScreen()
                if ef then
                    setNoclip(false)
                    self.RunActive = false
                    self.ActiveRunToken = nil
                    self:SetPhase("Recuperando", "Tela de resultado detectada")
                    task.spawn(self.Run, self, token)
                end
            end
            task.wait(ctx == "Game" and 0.5 or 1)
        end
    end)

    task.spawn(self.Run, self, self.Token)
    self:UpdateUI()
end

function AutoFarm:Stop()
    if not self.Running then return end
    self.Running = false
    self.Token = nil
    self.RunActive = false
    self.ActiveRunToken = nil
    setNoclip(false)
    restoreGodMode()
    self:SetPhase("Parado", "AutoFarm desligado")
end

-- ═══════════════════ EVENTOS ═══════════════════
player.OnTeleport:Connect(function(state)
    if not AutoFarm.Running then return end
    if state == Enum.TeleportState.Started or state == Enum.TeleportState.InProgress then
        AutoFarm.Teleporting = true
        AutoFarm:SetPhase("Teleportando", "Indo para o próximo servidor")
    end
end)

TeleportService.TeleportInitFailed:Connect(function(failedPlayer, result, message)
    if failedPlayer ~= player then return end
    AutoFarm.Teleporting = false
    AutoFarm.LastError = tostring(message)
    AutoFarm:SetPhase("Teleport falhou", AutoFarm.LastError)
    task.wait(10)
    local target = getContext() == "Lobby" and Config.GamePlaceId or Config.GamePlaceId
    queueReload("retry")
    pcall(TeleportService.Teleport, TeleportService, target, player)
end)

-- ═══════════════════ MONTAR UI ═══════════════════
local ui = UI:Create()

ui.newSection("Auto Farm")
local startBtn = ui.newButton("▶  INICIAR AUTO FARM", Color3.fromRGB(40, 120, 70))
local stopBtn = ui.newButton("■  PARAR", Color3.fromRGB(120, 40, 50))

ui.newSection("Configurações")
local hideToggle = ui.newToggle("Esconder na parede (noclip)", Config.HideInWall)
hideToggle.OnChanged(function(v) Config.HideInWall = v end)

ui.newToggle("God mode durante espera", true)
ui.newToggle("Kill aura durante espera", true)

ui.newSection("Status")
AutoFarm.Labels.Status = ui.newLabel("• Idle\n  Ready")
AutoFarm.Labels.Runs = ui.newLabel("Runs: 0 ok / 0 start | 0 fail")
AutoFarm.Labels.Extra = ui.newLabel("Gates: 0 | NPCs: 0 | Replays: 0")

ui.newSection("Sistema")
local infoLbl = ui.newLabel(savedLocally and "✓ Arquivo local salvo" or "⚠ Sem writefile — reload desligado")
infoLbl.TextColor3 = savedLocally and Color3.fromRGB(120, 200, 140) or Color3.fromRGB(220, 160, 80)
ui.newLabel("Tecla: RightShift (mostrar/ocultar UI)")

startBtn.MouseButton1Click:Connect(function()
    AutoFarm:Start()
end)

stopBtn.MouseButton1Click:Connect(function()
    AutoFarm:Stop()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Config.Keybind then
        ui.Toggle()
    end
end)

-- ═══════════════════ INICIALIZAÇÃO ═══════════════════
log("Contexto: " .. getContext() .. " | Place: " .. tostring(game.PlaceId))
log(savedLocally and ("Arquivo local: " .. SCRIPT_PATH) or "Arquivo local NÃO disponível")

AutoFarm:UpdateUI()

if Config.EnabledByDefault then
    task.defer(function()
        AutoFarm:Start()
    end)
end

env.RunawaysLocalAutoFarm = AutoFarm