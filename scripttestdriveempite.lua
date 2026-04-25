local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันจัดการ Teleport และส่งคำสั่ง
local function interactWithATM(atmModel)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp and atmModel then
        print("📍 พบ ATM! กำลังวาร์ปไปด้านหน้า...")
        
        -- แก้ไข Teleport: ไปข้างหน้าตู้ 3 หน่วย และให้หันหน้าเข้าหาตู้
        local atmPosition = atmModel:GetPivot().Position
        local offset = atmModel:GetPivot().LookVector * 3 -- ปรับระยะห่างตรงนี้
        hrp.CFrame = CFrame.new(atmPosition + offset, atmPosition)

        -- ส่วนกด E (ส่งค่าตามที่คุณระบุ)
        local targetATM = workspace.Game.Jobs.CriminalATMSpawners.CriminalATMSpawner.CriminalATM
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
        
        if remote then
            -- รอสักนิดให้วาร์ปถึงที่ก่อน
            task.wait(0.5)
            
            pcall(function()
                -- ลองส่งแบบ InvokeServer
                remote:InvokeServer(targetATM)
                -- หรือถ้ามันใช้ Event ให้ลอง FireServer
                remote:FireServer(targetATM)
                print("✅ กด E สำเร็จ!")
            end)
        else
            warn("❌ ไม่พบ Remote 'AttemptATMBustComplete'")
        end
    end
end

-- ============================================================
-- MAIN LOOP: สแกนทุก 30 วินาที
-- ============================================================
task.spawn(function()
    print("🚀 เริ่มระบบ Auto ATM แล้ว...")
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
            task.wait(30) -- รอ 30 วินาทีตามที่ขอ
        else
            task.wait(3) -- ถ้าไม่เจอให้วนหาใหม่
        end
    end
end)
