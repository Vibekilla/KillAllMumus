function lockCost(type, key){ if(FREE_CONTENT[type+':'+key]) return 0; return SHOP_COST[type+':'+key] || CONTENT_COST[type] || 30; }
