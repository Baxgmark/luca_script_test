local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- ============================================================
--  ⚠️ คำเตือน: อย่าแชร์ Webhook URL ให้ใครเห็นเด็ดขาด
-- ============================================================
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"  -- ← ใส่ของคุณ
local COOLDOWN_SEC   = 50     -- หน่วงเวลาขั้นต่ำระหว่างการส่งแต่ละครั้ง (วินาที)
local HOURLY_REPORT  = true   -- เปิด/ปิด รายงานอัตโนมัติทุก 1 ชั่วโมง
local TRACK_POSITION = true   -- เปิด/ปิด ส่งพิกัดตัวละคร
local MAX_DESC_LEN   = 3900   -- ความยาวสูงสุดของ Embed Description (Discord จำกัด 4096)

-- ============================================================
--  ตรวจจับ HTTP executor
-- ============================================================
local httprequest =
    (syn        and syn.request)      or
    (http       and http.request)     or
    http_request                      or
    (fluxus     and fluxus.request)   or
    (krnl       and krnl.request)     or
    request

-- ============================================================
--  ตัวแปรควบคุม Queue
-- ============================================================
local isSending   = false
local pendingUpdate = false
local lastSentTime  = 0

-- ============================================================
--  Helper: แปลง tick เป็น timestamp อ่านง่าย
-- ============================================================
local function timestamp()
    return os.date("%Y-%m-%d %H:%M:%S")
end

-- ============================================================
--  ดึงข้อมูลผู้เล่นแบบละเอียด
-- ============================================================
local function getPlayerBlock(player)
    local lines = {}

    -- ชื่อ / DisplayName / ID / Account Age
    table.insert(lines, string.format(
        "**👤 %s** (@%s)  •  🆔 `%d`  •  📅 `อายุบัญชี %d วัน`",
        player.Name, player.DisplayName, player.UserId, player.AccountAge
    ))

    -- Team
    if player.Team then
        table.insert(lines, string.format("🏳️ `ทีม: %s`", player.Team.Name))
    end

    -- Membership (Premium)
    local hasPremium = player.MembershipType == Enum.MembershipType.Premium
    table.insert(lines, hasPremium and "💎 `Premium: ✅`" or "💎 `Premium: ❌`")

    -- Leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local parts = {}
        for _, v in ipairs(leaderstats:GetChildren()) do
            if v:IsA("ValueBase") then
                table.insert(parts, v.Name .. ": **" .. tostring(v.Value) .. "**")
            end
        end
        if #parts > 0 then
            table.insert(lines, "📊 " .. table.concat(parts, "  |  "))
        else
            table.insert(lines, "📊 `ไม่มี Leaderstats`")
        end
    else
        table.insert(lines, "📊 `ไม่มี Leaderstats`")
    end

    -- ตัวละคร: HP + ตำแหน่ง
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum then
            local hp    = math.floor(hum.Health)
            local maxHp = math.floor(hum.MaxHealth)
            local bar   = (maxHp > 0) and math.floor((hp / maxHp) * 10) or 0
            local fill  = string.rep("█", bar) .. string.rep("░", 10 - bar)
            table.insert(lines, string.format("❤️ `%d / %d`  [%s]", hp, maxHp, fill))
        end
        if TRACK_POSITION and hrp then
            local p = hrp.Position
            table.insert(lines, string.format("📍 `X:%.1f  Y:%.1f  Z:%.1f`", p.X, p.Y, p.Z))
        end
    else
        table.insert(lines, "👻 `ยังไม่ได้เกิด`")
    end

    -- Ping (ค่าประมาณ)
    local ping = player:GetNetworkPing and math.floor(player:GetNetworkPing() * 1000) or nil
    if ping then
        table.insert(lines, string.format("🌐 `Ping: %d ms`", ping))
    end

    return table.concat(lines, "\n") .. "\n" .. string.rep("─", 30) .. "\n"
end

-- ============================================================
--  สร้าง Payload แล้วส่ง Webhook
-- ============================================================
local function sendToDiscord(eventLabel)
    local playersList = Players:GetPlayers()
    if #playersList == 0 then return end

    local desc = ""
    for _, player in ipairs(playersList) do
        local block = getPlayerBlock(player)
        if #desc + #block >= MAX_DESC_LEN then
            desc = desc .. "*...และผู้เล่นอื่น ๆ ที่ไม่แสดง (เกิน limit)*\n"
            break
        end
        desc = desc .. block
    end

    local serverInfo = string.format(
        "🖥️ **Server** `%s`  |  👥 **ผู้เล่น %d/%d**  |  🕐 `%s`",
        game.JobId ~= "" and game.JobId:sub(1, 8) .. "..." or "Studio",
        #playersList,
        Players.MaxPlayers,
        timestamp()
    )

    local payload = HttpService:JSONEncode({
        username   = "🔴 Roblox Live Tracker",
        avatar_url = "https://www.roblox.com/asset/?id=7072706464",
        embeds = {{
            title       = "🔄 " .. (eventLabel or "อัปเดตสถานะผู้เล่น"),
            description = desc,
            color       = 0x00CC66,
            footer      = { text = serverInfo },
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })

    if not httprequest then
        warn("[Tracker] Executor ไม่รองรับ HTTP Request")
        return
    end

    local ok, response = pcall(function()
        return httprequest({
            Url     = WEBHOOK_URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = payload
        })
    end)

    if ok then
        if response.StatusCode == 204 or response.StatusCode == 200 then
            print("[Tracker] ✅ ส่งสำเร็จ | Event:", eventLabel or "update")
        elseif response.StatusCode == 429 then
            warn("[Tracker] ⚠️ Rate Limited! เพิ่ม COOLDOWN_SEC แนะนำ 60+")
        else
            warn("[Tracker] ❌ HTTP", response.StatusCode, response.Body or "")
        end
    else
        warn("[Tracker] ❌ pcall error:", response)
    end
end

-- ============================================================
--  Queue ป้องกันสแปม (cooldown + pending flag)
-- ============================================================
local function triggerUpdate(label)
    if isSending then
        pendingUpdate = true
        return
    end

    local now = tick()
    local wait_time = COOLDOWN_SEC - (now - lastSentTime)
    if wait_time < 0 then wait_time = 0 end

    isSending = true

    task.spawn(function()
        if wait_time > 0 then
            task.wait(wait_time)
        end

        lastSentTime = tick()
        sendToDiscord(label)
        isSending = false

        -- มีการรออัปเดตค้างอยู่ → ส่งต่อ
        if pendingUpdate then
            pendingUpdate = false
            triggerUpdate("pending update")
        end
    end)
end

-- ============================================================
--  ตั้งค่า Hook ให้ผู้เล่นแต่ละคน
-- ============================================================
local function setupPlayerTracker(player)
    -- Hook Leaderstats ที่มีอยู่แล้ว
    local function hookLeaderstats(leaderstats)
        local function hookStat(stat)
            if stat:IsA("ValueBase") then
                stat.Changed:Connect(function()
                    triggerUpdate(player.Name .. " stat changed")
                end)
            end
        end
        for _, stat in ipairs(leaderstats:GetChildren()) do
            hookStat(stat)
        end
        leaderstats.ChildAdded:Connect(hookStat)
    end

    if player:FindFirstChild("leaderstats") then
        hookLeaderstats(player.leaderstats)
    end

    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            hookLeaderstats(child)
        end
    end)

    -- Hook ตัวละคร Respawn (HP / ตำแหน่งเปลี่ยน)
    player.CharacterAdded:Connect(function(char)
        triggerUpdate(player.Name .. " respawned")

        local hum = char:WaitForChild("Humanoid", 5)
        if hum then
            hum.Died:Connect(function()
                triggerUpdate(player.Name .. " died")
            end)
        end
    end)
end

-- ============================================================
--  Hook ผู้เล่นที่อยู่ในห้องแล้ว
-- ============================================================
for _, p in ipairs(Players:GetPlayers()) do
    setupPlayerTracker(p)
end

-- ============================================================
--  Hook ผู้เล่นใหม่ / ผู้เล่นออก
-- ============================================================
Players.PlayerAdded:Connect(function(player)
    setupPlayerTracker(player)
    triggerUpdate(player.Name .. " เข้าห้อง")
end)

Players.PlayerRemoving:Connect(function(player)
    triggerUpdate(player.Name .. " ออกจากห้อง")
end)

-- ============================================================
--  รายงานอัตโนมัติทุก 1 ชั่วโมง (ถ้าเปิดไว้)
-- ============================================================
if HOURLY_REPORT then
    task.spawn(function()
        while true do
            task.wait(3600)
            print("[Tracker] ⏰ รายงานรายชั่วโมง")
            -- บายพาส queue เพราะนี่เป็น scheduled send ไม่ใช่ event
            lastSentTime = 0
            triggerUpdate("รายงานรายชั่วโมง")
        end
    end)
end

-- ============================================================
--  ส่งข้อมูลครั้งแรก
-- ============================================================
triggerUpdate("เริ่มต้น Tracker")
print("[Tracker] 🚀 เริ่มทำงานแล้ว | Cooldown:", COOLDOWN_SEC, "วินาที")