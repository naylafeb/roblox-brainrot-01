-- Brainrot Bay wave: every WAVE_INTERVAL seconds a wall of water sweeps the
-- map from north to south. A player caught off their own base when the wall
-- passes is swept back to their base, drops whatever they are carrying, and
-- loses a slice of their money. The warning gives everyone time to dash home.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))

local WaveManager = {}

local callbacks = nil
local timeUntilWave = Config.WAVE_INTERVAL
local warned = false
local sweeping = false
local wall = nil
local wallZ = -110
local knocked = {} -- players already swept by this wave

local function buildWall()
	local part = Instance.new("Part")
	part.Name = "WaveWall"
	part.Size = Vector3.new(220, 30, 2)
	part.Color = Color3.fromRGB(60, 140, 255)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.5
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Position = Vector3.new(0, 15, -110)
	part.Parent = Workspace
	return part
end

-- Seconds until the next wave starts, for the HUD countdown.
function WaveManager.timeUntilWave()
	if sweeping then
		return 0
	end
	return math.max(0, timeUntilWave)
end

function WaveManager.isWarning()
	return not sweeping and timeUntilWave <= Config.WAVE_WARNING
end

function WaveManager.isSweeping()
	return sweeping
end

local function startSweep()
	sweeping = true
	wallZ = -110
	knocked = {}
	if not wall then
		wall = buildWall()
	end
	wall.Position = Vector3.new(0, 15, wallZ)
	callbacks.notifyAll("🌊 THE WAVE IS HERE! Get to your base!")
end

local function endSweep()
	sweeping = false
	timeUntilWave = Config.WAVE_INTERVAL
	warned = false
	if wall then
		wall.Position = Vector3.new(0, -100, -110)
	end
	callbacks.notifyAll("The wave has passed. Back to collecting!")
end

-- Sweep one step: move the wall, and knock anyone it catches off-base.
local function sweepStep(dt)
	wallZ += Config.WAVE_SPEED * dt
	wall.Position = Vector3.new(0, 15, wallZ)
	for _, player in ipairs(Players:GetPlayers()) do
		if not knocked[player] then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				local base = callbacks.getBaseOf(player)
				local onOwnBase = base and BaseManager.baseAt(root.Position) == base
				if not onOwnBase and math.abs(root.Position.Z - wallZ) < 4 then
					knocked[player] = true
					callbacks.knockPlayer(player)
				end
			end
		end
	end
	if wallZ >= 110 then
		endSweep()
	end
end

local function update(dt)
	if sweeping then
		sweepStep(dt)
		return
	end
	timeUntilWave -= dt
	if timeUntilWave <= Config.WAVE_WARNING and not warned then
		warned = true
		callbacks.notifyAll("⚠️ WAVE INCOMING in " .. Config.WAVE_WARNING .. "s! Dash to your base!")
	end
	if timeUntilWave <= 0 then
		startSweep()
	end
end

function WaveManager.init(cb)
	callbacks = cb
	RunService.Heartbeat:Connect(update)
end

return WaveManager
