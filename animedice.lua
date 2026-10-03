-- ============================================================
-- ANIME DICE - Script 100% local (sem HTTP, sem loadstring)
-- Autor: DFoxy
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

player.Idled:Connect(function()
   VirtualUser:CaptureController()
   VirtualUser:ClickButton2(Vector2.new())
end)

local Network = ReplicatedStorage:WaitForChild("Network")
local equipBestRemote      = Network:WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("EquipBest")
local equipBestTowerRemote = Network:WaitForChild("Towers"):WaitForChild("RE"):WaitForChild("EquipBestTowerTeam")
local rebirthRemote        = Network:WaitForChild("RebirthService"):WaitForChild("RE"):WaitForChild("Rebirth")
local collectRemote        = Network:WaitForChild("PlotService"):WaitForChild("RE"):WaitForChild("CollectBalance")
local claimDailyRemote     = Network:WaitForChild("DailyRewardService"):WaitForChild("RE"):WaitForChild("Claim")

local old = playerGui:FindFirstChild("DFoxyUI")
if old then old:Destroy() end

local COR_FUNDO        = Color3.fromRGB(18, 22, 38)
local COR_TITULO       = Color3.fromRGB(30, 90, 200)
local COR_LARANJA      = Color3.fromRGB(240, 130, 40)
local COR_BOTAO        = Color3.fromRGB(40, 90, 170)
local COR_BOTAO_OFF    = Color3.fromRGB(40, 70, 120)
local COR_TEXTO        = Color3.fromRGB(255, 255, 255)
local COR_SECAO        = Color3.fromRGB(255, 160, 70)
local COR_SLIDER_FUNDO = Color3.fromRGB(25, 45, 80)

local gui = Instance.new("ScreenGui")
gui.Name = "DFoxyUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 320, 0, 420)
main.Position = UDim2.new(0.5, -160, 0.5, -210)
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
   ColorSequenceKeypoint.new(1, COR_LARANJA)
})
gradTitle.Rotation = 0
gradTitle.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -45, 1, 0)
titleText.Position = UDim2.new(0, 10, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "Anime Dice - by DFoxy"
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

local minimized = false
closeBtn.MouseButton1Click:Connect(function()
   minimized = not minimized
   if minimized then
      main.Size = UDim2.new(0, 320, 0, 35)
      closeBtn.Text = "+"
   else
      main.Size = UDim2.new(0, 320, 0, 420)
      closeBtn.Text = "X"
   end
end)

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

local function addButton(name, callback)
   local b = Instance.new("TextButton")
   b.Size = UDim2.new(1, 0, 0, 32)
   b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
   b.Text = name
   b.TextColor3 = COR_TEXTO
   b.Font = Enum.Font.Gotham
   b.TextSize = 13
   b.BorderSizePixel = 0
   b.Parent = content
   Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

   local g = Instance.new("UIGradient")
   g.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, COR_BOTAO),
      ColorSequenceKeypoint.new(1, COR_LARANJA)
   })
   g.Rotation = 15
   g.Parent = b

   b.MouseButton1Click:Connect(function()
      local ok, err = pcall(callback)
      if not ok then warn("[DFoxy] erro:", err) end
   end)
end

local function addToggle(name, default, onChange)
   local state = default or false
   local b = Instance.new("TextButton")
   b.Size = UDim2.new(1, 0, 0, 32)
   b.BackgroundColor3 = state and COR_LARANJA or COR_BOTAO_OFF
   b.Text = name .. (state and "  [ON]" or "  [OFF]")
   b.TextColor3 = COR_TEXTO
   b.Font = Enum.Font.Gotham
   b.TextSize = 13
   b.TextXAlignment = Enum.TextXAlignment.Left
   b.BorderSizePixel = 0
   b.Parent = content
   local p = Instance.new("UIPadding")
   p.PaddingLeft = UDim.new(0, 10)
   p.Parent = b
   Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)

   local function set(v)
      state = v
      b.Text = name .. (state and "  [ON]" or "  [OFF]")
      b.BackgroundColor3 = state and COR_LARANJA or COR_BOTAO_OFF
      if onChange then onChange(state) end
   end
   b.MouseButton1Click:Connect(function() set(not state) end)
end

local function addSlider(name, minV, maxV, default, onChange)
   local value = default
   local holder = Instance.new("Frame")
   holder.Size = UDim2.new(1, 0, 0, 48)
   holder.BackgroundColor3 = COR_BOTAO_OFF
   holder.BorderSizePixel = 0
   holder.Parent = content
   Instance.new("UICorner", holder).CornerRadius = UDim.new(0, 6)

   local label = Instance.new("TextLabel")
   label.Size = UDim2.new(1, -20, 0, 20)
   label.Position = UDim2.new(0, 10, 0, 2)
   label.BackgroundTransparency = 1
   label.Text = name .. ": " .. value
   label.TextColor3 = COR_TEXTO
   label.TextXAlignment = Enum.TextXAlignment.Left
   label.Font = Enum.Font.Gotham
   label.TextSize = 12
   label.Parent = holder

   local bar = Instance.new("Frame")
   bar.Size = UDim2.new(1, -20, 0, 8)
   bar.Position = UDim2.new(0, 10, 0, 30)
   bar.BackgroundColor3 = COR_SLIDER_FUNDO
   bar.BorderSizePixel = 0
   bar.Parent = holder
   Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 4)

   local fill = Instance.new("Frame")
   fill.Size = UDim2.new((value - minV) / (maxV - minV), 0, 1, 0)
   fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
   fill.BorderSizePixel = 0
   fill.Parent = bar
   Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

   local gFill = Instance.new("UIGradient")
   gFill.Color = ColorSequence.new({
      ColorSequenceKeypoint.new(0, COR_TITULO),
      ColorSequenceKeypoint.new(1, COR_LARANJA)
   })
   gFill.Parent = fill

   local drag = false
   local function update(x)
      local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
      value = math.floor(minV + rel * (maxV - minV) + 0.5)
      fill.Size = UDim2.new((value - minV) / (maxV - minV), 0, 1, 0)
      label.Text = name .. ": " .. value
      if onChange then onChange(value) end
   end

   bar.InputBegan:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
         or input.UserInputType == Enum.UserInputType.Touch then
         drag = true
         update(input.Position.X)
      end
   end)
   bar.InputEnded:Connect(function(input)
      if input.UserInputType == Enum.UserInputType.MouseButton1
         or input.UserInputType == Enum.UserInputType.Touch then
         drag = false
      end
   end)
   UserInputService.InputChanged:Connect(function(input)
      if drag and (input.UserInputType == Enum.UserInputType.MouseMovement
         or input.UserInputType == Enum.UserInputType.Touch) then
         update(input.Position.X)
      end
   end)
end

local loopGen = {}
local function startLoop(key, getState, intervalFn, fn)
   loopGen[key] = (loopGen[key] or 0) + 1
   local myGen = loopGen[key]
   task.spawn(function()
      while loopGen[key] == myGen and getState() do
         pcall(fn)
         local w = intervalFn()
         task.wait(w)
      end
   end)
end

local autoEquip, autoEquipTower, autoRebirth, autoCollect, autoDaily = false, false, false, false, false
local collectDelay = 1200
local fpsOn, noclipOn, wsOn = false, false, false
local wsValue = 16

local fpsRestore = {}
local fpsHidden = {}
local fpsConn = nil
local fpsRunning = false

local FPS_OFF_CLASSES = {
   ParticleEmitter = true, Trail = true, Beam = true,
   Smoke = true, Fire = true, Sparkles = true,
   PointLight = true, SpotLight = true, SurfaceLight = true,
}

local function fpsDisableObj(o)
   pcall(function()
      local cn = o.ClassName
      if FPS_OFF_CLASSES[cn] then
         if o.Enabled then
            table.insert(fpsRestore, { o = o, p = "Enabled", v = true })
            o.Enabled = false
         end
      elseif cn == "Decal" or cn == "Texture" then
         if o.Transparency < 1 then
            table.insert(fpsRestore, { o = o, p = "Transparency", v = o.Transparency })
            o.Transparency = 1
         end
      elseif o:IsA("PostEffect") then
         if o.Enabled then
            table.insert(fpsRestore, { o = o, p = "Enabled", v = true })
            o.Enabled = false
         end
      elseif o:IsA("BasePart") and not o:IsA("Terrain") then
         if o.CastShadow then
            table.insert(fpsRestore, { o = o, p = "CastShadow", v = true })
            o.CastShadow = false
         end
         if o.Reflectance and o.Reflectance > 0 then
            table.insert(fpsRestore, { o = o, p = "Reflectance", v = o.Reflectance })
            o.Reflectance = 0
         end
      end
   end)
end

local function fpsHideObj(o)
   if o and o.Parent then
      table.insert(fpsHidden, { o = o, parent = o.Parent })
      o.Parent = nil
   end
end

local function fpsApply()
   if fpsRunning then return end
   fpsRunning = true

   pcall(function()
      table.insert(fpsRestore, { o = Lighting, p = "GlobalShadows", v = Lighting.GlobalShadows })
      Lighting.GlobalShadows = false
      table.insert(fpsRestore, { o = Lighting, p = "FogEnd", v = Lighting.FogEnd })
      Lighting.FogEnd = 1e9
      table.insert(fpsRestore, { o = Lighting, p = "FogStart", v = Lighting.FogStart })
      Lighting.FogStart = 1e9
      table.insert(fpsRestore, { o = Lighting, p = "EnvironmentDiffuseScale", v = Lighting.EnvironmentDiffuseScale })
      Lighting.EnvironmentDiffuseScale = 0
      table.insert(fpsRestore, { o = Lighting, p = "EnvironmentSpecularScale", v = Lighting.EnvironmentSpecularScale })
      Lighting.EnvironmentSpecularScale = 0
   end)

   pcall(function()
      for _, cn in ipairs({ "Sky", "Atmosphere", "Clouds" }) do
         local inst = Lighting:FindFirstChildOfClass(cn)
         if inst then fpsHideObj(inst) end
      end
   end)

   pcall(function()
      local T = workspace:FindFirstChildOfClass("Terrain")
      if T then
         table.insert(fpsRestore, { o = T, p = "WaterWaveSize", v = T.WaterWaveSize })
         T.WaterWaveSize = 0
         table.insert(fpsRestore, { o = T, p = "WaterWaveSpeed", v = T.WaterWaveSpeed })
         T.WaterWaveSpeed = 0
         table.insert(fpsRestore, { o = T, p = "WaterReflectance", v = T.WaterReflectance })
         T.WaterReflectance = 0
         table.insert(fpsRestore, { o = T, p = "Decoration", v = T.Decoration })
         T.Decoration = false
      end
   end)

   task.spawn(function()
      local count = 0
      for _, o in ipairs(workspace:GetDescendants()) do
         if not fpsRunning then return end
         fpsDisableObj(o)
         count += 1
         if count % 400 == 0 then task.wait() end
      end
   end)

   if not fpsConn then
      fpsConn = workspace.DescendantAdded:Connect(function(o)
         if fpsOn then fpsDisableObj(o) end
      end)
   end
end

local function fpsRemove()
   fpsRunning = false
   if fpsConn then
      fpsConn:Disconnect()
      fpsConn = nil
   end
   for i = #fpsHidden, 1, -1 do
      local h = fpsHidden[i]
      pcall(function() h.o.Parent = h.parent end)
   end
   fpsHidden = {}
   for _, r in ipairs(fpsRestore) do
      pcall(function() r.o[r.p] = r.v end)
   end
   fpsRestore = {}
end

addSection("EQUIP BEST")

addToggle("Auto Equip Best Anime (30s)", false, function(v)
   autoEquip = v
   if v then
      startLoop("equip", function() return autoEquip end,
         function() return 30 end,
         function() equipBestRemote:FireServer() end)
   end
end)

addToggle("Auto Equip Best Tower (30s)", false, function(v)
   autoEquipTower = v
   if v then
      startLoop("equipTower", function() return autoEquipTower end,
         function() return 30 end,
         function() equipBestTowerRemote:FireServer() end)
   end
end)

addSection("REBIRTH")

addButton("Do Rebirth (agora)", function()
   rebirthRemote:FireServer()
end)

addToggle("Auto Rebirth (10 min)", false, function(v)
   autoRebirth = v
   if v then
      startLoop("rebirth", function() return autoRebirth end,
         function() return 600 end,
         function() rebirthRemote:FireServer() end)
   end
end)

addSection("AUTO COLLECT")

local function collectAllPlots()
   for i = 1, 20 do
      pcall(function() collectRemote:FireServer(i) end)
      task.wait(0.05)
   end
end

addButton("Collect All Balance (agora)", function()
   collectAllPlots()
end)

addSlider("Intervalo (min)", 1, 120, 20, function(v)
   collectDelay = v * 60
end)

addToggle("Auto Collect Balance", false, function(v)
   autoCollect = v
   if v then
      startLoop("collect", function() return autoCollect end,
         function() return collectDelay end,
         function() collectAllPlots() end)
   end
end)

addSection("DAILY REWARD")

addButton("Claim Daily Reward (agora)", function()
   claimDailyRemote:FireServer()
end)

addToggle("Auto Claim Daily (1 hora)", false, function(v)
   autoDaily = v
   if v then
      startLoop("daily", function() return autoDaily end,
         function() return 3600 end,
         function() claimDailyRemote:FireServer() end)
   end
end)

addSection("PERFORMANCE")

addToggle("FPS Boost (efeitos visuais)", false, function(v)
   fpsOn = v
   if v then
      task.spawn(fpsApply)
   else
      pcall(fpsRemove)
   end
end)

addSection("PERSONAGEM")

addToggle("Noclip", false, function(v)
   noclipOn = v
end)

addToggle("WalkSpeed", false, function(v)
   wsOn = v
   local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
   if hum then
      hum.WalkSpeed = v and wsValue or 16
   end
end)

addSlider("WalkSpeed valor", 16, 250, 16, function(v)
   wsValue = v
   if wsOn then
      local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
      if hum then hum.WalkSpeed = v end
   end
end)

player.CharacterAdded:Connect(function(char)
   task.wait(0.5)
   local hum = char:FindFirstChildOfClass("Humanoid")
   if hum and wsOn then hum.WalkSpeed = wsValue end
end)

RunService.Stepped:Connect(function()
   if not noclipOn then return end
   local char = player.Character
   if not char then return end
   for _, p in ipairs(char:GetDescendants()) do
      if p:IsA("BasePart") and p.CanCollide then
         p.CanCollide = false
      end
   end
end)

-- ============================================================
-- UNLOAD (o hub chama isso no botão "Descarregar Tudo")
-- ============================================================
getgenv().DFoxyUnload = function()
   for k in pairs(loopGen) do
      loopGen[k] = -1
   end
   fpsRunning = false
   if fpsConn then fpsConn:Disconnect() fpsConn = nil end
   local ui = playerGui:FindFirstChild("DFoxyUI")
   if ui then ui:Destroy() end
   warn("[DFoxy] Unloaded.")
end

-- ============================================================
-- NOTIFICACAO INICIAL
-- ============================================================
local notify = Instance.new("TextLabel")
notify.Size = UDim2.new(0, 240, 0, 34)
notify.Position = UDim2.new(0, 10, 0, 10)
notify.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
notify.TextColor3 = COR_TEXTO
notify.Font = Enum.Font.GothamBold
notify.TextSize = 13
notify.Text = "  DFoxy carregado! Anti-AFK ativo."
notify.TextXAlignment = Enum.TextXAlignment.Left
notify.Parent = gui
Instance.new("UICorner", notify).CornerRadius = UDim.new(0, 6)

local gNot = Instance.new("UIGradient")
gNot.Color = ColorSequence.new({
   ColorSequenceKeypoint.new(0, COR_TITULO),
   ColorSequenceKeypoint.new(1, COR_LARANJA)
})
gNot.Parent = notify

task.delay(4, function()
   notify:TweenPosition(
      UDim2.new(0, 10, 0, -40),
      Enum.EasingDirection.Out,
      Enum.EasingStyle.Quad,
      0.5,
      true
   )
   task.wait(0.6)
   notify:Destroy()
end)
