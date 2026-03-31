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
--  ส่งข้อความไป Discord
-- ============================================================
local function sendEmbed(title, description, color)
    if not httprequest then
        warn("[Scan] Executor ไม่รองรับ HTTP")
        return
    end

    -- ตัดไม่ให้เกิน Discord limit
    if #description > 3900 then
        description = description:sub(1, 3900) .. "\n...(ตัดเพราะเกิน limit)"
    end

    local payload = HttpService:JSONEncode({
        username = "🔍 Roblox Scanner",
        embeds = {{
            title       = title,
            description = description,
            color       = color or 0x3498DB,
            footer      = { text = "Game: " .. game.Name .. " | Player: " .. localPlayer.Name },
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })

    local ok, res = pcall(function()
        return httprequest({
            Url     = WEBHOOK_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = payload
        })
    end)

    if ok then
        print("[Scan] ✅ ส่งสำเร็จ:", title, "| Status:", res.StatusCode)
    else
        warn("[Scan] ❌ Error:", res)
    end
end

-- ============================================================
--  รอ GUI โหลด
-- ============================================================
task.wait(3)
print("[Scan] เริ่ม scan...")

-- ============================================================
--  1. LEADERSTATS
-- ============================================================
local section1 = ""
local leaderstats = localPlayer:FindFirstChild("leaderstats")
if leaderstats then
    for _, v in ipairs(leaderstats:GetChildren()) do
        section1 = section1 .. string.format("`%-20s` = `%s`\n", v.Name, tostring(v.Value))
    end
else
    section1 = "❌ ไม่มี leaderstats\n"
end

-- ============================================================
--  2. PLAYER VALUES (IntValue, NumberValue ฯลฯ)
-- ============================================================
local section2 = ""
local function scanValues(parent, depth)
    depth = depth or 0
    if depth > 8 then return end
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("ValueBase") then
            section2 = section2 .. string.format(
                "`%-20s` = `%-15s`  →  `%s`\n",
                obj.Name, tostring(obj.Value), obj:GetFullName()
            )
        end
        scanValues(obj, depth + 1)
    end
end
scanValues(localPlayer)
if section2 == "" then section2 = "❌ ไม่พบ ValueBase\n" end

-- ============================================================
--  3. PLAYER GUI — TextLabel/TextButton ที่มีตัวเลข/$
-- ============================================================
local section3 = ""
local function scanGui(parent, depth)
    depth = depth or 0
    if depth > 15 then return end
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = tostring(obj.Text)
            if  txt:match("%d") or txt:match("%$") or
                txt:lower():match("cash") or txt:lower():match("coin") or
                txt:lower():match("step") or txt:lower():match("speed") or
                txt:match("เงิน") or txt:match("ความเร็ว") or txt:match("สกุล")
            then
                section3 = section3 .. string.format(
                    "**[%s]** `%s`\n→ `%s`\n",
                    obj.ClassName, txt, obj:GetFullName()
                )
            end
        end
        scanGui(obj, depth + 1)
    end
end
scanGui(localPlayer:WaitForChild("PlayerGui"))
if section3 == "" then section3 = "❌ ไม่พบ UI ที่เกี่ยวข้อง\n" end

-- ============================================================
--  4. REMOTE EVENTS / FUNCTIONS
-- ============================================================
local section4 = ""
local function scanRemotes(parent, depth)
    depth = depth or 0
    if depth > 6 then return end
    for _, obj in ipairs(parent:GetChildren()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            section4 = section4 .. string.format(
                "📡 **[%s]** `%s`\n",
                obj.ClassName, obj:GetFullName()
            )
        end
        scanRemotes(obj, depth + 1)
    end
end
scanRemotes(game:GetService("ReplicatedStorage"))
if section4 == "" then section4 = "❌ ไม่พบ Remote\n" end

-- ============================================================
--  ส่งแยก 4 Embed (ป้องกัน limit)
-- ============================================================
task.wait(1)
sendEmbed("📊 [1/4] Leaderstats", section1, 0x2ECC71)
task.wait(2)
sendEmbed("💾 [2/4] Player Values", section2, 0xF39C12)
task.wait(2)
sendEmbed("🖥️ [3/4] PlayerGui TextLabels", section3, 0x9B59B6)
task.wait(2)
sendEmbed("📡 [4/4] RemoteEvents / Functions", section4, 0xE74C3C)

print("[Scan] ✅ ส่งครบทั้งหมดแล้ว!")