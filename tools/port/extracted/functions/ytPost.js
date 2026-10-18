function ytPost(func, args){
  try{
    var iframe=document.getElementById('ytmusic');
    if(!iframe||!iframe.contentWindow) return;
    iframe.contentWindow.postMessage(JSON.stringify({event:'command',func:func,args:args||[],id:'ytmusic',channel:'widget'}),'*');
  }catch(e){}
}
