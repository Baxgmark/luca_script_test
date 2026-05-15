local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local localPlayer = Players.LocalPlayer

-- [!] Webhook ของคุณ
local WEBHOOK_URL = "https://discord.com/api/webhooks/1504925889631227947/OnGHrSl5-QnRaX5Q3jrT840J1EhDh2U219BRcBCiGP4SF8Kx5AQdsbz4U1-9eAXFmgVO" 

local httprequest = (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or request

-- ฟังก์ชันส่ง Webhook
local function send(title, desc)
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "💸 Auto ATM Robbery",
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

-- ฟังก์ชันสำหรับกด E (Interact)
local function interact(targetObj)
    local promptFound = false
    -- ค้นหา ProximityPrompt (ตัวกด E ของ Roblox) ในตู้ ATM
    for _, obj in ipairs(targetObj:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            promptFound = true
            -- ถ้าตัวรันสคริปต์รองรับคำสั่ง fireproximityprompt ให้ใช้เลย (แม่นยำสุด)
            if fireproximityprompt then
                fireproximityprompt(obj)
            else
                -- ถ้าไม่มี จำลองการกดปุ่ม E ค้างไว้ตามเวลาที่ตู้กำหนด
                local holdTime = obj.HoldDuration > 0 and obj.HoldDuration or 0.5
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                task.wait(holdTime + 0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            end
            break
        end
    end

    -- ถ้าเกมนี้ไม่ได้ใช้ ProximityPrompt ให้จำลองการกดปุ่ม E ธรรมดาหน้าตู้
    if not promptFound then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
        task.wait(0.5)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
    end
end

-- เริ่มการทำงานหลัก
local atmFolder = game.Workspace:FindFirstChild("Game")
    and game.Workspace.Game:FindFirstChild("Jobs")
    and game.Workspace.Game.Jobs:FindFirstChild("CriminalATMSpawners")

if atmFolder then
    local atms = atmFolder:GetChildren()
    local totalAtms = 0
    for _, a in ipairs(atms) do if a.Name == "CriminalATMSpawner" then totalAtms = totalAtms + 1 end end
    
    send("🚀 เริ่มการฟาร์ม ATM", string.format("เป้าหมายทั้งหมด: %d ตู้\nกำลังเริ่มวาร์ปและปล้น...", totalAtms))
    task.wait(2)
    
    local currentCount = 0
    
    for _, atm in ipairs(atms) do
        if atm.Name == "CriminalATMSpawner" and atm:IsA("BasePart") then
            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                currentCount = currentCount + 1
                
                -- 1. วาร์ปไปยืนข้างหน้าตู้ (ระยะ 3 Studs เอียงนิดหน่อยกันติดบัค) และ หันหน้าเข้าหาตู้ (CFrame.lookAt)
                local standPosition = atm.Position + Vector3.new(3, 0, 3) 
                rootPart.CFrame = CFrame.lookAt(standPosition, atm.Position)
                
                -- รอให้เกมโหลดและตัวละครนิ่ง 1 วินาที
                task.wait(1) 
                
                -- 2. สั่งกดปุ่ม E หรือใช้งาน ProximityPrompt
                interact(atm)
                
                -- 3. ส่งสถานะเข้า Webhook
                send(
                    string.format("💸 ปล้นตู้ที่ %d/%d", currentCount, totalAtms), 
                    string.format("วาร์ปและกด E เรียบร้อย\nพิกัดตู้: `%d, %d, %d`", atm.Position.X, atm.Position.Y, atm.Position.Z)
                )
                
                -- 4. หน่วงเวลา 10 วินาที เพื่อรอรับเงินและกัน Anti-Cheat แบนจากการวาร์ปรัวๆ 
                -- (สามารถปรับลด/เพิ่มตัวเลข 10 ได้ตามความเหมาะสมของแอนิเมชันเกม)
                task.wait(10) 
            end
        end
    end
    
    send("✅ ปล้นครบทุกตู้แล้ว!", "ฟาร์ม ATM รอบนี้เสร็จสิ้น กลับสู่สถานะพัก")
else
    send("❌ เกิดข้อผิดพลาด", "หาโฟลเดอร์ CriminalATMSpawners ไม่เจอ (ตู้ยังไม่สปอว์นหรือเปลี่ยนชื่อ)")
end
