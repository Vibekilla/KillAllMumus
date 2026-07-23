function advanceScreen(){
  if(state==='intro'){ state='play'; neutralizeInputs(); }   // clean stage start: neutralise the tap/keypress that began the stage
  else if(state==='stageclear'){ loadStage(run.stageIdx+1); state='intro'; introTimer=120; }
  else if(state==='gameover'){ newRun(); }
  else if(state==='win'){ newRun(); }
  else if(state==='leaderboard'){ state='title'; }
  else if(state==='emblems'){ state='title'; }
  else if(state==='outfits'){ state='title'; }
  else if(state==='ngselect'){ state='title'; }
}
