local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

-- [!] ใส่ Webhook URL ของคุณที่นี่
local WEBHOOK_URL    = "https://discord.com/api/webhooks/1504925889631227947/OnGHrSl5-QnRaX5Q3jrT840J1EhDh2U219BRcBCiGP4SF8Kx5AQdsbz4U1-9eAXFmgVO" 
local httprequest = (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or request

local function send(title, desc)
    -- ตัดข้อความหากยาวเกิน Limit ของ Discord Embed
    if #desc > 3900 then desc = desc:sub(1,3900) .. "\n...(ตัด)" end
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "🔍 Blox Scanner",
                embeds = {{title=title, description=desc, color=0xF1C40F,
                    footer={text="Player: "..localPlayer.Name}}}
            })
        })
    end)
end

task.wait(3)

-- Dump ดู Object หลักทั้งหมดที่อยู่ใน Workspace ขั้นแรก (Layer 1)
local workspaceNames = ""
for _, obj in ipairs(game.Workspace:GetChildren()) do
    workspaceNames = workspaceNames .. string.format("`%s` (%s)\n", obj.Name, obj.ClassName)
end
send("🌍 Workspace ชั้นนอกสุดทั้งหมด", workspaceNames)
task.wait(2)

-- ระบุชื่อโฟลเดอร์หรือโมเดลเป้าหมายใน Workspace ที่ต้องการเจาะลึก 
-- (เปลี่ยนชื่อตามโครงสร้างของเกม เช่น "Drops", "Items", "Map", "Spawns")
local targets = {"Items", "Drops", "Map", "Workspace", "Entities", "Pickups"}
for _, name in ipairs(targets) do
    local targetObj = game.Workspace:FindFirstChild(name)
    if targetObj then
        local out = ""
        local function dump(parent, depth)
            depth = depth or 0
            -- จำกัดความลึกเพื่อป้องกันการสแกนเยอะเกินไปจนเกมค้าง
            if depth > 15 then return end 
            
            for _, obj in ipairs(parent:GetChildren()) do
                -- เช็คว่าเป็นประเภท Part (BasePart ครอบคลุม Part, MeshPart ฯลฯ) หรือ Model
                if obj:IsA("BasePart") or obj:IsA("Model") then
                    out = out .. string.format("`%s` [%s] → `%s`\n",
                        obj.Name, obj.ClassName, obj:GetFullName())
                end
                -- สแกนเข้าไปใน Object ลูกต่อ
                dump(obj, depth + 1)
            end
        end
        
        dump(targetObj)
        
        if out ~= "" then
            send("📦 สแกน Object: " .. name, out)
            task.wait(2)
        end
    end
end
