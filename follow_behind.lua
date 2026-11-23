-- Credit: hedgehog
-- Repository: https://github.com/ngotrongtin242-sudo/roblox-scripts/blob/main/follow_behind.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local DISCORD_INVITE = "https://discord.gg/v3RG6hZFA"

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()
if not Luna then
	warn("[hedgehog] Luna Interface Suite failed to load.")
	return
end

local Window = Luna:CreateWindow({
	Name = "Follow Behind - hedgehog",
	Subtitle = "Single Target & Outline ESP",
	LogoID = "82795327169782",
	LoadingEnabled = true,
	LoadingTitle = "Luna Interface Suite",
	LoadingSubtitle = "Credit: hedgehog",

	ConfigSettings = {
		RootFolder = nil,
		ConfigFolder = "HedgehogFollowV3"
	},

	KeySystem = true,
	KeySettings = {
		Title = "Hedgehog Key System",
		Subtitle = "Get Key",
		Note = "Get your key at: https://discord.gg/v3RG6hZFA (Keys: HEDGEHOG-KEY, 1234)",
		SaveInRoot = false,
		SaveKey = true,
		Key = {"HEDGEHOG-KEY", "1234"},
		SecondAction = {
			Enabled = true,
			Type = "Link",
			Parameter = DISCORD_INVITE
		}
	}
})

local MainTab = Window:CreateTab({
	Name = "Follow",
	Icon = "directions_run",
	ImageSource = "Material",
	ShowTitle = true
})

local ESPTab = Window:CreateTab({
	Name = "ESP",
	Icon = "visibility",
	ImageSource = "Material",
	ShowTitle = true
})

local WhitelistTab = Window:CreateTab({
	Name = "Whitelist",
	Icon = "person_pin",
	ImageSource = "Material",
	ShowTitle = true
})

-- STATE
local DISTANCE_BEHIND = 3.5
local isFollowing = false
local isSyncingToggle = false
local isSyncingDropdown = false
local followConn = nil

local ESP_ENABLED = false
local ESP_ONLY_TARGET = false
local ESP_TARGET_COLOR = Color3.fromRGB(255, 65, 65)
local ESP_ALL_COLOR = Color3.fromRGB(86, 171, 128)
local espHighlights = {}

local usernameList = {}
local singleSelectedTarget = nil
local typedUsername = ""

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

-- OUTLINE ESP
local function removePlayerESP(targetPlayer)
	local hl = espHighlights[targetPlayer]
	if hl then
		pcall(function()
			hl:Destroy()
		end)
		espHighlights[targetPlayer] = nil
	end
end

local function clearAllESP()
	for p, _ in pairs(espHighlights) do
		removePlayerESP(p)
	end
end

local function updateAllESP()
	if not ESP_ENABLED then
		clearAllESP()
		return
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local isTarget = (singleSelectedTarget ~= nil and p.Name == singleSelectedTarget)
			local shouldShow = (not ESP_ONLY_TARGET) or isTarget
			local char = p.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if shouldShow and char and hum and hum.Health > 0 then
				local hl = espHighlights[p]
				if not hl or hl.Parent ~= char then
					removePlayerESP(p)
					hl = Instance.new("Highlight")
					hl.Name = "Hedgehog_Outline_ESP"
					hl.Adornee = char
					hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
					hl.FillTransparency = 1
					hl.OutlineTransparency = 0
					hl.Parent = char
					espHighlights[p] = hl
				end
				hl.OutlineColor = isTarget and ESP_TARGET_COLOR or ESP_ALL_COLOR
			else
				removePlayerESP(p)
			end
		end
	end
end

-- SINGLE TARGET MANAGEMENT
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
		if btn and btn.Set then
			pcall(function()
				btn:Set((singleSelectedTarget == uName) and ("[SELECTED] " .. uName) or ("Select Player: " .. uName))
			end)
		end
	end
end

local function refreshStatusUI()
	if activeTargetLabel and activeTargetLabel.Set then
		local statusTag = isFollowing and " [FOLLOWING BEHIND]" or ""
		local text = singleSelectedTarget
			and ("Locked Target (1 Player): " .. singleSelectedTarget .. statusTag)
			or "Locked Target (1 Player): None"
		pcall(function()
			activeTargetLabel:Set(text)
		end)
	end
	updatePlayerButtonLabels()
end

local function syncSingleDropdown()
	refreshStatusUI()
	if not targetDropdown or not targetDropdown.Refresh then
		return
	end

	local options = {}
	for _, uName in ipairs(usernameList) do
		table.insert(options, uName)
	end
	if #options == 0 then
		table.insert(options, "None")
	end

	local chosen = (singleSelectedTarget and table.find(options, singleSelectedTarget)) and {singleSelectedTarget} or {options[1]}

	isSyncingDropdown = true
	pcall(function()
		targetDropdown:Refresh(options, chosen)
	end)
	isSyncingDropdown = false
end

local function selectSingleUsername(uName, notify)
	if typeof(uName) ~= "string" or uName == "" or uName == "None" or uName == player.Name then
		return
	end
	addUsername(uName, true)
	singleSelectedTarget = uName
	syncSingleDropdown()

	if notify then
		pcall(function()
			Luna:Notification({
				Title = "Single Target Locked",
				Icon = "person",
				ImageSource = "Material",
				Content = "Now targeting ONLY player: " .. singleSelectedTarget
			})
		end)
	end
end

local function rebuildPlayerQuickButtons()
	for uName, btn in pairs(playerButtons) do
		if btn and btn.Destroy then
			pcall(function()
				btn:Destroy()
			end)
		end
		playerButtons[uName] = nil
	end

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and typeof(p.Name) == "string" and p.Name ~= "" then
			addUsername(p.Name, false)
			local uName = p.Name
			playerButtons[uName] = WhitelistTab:CreateButton({
				Name = (singleSelectedTarget == uName) and ("[SELECTED] " .. uName) or ("Select Player: " .. uName),
				Description = "Target ONLY " .. uName .. " (DisplayName: " .. p.DisplayName .. ")",
				Callback = function()
					selectSingleUsername(uName, true)
				end
			})
		end
	end

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

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and string.lower(p.Name) == query then
			return p.Name
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and string.find(string.lower(p.Name), query, 1, true) then
			return p.Name
		end
	end
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
	local p = Players:FindFirstChild(singleSelectedTarget)
	if p and p.Character then
		return p.Character
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Name == singleSelectedTarget and other.Character then
			return other.Character
		end
	end
	local wsModel = workspace:FindFirstChild(singleSelectedTarget)
	if isValidCharacterModel(wsModel) then
		return wsModel
	end
	return nil
end

local function setToggleSilently(state)
	if followToggle and followToggle.Set and not isSyncingToggle then
		isSyncingToggle = true
		pcall(function()
			followToggle:Set(state)
		end)
		isSyncingToggle = false
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
	refreshStatusUI()
end

local function startFollowing()
	local myChar, myHRP, myHum = getMyParts()
	if not (myChar and myHRP and myHum and myHum.Health > 0) then
		stopFollowing(true)
		return
	end
	if not singleSelectedTarget then
		stopFollowing(true)
		return
	end

	local targetChar = getSingleTargetCharacter()
	local targetHRP = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	local targetHum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
	if not (targetChar and targetHRP and targetHRP.Parent and targetHum and targetHum.Health > 0) then
		stopFollowing(true)
		return
	end

	stopFollowing(false)
	isFollowing = true
	setToggleSilently(true)
	refreshStatusUI()

	followConn = RunService.Heartbeat:Connect(function()
		if not isFollowing then
			return
		end
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
			return
		end

		if curMyHum.Sit then
			curMyHum.Sit = false
		end
		if curMyHum.PlatformStand then
			curMyHum.PlatformStand = false
		end

		curMyHRP.AssemblyLinearVelocity = Vector3.zero
		curMyHRP.AssemblyAngularVelocity = Vector3.zero
		curMyHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, DISTANCE_BEHIND)
	end)
end

local function toggleFollowState(desiredState)
	if isSyncingToggle then
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
		if isSyncingToggle then
			return
		end
		toggleFollowState(Value)
	end
})

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
})

MainTab:CreateSlider({
	Name = "Distance Behind",
	Description = "Distance behind selected player HumanoidRootPart.",
	Range = {1, 15},
	Increment = 0.5,
	CurrentValue = DISTANCE_BEHIND,
	Callback = function(Value)
		DISTANCE_BEHIND = Value
	end
})

MainTab:CreateLabel({
	Text = "Credit: hedgehog | Single player lock | No auto-attack or skills.",
	Style = 2
})

-- ESP TAB (OUTLINE ONLY)
ESPTab:CreateSection("Outline ESP Controls")

ESPTab:CreateToggle({
	Name = "Enable Outline ESP",
	Description = "Show character outline border only through walls.",
	CurrentValue = ESP_ENABLED,
	Callback = function(Value)
		ESP_ENABLED = Value
		if not ESP_ENABLED then
			clearAllESP()
		end
	end
})

ESPTab:CreateToggle({
	Name = "Outline Locked Target Only",
	Description = "Show outline border only on the single selected target Username.",
	CurrentValue = ESP_ONLY_TARGET,
	Callback = function(Value)
		ESP_ONLY_TARGET = Value
	end
})

ESPTab:CreateColorPicker({
	Name = "Locked Target Outline Color",
	Color = ESP_TARGET_COLOR,
	Callback = function(Value)
		ESP_TARGET_COLOR = Value
	end
})

ESPTab:CreateColorPicker({
	Name = "Other Players Outline Color",
	Color = ESP_ALL_COLOR,
	Callback = function(Value)
		ESP_ALL_COLOR = Value
	end
})

-- WHITELIST / SINGLE PLAYER SELECT TAB
WhitelistTab:CreateSection("Select Single Player Username")

activeTargetLabel = WhitelistTab:CreateLabel({
	Text = "Locked Target (1 Player): None",
	Style = 2
})

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
})

WhitelistTab:CreateButton({
	Name = "Lock Typed Username (Single)",
	Description = "Set ONLY this typed Username as the active target.",
	Callback = function()
		local resolved = resolvePlayerUsername(typedUsername)
		if resolved then
			selectSingleUsername(resolved, true)
		end
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
		if isSyncingDropdown then
			return
		end
		local chosenName = typeof(Selected) == "table" and Selected[1] or Selected
		if typeof(chosenName) == "string" and chosenName ~= "" and chosenName ~= "None" then
			selectSingleUsername(chosenName, true)
		end
	end
})

WhitelistTab:CreateButton({
	Name = "Reload Server Player Usernames",
	Description = "Refresh current player Usernames in the server.",
	Callback = function()
		rebuildPlayerQuickButtons()
	end
})

WhitelistTab:CreateButton({
	Name = "Clear Selected Target",
	Description = "Unselect current target and stop following.",
	Callback = function()
		singleSelectedTarget = nil
		stopFollowing(true)
		syncSingleDropdown()
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

task.spawn(function()
	while task.wait(0.15) do
		if ESP_ENABLED then
			pcall(updateAllESP)
		end
	end
end)

Players.PlayerAdded:Connect(function(newPlayer)
	if newPlayer ~= player and typeof(newPlayer.Name) == "string" and newPlayer.Name ~= "" then
		addUsername(newPlayer.Name, false)
		syncSingleDropdown()
	end
end)

Players.PlayerRemoving:Connect(function(leftPlayer)
	if leftPlayer then
		removePlayerESP(leftPlayer)
		if typeof(leftPlayer.Name) == "string" then
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
	end
end)

task.delay(1, function()
	rebuildPlayerQuickButtons()
	if #usernameList == 1 and not singleSelectedTarget then
		selectSingleUsername(usernameList[1], false)
	end
end)
