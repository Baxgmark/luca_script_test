local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local BOUNTY_NAME = "Bounty" 
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

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

-- 🔎 ฟังก์ชันสแกนแบบสายฟ้าแลบ (เจออันแรก ส่งกลับทันที ไม่รอสแกนจบแมพ)
local function findNextATM()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            -- ถ้าเจออันที่ใช้งานได้ (Enabled) ให้ส่งค่ากลับไปวาร์ปทันที
            if prompt and prompt.Enabled then
                return {model = obj, prompt = prompt}
            end
        end
    end
    return nil
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end

    -- วาร์ป และ หันหน้า (รักษาโครงเดิม)
    local atmCFrame = atmModel:GetPivot()
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmCFrame.Position.X, standPos.Y, atmCFrame.Position.Z))
    
    task.wait(0.2) -- ลดเวลารอหลังวาร์ปเหลือ 0.2 (เร็วที่สุดที่ปุ่มจะเด้ง)

    if prompt and prompt.Enabled then
        print("⚡ เจอเป้าหมาย! กำลังทำงาน...")
        prompt.HoldDuration = 5 -- บังคับ 5 วิ ตามเงื่อนไขเดิม
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.2) -- 5 วิ + ดีเลย์นิดเดียวพอ
            
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP (ปรับให้ทำงานต่อเนื่อง 1 วินาที)
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมดความเร็วสูงสุด - ไม่คำนวณ)")
    
    while true do
        -- 1. เช็คค่าหัว
        local isResting = checkBounty()
        
        if not isResting then
            -- 2. หาตู้ถัดไป (เจอแล้วเอาเลย ไม่รอสแกนทั้งแมพ)
            local nextTarget = findNextATM()
            
            if nextTarget then
                bustATM(nextTarget)
                -- 3. ปล้นเสร็จ รอ 1 วินาทีตามที่ขอ แล้วหาอันใหม่ทันที
                print("🔄 ปล้นเสร็จ รอ 1 วิ...")
                task.wait(1)
            else
                -- ถ้าไม่เจอเลยจริงๆ ให้รอแป๊บนึงแล้วสแกนใหม่
                task.wait(0.5)
            end
        else
            task.wait(0.3)
        end
    end
end)
