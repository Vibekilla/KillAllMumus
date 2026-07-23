function canvasPos(e){ const r=cv.getBoundingClientRect(); const t=e.touches?e.touches[0]:e; return {x:(t.clientX-r.left)*(W/r.width), y:(t.clientY-r.top)*(H/r.height)}; }
