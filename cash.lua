local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer

local WEBHOOK_URL    = "https://discord.com/api/webhooks/1487828555927785784/HmvL26aHOfJ7kAMrrwaDHtX6hOHIS7oVR_p_Qtjpsl8Gcg5BYbY53WNb5NzQCOu4N6uL"  -- ← ใส่ของคุณ
local httprequest = (syn and syn.request) or (http and http.request) or
    http_request or (fluxus and fluxus.request) or request

local function send(title, desc)
    if #desc > 3900 then desc = desc:sub(1,3900) .. "\n...(ตัด)" end
    pcall(function()
        httprequest({
            Url = WEBHOOK_URL, Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                username = "🔍 Blox Scanner",
                embeds = {{title=title, description=desc, color=0xF1C40F,
                    footer={text="Player: "..localPlayer.Name}}}
            })
        })
    end)
end

task.wait(3)

-- Dump ทุก GUI ที่มี (list ชื่อก่อน)
local guiNames = ""
for _, gui in ipairs(localPlayer.PlayerGui:GetChildren()) do
    guiNames = guiNames .. string.format("`%s` (%s)\n", gui.Name, gui.ClassName)
end
send("📋 PlayerGui ทั้งหมด", guiNames)
task.wait(2)

-- Dump label ใน GUI หลักที่น่าจะมีเงิน
local targets = {"Main", "HUD", "Hud", "MainGui", "Money", "Currency", "Stats", "PlayerStats"}
for _, name in ipairs(targets) do
    local gui = localPlayer.PlayerGui:FindFirstChild(name)
    if gui then
        local out = ""
        local function dump(parent, depth)
            depth = depth or 0
            if depth > 15 then return end
            for _, obj in ipairs(parent:GetChildren()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    out = out .. string.format("`%s` → `%s`\n",
                        tostring(obj.Text):sub(1,60), obj:GetFullName())
                end
                dump(obj, depth + 1)
            end
        end
        dump(gui)
        if out ~= "" then
            send("🖥️ GUI: " .. name, out)
            task.wait(2)
        end
    end
end