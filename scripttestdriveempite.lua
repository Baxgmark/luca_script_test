local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- เปลี่ยนลิงก์ Discord ของคุณตรงนี้ ให้เติม .hyra.io เข้าไป
local WEBHOOK_URL = "https://hooks.hyra.io/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"

local httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or (krnl and krnl.request) or request

-- ฟังก์ชันส่ง Discord แบบทั่วไป
local function sendDiscord(message)
    if not httprequest then return end
    httprequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode({content = message})
    })
end

-- ฟังก์ชันส่ง Embed (สำหรับสแกน)
local function sendEmbed(title, description, color)
    if not httprequest then return end
    local payload = HttpService:JSONEncode({
        username = "🔍 Roblox Scanner",
        embeds = {{
            title = title,
            description = #description > 3900 and description:sub(1,3900) or description,
            color = color or 0x3498DB,
            footer = { text = "Game: " .. game.Name },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    })
    httprequest({
        Url = WEBHOOK_URL,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = payload
    })
end

-- 1. ส่วนงาน: ตรวจหา ATM (รันแยกเป็น Loop)
task.spawn(function()
    while true do
        local atm = nil
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "CriminalATM" and obj:IsA("Model") then
                atm = obj break
            end
        end

        if atm then
            local pos = atm:GetPivot().Position
            sendDiscord(string.format(":round_pushpin: พบ ATM ที่: %.0f, %.0f, %.0f", pos.X, pos.Y, pos.Z))
        end
        task.wait(30)
    end
end)

-- 2. ส่วนงาน: สแกนข้อมูล (รันครั้งเดียว)
task.spawn(function()
    task.wait(5) -- รอโหลด
    local data = ""
    
    -- สแกน Leaderstats
    local stats = localPlayer:FindFirstChild("leaderstats")
    if stats then
        for _, v in pairs(stats:GetChildren()) do
            data = data .. "`"..v.Name.."`: "..tostring(v.Value).."\n"
        end
    end
    
    sendEmbed("📊 สแกนข้อมูลผู้เล่น", data ~= "" and data or "ไม่พบข้อมูล", 0x2ECC71)
end)
