function poseParams(p, t){
  let vx=0,vy=0,lean=0,expr='smile',rot=0,bounce=0,sway=0,sq=1;
  if(p===1){ // Dance — full-body dance with swinging limbs (the ONLY pose with limb motion)
    bounce=Math.abs(Math.sin(t*0.15))*15; sway=Math.sin(t*0.11)*18; rot=Math.sin(t*0.11)*0.13; vx=Math.sin(t*0.3)*3.6; vy=Math.cos(t*0.42)*1.6; lean=Math.sin(t*0.11)*0.5; expr='uwu'; }
  else if(p===2){ // Twirl — a clean pirouette spin in place (no flailing limbs)
    rot=t*0.05; bounce=Math.abs(Math.sin(t*0.15))*3.5; expr='annoyed'; }
  else if(p===3){ // Bounce — big vertical hops with squash-and-stretch
    bounce=Math.abs(Math.sin(t*0.2))*26; sq=1+Math.sin(t*0.2)*0.1; expr='smile'; }
  else if(p===4){ // >v< Cheer — happy side-to-side wiggle
    const s=Math.sin(t*0.12); sway=s*13; lean=s*0.5; rot=s*0.06; bounce=Math.abs(Math.sin(t*0.24))*4.5; expr='squee'; }
  else if(p===5){ // This Is Fine — sit calmly and sip coffee while everything burns (arm + fire drawn in drawPoseProp)
    bounce=(1-Math.cos(t*0.05))*1.4; lean=0.04; expr='giggle'; }
  else { // Idle — barely-there breathing sway
    bounce=(1-Math.cos(t*0.045))*1.6; sway=Math.sin(t*0.035)*2; expr='smile'; }
  return {vx,vy,lean,expr,rot,bounce,sway,sq};
}
