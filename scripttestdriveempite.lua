local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- [[ ตั้งค่าคงที่ ]]
-- ============================================================
local SAFE_ZONE_CFRAME     = CFrame.new(-2540.14, 15.83, 4030.19)
local JOB_CENTER_CFRAME    = CFrame.new(-2524.55, 15.83, 4015.16)
local DEFAULT_BOUNTY_THRESHOLD = 500000

local JOB_PROMPT_RADIUS    = 20    -- รัศมีค้นหา Prompt รับงาน (studs)
local CONFIRM_WAIT_TIME    = 2.5   -- วินาทีที่รอ UI ขึ้นก่อนกดยืนยัน
local CONFIRM_RETRY_COUNT  = 8     -- จำนวนรอบ retry กดยืนยัน
local CONFIRM_RETRY_WAIT   = 0.5   -- หน่วงแต่ละรอบ retry (วินาที)
local ATM_WAIT_TIMEOUT     = 20    -- วินาทีรอตู้เกิดก่อน retry รับงาน
local VALID_CONFIRM_WORDS  = {"ยืนยัน", "confirm", "accept", "ok", "ตกลง", "รับงาน", "take job", "start"}

-- ============================================================
-- [[ สถานะ ]]
-- ============================================================
local isRunning            = false
local currentBountyThreshold = DEFAULT_BOUNTY_THRESHOLD
local cachedATMs           = {}
local hasJob               = false
local waitAtmTimer         = 0
local jobRetryCount        = 0
local MAX_JOB_RETRY        = 3    -- retry รับงานสูงสุดกี่รอบก่อนหยุดพัก

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes")
    and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ============================================================
-- 1. ระบบดักจับตู้ (Real-time cache)
-- ============================================================
local function checkAndCacheATM(obj)
    if obj:IsA("ProximityPrompt") then
        local model = obj:FindFirstAncestorWhichIsA("Model")
        if model and model.Name == "CriminalATM" then
            -- เช็คซ้ำก่อนใส่
            for _, existing in ipairs(cachedATMs) do
                if existing.prompt == obj then return end
            end
            table.insert(cachedATMs, {prompt = obj})
        end
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    checkAndCacheATM(obj)
end
Workspace.DescendantAdded:Connect(checkAndCacheATM)

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
        {Position = UDim2.new(0.5, -200, 0.5, -65)}):Play()

    task.delay(3.2, function()
        local tweenOut = TweenService:Create(introFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1})
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
MainFrame.Size = UDim2.new(0, 300, 0, 210)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -105)
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

-- แถบ Status (2 บรรทัด)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0.82, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Idle"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = MainFrame

local JobLabel = Instance.new("TextLabel")
JobLabel.Size = UDim2.new(1, -10, 0, 18)
JobLabel.Position = UDim2.new(0, 5, 0.92, 0)
JobLabel.BackgroundTransparency = 1
JobLabel.Text = "Job: None"
JobLabel.TextColor3 = Color3.fromRGB(120, 200, 120)
JobLabel.Font = Enum.Font.Gotham
JobLabel.TextSize = 11
JobLabel.TextXAlignment = Enum.TextXAlignment.Left
JobLabel.Parent = MainFrame

task.delay(3.5, function() MainFrame.Visible = true end)

BountyBox.FocusLost:Connect(function()
    local num = tonumber(BountyBox.Text)
    if num then currentBountyThreshold = num
    else BountyBox.Text = tostring(currentBountyThreshold) end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    isRunning = not isRunning
    if isRunning then
        ToggleBtn.Text = "Auto Farm : ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
        StatusLabel.Text = "Status: Starting..."
        hasJob = false
        waitAtmTimer = 0
        jobRetryCount = 0
    else
        ToggleBtn.Text = "Start Auto Farm : OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
        StatusLabel.Text = "Status: Paused"
        JobLabel.Text = "Job: None"
    end
end)

-- ============================================================
-- 3. Helper Functions
-- ============================================================
local function updateStatus(text)
    if StatusLabel then StatusLabel.Text = "Status: " .. text end
    print("[UKC_ATM] " .. text)
end

local function updateJob(text)
    if JobLabel then JobLabel.Text = "Job: " .. text end
end

local function getCleanText(guiObj)
    if guiObj:IsA("TextLabel") or guiObj:IsA("TextButton") or guiObj:IsA("TextBox") then
        local raw = guiObj.ContentText ~= "" and guiObj.ContentText or guiObj.Text
        -- ลบ RichText tags
        raw = raw:gsub("<[^>]+>", "")
        return raw:lower():match("^%s*(.-)%s*$") -- trim
    end
    return ""
end

-- กดปุ่มแบบ multi-method
local function executeButtonClick(btn)
    if getconnections then
        for _, conn in pairs(getconnections(btn.MouseButton1Click)) do pcall(conn.Fire, conn) end
        for _, conn in pairs(getconnections(btn.Activated)) do pcall(conn.Fire, conn) end
    end
    if firesignal then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    -- VirtualInputManager fallback
    local absPos = btn.AbsolutePosition
    local absSize = btn.AbsoluteSize
    if absSize.X > 0 and absSize.Y > 0 then
        local inset = GuiService:GetGuiInset()
        local cx = absPos.X + absSize.X / 2
        local cy = absPos.Y + absSize.Y / 2 + inset.Y
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 1)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 1)
    end
end

-- ============================================================
-- 4. getJob() — ปรับปรุงใหม่
-- ============================================================

-- ยิง Proximity Prompt ทุก method ที่มี
local function firePromptAllMethods(prompt)
    if fireproximityprompt then
        pcall(function() fireproximityprompt(prompt) end)
    end
    if fireclickdetector then
        -- บางเกมใช้ ClickDetector แทน
        local cd = prompt.Parent and prompt.Parent:FindFirstChildWhichIsA("ClickDetector")
        if cd then pcall(function() fireclickdetector(cd) end) end
    end
end

-- สแกนหาปุ่มยืนยันใน PlayerGui อย่างเจาะลึก
local function findAndClickConfirm()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if (gui:IsA("TextButton") or gui:IsA("ImageButton")) and gui.Visible then
            local size = gui.AbsoluteSize
            if size.X < 5 or size.Y < 5 then continue end

            -- รวม text ของตัวเองและ descendant ทั้งหมด
            local combinedText = getCleanText(gui)
            for _, child in ipairs(gui:GetDescendants()) do
                combinedText = combinedText .. " " .. getCleanText(child)
            end

            for _, word in ipairs(VALID_CONFIRM_WORDS) do
                if combinedText:find(word, 1, true) then
                    print("[UKC_ATM] Found confirm button: '" .. combinedText:sub(1, 40) .. "'")
                    executeButtonClick(gui)
                    return true
                end
            end
        end
    end
    return false
end

-- ฟังก์ชันหลักรับงาน — คืนค่า true ถ้าสำเร็จ
local function getJob()
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        updateStatus("No character found, waiting...")
        return false
    end

    updateStatus("Teleporting to job center...")
    hrp.CFrame = JOB_CENTER_CFRAME
    task.wait(1.2) -- รอ server sync

    -- ---- ขั้นตอน 1: หา ProximityPrompt ในรัศมี ----
    updateStatus("Searching for job prompt...")
    local foundPrompts = {}

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") and obj.Enabled then
            local part = obj.Parent
            if part and part:IsA("BasePart") then
                local dist = (hrp.Position - part.Position).Magnitude
                if dist <= JOB_PROMPT_RADIUS then
                    table.insert(foundPrompts, {prompt = obj, dist = dist})
                end
            end
        end
    end

    -- เรียงจากใกล้ -> ไกล
    table.sort(foundPrompts, function(a, b) return a.dist < b.dist end)

    if #foundPrompts == 0 then
        updateStatus("No job prompt found nearby!")
        return false
    end

    -- ---- ขั้นตอน 2: ยิง Prompt (ลอง retry ทุกตัว) ----
    for _, data in ipairs(foundPrompts) do
        data.prompt.RequiresLineOfSight = false
        data.prompt.MaxActivationDistance = 50
        firePromptAllMethods(data.prompt)
        print("[UKC_ATM] Fired prompt: " .. data.prompt.Parent.Name .. " (dist=" .. math.floor(data.dist) .. ")")
    end

    -- ---- ขั้นตอน 3: รอ UI ขึ้น แล้ว retry กดยืนยันหลายรอบ ----
    updateStatus("Waiting for job UI...")
    task.wait(CONFIRM_WAIT_TIME)

    local confirmed = false
    for attempt = 1, CONFIRM_RETRY_COUNT do
        updateStatus("Confirming job... (attempt " .. attempt .. "/" .. CONFIRM_RETRY_COUNT .. ")")
        confirmed = findAndClickConfirm()
        if confirmed then
            updateStatus("Job accepted!")
            updateJob("Active")
            task.wait(0.8)
            return true
        end

        -- ถ้า retry รอบแรกไม่เจอ UI ให้ยิง prompt ซ้ำ
        if attempt <= 2 then
            for _, data in ipairs(foundPrompts) do
                firePromptAllMethods(data.prompt)
            end
        end

        task.wait(CONFIRM_RETRY_WAIT)
    end

    updateStatus("Could not confirm job UI!")
    updateJob("Failed")
    return false
end

-- ============================================================
-- 5. checkBounty()
-- ============================================================
local function checkBounty()
    local character = LocalPlayer.Character
    if not character then return false end

    local highestNumber = 0
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("TextLabel") then
            if obj:FindFirstAncestorWhichIsA("BillboardGui") or obj:FindFirstAncestorWhichIsA("SurfaceGui") then
                local cleanText = obj.Text:gsub(",", "")
                for numStr in cleanText:gmatch("%d+") do
                    local num = tonumber(numStr)
                    if num and num > highestNumber then highestNumber = num end
                end
            end
        end
    end

    if currentBountyThreshold > 0 and highestNumber >= currentBountyThreshold then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            updateStatus("Bounty limit! Delivering money...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(4)
            -- หลังส่งเงินเสร็จ ต้องรับงานใหม่
            hasJob = false
            waitAtmTimer = 0
            jobRetryCount = 0
            return true
        end
    end
    return false
end

-- ============================================================
-- 6. getATMs()
-- ============================================================
local function getATMs()
    local validATMs = {}
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return validATMs end

    for i = #cachedATMs, 1, -1 do
        local atmData = cachedATMs[i]
        local prompt = atmData.prompt

        if prompt and prompt.Parent and prompt.Enabled then
            local part = prompt.Parent
            local pos
            if part:IsA("BasePart") then
                pos = part.Position
            elseif part:IsA("Model") then
                pos = part:GetPivot().Position
            end

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

-- ============================================================
-- 7. bustATM()
-- ============================================================
local function bustATM(atmData)
    local prompt  = atmData.prompt
    local part    = atmData.part
    local pos     = atmData.pos
    local character = LocalPlayer.Character
    local hrp     = character and character:FindFirstChild("HumanoidRootPart")
    local camera  = Workspace.CurrentCamera

    if not hrp then return false end

    prompt.RequiresLineOfSight  = false
    prompt.MaxActivationDistance = 50
    if prompt.HoldDuration > 0 then prompt.HoldDuration = 0 end

    local standPos = pos + Vector3.new(0, 0, 2.5)
    if part:IsA("BasePart") then
        standPos = (part.CFrame * CFrame.new(0, 0, 2.5)).Position
    end

    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(pos.X, standPos.Y, pos.Z))
    if camera then
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, pos)
    end

    task.wait(0.1)

    if prompt.Enabled then
        updateStatus("Busting ATM (" .. math.floor(atmData.distance) .. " st.)")
        if fireproximityprompt then
            pcall(function() fireproximityprompt(prompt) end)
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
-- 8. MAIN LOOP
-- ============================================================
task.spawn(function()
    while true do
        task.wait(0.1)

        if isRunning then
            -- ตรวจ bounty ก่อนเสมอ
            local delivering = checkBounty()
            if delivering then continue end

            local allATMs = getATMs()

            if #allATMs > 0 then
                -- มีตู้ = รีเซ็ตทุกอย่าง
                hasJob      = true
                waitAtmTimer = 0
                jobRetryCount = 0
                bustATM(allATMs[1])

            else
                -- ไม่มีตู้
                if not hasJob then
                    -- ยังไม่มีงาน → รับงาน
                    if jobRetryCount >= MAX_JOB_RETRY then
                        -- ลองหลายรอบแล้วยังไม่ได้ หยุดพักก่อน
                        updateStatus("Job retry limit reached, resting 10s...")
                        updateJob("Resting")
                        task.wait(10)
                        jobRetryCount = 0
                    else
                        jobRetryCount = jobRetryCount + 1
                        updateStatus("Trying to get job... (try " .. jobRetryCount .. "/" .. MAX_JOB_RETRY .. ")")
                        local success = getJob()
                        if success then
                            hasJob = true
                            waitAtmTimer = 0
                        else
                            -- รับงานไม่สำเร็จ รอก่อน
                            task.wait(3)
                        end
                    end

                else
                    -- รับงานแล้ว แต่รอตู้เกิด
                    updateStatus("Waiting for ATMs... (" .. math.floor(waitAtmTimer) .. "s)")
                    waitAtmTimer = waitAtmTimer + 0.1

                    if waitAtmTimer >= ATM_WAIT_TIMEOUT then
                        -- timeout → ถือว่าบัค รีเซ็ตไปรับงานใหม่
                        updateStatus("ATM timeout, re-acquiring job...")
                        updateJob("Resetting")
                        hasJob = false
                        waitAtmTimer = 0
                        jobRetryCount = 0
                    end
                end
            end
        end
    end
end)
