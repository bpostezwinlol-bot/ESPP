local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

------------------------------------------------------------------------
-- НАСТРОЙКИ
------------------------------------------------------------------------
local CYBER_COLORS = {
    Cyan     = Color3.fromRGB(0, 240, 255),
    DarkBg   = Color3.fromRGB(15, 15, 20),
    Visible  = Color3.fromRGB(0, 255, 0),   -- Зеленый (видно)
    Hidden   = Color3.fromRGB(255, 0, 0),   -- Красный (за стеной)
    Default  = Color3.fromRGB(255, 255, 255),
}

local settings_tbl = {
    ESP_Enabled = true,
    Box_Enabled = true,
    Skeleton = true,
    ViewAngle = true,
    Tracers = true,
    WallColor_Enabled = true,
    Max_Distance = 1500,
}

local BOX_SCALE = 1.10

if CoreGui:FindFirstChild("UniversalEspGui") then
    CoreGui.UniversalEspGui:Destroy()
end

local espCache = {}

local function createDrawing(className, properties)
    local obj = Drawing.new(className)
    for k, v in pairs(properties) do
        obj[k] = v
    end
    return obj
end

local function addPlayerESP(player)
    if espCache[player] then return end
    
    local drawings = {
        Box = createDrawing("Square", {Thickness = 1 * BOX_SCALE, Filled = false, Visible = false}),
        Info = createDrawing("Text", {Size = 13, Center = true, Outline = true, Visible = false}),
        TracerLine = createDrawing("Line", {Thickness = 1, Transparency = 0.7, Visible = false}),
        
        HeadCircle = createDrawing("Circle", {Thickness = 2, Filled = false, Visible = false, NumSides = 20}),
        ViewAngleLine = createDrawing("Line", {Thickness = 1.5, Visible = false}),
        
        SkeletonLines = {
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
            createDrawing("Line", {Thickness = 1.5, Visible = false}),
        }
    }
    
    espCache[player] = drawings
end

local function hidePlayerESP(drawings)
    drawings.Box.Visible = false
    drawings.Info.Visible = false
    drawings.TracerLine.Visible = false
    drawings.HeadCircle.Visible = false
    drawings.ViewAngleLine.Visible = false
    for _, line in ipairs(drawings.SkeletonLines) do line.Visible = false end
end

local function removePlayerESP(player)
    if espCache[player] then
        for k, obj in pairs(espCache[player]) do
            if k == "SkeletonLines" then
                for _, line in ipairs(obj) do pcall(function() line:Remove() end) end
            elseif typeof(obj) == "table" then
                for _, subObj in pairs(obj) do pcall(function() subObj:Remove() end) end
            else
                pcall(function() obj:Remove() end)
            end
        end
        espCache[player] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then addPlayerESP(p) end
end
Players.PlayerAdded:Connect(addPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

local function IsVisible(part)
    local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 5000)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
    return hit and hit:IsDescendantOf(part.Parent)
end

------------------------------------------------------------------------
-- РЕНДЕР ЛУП
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if not myHrp then return end

    for _, player in ipairs(Players:GetPlayers()) do 
        if player ~= LocalPlayer then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local drawings = espCache[player]
            
            if drawings then
                local rendered = false
                
                if settings_tbl.ESP_Enabled and char and hrp and hum and hum.Health > 0 then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    
                    if distance <= settings_tbl.Max_Distance then
                        local head = char:FindFirstChild("Head")
                        
                        if head then
                            local current_color = CYBER_COLORS.Default
                            if settings_tbl.WallColor_Enabled then
                                if IsVisible(head) then
                                    current_color = CYBER_COLORS.Visible
                                else
                                    current_color = CYBER_COLORS.Hidden
                                end
                            end

                            local rootScreenPos, rootOnScreen = Camera:WorldToViewportPoint(hrp.Position)
                            local headScreenPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legScreenPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                            
                            if rootOnScreen then
                                rendered = true
                                
                                local height = math.abs(headScreenPos.Y - legScreenPos.Y) * BOX_SCALE
                                local width = (height / 2) * BOX_SCALE
                                local boxPos = Vector2.new(rootScreenPos.X - width / 2, headScreenPos.Y)

                                if settings_tbl.Box_Enabled then
                                    drawings.Box.Size = Vector2.new(width, height)
                                    drawings.Box.Position = boxPos
                                    drawings.Box.Color = current_color
                                    drawings.Box.Visible = true
                                else
                                    drawings.Box.Visible = false
                                end
                                
                                local hpInt = math.floor(hum.Health)
                                drawings.Info.Text = string.format("%s\n[%d HP] [%dm]", player.Name, hpInt, math.floor(distance))
                                drawings.Info.Position = Vector2.new(boxPos.X + (width / 2), boxPos.Y - 35)
                                drawings.Info.Color = current_color
                                drawings.Info.Visible = true
                                
                                if settings_tbl.ViewAngle then
                                    local headPos = head.Position
                                    local lookVectorEnd = headPos + (head.CFrame.LookVector * 4)
                                    local headScr, headOnS = Camera:WorldToViewportPoint(headPos)
                                    local lookScr, lookOnS = Camera:WorldToViewportPoint(lookVectorEnd)
                                    
                                    if headOnS and lookOnS then
                                        drawings.ViewAngleLine.From = Vector2.new(headScr.X, headScr.Y)
                                        drawings.ViewAngleLine.To = Vector2.new(lookScr.X, lookScr.Y)
                                        drawings.ViewAngleLine.Color = current_color
                                        drawings.ViewAngleLine.Visible = true
                                    else
                                        drawings.ViewAngleLine.Visible = false
                                    end
                                else
                                    drawings.ViewAngleLine.Visible = false
                                end
                                
                                if settings_tbl.Tracers then
                                    local vpSize = Camera.ViewportSize
                                    drawings.TracerLine.From = Vector2.new(vpSize.X / 2, vpSize.Y)
                                    drawings.TracerLine.To = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                                    drawings.TracerLine.Color = current_color
                                    drawings.TracerLine.Visible = true
                                else
                                    drawings.TracerLine.Visible = false
                                end
                                
                                if settings_tbl.Skeleton then
                                    local function getJoint(name)
                                        local part = char:FindFirstChild(name)
                                        if part then
                                            local pos, onS = Camera:WorldToViewportPoint(part.Position)
                                            return onS and Vector2.new(pos.X, pos.Y) or nil
                                        end
                                        return nil
                                    end
                                    
                                    local headJoint = getJoint("Head")
                                    local upperTorso = getJoint("UpperTorso") or getJoint("Torso")
                                    local lowerTorso = getJoint("LowerTorso") or upperTorso
                                    local leftUpperArm = getJoint("LeftUpperArm") or getJoint("Left Arm")
                                    local leftLowerArm = getJoint("LeftLowerArm") or getJoint("LeftUpperArm")
                                    local rightUpperArm = getJoint("RightUpperArm") or getJoint("Right Arm")
                                    local rightLowerArm = getJoint("RightLowerArm") or getJoint("RightUpperArm")
                                    local leftLeg = getJoint("LeftLowerLeg") or getJoint("Left Leg") or getJoint("LeftUpperLeg")
                                    local rightLeg = getJoint("RightLowerLeg") or getJoint("Right Leg") or getJoint("RightUpperLeg")
                                    
                                    if headJoint then
                                        drawings.HeadCircle.Visible = true
                                        drawings.HeadCircle.Radius = math.clamp((height / 8) * 2, 8, 30)
                                        drawings.HeadCircle.Position = headJoint
                                        drawings.HeadCircle.Color = current_color
                                    else
                                        drawings.HeadCircle.Visible = false
                                    end

                                    local pairs_list = {
                                        {headJoint, upperTorso},
                                        {upperTorso, leftUpperArm}, {leftUpperArm, leftLowerArm},
                                        {upperTorso, rightUpperArm}, {rightUpperArm, rightLowerArm},
                                        {upperTorso, lowerTorso},
                                        {lowerTorso, leftLeg},
                                        {lowerTorso, rightLeg}
                                    }
                                    
                                    for i, line in ipairs(drawings.SkeletonLines) do
                                        local pPair = pairs_list[i]
                                        if pPair and pPair[1] and pPair[2] then
                                            line.From = pPair[1]
                                            line.To = pPair[2]
                                            line.Color = current_color
                                            line.Visible = true
                                        else
                                            line.Visible = false
                                        end
                                    end
                                else
                                    drawings.HeadCircle.Visible = false
                                    for _, line in ipairs(drawings.SkeletonLines) do line.Visible = false end
                                end
                            end
                        end
                    end
                end
                
                if not rendered then
                    hidePlayerESP(drawings)
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- МОБИЛЬНОЕ МЕНЮ
------------------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UniversalEspGui"
ScreenGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Parent = ScreenGui
ToggleBtn.Size = UDim2.new(0, 70, 0, 30)
ToggleBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
ToggleBtn.BackgroundColor3 = CYBER_COLORS.Cyan
ToggleBtn.Text = "MENU"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.Font = Enum.Font.RobotoMono
ToggleBtn.TextSize = 12
ToggleBtn.Active = true
ToggleBtn.Draggable = true

local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = CYBER_COLORS.DarkBg
MainFrame.Position = UDim2.new(0.3, 0, 0.2, 0)
MainFrame.Size = UDim2.new(0, 180, 0, 260)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = CYBER_COLORS.Cyan
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Visible = false

ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local function createButton(name, posY, key)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.Size = UDim2.new(0.9, 0, 0, 25)
    btn.Position = UDim2.new(0.05, 0, posY, 0)
    btn.Font = Enum.Font.RobotoMono
    btn.TextSize = 10
    
    local function updateState()
        if settings_tbl[key] then
            btn.BackgroundColor3 = CYBER_COLORS.Cyan
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
            btn.Text = name .. ": [ON]"
        else
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = CYBER_COLORS.Cyan
            btn.Text = name .. ": [OFF]"
        end
    end
    
    updateState()
    
    btn.MouseButton1Click:Connect(function()
        settings_tbl[key] = not settings_tbl[key]
        updateState()
    end)
end

createButton("ESP", 0.04, "ESP_Enabled")
createButton("BOX", 0.16, "Box_Enabled")
createButton("SKELETON", 0.28, "Skeleton")
createButton("VIEW ANGLE", 0.40, "ViewAngle")
createButton("TRACERS", 0.52, "Tracers")
createButton("WALL COLOR", 0.64, "WallColor_Enabled")

local DistBox = Instance.new("TextBox")
DistBox.Parent = MainFrame
DistBox.Size = UDim2.new(0.9, 0, 0, 25)
DistBox.Position = UDim2.new(0.05, 0, 0.77, 0)
DistBox.Font = Enum.Font.RobotoMono
DistBox.TextSize = 10
DistBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
DistBox.TextColor3 = CYBER_COLORS.Cyan
DistBox.Text = tostring(settings_tbl.Max_Distance)
DistBox.ClearTextOnFocus = false

DistBox.FocusLost:Connect(function()
    local num = tonumber(DistBox.Text)
    if num then
        settings_tbl.Max_Distance = num
        DistBox.Text = tostring(num)
    else
        DistBox.Text = tostring(settings_tbl.Max_Distance)
    end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Главный GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RealMiniMapGuiPro"
ScreenGui.ResetOnSpawn = false

local parentGui = pcall(function() return CoreGui.Name end) and CoreGui or LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Parent = parentGui

-- Главный контейнер
local MainHolder = Instance.new("Frame")
MainHolder.Name = "MainHolder"
MainHolder.Size = UDim2.new(0, 140, 0, 175)
MainHolder.Position = UDim2.new(1, -160, 0, 20)
MainHolder.BackgroundTransparency = 1
MainHolder.Parent = ScreenGui

-- Окно карты
local MapFrame = Instance.new("Frame")
MapFrame.Name = "MapFrame"
MapFrame.Size = UDim2.new(0, 140, 0, 140)
MapFrame.Position = UDim2.new(0, 0, 0, 0)
MapFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MapFrame.BorderSizePixel = 2
MapFrame.BorderColor3 = Color3.fromRGB(0, 240, 255)
MapFrame.ClipsDescendants = true
MapFrame.Parent = MainHolder

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0.5, 0)
UICorner.Parent = MapFrame

-- ViewportFrame
local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, 0, 1, 0)
Viewport.BackgroundTransparency = 1
Viewport.Parent = MapFrame

local MapCamera = Instance.new("Camera")
MapCamera.FieldOfView = 50
Viewport.CurrentCamera = MapCamera

-- Кнопка "Свернуть" / Кружок
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 24, 0, 24)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ToggleBtn.BackgroundTransparency = 0.3
ToggleBtn.BorderSizePixel = 1
ToggleBtn.BorderColor3 = Color3.fromRGB(0, 240, 255)
ToggleBtn.Text = "—"
ToggleBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 18
ToggleBtn.ZIndex = 50
ToggleBtn.Parent = MainHolder

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0.5, 0)
ToggleCorner.Parent = ToggleBtn

-- Кнопка "Обновить"
local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Name = "RefreshBtn"
RefreshBtn.Size = UDim2.new(0, 60, 0, 22)
RefreshBtn.Position = UDim2.new(0, 0, 0, 145)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
RefreshBtn.BackgroundTransparency = 0.8
RefreshBtn.BorderSizePixel = 1
RefreshBtn.BorderColor3 = Color3.fromRGB(0, 240, 255)
RefreshBtn.Text = "Обновить"
RefreshBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
RefreshBtn.Font = Enum.Font.SourceSansBold
RefreshBtn.TextSize = 11
RefreshBtn.ZIndex = 40
RefreshBtn.Parent = MainHolder

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = RefreshBtn

-- Кнопки Зума (+ / -)
local ZoomInBtn = Instance.new("TextButton")
ZoomInBtn.Size = UDim2.new(0, 35, 0, 22)
ZoomInBtn.Position = UDim2.new(0, 65, 0, 145)
ZoomInBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ZoomInBtn.BackgroundTransparency = 0.8
ZoomInBtn.BorderSizePixel = 1
ZoomInBtn.BorderColor3 = Color3.fromRGB(0, 240, 255)
ZoomInBtn.Text = "+"
ZoomInBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
ZoomInBtn.Font = Enum.Font.SourceSansBold
ZoomInBtn.TextSize = 14
ZoomInBtn.ZIndex = 40
ZoomInBtn.Parent = MainHolder

local ZoomInCorner = Instance.new("UICorner")
ZoomInCorner.CornerRadius = UDim.new(0, 6)
ZoomInCorner.Parent = ZoomInBtn

local ZoomOutBtn = Instance.new("TextButton")
ZoomOutBtn.Size = UDim2.new(0, 35, 0, 22)
ZoomOutBtn.Position = UDim2.new(0, 105, 0, 145)
ZoomOutBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
ZoomOutBtn.BackgroundTransparency = 0.8
ZoomOutBtn.BorderSizePixel = 1
ZoomOutBtn.BorderColor3 = Color3.fromRGB(0, 240, 255)
ZoomOutBtn.Text = "-"
ZoomOutBtn.TextColor3 = Color3.fromRGB(0, 240, 255)
ZoomOutBtn.Font = Enum.Font.SourceSansBold
ZoomOutBtn.TextSize = 14
ZoomOutBtn.ZIndex = 40
ZoomOutBtn.Parent = MainHolder

local ZoomOutCorner = Instance.new("UICorner")
ZoomOutCorner.CornerRadius = UDim.new(0, 6)
ZoomOutCorner.Parent = ZoomOutBtn

-- Стрелка локального игрока
local MyMarker = Instance.new("Frame")
MyMarker.Name = "MyMarker"
MyMarker.Size = UDim2.new(0, 20, 0, 20)
MyMarker.AnchorPoint = Vector2.new(0.5, 0.5)
MyMarker.Position = UDim2.new(0.5, 0, 0.5, 0)
MyMarker.BackgroundTransparency = 1
MyMarker.ZIndex = 30
MyMarker.Parent = MapFrame

local MyArrow = Instance.new("ImageLabel")
MyArrow.Size = UDim2.new(1, 0, 1, 0)
MyArrow.BackgroundTransparency = 1
MyArrow.Image = "rbxassetid://6034818372"
MyArrow.ImageColor3 = Color3.fromRGB(0, 240, 255)
MyArrow.Rotation = 180
MyArrow.ZIndex = 31
MyArrow.Parent = MyMarker

local PlayerMarkers = {}

local function GetPlayerMarker(plr)
    if PlayerMarkers[plr] then return PlayerMarkers[plr] end
    local pMarker = Instance.new("Frame")
    pMarker.Name = "Marker_" .. plr.Name
    pMarker.Size = UDim2.new(0, 16, 0, 16)
    pMarker.AnchorPoint = Vector2.new(0.5, 0.5)
    pMarker.BackgroundTransparency = 1
    pMarker.ZIndex = 20
    pMarker.Parent = MapFrame
    
    local pArrow = Instance.new("ImageLabel")
    pArrow.Name = "PArrow"
    pArrow.Size = UDim2.new(1, 0, 1, 0)
    pArrow.BackgroundTransparency = 1
    pArrow.Image = "rbxassetid://6034818372"
    pArrow.ImageColor3 = Color3.fromRGB(255, 50, 50)
    pArrow.Rotation = 180
    pArrow.ZIndex = 21
    pArrow.Parent = pMarker
    
    PlayerMarkers[plr] = pMarker
    return pMarker
end

Players.PlayerRemoving:Connect(function(plr)
    if PlayerMarkers[plr] then
        PlayerMarkers[plr]:Destroy()
        PlayerMarkers[plr] = nil
    end
end)

-- УМНОЕ ПЕРЕНОСИМОЕ СВОРАЧИВАНИЕ (Кружок можно и таскать, и кликать)
local isCollapsed = false
local dragging, dragInput, dragStart, startPos
local hasMoved = false

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainHolder.Position
        hasMoved = false
    end
end)

MainHolder.InputBegan:Connect(function(input)
    if not isCollapsed and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragging = true
        dragStart = input.Position
        startPos = MainHolder.Position
        hasMoved = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 4 then
            hasMoved = true
            MainHolder.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if not hasMoved then
        isCollapsed = not isCollapsed
        MapFrame.Visible = not isCollapsed
        RefreshBtn.Visible = not isCollapsed
        ZoomInBtn.Visible = not isCollapsed
        ZoomOutBtn.Visible = not isCollapsed
        ToggleBtn.Text = isCollapsed and "+" or "—"
        MainHolder.Size = isCollapsed and UDim2.new(0, 24, 0, 24) or UDim2.new(0, 140, 0, 175)
    end
end)

-- ЗУМ (от 30 до 1200)
local HEIGHT_ZOOM = 120

ZoomInBtn.MouseButton1Click:Connect(function()
    HEIGHT_ZOOM = math.max(30, HEIGHT_ZOOM - 35)
end)

ZoomOutBtn.MouseButton1Click:Connect(function()
    HEIGHT_ZOOM = math.min(1200, HEIGHT_ZOOM + 35)
end)

-- Обновление геометрии мира
local isUpdating = false
local function RefreshMap()
    if isUpdating then return end
    isUpdating = true
    RefreshBtn.Text = "..."
    
    Viewport:ClearAllChildren()
    for _, obj in ipairs(workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("BasePart") or obj:IsA("Folder")) 
           and not Players:GetPlayerFromCharacter(obj) 
           and not obj:FindFirstChildOfClass("ParticleEmitter") then
            pcall(function()
                local clone = obj:Clone()
                clone.Parent = Viewport
            end)
        end
    end
    
    RefreshBtn.Text = "Обновить"
    isUpdating = false
end

task.spawn(RefreshMap)
RefreshBtn.MouseButton1Click:Connect(RefreshMap)

-- Рендер кадров + Чек стен (зеленый/красный)
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.RenderStepped:Connect(function()
    if isCollapsed then return end
    
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if myHrp then
        local myPos = myHrp.Position
        
        -- Камера миникарты
        MapCamera.CFrame = CFrame.new(myPos + Vector3.new(0, HEIGHT_ZOOM, 0), myPos)
        
        -- Стрелка игрока ровно вперед
        local myLook = myHrp.CFrame.LookVector
        local myAngleRad = math.atan2(-myLook.X, myLook.Z)
        MyMarker.Rotation = math.deg(myAngleRad) + 90
        
        -- Позиция твоей реальной камеры для чека стен
        local realCamPos = workspace.CurrentCamera.CFrame.Position
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local pChar = plr.Character
                local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart")
                local pHum = pChar and pChar:FindFirstChildOfClass("Humanoid")
                
                local hasHealth = false
                if pHum then hasHealth = pHum.Health > 0 end
                
                if pHrp and hasHealth then
                    local pMarker = GetPlayerMarker(plr)
                    local screenPos, onScreen = MapCamera:WorldToViewportPoint(pHrp.Position)
                    
                    if onScreen then
                        pMarker.Visible = true
                        pMarker.Position = UDim2.new(screenPos.X, 0, screenPos.Y, 0)
                        
                        -- Поворот врага
                        local pLook = pHrp.CFrame.LookVector
                        local pAngleRad = math.atan2(-pLook.X, pLook.Z)
                        pMarker.Rotation = math.deg(pAngleRad) + 90
                        
                        -- Чек стен (лучи от твоей камеры до врага)
                        local targetPos = pHrp.Position
                        local direction = targetPos - realCamPos
                        
                        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, pChar}
                        local rayResult = workspace:Raycast(realCamPos, direction, raycastParams)
                        
                        local pArrow = pMarker:FindFirstChild("PArrow")
                        if pArrow then
                            if rayResult == nil then
                                pArrow.ImageColor3 = Color3.fromRGB(0, 255, 100) -- Зеленый (видишь прямо)
                            else
                                pArrow.ImageColor3 = Color3.fromRGB(255, 50, 50) -- Красный (за стеной)
                            end
                        end
                    else
                        pMarker.Visible = false
                    end
                else
                    if PlayerMarkers[plr] then PlayerMarkers[plr].Visible = false end
                end
            end
        end
    end
end)

print("--- UNIVERSAL 3D MAP MILLION/10 LOADED ---")
