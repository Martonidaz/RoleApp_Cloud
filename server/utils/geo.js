// utils/geo.js
function getDistanciaEmMetros(lat1, lon1, lat2, lon2) {
    const lt1 = parseFloat(lat1), ln1 = parseFloat(lon1);
    const lt2 = parseFloat(lat2), ln2 = parseFloat(lon2);
    if (isNaN(lt1) || isNaN(ln1) || isNaN(lt2) || isNaN(ln2)) return 99999;
    const R = 6371e3; 
    const q1 = lt1 * Math.PI / 180;
    const q2 = lt2 * Math.PI / 180;
    const dq = (lt2 - lt1) * Math.PI / 180;
    const dl = (ln2 - ln1) * Math.PI / 180;
    const a = Math.sin(dq/2) * Math.sin(dq/2) + Math.cos(q1) * Math.cos(q2) * Math.sin(dl/2) * Math.sin(dl/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return Math.floor(R * c);
}

module.exports = { getDistanciaEmMetros };