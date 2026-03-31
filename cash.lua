local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

-- ============================================================
--  ⚠️ ใส่ Webhook URL ของคุณตรงนี้
-- ============================================================
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"  -- ← ใส่ของคุณ

local httprequest =
    (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or
    (krnl and krnl.request) or request

-- ============================================================
--  Helper ส่ง Embed
-- ============================================================
local function sendEmbed(title, desc, color)
    if not httprequest then warn("[Tracker] ไม่รองรับ HTTP") return end
    if #desc > 3900 then desc = desc:sub(1, 3900) end
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                username  = "🍎 Blox Fruits Tracker",
                avatar_url = "https://www.roblox.com/asset/?id=7072706464",
                embeds = {{
                    title       = title,
                    description = desc,
                    color       = color or 0xF1C40F,
                    footer      = {
                        text = "Player: " .. localPlayer.Name ..
                               " | Game: " .. game.Name
                    },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    end)
end

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
task.wait(3)

local gui      = localPlayer:WaitForChild("PlayerGui")
local mainGui  = gui:WaitForChild("Main", 15)

if not mainGui then
    warn("[Tracker] ไม่พบ Main GUI")
    return
end

-- ============================================================
--  ดึงค่า Beli ปัจจุบันจาก label
-- ============================================================
local beliLabel = mainGui:WaitForChild("Beli", 10)

local function getBeliText()
    return beliLabel and tostring(beliLabel.Text) or "N/A"
end

-- ============================================================
--  ดึง Bounty/Honor จาก leaderstats
-- ============================================================
local function getBounty()
    local ls = localPlayer:FindFirstChild("leaderstats")
    if ls then
        local b = ls:FindFirstChild("Bounty/Honor") or ls:FindFirstChild("Bounty") or ls:FindFirstChild("Honor")
        if b then return tostring(b.Value) end
        -- fallback: เอาค่าแรกที่เจอ
        local first = ls:GetChildren()[1]
        if first then return first.Name .. ": " .. tostring(first.Value) end
    end
    return "N/A"
end

-- ============================================================
--  ส่ง snapshot ครั้งแรก
-- ============================================================
local function snapshot(label)
    local desc = string.format(
        "💰 **Beli:** `%s`\n⚔️ **Bounty/Honor:** `%s`",
        getBeliText(), getBounty()
    )
    sendEmbed("📸 " .. label, desc, 0x2ECC71)
end

snapshot("Snapshot เริ่มต้น")
task.wait(2)

-- ============================================================
--  Hook Beli label — ส่งทุกครั้งที่เงินเปลี่ยน
-- ============================================================
local lastBeli = getBeliText()

if beliLabel then
    beliLabel:GetPropertyChangedSignal("Text"):Connect(function()
        local newBeli = getBeliText()
        if newBeli == lastBeli then return end

        local desc = string.format(
            "💰 **Beli เดิม:** `%s`\n💰 **Beli ใหม่:** `%s`\n⚔️ **Bounty/Honor:** `%s`",
            lastBeli, newBeli, getBounty()
        )
        print("[Beli Changed]", lastBeli, "→", newBeli)
        sendEmbed("💰 Beli เปลี่ยนแปลง", desc, 0xF39C12)
        lastBeli = newBeli
    end)
    print("[Tracker] ✅ Hook Beli สำเร็จ | ค่าปัจจุบัน:", lastBeli)
else
    warn("[Tracker] ❌ ไม่พบ Beli label")
end

-- ============================================================
--  Hook Bounty/Honor จาก leaderstats
-- ============================================================
task.spawn(function()
    local ls = localPlayer:WaitForChild("leaderstats", 10)
    if not ls then return end

    local function hookStat(stat)
        if not stat:IsA("ValueBase") then return end
        stat.Changed:Connect(function(val)
            local desc = string.format(
                "**%s** เปลี่ยนเป็น `%s`\n💰 **Beli ตอนนี้:** `%s`",
                stat.Name, tostring(val), getBeliText()
            )
            print("[Leaderstats]", stat.Name, "=", val)
            sendEmbed("⚔️ " .. stat.Name .. " เปลี่ยนแปลง", desc, 0xE74C3C)
        end)
    end

    for _, stat in ipairs(ls:GetChildren()) do hookStat(stat) end
    ls.ChildAdded:Connect(hookStat)
    print("[Tracker] ✅ Hook Leaderstats สำเร็จ")
end)

-- ============================================================
--  รายงานสรุปทุก 5 นาที
-- ============================================================
task.spawn(function()
    while true do
        task.wait(300)
        snapshot("รายงานสรุป (ทุก 5 นาที)")
    end
end)

print("[Tracker] 🚀 ระบบทำงานแล้ว — ดัก Beli + Bounty/Honor")