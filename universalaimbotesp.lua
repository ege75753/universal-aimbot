-- LocalScript (Client-Side)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer

-- GUI Setup
local gui = Instance.new("ScreenGui")
gui.Name = "ESPvFinal"
gui.ResetOnSpawn = false
gui.Parent = localPlayer:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 150)
mainFrame.Position = UDim2.new(0.02, 0, 0.02, 0)
mainFrame.BackgroundTransparency = 0.8
mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = gui

local title = Instance.new("TextLabel")
title.Text = "ESP Controls"
title.Size = UDim2.new(1, 0, 0, 25)
title.Font = Enum.Font.SourceSansBold
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundTransparency = 1
title.Parent = mainFrame

local highlightToggle = Instance.new("TextButton")
highlightToggle.Text = "Boxes: ON"
highlightToggle.Size = UDim2.new(0.9, 0, 0, 30)
highlightToggle.Position = UDim2.new(0.05, 0, 0.2, 0)
highlightToggle.Parent = mainFrame

local nameTagToggle = Instance.new("TextButton")
nameTagToggle.Text = "Names: ON"
nameTagToggle.Size = UDim2.new(0.9, 0, 0, 30)
nameTagToggle.Position = UDim2.new(0.05, 0, 0.4, 0)
nameTagToggle.Parent = mainFrame

local healthBarToggle = Instance.new("TextButton")
healthBarToggle.Text = "Health: ON"
healthBarToggle.Size = UDim2.new(0.9, 0, 0, 30)
healthBarToggle.Position = UDim2.new(0.05, 0, 0.6, 0)
healthBarToggle.Parent = mainFrame

local headLockToggle = Instance.new("TextButton")
headLockToggle.Text = "Head Lock: OFF"
headLockToggle.Size = UDim2.new(0.9, 0, 0, 30)
headLockToggle.Position = UDim2.new(0.05, 0, 0.8, 0)
headLockToggle.Parent = mainFrame

-- Configuration
local settings = {
    showBox = true,
    showName = true,
    showHealth = true,
    boxColor = Color3.new(1, 0.2, 0.2),
    textColor = Color3.new(1, 1, 1),
    headLockEnabled = false,
    lockSmoothness = 0.2, -- Smoothness of camera tracking (lower = smoother)
    isRightClickHeld = false,
    lockedTarget = nil
}

-- Toggle System
local function updateToggles()
    highlightToggle.Text = "Boxes: " .. (settings.showBox and "ON" or "OFF")
    nameTagToggle.Text = "Names: " .. (settings.showName and "ON" or "OFF")
    healthBarToggle.Text = "Health: " .. (settings.showHealth and "ON" or "OFF")
    headLockToggle.Text = "Head Lock: " .. (settings.headLockEnabled and "ON" or "OFF")
end

local function findHeadTarget()
    local mouse = localPlayer:GetMouse()
    local camera = workspace.CurrentCamera
    local maxDistance = math.huge -- Infinite lock range
    local closestTarget = nil
    local closestDistance = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                -- Convert head position to screen space
                local headPos, onScreen = camera:WorldToScreenPoint(head.Position)
                
                if onScreen then
                    -- Calculate distance from mouse to head
                    local distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(headPos.X, headPos.Y)).Magnitude
                    
                    -- Find closest target under cursor
                    if distance < closestDistance and distance < 50 then -- 50 pixel threshold
                        closestDistance = distance
                        closestTarget = {
                            player = player,
                            head = head
                        }
                    end
                end
            end
        end
    end
    
    return closestTarget
end

-- Modified input handling
local isLocking = false

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 and settings.headLockEnabled then
        isLocking = true
        settings.lockedTarget = findHeadTarget()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isLocking = false
        settings.lockedTarget = nil
    end
end)

-- ESP System (Unmodified)
local trackedPlayers = {}

local function createESP(player)
    if player == localPlayer then return end
    
    local esp = {
        box = nil,
        nameTag = nil,
        healthBar = nil,
        connections = {}
    }
    
    local function updateCharacter(character)
        if esp.box then esp.box:Destroy() end
        if esp.nameTag then esp.nameTag:Destroy() end
        if esp.healthBar then esp.healthBar:Destroy() end
        
        local humanoid = character:WaitForChild("Humanoid")
        local rootPart = character:WaitForChild("HumanoidRootPart")
        
        -- Box Highlight
        esp.box = Instance.new("BillboardGui")
        esp.box.Size = UDim2.new(4, 0, 4, 0)
        esp.box.SizeOffset = Vector2.new(0.05, 0.05)
        esp.box.StudsOffset = Vector3.new(0, 0, 0)
        esp.box.AlwaysOnTop = true
        esp.box.Adornee = rootPart
        esp.box.Enabled = settings.showBox
        
        local boxFrame = Instance.new("Frame")
        boxFrame.Size = UDim2.new(1, 0, 1, 0)
        boxFrame.BackgroundTransparency = 1
        
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = settings.boxColor
        boxStroke.Thickness = 2
        boxStroke.Parent = boxFrame
        
        boxFrame.Parent = esp.box
        esp.box.Parent = character
        
        -- Name Tag
        esp.nameTag = Instance.new("BillboardGui")
        esp.nameTag.Size = UDim2.new(0, 200, 0, 50)
        esp.nameTag.StudsOffset = Vector3.new(0, 2.5, 0)
        esp.nameTag.AlwaysOnTop = true
        esp.nameTag.Adornee = rootPart
        esp.nameTag.Enabled = settings.showName
        
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text = player.Name
        nameLabel.Size = UDim2.new(1, 0, 1, 0)
        nameLabel.TextColor3 = settings.textColor
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansBold
        
        local textStroke = Instance.new("UIStroke")
        textStroke.Color = Color3.new(0, 0, 0)
        textStroke.Thickness = 1.5
        textStroke.Parent = nameLabel
        
        nameLabel.Parent = esp.nameTag
        esp.nameTag.Parent = character
        
        -- Health Bar
        esp.healthBar = Instance.new("BillboardGui")
        esp.healthBar.Size = UDim2.new(2, 0, 0.5, 0)
        esp.healthBar.StudsOffset = Vector3.new(0, 3, 0)
        esp.healthBar.AlwaysOnTop = true
        esp.healthBar.Adornee = rootPart
        esp.healthBar.Enabled = settings.showHealth
        
        local healthBar = Instance.new("Frame")
        healthBar.Size = UDim2.new(0.8, 0, 0.5, 0)
        healthBar.Position = UDim2.new(0.1, 0, 0.25, 0)
        healthBar.BackgroundColor3 = Color3.new(0.3, 0, 0)
        healthBar.BorderSizePixel = 0
        
        local healthFill = Instance.new("Frame")
        healthFill.Size = UDim2.new(1, 0, 1, 0)
        healthFill.BackgroundColor3 = Color3.new(0, 1, 0)
        healthFill.Parent = healthBar
        
        healthBar.Parent = esp.healthBar
        esp.healthBar.Parent = character
        
        -- Health updates
        esp.connections.health = humanoid.HealthChanged:Connect(function()
            healthFill.Size = UDim2.new(math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1), 0, 1, 0)
        end)
    end
    
    esp.connections.characterAdded = player.CharacterAdded:Connect(updateCharacter)
    if player.Character then
        updateCharacter(player.Character)
    end
    
    trackedPlayers[player] = esp
end

-- Toggle Handlers
headLockToggle.MouseButton1Click:Connect(function()
    settings.headLockEnabled = not settings.headLockEnabled
    updateToggles()
end)

highlightToggle.MouseButton1Click:Connect(function()
    settings.showBox = not settings.showBox
    updateToggles()
    for _, esp in pairs(trackedPlayers) do
        if esp.box then esp.box.Enabled = settings.showBox end
    end
end)

nameTagToggle.MouseButton1Click:Connect(function()
    settings.showName = not settings.showName
    updateToggles()
    for _, esp in pairs(trackedPlayers) do
        if esp.nameTag then esp.nameTag.Enabled = settings.showName end
    end
end)

healthBarToggle.MouseButton1Click:Connect(function()
    settings.showHealth = not settings.showHealth
    updateToggles()
    for _, esp in pairs(trackedPlayers) do
        if esp.healthBar then esp.healthBar.Enabled = settings.showHealth end
    end
end)

-- Player Management
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(function(player)
    if trackedPlayers[player] then
        if trackedPlayers[player].box then trackedPlayers[player].box:Destroy() end
        if trackedPlayers[player].nameTag then trackedPlayers[player].nameTag:Destroy() end
        if trackedPlayers[player].healthBar then trackedPlayers[player].healthBar:Destroy() end
        trackedPlayers[player] = nil
    end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        createESP(player)
    end
end

updateToggles()

-- Modified tracking system
RunService.RenderStepped:Connect(function()
    if settings.headLockEnabled and isLocking then
        -- Refresh target while holding right click
        settings.lockedTarget = findHeadTarget()
        
        if settings.lockedTarget and settings.lockedTarget.head then
            local camera = workspace.CurrentCamera
            local headPosition = settings.lockedTarget.head.Position
            local currentCFrame = camera.CFrame
            
            -- Calculate smooth look direction
            local newLookVector = (headPosition - currentCFrame.Position).Unit
            local smoothLookVector = currentCFrame.LookVector:Lerp(
                newLookVector,
                settings.lockSmoothness
            )
            
            -- Update camera
            camera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothLookVector)
        end
    end
end)