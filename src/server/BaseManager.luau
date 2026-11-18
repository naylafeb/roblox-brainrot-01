-- Brainrot Bay bases: four platforms, one per player, each with six pads
-- for owned brainrots, a lock button, and a flag. This module owns base
-- assignment, pad occupancy, the lock, and the "is this point on a base"
-- test the wave and the carry logic use.

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local BaseManager = {}

local BASE_NAMES = { "Base1", "Base2", "Base3", "Base4" }

-- One record per base: its folder, its owner, which pad holds which model,
-- and the lock state.
local bases = {}

local function buildBaseRecord(folder)
	local pads = {}
	for i = 1, Config.BASE_SLOTS do
		local pad = folder:FindFirstChild("Pad" .. i)
		if pad then
			pads[pad] = false -- false means the pad is free
		end
	end
	return {
		folder = folder,
		owner = nil,
		pads = pads,
		lockUntil = 0,
		lockCooldownUntil = 0,
	}
end

function BaseManager.init()
	for _, name in ipairs(BASE_NAMES) do
		local folder = Workspace:FindFirstChild(name)
		if folder then
			bases[name] = buildBaseRecord(folder)
		end
	end
end

-- Give the joining player the first free base, or nil when all four are taken.
function BaseManager.assignBase(player)
	for _, name in ipairs(BASE_NAMES) do
		local record = bases[name]
		if record and record.owner == nil then
			record.owner = player
			return record
		end
	end
	return nil
end

-- Hand a base back when its owner leaves; its brainrots go with them.
function BaseManager.releaseBase(player)
	for _, record in pairs(bases) do
		if record.owner == player then
			record.owner = nil
			for pad, model in pairs(record.pads) do
				if model then
					model:Destroy()
				end
				record.pads[pad] = false
			end
			record.lockUntil = 0
			record.lockCooldownUntil = 0
			return record
		end
	end
	return nil
end

function BaseManager.getBaseOf(player)
	for _, record in pairs(bases) do
		if record.owner == player then
			return record
		end
	end
	return nil
end

function BaseManager.getRecord(name)
	return bases[name]
end

-- The platform a point stands on, if any. The wave uses this to tell who is
-- safe; the carry logic uses it to tell when a carried brainrot is home.
function BaseManager.baseAt(position)
	for _, record in pairs(bases) do
		local platform = record.folder:FindFirstChild("Platform")
		if platform then
			local half = platform.Size / 2
			local c = platform.Position
			if math.abs(position.X - c.X) <= half.X
				and math.abs(position.Z - c.Z) <= half.Z
				and position.Y >= c.Y - 2 and position.Y <= c.Y + 12 then
				return record
			end
		end
	end
	return nil
end

-- A free pad on this base, or nil when the base is full.
function BaseManager.findFreePad(record)
	for pad, model in pairs(record.pads) do
		if not model then
			return pad
		end
	end
	return nil
end

function BaseManager.freePadCount(record)
	local free = 0
	for _, model in pairs(record.pads) do
		if not model then
			free += 1
		end
	end
	return free
end

function BaseManager.occupyPad(record, pad, model)
	record.pads[pad] = model
end

function BaseManager.freePad(record, pad)
	record.pads[pad] = false
end

-- The pad a placed model sits on, if it sits on one.
function BaseManager.padOf(record, model)
	for pad, occupant in pairs(record.pads) do
		if occupant == model then
			return pad
		end
	end
	return nil
end

-- Where a player respawns on their base: the middle of the platform.
function BaseManager.spawnCFrame(record)
	local platform = record.folder:FindFirstChild("Platform")
	if not platform then
		return CFrame.new(0, 5, 0)
	end
	local top = platform.Position.Y + platform.Size.Y / 2
	return CFrame.new(platform.Position.X, top + 3, platform.Position.Z)
end

-- Locking: only the base's owner can lock it, for LOCK_DURATION seconds,
-- and the button then needs LOCK_COOLDOWN seconds before it works again.
function BaseManager.isLocked(record)
	return os.clock() < record.lockUntil
end

function BaseManager.lockRemaining(record)
	return math.max(0, record.lockUntil - os.clock())
end

function BaseManager.lockCooldownRemaining(record)
	return math.max(0, record.lockCooldownUntil - os.clock())
end

function BaseManager.tryLock(record, player)
	if record.owner ~= player then
		return false, "Only the base owner can lock it."
	end
	if BaseManager.isLocked(record) then
		return false, "Base is already locked."
	end
	local cooldown = BaseManager.lockCooldownRemaining(record)
	if cooldown > 0 then
		return false, "Lock recharges in " .. math.ceil(cooldown) .. "s."
	end
	record.lockUntil = os.clock() + Config.LOCK_DURATION
	record.lockCooldownUntil = os.clock() + Config.LOCK_COOLDOWN
	return true, "Base locked for " .. Config.LOCK_DURATION .. "s."
end

return BaseManager
