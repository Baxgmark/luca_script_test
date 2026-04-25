local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- 🔎 ฟังก์ชันสแกนแบบไดนามิก (Dynamic Scanner)
-- ============================================================
-- รับค่า: ชื่อของที่ต้องการหา (targetName), คลาสของมัน (targetClass)
local function scanDynamic(targetName, targetClass)
    local results = {}
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")

    -- สแกนแบบกวาดทั้ง Workspace (ไม่สนใจว่ามันจะถูกซ่อนอยู่ในโฟลเดอร์ไหน)
    for _, obj in ipairs(Workspace:GetDescendants()) do
        -- เช็คว่าชื่อตรง และประเภทตรงกับที่เราหาหรือไม่
        if obj.Name == targetName and obj:IsA(targetClass) then
            
            -- กรองเอาเฉพาะอันที่ "มีปุ่ม E ให้กด" และ "ปุ่มเปิดใช้งานอยู่"
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
            
            if prompt and prompt.Enabled then
                -- คำนวณระยะห่างระหว่างตัวเรากับเป้าหมาย
                local distance = math.huge
                if hrp then
                    -- ใช้ GetPivot() เพื่อดึงพิกัดกลางของ Model เสมอ
                    distance = (hrp.Position - obj:GetPivot().Position).Magnitude
                end
                
                -- เก็บข้อมูลใส่ตาราง
                table.insert(results, {
                    model = obj,
                    prompt = prompt,
                    dist = distance
                })
            end
        end
    end

    -- 🧠 ความฉลาดเพิ่มเติม: เรียงลำดับจาก "ใกล้ที่สุด" ไป "ไกลที่สุด"
    table.sort(results, function(a, b)
        return a.dist < b.dist
    end)

    return results -- ส่งคืนรายการที่หาเจอทั้งหมด (เรียงระยะทางให้แล้ว)
end

-- ============================================================
-- 🚀 ตัวอย่างการนำไปใช้งานใน Loop
-- ============================================================
task.spawn(function()
    print("🚀 เริ่มระบบสแกนเรดาร์ (สแกนหาเป้าหมายที่ใกล้ที่สุด)")
    
    while true do
        -- 💡 ไม่ตายตัว: คุณสามารถเปลี่ยนไปหา "Safe", "Register", "Airdrop" ได้หมดเลย
        -- แค่เปลี่ยนชื่อ "CriminalATM" เป็นชื่อโมเดลที่คุณต้องการ
        local targetItems = scanDynamic("CriminalATM", "Model")
        
        if #targetItems > 0 then
            -- ดึงอันดับ 1 (index 1) ซึ่งสคริปต์คำนวณมาแล้วว่า "อยู่ใกล้เราที่สุด"
            local nearestItem = targetItems[1]
            
            print(string.format("🎯 เจอเป้าหมาย %d จุด | ใกล้สุดห่างไป: %d Studs", #targetItems, nearestItem.dist))
            
            -- เอาเป้าหมายที่ใกล้ที่สุดไปเข้าฟังก์ชันปล้นของคุณต่อได้เลย
            -- bustATM(nearestItem) 
            
        else
            print("❌ ไม่พบเป้าหมายที่ใช้งานได้ในแมพตอนนี้")
        end
        
        task.wait(2) -- หน่วงเวลาการสแกนรอบต่อไป
    end
end)
