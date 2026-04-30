-- ============================================================
--  Money Goal Tracker — Draggable UI, ซ่อนได้, ออกอัตโนมัติ
-- ============================================================
local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local localPlayer  = Players.LocalPlayer

local goalMoney    = 0
local currentMoney = 0
local tracking     = false

-- ============================================================
--  FIX: parseNum ที่ถูกต้อง — ไม่ใช้ argument ที่ 2 ของ tonumber
-- ============================================================
local function parseNum(s)
    -- ลบ comma และ whitespace ก่อน แล้วค่อย tonumber
    local cleaned = tostring(s):gsub(",", ""):gsub("%s+", "")
    return tonumber(cleaned) or 0
end

-- ============================================================
--  Format number → "200,000"
-- ============================================================
local function formatNum(n)
    n = math.floor(n)
    local s = tostring(n)
    local result, count = "", 0
    for i = #s, 1, -1 do
        if count > 0 and count % 3 == 0 then result = "," .. result end
        result = s:sub(i, i) .. result
        count  = count + 1
    end
    return result
end

-- ============================================================
--  ออกจากเกม
-- ============================================================
local function kickPlayer()
    pcall(function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, localPlayer)
    end)
    task.wait(2)
    pcall(function() game:Shutdown() end)
end

-- ============================================================
--  สร้าง UI
-- ============================================================
local function createUI()
    local pg  = localPlayer:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("MoneyTrackerGui")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name            = "MoneyTrackerGui"
    sg.ResetOnSpawn    = false
    sg.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    sg.IgnoreGuiInset  = true
    sg.Parent          = pg

    -- ============================================================
    --  ปุ่ม Toggle (แสดงเมื่อซ่อน UI หลัก)
    -- ============================================================
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size              = UDim2.new(0, 36, 0, 36)
    toggleBtn.Position          = UDim2.new(0, 20, 0.5, -18)
    toggleBtn.BackgroundColor3  = Color3.fromRGB(30, 30, 45)
    toggleBtn.Text              = "💰"
    toggleBtn.TextSize          = 18
    toggleBtn.Font              = Enum.Font.GothamBold
    toggleBtn.BorderSizePixel   = 0
    toggleBtn.Visible           = false
    toggleBtn.ZIndex            = 20
    toggleBtn.Parent            = sg
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)
    local ts2 = Instance.new("UIStroke", toggleBtn)
    ts2.Color = Color3.fromRGB(100, 100, 160); ts2.Thickness = 1

    -- ============================================================
    --  Frame หลัก
    -- ============================================================
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(0, 280, 0, 230)
    frame.Position         = UDim2.new(0, 20, 0.5, -115)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    frame.BorderSizePixel  = 0
    frame.ZIndex           = 10
    frame.Parent           = sg
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    local fStroke = Instance.new("UIStroke", frame)
    fStroke.Color = Color3.fromRGB(80, 80, 130); fStroke.Thickness = 1

    -- ============================================================
    --  Title bar (ลาก drag ได้)
    -- ============================================================
    local titleBar = Instance.new("Frame")
    titleBar.Size             = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 11
    titleBar.Parent           = frame
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 12)

    -- ปิดมุมล่างของ titleBar
    local titleFix = Instance.new("Frame")
    titleFix.Size             = UDim2.new(1, 0, 0, 10)
    titleFix.Position         = UDim2.new(0, 0, 1, -10)
    titleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
    titleFix.BorderSizePixel  = 0
    titleFix.ZIndex           = 11
    titleFix.Parent           = titleBar

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size               = UDim2.new(1, -80, 1, 0)
    titleLbl.Position           = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text               = "💰 Money Tracker"
    titleLbl.TextColor3         = Color3.fromRGB(200, 190, 255)
    titleLbl.Font               = Enum.Font.GothamBold
    titleLbl.TextSize           = 13
    titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
    titleLbl.ZIndex             = 12
    titleLbl.Parent             = titleBar

    -- ปุ่มซ่อน
    local hideBtn = Instance.new("TextButton")
    hideBtn.Size             = UDim2.new(0, 26, 0, 26)
    hideBtn.Position         = UDim2.new(1, -62, 0, 5)
    hideBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
    hideBtn.Text             = "—"
    hideBtn.TextColor3       = Color3.fromRGB(200, 200, 255)
    hideBtn.Font             = Enum.Font.GothamBold
    hideBtn.TextSize         = 14
    hideBtn.BorderSizePixel  = 0
    hideBtn.ZIndex           = 13
    hideBtn.Parent           = titleBar
    Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

    -- ปุ่มปิด
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 26, 0, 26)
    closeBtn.Position         = UDim2.new(1, -32, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    closeBtn.Text             = "✕"
    closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 13
    closeBtn.BorderSizePixel  = 0
    closeBtn.ZIndex           = 13
    closeBtn.Parent           = titleBar
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

    -- Divider
    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, -24, 0, 1)
    div.Position         = UDim2.new(0, 12, 0, 38)
    div.BackgroundColor3 = Color3.fromRGB(70, 70, 110)
    div.BorderSizePixel  = 0
    div.Parent           = frame

    -- เงินปัจจุบัน
    local curLbl = Instance.new("TextLabel")
    curLbl.Size               = UDim2.new(1, -24, 0, 22)
    curLbl.Position           = UDim2.new(0, 12, 0, 48)
    curLbl.BackgroundTransparency = 1
    curLbl.Text               = "เงินตอนนี้: --"
    curLbl.TextColor3         = Color3.fromRGB(140, 220, 140)
    curLbl.Font               = Enum.Font.Gotham
    curLbl.TextSize           = 13
    curLbl.TextXAlignment     = Enum.TextXAlignment.Left
    curLbl.Parent             = frame

    -- เป้าหมาย
    local goalLbl = Instance.new("TextLabel")
    goalLbl.Size               = UDim2.new(1, -24, 0, 22)
    goalLbl.Position           = UDim2.new(0, 12, 0, 70)
    goalLbl.BackgroundTransparency = 1
    goalLbl.Text               = "เป้าหมาย: ยังไม่ตั้ง"
    goalLbl.TextColor3         = Color3.fromRGB(255, 200, 80)
    goalLbl.Font               = Enum.Font.Gotham
    goalLbl.TextSize           = 13
    goalLbl.TextXAlignment     = Enum.TextXAlignment.Left
    goalLbl.Parent             = frame

    -- Progress bar bg
    local barBg = Instance.new("Frame")
    barBg.Size             = UDim2.new(1, -24, 0, 10)
    barBg.Position         = UDim2.new(0, 12, 0, 98)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 65)
    barBg.BorderSizePixel  = 0
    barBg.Parent           = frame
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 5)

    local barFill = Instance.new("Frame")
    barFill.Size             = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(80, 200, 120)
    barFill.BorderSizePixel  = 0
    barFill.Parent           = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 5)

    -- % label
    local pctLbl = Instance.new("TextLabel")
    pctLbl.Size               = UDim2.new(1, -24, 0, 18)
    pctLbl.Position           = UDim2.new(0, 12, 0, 112)
    pctLbl.BackgroundTransparency = 1
    pctLbl.Text               = ""
    pctLbl.TextColor3         = Color3.fromRGB(130, 130, 180)
    pctLbl.Font               = Enum.Font.Gotham
    pctLbl.TextSize           = 11
    pctLbl.TextXAlignment     = Enum.TextXAlignment.Left
    pctLbl.Parent             = frame

    -- Input bg
    local inputBg = Instance.new("Frame")
    inputBg.Size             = UDim2.new(1, -24, 0, 34)
    inputBg.Position         = UDim2.new(0, 12, 0, 136)
    inputBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    inputBg.BorderSizePixel  = 0
    inputBg.Parent           = frame
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)
    local iStroke = Instance.new("UIStroke", inputBg)
    iStroke.Color = Color3.fromRGB(80, 80, 140); iStroke.Thickness = 1

    local input = Instance.new("TextBox")
    input.Size               = UDim2.new(1, -16, 1, -8)
    input.Position           = UDim2.new(0, 8, 0, 4)
    input.BackgroundTransparency = 1
    input.PlaceholderText    = "ใส่เป้าหมาย เช่น 500000"
    input.PlaceholderColor3  = Color3.fromRGB(90, 90, 130)
    input.Text               = ""
    input.TextColor3         = Color3.fromRGB(220, 220, 255)
    input.Font               = Enum.Font.Gotham
    input.TextSize           = 13
    input.ClearTextOnFocus   = false
    input.Parent             = inputBg

    -- Set Goal button
    local setBtn = Instance.new("TextButton")
    setBtn.Size             = UDim2.new(1, -24, 0, 34)
    setBtn.Position         = UDim2.new(0, 12, 0, 180)
    setBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 210)
    setBtn.Text             = "ตั้งเป้าหมาย & เริ่ม Track"
    setBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    setBtn.Font             = Enum.Font.GothamBold
    setBtn.TextSize         = 13
    setBtn.BorderSizePixel  = 0
    setBtn.Parent           = frame
    Instance.new("UICorner", setBtn).CornerRadius = UDim.new(0, 8)

    -- ============================================================
    --  Update UI
    -- ============================================================
    local function updateUI()
        curLbl.Text = "เงินตอนนี้: $" .. formatNum(currentMoney)
        if goalMoney > 0 then
            local pct = math.min(currentMoney / goalMoney, 1)
            goalLbl.Text = "เป้าหมาย: $" .. formatNum(goalMoney)
            barFill.Size = UDim2.new(pct, 0, 1, 0)
            barFill.BackgroundColor3 = pct >= 1
                and Color3.fromRGB(60, 220, 90)
                or  Color3.fromRGB(80, 160, 255)
            local remain = math.max(goalMoney - currentMoney, 0)
            pctLbl.Text = string.format("%.1f%%  — เหลืออีก $%s", pct * 100, formatNum(remain))
        end
    end

    -- ============================================================
    --  Drag ได้ (InputBegan บน titleBar)
    -- ============================================================
    local dragging, dragStart, startPos = false, nil, nil

    titleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
        end
    end)

    UserInput.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInput.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ============================================================
    --  ปุ่มซ่อน / แสดง
    -- ============================================================
    hideBtn.MouseButton1Click:Connect(function()
        frame.Visible      = false
        toggleBtn.Visible  = true
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        frame.Visible      = true
        toggleBtn.Visible  = false
    end)

    -- ============================================================
    --  ปุ่มปิด
    -- ============================================================
    closeBtn.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    -- ============================================================
    --  ตั้งเป้าหมาย
    -- ============================================================
    setBtn.MouseButton1Click:Connect(function()
        local raw = parseNum(input.Text)
        if raw <= 0 then
            goalLbl.Text      = "⚠️ กรอกตัวเลขให้ถูกต้อง"
            goalLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        goalMoney          = raw
        goalLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
        tracking           = true
        updateUI()
        if currentMoney >= goalMoney then
            goalLbl.Text = "✅ ครบแล้ว! ออกใน 3 วิ..."
            task.delay(3, kickPlayer)
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
if not hudGui then warn("[Tracker] ไม่พบ HUD GUI") return end

local moneyLabel = hudGui
    :WaitForChild("HUD")
    :WaitForChild("MainHUD")
    :WaitForChild("SideHUD")
    :WaitForChild("BL-Row3")
    :WaitForChild("Money")
    :WaitForChild("Holder")
    :WaitForChild("Money", 10)

if not moneyLabel then warn("[Tracker] ไม่พบ Money label") return end
print("[Tracker] ✅ พบ Money label:", moneyLabel:GetFullName())

-- ============================================================
--  เริ่ม UI + อ่านค่าแรก
-- ============================================================
local updateUI   = createUI()
currentMoney     = parseNum(moneyLabel.Text)
updateUI()

-- ============================================================
--  Hook เงินเปลี่ยน
-- ============================================================
local lastText = moneyLabel.Text

moneyLabel:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = moneyLabel.Text
    if newText == lastText then return end
    lastText     = newText
    currentMoney = parseNum(newText)
    updateUI()

    if tracking and goalMoney > 0 and currentMoney >= goalMoney then
        tracking = false
        -- แจ้งเตือน
        local pg  = localPlayer:FindFirstChild("PlayerGui")
        local sg2 = pg and pg:FindFirstChild("MoneyTrackerGui")
        if sg2 then
            local f = sg2:FindFirstChildOfClass("Frame")
            if f then
                local notif = Instance.new("Frame")
                notif.Size             = UDim2.new(1, 0, 0, 38)
                notif.Position         = UDim2.new(0, 0, 1, -38)
                notif.BackgroundColor3 = Color3.fromRGB(30, 160, 70)
                notif.BorderSizePixel  = 0
                notif.ZIndex           = 15
                notif.Parent           = f
                Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 12)
                local nl = Instance.new("TextLabel", notif)
                nl.Size               = UDim2.new(1, 0, 1, 0)
                nl.BackgroundTransparency = 1
                nl.Text               = "✅ ครบเป้าแล้ว! ออกใน 3 วิ..."
                nl.TextColor3         = Color3.fromRGB(255, 255, 255)
                nl.Font               = Enum.Font.GothamBold
                nl.TextSize           = 13
                nl.ZIndex             = 16
            end
        end
        task.delay(3, kickPlayer)
    end
end)

print("[Tracker] 🎯 พร้อมทำงาน!")
