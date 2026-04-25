local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันจัดการ Teleport และกด E
local function interactWithATM(atmModel)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp and atmModel then
        -- 1. Teleport ไปหน้าตู้
        local atmPosition = atmModel:GetPivot().Position
        local offset = atmModel:GetPivot().LookVector * 3
        hrp.CFrame = CFrame.new(atmPosition + offset, atmPosition)
        
        task.wait(0.5) -- รอให้วาร์ปนิ่งก่อน

        -- 2. ส่วนการกด E
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
        
        if remote then
            print("🚀 กำลังพยายามกด E (ส่ง Remote)...")
            
            pcall(function()
                -- ลองใช้ FireServer ก่อน (สำหรับ RemoteEvent)
                -- ส่งค่า atmModel ไปตรงๆ ตามที่เกมต้องการ
                remote:FireServer(atmModel)
                print("✅ ส่ง FireServer แล้ว")
            end)
            
            -- ถ้า FireServer ไม่ทำงาน ให้ลอง InvokeServer (เผื่อเป็น RemoteFunction)
            pcall(function()
                remote:InvokeServer(atmModel)
                print("✅ ส่ง InvokeServer แล้ว")
            end)
        else
            warn("❌ ไม่พบ Remote 'AttemptATMBustComplete' ใน Remotes")
        end
    end
end

-- ============================================================
-- MAIN LOOP: สแกนและจัดการ ATM ทุก 30 วินาที
-- ============================================================
task.spawn(function()
    while true do
        local foundATM = nil
        
        -- วนหา ATM
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name == "CriminalATM" and obj:IsA("Model") then
                foundATM = obj
                break
            end
        end

        if foundATM then
            interactWithATM(foundATM)
            task.wait(30) -- รอ 30 วินาที
        else
            task.wait(3) -- สแกนหาใหม่
        end
    end
end)
