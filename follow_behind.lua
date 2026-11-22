-- Credit: hedgehog
-- File: follow_behind.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local Luna = loadstring(game:HttpGet("https://raw.githubusercontent.com/Nebula-Softworks/Luna-Interface-Suite/refs/heads/master/source.lua", true))()

local Window = Luna:CreateWindow({
	Name = "Follow Behind - hedgehog",
	Subtitle = "Whitelist & Position Lock",
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
	Icon = "group_add",
	ImageSource = "Material",
	ShowTitle = true
})

-- STATE & WHITELIST DATA
local DISTANCE_BEHIND = 3.5
local isFollowing = false
local followConn = nil
local currentTarget = nil

local whitelist = {}
local selectedTargets = {}
local followToggle = nil
local targetDropdown = nil

local function getMyParts()
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function isValidTargetModel(obj)
	return obj:IsA("Model")
		and obj ~= player.Character
		and obj:FindFirstChildOfClass("Humanoid") ~= nil
		and obj:FindFirstChild("HumanoidRootPart") ~= nil
end

local function addNameUnique(nameStr, autoSelect)
	if not nameStr or nameStr == "" or nameStr == player.Name then
		return false
	end
	for _, existing in ipairs(whitelist) do
		if existing == nameStr then
			if autoSelect then
				selectedTargets[existing] = true
			end
			return true
		end
	end
	table.insert(whitelist, nameStr)
	if autoSelect then
		selectedTargets[nameStr] = true
	end
	return true
end

local function getSelectedList()
	local chosen = {}
	for name, isChecked in pairs(selectedTargets) do
		if isChecked then
			table.insert(chosen, name)
		end
	end
	return chosen
end

local function syncDropdown()
	if not targetDropdown then
		return
	end
	local optionsToShow = #whitelist > 0 and whitelist or {"None"}
	local currentSelected = getSelectedList()
	targetDropdown:Refresh(optionsToShow, #currentSelected > 0 and currentSelected or {optionsToShow[1]})
end

local function scanWorld()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			addNameUnique(p.Name, false)
		end
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isValidTargetModel(obj) then
			addNameUnique(obj.Name, false)
		end
	end
	syncDropdown()
	Luna:Notification({
		Title = "Whitelist Scan",
		Icon = "radar",
		ImageSource = "Material",
		Content = "Scanned map: " .. tostring(#whitelist) .. " valid targets available."
	})
end

local function resolveTargetName(rawText)
	local cleaned = string.gsub(rawText or "", "^%s*(.-)%s*$", "%1")
	if cleaned == "" then
		return nil
	end
	local query = string.lower(cleaned)

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			if string.find(string.lower(p.Name), query, 1, true)
				or string.find(string.lower(p.DisplayName), query, 1, true) then
				return p.Name
			end
		end
	end

	for _, obj in ipairs(workspace:GetDescendants()) do
		if isValidTargetModel(obj) and string.find(string.lower(obj.Name), query, 1, true) then
			return obj.Name
		end
	end

	return cleaned
end

local function findCharacterByName(targetName)
	local p = Players:FindFirstChild(targetName)
	if p and p.Character then
		return p.Character
	end
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj.Name == targetName and isValidTargetModel(obj) then
			return obj
		end
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

local function stopFollowing()
	isFollowing = false
	currentTarget = nil
	if followConn then
		followConn:Disconnect()
		followConn = nil
	end
	if followToggle then
		followToggle:Set(false)
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
		stopFollowing()
		return
	end

	local targetChar = pickActiveTarget(myHRP)
	if not targetChar then
		Luna:Notification({
			Title = "Whitelist Required",
			Icon = "warning",
			ImageSource = "Material",
			Content = "Select at least one valid target in Whitelist first."
		})
		stopFollowing()
		return
	end

	isFollowing = true
	currentTarget = targetChar

	if followConn then
		followConn:Disconnect()
		followConn = nil
	end

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
				tHRP = nextTarget:FindFirstChild("HumanoidRootPart")
				tHum = nextTarget:FindFirstChildOfClass("Humanoid")
			else
				stopFollowing()
				Luna:Notification({
					Title = "Follow Behind",
					Icon = "info",
					ImageSource = "Material",
					Content = "No active whitelisted targets remaining."
				})
				return
			end
		end

		if tHRP and tHum and tHum.Health > 0 then
			curMyHRP.AssemblyLinearVelocity = Vector3.zero
			curMyHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, DISTANCE_BEHIND)
		end
	end)
end

local function toggleFollowState(desiredState)
	if desiredState == nil then
		desiredState = not isFollowing
	end

	if desiredState then
		if not isFollowing then
			startFollowing()
		end
	else
		if isFollowing then
			stopFollowing()
		end
	end
end

-- MAIN TAB CONTROLS
MainTab:CreateSection("Follow Controls - Credit: hedgehog")

followToggle = MainTab:CreateToggle({
	Name = "Follow Behind Target",
	Description = "Lock position behind selected whitelisted target without auto-attacking.",
	CurrentValue = false,
	Callback = function(Value)
		toggleFollowState(Value)
	end
}, "FollowBehindToggle")

MainTab:CreateBind({
	Name = "Toggle Follow Keybind",
	Description = "Press key (default F) to toggle following behind target.",
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
	Description = "Offset distance behind target HumanoidRootPart.",
	Range = {1, 15},
	Increment = 0.5,
	CurrentValue = DISTANCE_BEHIND,
	Callback = function(Value)
		DISTANCE_BEHIND = Value
	end
}, "DistanceBehindSlider")

MainTab:CreateLabel({
	Text = "Credit: hedgehog | No auto-attack or skill execution enabled.",
	Style = 2
})

-- WHITELIST TAB CONTROLS
WhitelistTab:CreateSection("Whitelist Management")

local pendingName = ""

WhitelistTab:CreateInput({
	Name = "Target Name",
	Description = "Enter player or NPC name (partial match supported).",
	PlaceholderText = "Type name...",
	CurrentValue = "",
	Numeric = false,
	MaxCharacters = nil,
	Enter = true,
	Callback = function(Text)
		pendingName = Text
		local resolved = resolveTargetName(Text)
		if resolved and addNameUnique(resolved, true) then
			syncDropdown()
			Luna:Notification({
				Title = "Whitelist Updated",
				Icon = "check_circle",
				ImageSource = "Material",
				Content = "Added and selected: " .. resolved
			})
		end
	end
}, "WhitelistInput")

WhitelistTab:CreateButton({
	Name = "Add Typed Target",
	Description = "Add current input name to Whitelist and select it.",
	Callback = function()
		local resolved = resolveTargetName(pendingName)
		if not resolved then
			Luna:Notification({
				Title = "Whitelist",
				Icon = "warning",
				ImageSource = "Material",
				Content = "Please enter a target name first."
			})
			return
		end
		if addNameUnique(resolved, true) then
			syncDropdown()
			Luna:Notification({
				Title = "Whitelist Updated",
				Icon = "check_circle",
				ImageSource = "Material",
				Content = "Added and selected: " .. resolved
			})
		end
	end
})

WhitelistTab:CreateButton({
	Name = "Scan Players & NPCs",
	Description = "Scan current map for valid characters and add them to Whitelist.",
	Callback = function()
		scanWorld()
	end
})

targetDropdown = WhitelistTab:CreateDropdown({
	Name = "Active Whitelisted Targets",
	Description = "Select one or multiple targets from Whitelist.",
	Options = {"None"},
	CurrentOption = {"None"},
	MultipleOptions = true,
	SpecialType = nil,
	Callback = function(Options)
		selectedTargets = {}
		if typeof(Options) == "table" then
			for _, item in ipairs(Options) do
				if item ~= "None" then
					selectedTargets[item] = true
				end
			end
		elseif typeof(Options) == "string" and Options ~= "None" then
			selectedTargets[Options] = true
		end
	end
}, "WhitelistDropdown")

WhitelistTab:CreateButton({
	Name = "Clear Whitelist",
	Description = "Remove all entries and selections from Whitelist.",
	Callback = function()
		table.clear(whitelist)
		table.clear(selectedTargets)
		syncDropdown()
		Luna:Notification({
			Title = "Whitelist Cleared",
			Icon = "delete_sweep",
			ImageSource = "Material",
			Content = "All whitelisted targets have been cleared."
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

task.defer(scanWorld)
