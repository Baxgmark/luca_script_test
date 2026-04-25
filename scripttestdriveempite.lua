local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- กำหนด Target ตามที่คุณต้องการเป๊ะๆ
local TARGET_ATM = workspace.Game.Jobs.CriminalATMSpawners.CriminalATMSpawner.CriminalATM

-- ฟังก์ชันปล้น
local function bustATM(atmModel)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end

    print("📍 กำลังวาร์ปไปที่ ATM...")
    -- Teleport ไปหน้าตู้
    hrp.CFrame = atmModel:GetPivot() * CFrame.new(0, 0, 4)
    task.wait(0.5)

    -- 1. กด E ค้าง (ProximityPrompt)
    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        print("⏳ เริ่มกด E ค้าง 5 วินาที...")
        fireproximityprompt(prompt)
        task.wait(5.5) -- รอให้ครบเวลา 5 วินาทีตามที่เกมกำหนด
    else
        print("⚠️ ไม่พบ ProximityPrompt (ข้ามไปขั้นตอนถัดไป)")
    end

    -- 2. ส่ง Remote ตามที่คุณระบุ
    print("📡 กำลังส่งข้อมูลไปยัง Server...")
    local args = { [1] = TARGET_ATM }
    
    local success, err = pcall(function()
        ReplicatedStorage.Remotes.AttemptATMBustComplete:InvokeServer(unpack(args))
    end)

    if success then
        -- ย้ายมาไว้ตรงนี้ เพื่อให้มั่นใจว่าทำสำเร็จจริงๆ
        print("✅ ปล้นสำเร็จ! (ข้อมูลถูกส่งครบถ้วน)")
    else
        warn("❌ ส่ง Remote ไม่ผ่าน:", err)
    end
end

-- ============================================================
-- MAIN LOOP: ทำงานทุก 10 วินาที
-- ============================================================
task.spawn(function()
    print("🚀 ระบบ Auto ATM เริ่มทำงานแล้ว!")
    
    while true do
        -- สแกนหาตู้ใน Workspace
        local foundATM = nil
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "CriminalATM" and obj:IsA("Model") then
                foundATM = obj
                break
            end
        end

        if foundATM then
            bustATM(foundATM)
            task.wait(10) -- พัก 10 วินาทีตามที่ต้องการ
        else
            task.wait(3) -- ถ้าหาไม่เจอ ให้หาใหม่ในอีก 3 วินาที
        end
    end
end)
