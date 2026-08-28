'use client';
import { useMemo, useState } from 'react';

type Vlan={id:number;name:string;color:string};
type Port={number:number;status:'up'|'down';speed?:string;vlan:number;tagged?:number[];poe?:string;device?:string};
type Switch={name:string;model:string;ip:string;location:string;ports:Port[]};

const vlans:Vlan[]=[
  {id:10,name:'Dante Primary',color:'#27c6a3'},{id:20,name:'Video',color:'#ff9d42'},
  {id:30,name:'Control',color:'#8ac65b'},{id:40,name:'NDI',color:'#b281e8'},
  {id:1,name:'Management',color:'#8b98a9'}
];
const switches:Switch[]=[
 {name:'Stage Left',model:'M4250-26G4XF-PoE+',ip:'10.21.0.21',location:'Main Stage · Rack A',ports:[
  {number:1,status:'up',speed:'1G',vlan:10,poe:'6.8 W',device:'Rio3224-D2'},{number:2,status:'up',speed:'1G',vlan:10,poe:'4.2 W',device:'QL5 Console'},
  {number:3,status:'up',speed:'1G',vlan:20,device:'PIXERA-01'},{number:4,status:'up',speed:'1G',vlan:20,device:'Disguise RX'},
  {number:5,status:'up',speed:'1G',vlan:30,poe:'7.4 W',device:'Lighting Node'},{number:6,status:'down',vlan:30},
  {number:7,status:'up',speed:'1G',vlan:1,device:'Rack Mac Mini'},{number:8,status:'up',speed:'10G',vlan:1,tagged:[10,20,30,40],device:'FOH Uplink'},
  {number:9,status:'down',vlan:10},{number:10,status:'down',vlan:10},{number:11,status:'up',speed:'1G',vlan:40,poe:'12.1 W',device:'NDI Camera 1'},
  {number:12,status:'up',speed:'1G',vlan:40,poe:'11.8 W',device:'NDI Camera 2'}]},
 {name:'Front of House',model:'M4350-24X4V',ip:'10.21.0.22',location:'FOH · Network Rack',ports:[
  {number:1,status:'up',speed:'1G',vlan:10,device:'CL5 Console'},{number:2,status:'up',speed:'1G',vlan:10,device:'Dante Virtual Soundcard'},
  {number:3,status:'up',speed:'10G',vlan:20,device:'Media Server A'},{number:4,status:'up',speed:'10G',vlan:20,device:'Media Server B'},
  {number:5,status:'up',speed:'1G',vlan:30,device:'GrandMA3'},{number:6,status:'down',vlan:30},
  {number:7,status:'up',speed:'1G',vlan:1,device:'Engineer Laptop'},{number:8,status:'up',speed:'10G',vlan:1,tagged:[10,20,30,40],device:'Stage Uplink'}]}
];
const vlanFor=(id:number)=>vlans.find(v=>v.id===id)??vlans[4];

export default function Home(){
 const [filter,setFilter]=useState<'all'|number|'trunks'|'offline'>('all');
 const [query,setQuery]=useState(''); const [selected,setSelected]=useState<{sw:Switch;port:Port}|null>(null);
 const visible=useMemo(()=>switches.map(sw=>({...sw,ports:sw.ports.filter(p=>{
  const text=`${sw.name} ${sw.model} ${sw.ip} ${p.number} ${p.device??''} ${vlanFor(p.vlan).name}`.toLowerCase();
  return text.includes(query.toLowerCase())&&(filter==='all'||(filter==='trunks'?!!p.tagged?.length:filter==='offline'?p.status==='down':p.vlan===filter));
 })})).filter(sw=>sw.ports.length),[filter,query]);
 const active=switches.flatMap(sw=>sw.ports).filter(p=>p.status==='up').length;
 return <main className="app-shell">
  <header className="topbar"><div className="brand"><span className="brand-mark">N</span><div><strong>NETGEAR</strong><small>AV NETWORK</small></div></div><div className="network-state"><span className="pulse"/> Network healthy</div><button className="icon-button" aria-label="Settings">⚙</button></header>
  <section className="hero"><div><p className="eyebrow">LIVE OVERVIEW</p><h1>Switchboard</h1><p className="subtitle">Every port. Every VLAN. One clear view.</p></div><div className="stats"><div><span className="stat-dot"/><strong>{switches.length}</strong><small>SWITCHES</small></div><div><strong>{active}</strong><small>PORTS ACTIVE</small></div><div><strong>{vlans.length}</strong><small>VLANS</small></div></div></section>
  <section className="controls"><label className="search"><span>⌕</span><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Search switch, port, device or VLAN…"/></label><div className="filters" aria-label="Filter ports"><button className={filter==='all'?'active':''} onClick={()=>setFilter('all')}>All ports</button>{vlans.slice(0,4).map(v=><button key={v.id} className={filter===v.id?'active':''} onClick={()=>setFilter(v.id)}><i style={{background:v.color}}/>{v.name.replace(' Primary','')}</button>)}<button className={filter==='trunks'?'active':''} onClick={()=>setFilter('trunks')}>◫ Trunks</button><button className={filter==='offline'?'active':''} onClick={()=>setFilter('offline')}>○ Offline</button></div></section>
  <section className="switch-list">{visible.map(sw=><article className="switch-card" key={sw.ip}>
   <header className="switch-header"><div className="switch-title"><span className="switch-icon">▤</span><div><h2>{sw.name}</h2><p>{sw.location}</p></div></div><div className="switch-meta"><span className="online"><i/>ONLINE</span><strong>{sw.model}</strong><code>{sw.ip}</code></div></header>
   <div className="port-grid">{sw.ports.map(port=>{const vlan=vlanFor(port.vlan),trunk=!!port.tagged?.length;return <button key={port.number} className={`port ${port.status} ${trunk?'trunk':''}`} onClick={()=>setSelected({sw,port})} style={{'--port-color':vlan.color} as React.CSSProperties}><span className="port-top"><b>{port.number}</b><i className="link"/></span><span className="jack"><i/><i/><i/><i/><i/><i/><i/><i/></span><span className="vlan-id">{trunk?'TRUNK':`VLAN ${port.vlan}`}</span><strong>{trunk?'Multi-VLAN':vlan.name}</strong><small>{port.device??'Not connected'}</small></button>})}</div>
   <footer><span><i className="legend-up"/>{sw.ports.filter(p=>p.status==='up').length} active</span><span><i className="legend-down"/>{sw.ports.filter(p=>p.status==='down').length} offline</span><button>View switch details →</button></footer>
  </article>)}{!visible.length&&<div className="empty"><strong>No matching ports</strong><span>Try a different search or filter.</span></div>}</section>
  <aside className="legend"><strong>VLAN COLOR KEY</strong>{vlans.map(v=><span key={v.id}><i style={{background:v.color}}/>{v.id} · {v.name}</span>)}</aside>
  {selected&&<div className="modal-backdrop" onMouseDown={()=>setSelected(null)}><section className="port-sheet" role="dialog" aria-modal="true" onMouseDown={e=>e.stopPropagation()}><button className="close" onClick={()=>setSelected(null)} aria-label="Close">×</button><div className="sheet-handle"/><p className="eyebrow">{selected.sw.name.toUpperCase()}</p><h2>Port {selected.port.number}</h2><div className="detail-status"><span className={`big-dot ${selected.port.status}`}/><strong>{selected.port.status==='up'?'Connected':'Not connected'}</strong>{selected.port.speed&&<span>{selected.port.speed}</span>}</div><dl><div><dt>Device</dt><dd>{selected.port.device??'—'}</dd></div><div><dt>Native VLAN</dt><dd><i style={{background:vlanFor(selected.port.vlan).color}}/>{selected.port.vlan} · {vlanFor(selected.port.vlan).name}</dd></div><div><dt>Tagged VLANs</dt><dd>{selected.port.tagged?.join(', ')||'None'}</dd></div><div><dt>PoE draw</dt><dd>{selected.port.poe??'—'}</dd></div><div><dt>Switch</dt><dd>{selected.sw.model}</dd></div></dl><p className="readonly-note">Read-only monitoring · Updated just now</p></section></div>}
 </main>;
}
