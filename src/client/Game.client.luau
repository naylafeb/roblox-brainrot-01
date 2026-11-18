-- Brainrot Bay client: the whole HUD is built here in code, over the 3D
-- world. Money and income up top, your collection on the right, the wave
-- warning across the top, rebirth and lock buttons at the bottom, and the
-- how-to-play panel at the lower left. The server pushes state once a second.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RebirthEvent = Remotes:WaitForChild("Rebirth")
local LockBaseEvent = Remotes:WaitForChild("LockBase")
local GameStateEvent = Remotes:WaitForChild("GameState")
local NotifyEvent = Remotes:WaitForChild("Notify")

-- Format 1234567 as $1,234,567.
local function formatMoney(amount)
	local text = tostring(math.floor(amount))
	local result = ""
	while #text > 3 do
		result = "," .. text:sub(-3) .. result
		text = text:sub(1, -4)
	end
	return "$" .. text .. result
end

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.TextSize = textSize
	label.Font = Enum.Font.SourceSansBold
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Parent = parent
	return label
end

local function makePanel(parent, name, size, position, color)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.Position = position
	panel.BackgroundColor3 = color or Color3.fromRGB(20, 20, 30)
	panel.BackgroundTransparency = 0.35
	panel.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = panel
	panel.Parent = parent
	return panel
end

-- Top centre: money, income, rebirths. Kept clear of the top-left corner,
-- where Roblox's own menu buttons sit.
local topPanel = makePanel(gui, "TopPanel", UDim2.new(0, 340, 0, 96),
	UDim2.new(0.5, -170, 0, 12))
local moneyLabel = makeLabel(topPanel, "MoneyLabel", "$0",
	UDim2.new(1, 0, 0, 46), UDim2.new(0, 0, 0, 4), 34,
	Color3.fromRGB(255, 215, 80))
local incomeLabel = makeLabel(topPanel, "IncomeLabel", "$0/s",
	UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 48), 18,
	Color3.fromRGB(120, 255, 140))
local rebirthLabel = makeLabel(topPanel, "RebirthLabel", "Rebirths: 0 (x1.00)",
	UDim2.new(1, 0, 0, 20), UDim2.new(0, 0, 0, 70), 15,
	Color3.fromRGB(200, 220, 255))

-- Wave banner, under the money panel; hidden until a wave is near.
local wavePanel = makePanel(gui, "WavePanel", UDim2.new(0, 420, 0, 44),
	UDim2.new(0.5, -210, 0, 118), Color3.fromRGB(40, 90, 160))
wavePanel.Visible = false
local waveLabel = makeLabel(wavePanel, "WaveLabel", "",
	UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), 20,
	Color3.fromRGB(255, 255, 255))

-- Top right: collection, carried brainrot, lock status.
local statsPanel = makePanel(gui, "StatsPanel", UDim2.new(0, 240, 0, 96),
	UDim2.new(1, -252, 0, 12))
local ownedLabel = makeLabel(statsPanel, "OwnedLabel", "Brainrots: 0/6",
	UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 8), 18,
	Color3.fromRGB(255, 255, 255))
local carriedLabel = makeLabel(statsPanel, "CarriedLabel", "Carrying: -",
	UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 34), 18,
	Color3.fromRGB(255, 200, 120))
local lockLabel = makeLabel(statsPanel, "LockLabel", "Base: Unlocked",
	UDim2.new(1, -12, 0, 26), UDim2.new(0, 6, 0, 60), 18,
	Color3.fromRGB(160, 220, 255))

-- Right side: the brainrots on your base, richest first.
local collectionPanel = makePanel(gui, "CollectionPanel", UDim2.new(0, 250, 0, 220),
	UDim2.new(1, -262, 0, 120))
makeLabel(collectionPanel, "CollectionTitle", "YOUR BASE",
	UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, 6), 18,
	Color3.fromRGB(255, 215, 80))
local collectionList = Instance.new("Frame")
collectionList.Name = "CollectionList"
collectionList.Size = UDim2.new(1, -16, 1, -40)
collectionList.Position = UDim2.new(0, 8, 0, 34)
collectionList.BackgroundTransparency = 1
collectionList.Parent = collectionPanel

-- Bottom centre: rebirth and lock buttons.
local buttonsPanel = makePanel(gui, "ButtonsPanel", UDim2.new(0, 460, 0, 64),
	UDim2.new(0.5, -230, 1, -76))
local rebirthButton = Instance.new("TextButton")
rebirthButton.Name = "RebirthButton"
rebirthButton.Size = UDim2.new(0.48, -6, 1, -12)
rebirthButton.Position = UDim2.new(0, 6, 0, 6)
rebirthButton.BackgroundColor3 = Color3.fromRGB(150, 60, 200)
rebirthButton.Text = "✨ Rebirth"
rebirthButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rebirthButton.TextSize = 20
rebirthButton.Font = Enum.Font.SourceSansBold
rebirthButton.Parent = buttonsPanel
local rebirthCorner = Instance.new("UICorner")
rebirthCorner.CornerRadius = UDim.new(0, 10)
rebirthCorner.Parent = rebirthButton

local lockButton = Instance.new("TextButton")
lockButton.Name = "LockButton"
lockButton.Size = UDim2.new(0.48, -6, 1, -12)
lockButton.Position = UDim2.new(0.52, 0, 0, 6)
lockButton.BackgroundColor3 = Color3.fromRGB(40, 120, 200)
lockButton.Text = "🔒 Lock Base"
lockButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lockButton.TextSize = 20
lockButton.Font = Enum.Font.SourceSansBold
lockButton.Parent = buttonsPanel
local lockCorner = Instance.new("UICorner")
lockCorner.CornerRadius = UDim.new(0, 10)
lockCorner.Parent = lockButton

rebirthButton.MouseButton1Click:Connect(function()
	RebirthEvent:FireServer()
end)
lockButton.MouseButton1Click:Connect(function()
	LockBaseEvent:FireServer()
end)

-- Bottom left: how to play.
local helpPanel = makePanel(gui, "HelpPanel", UDim2.new(0, 300, 0, 128),
	UDim2.new(0, 12, 1, -140))
makeLabel(helpPanel, "HelpTitle", "HOW TO PLAY",
	UDim2.new(1, 0, 0, 24), UDim2.new(0, 0, 0, 6), 17,
	Color3.fromRGB(255, 215, 80))
local helpText = makeLabel(helpPanel, "HelpText",
	"1. Walk the boulevard, press E on a brainrot to buy it.\n"
	.. "2. Carry it home to your base - it earns $ every second.\n"
	.. "3. Rarer brainrots earn more. Golden, Diamond and Rainbow pay extra.\n"
	.. "4. When the wave comes, dash to your base or be swept away!",
	UDim2.new(1, -16, 0, 96), UDim2.new(0, 8, 0, 28), 14,
	Color3.fromRGB(230, 230, 230))
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Top

-- Toasts: one line at the bottom centre, above the buttons.
local toastLabel = makeLabel(gui, "ToastLabel", "",
	UDim2.new(0, 520, 0, 30), UDim2.new(0.5, -260, 1, -116), 18,
	Color3.fromRGB(255, 255, 255))
toastLabel.BackgroundTransparency = 0.4
toastLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
toastLabel.Visible = false
local toastToken = 0

local function showToast(message)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = message
	toastLabel.Visible = true
	task.delay(3.5, function()
		if token == toastToken then
			toastLabel.Visible = false
		end
	end)
end

-- Refresh the collection list from the server's owned list.
local function refreshCollection(ownedList)
	for _, child in ipairs(collectionList:GetChildren()) do
		child:Destroy()
	end
	if #ownedList == 0 then
		makeLabel(collectionList, "EmptyLabel", "No brainrots yet.\nBuy one on the boulevard!",
			UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 6), 15,
			Color3.fromRGB(200, 200, 200))
		return
	end
	for i, item in ipairs(ownedList) do
		if i > 6 then
			break
		end
		local row = makeLabel(collectionList, "Row" .. i,
			item.name .. "  •  " .. formatMoney(item.income) .. "/s",
			UDim2.new(1, 0, 0, 26), UDim2.new(0, 0, 0, (i - 1) * 28), 15,
			BrainrotCatalog.RARITY_COLORS[item.rarity] or Color3.fromRGB(255, 255, 255))
		row.TextXAlignment = Enum.TextXAlignment.Left
	end
end

-- The server's once-a-second state push.
GameStateEvent.OnClientEvent:Connect(function(state)
	moneyLabel.Text = formatMoney(state.money)
	incomeLabel.Text = formatMoney(state.income) .. "/s"
	rebirthLabel.Text = "Rebirths: " .. state.rebirths
		.. " (x" .. string.format("%.2f", state.rebirthMult) .. ")"
	ownedLabel.Text = "Brainrots: " .. state.owned .. "/" .. state.slots
	if state.carried then
		carriedLabel.Text = "Carrying: " .. state.carried
	else
		carriedLabel.Text = "Carrying: -"
	end
	if state.lockRemaining > 0 then
		lockLabel.Text = "Base: LOCKED " .. state.lockRemaining .. "s"
	elseif state.lockCooldown > 0 then
		lockLabel.Text = "Base: lock in " .. state.lockCooldown .. "s"
	else
		lockLabel.Text = "Base: Unlocked"
	end
	rebirthButton.Text = "✨ Rebirth (" .. formatMoney(state.rebirthCost) .. ")"
	if state.waveSweeping then
		wavePanel.Visible = true
		waveLabel.Text = "🌊 THE WAVE IS HERE! Get to your base!"
	elseif state.waveWarning then
		wavePanel.Visible = true
		waveLabel.Text = "⚠️ WAVE in " .. state.waveIn .. "s — dash to your base!"
	elseif state.waveIn <= 30 then
		wavePanel.Visible = true
		waveLabel.Text = "🌊 Wave in " .. state.waveIn .. "s"
	else
		wavePanel.Visible = false
	end
	if state.ownedList then
		refreshCollection(state.ownedList)
	end
end)

NotifyEvent.OnClientEvent:Connect(function(message)
	showToast(message)
end)

gui.Parent = player:WaitForChild("PlayerGui")
