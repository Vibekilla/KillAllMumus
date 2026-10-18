function lbSetPage(n){ const pc=lbPageCount(); lbPage=Math.max(0,Math.min(pc-1,n)); }
let bobinaMe=null; // {authenticated, bcId, username, ...} from /api/me
window.__setBobinaMe=function(me){ bobinaMe=(me&&me.authenticated)?me:null; };
