-- Brainrot Bay tuning: every number the game balances on, in one place.
-- The server and the client both read this module.

local Config = {}

-- How many brainrots one base can hold.
Config.BASE_SLOTS = 6

-- The conveyor (Brainrot Boulevard): characters walk from the north gate to
-- the south end, then despawn.
Config.PATH_START_Z = -100
Config.PATH_END_Z = 100
Config.PATH_SPEED = 6 -- studs per second
Config.SPAWN_INTERVAL = 4 -- seconds between spawns
Config.MAX_ON_PATH = 10 -- never more than this many walking the boulevard

-- The wave: a wall of water sweeps the map from north to south. Anyone caught
-- off their base when it passes is swept back to their base and drops what
-- they are carrying.
Config.WAVE_INTERVAL = 100 -- seconds between waves
Config.WAVE_WARNING = 10 -- seconds of warning before the wall starts
Config.WAVE_SPEED = 26 -- studs per second, north to south
Config.WAVE_PENALTY_FRACTION = 0.05 -- money lost when the wave catches you

-- Base lock: the owner's button locks the base against stealing.
Config.LOCK_DURATION = 20 -- seconds a lock holds
Config.LOCK_COOLDOWN = 60 -- seconds before the button works again

-- Rebirth: reset money and your base for a permanent income multiplier.
Config.REBIRTH_BASE_COST = 10000 -- cost of the first rebirth
Config.REBIRTH_COST_GROWTH = 2 -- each rebirth costs this many times the last
Config.REBIRTH_MULT_PER = 0.25 -- +25% income per rebirth, stacking

-- Money ticks once a second on the server.
Config.INCOME_TICK = 1

-- A carried brainrot floats beside its carrier at this offset.
Config.CARRY_OFFSET = Vector3.new(3, 1.5, 0)

return Config
