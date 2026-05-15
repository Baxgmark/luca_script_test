local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- [!] ใส่ Webhook URL ของคุณที่นี่
local WEBHOOK_URL = "https://discord.com/api/webhooks/1504925889631227947/OnGHrSl5-QnRaX5Q3jrT840J1EhDh2U219BRcBCiGP4SF8Kx5AQdsbz4U1-9eAXFmgVO" 

local httprequest = (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or request

local function send(title, desc)
    if desc == "" then return end
    if #desc > 3900 then desc = desc:sub(1,3900) .. "\n\n...(ข้อมูลยาวเกินไป ถูกตัดออกบางส่วน)" end
    
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "🔍 Blox Deep Scanner",
                embeds = {{
                    title = title, 
                    description = desc, 
                    color = 0x00FF00,
                    footer = {text = "Player: " .. localPlayer.Name}
                }}
            })
        })
    end)
end

local keywords = {"atm", "bank", "cash", "money"} 

local function deepScanTarget(targetFolder)
    local out = ""
    local count = 0
    
    -- ดึงข้อมูลทั้งหมดมาเก็บไว้ในตารางก่อน
    local descendants = targetFolder:GetDescendants()
    
    for i, obj in ipairs(descendants) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            local objName = string.lower(obj.Name)
            
            for _, kw in ipairs(keywords) do
                if string.find(objName, kw) then
                    out = out .. string.format("**%s** `[%s]`\n↳ `%s`\n\n", obj.Name, obj.ClassName, obj:GetFullName())
                    count = count + 1
                    break 
                end
            end
        end
        
        -- 🛠️ ป้องกันเกมค้าง: ทุกๆ การสแกน 500 ชิ้น จะสั่งให้สคริปต์พัก 1 เฟรม
        if i % 500 == 0 then
            task.wait() 
        end
    end
    
    if count > 0 then
        send("🎯 พบเป้าหมายใน: " .. targetFolder.Name, string.format("พบทั้งหมด %d รายการ:\n\n%s", count, out))
        task.wait(2)
    end
end

task.wait(3)
send("🚀 เริ่มการสแกนแบบล้ำลึก (Safe Mode)", "กำลังค้นหาคีย์เวิร์ด: `" .. table.concat(keywords, "`, `") .. "`\nสแกนแบบแบ่งโหลด ป้องกันเกมค้าง")
task.wait(2)

local targets = {"Props", "Map", "Roleplay", "Game", "RegionsContent"}

for _, name in ipairs(targets) do
    local folder = game.Workspace:FindFirstChild(name)
    if folder then
        deepScanTarget(folder)
    end
end

send("✅ สแกนเสร็จสิ้น", "ระบบได้ทำการค้นหาในโฟลเดอร์เป้าหมายเรียบร้อยแล้ว")
