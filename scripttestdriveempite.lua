local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local JOB_CENTER_CFRAME = CFrame.new(-2524.55, 15.83, 4015.16)
local DEFAULT_BOUNTY_THRESHOLD = 500000

-- สถานะของ Script
local isRunning = false
local currentBountyThreshold = DEFAULT_BOUNTY_THRESHOLD
local cachedATMs = {}
local hasJob = false 
local waitAtmTimer = 0 -- ตัวนับเวลา ถ้าตู้หายไปนานเกินไปจะไปรับงานใหม่

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ============================================================
-- 1. ระบบดักจับตู้ (Real-time)
-- ============================================================
local function checkAndCacheATM(obj)
    if obj:IsA("ProximityPrompt") then
        local model = obj:FindFirstAncestorWhichIsA("Model")
        if model and model.Name == "CriminalATM" then
            table.insert(cachedATMs, {prompt = obj})
        end
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    checkAndCacheATM(obj)
end
Workspace.DescendantAdded:Connect(checkAndCacheATM)

-- ============================================================
-- 2. UI & Intro Slide 
-- ============================================================
local function showIntro(parentSg)
    local introFrame = Instance.new("Frame")
    introFrame.Size = UDim2.new(1, 0, 1, 0)
    introFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    introFrame.BackgroundTransparency = 0.15
    introFrame.BorderSizePixel = 0
    introFrame.ZIndex = 100
    introFrame.Parent = parentSg

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

    local tweenIn = TweenService:Create(container, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, -200, 0.5, -65) })
    tweenIn:Play()

    task.delay(3.2, function()
        local tweenOut = TweenService:Create(introFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
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
-- 3. Core Logic (เจาะระบบ UI)
-- ============================================================
local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
end

-- ดึง Text แบบลบโค้ดสีทิ้ง (ทะลุ RichText)
local function getCleanText(guiObj)
    if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") or guiObj:IsA("TextBox") then
        local text = guiObj.ContentText ~= "" and guiObj.ContentText or guiObj.Text
        return string.lower(text)
    end
    return ""
end

-- ยิงคำสั่งกดปุ่มแบบโหดๆ 4 รูปแบบพร้อมกัน
local function executeButtonClick(btn)
    -- วิธีที่ 1: ใช้ getconnections (คลิกรัวๆ ทุก Event)
    if getconnections then
        for _, conn in pairs(getconnections(btn.MouseButton1Click)) do pcall(function() conn:Fire() end) end
        for _, conn in pairs(getconnections(btn.MouseButton1Down)) do pcall(function() conn:Fire() end) end
        for _, conn in pairs(getconnections(btn.Activated)) do pcall(function() conn:Fire() end) end
    end
    
    -- วิธีที่ 2: ใช้ firesignal
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    
    -- วิธีที่ 3: ใช้ VirtualInputManager (แก้ GuiInset ตำแหน่งเมาส์)
    local absPos = btn.AbsolutePosition
    local absSize = btn.AbsoluteSize
    if absSize.X > 0 and absSize.Y > 0 then
        local inset = GuiService:GetGuiInset()
        local centerX = absPos.X + (absSize.X / 2)
        local centerY = absPos.Y + (absSize.Y / 2) + inset.Y -- บวกค่าขอบจอด้านบนให้คลิกตรงเป๊ะ
        
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 1)
    end
end

-- ฟังก์ชันสำหรับไปกดรับงาน
local function getJob()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    updateStatus("Going to job center...")
    hrp.CFrame = JOB_CENTER_CFRAME
    task.wait(1) -- รอแมพโหลด

    -- 1. ค้นหาปุ่ม E ของจุดรับงานและกด
    updateStatus("Pressing E Prompt...")
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                if (hrp.Position - part.Position).Magnitude <= 20 then
                    obj.RequiresLineOfSight = false
                    if fireproximityprompt then
                        fireproximityprompt(obj)
                    end
                end
            end
        end
    end
    
    task.wait(1.5) -- รอ UI อนิเมชั่นเด้งขึ้นมา

    -- 2. สแกนหาปุ่ม "ยืนยัน" บนจอและคลิก
    updateStatus("Confirming UI...")
    local validWords = {"ยืนยัน", "confirm", "accept"}
    
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible and gui.AbsoluteSize.X > 0 then
            
            -- รวม Text ทั้งหมดที่อยู่บนตัวมันและลูกๆ ของมัน
            local combinedText = getCleanText(gui)
            for _, child in ipairs(gui:GetDescendants()) do
                combinedText = combinedText .. " " .. getCleanText(child)
            end
            
            for _, word in ipairs(validWords) do
                if string.find(combinedText, word) then
                    executeButtonClick(gui)
                    updateStatus("Clicked Confirm!")
                    task.wait(1)
                    return
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
            updateStatus("Bounty limit reached! Delivering money...")
            hrp.CFrame = SAFE_ZONE_CFRAME 
            task.wait(4) 
            return true 
        end
    end
    return false
end

local function getATMs()
    local validATMs = {}
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return validATMs end

    for i = #cachedATMs, 1, -1 do
        local atmData = cachedATMs[i]
        local prompt = atmData.prompt
        
        if prompt and prompt.Parent and prompt.Enabled then
            local part = prompt.Parent
            local pos = part:IsA("BasePart") and part.Position or (part.Parent:IsA("Model") and part.Parent:GetPivot().Position)
            
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                table.insert(validATMs, {prompt = prompt, part = part, pos = pos, distance = dist})
            end
        else
            table.remove(cachedATMs, i)
        end
    end

    table.sort(validATMs, function(a, b) return a.distance < b.distance end)
    return validATMs
end

local function bustATM(atmData)
    local prompt = atmData.prompt
    local part = atmData.part
    local pos = atmData.pos
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    local camera = Workspace.CurrentCamera
    
    if not hrp then return false end

    prompt.RequiresLineOfSight = false 
    prompt.MaxActivationDistance = 50 
    if prompt.HoldDuration > 0 then prompt.HoldDuration = 0 end 

    local standPos = pos + Vector3.new(0, 0, 2.5) 
    if part:IsA("BasePart") then
        standPos = (part.CFrame * CFrame.new(0, 0, 2.5)).Position
    end
    
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(pos.X, standPos.Y, pos.Z))
    camera.CFrame = CFrame.lookAt(camera.CFrame.Position, pos)
    
    task.wait(0.1) 

    if prompt.Enabled then
        updateStatus("Busting ATM (" .. math.floor(atmData.distance) .. " st.)")
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(0.15) 
            
            if atmRemote then 
                local model = part:FindFirstAncestorWhichIsA("Model")
                if model then pcall(function() atmRemote:InvokeServer(model) end) end
            end
            
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
        task.wait(0.1) -- หน่วงนิดนึงกันเกมแครช
        
        if isRunning then
            local isDeliveringMoney = checkBounty()
            
            if not isDeliveringMoney then
                local allATMs = getATMs()
                
                if #allATMs > 0 then
                    -- มีตู้ = มีงานแล้ว รีเซ็ตตัวนับเวลาทิ้ง
                    hasJob = true 
                    waitAtmTimer = 0 
                    bustATM(allATMs[1])
                else
                    -- ถ้าไม่มีตู้
                    if not hasJob then
                        getJob()
                        hasJob = true -- พอรับงานเสร็จ ติ๊กไว้ว่ามีงานแล้ว จะได้ไม่วนกลับมากดรัวๆ
                    else
                        -- ถ้ารับงานแล้วแต่ไม่มีตู้ (รอตู้เกิด)
                        updateStatus("Waiting for ATMs to respawn...")
                        waitAtmTimer = waitAtmTimer + 0.1
                        
                        -- ถ้ารอตู้เกิดนานเกิน 15 วินาที แปลว่าบัคไม่ได้รับงาน หรือตู้บัค
                        if waitAtmTimer >= 15 then
                            hasJob = false -- รีเซ็ตให้มันกลับไปรับงานใหม่
                            waitAtmTimer = 0
                        end
                    end
                end
            end
        end
    end
end)
