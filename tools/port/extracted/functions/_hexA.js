function _hexA(h,a){ const c=_hexRgb(h); return `rgba(${c[0]},${c[1]},${c[2]},${a})`; }
// Power visual — a psychedelic soap-BUBBLE that envelops her: iridescent hue-shifting film, swirling colour ribbons,
// a rotating rainbow rim, glossy sheen and twinkling sparkles. Outfit-tinted outer glow keeps it cohesive; it all grows with power.
// Her body rotates about (p.x, p.y-16), so its visual centre ORBITS that pivot with her facing.
// Every effect that should wrap her body (aura, shield bubbles, weapon charge) centres on this — keeps her dead-centre at any orientation.
