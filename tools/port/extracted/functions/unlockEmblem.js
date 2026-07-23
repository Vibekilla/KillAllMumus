function unlockEmblem(id){ if(emblemsGot[id]||!emblemDef(id)) return; emblemsGot[id]=true; saveEmblems();
  emblemToasts.push({id,t:0}); newEmblems.push(id); try{ sfx('extend'); }catch(e){} }
