local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ⚙️ การตั้งค่าระบบ
-- ==========================================
local BOUNTY_NAME = "Bounty" 
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000
local FLY_HEIGHT = 1000 

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ==========================================
-- 🧠 ระบบความจำระดับเสี้ยววินาที (Event-Driven)
-- ==========================================
local KnownATMs = {}       
local ReadyQueue = {}      
local InQueueDict = {}     
local ProcessedATMs = {}   
local lastFoundTick = tick()

-- ฟังก์ชันจดจำตู้ (ดักจับของใหม่แบบ Real-time)
local function registerATM(obj)
    if obj.Name == "CriminalATM" and obj:IsA("Model") then
        table.insert(KnownATMs, obj)
    end
end

-- สแกนครั้งแรกครั้งเดียวเพื่อเก็บข้อมูลตู้ที่มีอยู่แล้ว
for _, obj in ipairs(Workspace:GetDescendants()) do
    registerATM(obj)
end

-- 🚨 ดักจับตู้ที่กำลังจะเกิดใหม่ในอนาคต (0.01 วิ)
Workspace.DescendantAdded:Connect(registerATM)

-- ==========================================
-- 📡 ระบบสแกนหาตู้พร้อมปล้น (ทำงานเบื้องหลัง)
-- ==========================================
task.spawn(function()
    print("📡 เรดาร์สแกนตู้พร้อมใช้งาน...")
    while task.wait(0.1) do
        local foundInCycle = false
        for _, atm in ipairs(KnownATMs) do
            if atm.Parent and not ProcessedATMs[atm] and not InQueueDict[atm] then
                local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt and prompt.Enabled then
                    table.insert(ReadyQueue, {model = atm, prompt = prompt})
                    InQueueDict[atm] = true 
                    foundInCycle = true
                end
            end
        end
        -- รีเซ็ตเวลาถ้าระบบสแกนเจอของ
        if foundInCycle then
            lastFoundTick = tick()
        end
    end
end)

-- ==========================================
-- 🛡️ ระบบเช็คค่าหัว & 💰 ปล้นตู้
-- ==========================================
local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= BOUNTY_THRESHOLD then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            print("🚨 ค่าหัวเต็ม! วาร์ปพัก...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3) 
        end
        return true
    end
    return false
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not atmModel.Parent or not prompt.Enabled then return false end

    ProcessedATMs[atmModel] = true -- ล็อกสถานะตู้

    -- วาร์ปแบบหันหน้า
    local atmPivot = atmModel:GetPivot()
    local standPos = (atmPivot * CFrame.new(0, 0, 3)).Position 
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmPivot.Position.X, standPos.Y, atmPivot.Position.Z))
    
    task.wait(0.2) 

    if prompt.Enabled then
        prompt.HoldDuration = 5 
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.1) 
            
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            
            task.delay(5, function() ProcessedATMs[atmModel] = nil end)
            return true
        end
    end
    
    ProcessedATMs[atmModel] = nil
    return false
end

-- ==========================================
-- 🚀 MAIN ENGINE (เครื่องยนต์หลัก)
-- ==========================================
task.spawn(function()
    print("🚀 [Hover & Strike Engine] พร้อมลุยยาวๆ บนเซิร์ฟเวอร์นี้!")
    local isFlying = false
    
    while true do
        checkBounty()

        -- ถ้ามีตู้ในคิวให้ทำทันที
        if #ReadyQueue > 0 then
            if isFlying then
                print("🎯 ตู้เกิดแล้ว! ทิ้งดิ่งลงไปฟาร์ม...")
                isFlying = false
            end
            
            local currentTarget = table.remove(ReadyQueue, 1)
            InQueueDict[currentTarget.model] = nil 
            
            bustATM(currentTarget)
            
            -- ปล้นเสร็จ รอ 1 วิ ตามที่คุณต้องการ
            task.wait(1) 
            
        else
            -- ☁️ ถ้าคิวว่างเกิน 2 วินาที: ให้บินขึ้นไปรอรับของบนฟ้า
            if (tick() - lastFoundTick) > 2 then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not isFlying then
                        print("☁️ ตู้หมดแมพ: บินขึ้นฟ้า รอแอดมิน/ระบบเสกตู้ใหม่...")
                        isFlying = true
                    end
                    
                    -- ดันตัวละครขึ้นฟ้าและหยุดแรงโน้มถ่วง
                    if hrp.Position.Y < (FLY_HEIGHT - 100) then
                        hrp.CFrame = CFrame.new(hrp.Position.X, FLY_HEIGHT, hrp.Position.Z)
                    end
                    hrp.Velocity = Vector3.new(0,0,0)
                end
            end
            
            -- รอจังหวะสั้นๆ เพื่อไม่ให้ลูปกิน CPU หนักเกินไป
            task.wait(0.1)
        end
    end
end)
