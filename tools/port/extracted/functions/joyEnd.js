function joyEnd(e){ if(!joy.active)return; if(e.changedTouches){ let hit=false; for(const tt of e.changedTouches){ if(tt.identifier===joy.id)hit=true; } if(!hit)return; } joyReset(); }
