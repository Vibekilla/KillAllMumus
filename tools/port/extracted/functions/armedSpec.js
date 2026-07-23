function armedSpec(){ if(!run||!run.specials||!run.specials.length) return null; return SPECIALS.find(s=>s.key===run.specials[run.armed%run.specials.length])||null; }
