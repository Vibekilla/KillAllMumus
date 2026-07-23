function simStep(){
  if(state==='title') titleIdleT++; else titleIdleT=0;
  update(); emblemTick();
}
