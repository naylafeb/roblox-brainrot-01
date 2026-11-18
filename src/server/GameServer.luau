-- Brainrot Bay game server: the one place that keeps player state.
-- Money, rebirths, bases and the income tick live here. The conveyor, the
-- bases and the wave are modules this server wires together; the client
-- only ever talks to this server through RemoteEvents, never to the modules.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Config = require(Shared:WaitForChild("Config"))

local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local CharacterSpawner = require(script.Parent:WaitForChild("CharacterSpawner"))
local WaveManager = require(script.Parent:WaitForChild("WaveManager"))

local GameServer = {}

local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local RebirthEvent = Remotes:WaitForChild("Rebirth")
local LockBaseEvent = Remotes:WaitForChild("LockBase")
local GameStateEvent = Remotes:WaitForChild("GameState")
local NotifyEvent = Remotes:WaitForChild("Notify")

-- One record per player: their money, rebirths and base.
local players = {}

local function rebirthCost(state)
	return math.floor(Config.REBIRTH_BASE_COST
		* (Config.REBIRTH_COST_GROWTH ^ state.rebirths) + 0.5)
end

function GameServer.getState(player)
	return players[player]
end

function GameServer.getRebirthMult(player)
	local state = players[player]
	if not state then
		return 1
	end
	return 1 + Config.REBIRTH_MULT_PER * state.rebirths
end

function GameServer.getBaseOf(player)
	local state = players[player]
	if state then
		return state.base
	end
	return nil
end

function GameServer.getCarried(player)
	return CharacterSpawner.getCarried(player)
end

-- Take money for a purchase. Returns true, or false and why not.
function GameServer.charge(player, cost)
	local state = players[player]
	if not state then
		return false, "No player state yet."
	end
	if state.money < cost then
		return false, "Need $" .. cost .. " (you have $" .. state.money .. ")."
	end
	state.money -= cost
	GameServer.syncLeaderstats(player)
	return true
end

function GameServer.syncLeaderstats(player)
	local state = players[player]
	if not state then
		return
	end
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local money = leaderstats:FindFirstChild("Money")
		if money then
			money.Value = state.money
		end
		local rebirths = leaderstats:FindFirstChild("Rebirths")
		if rebirths then
			rebirths.Value = state.rebirths
		end
	end
end

-- Push the HUD state to one player: money, income, collection, rebirths,
-- wave countdown and lock status.
function GameServer.broadcastState(player)
	local state = players[player]
	if not state then
		return
	end
	local base = state.base
	local carried = CharacterSpawner.getCarried(player)
	local carriedName = nil
	if carried then
		local entry = BrainrotCatalog.getById(carried.Name)
		if entry then
			carriedName = entry.name
		end
	end
	GameStateEvent:FireClient(player, {
		money = state.money,
		income = CharacterSpawner.incomeFor(player),
		owned = CharacterSpawner.placedCount(player),
		ownedList = CharacterSpawner.ownedList(player),
		slots = Config.BASE_SLOTS,
		rebirths = state.rebirths,
		rebirthMult = GameServer.getRebirthMult(player),
		rebirthCost = rebirthCost(state),
		carried = carriedName,
		waveIn = math.ceil(WaveManager.timeUntilWave()),
		waveWarning = WaveManager.isWarning(),
		waveSweeping = WaveManager.isSweeping(),
		lockRemaining = base and math.ceil(BaseManager.lockRemaining(base)) or 0,
		lockCooldown = base and math.ceil(BaseManager.lockCooldownRemaining(base)) or 0,
	})
end

function GameServer.notify(player, message)
	NotifyEvent:FireClient(player, message)
end

function GameServer.notifyAll(message)
	NotifyEvent:FireAllClients(message)
end

-- The wave caught a player off their base: drop what they carry, send them
-- home, and take a slice of their money.
function GameServer.knockPlayer(player)
	local state = players[player]
	if not state then
		return
	end
	CharacterSpawner.dropCarried(player, "The wave swept you away!")
	local lost = math.floor(state.money * Config.WAVE_PENALTY_FRACTION)
	state.money -= lost
	GameServer.syncLeaderstats(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root and state.base then
		player.Character:PivotTo(BaseManager.spawnCFrame(state.base))
	end
	GameServer.notify(player, "🌊 The wave caught you! Lost $" .. lost .. ".")
	GameServer.broadcastState(player)
end

-- Rebirth: reset money and your base for a permanent income multiplier.
function GameServer.rebirth(player)
	local state = players[player]
	if not state then
		return
	end
	local cost = rebirthCost(state)
	if state.money < cost then
		GameServer.notify(player, "Rebirth costs $" .. cost .. " (you have $" .. state.money .. ").")
		return
	end
	state.money = 0
	state.rebirths += 1
	CharacterSpawner.clearPlayer(player)
	GameServer.syncLeaderstats(player)
	GameServer.notify(player, "✨ REBIRTH! Income is now x"
		.. string.format("%.2f", GameServer.getRebirthMult(player)) .. ".")
	GameServer.notifyAll(player.Name .. " rebirthed! (x"
		.. string.format("%.2f", GameServer.getRebirthMult(player)) .. " income)")
	GameServer.broadcastState(player)
end

-- Lock this player's base against stealing.
function GameServer.lockBase(player)
	local state = players[player]
	if not state or not state.base then
		return
	end
	local ok, message = BaseManager.tryLock(state.base, player)
	GameServer.notify(player, message)
	if ok then
		GameServer.broadcastState(player)
	end
end

-- A brainrot was placed on a pad: refresh the owner's HUD.
function GameServer.onPlaced(player)
	GameServer.broadcastState(player)
end

local function setupPlayer(player)
	local base = BaseManager.assignBase(player)
	players[player] = { money = 0, rebirths = 0, base = base }

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = 0
	money.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = 0
	rebirths.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local state = players[player]
		if state and state.base then
			task.wait(0.2)
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				character:PivotTo(BaseManager.spawnCFrame(state.base))
			end
		end
	end)

	if base then
		GameServer.notify(player, "Welcome to Brainrot Bay! This is your base. "
			.. "Buy brainrots on the boulevard and carry them home!")
	else
		GameServer.notify(player, "Welcome to Brainrot Bay! All bases are taken - "
			.. "you can still watch, or wait for a free base.")
	end
end

local function removePlayer(player)
	CharacterSpawner.clearPlayer(player)
	BaseManager.releaseBase(player)
	players[player] = nil
end

-- Every second: pay every player's placed brainrots, then refresh their HUD.
local function incomeTick()
	while true do
		task.wait(Config.INCOME_TICK)
		for player, state in pairs(players) do
			local income = CharacterSpawner.incomeFor(player)
			if income > 0 then
				state.money += income
			end
			GameServer.syncLeaderstats(player)
			GameServer.broadcastState(player)
		end
	end
end

function GameServer.init()
	BaseManager.init()

	RebirthEvent.OnServerEvent:Connect(function(player)
		GameServer.rebirth(player)
	end)
	LockBaseEvent.OnServerEvent:Connect(function(player)
		GameServer.lockBase(player)
	end)

	-- Wire the in-world lock buttons (one per base) to the same lock action
	-- as the HUD button.
	for _, name in ipairs({ "Base1", "Base2", "Base3", "Base4" }) do
		local record = BaseManager.getRecord(name)
		if record then
			local lockButton = record.folder:FindFirstChild("LockButton")
			local prompt = lockButton and lockButton:FindFirstChild("LockPrompt")
			if prompt then
				prompt.Triggered:Connect(function(player)
					GameServer.lockBase(player)
				end)
			end
		end
	end

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(removePlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end

	CharacterSpawner.init({
		charge = function(player, cost)
			return GameServer.charge(player, cost)
		end,
		getBaseOf = function(player)
			return GameServer.getBaseOf(player)
		end,
		getCarried = function(player)
			return GameServer.getCarried(player)
		end,
		getRebirthMult = function(player)
			return GameServer.getRebirthMult(player)
		end,
		notify = function(player, message)
			GameServer.notify(player, message)
		end,
		onPlaced = function(player)
			GameServer.onPlaced(player)
		end,
	})

	WaveManager.init({
		getBaseOf = function(player)
			return GameServer.getBaseOf(player)
		end,
		knockPlayer = function(player)
			GameServer.knockPlayer(player)
		end,
		notifyAll = function(message)
			GameServer.notifyAll(message)
		end,
	})

	task.spawn(incomeTick)
end

return GameServer
