function bossWepMul(){ const t=run && BOSS_WEP_DEBUFF[run.weapon]; return t ? (t[difficulty]||t[0]) : 1; }
