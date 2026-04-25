local HttpService = game:GetService("HttpService")

local Players = game:GetService("Players")

local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer



-- ============================================================

-- 1. ตั้งค่า Webhook URL (ต้องเปลี่ยนเป็น URL ใหม่ของคุณ)

-- วิธีแก้: เติม .hyra.io หลังคำว่า discord.com เพื่อผ่านการบล็อก

-- ตัวอย่าง: https://discord.com.hyra.io/api/webhooks/YOUR_ID/YOUR_TOKEN

-- ============================================================

local WEBHOOK_URL = "https://discord.com.hyra.io/api/webhooks/1293985728866291722/Lf76g8oL9B9N9qy_6twTsnqDPBGmBBdE6viGvU3ML_C-JrqM6bDwU3Rd5-OGlPDTC7Ge"



-- ฟังก์ชันดึง Request ของ Executor (ห้ามใช้ HttpService:PostAsync เด็ดขาด)

local request = (http_request or request or syn.request or http.request)



-- ฟังก์ชันส่งข้อมูลเข้า Discord

local function sendDiscord(message)

    if not request then

        warn("❌ Executor ไม่รองรับฟังก์ชัน request")

        return

    end



    local payload = {

        ["content"] = message

    }



    local success, response = pcall(function()

        return request({

            Url = WEBHOOK_URL,

            Method = "POST",

            Headers = { ["Content-Type"] = "application/json" },

            Body = HttpService:JSONEncode(payload)

        })

    end)



    if not success then

        warn("❌ ส่งไม่สำเร็จ: " .. tostring(response))

    else

        print("✅ ส่งข้อมูลสำเร็จ!")

    end

end



-- ฟังก์ชันสั่งให้ตัวละครบินขึ้น

local function startFlying()

    local character = localPlayer.Character

    if character and character:FindFirstChild("HumanoidRootPart") then

        local hrp = character.HumanoidRootPart

        

        -- สร้างแรงพุ่งขึ้น

        local bv = Instance.new("BodyVelocity")

        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)

        bv.Velocity = Vector3.new(0, 50, 0) -- บินขึ้น

        bv.Parent = hrp

        

        -- ลบแรงทิ้งหลังจาก 1.5 วินาที

        task.delay(1.5, function()

            bv:Destroy()

        end)

    end

end



-- ============================================================

-- MAIN LOOP: สแกนหา ATM

-- ============================================================

task.spawn(function()

    print("🚀 เริ่มระบบสแกนแล้ว...")

    while true do

        local foundATM = nil

        

        -- วนหา ATM

        for _, obj in pairs(Workspace:GetDescendants()) do

            if obj.Name == "CriminalATM" and obj:IsA("Model") then

                foundATM = obj

                break

            end

        end



        if foundATM then

            local pos = foundATM:GetPivot().Position

            local msg = string.format("💰 **พบ ATM!**\nพิกัด: X:%.0f, Y:%.0f, Z:%.0f", pos.X, pos.Y, pos.Z)

            

            print("พบ ATM! กำลังดำเนินการ...")

            startFlying()     -- สั่งบิน

            sendDiscord(msg)  -- ส่งข้อความ

            

            task.wait(60)     -- รอ 60 วินาทีค่อยสแกนใหม่ (ป้องกัน Spam)

        end

        

        task.wait(3) -- สแกนทุก 3 วินาที

    end

end)
