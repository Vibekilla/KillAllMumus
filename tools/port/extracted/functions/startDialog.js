function startDialog(lines, bd){ if(speedrun){ dialog=null; return; }   // speedrun: Bobina hates monologues — cut straight to it
  dialog={ boss:bd, queue:lines.slice(), i:0, timer:lineTime(lines[0]) }; }
