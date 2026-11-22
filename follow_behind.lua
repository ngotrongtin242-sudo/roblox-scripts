-- Credit: hedgehog
-- File: follow_behind.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "Follow Behind - hedgehog",
	Subtitle = "Single Username Lock",
	LogoID = "82795327169782",
	LoadingEnabled = true,
	LoadingTitle = "Luna Interface Suite",
	LoadingSubtitle = "Credit: hedgehog",

	ConfigSettings = {
		RootFolder = nil,
		ConfigFolder = "HedgehogFollowHub"
	},

	KeySystem = true,
	KeySettings = {
		Title = "Hedgehog Key System",
		Subtitle = "License Verification",
		Note = "Enter a valid key to unlock Follow Behind (hedgehog). Default keys: HEDGEHOG-KEY or 1234.",
		SaveInRoot = false,
		SaveKey = true,
		Key = {"HEDGEHOG-KEY", "1234"},
		SecondAction = {
			Enabled = true,
			Type = "Link",
			Parameter = "https://github.com/ngotrongtin242-sudo/roblox-scripts"
		}
	}
})

local MainTab = Window:CreateTab({
	Name = "Follow",
	Icon = "directions_run",
	ImageSource = "Material",
	ShowTitle = true
})

local WhitelistTab = Window:CreateTab({
	Name = "Whitelist",
	Icon = "person_pin",
	ImageSource = "Material",
	ShowTitle = true
})

-- STATE (SINGLE TARGET ONLY)
local DISTANCE_BEHIND = 3.5
local isFollowing = false
local isUpdatingToggle = false
local isUpdatingDropdown = false
local followConn = nil

local usernameList = {}
local singleSelectedTarget = nil -- Only ONE target username at a time

local followToggle = nil
local targetDropdown = nil
local activeTargetLabel = nil
local playerButtons = {}

local function getMyParts()
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function isValidCharacterModel(model)
	return typeof(model) == "Instance"
		and model:IsA("Model")
		and model ~= player.Character
		and model:FindFirstChildOfClass("Humanoid") ~= nil
		and model:FindFirstChild("HumanoidRootPart") ~= nil
end

local function addUsername(rawName, setAsSingleTarget)
	if typeof(rawName) ~= "string" then
		return false
	end
	local trimmed = string.gsub(rawName, "^%s*(.-)%s*$", "%1")
	if trimmed == "" or trimmed == player.Name or trimmed == "None" then
		return false
	end

	if not table.find(usernameList, trimmed) then
		table.insert(usernameList, trimmed)
	end

	if setAsSingleTarget then
		singleSelectedTarget = trimmed
	end
	return true
end

local function updatePlayerButtonLabels()
	for uName, btn in pairs(playerButtons) do
		if btn then
			pcall(function()
				if singleSelectedTarget == uName then
					btn:Set("[SELECTED] " .. uName)
				else
					btn:Set("Select Player: " .. uName)
				end
			end)
		end
	end
end

local function refreshStatusUI()
	if activeTargetLabel then
		local currentText = singleSelectedTarget and ("Locked Target (1 Player): " .. singleSelectedTarget) or "Locked Target (1 Player): None"
		pcall(function()
			activeTargetLabel:Set(currentText)
		end)
	end
	updatePlayerButtonLabels()
end

local function syncSingleDropdown()
	refreshStatusUI()
	if not targetDropdown then
		return
	end

	local options = {}
	for _, uName in ipairs(usernameList) do
		table.insert(options, uName)
	end
	if #options == 0 then
		table.insert(options, "None")
	end

	local selectedOption = (singleSelectedTarget and table.find(options, singleSelectedTarget)) and {singleSelectedTarget} or {options[1]}

	isUpdatingDropdown = true
	pcall(function()
		targetDropdown:Refresh(options, selectedOption)
	end)
	isUpdatingDropdown = false
end

local function selectSingleUsername(uName, notify)
	if typeof(uName) ~= "string" or uName == "" or uName == "None" or uName == player.Name then
		return
	end

	addUsername(uName, true)
	singleSelectedTarget = uName
	syncSingleDropdown()

	if notify then
		Luna:Notification({
			Title = "Single Target Locked",
			Icon = "person",
			ImageSource = "Material",
			Content = "Now targeting ONLY player: " .. singleSelectedTarget
		})
	end
end

local function rebuildPlayerQuickButtons()
	-- Remove previous quick buttons if any
	for uName, btn in pairs(playerButtons) do
		if btn and btn.Destroy then
			pcall(function()
				btn:Destroy()
			end)
		end
		playerButtons[uName] = nil
	end

	-- Create one button per player Username in server (excluding self)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and typeof(p.Name) == "string" and p.Name ~= "" then
			addUsername(p.Name, false)
			local uName = p.Name
			local labelText = (singleSelectedTarget == uName) and ("[SELECTED] " .. uName) or ("Select Player: " .. uName)

			playerButtons[uName] = WhitelistTab:CreateButton({
				Name = labelText,
				Description = "Target ONLY " .. uName .. " (DisplayName: " .. p.DisplayName .. ")",
				Callback = function()
					selectSingleUsername(uName, true)
				end
			})
		end
	end

	-- Keep singleSelectedTarget only if still present or manually added
	if singleSelectedTarget and not table.find(usernameList, singleSelectedTarget) then
		table.insert(usernameList, singleSelectedTarget)
	end

	syncSingleDropdown()
end

local function resolvePlayerUsername(rawText)
	local cleaned = string.gsub(rawText or "", "^%s*(.-)%s*$", "%1")
	if cleaned == "" then
		return nil
	end
	local query = string.lower(cleaned)

	-- Exact Username match first
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and string.lower(p.Name) == query then
			return p.Name
		end
	end

	-- Partial Username match
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and string.find(string.lower(p.Name), query, 1, true) then
			return p.Name
		end
	end

	-- DisplayName match -> resolves to real Username
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and string.find(string.lower(p.DisplayName), query, 1, true) then
			return p.Name
		end
	end

	return cleaned
end

local function getSingleTargetCharacter()
	if not singleSelectedTarget or singleSelectedTarget == "" or singleSelectedTarget == "None" then
		return nil
	end

	local targetPlayer = Players:FindFirstChild(singleSelectedTarget)
	if targetPlayer and targetPlayer.Character then
		return targetPlayer.Character
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == singleSelectedTarget and p.Character then
			return p.Character
		end
	end

	local workspaceModel = workspace:FindFirstChild(singleSelectedTarget)
	if isValidCharacterModel(workspaceModel) then
		return workspaceModel
	end

	return nil
end

local function setToggleSilently(state)
	if followToggle and not isUpdatingToggle then
		isUpdatingToggle = true
		pcall(function()
			followToggle:Set(state)
		end)
		isUpdatingToggle = false
	end
end

local function stopFollowing(syncUI)
	isFollowing = false
	if followConn then
		followConn:Disconnect()
		followConn = nil
	end
	if syncUI then
		setToggleSilently(false)
	end
end

local function startFollowing()
	local myChar, myHRP, myHum = getMyParts()
	if not (myChar and myHRP and myHum and myHum.Health > 0) then
		Luna:Notification({
			Title = "Follow Behind",
			Icon = "error_outline",
			ImageSource = "Material",
			Content = "Your character is not ready yet."
		})
		stopFollowing(true)
		return
	end

	if not singleSelectedTarget then
		Luna:Notification({
			Title = "No Player Selected",
			Icon = "warning",
			ImageSource = "Material",
			Content = "Select 1 player Username first before activating."
		})
		stopFollowing(true)
		return
	end

	local targetChar = getSingleTargetCharacter()
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")

	if not (targetChar and targetHRP and targetHRP.Parent and targetHum and targetHum.Health > 0) then
		Luna:Notification({
			Title = "Target Unavailable",
			Icon = "info",
			ImageSource = "Material",
			Content = "Player '" .. tostring(singleSelectedTarget) .. "' is not spawned or active right now."
		})
		stopFollowing(true)
		return
	end

	stopFollowing(false)
	isFollowing = true
	setToggleSilently(true)

	-- Strictly locks onto ONLY the single selected Username (no switching to other players)
	followConn = RunService.Heartbeat:Connect(function()
		if not isFollowing then
			return
		end

		local ok = pcall(function()
			local _, curMyHRP, curMyHum = getMyParts()
			if not (curMyHRP and curMyHRP.Parent and curMyHum and curMyHum.Health > 0) then
				stopFollowing(true)
				return
			end

			local lockedChar = getSingleTargetCharacter()
			local tHRP = lockedChar and lockedChar:FindFirstChild("HumanoidRootPart")
			local tHum = lockedChar and lockedChar:FindFirstChildOfClass("Humanoid")

			if not (lockedChar and lockedChar.Parent and tHRP and tHRP.Parent and tHum and tHum.Health > 0) then
				stopFollowing(true)
				Luna:Notification({
					Title = "Target Lost",
					Icon = "info",
					ImageSource = "Material",
					Content = "Stopped following '" .. tostring(singleSelectedTarget) .. "' (left or defeated)."
				})
				return
			end

			curMyHRP.AssemblyLinearVelocity = Vector3.zero
			curMyHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, DISTANCE_BEHIND)
		end)

		if not ok then
			stopFollowing(true)
		end
	end)
end

local function toggleFollowState(desiredState)
	if isUpdatingToggle then
		return
	end
	if desiredState == nil then
		desiredState = not isFollowing
	end

	if desiredState then
		startFollowing()
	else
		stopFollowing(true)
	end
end

-- MAIN TAB
MainTab:CreateSection("Follow Controls - Credit: hedgehog")

followToggle = MainTab:CreateToggle({
	Name = "Follow Behind Single Target",
	Description = "Follow strictly behind the single selected player Username without auto-attacking.",
	CurrentValue = false,
	Callback = function(Value)
		if isUpdatingToggle then
			return
		end
		toggleFollowState(Value)
	end
}, "FollowBehindToggle")

MainTab:CreateBind({
	Name = "Toggle Follow Keybind",
	Description = "Press key (default F) to toggle following behind selected player.",
	CurrentBind = "F",
	HoldToInteract = false,
	Callback = function(BindState)
		if BindState then
			toggleFollowState(not isFollowing)
		end
	end
}, "FollowBehindBind")

MainTab:CreateSlider({
	Name = "Distance Behind",
	Description = "Distance behind selected player HumanoidRootPart.",
	Range = {1, 15},
	Increment = 0.5,
	CurrentValue = DISTANCE_BEHIND,
	Callback = function(Value)
		DISTANCE_BEHIND = Value
	end
}, "DistanceBehindSlider")

MainTab:CreateLabel({
	Text = "Credit: hedgehog | Single player lock | No auto-attack or skills.",
	Style = 2
})

-- WHITELIST / SINGLE PLAYER SELECT TAB
WhitelistTab:CreateSection("Select Single Player Username")

activeTargetLabel = WhitelistTab:CreateLabel({
	Text = "Locked Target (1 Player): None",
	Style = 2
})

local typedUsername = ""

WhitelistTab:CreateInput({
	Name = "Enter Player Username",
	Description = "Type a Username and press Enter or click Lock Typed Username.",
	PlaceholderText = "Type exact or partial Username...",
	CurrentValue = "",
	Numeric = false,
	MaxCharacters = nil,
	Enter = true,
	Callback = function(Text)
		typedUsername = Text
	end
}, "SingleUsernameInput")

WhitelistTab:CreateButton({
	Name = "Lock Typed Username (Single)",
	Description = "Set ONLY this typed Username as the active target.",
	Callback = function()
		local resolved = resolvePlayerUsername(typedUsername)
		if not resolved then
			Luna:Notification({
				Title = "Username Required",
				Icon = "warning",
				ImageSource = "Material",
				Content = "Enter a player Username first."
			})
			return
		end
		selectSingleUsername(resolved, true)
	end
})

targetDropdown = WhitelistTab:CreateDropdown({
	Name = "Username List (Single Select)",
	Description = "Choose 1 player Username from server list.",
	Options = {"None"},
	CurrentOption = {"None"},
	MultipleOptions = false,
	SpecialType = nil,
	Callback = function(Selected)
		if isUpdatingDropdown then
			return
		end
		local chosenName = typeof(Selected) == "table" and Selected[1] or Selected
		if typeof(chosenName) == "string" and chosenName ~= "" and chosenName ~= "None" then
			selectSingleUsername(chosenName, true)
		end
	end
}, "SingleUsernameDropdown")

WhitelistTab:CreateButton({
	Name = "Reload Server Player Usernames",
	Description = "Refresh current player Usernames in the server.",
	Callback = function()
		rebuildPlayerQuickButtons()
		Luna:Notification({
			Title = "Usernames Refreshed",
			Icon = "refresh",
			ImageSource = "Material",
			Content = "Updated player Usernames: " .. tostring(#usernameList)
		})
	end
})

WhitelistTab:CreateButton({
	Name = "Clear Selected Target",
	Description = "Unselect current target and stop following.",
	Callback = function()
		singleSelectedTarget = nil
		stopFollowing(true)
		syncSingleDropdown()
		Luna:Notification({
			Title = "Target Cleared",
			Icon = "clear",
			ImageSource = "Material",
			Content = "Cleared selected player target."
		})
	end
})

local ThemeTab = Window:CreateTab({
	Name = "Theme",
	Icon = "palette",
	ImageSource = "Material",
	ShowTitle = true
})
ThemeTab:BuildThemeSection()

local ConfigTab = Window:CreateTab({
	Name = "Config",
	Icon = "settings",
	ImageSource = "Material",
	ShowTitle = true
})
ConfigTab:BuildConfigSection()

Players.PlayerAdded:Connect(function(newPlayer)
	if newPlayer ~= player and typeof(newPlayer.Name) == "string" and newPlayer.Name ~= "" then
		addUsername(newPlayer.Name, false)
		syncSingleDropdown()
	end
end)

Players.PlayerRemoving:Connect(function(leftPlayer)
	if leftPlayer and typeof(leftPlayer.Name) == "string" then
		local idx = table.find(usernameList, leftPlayer.Name)
		if idx then
			table.remove(usernameList, idx)
		end
		if singleSelectedTarget == leftPlayer.Name then
			singleSelectedTarget = nil
			stopFollowing(true)
		end
		syncSingleDropdown()
	end
end)

task.defer(function()
	rebuildPlayerQuickButtons()
	-- If there is exactly 1 other player in server, pre-lock that single player's Username
	if #usernameList == 1 and not singleSelectedTarget then
		selectSingleUsername(usernameList[1], false)
	end
end)
