local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer

-- 1. เตรียมระบบบิน
local function startFlying()
    local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 50, 0) -- บินขึ้นข้างบน
        bv.Parent = hrp
        
        -- ปิดการบินหลังจาก 2 วินาที (เพื่อให้ตัวละครลอยขึ้น)
        task.delay(2, function()
            bv:Destroy()
        end)
        print("[System] บินแล้ว!")
    end
end

-- 2. ตั้งค่า Webhook (ใช้ Proxy สำหรับ Roblox)
local WEBHOOK_URL = "https://hooks.hyra.io/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"

local function sendDiscord(message)
    local httprequest = (http_request or request or syn.request or http.request)
    if not httprequest then 
        warn("❌ Executor ไม่รองรับฟังก์ชันส่งข้อมูล") 
        return 
    end
    
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({content = message})
        })
    end)
    print("[System] ส่งข้อความไปแล้ว")
end

-- 3. ตรวจหา ATM
warn("✅ สคริปต์ทำงานแล้ว (กำลังสแกน ATM...)")

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
            warn("พบ ATM! เริ่มทำการบินและส่งข้อมูล")
            
            -- สั่งให้บิน
            startFlying()
            -- ส่งข้อมูล
            sendDiscord(":moneybag: พบ ATM ที่: " .. tostring(pos))
            
            task.wait(60) -- รอ 60 วินาทีค่อยสแกนใหม่ (ป้องกัน Spam)
        end
        
        task.wait(5) -- สแกนทุก 5 วินาที
    end
end)
