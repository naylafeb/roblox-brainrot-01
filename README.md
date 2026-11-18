# roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/naylafeb/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/naylafeb/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay** — a 3D Steal-a-Brainrot-style Roblox game. Brainrot characters walk the boulevard from the north gate; buy one with its prompt, carry it home, and place it on a pad of your base to earn money every second. Twelve absurd characters climb Common → Mythic rarities — Sir Picklesworth, DJ Toast, Captain Soggy, Baron Banana, Professor Llama Pants, Queen Quokka, Grandma's Router, The Forbidden Burrito, Sir Meowsalot, Chad Goldfish, Lord Spaghetti Monster, and The Interdimensional Fridge — each with Golden / Diamond / Rainbow mutations (x2 / x4 / x8 income) and rebirths that multiply everything. Every 100 seconds a wave sweeps the map: anyone caught off their base is swept home and drops what they carry, and a rival can steal a character from an unlocked base. Lock your base, dash home, and get rich.

- `main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with `vendor/makefun-roblox.ts`, the kit's copy, unchanged.
- `game.rbxl` is the place Rojo builds from `src/` and `default.project.json`: a 3D world (baseplate, boulevard, spawn plaza, 4 player bases, north gate, palm trees, lamps, rocks) plus the server scripts (`GameServer`, `BaseManager`, `CharacterSpawner`, `CharacterModels`, `WaveManager`), shared modules (`BrainrotCatalog`, `Config`), and the client HUD (money, income, collection, wave timer, rebirth and lock buttons).
- `screenshots/` holds three captures; one of them must also be your game's first thumbnail on Roblox, uploaded on the Creator Dashboard with your game's icon.
- `PLAY.json` names no place yet — it is filled in when the game is published.

## Run it

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

---

<sub>Entered on [make.fun](https://make.fun/?ref=nxwnbx2d&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
