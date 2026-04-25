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
local FLY_HEIGHT = 5000 

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ==========================================
-- 🧠 ระบบความจำระดับเสี้ยววินาที (Cache & Queue)
-- ==========================================
local KnownATMs = {}       -- จำตู้ทุกตู้ในแมพ (อัปเดตออโต้)
local ReadyQueue = {}      -- คิวตู้ที่ "พร้อมปล้นวินาทีนี้"
local InQueueDict = {}     -- ป้องกันการใส่คิวซ้ำซ้อน
local ProcessedATMs = {}   -- ตู้ที่กำลังปล้น/เพิ่งปล้นไป

-- 1. ฟังก์ชันจดจำตู้ (ถูกเรียกอัตโนมัติเมื่อเจอของใหม่)
local function registerATM(obj)
    if obj.Name == "CriminalATM" and obj:IsA("Model") then
        table.insert(KnownATMs, obj)
    end
end

-- 2. สแกนครั้งแรกครั้งเดียว (Zero-Lag Initiative)
for _, obj in ipairs(Workspace:GetDescendants()) do
    registerATM(obj)
end

-- 3. 🚨 เรดาร์ดักจับของเกิดใหม่แบบ Real-Time (0.01 วิ)
Workspace.DescendantAdded:Connect(registerATM)

-- ==========================================
-- 📡 ระบบสแกนเบื้องหลัง (ทำงาน 10 รอบต่อ 1 วินาที)
-- ==========================================
task.spawn(function()
    print("📡 ระบบเรดาร์ Real-time เริ่มทำงาน...")
    while task.wait(0.1) do
        for _, atm in ipairs(KnownATMs) do
            -- ถ้าตู้ยังอยู่ในแมพ และไม่ได้อยู่ในสถานะพึ่งปล้นเสร็จ
            if atm.Parent and not ProcessedATMs[atm] and not InQueueDict[atm] then
                local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
                
                if prompt and prompt.Enabled then
                    table.insert(ReadyQueue, {model = atm, prompt = prompt})
                    InQueueDict[atm] = true -- มาร์คว่าเข้าคิวแล้ว
                end
            end
        end
    end
end)

-- ==========================================
-- 🛡️ ระบบเช็คค่าหัว
-- ==========================================
local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= BOUNTY_THRESHOLD then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            print("🚨 ค่าหัวเต็ม! วาร์ปหนี...")
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3) 
        end
        return true
    end
    return false
end

-- ==========================================
-- 💰 ระบบปล้นตู้ (Bust)
-- ==========================================
local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if not hrp or not atmModel.Parent or not prompt.Enabled then return false end

    ProcessedATMs[atmModel] = true -- ล็อกตู้ไว้ไม่ให้เรดาร์กวน

    -- วาร์ปแบบหันหน้า
    local atmPivot = atmModel:GetPivot()
    local standPos = (atmPivot * CFrame.new(0, 0, 3)).Position 
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmPivot.Position.X, standPos.Y, atmPivot.Position.Z))
    
    task.wait(0.2) -- จังหวะหน่วงให้เซิร์ฟเวอร์โหลดตัวเรา (สำคัญมาก ห้ามน้อยกว่านี้)

    if prompt.Enabled then
        prompt.HoldDuration = 5 
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.1) -- ลดลงมาเหลือ 5.1 เพื่อความไวสุดขีด
            
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            
            -- ปลดล็อกตู้หลังผ่านไป 5 วินาที (เผื่อตู้มันเกิดไว)
            task.delay(5, function() ProcessedATMs[atmModel] = nil end)
            return true
        end
    end
    
    ProcessedATMs[atmModel] = nil -- ถ้าปล้นพลาด ปลดล็อกทันที
    return false
end

-- ==========================================
-- 🚀 MAIN ENGINE (เครื่องยนต์หลัก ไม่มีการหยุดพัก)
-- ==========================================
task.spawn(function()
    print("🚀 [Hyper-Stable Engine] ล็อกเป้าหมายแบบวินาทีต่อวินาที!")
    
    while true do
        checkBounty()

        -- ถ้ามีของในคิว (ดึงตัวแรกออกมาทำทันที)
        if #ReadyQueue > 0 then
            local currentTarget = table.remove(ReadyQueue, 1)
            InQueueDict[currentTarget.model] = nil -- เอาออกจากเช็คลิสต์คิว
            
            bustATM(currentTarget)
            
            -- จบ 1 ตู้ รอ 1 วิ ตามที่คุณต้องการ
            task.wait(1) 
            
        else
            -- ☁️ โหมดฉุกเฉิน: ถ้าคิวว่าง (หาตู้ไม่ได้) ลอยขึ้นฟ้าทันที!
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- ถ้าไม่ได้อยู่บนฟ้า ให้พุ่งขึ้นไป
                if hrp.Position.Y < (FLY_HEIGHT - 100) then
                    hrp.CFrame = CFrame.new(hrp.Position.X, FLY_HEIGHT, hrp.Position.Z)
                end
                hrp.Velocity = Vector3.new(0,0,0) -- หยุดแรงโน้มถ่วง
            end
            
            -- รอจังหวะสั้นๆ 0.1 วิ แล้ววนลูปใหม่ (สแตนด์บายรอตู้เกิด)
            task.wait(0.1)
        end
    end
end)
