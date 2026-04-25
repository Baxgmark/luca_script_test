local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local BOUNTY_NAME = "Bounty" -- เปลี่ยนตามชื่อใน leaderstats ของเกม (เช่น Wanted, HeadValue)
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000

-- แคช Remote สำหรับยืนยันการปล้น
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ฟังก์ชันเช็คค่าหัวและวาร์ปไปจุดพัก
local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= BOUNTY_THRESHOLD then
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            print("🚨 ค่าหัวครบกำหนด! กำลังวาร์ปไปจุดปลอดภัย...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3) -- คูลดาวน์ 3 วิ
            print("✅ คูลดาวน์เสร็จสิ้น กลับไปสแกนตู้ต่อ")
        end
    end
end

-- ฟังก์ชันค้นหาตู้แบบ Dynamic (หาทั่วแมพ + เรียงตามระยะทางที่ใกล้ที่สุด)
local function getDynamicATMs()
    local atms = {}
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return atms end

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            -- กรองเฉพาะตู้ที่มีปุ่ม E และปุ่มยังใช้งานได้ (ไม่พัง)
            if prompt and prompt.Enabled then
                local dist = (hrp.Position - obj:GetPivot().Position).Magnitude
                table.insert(atms, {model = obj, prompt = prompt, distance = dist})
            end
        end
    end

    -- เรียงลำดับ: เอาตู้ที่ใกล้ที่สุดขึ้นก่อน
    table.sort(atms, function(a, b)
        return a.distance < b.distance
    end)
    
    return atms
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end

    -- 1. วาร์ป และ หันหน้าเข้าตู้
    local atmCFrame = atmModel:GetPivot()
    local atmPos = atmCFrame.Position
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmPos.X, standPos.Y, atmPos.Z))
    task.wait(0.5) 

    -- 2. กด E ค้าง
    if prompt and prompt.Enabled then
        print("⏳ กำลังปล้นตู้ห่างไป " .. math.floor(atmData.distance) .. " Studs...")
        prompt.HoldDuration = 5
        
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.5) -- รอจนกว่าจะปล้นเสร็จ
            
            -- 3. ส่ง Remote
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            
            task.wait(1.5) -- พักแอนิเมชัน
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP (ไม่ตัดโค้ดเดิม แต่เพิ่มความฉลาดเข้าไป)
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมด: Dynamic Scan + Bounty Check)")
    
    while true do
        -- เช็คค่าหัวทุกครั้งก่อนเริ่มรอบใหม่
        checkBounty()
        
        local allATMs = getDynamicATMs()
        
        if #allATMs > 0 then
            for _, atmData in ipairs(allATMs) do
                -- เช็คค่าหัวอีกรอบระหว่างการทำแต่ละตู้ เพื่อความไว
                checkBounty()
                
                if atmData.model:IsDescendantOf(Workspace) then
                    bustATM(atmData)
                end
            end
        end
        
        print("🔄 สแกนรอบใหม่ในอีก 1 วินาที...")
        task.wait(1) 
    end
end)
