-- ============================================================
--  Money Goal Tracker — Draggable UI + Discord Logging
--  + Intro Slide: UKC_SCRIPT / Develop By UKC_TEAM (3 วิ)
-- ============================================================
local Players      = game:GetService("Players")
local UserInput    = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Lighting     = game:GetService("Lighting")
local localPlayer  = Players.LocalPlayer

local goalMoney    = 0
local currentMoney = 0
local tracking     = false

-- ========== DISCORD WEBHOOK (แก้ไขตรงนี้!) ==========
local WEBHOOK_URL = "https://discord.com/api/webhooks/1499510823222247584/uAFjR_0i7LFAgZX7C5rqeJQAVcKO_Af7ug85-p2zGvmXGtDqAIH90hEsaRFGXtFGcsmX"

-- ============================================================
--  ส่ง Log ไป Discord
-- ============================================================
local function sendToDiscord(action, details)
    if WEBHOOK_URL:find("YOUR_WEBHOOK") then return end
    
    local success, err = pcall(function()
        local data = {
            username = "Money Tracker Log",
            embeds = {{
                title = "💰 Money Tracker Log",
                color = 0x5865F2,
                fields = {
                    { name = "👤 ผู้เล่น", value = localPlayer.Name, inline = true },
                    { name = "🆔 User ID", value = tostring(localPlayer.UserId), inline = true },
                    { name = "⏰ เวลา", value = os.date("%Y-%m-%d %H:%M:%S"), inline = false },
                    { name = "🎮 เกม", value = tostring(game.PlaceId), inline = true },
                    { name = "📱 Device", value = tostring(UserInput:GetPlatform()), inline = true },
                    { name = "🔄 การกระทำ", value = action, inline = false },
                    { name = "📝 รายละเอียด", value = details, inline = false }
                },
                footer = { text = "UKC_TEAM • Money Tracker" }
            }}
        }
        
        local json = HttpService:JSONEncode(data)
        local headers = {["Content-Type"] = "application/json"}
        request({Url = WEBHOOK_URL, Method = "POST", Headers = headers, Body = json})
    end)
    
    if not success then warn("[Discord] ส่ง log ไม่สำเร็จ:", err) end
end

-- ============================================================
--  parseNum ที่ถูกต้อง
-- ============================================================
local function parseNum(s)
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
local function kickPlayer(reason)
    sendToDiscord("✅ บรรลุเป้าหมาย", string.format("เป้าหมาย: $%s | เงินปัจจุบัน: $%s\nเหตุผล: %s", 
        formatNum(goalMoney), formatNum(currentMoney), reason or "ครบเป้าหมาย"))
    task.wait(1)
    pcall(function() game:Shutdown() end)
end

-- ============================================================
--  Intro Slide — UKC_SCRIPT / Develop By UKC_TEAM (3 วิ)
-- ============================================================
local function showIntro(parentSg)
    local introFrame = Instance.new("Frame")
    introFrame.Size                   = UDim2.new(1, 0, 1, 0)
    introFrame.Position               = UDim2.new(0, 0, 0, 0)
    introFrame.BackgroundColor3       = Color3.fromRGB(10, 10, 20)
    introFrame.BackgroundTransparency = 0.15
    introFrame.BorderSizePixel        = 0
    introFrame.ZIndex                 = 100
    introFrame.Parent                 = parentSg

    -- สร้าง Blur Effect
    local blur = Instance.new("BlurEffect")
    blur.Name = "IntroBlur"
    blur.Size = 24
    blur.Parent = Lighting

    -- Container กลาง
    local container = Instance.new("Frame")
    container.Size                   = UDim2.new(0, 400, 0, 130)
    container.Position               = UDim2.new(0.5, -200, 0.7, 0)
    container.BackgroundTransparency = 1
    container.ZIndex                 = 101
    container.Parent                 = introFrame

    local layout = Instance.new("UIListLayout")
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment   = Enum.VerticalAlignment.Center
    layout.Padding             = UDim.new(0, 8)
    layout.Parent              = container

    -- บรรทัด 1: UKC_SCRIPT
    local line1 = Instance.new("TextLabel")
    line1.Size                    = UDim2.new(1, 0, 0, 64)
    line1.BackgroundTransparency  = 1
    line1.Text                    = "UKC_SCRIPT"
    line1.TextColor3              = Color3.fromRGB(210, 190, 255)
    line1.Font                    = Enum.Font.GothamBold
    line1.TextSize                = 40
    line1.TextXAlignment          = Enum.TextXAlignment.Center
    line1.TextStrokeTransparency  = 0.3
    line1.TextStrokeColor3        = Color3.fromRGB(130, 80, 255)
    line1.ZIndex                  = 102
    line1.Parent                  = container

    -- Divider เส้นบางๆ
    local divLine = Instance.new("Frame")
    divLine.Size             = UDim2.new(0.7, 0, 0, 1)
    divLine.BackgroundColor3 = Color3.fromRGB(120, 100, 200)
    divLine.BorderSizePixel  = 0
    divLine.ZIndex           = 102
    divLine.Parent           = container

    -- บรรทัด 2: Develop By UKC_TEAM
    local line2 = Instance.new("TextLabel")
    line2.Size                    = UDim2.new(1, 0, 0, 36)
    line2.BackgroundTransparency  = 1
    line2.Text                    = "Develop By UKC_TEAM"
    line2.TextColor3              = Color3.fromRGB(160, 150, 210)
    line2.Font                    = Enum.Font.Gotham
    line2.TextSize                = 18
    line2.TextXAlignment          = Enum.TextXAlignment.Center
    line2.TextStrokeTransparency  = 0.6
    line2.TextStrokeColor3        = Color3.fromRGB(80, 60, 160)
    line2.ZIndex                  = 102
    line2.Parent                  = container

    -- Slide-in ขึ้นมากลางจอ
    local tweenIn = TweenService:Create(
        container,
        TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -200, 0.5, -65) }
    )
    tweenIn:Play()

    -- ตั้งเวลาให้เบลอหายไปหลังจาก intro จบ
    task.delay(3.2, function()
        -- ทำลาย Blur Effect
        local blurEffect = Lighting:FindFirstChild("IntroBlur")
        if blurEffect then
            blurEffect:Destroy()
        end
        
        -- Fade out intro frame
        local tweenOut = TweenService:Create(
            introFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        )
        tweenOut:Play()
        
        task.delay(0.3, function()
            introFrame:Destroy()
        end)
    end)
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

    -- เรียก Intro Slide
    showIntro(sg)

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

    local div = Instance.new("Frame")
    div.Size             = UDim2.new(1, -24, 0, 1)
    div.Position         = UDim2.new(0, 12, 0, 38)
    div.BackgroundColor3 = Color3.fromRGB(70, 70, 110)
    div.BorderSizePixel  = 0
    div.Parent           = frame

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
    --  Drag ได้
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
        frame.Visible     = false
        toggleBtn.Visible = true
    end)

    toggleBtn.MouseButton1Click:Connect(function()
        frame.Visible     = true
        toggleBtn.Visible = false
    end)

    -- ============================================================
    --  ปุ่มปิด
    -- ============================================================
    closeBtn.MouseButton1Click:Connect(function()
        sendToDiscord("❌ ปิดโปรแกรม", string.format("ผู้เล่นปิด Money Tracker (เป้าหมาย $%s)", formatNum(goalMoney)))
        sg:Destroy()
    end)

    -- ============================================================
    --  ตั้งเป้าหมาย
    -- ============================================================
    setBtn.MouseButton1Click:Connect(function()
        local raw = parseNum(input.Text)
        if raw <= 0 then
            goalLbl.Text       = "⚠️ กรอกตัวเลขให้ถูกต้อง"
            goalLbl.TextColor3 = Color3.fromRGB(255, 100, 100)
            return
        end
        goalMoney          = raw
        goalLbl.TextColor3 = Color3.fromRGB(255, 200, 80)
        tracking           = true
        updateUI()
        
        -- ส่ง Log การตั้งเป้าหมาย
        sendToDiscord("🎯 ตั้งเป้าหมาย", string.format("ตั้งเป้าหมาย: $%s | เงินปัจจุบัน: $%s", 
            formatNum(goalMoney), formatNum(currentMoney)))
        
        if currentMoney >= goalMoney then
            goalLbl.Text = "✅ ครบแล้ว! ออกใน 3 วิ..."
            task.delay(3, function() kickPlayer("ตั้งเป้าหมายแล้วสำเร็จทันที") end)
        end
    end)

    return updateUI
end

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
task.wait(3)

local gui    = localPlayer:WaitForChild("PlayerGui")
local hudGui = gui:FindFirstChild("HUD")
if not hudGui then 
    warn("[Tracker] ไม่พบ HUD GUI")
    sendToDiscord("⚠️ ข้อผิดพลาด", "ไม่พบ HUD GUI ในเกมนี้")
    return 
end

local moneyLabel = nil
local success, err = pcall(function()
    moneyLabel = hudGui:WaitForChild("HUD"):WaitForChild("MainHUD"):WaitForChild("SideHUD"):WaitForChild("BL-Row3"):WaitForChild("Money"):WaitForChild("Holder"):WaitForChild("Money", 10)
end)

if not moneyLabel then 
    warn("[Tracker] ไม่พบ Money label:", err)
    sendToDiscord("⚠️ ข้อผิดพลาด", "ไม่พบ Money label ใน UI ของเกม")
    return 
end

print("[Tracker] ✅ พบ Money label:", moneyLabel:GetFullName())

-- ============================================================
--  เริ่ม UI + อ่านค่าแรก
-- ============================================================
local updateUI   = createUI()
currentMoney     = parseNum(moneyLabel.Text)
updateUI()

-- ส่ง Log การเริ่มต้น
sendToDiscord("🚀 เริ่มใช้งาน", string.format("ผู้เล่น %s เริ่มใช้ Money Tracker\nเงินเริ่มต้น: $%s", 
    localPlayer.Name, formatNum(currentMoney)))

-- ============================================================
--  Hook เงินเปลี่ยน
-- ============================================================
local lastText = moneyLabel.Text
local goalReachedNotified = false

moneyLabel:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = moneyLabel.Text
    if newText == lastText then return end
    lastText     = newText
    currentMoney = parseNum(newText)
    updateUI()

    if tracking and goalMoney > 0 and currentMoney >= goalMoney and not goalReachedNotified then
        goalReachedNotified = true
        tracking = false
        
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
        
        task.delay(3, function() kickPlayer("เก็บเงินครบเป้าหมาย") end)
    end
end)

print("[Tracker] 🎯 พร้อมทำงาน! (พร้อมส่ง Log ไป Discord)")
