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
--  Helper ส่ง Discord
-- ============================================================
local function send(title, desc, color)
    if not httprequest then return end
    if #desc > 3900 then desc = desc:sub(1, 3900) .. "\n...(ตัด)" end
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({
                username  = "🚗 Car Tracker",
                embeds = {{
                    title       = title,
                    description = desc,
                    color       = color or 0xF1C40F,
                    footer      = { text = "Player: " .. localPlayer.Name .. " | " .. os.date("%H:%M:%S") },
                    timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
                }}
            })
        })
    end)
end
 
-- ============================================================
--  Helper แปลง "200,000" → number
-- ============================================================
local function parseNum(s)
    return tonumber(tostring(s):gsub(",", ""):gsub("%s", "")) or 0
end
 
local function fmtMoney(n)
    local s = tostring(math.floor(math.abs(n))):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return "$" .. s
end
 
task.wait(3)
 
-- ============================================================
--  รอ GUI โหลด — path ที่รู้แน่นอนแล้ว
-- ============================================================
local gui     = localPlayer:WaitForChild("PlayerGui")
local hudGui  = gui:WaitForChild("HUD", 15)
 
if not hudGui then
    send("❌ Error", "ไม่พบ HUD GUI", 0xE74C3C)
    return
end
 
-- Path: HUD.HUD.MainHUD.SideHUD.BL-Row3.Money.Holder.Money
local moneyLabel = hudGui
    :WaitForChild("HUD")
    :WaitForChild("MainHUD")
    :WaitForChild("SideHUD")
    :WaitForChild("BL-Row3")
    :WaitForChild("Money")
    :WaitForChild("Holder")
    :WaitForChild("Money", 10)
 
if not moneyLabel then
    send("❌ Error", "ไม่พบ Money label\nPath: HUD.HUD.MainHUD.SideHUD.BL-Row3.Money.Holder.Money", 0xE74C3C)
    return
end
 
print("[Tracker] ✅ เจอ Money label:", moneyLabel:GetFullName(), "→", moneyLabel.Text)
 
-- ============================================================
--  Helper ข้อมูลผู้เล่น
-- ============================================================
local function playerInfo()
    return string.format(
        "👤 **%s** (@%s)  •  🆔 `%d`",
        localPlayer.DisplayName, localPlayer.Name, localPlayer.UserId
    )
end
 
-- ============================================================
--  Snapshot ครั้งแรก
-- ============================================================
local function snapshot(reason)
    send("📸 " .. reason,
        string.format("%s\n💰 **เงิน:** `$%s`", playerInfo(), moneyLabel.Text),
        0x2ECC71)
end
 
snapshot("Snapshot เริ่มต้น")
task.wait(1)
 
-- ============================================================
--  Hook Money Label
-- ============================================================
local lastText = moneyLabel.Text
local sessionEarned = 0
local sessionLost   = 0
 
moneyLabel:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = moneyLabel.Text
    if newText == lastText then return end
 
    local prev = parseNum(lastText)
    local curr = parseNum(newText)
    local diff = curr - prev
 
    -- สะสม session stats
    if diff > 0 then
        sessionEarned = sessionEarned + diff
    else
        sessionLost = sessionLost + math.abs(diff)
    end
 
    local sign  = diff >= 0 and "📈 +" or "📉 "
    local color = diff >= 0 and 0x2ECC71 or 0xE74C3C
 
    local desc = string.format(
        "%s\n\n**ก่อน:** `$%s`\n**หลัง:** `$%s`\n%s`%s`\n\n📊 **Session:** ได้ `%s` | เสีย `%s`",
        playerInfo(),
        lastText, newText,
        sign, fmtMoney(math.abs(diff)),
        fmtMoney(sessionEarned), fmtMoney(sessionLost)
    )
 
    send("💰 เงินเปลี่ยน", desc, color)
    lastText = newText
end)
 
-- ============================================================
--  รายงานสรุปทุก 5 นาที
-- ============================================================
task.spawn(function()
    while true do
        task.wait(300)
        send("🔄 รายงานทุก 5 นาที",
            string.format(
                "%s\n\n💰 **เงินปัจจุบัน:** `$%s`\n\n📊 **Session Stats**\n✅ ได้รับ: `%s`\n❌ เสียไป: `%s`\n💹 สุทธิ: `%s`",
                playerInfo(),
                moneyLabel.Text,
                fmtMoney(sessionEarned),
                fmtMoney(sessionLost),
                (sessionEarned - sessionLost >= 0 and "+" or "") .. fmtMoney(sessionEarned - sessionLost)
            ), 0x3498DB)
    end
end)
 
print("[Tracker] 🚗 Car Game Tracker พร้อมทำงาน!")
 