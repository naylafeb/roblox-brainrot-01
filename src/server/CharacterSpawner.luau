-- Brainrot Bay conveyor: brainrots walk the boulevard from the north gate
-- to the south end. A player buys one with its prompt, carries it home, and
-- it earns money on a pad of their base. A brainrot on a pad can be stolen
-- by another player unless the base is locked. The wave drops whatever a
-- player is carrying.
--
-- Character states: "conveyor" (walking), "carried" (following a player),
-- "placed" (earning on a pad). The spawner owns every character record.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))
local Config = require(Shared:WaitForChild("Config"))

local CharacterModels = require(script.Parent:WaitForChild("CharacterModels"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))

local CharacterSpawner = {}

local characters = {} -- [model] = record
local callbacks = nil
local spawnAccumulator = 0

-- A character record: the model, what it is, where it is, who owns it.
local function newRecord(model, entry, mutation)
	return {
		model = model,
		entry = entry,
		mutation = mutation,
		state = "conveyor",
		owner = nil,
		homeBase = nil,
		homePad = nil,
		carrier = nil,
		stolenFrom = nil, -- the base it was stolen from, while it is carried
		bobPhase = math.random() * math.pi * 2,
	}
end

local function setPrompt(model, actionText, objectText, enabled)
	local body = model.PrimaryPart
	if not body then
		return
	end
	local prompt = body:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.ActionText = actionText
		prompt.ObjectText = objectText
		prompt.Enabled = enabled
	end
end

local function refreshLabel(record, rebirthMult)
	local income = CharacterModels.incomeOf(record.entry, record.mutation, rebirthMult)
	CharacterModels.refreshLabel(record.model, record.entry, record.mutation, income)
	return income
end

-- Spawn one brainrot at the north gate and let it walk south.
local function spawnBrainrot()
	local conveyorCount = 0
	for _, record in pairs(characters) do
		if record.state == "conveyor" then
			conveyorCount += 1
		end
	end
	if conveyorCount >= Config.MAX_ON_PATH then
		return
	end

	local entry = BrainrotCatalog.rollCharacter()
	local mutation = BrainrotCatalog.rollMutation()
	local model = CharacterModels.build(entry, mutation)
	model:PivotTo(CFrame.new(math.random(-8, 8), 0.2, Config.PATH_START_Z))
	model.Parent = Workspace
	CharacterModels.refreshLabel(model, entry, mutation,
		CharacterModels.incomeOf(entry, mutation, 1))

	local record = newRecord(model, entry, mutation)
	characters[model] = record
	setPrompt(model, "Buy", entry.name .. "  •  $" .. entry.cost, true)

	local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			CharacterSpawner.onPromptTriggered(player, model)
		end)
	end
end

-- A player pressed the prompt on a brainrot. On the conveyor it is a buy;
-- on a pad it is a steal attempt.
function CharacterSpawner.onPromptTriggered(player, model)
	local record = characters[model]
	if not record then
		return
	end

	if record.state == "conveyor" then
		CharacterSpawner.tryBuy(player, record)
	elseif record.state == "placed" then
		CharacterSpawner.trySteal(player, record)
	end
end

-- Buy the brainrot: pay, then carry it home to a free pad of your base.
function CharacterSpawner.tryBuy(player, record)
	if record.state ~= "conveyor" then
		return
	end
	local base = callbacks.getBaseOf(player)
	if not base then
		callbacks.notify(player, "No base yet - wait a moment.")
		return
	end
	if callbacks.getCarried(player) then
		callbacks.notify(player, "Carry one at a time - bring it home first!")
		return
	end
	if BaseManager.freePadCount(base) < 1 then
		callbacks.notify(player, "Your base is full! Rebirth to clear it.")
		return
	end
	local ok, reason = callbacks.charge(player, record.entry.cost)
	if not ok then
		callbacks.notify(player, reason)
		return
	end
	record.state = "carried"
	record.carrier = player
	record.owner = player
	record.homeBase = base
	setPrompt(record.model, "Buy", record.entry.name, false)
	callbacks.notify(player, "Got " .. record.entry.name .. "! Run it home to your base!")
end

-- Steal a brainrot off another player's pad.
function CharacterSpawner.trySteal(player, record)
	if record.state ~= "placed" then
		return
	end
	if record.owner == player then
		callbacks.notify(player, "That one is already yours.")
		return
	end
	local homeBase = record.homeBase
	if not homeBase then
		return
	end
	if BaseManager.isLocked(homeBase) then
		callbacks.notify(player, "That base is locked! Come back later.")
		return
	end
	if callbacks.getCarried(player) then
		callbacks.notify(player, "Carry one at a time - bring it home first!")
		return
	end
	local myBase = callbacks.getBaseOf(player)
	if not myBase then
		return
	end
	if BaseManager.freePadCount(myBase) < 1 then
		callbacks.notify(player, "Your base is full! Rebirth to clear it.")
		return
	end
	-- Lift it off the pad and carry it.
	local pad = record.homePad
	if pad then
		BaseManager.freePad(homeBase, pad)
	end
	record.stolenFrom = homeBase
	record.state = "carried"
	record.carrier = player
	setPrompt(record.model, "Steal", record.entry.name, false)
	callbacks.notify(player, "You stole " .. record.entry.name .. "! Run it home!")
	if record.owner then
		callbacks.notify(record.owner, player.Name .. " is stealing your "
			.. record.entry.name .. "! Tag them to get it back!")
	end
end

-- Put a carried brainrot on a free pad of the carrier's base.
local function placeOnBase(player, record)
	local base = callbacks.getBaseOf(player)
	if not base then
		return false
	end
	local pad = BaseManager.findFreePad(base)
	if not pad then
		return false
	end
	local mult = callbacks.getRebirthMult(player)
	local income = refreshLabel(record, mult)
	record.state = "placed"
	record.owner = player
	record.homeBase = base
	record.homePad = pad
	record.carrier = nil
	record.stolenFrom = nil
	BaseManager.occupyPad(base, pad, record.model)
	local padTop = pad.Position.Y + pad.Size.Y / 2
	record.model:PivotTo(CFrame.new(pad.Position.X, padTop, pad.Position.Z))
	setPrompt(record.model, "Steal", record.entry.name .. "  •  $" .. income .. "/s", true)
	callbacks.onPlaced(player, record)
	return true
end

-- Send a carried brainrot back where it belongs: a stolen one returns to
-- its home base, a bought one goes back to the conveyor.
function CharacterSpawner.dropCarried(player, reason)
	local model = callbacks.getCarried(player)
	if not model then
		return
	end
	local record = characters[model]
	if not record then
		return
	end
	record.carrier = nil
	if record.stolenFrom then
		-- A stolen brainrot goes home to its original base. Its owner is
		-- still the player it was stolen from (trySteal never changes it).
		local homeBase = record.stolenFrom
		local pad = BaseManager.findFreePad(homeBase)
		if pad then
			record.state = "placed"
			record.homeBase = homeBase
			record.homePad = pad
			record.stolenFrom = nil
			BaseManager.occupyPad(homeBase, pad, model)
			local padTop = pad.Position.Y + pad.Size.Y / 2
			model:PivotTo(CFrame.new(pad.Position.X, padTop, pad.Position.Z))
			setPrompt(model, "Steal", record.entry.name, true)
			callbacks.notify(player, "You dropped " .. record.entry.name .. " - it ran home!")
			return
		end
	end
	-- A bought brainrot goes back to the conveyor.
	record.state = "conveyor"
	record.owner = nil
	record.homeBase = nil
	record.homePad = nil
	record.stolenFrom = nil
	model:PivotTo(CFrame.new(math.random(-8, 8), 0.2, Config.PATH_START_Z))
	setPrompt(model, "Buy", record.entry.name .. "  •  $" .. record.entry.cost, true)
	callbacks.notify(player, reason or ("You dropped " .. record.entry.name .. "!"))
end

-- Money per second of everything this player has placed, at their current
-- rebirth multiplier.
function CharacterSpawner.incomeFor(player)
	local mult = callbacks.getRebirthMult(player)
	local total = 0
	for _, record in pairs(characters) do
		if record.state == "placed" and record.owner == player then
			total += CharacterModels.incomeOf(record.entry, record.mutation, mult)
		end
	end
	return total
end

-- The brainrot this player is carrying right now, or nil.
function CharacterSpawner.getCarried(player)
	for model, record in pairs(characters) do
		if record.state == "carried" and record.carrier == player then
			return model
		end
	end
	return nil
end

-- The brainrots this player has placed, richest first, for the HUD list.
function CharacterSpawner.ownedList(player)
	local mult = callbacks.getRebirthMult(player)
	local list = {}
	for _, record in pairs(characters) do
		if record.state == "placed" and record.owner == player then
			table.insert(list, {
				name = record.entry.name,
				rarity = record.entry.rarity,
				income = CharacterModels.incomeOf(record.entry, record.mutation, mult),
			})
		end
	end
	table.sort(list, function(a, b)
		return a.income > b.income
	end)
	return list
end

-- How many brainrots this player has placed.
function CharacterSpawner.placedCount(player)
	local count = 0
	for _, record in pairs(characters) do
		if record.state == "placed" and record.owner == player then
			count += 1
		end
	end
	return count
end

-- Destroy every brainrot a player owns or carries (rebirth, or leaving).
function CharacterSpawner.clearPlayer(player)
	for model, record in pairs(characters) do
		if record.owner == player or record.carrier == player then
			if record.homeBase and record.homePad then
				BaseManager.freePad(record.homeBase, record.homePad)
			end
			characters[model] = nil
			model:Destroy()
		end
	end
end

-- The per-frame update: walk the conveyor, float carried brainrots beside
-- their carrier, place them when the carrier is home, and return stolen
-- ones when their owner tags the thief.
local function update(dt)
	local now = os.clock()
	for model, record in pairs(characters) do
		if record.state == "conveyor" then
			local cf = model:GetPivot()
			local pos = cf.Position
			local bob = math.sin(now * 3 + record.bobPhase) * 0.15
			local newZ = pos.Z + Config.PATH_SPEED * dt
			if newZ >= Config.PATH_END_Z then
				characters[model] = nil
				model:Destroy()
			else
				model:PivotTo(CFrame.new(pos.X, 0.2 + bob, newZ))
			end
		elseif record.state == "carried" then
			local carrier = record.carrier
			if not carrier then
				-- No one carries it any more: send it back to the conveyor.
				record.state = "conveyor"
				record.owner = nil
				record.homeBase = nil
				record.homePad = nil
				record.stolenFrom = nil
				model:PivotTo(CFrame.new(math.random(-8, 8), 0.2, Config.PATH_START_Z))
				setPrompt(model, "Buy", record.entry.name .. "  •  $" .. record.entry.cost, true)
			else
				local character = carrier.Character
				local root = character and character:FindFirstChild("HumanoidRootPart")
				if not root then
					-- The carrier left or died: drop the brainrot.
					CharacterSpawner.dropCarried(carrier, "You dropped " .. record.entry.name .. "!")
				else
					local bob = math.sin(now * 4 + record.bobPhase) * 0.3
					local target = root.CFrame * CFrame.new(Config.CARRY_OFFSET.X, bob, Config.CARRY_OFFSET.Z)
					model:PivotTo(target)
					-- Home? Place it on a pad of the carrier's own base.
					local base = callbacks.getBaseOf(carrier)
					if base then
						local onBase = BaseManager.baseAt(root.Position)
						if onBase == base then
							placeOnBase(carrier, record)
						end
					end
					-- Stolen? The original owner can tag the thief to take it back.
					if record.stolenFrom and record.owner then
						local ownerChar = record.owner.Character
						local ownerRoot = ownerChar and ownerChar:FindFirstChild("HumanoidRootPart")
						if ownerRoot and (ownerRoot.Position - root.Position).Magnitude < 7 then
							CharacterSpawner.dropCarried(carrier,
								record.owner.Name .. " tagged you! " .. record.entry.name .. " ran home!")
						end
					end
				end
			end
		end
	end

	-- Spawn timer.
	spawnAccumulator += dt
	if spawnAccumulator >= Config.SPAWN_INTERVAL then
		spawnAccumulator = 0
		spawnBrainrot()
	end
end

function CharacterSpawner.init(cb)
	callbacks = cb
	-- A few brainrots already walking when the first player arrives.
	for _ = 1, 3 do
		spawnBrainrot()
	end
	-- Stagger the starters along the boulevard.
	local i = 0
	for model, record in pairs(characters) do
		if record.state == "conveyor" then
			i += 1
			model:PivotTo(CFrame.new(math.random(-8, 8), 0.2, -80 + i * 40))
		end
	end
	RunService.Heartbeat:Connect(update)
end

-- Remove a brainrot from the game entirely (used when its base is cleared).
function CharacterSpawner.destroyModel(model)
	local record = characters[model]
	if record then
		if record.homeBase and record.homePad then
			BaseManager.freePad(record.homeBase, record.homePad)
		end
		characters[model] = nil
	end
	model:Destroy()
end

return CharacterSpawner
