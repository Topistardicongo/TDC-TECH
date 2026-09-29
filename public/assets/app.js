async function loadAccountState(){
  const r=await fetch('/api/me.php',{credentials:'same-origin',cache:'no-store'});const data=await r.json();
  if(!data.authenticated){location.href='/login.php';return null;}
  currentUser=data.user.name;walletBalance=Number(data.balance||0);updateWalletDisplay();
  const nav=document.querySelector('.sb-nav');
  if(data.user.role==='admin'&&nav&&!document.getElementById('admin-entry')){const a=document.createElement('a');a.id='admin-entry';a.className='sb-link';a.href='/admin/';a.textContent='Admin panel';a.style.textDecoration='none';nav.appendChild(a);}
  const head=document.getElementById('dash-header');
  if(head&&!document.getElementById('logout-button')){const b=document.createElement('button');b.id='logout-button';b.className='btn-secondary';b.textContent='Sign out';b.onclick=async()=>{try{await apiPost('/api/auth.php',{action:'logout'});}finally{location.href='/';}};head.appendChild(b);}
  await loadAccountActivity();return data;
}
function safeNode(tag,cls,text){const n=document.createElement(tag);if(cls)n.className=cls;n.textContent=text;return n;}
async function loadAccountActivity(){
  try{
    const res=await fetch('/api/orders.php',{credentials:'same-origin',cache:'no-store'});if(!res.ok)return;const data=await res.json();
    document.querySelectorAll('#view-dashboard .txn-row').forEach(n=>n.remove());
    document.querySelectorAll('#view-dashboard .dsp-row').forEach(n=>n.remove());
    const lists=document.querySelectorAll('#view-dashboard .txn-list');
    lists.forEach(n=>{if(!n.children.length)n.append(safeNode('p','empty-state','No transactions yet.'));});
    if(lists[0]&&data.transactions?.length){lists[0].replaceChildren();data.transactions.slice(0,6).forEach(t=>{const row=safeNode('div','txn-row','');const left=safeNode('div','txn-left','');left.append(safeNode('div','txn-ic',t.kind==='credit'?'£':'•'));const info=safeNode('div','','');info.append(safeNode('p','txn-name',t.note||t.kind));info.append(safeNode('p','txn-meta',new Date(t.created_at+'Z').toLocaleString()));left.append(info);const amt=Number(t.amount);row.append(left,safeNode('span','txn-amt '+(amt>=0?'inc':'out'),(amt>=0?'+':'')+'£'+Math.abs(amt).toFixed(2)+' · '+t.status));lists[0].append(row);});}
    const box=document.getElementById('account-orders');if(box){box.replaceChildren();if(!data.orders?.length)box.append(safeNode('p','empty-state','No orders yet.'));else data.orders.forEach(o=>{const card=safeNode('article','order-card','');card.append(safeNode('strong','',`#${o.id} · ${o.service} · £${Number(o.amount).toFixed(2)}`));card.append(safeNode('p','',`${o.description} · ${o.status} · ${new Date(o.created_at+'Z').toLocaleString()}`));if(o.admin_note)card.append(safeNode('p','order-note',o.admin_note));box.append(card);});}
    const proxy=[...(data.orders||[])].find(o=>String(o.service).toLowerCase().includes('proxy')&&o.admin_note);if(proxy){const out=document.getElementById('proxy-cred-output');if(out)out.textContent=proxy.admin_note;}
    document.querySelectorAll('#view-dashboard .stat-card-val').forEach(n=>{if(n.id!=='home-wallet')n.textContent='0';});
    document.querySelectorAll('#view-dashboard .metric-val').forEach(n=>n.textContent=n.textContent.includes('£')?'£0.00':'0');
    document.querySelectorAll('#view-dashboard .metric-sub').forEach(n=>n.textContent='No account activity yet');
  }catch(_e){}
}
const routes={'home':'/dashboard.php','social-ads':'/services/social-ads.php','music':'/services/music.php','verification':'/services/verification.php','web-dev':'/services/web-dev.php','account-mgmt':'/services/account-mgmt.php','press':'/services/press.php','smm':'/services/smm.php','numbers':'/services/numbers.php','bots':'/services/bots.php','proxies':'/services/proxies.php'};
if(typeof window.navTo==='function'){
  const originalNavTo=window.navTo;
  window.navTo=function(page){originalNavTo(page);const route=routes[page];if(route&&location.pathname!==route)history.pushState({page},'',route);};
}
window.addEventListener('popstate',()=>{const page=Object.keys(routes).find(k=>routes[k]===location.pathname)||document.body.dataset.service||'home';if(typeof window.navTo==='function')window.navTo(page);});
window.addEventListener('DOMContentLoaded',async()=>{
  const path=location.pathname;
  if(path==='/dashboard.php'||path.startsWith('/services/')){
    const data=await loadAccountState();if(!data)return;
    const dash=document.getElementById('view-dashboard');if(dash){document.getElementById('view-landing')?.remove();dash.style.display='flex';dash.classList.add('active');document.getElementById('chat-fab').style.display='flex';const fn=document.getElementById('float-nav');if(fn)fn.style.display='flex';}
    const target=document.body.dataset.service||'home';if(typeof navTo==='function')navTo(target);
  }
});
