local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local BOUNTY_NAME = "Bounty" 
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000
local SCAN_AMOUNT = 20 -- จำนวนตู้ที่สแกนต่อรอบ

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

local atmQueue = {} -- คิวเก็บรายชื่อตู้
local processedAtms = {} -- เก็บตู้ที่ปล้นไปแล้วชั่วคราวเพื่อไม่ให้สแกนซ้ำ

-- ฟังก์ชันเช็คค่าหัว
local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= BOUNTY_THRESHOLD then
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            print("🚨 ค่าหัวครบ! วาร์ปพัก...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3) 
        end
        return true
    end
    return false
end

-- 🔎 ฟังก์ชันสแกนหาตู้แบบชุด (Batch Scan)
local function populateQueue()
    print("📡 กำลังสแกนหาตู้ใหม่ " .. SCAN_AMOUNT .. " ตู้...")
    local foundCount = 0
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            -- เช็คว่า: มีปุ่ม E + ปุ่มเปิดอยู่ + ไม่ใช่ตู้ที่เพิ่งปล้นไป + ไม่อยู่ในคิวแล้ว
            if prompt and prompt.Enabled and not processedAtms[obj] then
                table.insert(atmQueue, {model = obj, prompt = prompt})
                processedAtms[obj] = true -- มาร์คไว้ว่าเอาเข้าคิวแล้ว
                foundCount = foundCount + 1
            end
        end
        
        if foundCount >= SCAN_AMOUNT then break end
    end
    print("✅ สแกนเสร็จสิ้น! พบ " .. foundCount .. " ตู้")
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end

    -- วาร์ป และ หันหน้า
    local atmCFrame = atmModel:GetPivot()
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmCFrame.Position.X, standPos.Y, atmCFrame.Position.Z))
    
    task.wait(0.2) 

    if prompt and prompt.Enabled then
        prompt.HoldDuration = 5 
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.2) -- 5 วิ + ดีเลย์นิดหน่อย
            
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            
            -- หลังจากปล้นเสร็จ ให้นำออกจากรายการตรวจสอบเพื่อให้สแกนใหม่ได้ในรอบหน้า (ถ้าตู้เกิดใหม่)
            task.delay(10, function() processedAtms[atmModel] = nil end)
            
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP (ระบบ Queue)
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมด Queue 20 ตู้ + Auto-Refill)")
    
    while true do
        -- 1. ถ้าคิวว่าง ให้สแกนหา 20 ตู้แรก
        if #atmQueue == 0 then
            populateQueue()
        end
        
        -- 2. เริ่มทำงานตามคิว
        for i = 1, #atmQueue do
            -- เช็คค่าหัวทุกครั้ง
            checkBounty()
            
            local currentTarget = atmQueue[i]
            
            -- 🎯 ไฮไลท์: ถ้าถึงตู้ที่ 19 (หรือตู้รองสุดท้าย) ให้สแกนชุดใหม่มารอเลย
            if i == #atmQueue or i == (SCAN_AMOUNT - 1) then
                task.spawn(populateQueue) -- สแกนแบบเบื้องหลัง (ไม่หยุดรอ)
            end
            
            if currentTarget and currentTarget.model:IsDescendantOf(Workspace) then
                bustATM(currentTarget)
                task.wait(1) -- รอ 1 วิแล้วไปตู้ถัดไปตามคำขอ
            end
            
            -- ลบตู้ออกจากคิวเมื่อทำเสร็จ
            atmQueue[i] = nil
        end
        
        -- เคลียร์ตารางคิวให้สะอาดก่อนเริ่มรอบใหม่
        table.clear(atmQueue)
        task.wait(0.5)
    end
end)
