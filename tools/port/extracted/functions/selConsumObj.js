function selConsumObj(){
  if(!Array.isArray(arsenalI)) arsenalI=[];
  if(!arsenalI.length) return null;
  if(selConsum<0||selConsum>=arsenalI.length) selConsum=0;
  return consumById(arsenalI[selConsum]);
}
