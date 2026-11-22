-- Credit: hedgehog
-- File: follow_behind.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DISTANCE_BEHIND = 3.5
local GUI_NAME = "HedgehogFollowUI"

if playerGui:FindFirstChild(GUI_NAME) then
	playerGui[GUI_NAME]:Destroy()
end

-- 1. UI SETUP
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 100
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 276)
mainFrame.Position = UDim2.new(0.5, -140, 0.62, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", mainFrame)
stroke.Color = Color3.fromRGB(80, 80, 105)
stroke.Thickness = 1.5

local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(0.92, 0, 0, 16)
creditLabel.Position = UDim2.new(0.04, 0, 0.025, 0)
creditLabel.BackgroundTransparency = 1
creditLabel.TextColor3 = Color3.fromRGB(130, 165, 255)
creditLabel.Text = "Credit: hedgehog"
creditLabel.Font = Enum.Font.GothamBold
creditLabel.TextSize = 11
creditLabel.TextXAlignment = Enum.TextXAlignment.Right
creditLabel.Parent = mainFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.92, 0, 0, 18)
statusLabel.Position = UDim2.new(0.04, 0, 0.075, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(180, 190, 215)
statusLabel.Text = "Select target in Whitelist, then press button / F"
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = mainFrame

local targetInput = Instance.new("TextBox")
targetInput.Size = UDim2.new(0.46, 0, 0, 32)
targetInput.Position = UDim2.new(0.04, 0, 0.15, 0)
targetInput.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
targetInput.TextColor3 = Color3.fromRGB(255, 255, 255)
targetInput.PlaceholderColor3 = Color3.fromRGB(145, 145, 165)
targetInput.PlaceholderText = "Add name..."
targetInput.Text = ""
targetInput.Font = Enum.Font.GothamMedium
targetInput.TextSize = 12
targetInput.ClearTextOnFocus = false
targetInput.Parent = mainFrame
Instance.new("UICorner", targetInput).CornerRadius = UDim.new(0, 7)

local addButton = Instance.new("TextButton")
addButton.Size = UDim2.new(0.21, 0, 0, 32)
addButton.Position = UDim2.new(0.515, 0, 0.15, 0)
addButton.BackgroundColor3 = Color3.fromRGB(60, 115, 220)
addButton.TextColor3 = Color3.fromRGB(255, 255, 255)
addButton.Text = "+ ADD"
addButton.Font = Enum.Font.GothamBold
addButton.TextSize = 11
addButton.Parent = mainFrame
Instance.new("UICorner", addButton).CornerRadius = UDim.new(0, 7)

local scanButton = Instance.new("TextButton")
scanButton.Size = UDim2.new(0.215, 0, 0, 32)
scanButton.Position = UDim2.new(0.745, 0, 0.15, 0)
scanButton.BackgroundColor3 = Color3.fromRGB(85, 85, 105)
scanButton.TextColor3 = Color3.fromRGB(255, 255, 255)
scanButton.Text = "SCAN"
scanButton.Font = Enum.Font.GothamBold
scanButton.TextSize = 10
scanButton.Parent = mainFrame
Instance.new("UICorner", scanButton).CornerRadius = UDim.new(0, 7)

local whitelistScroll = Instance.new("ScrollingFrame")
whitelistScroll.Size = UDim2.new(0.92, 0, 0, 112)
whitelistScroll.Position = UDim2.new(0.04, 0, 0.29, 0)
whitelistScroll.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
whitelistScroll.BorderSizePixel = 0
whitelistScroll.ScrollBarThickness = 5
whitelistScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
whitelistScroll.Parent = mainFrame
Instance.new("UICorner", whitelistScroll).CornerRadius = UDim.new(0, 8)

local listLayout = Instance.new("UIListLayout", whitelistScroll)
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

local listPadding = Instance.new("UIPadding", whitelistScroll)
listPadding.PaddingTop = UDim.new(0, 6)
listPadding.PaddingBottom = UDim.new(0, 6)
listPadding.PaddingLeft = UDim.new(0, 6)
listPadding.PaddingRight = UDim.new(0, 6)

local actionButton = Instance.new("TextButton")
actionButton.Size = UDim2.new(0.92, 0, 0, 42)
actionButton.Position = UDim2.new(0.04, 0, 0.795, 0)
actionButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
actionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
actionButton.Text = "FOLLOW BEHIND (F)"
actionButton.Font = Enum.Font.GothamBold
actionButton.TextSize = 13
actionButton.Parent = mainFrame
Instance.new("UICorner", actionButton).CornerRadius = UDim.new(0, 8)

-- 2. DRAG UI
local dragging, dragInput, dragStart, startPos
mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, input.Position, mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- 3. WHITELIST & TARGETS
local whitelist = {}
local selectedTargets = {}

local function getMyParts()
	local char = player.Character
	if not char then return nil, nil, nil end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function isValidTargetModel(obj)
	return obj:IsA("Model")
		and obj ~= player.Character
		and obj:FindFirstChildOfClass("Humanoid") ~= nil
		and obj:FindFirstChild("HumanoidRootPart") ~= nil
end

local function addNameUnique(nameStr, autoSelect)
	if not nameStr or nameStr == "" or nameStr == player.Name then return end
	for _, existing in ipairs(whitelist) do
		if existing == nameStr then
			if autoSelect then selectedTargets[existing] = true end
			return
		end
	end
	table.insert(whitelist, nameStr)
	if autoSelect then selectedTargets[nameStr] = true end
end

local function refreshWhitelistUI()
	for _, child in ipairs(whitelistScroll:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end

	for idx, name in ipairs(whitelist) do
		local isSelected = selectedTargets[name] == true
		local row = Instance.new("Frame")
		row.LayoutOrder = idx
		row.Size = UDim2.new(1, -4, 0, 28)
		row.BackgroundColor3 = isSelected and Color3.fromRGB(45, 145, 85) or Color3.fromRGB(48, 48, 60)
		row.BorderSizePixel = 0
		row.Parent = whitelistScroll
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

		local selectBtn = Instance.new("TextButton")
		selectBtn.Size = UDim2.new(0.82, 0, 1, 0)
		selectBtn.BackgroundTransparency = 1
		selectBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		selectBtn.Text = (isSelected and "[SELECTED] " or "[SELECT] ") .. name
		selectBtn.Font = isSelected and Enum.Font.GothamBold or Enum.Font.Gotham
		selectBtn.TextSize = 11
		selectBtn.TextXAlignment = Enum.TextXAlignment.Left
		selectBtn.Parent = row
		Instance.new("UIPadding", selectBtn).PaddingLeft = UDim.new(0, 8)

		local removeBtn = Instance.new("TextButton")
		removeBtn.Size = UDim2.new(0.16, 0, 1, 0)
		removeBtn.Position = UDim2.new(0.83, 0, 0, 0)
		removeBtn.BackgroundTransparency = 1
		removeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
		removeBtn.Text = "X"
		removeBtn.Font = Enum.Font.GothamBold
		removeBtn.TextSize = 12
		removeBtn.Parent = row

		selectBtn.MouseButton1Click:Connect(function()
			selectedTargets[name] = not selectedTargets[name] or nil
			statusLabel.Text = (selectedTargets[name] and "Selected target: " or "Deselected: ") .. name
			refreshWhitelistUI()
		end)

		removeBtn.MouseButton1Click:Connect(function()
			selectedTargets[name] = nil
			table.remove(whitelist, idx)
			statusLabel.Text = "Removed: " .. name
			refreshWhitelistUI()
		end)
	end

	whitelistScroll.CanvasSize = UDim2.new(0, 0, 0, math.max((#whitelist * 33) + 12, 112))
end

local function scanWorld()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then addNameUnique(p.Name, false) end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isValidTargetModel(obj) then addNameUnique(obj.Name, false) end
	end
	refreshWhitelistUI()
	statusLabel.Text = "Found " .. tostring(#whitelist) .. " targets in map"
end

local function addTypedTarget()
	local raw = string.gsub(targetInput.Text, "^%s*(.-)%s*$", "%1")
	if raw == "" then
		statusLabel.Text = "Enter a name before clicking + ADD"
		return
	end

	local query = string.lower(raw)
	local matched = raw

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and (string.find(string.lower(p.Name), query, 1, true) or string.find(string.lower(p.DisplayName), query, 1, true)) then
			matched = p.Name
			break
		end
	end

	if matched == raw then
		for _, obj in ipairs(workspace:GetDescendants()) do
			if isValidTargetModel(obj) and string.find(string.lower(obj.Name), query, 1, true) then
				matched = obj.Name
				break
			end
		end
	end

	addNameUnique(matched, true)
	targetInput.Text = ""
	refreshWhitelistUI()
	statusLabel.Text = "Added & selected: " .. matched
end

addButton.MouseButton1Click:Connect(addTypedTarget)
scanButton.MouseButton1Click:Connect(scanWorld)
targetInput.FocusLost:Connect(function(enter)
	if enter then addTypedTarget() end
end)

local function findCharacterByName(targetName)
	local p = Players:FindFirstChild(targetName)
	if p and p.Character then return p.Character end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == targetName and isValidTargetModel(obj) then return obj end
	end
	return nil
end

local function pickActiveTarget(myHRP)
	local bestChar, shortest = nil, math.huge
	for name, checked in pairs(selectedTargets) do
		if checked then
			local char = findCharacterByName(name)
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hum and hum.Health > 0 and hrp then
				local dist = (hrp.Position - myHRP.Position).Magnitude
				if dist < shortest then
					shortest, bestChar = dist, char
				end
			end
		end
	end
	return bestChar
end

-- 4. FOLLOW BEHIND LOOP
local isFollowing = false
local followConn = nil
local currentTarget = nil

local function stopFollowing()
	isFollowing = false
	currentTarget = nil
	if followConn then
		followConn:Disconnect()
		followConn = nil
	end
	statusLabel.Text = "Stopped following"
	actionButton.Text = "FOLLOW BEHIND (F)"
	actionButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end

local function startFollowing()
	local myChar, myHRP, myHum = getMyParts()
	if not (myChar and myHRP and myHum and myHum.Health > 0) then
		statusLabel.Text = "Your character is not ready!"
		return
	end

	local targetChar = pickActiveTarget(myHRP)
	if not targetChar then
		statusLabel.Text = "Select a target in Whitelist first!"
		return
	end

	isFollowing = true
	currentTarget = targetChar
	statusLabel.Text = "Following: " .. targetChar.Name
	actionButton.Text = "STOP FOLLOWING (F)"
	actionButton.BackgroundColor3 = Color3.fromRGB(40, 175, 95)

	followConn = RunService.Heartbeat:Connect(function()
		if not isFollowing then
			stopFollowing()
			return
		end

		local _, curMyHRP, curMyHum = getMyParts()
		if not (curMyHRP and curMyHum and curMyHum.Health > 0) then
			stopFollowing()
			return
		end

		local tHRP = currentTarget and currentTarget:FindFirstChild("HumanoidRootPart")
		local tHum = currentTarget and currentTarget:FindFirstChildOfClass("Humanoid")

		if not (currentTarget and currentTarget.Parent and tHRP and tHum and tHum.Health > 0) then
			local nextTarget = pickActiveTarget(curMyHRP)
			if nextTarget then
				currentTarget = nextTarget
				statusLabel.Text = "Switched to: " .. nextTarget.Name
				tHRP = nextTarget:FindFirstChild("HumanoidRootPart")
				tHum = nextTarget:FindFirstChildOfClass("Humanoid")
			else
				stopFollowing()
				statusLabel.Text = "Target defeated / no valid target left"
				return
			end
		end

		if tHRP and tHum and tHum.Health > 0 then
			curMyHRP.AssemblyLinearVelocity = Vector3.zero
			curMyHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, DISTANCE_BEHIND)
		end
	end)
end

actionButton.MouseButton1Click:Connect(function()
	if isFollowing then stopFollowing() else startFollowing() end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.F then
		if isFollowing then stopFollowing() else startFollowing() end
	end
end)

task.defer(scanWorld)
