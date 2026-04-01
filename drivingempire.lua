local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

-- ============================================================
--  ⚠️ ใส่ IP/URL ของ Node.js Server ตรงนี้
-- ============================================================
local SERVER_URL = "https://fram.mrluca.shop/api/tracker"  -- ← เปลี่ยนเป็น IP ของคุณ

local httprequest =
    (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or
    (krnl and krnl.request) or request

-- ============================================================
--  Helper ส่งข้อมูลไป Node.js (เฉพาะ username + money)
-- ============================================================
local function sendToServer(moneyText)
    if not httprequest then return end
    pcall(function()
        httprequest({
            Url    = SERVER_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body   = HttpService:JSONEncode({
                username    = localPlayer.Name,
                displayName = localPlayer.DisplayName,
                money       = moneyText,
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

task.wait(3)

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
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

print("[Tracker] ✅ เจอ Money label:", moneyLabel:GetFullName(), "→", moneyLabel.Text)

-- ============================================================
--  Snapshot ครั้งแรก
-- ============================================================
sendToServer(moneyLabel.Text)
task.wait(1)

-- ============================================================
--  Hook Money Label — ส่งทุกครั้งที่เงินเปลี่ยน
-- ============================================================
local lastText = moneyLabel.Text

moneyLabel:GetPropertyChangedSignal("Text"):Connect(function()
    local newText = moneyLabel.Text
    if newText == lastText then return end

    sendToServer(newText)
    lastText = newText
end)

-- ============================================================
--  รายงานทุก 5 นาที
-- ============================================================
task.spawn(function()
    while true do
        task.wait(300)
        sendToServer(moneyLabel.Text)
    end
end)

print("[Tracker] 🚗 Car Game Tracker พร้อมทำงาน!")