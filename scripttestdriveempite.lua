local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- ⚙️ การตั้งค่าระบบ
-- ==========================================
local BOUNTY_NAME = "Bounty" 
local SAFE_ZONE_CFRAME = CFrame.new(-2540.14, 15.83, 4030.19)
local BOUNTY_THRESHOLD = 500000
local FLY_HEIGHT = 5000 
local MAX_WAIT_TIME = 45 -- ⏳ ถ้ารอเกิน 45 วินาที จะทำการย้ายเซิร์ฟเวอร์ทันที!

local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

local KnownATMs = {}       
local ReadyQueue = {}      
local InQueueDict = {}     
local ProcessedATMs = {}   
local lastFoundTick = tick() -- ตัวจับเวลา

-- ==========================================
-- 🔄 ระบบย้ายเซิร์ฟเวอร์ (Server Hop)
-- ==========================================
local hopping = false
local function serverHop()
    if hopping then return end
    hopping = true
    print("🔄 เซิร์ฟเวอร์นี้ตู้ขาดแคลน! กำลังย้ายเซิร์ฟเวอร์ใหม่ (Server Hop)...")
    
    local placeId = game.PlaceId
    local serversApi = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return game:HttpGet(serversApi) -- จำเป็นต้องใช้ Executor ที่รองรับ HttpGet
    end)

    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            -- สุ่มหาเซิร์ฟเวอร์ที่คนไม่เต็ม
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    print("✈️ เจอเซิร์ฟเวอร์ใหม่แล้ว! กำลังวาร์ป...")
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                    task.wait(10) -- รอระบบย้ายเซิร์ฟ
                end
            end
        end
    end
    
    warn("⚠️ ย้ายเซิร์ฟเวอร์ล้มเหลว (รอสแกนตู้ในเซิร์ฟนี้ต่อไป)...")
    hopping = false
    lastFoundTick = tick() -- รีเซ็ตเวลาใหม่เพื่อไม่ให้สแปม Hop
end

-- ==========================================
-- 🧠 ระบบความจำ & เรดาร์แบบ Real-Time
-- ==========================================
local function registerATM(obj)
    if obj.Name == "CriminalATM" and obj:IsA("Model") then
        table.insert(KnownATMs, obj)
    end
end

for _, obj in ipairs(Workspace:GetDescendants()) do
    registerATM(obj)
end

Workspace.DescendantAdded:Connect(registerATM)

task.spawn(function()
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
        if foundInCycle then
            lastFoundTick = tick() -- รีเซ็ตเวลาถ้าระบบสแกนเจอของพร้อมใช้
        end
    end
end)

-- ==========================================
-- 🛡️ ระบบเช็คค่าหัว & ปล้นตู้
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

    ProcessedATMs[atmModel] = true 

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
-- 🚀 MAIN ENGINE
-- ==========================================
task.spawn(function()
    print("🚀 [Server Hopper Engine] รับประกันเจอของใน 1 นาที!")
    
    while true do
        checkBounty()

        if #ReadyQueue > 0 then
            local currentTarget = table.remove(ReadyQueue, 1)
            InQueueDict[currentTarget.model] = nil 
            bustATM(currentTarget)
            task.wait(1) 
        else
            -- เช็คเวลาว่าหาตู้ไม่ได้มานานแค่ไหนแล้ว
            local timeWaiting = tick() - lastFoundTick
            
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                -- ☁️ 1. ผ่านไป 2 วิ: ลอยขึ้นฟ้า
                if timeWaiting > 2 and timeWaiting < MAX_WAIT_TIME then
                    if hrp.Position.Y < (FLY_HEIGHT - 100) then
                        hrp.CFrame = CFrame.new(hrp.Position.X, FLY_HEIGHT, hrp.Position.Z)
                    end
                    hrp.Velocity = Vector3.new(0,0,0)
                
                -- 🔄 2. ผ่านไป 45 วิ: ย้ายเซิร์ฟเวอร์ทันที!
                elseif timeWaiting >= MAX_WAIT_TIME then
                    serverHop()
                end
            end
            
            task.wait(0.1)
        end
    end
end)
