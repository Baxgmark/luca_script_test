local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันจัดการ Teleport และส่งคำสั่ง
local function interactWithATM(atmModel)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp and atmModel then
        print("📍 พบ ATM! กำลัง Teleport ไปที่: " .. atmModel:GetFullName())
        
        -- 1. Teleport ไปหา ATM (ปรับระยะห่างเล็กน้อยเพื่อไม่ให้ซ้อนกัน)
        hrp.CFrame = atmModel:GetPivot() * CFrame.new(0, 0, 3) 

        -- 2. เรียกใช้ RemoteFunction
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
        
        if remote then
            pcall(function()
                -- ส่งค่าตามที่คุณต้องการ
                remote:InvokeServer(atmModel) 
                print("✅ ส่งคำสั่งสำเร็จ!")
            end)
        else
            warn("❌ ไม่พบ Remote 'AttemptATMBustComplete'")
        end
    end
end

-- ============================================================
-- MAIN LOOP: สแกนและจัดการ ATM
-- ============================================================
task.spawn(function()
    print("🚀 เริ่มระบบ Auto ATM (รอบละ 30 วินาที) แล้ว...")
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
            -- ปรับเป็น 30 วินาทีตามที่ขอ
            task.wait(30) 
        end
        
        task.wait(3) -- สแกนทุก 3 วินาที
    end
end)
