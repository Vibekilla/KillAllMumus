function wrapText(t,x,y,maxw,lh){ const words=t.split(' '); let line='',yy=y; for(const wd of words){ if(ctx.measureText(line+wd+' ').width>maxw){ ctx.fillText(line,x,yy); line=wd+' '; yy+=lh; } else line+=wd+' '; } ctx.fillText(line,x,yy); }

/* ---- HUD panel ---- */
// mobile-landscape HUD: a COMPACT readout packed into the top of the panel, leaving the lower box free
// for the on-screen control panel (weapon/special/melee/bomb are shown on the buttons, so they're dropped here).
