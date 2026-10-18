function saveShopUnlocks(){ try{ localStorage.setItem('bobina_shopunlocks', JSON.stringify(shopUnlocks)); }catch(e){} }
// A FRESH save starts with only these four (Red Death / SKOL Mech + Bearzooka / Kuma Katana). Everything else is
// bought with Mumu heads at Honey Badger's shop. (Existing players are grandfathered — see the migration below.)
const FREE_CONTENT={ 'w:laser':1, 's:mech':1, 's:bearzooka':1, 'm:katana':1 };
const SHOP_COST={ 'w:lotus':60,'w:shock':60,'s:kraken':90,'s:void':90,'m:hammer':75 };   // per-item price overrides
const CONTENT_COST={ w:48, s:68, m:55 };   // default shop price by category
