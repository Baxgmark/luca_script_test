local Players = game:GetService("Players")

local HttpService = game:GetService("HttpService")



-- ⚠️ คำเตือน: อย่าเผยแพร่ลิงก์ Webhook ของคุณให้ใครเห็น นำมาใส่ตรงนี้

local WEBHOOK_URL = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"

local UPDATE_COOLDOWN = 50 -- หน่วงเวลาส่งทุกๆ 10 วินาที เพื่อป้องกัน Discord แบน Webhook (Rate Limit)



local isSending = false

local pendingUpdate = false



-- ฟังก์ชันดึง Request แบบครอบคลุมหลาย Executor

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request



-- ฟังก์ชันสำหรับดึงข้อมูล "ทั้งหมด" ของผู้เล่น

local function getPlayerDataString(player)

    local dataString = "**👤 " .. player.Name .. " (@" .. player.DisplayName .. ")**\n"

    dataString = dataString .. "🆔 `ID: " .. player.UserId .. "` | ⏳ `Account Age: " .. player.AccountAge .. " days`\n"

    

    -- ดึงข้อมูล Team (ถ้ามี)

    if player.Team then

        dataString = dataString .. "🏳️ `Team: " .. player.Team.Name .. "`\n"

    end



    -- ดึงข้อมูล Leaderstats "ทุกค่า" ไม่ใช่แค่เงิน

    local stats = {}

    local leaderstats = player:FindFirstChild("leaderstats")

    if leaderstats then

        for _, stat in ipairs(leaderstats:GetChildren()) do

            if stat:IsA("ValueBase") then

                table.insert(stats, stat.Name .. ": " .. tostring(stat.Value))

            end

        end

    end

    

    if #stats > 0 then

        dataString = dataString .. "📊 **Stats:** `" .. table.concat(stats, " | ") .. "`\n"

    else

        dataString = dataString .. "📊 **Stats:** `ไม่มีข้อมูล (No Leaderstats)`\n"

    end



    -- ดึงข้อมูลตัวละคร (เลือด, ตำแหน่ง)

    local char = player.Character

    if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then

        local hp = math.floor(char.Humanoid.Health)

        local maxHp = math.floor(char.Humanoid.MaxHealth)

        local pos = char.HumanoidRootPart.Position

        local posString = string.format("%.1f, %.1f, %.1f", pos.X, pos.Y, pos.Z)

        

        dataString = dataString .. "❤️ `Health: " .. hp .. "/" .. maxHp .. "` | 📍 `Pos: " .. posString .. "`\n"

    else

        dataString = dataString .. "👻 `สถานะ: ยังไม่ได้เกิด (Not Spawned)`\n"

    end



    return dataString .. "━━━━━━━━━━━━━━━━━━━━━━\n"

end



-- ฟังก์ชันรวบรวมและส่งไป Discord

local function sendDataToDiscord()

    local messageDescription = ""



    -- รวบรวมข้อมูลผู้เล่นทุกคน

    local playersList = Players:GetPlayers()

    if #playersList == 0 then return end



    for _, player in ipairs(playersList) do

        -- ตัดข้อความไม่ให้เกิน Limit ของ Discord Embed Description (4096 ตัวอักษร)

        local playerData = getPlayerDataString(player)

        if #messageDescription + #playerData < 4000 then

            messageDescription = messageDescription .. playerData

        end

    end



    -- จัดรูปแบบให้อ่านง่ายขึ้นด้วย Embed

    local payload = HttpService:JSONEncode({

        username = "Roblox Live Tracker",

        embeds = {{

            title = "🔄 อัปเดตสถานะผู้เล่นแบบ Real-time",

            description = messageDescription,

            color = tonumber(0x00FF00), -- สีเขียว

            footer = { text = "อัปเดตล่าสุด: " .. os.date("%X") }

        }}

    })



    if httprequest then

        local response = httprequest({

            Url = WEBHOOK_URL,

            Method = "POST",

            Headers = { ["Content-Type"] = "application/json" },

            Body = payload

        })

        if response.StatusCode == 204 or response.StatusCode == 200 then

            print("[Tracker] ส่งข้อมูลอัปเดตไปยัง Discord สำเร็จ!")

        else

            print("[Tracker] Error Code: " .. tostring(response.StatusCode))

        end

    else

        print("[Tracker] Executor ของคุณไม่รองรับ HTTP Request")

    end

end



-- ฟังก์ชันคิวการส่ง (ป้องกันสแปม Webhook)

local function triggerUpdate()

    if isSending then

        pendingUpdate = true -- ถ้ากำลังส่งอยู่ ให้จำไว้ว่ามีการอัปเดตใหม่รออยู่

        return

    end



    isSending = true

    task.spawn(function()

        sendDataToDiscord()

        task.wait(UPDATE_COOLDOWN) -- รอ 10 วินาทีก่อนส่งรอบถัดไป

        isSending = false



        -- ถ้ามีการเปลี่ยนแปลงค่าระหว่างที่กำลังรอคูลดาวน์ ให้ส่งใหม่อีกรอบ

        if pendingUpdate then

            pendingUpdate = false

            triggerUpdate()

        end

    end)

end



-- ฟังก์ชันฝังตัวดักจับ (Hook) การเปลี่ยนแปลงค่า

local function setupPlayerTracker(player)

    local function onLeaderstatsAdded(leaderstats)

        -- ลูปเพื่อดักจับทุกค่าที่มีใน Leaderstats

        for _, stat in ipairs(leaderstats:GetChildren()) do

            if stat:IsA("ValueBase") then

                stat.Changed:Connect(function()

                    triggerUpdate() -- สั่งให้ส่งข้อมูลเมื่อค่าเปลี่ยน

                end)

            end

        end

        

        -- เผื่อเกมสร้าง Stat ขึ้นมาใหม่ทีหลัง

        leaderstats.ChildAdded:Connect(function(stat)

            if stat:IsA("ValueBase") then

                stat.Changed:Connect(function()

                    triggerUpdate()

                end)

            end

        end)

    end



    if player:FindFirstChild("leaderstats") then

        onLeaderstatsAdded(player.leaderstats)

    end

    

    player.ChildAdded:Connect(function(child)

        if child.Name == "leaderstats" then

            onLeaderstatsAdded(child)

        end

    end)

end



-- 1. ลูปฝังตัวดักจับกับผู้เล่นที่อยู่ในห้องอยู่แล้ว

for _, p in ipairs(Players:GetPlayers()) do

    setupPlayerTracker(p)

end



-- 2. ฝังตัวดักจับกับผู้เล่นใหม่ที่เพิ่งเข้าห้องมา

Players.PlayerAdded:Connect(function(player)

    setupPlayerTracker(player)

    triggerUpdate() -- อัปเดตทันทีเมื่อมีคนเข้าห้อง

end)



Players.PlayerRemoving:Connect(function()

    triggerUpdate() -- อัปเดตทันทีเมื่อมีคนออกห้อง

end)



-- ส่งข้อมูลครั้งแรกเมื่อรันสคริปต์

triggerUpdate()