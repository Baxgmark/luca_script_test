local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

-- ฟังก์ชันโต้ตอบกับตู้
local function interactWithATM(atmModel)
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return end

    print("📍 กำลังดำเนินการกับตู้: " .. atmModel.Name)

    -- 1. วาร์ปไปหน้าตู้
    local atmPosition = atmModel:GetPivot().Position
    local offset = atmModel:GetPivot().LookVector * 4 -- ห่าง 4 หน่วย
    hrp.CFrame = CFrame.new(atmPosition + offset, atmPosition)
    
    task.wait(0.5) -- รอให้วาร์ปเสร็จ

    -- 2. วิธีที่ 1: พยายามกด ProximityPrompt (กด E ในเกม)
    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        print("🔍 พบ ProximityPrompt! กำลังจำลองการกด E...")
        fireproximityprompt(prompt)
        task.wait(0.5)
    else
        print("⚠️ ไม่พบ ProximityPrompt (จะข้ามไปใช้ Remote)")
    end

    -- 3. วิธีที่ 2: ใช้ Remote ตามที่คุณให้มา (สำรอง)
    local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")
    
    if remote then
        print("📡 กำลังส่ง Remote...")
        local success, err = pcall(function()
            -- ใช้ path ที่คุณระบุมาใน args
            local args = {
                [1] = atmModel -- ส่งตัวตู้ที่สแกนเจอเข้าไป
            }
            remote:InvokeServer(unpack(args))
        end)
        
        if success then
            print("✅ ส่ง Remote สำเร็จ!")
        else
            warn("❌ ส่ง Remote ล้มเหลว:", err)
        end
    else
        warn("❌ หา Remote 'AttemptATMBustComplete' ใน ReplicatedStorage ไม่เจอ!")
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    print("🚀 ระบบ Auto ATM เริ่มทำงานแล้ว (รอ 30 วินาทีต่อรอบ)")
    
    while true do
        local foundATM = nil
        
        -- ค้นหาตู้ใน Workspace
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
            -- ถ้าไม่เจอ ให้รอ 5 วินาทีแล้วหาใหม่
            task.wait(5)
        end
    end
end)
