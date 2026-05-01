local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local BOUNTY_NAME = "Bounty"
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local JOB_CENTER_CFRAME = CFrame.new(-2524.55, 15.83, 4015.16) -- พิกัดจุดรับงาน
local DEFAULT_BOUNTY_THRESHOLD = 500000

-- สถานะของ Script
local isRunning = false
local currentBountyThreshold = DEFAULT_BOUNTY_THRESHOLD
local cachedATMs = {}
local lastScanTime = 0

-- แคช Remote
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ============================================================
-- 1. Intro Slide — UKC_SCRIPT / Develop By UKC_TEAM
-- ============================================================
local function showIntro(parentSg)
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    introFrame.BackgroundTransparency = 0.15
    introFrame.BorderSizePixel = 0
    introFrame.ZIndex = 100
    introFrame.Parent = parentSg

    local blur = Instance.new("BlurEffect")
    blur.Name = "IntroBlur"
    blur.Size = 24
    blur.Parent = Lighting

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 400, 0, 130)
    container.Position = UDim2.new(0.5, -200, 0.7, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 101
    container.Parent = introFrame

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container

    local line1 = Instance.new("TextLabel")
    line1.Size = UDim2.new(1, 0, 0, 64)
    line1.BackgroundTransparency = 1
    line1.Text = "UKC_SCRIPT"
    line1.TextColor3 = Color3.fromRGB(210, 190, 255)
    line1.Font = Enum.Font.GothamBold
    line1.TextSize = 40
    line1.TextStrokeTransparency = 0.3
    line1.TextStrokeColor3 = Color3.fromRGB(130, 80, 255)
    line1.Parent = container

    local divLine = Instance.new("Frame")
    divLine.Size = UDim2.new(0.7, 0, 0, 1)
    divLine.BackgroundColor3 = Color3.fromRGB(120, 100, 200)
    divLine.BorderSizePixel = 0
    divLine.Parent = container

    local line2 = Instance.new("TextLabel")
    line2.Size = UDim2.new(1, 0, 0, 36)
    line2.BackgroundTransparency = 1
    line2.Text = "Develop By UKC_TEAM"
    line2.TextColor3 = Color3.fromRGB(160, 150, 210)
    line2.Font = Enum.Font.Gotham
    line2.TextSize = 18
    line2.Parent = container

    local tweenIn = TweenService:Create(
        container,
        TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -200, 0.5, -65) }
    )
    tweenIn:Play()

    task.delay(3.2, function()
        local blurEffect = Lighting:FindFirstChild("IntroBlur")
        if blurEffect then blurEffect:Destroy() end
        
        local tweenOut = TweenService:Create(
            introFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        )
        tweenOut:Play()
        task.delay(0.3, function() introFrame:Destroy() end)
    end)
end

-- ============================================================
-- 2. สร้าง Main UI
-- ============================================================
local existingGui = CoreGui:FindFirstChild("UKC_AutoATM")
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UKC_AutoATM"
ScreenGui.Parent = CoreGui

showIntro(ScreenGui)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false 
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "UKC ATM AUTO FARM"
Title.TextColor3 = Color3.fromRGB(210, 190, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.8, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.1, 0, 0.3, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
ToggleBtn.Text = "Start Auto Farm : OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = MainFrame
local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local BountyLabel = Instance.new("TextLabel")
BountyLabel.Size = UDim2.new(0.4, 0, 0, 30)
BountyLabel.Position = UDim2.new(0.1, 0, 0.6, 0)
BountyLabel.BackgroundTransparency = 1
BountyLabel.Text = "Limit Bounty:"
BountyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
BountyLabel.Font = Enum.Font.Gotham
BountyLabel.TextSize = 14
BountyLabel.TextXAlignment = Enum.TextXAlignment.Left
BountyLabel.Parent = MainFrame

local BountyBox = Instance.new("TextBox")
BountyBox.Size = UDim2.new(0.4, 0, 0, 30)
BountyBox.Position = UDim2.new(0.5, 0, 0.6, 0)
BountyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BountyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
BountyBox.Text = tostring(DEFAULT_BOUNTY_THRESHOLD)
BountyBox.Font = Enum.Font.Gotham
BountyBox.TextSize = 14
BountyBox.ClearTextOnFocus = false
BountyBox.Parent = MainFrame
local BoxCorner = Instance.new("UICorner")
BoxCorner.CornerRadius = UDim.new(0, 6)
BoxCorner.Parent = BountyBox

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

task.delay(3.5, function() MainFrame.Visible = true end)

BountyBox.FocusLost:Connect(function()
    local num = tonumber(BountyBox.Text)
    if num then currentBountyThreshold = num else BountyBox.Text = tostring(currentBountyThreshold) end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "Auto Farm : ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        StatusLabel.Text = "Status: Starting..."
    else
        ToggleBtn.Text = "Start Auto Farm : OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        StatusLabel.Text = "Status: Paused"
    end
end)

-- ============================================================
-- 3. Core Logic (อัปเกรดระบบรับงานอัตโนมัติ)
-- ============================================================
local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
end

-- ฟังก์ชันกดยืนยันรับงานอัตโนมัติ (ครอบคลุมทั้ง UI และ E)
local function autoConfirmJob()
    -- 1. เช็คหา ProximityPrompt ใกล้ๆ
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") and obj.Enabled then
                local part = obj.Parent
                if part and part:IsA("BasePart") then
                    if (hrp.Position - part.Position).Magnitude <= 20 then
                        fireproximityprompt(obj)
                        task.wait(0.5)
                    end
                end
            end
        end
    end

    -- 2. เช็คหาปุ่มบนหน้าจอ UI ที่มีคำว่า "ยืนยัน" หรือ "Confirm"
    local validWords = {"ยืนยัน", "confirm", "accept", "yes", "ตกลง"}
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Visible then
            local txt = string.lower(gui.Text)
            for _, word in ipairs(validWords) do
                if string.find(txt, word) then
                    -- จำลองการคลิกโดยใช้ Executor Function
                    if getconnections then
                        for _, conn in pairs(getconnections(gui.MouseButton1Click)) do
                            pcall(function() conn:Function() end)
                            pcall(function() conn:Fire() end)
                        end
                    end
                end
            end
        end
    end
end

local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= currentBountyThreshold then
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            updateStatus("Bounty limit reached! Safe Zone...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3)
            return true
        end
    end
    return false
end

local function refreshATMCache()
    local now = tick()
    if now - lastScanTime < 10 then return end
    lastScanTime = now
    
    cachedATMs = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                table.insert(cachedATMs, {model = obj, prompt = prompt})
            end
        end
    end
end

local function getDynamicATMs()
    refreshATMCache()
    local validATMs = {}
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return validATMs end

    for _, atmData in ipairs(cachedATMs) do
        if atmData.model.Parent and atmData.prompt and atmData.prompt.Enabled then
            local dist = (hrp.Position - atmData.model:GetPivot().Position).Magnitude
            table.insert(validATMs, {model = atmData.model, prompt = atmData.prompt, distance = dist})
        end
    end

    table.sort(validATMs, function(a, b) return a.distance < b.distance end)
    return validATMs
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local atmCFrame = atmModel:GetPivot()
    local atmPos = atmCFrame.Position
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmPos.X, standPos.Y, atmPos.Z))
    task.wait(0.5) 

    if prompt and prompt.Enabled then
        updateStatus("Busting ATM (" .. math.floor(atmData.distance) .. " st.)")
        prompt.HoldDuration = 5
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.5) 
            if atmRemote then pcall(function() atmRemote:InvokeServer(atmModel) end) end
            task.wait(1.5) 
            return true
        end
    end
    return false
end

-- ============================================================
-- 4. MAIN LOOP
-- ============================================================
task.spawn(function()
    while true do
        if isRunning then
            local isCoolingDown = checkBounty()
            
            if not isCoolingDown then
                local allATMs = getDynamicATMs()
                
                -- ถ้าระบบหาตู้เจอ (มีงานแล้ว) ให้เริ่มวาร์ปไปปล้น
                if #allATMs > 0 then
                    for _, atmData in ipairs(allATMs) do
                        if not isRunning then break end
                        if checkBounty() then break end
                        
                        if atmData.model:IsDescendantOf(Workspace) then
                            bustATM(atmData)
                        end
                    end
                else
                    -- ถ้าหาตู้ไม่เจอ (อาจจะยังไม่ได้รับงาน) -> วาร์ปไปจุดรับงาน
                    updateStatus("No ATMs found! Going to job center...")
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        hrp.CFrame = JOB_CENTER_CFRAME -- วาร์ปไปพิกัดรับงาน
                        task.wait(1.5) -- รอแมพ/UI โหลด
                        
                        updateStatus("Confirming Job...")
                        autoConfirmJob() -- สั่งกดยืนยันอัตโนมัติ
                        task.wait(2) -- รอให้ตู้เกิด
                        
                        lastScanTime = 0 -- รีเซ็ตการค้นหาตู้ ให้มันแสกนตู้ใหม่ทันทีในลูปถัดไป
                    end
                end
            end
        end
        task.wait(1) 
    end
end)
