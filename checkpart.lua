local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

-- [!] Webhook ของคุณ (ตามที่ขอ ไม่ได้ตัดออก)
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
                username = "🔍 Blox Smart Scanner",
                embeds = {{
                    title = title, 
                    description = desc, 
                    color = 0x00FFFF,
                    footer = {text = "Player: " .. localPlayer.Name}
                }}
            })
        })
    end)
end

-- 🎯 คีย์เวิร์ดที่ต้องการหา
local keywords = {"atm", "bank", "cash", "money", "vault", "register"} 

-- 🚫 โฟลเดอร์ขยะที่จะไม่อ่าน
local blacklist = {
    ["lods"] = true, 
    ["buildings"] = true, 
    ["terrain"] = true,
    ["trees"] = true,
    ["roads"] = true
}

local scanYield = 0

local function smartScanTarget(targetFolder)
    local out = ""
    local count = 0
    
    local function scan(parent, depth)
        depth = depth or 0
        if depth > 20 then return end

        for _, obj in ipairs(parent:GetChildren()) do
            local lowerName = string.lower(obj.Name)
            
            if not blacklist[lowerName] then
                local isFound = false
                
                if obj:IsA("Model") or obj:IsA("BasePart") then
                    for _, kw in ipairs(keywords) do
                        if string.find(lowerName, kw) then
                            out = out .. string.format("**%s** `[%s]`\n↳ `%s`\n\n", obj.Name, obj.ClassName, obj:GetFullName())
                            count = count + 1
                            isFound = true
                            break 
                        end
                    end
                end
                
                -- 💡 ถ้ายังไม่เจอเป้าหมาย ให้มุดหาต่อ
                -- (ถ้าเจอแล้ว จะหยุดมุดเข้าไปในของชิ้นนั้น เพื่อป้องกันการสแปมชิ้นส่วนย่อยเช่นแบงก์ทีละใบ)
                if not isFound then
                    scan(obj, depth + 1)
                end
            end
            
            -- 🛠️ ป้องกันเกมค้าง: ทุกๆ การวนลูป 100 ครั้ง ให้พัก 1 เฟรม
            scanYield = scanYield + 1
            if scanYield % 100 == 0 then
                task.wait()
            end
        end
    end
    
    scan(targetFolder)
    
    if count > 0 then
        send("🎯 พบเป้าหมายใน: " .. targetFolder.Name, string.format("พบทั้งหมด %d รายการ:\n\n%s", count, out))
        task.wait(2)
    end
end

task.wait(3)
send("🚀 เริ่มการสแกนแบบ Smart Mode", "กำลังค้นหาคีย์เวิร์ด: `" .. table.concat(keywords, "`, `") .. "`\nระบบจะจัดกลุ่มข้อมูลและข้ามชิ้นส่วนย่อยเพื่อลดการสแปม")
task.wait(2)

local targets = {"Props", "Map", "Roleplay", "Game", "RegionsContent"}

for _, name in ipairs(targets) do
    local folder = game.Workspace:FindFirstChild(name)
    if folder then
        smartScanTarget(folder)
    end
end

send("✅ สแกนเสร็จสิ้น", "ไม่มีข้อมูลเพิ่มเติมแล้ว")
