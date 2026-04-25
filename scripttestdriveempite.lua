local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- แคช Remote สำหรับยืนยันการปล้น
local atmRemote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("AttemptATMBustComplete")

-- ฟังก์ชันค้นหาตู้ (สแกนเฉพาะตู้ที่ "กด E ได้" เท่านั้น จะได้ไม่วาร์ปไปตู้ที่พังแล้ว)
local function getATMs()
    local atms = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            -- ตรวจสอบว่ามี ProximityPrompt และมันเปิดใช้งานอยู่ (Enabled = true)
            if prompt and prompt.Enabled then
                table.insert(atms, {model = obj, prompt = prompt})
            end
        end
    end
    return atms
end

local function bustATM(atmData)
    local atmModel = atmData.model
    local prompt = atmData.prompt
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return false end

    -- ==========================================
    -- 1. วาร์ป และ บังคับหันหน้าเข้าหาตู้ ATM
    -- ==========================================
    local atmCFrame = atmModel:GetPivot()
    local atmPos = atmCFrame.Position
    
    -- คำนวณจุดยืน: ถอยออกมาจากหน้าตู้ 3 studs
    -- 💡 หมายเหตุ: ถ้ายืนแล้วมันไปอยู่ "หลังตู้" ให้แก้เลข 3 เป็น -3 นะครับ (ขึ้นอยู่กับคนสร้างโมเดลเกม)
    local standPos = (atmCFrame * CFrame.new(0, 0, 3)).Position 
    
    -- วาร์ปไปที่จุดยืน พร้อมหันหน้าไปที่พิกัดตู้ ATM (ล็อกแกน Y ไว้ ตัวละครจะได้ไม่ก้ม/เงย)
    hrp.CFrame = CFrame.lookAt(standPos, Vector3.new(atmPos.X, standPos.Y, atmPos.Z))
    
    -- ⏳ ให้เวลาเกมโหลดตัวละครและ UI ให้เสร็จก่อนกด E (สำคัญมาก)
    task.wait(0.5) 

    -- ==========================================
    -- 2. กระบวนการกด E ค้าง (รอจนกว่าจะเสร็จแน่ๆ)
    -- ==========================================
    -- เช็คอีกรอบเผื่อตู้เพิ่งพังตอนเราวาร์ปมาถึง
    if prompt and prompt.Enabled then
        print("⏳ เจอหน้าจอ! กำลังกด E ค้างไว้ 5 วินาที...")
        
        -- ล็อกค่าเวลาไว้ที่ 5 วินาที
        prompt.HoldDuration = 5
        
        if fireproximityprompt then
            -- สั่งกด E
            fireproximityprompt(prompt)
            
            -- ⏳ ล็อกสคริปต์! บังคับให้รอ 5.5 วินาที (5 วิ + เผื่อเน็ตดีเลย์ 0.5 วิ)
            task.wait(5.5) 
            
            -- ==========================================
            -- 3. ส่ง Remote ยืนยันว่าเราปล้นเสร็จแล้ว
            -- ==========================================
            if atmRemote then
                local success, err = pcall(function()
                    atmRemote:InvokeServer(atmModel)
                end)
                
                if success then
                    print("✅ ปล้นสำเร็จ ได้เงินแล้ว!")
                else
                    warn("❌ เซิร์ฟเวอร์ปฏิเสธ: " .. tostring(err))
                end
            end
            
            -- ⏳ รออีกนิดให้หลอดแอนิเมชันมันหายไป ก่อนจะบินไปตู้ต่อไป
            task.wait(1.5)
            return true
        else
            warn("❌ Executor ของคุณไม่รองรับคำสั่ง fireproximityprompt")
            return false
        end
    else
        warn("⚠️ ตู้นี้กดไม่ได้แล้ว ข้าม...")
        return false
    end
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
    print("🚀 ระบบเริ่มทำงาน (โหมด: หันหน้าเข้าตู้ + ชัวร์ 100%)")
    
    while true do
        local allATMs = getATMs()
        
        for _, atmData in ipairs(allATMs) do
            if atmData.model:IsDescendantOf(Workspace) then
                -- ฟังก์ชันนี้จะ "บล็อก" จนกว่ากระบวนการปล้นตู้หนึ่งจะจบสมบูรณ์ (ประมาณ 7 วินาทีต่อตู้)
                bustATM(atmData)
            end
        end
        
        print("🔄 สแกนหาตู้รอบใหม่ในอีก 3 วินาที...")
        task.wait(3) 
    end
end)
