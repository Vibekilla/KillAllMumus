function addWeapon(key, def){ WEAPONS[key]=def; if(!WEAPON_ORDER.includes(key)) WEAPON_ORDER.push(key); return key; }
