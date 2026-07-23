
const cv=document.getElementById('c'), ctx=cv.getContext('2d');
// ---- responsive layout: landscape 960×540 (desktop, UNCHANGED) OR portrait (phones: square playfield on top, HUD + thumb controls below) ----
let W, H, PF, PANEL, COLLECT_LINE, portrait=false;
