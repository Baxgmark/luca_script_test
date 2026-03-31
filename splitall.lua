local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

-- ============================================================
--  ⚠️ ใส่ Webhook URL ของคุณตรงนี้
-- ============================================================
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"  -- ← ใส่ของคุณ

local httprequest =
    (syn and syn.request) or
    (http and http.request) or
    http_request or
    (fluxus and fluxus.request) or
    (krnl and krnl.request) or
    request

-- ============================================================
--  Helper: ส่ง Embed ไป Discord
-- ============================================================
local function sendEmbed(title, desc, color)
    if not httprequest then warn("[Tracker] ไม่รองรับ HTTP") return end
    if #desc > 3900 then desc = desc:sub(1, 3900) .. "\n...(ตัดเพราะเกิน limit)" end
    local ok, res = pcall(function()
        return httprequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                username = "🔴 Roblox Tracker",
                embeds = {{
                    title       = title,
                    description = desc,
                    color       = color or 0x3498DB,
                    footer      = { text = "Player: " .. localPlayer.Name .. " | Game: " .. game.Name },
                    timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    end)
    if ok then
        print("[Tracker] ✅ ส่งสำเร็จ:", title, "| Status:", res.StatusCode)
    else
        warn("[Tracker] ❌ Error:", res)
    end
end

-- ============================================================
--  Helper: path ลัด ไปยัง _NetManaged
-- ============================================================
local function getNetManaged()
    return game:GetService("ReplicatedStorage")
        :WaitForChild("Modules")
        :WaitForChild("RbxNet")
        :WaitForChild("net")
        :WaitForChild("_NetManaged")
end

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
task.wait(3)
print("[Tracker] 🚀 เริ่มทำงาน...")

-- ============================================================
--  SECTION 1 — Leaderstats snapshot
-- ============================================================
local function getLeaderstatsBlock()
    local out = ""
    local ls = localPlayer:FindFirstChild("leaderstats")
    if ls then
        for _, v in ipairs(ls:GetChildren()) do
            out = out .. string.format("`%-20s` = `%s`\n", v.Name, tostring(v.Value))
        end
    else
        out = "❌ ไม่มี leaderstats"
    end
    return out
end

-- ============================================================
--  SECTION 2 — สแกน GUI หา Money Label ($, k, m, b)
-- ============================================================
local function scanMoneyLabels()
    local out = ""
    local function scan(parent, depth)
        depth = depth or 0
        if depth > 20 then return end
        for _, obj in ipairs(parent:GetChildren()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                local txt = tostring(obj.Text)
                if txt:match("%$") or
                   txt:match("%d+%.?%d*[kmb]") or
                   txt:match("^%$?%d+$") then
                    out = out .. string.format("**`%s`** → `%s`\n", txt, obj:GetFullName())
                end
            end
            scan(obj, depth + 1)
        end
    end
    scan(localPlayer:WaitForChild("PlayerGui"))
    return out ~= "" and out or "❌ ไม่พบ Label เงิน"
end

-- ============================================================
--  SECTION 3 — สร้าง snapshot รวม (Leaderstats + GUI cash)
-- ============================================================
local function buildSnapshot(label)
    local ls  = getLeaderstatsBlock()
    local gui = scanMoneyLabels()
    return string.format(
        "**📊 Leaderstats**\n%s\n**💰 Money Labels (GUI)**\n%s",
        ls, gui
    ), label
end

-- ============================================================
--  ส่ง snapshot ครั้งแรก
-- ============================================================
local snapDesc, snapLabel = buildSnapshot("Snapshot เริ่มต้น")
sendEmbed("📸 " .. snapLabel, snapDesc, 0x2ECC71)
task.wait(2)

-- ============================================================
--  SECTION 4 — Hook NotiStats (server → client sync)
-- ============================================================
local notiLog   = ""
local notiCount = 0
task.spawn(function()
    local ok, net = pcall(getNetManaged)
    if not ok then warn("[Hook] ไม่พบ _NetManaged") return end
    local ev = net:WaitForChild("NotiStats", 10)
    if not ev then warn("[Hook] ไม่พบ NotiStats") return end

    print("[Hook] ✅ เจอ NotiStats — เริ่มดัก")
    ev.OnClientEvent:Connect(function(...)
        notiCount = notiCount + 1
        local line = string.format("[#%d] ", notiCount)
        for i, v in ipairs({...}) do
            line = line .. "[arg" .. i .. "] `" .. tostring(v) .. "` "
        end
        notiLog = notiLog .. line .. "\n"
        print("[NotiStats]", line)

        -- ส่งทันทีเมื่อได้รับ event
        sendEmbed("📡 NotiStats Event", line, 0xE74C3C)
    end)
end)

-- ============================================================
--  SECTION 5 — Hook SpeedGained
-- ============================================================
local speedLog   = ""
local speedCount = 0
task.spawn(function()
    local ok, net = pcall(getNetManaged)
    if not ok then return end
    local ev = net:WaitForChild("SpeedGained", 10)
    if not ev then warn("[Hook] ไม่พบ SpeedGained") return end

    print("[Hook] ✅ เจอ SpeedGained — เริ่มดัก")
    ev.OnClientEvent:Connect(function(...)
        speedCount = speedCount + 1
        local line = string.format("[#%d] ", speedCount)
        for i, v in ipairs({...}) do
            line = line .. "[arg" .. i .. "] `" .. tostring(v) .. "` "
        end
        speedLog = speedLog .. line .. "\n"
        print("[SpeedGained]", line)

        sendEmbed("⚡ SpeedGained Event", line, 0x9B59B6)
    end)
end)

-- ============================================================
--  SECTION 6 — Hook TrophyGained
-- ============================================================
task.spawn(function()
    local ok, net = pcall(getNetManaged)
    if not ok then return end
    local ev = net:WaitForChild("TrophyGained", 10)
    if not ev then warn("[Hook] ไม่พบ TrophyGained") return end

    print("[Hook] ✅ เจอ TrophyGained — เริ่มดัก")
    ev.OnClientEvent:Connect(function(...)
        local line = ""
        for i, v in ipairs({...}) do
            line = line .. "[arg" .. i .. "] `" .. tostring(v) .. "` "
        end
        print("[TrophyGained]", line)
        sendEmbed("🏆 TrophyGained Event", line, 0xF1C40F)
    end)
end)

-- ============================================================
--  SECTION 7 — Hook Leaderstats Changed (Level, Rebirth, Wins)
-- ============================================================
task.spawn(function()
    local ls = localPlayer:WaitForChild("leaderstats", 10)
    if not ls then return end

    local function hookStat(stat)
        if not stat:IsA("ValueBase") then return end
        stat.Changed:Connect(function(newVal)
            local msg = string.format(
                "**%s** เปลี่ยนเป็น `%s`\nPath: `%s`",
                stat.Name, tostring(newVal), stat:GetFullName()
            )
            print("[Leaderstats]", stat.Name, "=", newVal)
            sendEmbed("📈 Leaderstats Changed: " .. stat.Name, msg, 0x1ABC9C)
        end)
    end

    for _, stat in ipairs(ls:GetChildren()) do hookStat(stat) end
    ls.ChildAdded:Connect(hookStat)
end)

-- ============================================================
--  SECTION 8 — Hook GUI Money Label Changed
--  (หา label เงิน $ แล้วดักการเปลี่ยนแปลง)
-- ============================================================
task.spawn(function()
    task.wait(2)
    local hooked = {}

    local function tryHookLabel(obj)
        if hooked[obj] then return end
        if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
        local txt = tostring(obj.Text)
        if txt:match("%$") or txt:match("%d+%.?%d*[kmb]") or txt:match("^%$?%d+$") then
            hooked[obj] = true
            print("[GUI Hook] ✅ Hook:", obj:GetFullName(), "→", txt)
            obj:GetPropertyChangedSignal("Text"):Connect(function()
                local newTxt = tostring(obj.Text)
                local msg = string.format(
                    "**Label:** `%s`\n**ค่าใหม่:** `%s`\n**Path:** `%s`",
                    obj.Name, newTxt, obj:GetFullName()
                )
                print("[GUI Changed]", obj:GetFullName(), "→", newTxt)
                sendEmbed("💰 GUI Money Changed", msg, 0xF39C12)
            end)
        end
    end

    local function scanAndHook(parent, depth)
        depth = depth or 0
        if depth > 20 then return end
        for _, obj in ipairs(parent:GetChildren()) do
            tryHookLabel(obj)
            scanAndHook(obj, depth + 1)
        end
    end

    local gui = localPlayer:WaitForChild("PlayerGui")
    scanAndHook(gui)

    -- ดัก label ที่เพิ่มเข้ามาทีหลัง
    gui.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        tryHookLabel(obj)
    end)
end)

-- ============================================================
--  SECTION 9 — รายงานรวมทุก 5 นาที
-- ============================================================
task.spawn(function()
    while true do
        task.wait(300)
        local desc = string.format(
            "**📊 Leaderstats**\n%s\n**💰 Money Labels (GUI)**\n%s\n\n📡 NotiStats events: `%d`\n⚡ SpeedGained events: `%d`",
            getLeaderstatsBlock(),
            scanMoneyLabels(),
            notiCount,
            speedCount
        )
        sendEmbed("🔄 รายงานสรุป (ทุก 5 นาที)", desc, 0x2ECC71)
    end
end)

print("[Tracker] ✅ ระบบทำงานครบแล้ว — Hook: Leaderstats, GUI $, NotiStats, SpeedGained, TrophyGained")