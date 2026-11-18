-- Brainrot Bay cast: every absurd character a player can collect.
-- Each entry is the character's name, rarity, money per second, buy cost,
-- body and head colours, and the accessory that makes it recognisable.
-- Rarities climb Common -> Uncommon -> Rare -> Epic -> Legendary -> Mythic.
-- Mutations multiply a character's income: Golden x2, Diamond x4, Rainbow x8.

local BrainrotCatalog = {}

BrainrotCatalog.RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
}

BrainrotCatalog.RARITY_COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(80, 200, 80),
	Rare = Color3.fromRGB(60, 130, 255),
	Epic = Color3.fromRGB(170, 80, 230),
	Legendary = Color3.fromRGB(255, 150, 30),
	Mythic = Color3.fromRGB(255, 50, 70),
}

-- Spawn weight: rarer characters walk the boulevard less often.
BrainrotCatalog.CHARACTERS = {
	{ id = "picklesworth", name = "Sir Picklesworth", rarity = "Common",
		income = 3, cost = 50, weight = 30,
		body = Color3.fromRGB(90, 160, 60), head = Color3.fromRGB(120, 190, 80),
		accessory = "TopHat", blurb = "A pickle in a top hat. Very distinguished." },
	{ id = "djtoast", name = "DJ Toast", rarity = "Common",
		income = 5, cost = 100, weight = 28,
		body = Color3.fromRGB(200, 170, 110), head = Color3.fromRGB(220, 190, 130),
		accessory = "Sunglasses", blurb = "A toaster that only plays bangers." },
	{ id = "soggy", name = "Captain Soggy", rarity = "Uncommon",
		income = 10, cost = 250, weight = 24,
		body = Color3.fromRGB(220, 120, 90), head = Color3.fromRGB(240, 150, 110),
		accessory = "CaptainHat", blurb = "A cereal-box captain, soggy but proud." },
	{ id = "banana", name = "Baron Banana", rarity = "Uncommon",
		income = 15, cost = 400, weight = 22,
		body = Color3.fromRGB(250, 220, 60), head = Color3.fromRGB(255, 235, 100),
		accessory = "BowTie", blurb = "A banana in a suit. Peels out at parties." },
	{ id = "llama", name = "Professor Llama Pants", rarity = "Rare",
		income = 30, cost = 900, weight = 18,
		body = Color3.fromRGB(200, 180, 150), head = Color3.fromRGB(220, 200, 170),
		accessory = "Glasses", blurb = "A llama in trousers with a PhD in drama." },
	{ id = "quokka", name = "Queen Quokka", rarity = "Rare",
		income = 45, cost = 1500, weight = 16,
		body = Color3.fromRGB(170, 120, 80), head = Color3.fromRGB(190, 140, 95),
		accessory = "Crown", blurb = "The happiest monarch in the bay." },
	{ id = "router", name = "Grandma's Router", rarity = "Epic",
		income = 80, cost = 3000, weight = 12,
		body = Color3.fromRGB(90, 90, 110), head = Color3.fromRGB(120, 120, 150),
		accessory = "Antenna", blurb = "A Wi-Fi router with granny glasses." },
	{ id = "burrito", name = "The Forbidden Burrito", rarity = "Epic",
		income = 120, cost = 5000, weight = 10,
		body = Color3.fromRGB(200, 140, 60), head = Color3.fromRGB(220, 160, 80),
		accessory = "Glow", blurb = "It glows. Do not eat it. It knows." },
	{ id = "meowsalot", name = "Sir Meowsalot", rarity = "Legendary",
		income = 200, cost = 10000, weight = 7,
		body = Color3.fromRGB(230, 150, 60), head = Color3.fromRGB(245, 170, 80),
		accessory = "KnightHelmet", blurb = "A cat knight, sworn to protect the snacks." },
	{ id = "goldfish", name = "Chad Goldfish", rarity = "Legendary",
		income = 300, cost = 15000, weight = 6,
		body = Color3.fromRGB(255, 140, 40), head = Color3.fromRGB(255, 170, 70),
		accessory = "Sunglasses", blurb = "A goldfish in a tiny car. He is him." },
	{ id = "spaghetti", name = "Lord Spaghetti Monster", rarity = "Mythic",
		income = 500, cost = 30000, weight = 4,
		body = Color3.fromRGB(240, 220, 160), head = Color3.fromRGB(250, 235, 190),
		accessory = "NoodleCrown", blurb = "A flying spaghetti monster. All hail." },
	{ id = "fridge", name = "The Interdimensional Fridge", rarity = "Mythic",
		income = 800, cost = 50000, weight = 3,
		body = Color3.fromRGB(200, 210, 220), head = Color3.fromRGB(220, 230, 240),
		accessory = "Portal", blurb = "A fridge with a portal. The light stays on." },
}

BrainrotCatalog.MUTATIONS = {
	{ name = "Normal", mult = 1, weight = 70, tint = nil },
	{ name = "Golden", mult = 2, weight = 18, tint = Color3.fromRGB(255, 210, 60) },
	{ name = "Diamond", mult = 4, weight = 9, tint = Color3.fromRGB(140, 220, 255) },
	{ name = "Rainbow", mult = 8, weight = 3, tint = Color3.fromRGB(255, 100, 200) },
}

function BrainrotCatalog.getById(id)
	for _, entry in ipairs(BrainrotCatalog.CHARACTERS) do
		if entry.id == id then
			return entry
		end
	end
	return nil
end

local function rollWeighted(list)
	local total = 0
	for _, entry in ipairs(list) do
		total += entry.weight
	end
	local roll = math.random() * total
	for _, entry in ipairs(list) do
		roll -= entry.weight
		if roll <= 0 then
			return entry
		end
	end
	return list[1]
end

-- Pick a random character, weighted so rarer ones appear less often.
function BrainrotCatalog.rollCharacter()
	return rollWeighted(BrainrotCatalog.CHARACTERS)
end

-- Pick a random mutation, weighted so the big multipliers are rare.
function BrainrotCatalog.rollMutation()
	return rollWeighted(BrainrotCatalog.MUTATIONS)
end

-- Money per second of one character with its mutation and rebirth multiplier.
function BrainrotCatalog.incomePerSecond(entry, mutation, rebirthMult)
	return math.floor(entry.income * mutation.mult * rebirthMult + 0.5)
end

return BrainrotCatalog
