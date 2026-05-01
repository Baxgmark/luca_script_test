local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local JOB_CENTER_CFRAME = CFrame.new(-2524.55, 15.83, 4015.16) -- พิกัดจุดรับงาน
local DEFAULT_BOUNTY_THRESHOLD = 500000

-- สถานะของ Script
local isRunning = false
local currentBountyThreshold = DEFAULT_BOUNTY_THRESHOLD
local cachedATMs = {}

-- แคช Remote
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ============================================================
-- 1. ระบบ Cache ตู้แบบ Real-time (เร็ว 100% ไม่มีหน่วง)
-- ============================================================
local function addATMToCache(obj)
    if obj.Name == "CriminalATM" and obj:IsA("Model") then
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt then
            -- ถ้าระบบสร้างตู้แต่ปุ่มยังไม่มา ให้รอ 0.5 วิแล้วเช็คใหม่
            task.delay(0.5, function()
                prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    table.insert(cachedATMs, {model = obj, prompt = prompt})
                end
            end)
        else
            table.insert(cachedATMs, {model = obj, prompt = prompt})
        end
    end
end

-- สแกนครั้งแรกครั้งเดียวตอนรันสคริปต์
for _, obj in ipairs(Workspace:GetDescendants()) do
    addATMToCache(obj)
end

-- ดักจับตู้ที่จะเกิดใหม่ตลอดเวลา โดยไม่ต้องวนลูปสแกนให้แลค
Workspace.DescendantAdded:Connect(addATMToCache)

-- ============================================================
-- 2. Intro Slide & UI
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
-- 3. Core Logic
-- ============================================================
local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
end

local function autoConfirmJob()
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

    local validWords = {"ยืนยัน", "confirm", "accept", "yes", "ตกลง"}
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") and gui.Visible then
            local txt = string.lower(gui.Text)
            for _, word in ipairs(validWords) do
                if string.find(txt, word) then
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
    local character = LocalPlayer.Character
    if not character then return false end

    local highestNumberFound = 0
    
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("TextLabel") then
            if obj:FindFirstAncestorWhichIsA("BillboardGui") or obj:FindFirstAncestorWhichIsA("SurfaceGui") then
                local text = obj.Text
                local cleanText = string.gsub(text, ",", "")
                
                for numberStr in string.gmatch(cleanText, "%d+") do
                    local num = tonumber(numberStr)
                    if num and num > highestNumberFound then
                        highestNumberFound = num
                    end
                end
            end
        end
    end

    if highestNumberFound >= currentBountyThreshold and currentBountyThreshold > 0 then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            updateStatus("Bounty limit reached! Safe Zone...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3)
            return true
        end
    end
    
    return false
end

-- ดึงตู้จากแคชมาคำนวณระยะ (รวดเร็วมาก)
local function getDynamicATMs()
    local validATMs = {}
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return validATMs end

    for i = #cachedATMs, 1, -1 do
        local atmData = cachedATMs[i]
        -- เช็คว่าตู้ยังอยู่ และปุ่มยังกดได้
        if atmData.model and atmData.model.Parent and atmData.prompt and atmData.prompt.Parent then
            if atmData.prompt.Enabled then
                local targetPos = atmData.prompt.Parent:IsA("BasePart") and atmData.prompt.Parent.Position or atmData.model:GetPivot().Position
                local dist = (hrp.Position - targetPos).Magnitude
                table.insert(validATMs, {model = atmData.model, prompt = atmData.prompt, distance = dist})
            end
        else
            -- ถ้าตู้พังหรือโดนลบ ให้ลบทิ้งจากแคชเลย (จัดการขยะ)
            table.remove(cachedATMs, i)
        end
    end

    table.sort(validATMs, function(a, b) return a.distance < b.distance end)
    return validATMs
end

-- [อัปเดต] ระบบหันหน้าและวาร์ปเข้าปุ่มแบบแม่นยำ 100%
local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local promptPart = prompt.Parent
    if promptPart and promptPart:IsA("BasePart") then
        -- หาตำแหน่งถอยหลังออกมาจากด้านหน้าปุ่ม (อ้างอิงจาก CFrame ของตัวปุ่ม)
        -- ทำให้ตัวละครยืนหันหน้าเข้าปุ่มเป๊ะๆ ไม่ว่าตู้จะหันไปทางไหน
        local offsetCFrame = promptPart.CFrame * CFrame.new(0, 0, 2.5) 
        
        -- ป้องกันตัวละครมุดดิน (ยึดความสูง Y เดิมของตู้/ตัวละคร)
        local standPosition = Vector3.new(offsetCFrame.Position.X, promptPart.Position.Y, offsetCFrame.Position.Z)
        local lookPosition = Vector3.new(promptPart.Position.X, promptPart.Position.Y, promptPart.Position.Z)
        
        hrp.CFrame = CFrame.lookAt(standPosition, lookPosition)
    else
        -- ระบบสำรอง กรณีที่ปุ่มไม่ได้ผูกกับพาร์ทโดยตรง
        local atmCFrame = atmModel:GetPivot()
        local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
        hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmCFrame.Position.X, standPos.Y, atmCFrame.Position.Z))
    end

    task.wait(0.3) -- รอเซิร์ฟเวอร์อัปเดตตำแหน่งให้ชัวร์ก่อนกด

    if prompt and prompt.Enabled then
        updateStatus("Busting ATM (" .. math.floor(atmData.distance) .. " st.)")
        
        -- แอบปรับลดเวลา HoldDuration ให้ไวกว่าเดิม 
        local waitTime = prompt.HoldDuration > 0 and prompt.HoldDuration or 5
        prompt.HoldDuration = 0 
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(waitTime + 0.2) -- รอเท่าเกจเวลาเดิมของมัน + เผื่อแลคนิดหน่อย
            
            if atmRemote then pcall(function() atmRemote:InvokeServer(atmModel) end) end
            task.wait(0.5) -- ลดเวลาพักรอบ จะได้ไปตู้ต่อไปไวขึ้น
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
                
                if #allATMs > 0 then
                    for _, atmData in ipairs(allATMs) do
                        if not isRunning then break end
                        if checkBounty() then break end
                        
                        if atmData.model.Parent then
                            bustATM(atmData)
                        end
                    end
                else
                    updateStatus("No ATMs found! Going to job center...")
                    local character = LocalPlayer.Character
                    local hrp = character and character:FindFirstChild("HumanoidRootPart")
                    
                    if hrp then
                        hrp.CFrame = JOB_CENTER_CFRAME 
                        task.wait(1) -- ลดเวลารอที่จุดรับงานให้เร็วขึ้น
                        
                        updateStatus("Confirming Job...")
                        autoConfirmJob() 
                        task.wait(1.5) -- รอ UI ปิด
                    end
                end
            end
        end
        task.wait(0.5) -- ลดดีเลย์ของลูปหลัก ทำให้มันเช็คสถานะไวขึ้น
    end
end)
