function ytShuffle(){
  if(ytShuffled) return;
  ytShuffled=true;
  // Only after PLAYING — getPlaylist/playVideoAt at CUED wedges the widget.
  // setShuffle leaves the current index, so jump into the shuffled list.
  var ytShuffleJump=-1, listed=false;
  try{
    if(ytPlayer){
      ytPlayer.setLoop(true);
      ytPlayer.setShuffle(true);
      var list=(ytPlayer.getPlaylist&&ytPlayer.getPlaylist())||[];
      listed=!!(list&&list.length);
      if(list&&list.length>1){
        var cur=0; try{ cur=ytPlayer.getPlaylistIndex()||0; }catch(e1){}
        if(cur<0||cur>=list.length) cur=0;
        ytShuffleJump=Math.floor(Math.random()*(list.length-1));
        if(ytShuffleJump>=cur) ytShuffleJump++;
      }
    }
  }catch(e){}
  ytPost('setLoop',[true]); ytPost('setShuffle',[true]);
  if(ytShuffleJump>=0){
    try{ if(ytPlayer) ytPlayer.playVideoAt(ytShuffleJump); }catch(e2){}
    ytPost('playVideoAt',[ytShuffleJump]);
  }else if(!listed){
    try{ if(ytPlayer) ytPlayer.nextVideo(); }catch(e3){}
    ytPost('nextVideo');
  }
}
window.onYouTubeIframeAPIReady=function(){
  try{
    ytPlayer=new YT.Player('ytmusic',{
      playerVars:{ autoplay:0, controls:0, disablekb:1, loop:1, listType:'playlist', list:YT_LIST, modestbranding:1, playsinline:1, rel:0, fs:0, origin:location.origin },
      events:{
        onReady:()=>{ ytReady=true; ytKick(); },
        onStateChange:(e)=>{
          if(e.data===YT.PlayerState.PLAYING){ ytErrSkips=0; ytKickUntil=0; ytShuffle(); }
          if(e.data===YT.PlayerState.CUED && ytWant) ytKick();
          if(e.data===YT.PlayerState.ENDED && ytWant){ try{ ytPlayer.nextVideo(); }catch(e2){} ytPost('nextVideo'); }
        },
        onError:()=>{ if(!ytWant) return; ytErrSkips++; if(ytErrSkips>12) return; try{ ytPlayer.nextVideo(); }catch(e){} ytPost('nextVideo'); }
      } });
  }catch(e){}
};
