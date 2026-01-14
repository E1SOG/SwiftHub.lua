-- [[ UI SCRIPT ]]
local engine = loadstring(game:HttpGet("https://raw.githubusercontent.com/Singularity5490/rbimgui-2/main/rbimgui-2.lua"))()
local SkeletonLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Blissful4992/ESPs/main/UniversalSkeleton.lua"))()

local window1 = engine.new({ 
    text = "Swift beta 1.0.0 (Counter blox)", 
    size = UDim2.new(300, 750) 
})
window1.open()
local mainTab = window1.new({ text = "Swift Menu" })

-- [[ Global Settings ]]
_G.CornerBox_Enabled = false
_G.Skeleton_Enabled = false
_G.HealthBar_Enabled = false
_G.Distance_Enabled = false
_G.ESP_TeamCheck = false

_G.Aimbot_Enabled = false
_G.WallCheck_Enabled = false
_G.Aim_TeamCheck = false
_G.Aimbot_Smoothness = 0.05
_G.Aimbot_Key = Enum.KeyCode.E 
_G.Aimbot_TargetPart = "Head"

_G.Show_FOV = false
_G.FOV_Radius = 150
_G.FOV_Transparency = 0.7
_G.FOV_Color = Color3.fromRGB(0, 0, 255)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local PlayerStorage = {}

-- [[ FOV Drawing ]]
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Thickness = 1
FOVCircle.NumSides = 64

-- [[ Cleanup Function ]]
local function RemovePlayerESP(plr)
    if PlayerStorage[plr] then
        local data = PlayerStorage[plr]
        if data.Skeleton then pcall(function() data.Skeleton:Remove() end) end
        for _, v in pairs(data.Box) do v:Remove() end
        data.HealthBarOutline:Remove()
        data.HealthBar:Remove()
        data.DistanceText:Remove()
        PlayerStorage[plr] = nil
    end
end

Players.PlayerRemoving:Connect(RemovePlayerESP)

-- [[ Visibility Check ]]
local function IsVisible(targetPart)
    if not _G.WallCheck_Enabled then return true end
    local ray = Ray.new(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return hit and hit:IsDescendantOf(targetPart.Parent)
end

-- [[ Core ESP Function ]]
local function UpdateESP(plr)
    if plr == LocalPlayer then return end
    
    if not PlayerStorage[plr] then
        PlayerStorage[plr] = {
            Skeleton = nil,
            LastChar = nil, -- ใช้สำหรับเช็ค Respawn
            Box = {
                TL1 = Drawing.new("Line"), TL2 = Drawing.new("Line"),
                TR1 = Drawing.new("Line"), TR2 = Drawing.new("Line"),
                BL1 = Drawing.new("Line"), BL2 = Drawing.new("Line"),
                BR1 = Drawing.new("Line"), BR2 = Drawing.new("Line")
            },
            HealthBarOutline = Drawing.new("Line"),
            HealthBar = Drawing.new("Line"),
            DistanceText = Drawing.new("Text")
        }
        local dtxt = PlayerStorage[plr].DistanceText
        dtxt.Outline = true dtxt.Center = true dtxt.Font = 2 dtxt.Color = Color3.new(1,1,1)
        
        for _, v in pairs(PlayerStorage[plr].Box) do v.Color = Color3.new(1,1,1) v.Thickness = 1.5 end
        
        -- Health Bar Config: 2.5 Thickness
        PlayerStorage[plr].HealthBarOutline.Thickness = 4.0
        PlayerStorage[plr].HealthBarOutline.Color = Color3.new(0,0,0)
        PlayerStorage[plr].HealthBar.Thickness = 2.5
    end

    local data = PlayerStorage[plr]
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    -- [[ Respawn Fix: ถ้าตัวละครเปลี่ยน ให้รีเซ็ตกระดูกใหม่ ]]
    if data.LastChar ~= char then
        if data.Skeleton then
            pcall(function() data.Skeleton:Remove() end)
            data.Skeleton = nil
        end
        data.LastChar = char
    end

    local isTeammate = (plr.Team == LocalPlayer.Team)
    local shouldShowESP = hrp and hum and hum.Health > 0 and (not _G.ESP_TeamCheck or not isTeammate)

    if not shouldShowESP then
        if data.Skeleton then data.Skeleton:SetVisible(false) end
        for _, v in pairs(data.Box) do v.Visible = false end
        data.HealthBarOutline.Visible = false
        data.HealthBar.Visible = false
        data.DistanceText.Visible = false
        return
    end

    -- [[ Skeleton Section ]]
    if _G.Skeleton_Enabled then
        if not data.Skeleton then 
            data.Skeleton = SkeletonLib:NewSkeleton(plr) 
        end
        data.Skeleton:SetVisible(true)
        pcall(function() data.Skeleton:Update() end)
    elseif data.Skeleton then 
        data.Skeleton:SetVisible(false) 
    end

    local pos, onS = Camera:WorldToViewportPoint(hrp.Position)
    if onS then
        local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
        local sizeX, sizeY = (2000/dist), (2500/dist)
        local x, y = pos.X, pos.Y

        -- Corner Box
        for _, v in pairs(data.Box) do v.Visible = _G.CornerBox_Enabled end
        if _G.CornerBox_Enabled then
            local o = sizeX * 0.25
            data.Box.TL1.From = Vector2.new(x-sizeX, y-sizeY) data.Box.TL1.To = Vector2.new(x-sizeX+o, y-sizeY)
            data.Box.TL2.From = Vector2.new(x-sizeX, y-sizeY) data.Box.TL2.To = Vector2.new(x-sizeX, y-sizeY+o)
            data.Box.TR1.From = Vector2.new(x+sizeX, y-sizeY) data.Box.TR1.To = Vector2.new(x+sizeX-o, y-sizeY)
            data.Box.TR2.From = Vector2.new(x+sizeX, y-sizeY) data.Box.TR2.To = Vector2.new(x+sizeX, y-sizeY+o)
            data.Box.BL1.From = Vector2.new(x-sizeX, y+sizeY) data.Box.BL1.To = Vector2.new(x-sizeX+o, y+sizeY)
            data.Box.BL2.From = Vector2.new(x-sizeX, y+sizeY) data.Box.BL2.To = Vector2.new(x-sizeX, y+sizeY-o)
            data.Box.BR1.From = Vector2.new(x+sizeX, y+sizeY) data.Box.BR1.To = Vector2.new(x+sizeX-o, y+sizeY)
            data.Box.BR2.From = Vector2.new(x+sizeX, y+sizeY) data.Box.BR2.To = Vector2.new(x+sizeX, y+sizeY-o)
        end

        -- Distance: Top Aligned
        if _G.Distance_Enabled then
            data.DistanceText.Visible = true
            data.DistanceText.Position = Vector2.new(x, y - sizeY - 20)
            data.DistanceText.Text = "[" .. math.floor(dist) .. "m]"
        else data.DistanceText.Visible = false end

        -- Health Bar: 2.5 Thickness
        if _G.HealthBar_Enabled then
            local bx = x - sizeX - 7
            local hP = hum.Health / hum.MaxHealth
            data.HealthBarOutline.Visible = true; data.HealthBar.Visible = true
            data.HealthBarOutline.From = Vector2.new(bx, y+sizeY)
            data.HealthBarOutline.To = Vector2.new(bx, y-sizeY)
            data.HealthBar.From = Vector2.new(bx, y+sizeY)
            data.HealthBar.To = Vector2.new(bx, y+sizeY - (sizeY*2*hP))
            data.HealthBar.Color = Color3.fromHSV(hP * 0.3, 1, 1)
        else 
            data.HealthBarOutline.Visible = false; data.HealthBar.Visible = false 
        end
    else
        for _, v in pairs(data.Box) do v.Visible = false end
        data.DistanceText.Visible = false
        data.HealthBarOutline.Visible = false
        data.HealthBar.Visible = false
    end
end

-- [[ Loop & Aimbot ]]
local aiming = false
UserInputService.InputBegan:Connect(function(i) if i.KeyCode == _G.Aimbot_Key then aiming = true end end)
UserInputService.InputEnded:Connect(function(i) if i.KeyCode == _G.Aimbot_Key then aiming = false end end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.Show_FOV
    FOVCircle.Radius = _G.FOV_Radius
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Color = _G.FOV_Color
    FOVCircle.Transparency = _G.FOV_Transparency

    if _G.Aimbot_Enabled and aiming then
        local target, shortest = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(_G.Aimbot_TargetPart) then
                if _G.Aim_TeamCheck and p.Team == LocalPlayer.Team then continue end
                local tPart = p.Character[_G.Aimbot_TargetPart]
                local pos, onS = Camera:WorldToViewportPoint(tPart.Position)
                if onS and IsVisible(tPart) then
                    local d = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                    if d <= _G.FOV_Radius and d < shortest then target, shortest = p, d end
                end
            end
        end
        if target then
            local cf = CFrame.new(Camera.CFrame.Position, target.Character[_G.Aimbot_TargetPart].Position)
            Camera.CFrame = Camera.CFrame:Lerp(cf, _G.Aimbot_Smoothness)
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do UpdateESP(p) end
end)

-- [[ UI Menu ]]
mainTab.new("label", { text = "--- ESP SETTINGS ---", color = Color3.new(0, 1, 0) })
mainTab.new("switch", { text = "ESP Box" }).event:Connect(function(s) _G.CornerBox_Enabled = s end)
mainTab.new("switch", { text = "Skeleton" }).event:Connect(function(s) _G.Skeleton_Enabled = s end)
mainTab.new("switch", { text = "Health Bar" }).event:Connect(function(s) _G.HealthBar_Enabled = s end)
mainTab.new("switch", { text = "Distance" }).event:Connect(function(s) _G.Distance_Enabled = s end)
mainTab.new("switch", { text = "Team Check" }).event:Connect(function(s) _G.ESP_TeamCheck = s end)

mainTab.new("label", { text = "--- AIMBOT SETTINGS ---", color = Color3.new(1, 0, 0) })
mainTab.new("switch", { text = "Aimbot" }).event:Connect(function(s) _G.Aimbot_Enabled = s end)
mainTab.new("switch", { text = "Wall Check" }).event:Connect(function(s) _G.WallCheck_Enabled = s end)
mainTab.new("switch", { text = "Team Check" }).event:Connect(function(s) _G.Aim_TeamCheck = s end)
mainTab.new("slider", { text = "Smoothness", min = 1, max = 10, value = 5 }).event:Connect(function(v)
    local sValues = {0.25, 0.2, 0.15, 0.1, 0.05, 0.03, 0.02, 0.015, 0.012, 0.008}
    _G.Aimbot_Smoothness = sValues[v]
end)

mainTab.new("label", { text = "--- FOV SETTINGS ---", color = Color3.new(0, 0, 1) })
mainTab.new("switch", { text = "Show FOV" }).event:Connect(function(s) _G.Show_FOV = s end)
mainTab.new("slider", { text = "FOV Radius", min = 10, max = 500, value = 150 }).event:Connect(function(v) _G.FOV_Radius = v end)
mainTab.new("slider", { text = "FOV Transparency", min = 1, max = 10, value = 7 }).event:Connect(function(v) _G.FOV_Transparency = v/10 end)

mainTab.new("keybind", { text = "Aim Key", key = Enum.KeyCode.E }).event:Connect(function(k) _G.Aimbot_Key = k end)
