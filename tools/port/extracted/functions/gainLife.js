function gainLife(){ if(run.lives<MAX_LIVES){ run.lives++; sfx('extend'); flashMsg={t:90,txt:'1UP!'}; pop(player.x,player.y-30,'1UP','#ff4d8d'); } else { sessionScore+=50000; } }
