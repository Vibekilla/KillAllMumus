function cloudLinked(){
  const me = window.bobinaMe || (typeof bobinaMe!=='undefined' ? bobinaMe : null);
  return !!(me && me.authenticated && me.bcId);
}
