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

-- loop ค้นหา ATM และส่งข้อความทุกกรณี
while true do
    local myATM = findATM()
    
    if myATM then
        local pos = myATM:GetPivot().Position
        local message = string.format("✅ พบตู้ ATM แล้ว!\nตำแหน่ง: X:%.0f Y:%.0f Z:%.0f", pos.X, pos.Y, pos.Z)
        
        sendToDiscord(message)
        print("เจอแล้ว! อยู่ที่: " .. myATM:GetFullName())
    else
        local message = "❌ ไม่พบ CriminalATM ในเกมขณะนี้\nกำลังค้นหาต่อไป..."
        
        sendToDiscord(message)
        print("ยังไม่พบ CriminalATM กำลังค้นหาใหม่ใน 5 วินาที...")
    end
    
    task.wait(5)  -- รอ 5 วินาที แล้วค้นหาใหม่ (ไม่ว่าเจอหรือไม่เจอ)
end
