function controlsHtml(){ return CONTROLS.map(c=>`<div class="set-ctrl"><span class="ca">${_hEsc(c[0])}</span><span class="ck">${_hEsc(c[1])}</span></div>`).join(''); }
