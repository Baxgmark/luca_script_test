local HttpService = game:GetService("HttpService")
local workspace = game:GetService("Workspace")

local WEBHOOK_URL = "https://discord.com/api/webhooks/1293985728866291722/Lf76g8oL9B9N9qy_6twTsnqDPBGmBBdE6viGvU3ML_C-JrqM6bDwU3Rd5-OGlPDTC7Ge"

local function sendToDiscord(message)
    local data = {["content"] = message}
    
    local success, response = pcall(function()
        return HttpService:PostAsync(
            WEBHOOK_URL,
            HttpService:JSONEncode(data),
            Enum.HttpContentType.ApplicationJson,
            false,
            {["Content-Type"] = "application/json"}
        )
    end)
    
    if not success then
        warn("Failed to send: " .. tostring(response))
    else
        print("Sent successfully!")
    end
end

local function findATM()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj.Name == "CriminalATM" and obj:IsA("Model") then
            return obj
        end
    end
    return nil
end

-- ส่งตำแหน่งทุกๆ 30 วินาที (หรือตามที่กำหนด)
while true do
    local myATM = findATM()
    
    if myATM then
        local pos = myATM:GetPivot().Position
        local message = string.format(":round_pushpin: อัปเดตตำแหน่ง ATM\nX:%.0f Y:%.0f Z:%.0f\nเวลา: %s", 
            pos.X, pos.Y, pos.Z, os.date("%H:%M:%S"))
        
        sendToDiscord(message)
        print("ส่งข้อมูลรอบล่าสุดเมื่อ: " .. os.date())
    else
        print("ไม่พบ ATM ในรอบนี้")
        sendToDiscord(":warning: ไม่พบ CriminalATM ในเกมขณะนี้")
    end
    
    task.wait(30)  -- รอ 30 วินาที แล้วทำงานซ้ำ
end
