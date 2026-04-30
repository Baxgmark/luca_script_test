-- ============================================================
--  Money Goal Tracker — ออก Roblox อัตโนมัติเมื่อเงินครบ
-- ============================================================
local Players     = game:GetService("Players")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local localPlayer  = Players.LocalPlayer

-- ============================================================
--  State
-- ============================================================
local goalMoney   = 0          -- เป้าหมาย (ตั้งผ่าน UI)
local currentMoney = 0         -- เงินปัจจุบัน
local tracking    = false      -- กำลัง track อยู่ไหม

-- ============================================================
--  Helper: แปลง "200,000" → number
-- ============================================================
local function parseNum(s)
    return tonumber(tostring(s):gsub(",", ""):gsub("%s", "")) or 0
end

-- ============================================================
--  Helper: format number → "200,000"
-- ============================================================
local function formatNum(n)
    local s = tostring(math.floor(n))
    local result = ""
    local count = 0
    for i = #s, 1, -1 do
        if count > 0 and count % 3 == 0 then
            result = "," .. result
        end
        result = s:sub(i, i) .. result
        count = count + 1
    end
    return result
end

-- ============================================================
--  ออกจาก Roblox
-- ============================================================
local function kickPlayer()
    game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
    task.wait(2)
    game:Shutdown()
end

-- ============================================================
--  สร้าง UI
-- ============================================================
local function createUI()
    -- ลบ UI เก่าถ้ามี
    local old = localPlayer:FindFirstChild("PlayerGui") and
                localPlayer.PlayerGui:FindFirstChild("MoneyTrackerGui")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MoneyTrackerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = localPlayer.PlayerGui

    -- กรอบหลัก
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 220)
    frame.Position = UDim2.new(0, 20, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

    -- Stroke
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 1

    -- ชื่อ Title bar
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 36)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "💰 Money Goal Tracker"
    title.TextColor3 = Color3.fromRGB(220, 210, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    -- ปุ่มปิด
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    -- Divider
    local div = Instance.new("Frame")
    div.Size = UDim2.new(1, -24, 0, 1)
    div.Position = UDim2.new(0, 12, 0, 36)
    div.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
    div.BorderSizePixel = 0
    div.Parent = frame

    -- Label: เงินปัจจุบัน
    local curLabel = Instance.new("TextLabel")
    curLabel.Size = UDim2.new(1, -24, 0, 20)
    curLabel.Position = UDim2.new(0, 12, 0, 46)
    curLabel.BackgroundTransparency = 1
    curLabel.Text = "เงินตอนนี้: --"
    curLabel.TextColor3 = Color3.fromRGB(160, 220, 160)
    curLabel.Font = Enum.Font.Gotham
    curLabel.TextSize = 13
    curLabel.TextXAlignment = Enum.TextXAlignment.Left
    curLabel.Parent = frame

    -- Label: เป้าหมาย
    local goalLabel = Instance.new("TextLabel")
    goalLabel.Size = UDim2.new(1, -24, 0, 20)
    goalLabel.Position = UDim2.new(0, 12, 0, 68)
    goalLabel.BackgroundTransparency = 1
    goalLabel.Text = "เป้าหมาย: ยังไม่ตั้ง"
    goalLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    goalLabel.Font = Enum.Font.Gotham
    goalLabel.TextSize = 13
    goalLabel.TextXAlignment = Enum.TextXAlignment.Left
    goalLabel.Parent = frame

    -- Progress bar bg
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -24, 0, 10)
    barBg.Position = UDim2.new(0, 12, 0, 96)
    barBg.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    barBg.BorderSizePixel = 0
    barBg.Parent = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 5)

    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 120)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 5)

    -- % text
    local pctLabel = Instance.new("TextLabel")
    pctLabel.Size = UDim2.new(1, -24, 0, 18)
    pctLabel.Position = UDim2.new(0, 12, 0, 110)
    pctLabel.BackgroundTransparency = 1
    pctLabel.Text = ""
    pctLabel.TextColor3 = Color3.fromRGB(140, 140, 180)
    pctLabel.Font = Enum.Font.Gotham
    pctLabel.TextSize = 12
    pctLabel.TextXAlignment = Enum.TextXAlignment.Left
    pctLabel.Parent = frame

    -- Input box
    local inputBg = Instance.new("Frame")
    inputBg.Size = UDim2.new(1, -24, 0, 34)
    inputBg.Position = UDim2.new(0, 12, 0, 134)
    inputBg.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    inputBg.BorderSizePixel = 0
    inputBg.Parent = frame
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)
    local inputStroke = Instance.new("UIStroke", inputBg)
    inputStroke.Color = Color3.fromRGB(90, 90, 140)
    inputStroke.Thickness = 1

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -16, 1, -8)
    input.Position = UDim2.new(0, 8, 0, 4)
    input.BackgroundTransparency = 1
    input.PlaceholderText = "ใส่เป้าหมายเงิน เช่น 500000"
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 140)
    input.Text = ""
    input.TextColor3 = Color3.fromRGB(220, 220, 255)
    input.Font = Enum.Font.Gotham
    input.TextSize = 13
    input.ClearTextOnFocus = false
    input.Parent = inputBg

    -- ปุ่ม Set Goal
    local setBtn = Instance.new("TextButton")
    setBtn.Size = UDim2.new(1, -24, 0, 34)
    setBtn.Position = UDim2.new(0, 12, 0, 176)
    setBtn.BackgroundColor3 = Color3.fromRGB(80, 130, 220)
    setBtn.Text = "ตั้งเป้าหมาย & เริ่ม Track"
    setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    setBtn.Font = Enum.Font.GothamBold
    setBtn.TextSize = 13
    setBtn.BorderSizePixel = 0
    setBtn.Parent = frame
    Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 8)

    -- ============================================================
    --  ฟังก์ชัน update UI
    -- ============================================================
    local function updateUI()
        curLabel.Text = "เงินตอนนี้: $" .. formatNum(currentMoney)
        if goalMoney > 0 then
            local pct = math.min(currentMoney / goalMoney, 1)
            goalLabel.Text = "เป้าหมาย: $" .. formatNum(goalMoney)
            barFill.Size = UDim2.new(pct, 0, 1, 0)
            local color = pct >= 1
                and Color3.fromRGB(80, 220, 80)
                or Color3.fromRGB(100, 180, 255)
            barFill.BackgroundColor3 = color
            pctLabel.Text = string.format("%.1f%%  ($%s เหลืออีก $%s)",
                pct * 100,
                formatNum(currentMoney),
                formatNum(math.max(goalMoney - currentMoney, 0))
            )
        end
    end

    -- ============================================================
    --  ปุ่ม Set Goal
    -- ============================================================
    setBtn.MouseButton1Click:Connect(function()
        local raw = parseNum(input.Text)
        if raw <= 0 then
            goalLabel.Text = "⚠️ กรอกตัวเลขให้ถูกต้อง"
            goalLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
            return
        end
        goalMoney = raw
        goalLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        tracking = true
        updateUI()
        -- ตรวจสอบทันที (กรณีเงินครบแล้วตอนตั้ง)
        if currentMoney >= goalMoney then
            goalLabel.Text = "✅ ครบแล้ว! กำลังออก..."
            task.delay(2, kickPlayer)
        end
    end)

    return updateUI
end

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
task.wait(3)

local gui    = localPlayer:WaitForChild("PlayerGui")
local hudGui = gui:WaitForChild("HUD", 15)
if not hudGui then
    warn("[Tracker] ไม่พบ HUD GUI")
    return
end

local moneyLabel = hudGui
    :WaitForChild("HUD")
    :WaitForChild("MainHUD")
    :WaitForChild("SideHUD")
    :WaitForChild("BL-Row3")
    :WaitForChild("Money")
    :WaitForChild("Holder")
    :WaitForChild("Money", 10)

if not moneyLabel then
    warn("[Tracker] ไม่พบ Money label")
    return
end

print("[Tracker] ✅ เจอ Money label:", moneyLabel:GetFullName())

-- ============================================================
--  เริ่ม UI
-- ============================================================
local updateUI = createUI()

-- อ่านค่าเงินแรก
currentMoney = parseNum(moneyLabel.Text)
updateUI()

-- ============================================================
--  Hook เงินเปลี่ยน
-- ============================================================
local lastText = moneyLabel.Text

moneyLabel:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = moneyLabel.Text
    if newText == lastText then return end
    lastText = newText
    currentMoney = parseNum(newText)
    updateUI()

    -- ตรวจเป้าหมาย
    if tracking and goalMoney > 0 and currentMoney >= goalMoney then
        tracking = false
        -- แจ้งเตือนใน UI
        local pg = localPlayer:FindFirstChild("PlayerGui")
        local sg = pg and pg:FindFirstChild("MoneyTrackerGui")
        if sg then
            local f = sg:FindFirstChildOfClass("Frame")
            if f then
                local notif = Instance.new("TextLabel")
                notif.Size = UDim2.new(1, 0, 0, 40)
                notif.Position = UDim2.new(0, 0, 1, -40)
                notif.BackgroundColor3 = Color3.fromRGB(40, 160, 80)
                notif.Text = "✅ ครบเป้าแล้ว! ออกใน 3 วิ..."
                notif.TextColor3 = Color3.fromRGB(255, 255, 255)
                notif.Font = Enum.Font.GothamBold
                notif.TextSize = 13
                notif.BorderSizePixel = 0
                notif.ZIndex = 10
                notif.Parent = f
                Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)
            end
        end
        task.delay(3, kickPlayer)
    end
end)

print("[Tracker] 🎯 Money Goal Tracker พร้อมทำงาน!")
