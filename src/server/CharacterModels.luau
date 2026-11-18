-- Brainrot Bay character models: builds each brainrot as a 3D model of Parts.
-- A model is a body, a head, eyes, one accessory that makes the character
-- recognisable, and a floating label with its name, rarity and money rate.
-- Every part is anchored and non-colliding, so a model moves only when the
-- server pivots it, and never blocks a player.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotCatalog = require(Shared:WaitForChild("BrainrotCatalog"))

local CharacterModels = {}

local function makePart(name, size, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = true
	part.CanTouch = true
	return part
end

local function addEyes(head, headSize)
	-- Eyes sit on the head's front face; the head's centre is 4 studs up,
	-- so every eye part is offset by that height.
	local headY = 4
	local eyeY = headY + headSize.Y * 0.15
	for _, side in ipairs({ -1, 1 }) do
		local eye = makePart("Eye", Vector3.new(0.45, 0.55, 0.2),
			Color3.fromRGB(255, 255, 255))
		eye.Position = Vector3.new(side * 0.55, eyeY, headSize.Z / 2 + 0.05)
		eye.Parent = head.Parent
		local pupil = makePart("Pupil", Vector3.new(0.22, 0.3, 0.1),
			Color3.fromRGB(20, 20, 20))
		pupil.Position = Vector3.new(side * 0.55, eyeY - 0.05, headSize.Z / 2 + 0.16)
		pupil.Parent = head.Parent
	end
end

-- One accessory per character id. Each is a few small parts on the head.
local ACCESSORIES = {}

ACCESSORIES.TopHat = function(model, head, headSize)
	local brim = makePart("HatBrim", Vector3.new(3, 0.3, 3), Color3.fromRGB(30, 30, 35))
	brim.Position = Vector3.new(0, headSize.Y / 2 + 0.15, 0)
	brim.Parent = model
	local top = makePart("HatTop", Vector3.new(1.8, 1.6, 1.8), Color3.fromRGB(30, 30, 35))
	top.Position = Vector3.new(0, headSize.Y / 2 + 1, 0)
	top.Parent = model
end

ACCESSORIES.Sunglasses = function(model, head, headSize)
	local shades = makePart("Shades", Vector3.new(1.8, 0.5, 0.3), Color3.fromRGB(15, 15, 15))
	shades.Position = Vector3.new(0, headSize.Y * 0.1, headSize.Z / 2 + 0.12)
	shades.Parent = model
end

ACCESSORIES.CaptainHat = function(model, head, headSize)
	local cap = makePart("Cap", Vector3.new(2.4, 0.6, 2.4), Color3.fromRGB(240, 240, 240))
	cap.Position = Vector3.new(0, headSize.Y / 2 + 0.3, 0)
	cap.Parent = model
	local brim = makePart("CapBrim", Vector3.new(2.4, 0.25, 1), Color3.fromRGB(240, 240, 240))
	brim.Position = Vector3.new(0, headSize.Y / 2 + 0.05, headSize.Z / 2 + 0.4)
	brim.Parent = model
end

ACCESSORIES.BowTie = function(model, head, headSize)
	local tie = makePart("BowTie", Vector3.new(1.4, 0.5, 0.3), Color3.fromRGB(200, 30, 40))
	tie.Position = Vector3.new(0, -headSize.Y / 2 - 0.6, headSize.Z / 2)
	tie.Parent = model
end

ACCESSORIES.Glasses = function(model, head, headSize)
	for _, side in ipairs({ -1, 1 }) do
		local lens = makePart("Lens", Vector3.new(0.8, 0.8, 0.15), Color3.fromRGB(40, 40, 50))
		lens.Position = Vector3.new(side * 0.55, headSize.Y * 0.1, headSize.Z / 2 + 0.1)
		lens.Parent = model
	end
end

ACCESSORIES.Crown = function(model, head, headSize)
	for i = -1, 1 do
		local spike = makePart("CrownSpike", Vector3.new(0.5, 0.9, 0.5),
			Color3.fromRGB(255, 210, 60), Enum.Material.Neon)
		spike.Position = Vector3.new(i * 0.7, headSize.Y / 2 + 0.45, 0)
		spike.Parent = model
	end
end

ACCESSORIES.Antenna = function(model, head, headSize)
	local rod = makePart("AntennaRod", Vector3.new(0.25, 1.4, 0.25), Color3.fromRGB(120, 120, 130))
	rod.Position = Vector3.new(0, headSize.Y / 2 + 0.7, 0)
	rod.Parent = model
	local tip = makePart("AntennaTip", Vector3.new(0.6, 0.6, 0.6), Color3.fromRGB(255, 80, 80),
		Enum.Material.Neon)
	tip.Shape = Enum.PartType.Ball
	tip.Position = Vector3.new(0, headSize.Y / 2 + 1.5, 0)
	tip.Parent = model
end

ACCESSORIES.Glow = function(model, head, headSize)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 60)
	light.Range = 12
	light.Brightness = 2
	light.Parent = head
end

ACCESSORIES.KnightHelmet = function(model, head, headSize)
	local helm = makePart("Helmet", Vector3.new(2.4, 1.2, 2.4), Color3.fromRGB(160, 160, 170))
	helm.Position = Vector3.new(0, headSize.Y / 2 + 0.4, 0)
	helm.Parent = model
	local plume = makePart("Plume", Vector3.new(0.4, 1.2, 1.6), Color3.fromRGB(220, 40, 50))
	plume.Position = Vector3.new(0, headSize.Y / 2 + 1.4, 0)
	plume.Parent = model
end

ACCESSORIES.NoodleCrown = function(model, head, headSize)
	for i = -1, 1 do
		local noodle = makePart("Noodle", Vector3.new(0.35, 1.1, 0.35),
			Color3.fromRGB(250, 235, 190))
		noodle.Position = Vector3.new(i * 0.7, headSize.Y / 2 + 0.55, 0)
		noodle.Parent = model
	end
end

ACCESSORIES.Portal = function(model, head, headSize)
	local ring = makePart("PortalRing", Vector3.new(0.3, 3.4, 3.4),
		Color3.fromRGB(170, 80, 255), Enum.Material.Neon)
	ring.Position = Vector3.new(0, 0.5, -1.4)
	ring.Parent = model
end

-- Build the floating label: name on top, rarity and rate below.
local function addLabel(model, head, entry, mutation, income)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BrainrotLabel"
	gui.Size = UDim2.fromOffset(150, 64)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = gui

	local infoLabel = Instance.new("TextLabel")
	infoLabel.Name = "InfoLabel"
	infoLabel.Size = UDim2.new(1, 0, 0.45, 0)
	infoLabel.Position = UDim2.new(0, 0, 0.55, 0)
	infoLabel.BackgroundTransparency = 1
	local mutationText = ""
	if mutation.name ~= "Normal" then
		mutationText = " " .. mutation.name
	end
	infoLabel.Text = entry.rarity .. mutationText .. "  •  $" .. income .. "/s"
	infoLabel.TextColor3 = BrainrotCatalog.RARITY_COLORS[entry.rarity]
	infoLabel.TextStrokeTransparency = 0
	infoLabel.TextScaled = true
	infoLabel.Font = Enum.Font.SourceSansBold
	infoLabel.Parent = gui
end

-- Build a brainrot model for a catalog entry and a mutation.
-- Returns the Model, with its PrimaryPart set to the body.
function CharacterModels.build(entry, mutation)
	local model = Instance.new("Model")
	model.Name = entry.id

	local bodyColor = entry.body
	if mutation.tint then
		bodyColor = mutation.tint
	end

	local body = makePart("Body", Vector3.new(3, 3, 2), bodyColor)
	body.Position = Vector3.new(0, 1.5, 0)
	body.Parent = model
	model.PrimaryPart = body

	local headSize = Vector3.new(2.2, 2, 2)
	local head = makePart("Head", headSize, entry.head)
	head.Position = Vector3.new(0, 4, 0)
	head.Parent = model

	addEyes(head, headSize)

	local buildAccessory = ACCESSORIES[entry.accessory]
	if buildAccessory then
		-- Accessories are placed relative to the head's centre; shift them up.
		local accessoryModel = Instance.new("Model")
		accessoryModel.Name = "Accessory"
		accessoryModel.Parent = model
		-- Build the accessory parts at head height by offsetting the model.
		local oldParent = accessoryModel.Parent
		-- Simpler: build parts directly into the model at head-relative offsets.
		-- The accessory functions place parts around y = headSize.Y/2 + ..., so
		-- re-parent them after by moving them up by the head's centre height.
		buildAccessory(accessoryModel, head, headSize)
		for _, part in ipairs(accessoryModel:GetChildren()) do
			if part:IsA("BasePart") then
				part.Position += Vector3.new(0, 4, 0)
				part.Parent = model
			end
		end
		accessoryModel:Destroy()
	end

	-- The buy prompt lives on the body; the spawner sets its price text.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = entry.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = body

	return model
end

-- The money a second this model earns, given its entry, mutation and the
-- owner's rebirth multiplier.
function CharacterModels.incomeOf(entry, mutation, rebirthMult)
	return BrainrotCatalog.incomePerSecond(entry, mutation, rebirthMult)
end

-- Refresh the floating label after a mutation or rebirth change.
function CharacterModels.refreshLabel(model, entry, mutation, income)
	local head = model:FindFirstChild("Head")
	if not head then
		return
	end
	local gui = head:FindFirstChild("BrainrotLabel")
	if gui then
		gui:Destroy()
	end
	addLabel(model, head, entry, mutation, income)
end

return CharacterModels
