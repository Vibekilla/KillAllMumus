function rebuildKMAP(){ KMAP=Object.assign({}, FIXED_KMAP); for(const a in binds){ if(binds[a]) KMAP[binds[a]]=a; } }
