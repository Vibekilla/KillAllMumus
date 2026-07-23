function computeEmblems(){ emblems=[];
  if(killsThisStage>=40 || totalKills>=120) emblems.push({n:'Mumu Exterminator', d:'High Mumu kill count'});
  if(totalKills>=260) emblems.push({n:'Total Mumu Annihilation', d:'Extreme total kills'});
  if(shotLevel()>=4) emblems.push({n:'Full Power Bobina', d:'Reached max power'});
  if(state!=='gameover' && run && run.stageIdx>=STAGES.length-1) emblems.push({n:'Bobo Savior + Mumu Slayer', d:'True ending clear'});
}
