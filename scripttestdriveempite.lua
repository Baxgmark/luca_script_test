local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [[ ตั้งค่าคงที่ ]]
-- ============================================================
local SAFE_ZONE_CFRAME         = CFrame.new(-2540.14, 15.83, 4030.19)
local DEFAULT_BOUNTY_THRESHOLD = 500000

local ATM_BUST_RETRIES         = 3     -- จำนวนรอบ retry กดตีตู้ต่อตู้
local ATM_BUST_RETRY_WAIT      = 0.2   -- หน่วงระหว่าง retry (วินาที)
local ATM_BUST_COOLDOWN        = 0.15  -- หน่วงหลังกดสำเร็จ (วินาที)
local LOOP_WAIT                = 0.08  -- หน่วง main loop (วินาที)
local BOUNTY_DELIVER_WAIT      = 4     -- รอหลังส่งเงิน (วินาที)
local CACHE_CLEAN_INTERVAL     = 5     -- รอบ loop ที่จะ clean cache (ทุก N รอบ)

-- ============================================================
-- [[ สถานะ ]]
-- ============================================================
local isRunning                = false
local currentBountyThreshold   = DEFAULT_BOUNTY_THRESHOLD
local cachedATMs               = {}
local loopCount                = 0

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes")
    and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ============================================================
-- 1. ระบบดักจับตู้ (Real-time cache)
-- ============================================================
local function checkAndCacheATM(obj)
    if not obj:IsA("ProximityPrompt") then return end
    local model = obj:FindFirstAncestorWhichIsA("Model")
    if not model or model.Name ~= "CriminalATM" then return end

    for _, existing in ipairs(cachedATMs) do
        if existing.prompt == obj then return end
    end

    table.insert(cachedATMs, { prompt = obj, model = model })
end

-- สแกนครั้งแรก
for _, obj in ipairs(Workspace:GetDescendants()) do
    checkAndCacheATM(obj)
end
Workspace.DescendantAdded:Connect(checkAndCacheATM)

-- ล้าง cache ที่ prompt หายไปแล้ว
local function cleanATMCache()
    for i = #cachedATMs, 1, -1 do
        local data = cachedATMs[i]
        local ok = data.prompt
            and data.prompt.Parent ~= nil
            and data.model ~= nil
            and data.model.Parent ~= nil
        if not ok then
            table.remove(cachedATMs, i)
        end
    end
end

-- ============================================================
-- 2. UI
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

    TweenService:Create(container, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -200, 0.5, -65) }):Play()

    task.delay(3.2, function()
        local tweenOut = TweenService:Create(introFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 })
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
MainFrame.Size = UDim2.new(0, 300, 0, 185)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -92)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

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
ToggleBtn.Position = UDim2.new(0.1, 0, 0.25, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
ToggleBtn.Text = "Start Auto Farm : OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 16
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)

local BountyLabel = Instance.new("TextLabel")
BountyLabel.Size = UDim2.new(0.4, 0, 0, 30)
BountyLabel.Position = UDim2.new(0.1, 0, 0.58, 0)
BountyLabel.BackgroundTransparency = 1
BountyLabel.Text = "Limit Bounty:"
BountyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
BountyLabel.Font = Enum.Font.Gotham
BountyLabel.TextSize = 14
BountyLabel.TextXAlignment = Enum.TextXAlignment.Left
BountyLabel.Parent = MainFrame

local BountyBox = Instance.new("TextBox")
BountyBox.Size = UDim2.new(0.4, 0, 0, 30)
BountyBox.Position = UDim2.new(0.5, 0, 0.58, 0)
BountyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
BountyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
BountyBox.Text = tostring(DEFAULT_BOUNTY_THRESHOLD)
BountyBox.Font = Enum.Font.Gotham
BountyBox.TextSize = 14
BountyBox.ClearTextOnFocus = false
BountyBox.Parent = MainFrame
Instance.new("UICorner", BountyBox).CornerRadius = UDim.new(0, 6)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0.83, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local ATMCountLabel = Instance.new("TextLabel")
ATMCountLabel.Size = UDim2.new(1, -10, 0, 18)
ATMCountLabel.Position = UDim2.new(0, 5, 0.92, 0)
ATMCountLabel.BackgroundTransparency = 1
ATMCountLabel.Text = "ATMs in cache: 0"
ATMCountLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
ATMCountLabel.Font = Enum.Font.Gotham
ATMCountLabel.TextSize = 11
ATMCountLabel.TextXAlignment = Enum.TextXAlignment.Left
ATMCountLabel.Parent = MainFrame

task.delay(3.5, function() MainFrame.Visible = true end)

BountyBox.FocusLost:Connect(function()
    local num = tonumber(BountyBox.Text)
    if num then
        currentBountyThreshold = num
    else
        BountyBox.Text = tostring(currentBountyThreshold)
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "Auto Farm : ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        StatusLabel.Text = "Status: Running"
    else
        ToggleBtn.Text = "Start Auto Farm : OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        StatusLabel.Text = "Status: Paused"
    end
end)

-- ============================================================
-- 3. Helper
-- ============================================================
local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
    print("[UKC_ATM] " .. text)
end

local function updateATMCount()
    if ATMCountLabel then
        ATMCountLabel.Text = "ATMs in cache: " .. #cachedATMs
    end
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- ============================================================
-- 4. getATMs() — คืน list ตู้ที่ valid เรียงตามระยะ
-- ============================================================
local function getATMs()
    local hrp = getHRP()
    if not hrp then return {} end

    local validATMs = {}

    for i = #cachedATMs, 1, -1 do
        local data = cachedATMs[i]
        local prompt = data.prompt
        local model  = data.model

        -- ตรวจ validity
        local promptOK = prompt
            and prompt.Parent ~= nil
            and prompt.Enabled
        local modelOK = model and model.Parent ~= nil

        if not promptOK or not modelOK then
            table.remove(cachedATMs, i)
        else
            -- หา pivot position
            local pos
            local pivot = pcall(function() pos = model:GetPivot().Position end)
            if not pos then
                local primary = model.PrimaryPart
                if primary then pos = primary.Position end
            end

            if pos then
                local dist = (hrp.Position - pos).Magnitude
                table.insert(validATMs, {
                    prompt   = prompt,
                    model    = model,
                    pos      = pos,
                    distance = dist,
                })
            end
        end
    end

    table.sort(validATMs, function(a, b) return a.distance < b.distance end)
    return validATMs
end

-- ============================================================
-- 5. bustATM() — ตีตู้ พร้อม retry
-- ============================================================
local function bustATM(atmData)
    local prompt = atmData.prompt
    local model  = atmData.model
    local pos    = atmData.pos

    -- Guard: ตรวจซ้ำก่อนทำงาน
    if not prompt or prompt.Parent == nil then
        return false
    end
    if not model or model.Parent == nil then
        return false
    end

    local hrp = getHRP()
    if not hrp then return false end

    -- ปรับ prompt settings
    prompt.RequiresLineOfSight   = false
    prompt.MaxActivationDistance = 60
    if prompt.HoldDuration and prompt.HoldDuration > 0 then
        prompt.HoldDuration = 0
    end

    -- คำนวณตำแหน่งยืน (ด้านหน้าตู้)
    local standOffset = Vector3.new(0, 0, 2.5)
    local primary = model.PrimaryPart
    local standPos
    if primary then
        standPos = (primary.CFrame * CFrame.new(standOffset)).Position
    else
        standPos = pos + standOffset
    end

    -- Teleport ไปยืนหน้าตู้ หันหน้าเข้าหาตู้
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(pos.X, standPos.Y, pos.Z))

    task.wait(0.08)

    -- Retry loop
    local success = false
    for attempt = 1, ATM_BUST_RETRIES do
        -- ตรวจอีกรอบหลัง teleport
        if not prompt or prompt.Parent == nil or not prompt.Enabled then break end
        if not getHRP() then break end

        updateStatus("Busting ATM | dist=" .. math.floor(atmData.distance) .. " | try " .. attempt)

        -- Fire proximity prompt
        if fireproximityprompt then
            local ok, err = pcall(function() fireproximityprompt(prompt) end)
            if not ok then
                print("[UKC_ATM] fireproximityprompt error: " .. tostring(err))
            end
        end

        -- Invoke remote ถ้ามี
        if atmRemote then
            local ok, err = pcall(function() atmRemote:InvokeServer(model) end)
            if not ok then
                print("[UKC_ATM] atmRemote error: " .. tostring(err))
            end
        end

        -- ตรวจว่า prompt ถูก disable หลังกด (หมายถึงสำเร็จ)
        task.wait(ATM_BUST_RETRY_WAIT)
        if not prompt.Enabled or prompt.Parent == nil then
            success = true
            break
        end

        -- ถ้ายังไม่ได้ลอง re-teleport ใกล้กว่าเดิมนิดหน่อย
        if attempt < ATM_BUST_RETRIES then
            standPos = pos + Vector3.new(0, 0, 1.5)
            hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(pos.X, standPos.Y, pos.Z))
            task.wait(0.05)
        end
    end

    if success then
        updateStatus("ATM busted!")
        task.wait(ATM_BUST_COOLDOWN)
    end

    return success
end

-- ============================================================
-- 6. checkBounty()
-- ============================================================
local function checkBounty()
    local character = LocalPlayer.Character
    if not character then return false end

    local highestNumber = 0
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("TextLabel") then
            local inBillboard = obj:FindFirstAncestorWhichIsA("BillboardGui")
            local inSurface   = obj:FindFirstAncestorWhichIsA("SurfaceGui")
            if inBillboard or inSurface then
                local cleanText = obj.Text:gsub(",", "")
                for numStr in cleanText:gmatch("%d+") do
                    local num = tonumber(numStr)
                    if num and num > highestNumber then
                        highestNumber = num
                    end
                end
            end
        end
    end

    if currentBountyThreshold > 0 and highestNumber >= currentBountyThreshold then
        local hrp = getHRP()
        if hrp then
            updateStatus("Bounty limit (" .. highestNumber .. ")! Delivering...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(BOUNTY_DELIVER_WAIT)
            return true
        end
    end
    return false
end

-- ============================================================
-- 7. MAIN LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(LOOP_WAIT)

        if not isRunning then continue end

        loopCount = loopCount + 1

        -- Clean cache เป็นระยะ
        if loopCount % CACHE_CLEAN_INTERVAL == 0 then
            cleanATMCache()
            updateATMCount()
        end

        -- Guard: ต้องมี character
        local hrp = getHRP()
        if not hrp then
            updateStatus("Waiting for character...")
            task.wait(1)
            continue
        end

        -- ตรวจ bounty
        if checkBounty() then continue end

        -- หาตู้และตี
        local allATMs = getATMs()
        updateATMCount()

        if #allATMs > 0 then
            bustATM(allATMs[1])
        else
            updateStatus("No ATMs found | cache=" .. #cachedATMs)
            task.wait(0.5)
        end
    end
end)
