local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- [[ ตั้งค่าคงที่ ]]
local BOUNTY_NAME = "Bounty" 
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000
local SCAN_AMOUNT = 20
local FLY_HEIGHT = 5000 -- ความสูงที่ต้องการให้ลอยขึ้นไป

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

local atmQueue = {}
local processedAtms = {}
local lastFoundTick = tick() -- ใช้จับเวลาล่าสุดที่เจอตัว

-- ฟังก์ชันเช็คค่าหัว
local function checkBounty()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    local bountyValue = leaderstats and leaderstats:FindFirstChild(BOUNTY_NAME)
    
    if bountyValue and bountyValue.Value >= BOUNTY_THRESHOLD then
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = SAFE_ZONE_CFRAME
            task.wait(3) 
        end
        return true
    end
    return false
end

-- 🔎 สแกนหาตู้
local function populateQueue()
    local foundCount = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt and prompt.Enabled and not processedAtms[obj] then
                table.insert(atmQueue, {model = obj, prompt = prompt})
                processedAtms[obj] = true
                foundCount = foundCount + 1
            end
        end
        if foundCount >= SCAN_AMOUNT then break end
    end
    
    if foundCount > 0 then
        lastFoundTick = tick() -- รีเซ็ตเวลาเมื่อเจอของ
    end
    return foundCount
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end

    local atmCFrame = atmModel:GetPivot()
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmCFrame.Position.X, standPos.Y, atmCFrame.Position.Z))
    
    task.wait(0.2) 

    if prompt and prompt.Enabled then
        prompt.HoldDuration = 5 
        if fireproximityprompt then
            fireproximityprompt(prompt)
            task.wait(5.2)
            if atmRemote then
                pcall(function() atmRemote:InvokeServer(atmModel) end)
            end
            task.delay(10, function() processedAtms[atmModel] = nil end)
            return true
        end
    end
    return false
end

-- ============================================================
-- MAIN LOOP (ระบบ Queue + ระบบลอยฟ้า)
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมด Queue + ระบบลอยฟ้าฉุกเฉิน)")
    
    while true do
        -- 1. พยายามหาตู้ใส่คิว
        if #atmQueue == 0 then
            populateQueue()
        end

        -- 2. ตรวจสอบเงื่อนไข: ถ้าคิวว่างเกิน 2 วินาที ให้ลอยขึ้นฟ้า
        if #atmQueue == 0 and (tick() - lastFoundTick) > 2 then
            local character = LocalPlayer.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                print("☁️ หาตู้ไม่เจอเกิน 2 วิ: กำลังลอยขึ้นฟ้าเพื่อความปลอดภัย...")
                -- ลอยค้างไว้จนกว่าจะเจอของใหม่
                while #atmQueue == 0 do
                    hrp.CFrame = CFrame.new(hrp.Position.X, FLY_HEIGHT, hrp.Position.Z)
                    hrp.Velocity = Vector3.new(0, 0, 0) -- หยุดแรงร่วง
                    
                    populateQueue() -- พยายามสแกนหาเรื่อยๆ ในขณะที่ลอย
                    task.wait(0.5)
                end
                print("🎯 เจอตู้ใหม่แล้ว! กำลังลงจากฟ้า...")
            end
        end

        -- 3. ทำงานตามคิวปกติ
        if #atmQueue > 0 then
            for i = 1, #atmQueue do
                checkBounty()
                
                local currentTarget = atmQueue[i]
                
                -- สแกนชุดใหม่มารอเมื่อถึงตู้ท้ายๆ
                if i == #atmQueue or i == (SCAN_AMOUNT - 1) then
                    task.spawn(populateQueue)
                end
                
                if currentTarget and currentTarget.model:IsDescendantOf(Workspace) then
                    bustATM(currentTarget)
                    task.wait(1)
                end
                
                atmQueue[i] = nil
            end
            table.clear(atmQueue)
        end
        
        task.wait(0.1)
    end
end)
