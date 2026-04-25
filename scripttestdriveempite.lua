local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ฟังก์ชันโต้ตอบกับตู้ที่สแกนเจอ
local function bustATM(atmModel)
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end

    print("📍 วาร์ปไปที่: " .. atmModel:GetFullName())
    
    -- วาร์ป
    hrp.CFrame = atmModel:GetPivot() * CFrame.new(0, 0, 4)
    task.wait(0.5)

    -- 1. กด E (ProximityPrompt)
    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        print("⏳ กำลังกด E ค้าง...")
        fireproximityprompt(prompt)
        task.wait(5.5) 
    end

    -- 2. ส่ง Remote โดยใช้ "atmModel" ที่เราสแกนเจอ (ไม่ต้องใช้ Path เดิมแล้ว)
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
    
    if remote then
        print("📡 ส่ง Remote ไปที่ Server...")
        
        -- ใช้ pcall เพื่อดักจับ Error ถ้า Server ปฏิเสธเรา
        local success, err = pcall(function()
            remote:InvokeServer(atmModel) -- ส่งตู้ที่สแกนเจอเข้าไปตรงๆ
        end)

        if success then
            print("✅ ส่งคำสั่งสำเร็จ!")
        else
            warn("❌ Server ปฏิเสธการปล้น: " .. tostring(err))
        end
    else
        warn("❌ ไม่พบ Remote!")
    end
end

-- ============================================================
-- MAIN LOOP: สแกนหา ATM ใหม่ทุกรอบ
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (สแกนตู้แบบ Dynamic)")
    
    while true do
        local foundATM = nil
        
        -- สแกนหา ATM ในทั้ง Workspace (วิธีนี้แม่นยำกว่าการระบุ Path)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "CriminalATM" and obj:IsA("Model") then
                foundATM = obj
                break
            end
        end

        if foundATM then
            -- ก่อนปล้น ให้เช็คว่ามันยังอยู่จริง
            if foundATM:IsDescendantOf(Workspace) then
                bustATM(foundATM)
                task.wait(10)
            end
        else
            task.wait(3)
        end
    end
end)
