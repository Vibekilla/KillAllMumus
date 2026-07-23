function setBind(action, code){ for(const a in binds){ if(binds[a]===code) binds[a]=''; } binds[action]=code; saveBinds(); rebuildKMAP(); }
