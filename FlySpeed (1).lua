-- Universal Fly + Speed + Fling + Vanish
-- RightShift para minimizar

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

local SpeedValue = 28
local FlySpeed = 45
local Flying = false
local SpeedOn = false
local FlingOn = false
local VanishOn = false
local BV, BG
local lastFling = 0
local SavedTransparency = {}

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local function startFly()
    local hrp, hum = getHRP()
    if not hrp or Flying then return end
    Flying = true
    if hum then hum.PlatformStand = true end
    BV = Instance.new("BodyVelocity")
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    BV.Parent = hrp
    BG = Instance.new("BodyGyro")
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.P = 9e4
    BG.Parent = hrp
end

local function stopFly()
    Flying = false
    if BV then BV:Destroy() BV = nil end
    if BG then BG:Destroy() BG = nil end
    local _, hum = getHRP()
    if hum then hum.PlatformStand = false end
end

local function setSpeed(on)
    SpeedOn = on
    local _, hum = getHRP()
    if hum then hum.WalkSpeed = on and SpeedValue or 16 end
end

local function setVanish(on)
    VanishOn = on
    local char = LocalPlayer.Character
    if not char then return end
    if on then
        SavedTransparency = {}
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                SavedTransparency[v] = v.Transparency
                v.Transparency = 1
            elseif v:IsA("Decal") or v:IsA("Texture") then
                SavedTransparency[v] = v.Transparency
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = false
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.NameDisplayDistance = 0
            hum.HealthDisplayDistance = 0
        end
    else
        for obj, trans in pairs(SavedTransparency) do
            if obj and obj.Parent then
                pcall(function() obj.Transparency = trans end)
            end
        end
        for _, v in pairs(char:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Fire") or v:IsA("Smoke") then
                v.Enabled = true
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.NameDisplayDistance = 100
            hum.HealthDisplayDistance = 100
        end
        SavedTransparency = {}
    end
end

local function flingTarget(targetChar)
    if not targetChar or tick() - lastFling < 2 then return end
    local thrp = targetChar:FindFirstChild("HumanoidRootPart")
    local myHRP = select(1, getHRP())
    if not thrp or not myHRP then return end
    lastFling = tick()
    pcall(function()
        local old = myHRP.CFrame
        myHRP.CFrame = thrp.CFrame * CFrame.new(0, 0, 1)
        task.wait(0.05)
        for i = 1, 4 do
            thrp.AssemblyLinearVelocity = Vector3.new(math.random(-60000, 60000), 70000, math.random(-60000, 60000))
            task.wait(0.03)
        end
        myHRP.CFrame = old
    end)
end

Mouse.Button1Down:Connect(function()
    if not FlingOn then return end
    local target = Mouse.Target
    if not target then return end
    local model = target.Parent
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    if not hum and model and model.Parent then
        model = model.Parent
        hum = model:FindFirstChildOfClass("Humanoid")
    end
    if hum and model ~= LocalPlayer.Character then
        local plr = Players:GetPlayerFromCharacter(model)
        if plr and plr ~= LocalPlayer then
            flingTarget(model)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if Flying and BV and BG then
        local cam = Camera.CFrame
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - cam.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + cam.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
        BV.Velocity = move.Magnitude > 0 and move.Unit * FlySpeed or Vector3.zero
        BG.CFrame = cam
    end
    if SpeedOn then
        local _, hum = getHRP()
        if hum and hum.WalkSpeed ~= SpeedValue then hum.WalkSpeed = SpeedValue end
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if SpeedOn then setSpeed(true) end
    if Flying then stopFly() task.wait(0.3) startFly() end
    if VanishOn then task.wait(0.2) setVanish(true) end
end)

local sg = Instance.new("ScreenGui")
sg.Name = "FlySpeedGUI"
sg.ResetOnSpawn = false
pcall(function() sg.Parent = CoreGui end)
if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Mini = Instance.new("TextButton")
Mini.Size = UDim2.new(0, 40, 0, 40)
Mini.Position = UDim2.new(0, 12, 0.5, -20)
Mini.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
Mini.Text = "FS"
Mini.TextColor3 = Color3.new(1, 1, 1)
Mini.Font = Enum.Font.GothamBold
Mini.TextSize = 14
Mini.Visible = false
Mini.Parent = sg
Instance.new("UICorner", Mini).CornerRadius = UDim.new(0, 8)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 290)
Main.Position = UDim2.new(0.5, -110, 0.5, -145)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
Main.Active = true
Main.Draggable = true
Main.Parent = sg
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 32)
Title.Position = UDim2.new(0, 10, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "Fly + Speed"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local function makeBtn(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.Parent = Main
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local flyBtn = makeBtn("Fly: OFF", 38, function()
    if Flying then
        stopFly()
        flyBtn.Text = "Fly: OFF"
        flyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    else
        startFly()
        flyBtn.Text = "Fly: ON"
        flyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
    end
end)

local speedBtn = makeBtn("Speed: OFF", 74, function()
    if SpeedOn then
        setSpeed(false)
        speedBtn.Text = "Speed: OFF"
        speedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    else
        setSpeed(true)
        speedBtn.Text = "Speed: ON (" .. SpeedValue .. ")"
        speedBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 80)
    end
end)

makeBtn("Speed +10", 110, function()
    SpeedValue = math.min(SpeedValue + 10, 80)
    if SpeedOn then setSpeed(true) speedBtn.Text = "Speed: ON (" .. SpeedValue .. ")" end
end)

makeBtn("Speed -10", 146, function()
    SpeedValue = math.max(SpeedValue - 10, 16)
    if SpeedOn then setSpeed(true) speedBtn.Text = "Speed: ON (" .. SpeedValue .. ")" end
end)

local flingBtn = makeBtn("Fling Click: OFF", 182, function()
    FlingOn = not FlingOn
    flingBtn.Text = FlingOn and "Fling Click: ON" or "Fling Click: OFF"
    flingBtn.BackgroundColor3 = FlingOn and Color3.fromRGB(120, 50, 50) or Color3.fromRGB(40, 40, 50)
end)

local vanishBtn = makeBtn("Vanish: OFF", 218, function()
    if VanishOn then
        setVanish(false)
        vanishBtn.Text = "Vanish: OFF"
        vanishBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    else
        setVanish(true)
        vanishBtn.Text = "Vanish: ON"
        vanishBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 160)
    end
end)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, -20, 0, 20)
info.Position = UDim2.new(0, 10, 0, 254)
info.BackgroundTransparency = 1
info.Text = "Vanish = invisible"
info.TextColor3 = Color3.fromRGB(140, 140, 160)
info.Font = Enum.Font.Gotham
info.TextSize = 11
info.Parent = Main

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -32, 0, 4)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 18
MinBtn.Parent = Main
MinBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Mini.Visible = true
end)

Mini.MouseButton1Click:Connect(function()
    Main.Visible = true
    Mini.Visible = false
end)

UserInputService.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
        Mini.Visible = not Main.Visible
    end
end)

print("Loaded! | Fly + Speed + Fling + Vanish")
