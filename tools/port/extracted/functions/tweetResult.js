function tweetResult(won){
  const rank=rankLetter();
  let handle=''; try{ handle=(localStorage.getItem('bobina_handle')||'').replace(/[^A-Za-z0-9_]/g,''); }catch(e){}
  const head = won ? '🐻 BOBO IS SAVED! 🎀' : '🐂 The Mumu horde got me...';
  const body = won
    ? `I exterminated the WHOLE Mumu army and beat James Wynn!`
    : `I went down swinging against the Mumu army.`;
  const stats = `📊 ${totalKills} Mumus · Rank ${rank} · ${fmtScore(sessionScore)} pts${(difficulty>0||ngPlus>0)?(' · '+modeTag()):''}`;
  const text = [
    `${head} 🎮 Bobina: KILL ALL MUMUS!!`, ``,
    body, stats, ``,
    won ? `Think you can top me? 👇` : `Bet you can’t do better. 👇`,
    `@Bobina_Council @EmblemVault @bobocouncil`,
    `#KillAllMumus #EmblemAI $EMBLEM`
  ].join('\n');
  // share page unfurls with a themed card + your stats
  const sp = `${GAME_URL}share/${won?'win':'over'}?s=${sessionScore}&k=${totalKills}&r=${rank}${handle?('&h='+encodeURIComponent(handle)):''}`;
  const u='https://twitter.com/intent/tweet?text='+encodeURIComponent(text)+'&url='+encodeURIComponent(sp);
  try{ window.open(u,'_blank','noopener'); }catch(e){}
}
