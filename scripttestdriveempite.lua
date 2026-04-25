local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันเช็คว่าตู้พร้อมปล้นไหม
local function isAtmReady(atmModel)
    -- *** ตรงนี้สำคัญ ***: คุณต้องเข้าไปดูใน Explorer ในเกมว่า 
    -- เวลาตู้พังแล้ว มีอะไรเปลี่ยนไปบ้าง เช่น มี BoolValue ชื่อ "Busted" เปลี่ยนเป็น true หรือเปล่า
    -- ถ้าไม่มี ให้ลองเช็คว่าโมเดลชื่อ "Money" หายไปไหม
    
    local bustedValue = atmModel:FindFirstChild("Busted") -- ลองเปลี่ยนชื่อตรงนี้ตามที่เห็นใน Explorer
    if bustedValue and bustedValue.Value == true then
        return false -- ถ้าค่าเป็น true แสดงว่าพังแล้ว
    end
    
    return true -- ถ้ายังปกติ ให้ return true
end

local function interactWithATM(atmModel)
    -- เช็คก่อนวาร์ป
    if not isAtmReady(atmModel) then
        print("⚠️ ตู้พังแล้ว ข้ามการปล้น")
        return
    end

    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    if hrp and atmModel then
        -- วาร์ปไปด้านหน้าตู้
        local atmPosition = atmModel:GetPivot().Position
        local offset = atmModel:GetPivot().LookVector * 3
        hrp.CFrame = CFrame.new(atmPosition + offset, atmPosition)
        
        task.wait(0.5)

        -- ส่ง Remote
        local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
        if remote then
            pcall(function()
                remote:InvokeServer(atmModel)
                print("✅ ปล้นตู้สำเร็จ!")
            end)
        end
    end
end

-- MAIN LOOP
task.spawn(function()
    while true do
        local foundATM = Workspace:FindFirstChild("CriminalATM", true) -- ค้นหาแบบเร็วขึ้น
        
        if foundATM and foundATM:IsA("Model") then
            interactWithATM(foundATM)
            task.wait(30)
        end
        task.wait(3)
    end
end)
