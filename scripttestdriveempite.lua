local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- แคช Remote สำหรับยืนยันการปล้น
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

local function getATMs()
    local atms = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            table.insert(atms, obj)
        end
    end
    return atms
end

local function bustATM(atmModel)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- 1. วาร์ปไปที่ตู้
    hrp.CFrame = atmModel:GetPivot() * CFrame.new(0, 0, 3)
    task.wait(0.3) -- รอให้ปุ่ม E โหลด

    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    
    if prompt then
        print("⏳ เริ่มกด E ค้างไว้ 5 วินาที...")
        
        -- บังคับให้ปุ่มใช้เวลา 5 วินาที (เผื่อค่าเดิมไม่ใช่ 5)
        prompt.HoldDuration = 5
        
        -- สั่งเริ่มกด (Fire)
        if fireproximityprompt then
            fireproximityprompt(prompt)
            
            -- **หัวใจสำคัญ**: ต้องรอให้ครบ 5 วินาทีตามที่ปุ่มต้องการ
            -- เราจะรอ 5.1 วินาทีเพื่อให้แน่ใจว่าเซิร์ฟเวอร์ยอมรับ
            task.wait(5.1) 
            
            -- 2. ส่ง Remote ยืนยันหลังกดเสร็จ
            if atmRemote then
                local success, err = pcall(function()
                    atmRemote:InvokeServer(atmModel)
                end)
                if success then
                    print("✅ ปล้นสำเร็จ!")
                else
                    warn("❌ เซิร์ฟเวอร์ปฏิเสธ: " .. tostring(err))
                end
            end
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมดกดค้าง 5 วินาที)")
    
    while true do
        local allATMs = getATMs()
        
        for _, currentATM in ipairs(allATMs) do
            if currentATM:IsDescendantOf(Workspace) then
                -- เช็คว่าตู้ยังไม่ถูกปล้น (ถ้ามีเงื่อนไขเช็ค เช่น ความโปร่งใสหรือชื่อเปลี่ยน)
                bustATM(currentATM)
                
                -- เวลารอก่อนไปตู้ถัดไป (ปรับได้ตามความเหมาะสม)
                task.wait(1) 
            end
        end
        task.wait(2) -- รอให้ตู้เกิดใหม่
    end
end)
