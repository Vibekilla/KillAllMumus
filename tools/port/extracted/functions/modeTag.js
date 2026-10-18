function modeTag(){ return diffName()+(ngPlus>0?('+'+ngPlus):''); }         // e.g. HELL+2 for the leaderboard
const MAX_NG=100;   // New Game+ is capped at 100 cycles
// human-readable score: 1.2K · 3.45M · 100B · 100T … so scores can climb forever and still fit
