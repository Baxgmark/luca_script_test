local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

-- เอาลิงก์ Webhook จาก Discord มาใส่ในเครื่องหมายคำพูดด้านล่าง
local WEBHOOK_URL = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"

local function sendDataToDiscord()
local messageContent = "**:bar_chart: รายงานสถานะผู้เล่นในห้อง**\n```\n"

-- ลูปเก็บข้อมูลผู้เล่น
for _, player in ipairs(Players:GetPlayers()) do
local username = player.Name
local money = "ไม่พบข้อมูล/ถูกซ่อน"
local leaderstats = player:FindFirstChild("leaderstats")

if leaderstats then
local moneyStat = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
if moneyStat then
money = tostring(moneyStat.Value)
end
end

messageContent = messageContent .. "👤 " .. username .. " | 💰 " .. money .. "\n"
end

messageContent = messageContent .. "```"

-- แปลงข้อมูลให้อยู่ในรูปแบบ JSON ที่ Discord ต้องการ
local payload = HttpService:JSONEncode({
content = messageContent,
username = "Roblox Bot" -- เปลี่ยนชื่อบอทได้ตามต้องการ
})

-- เช็คว่า Executor รองรับฟังก์ชัน request หรือไม่
if request then
local response = request({
Url = WEBHOOK_URL,
Method = "POST",
Headers = {
["Content-Type"] = "application/json"
},
Body = payload
})

if response.StatusCode == 204 or response.StatusCode == 200 then
print(":white_check_mark: ส่งข้อมูลไปยัง Discord Webhook สำเร็จ!")
else
print(":x: เกิดข้อผิดพลาดในการส่ง: " .. tostring(response.StatusCode))
end
elseif syn and syn.request then -- สำหรับ Synapse X (เวอร์ชันเก่า)
syn.request({
Url = WEBHOOK_URL,
Method = "POST",
Headers = {["Content-Type"] = "application/json"},
Body = payload
})
print(":white_check_mark: ส่งข้อมูลไปยัง Discord Webhook สำเร็จ (ผ่าน syn.request)!")
else
print(":warning: Executor ของคุณไม่รองรับการส่ง HTTP Request")
end
end

sendDataToDiscord()