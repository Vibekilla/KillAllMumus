# Migration checklist (HTML → Godot)

| Feature | HTML | Godot module | Status |
| --- | --- | --- | --- |
| Stages 1–7 data | STAGES | `data/stages.json` | ✅ |
| Weapons | WEAPONS | `data/weapons.json` + Player fire | ✅ |
| Specials | useSpecial | `SpecialSystem.gd` | ✅ modular hooks |
| Melee | doMeleeSwipe | `MeleeSystem.gd` | ✅ |
| Consumables | CONSUMABLES | `data/consumables.json` + ConsumableSystem | ✅ |
| Emblems (41) | EMBLEMS | `data/emblems.json` + EmblemSystem + UI | ✅ |
| Outfits (28) | OUTFITS | `data/outfits.json` + OutfitsUI + BobinaSprite | ✅ |
| Shop | drawShop | ShopSystem + ShopUI | ✅ |
| Arsenal | drawArsenal | ArsenalUI | ✅ |
| NG+ select | drawNgSelect | NgSelectUI | ✅ |
| Leaderboard/API | api/scores | ApiClient | ✅ |
| Cloud progress | /api/progress | ProgressStore | ✅ |
| Bobina OAuth | /auth/bobina | ApiClient.open_login | ✅ |
| Display settings | Display menu | DisplayMenu | ✅ |
| Boss patterns | drawBoss | BossController | ✅ basic patterns |
| Touch controls | #touch | reserved TouchControls | ⏳ next |
| Full outfit art | drawBobina | BobinaSprite stand-in | ⏳ enhance |
| YouTube music | YT embed | AudioBus placeholder | ⏳ |

Verification command:
```
~/.local/godot/godot --path godot --headless --quit-after 3
```
