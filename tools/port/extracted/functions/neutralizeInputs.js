function neutralizeInputs(){   // neutralise the tap/keypress that triggered a transition so it doesn't leak into firing / a melee swipe / an ability
  for(const k in keys) keys[k]=false; pointer.down=false; lastShiftTap=-99;
  if(player){ player.meleeHeld=false; player.meleeChg=0; player._eHeld=false; }
}
