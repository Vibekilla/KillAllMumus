function bobinaSay(text, frames, hurt){ if(dialog && !dialog.hurt) return; dialog={ boss:null, queue:[{w:1,t:text}], i:0, timer:frames||60, hurt:true }; }
