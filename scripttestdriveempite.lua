local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- แคช Remote ไว้ก่อน จะได้ไม่ต้องหาใหม่ทุกรอบ
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ฟังก์ชันดึงตู้ ATM ทั้งหมดในแมพ (สแกนรอบเดียวแล้วเก็บใส่ Table)
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
    if not hrp then return end

    -- วาร์ปไปที่ตู้
    hrp.CFrame = atmModel:GetPivot() * CFrame.new(0, 0, 3)
    task.wait(0.2) -- ลดเวลารอหลังวาร์ป (ให้โมเดลโหลดทันพอ)

    -- ลองส่ง Remote ยิงตรงไปที่ Server เลย (เพื่อความเร็วสูงสุด)
    if atmRemote then
        local success, err = pcall(function()
            atmRemote:InvokeServer(atmModel)
        end)

        -- ถ้าส่ง Remote สำเร็จ ไม่ต้องรอ 5.5 วิ
        if success then
            return true
        end
    end

    -- [กรณีที่ Server บังคับให้ต้องกด E ก่อน]
    local prompt = atmModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        -- ปรับเวลา ProximityPrompt ให้เป็น 0 (ถ้า Executor รองรับ)
        prompt.HoldDuration = 0 
        fireproximityprompt(prompt)
        
        -- รอให้ Server ประมวลผล (ปรับเวลาตรงนี้ขึ้นอยู่กับ Anti-cheat ของเกม แนะนำให้เริ่มที่ 1 วินาที)
        task.wait(1) 
        
        if atmRemote then
            pcall(function() atmRemote:InvokeServer(atmModel) end)
        end
        return true
    end

    return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    print("🚀 เริ่มระบบออโต้ฟาร์ม (Speed Optimized)")
    
    while true do
        local allATMs = getATMs() -- ดึงข้อมูลตู้ทั้งหมด
        
        if #allATMs > 0 then
            for _, currentATM in ipairs(allATMs) do
                -- เช็คว่าตู้ยังอยู่และเรายังมีชีวิตอยู่
                if currentATM:IsDescendantOf(Workspace) and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    bustATM(currentATM)
                    task.wait(1.5) -- ลดเวลารอระหว่างเปลี่ยนตู้ให้เร็วขึ้น
                end
            end
        else
            task.wait(2) -- ถ้ารอเกิดใหม่ ให้รอ 2 วินาทีแล้วหาใหม่
        end
        
        task.wait(0.5) -- พักสคริปต์นิดหน่อยกันเกมค้าง (Crash)
    end
end)
