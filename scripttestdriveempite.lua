local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local function interactWithATM(atmModel)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not atmModel then return end

    print("📍 วาร์ปไปที่: " .. atmModel.Name)

    -- 1. วาร์ป
    local atmPosition = atmModel:GetPivot().Position
    local offset = atmModel:GetPivot().LookVector * 4
    hrp.CFrame = CFrame.new(atmPosition + offset, atmPosition)
    task.wait(0.5)

    -- 2. กด E (ProximityPrompt)
    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        print("⏳ กำลังจำลองการกดค้าง 5 วินาที...")
        fireproximityprompt(prompt)
        
        -- *** หัวใจสำคัญ: รอให้ครบ 5 วินาที เพื่อจำลองการกดค้าง ***
        task.wait(5.5) 
    else
        print("⚠️ ไม่พบ ProximityPrompt")
    end

    -- 3. เรียกใช้ Remote
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
    
    if remote then
        print("📡 ส่ง Remote เพื่อรับเงิน...")
        local success, err = pcall(function()
            remote:InvokeServer(atmModel)
        end)
        
        if success then
            print("✅ ปล้นสำเร็จ!")
        else
            warn("❌ ส่ง Remote ล้มเหลว:", err)
        end
    end
end

-- ============================================================
-- MAIN LOOP: สแกนใหม่แบบ Real-time
-- ============================================================
task.spawn(function()
    print("🚀 ระบบ Auto ATM เริ่มทำงาน")
    
    while true do
        local targetATM = nil
        
        -- สแกนหาตู้
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "CriminalATM" and obj:IsA("Model") then
                targetATM = obj
                break
            end
        end

        if targetATM then
            interactWithATM(targetATM)
            -- หลังปล้นเสร็จ ให้รอเวลาที่ตู้จะรีเซ็ต
            task.wait(10) 
        else
            task.wait(3) -- ถ้าหาตู้ไม่เจอ วนหาใหม่
        end
    end
end)
