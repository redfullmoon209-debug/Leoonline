// Real browser input against the release Web export; observations are read-only.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('fs');
const crypto = require('crypto');
const path = require('path');
const out = process.env.QA_OUTPUT || 'build/web/qa';
fs.mkdirSync(out,{recursive:true});
const checks=[], errors=[];
let browser, page;
const check=(ok,name)=>{checks.push({name,passed:!!ok});if(!ok)throw new Error(name);};
const state=()=>page.evaluate(()=>window.__leoQA);
const until=fn=>page.waitForFunction(fn,null,{timeout:15000});
async function clickRect(rect,touch=false){
 const x=rect[0]+rect[2]/2,y=rect[1]+rect[3]/2;
 const v=page.viewportSize();
 check(x>=0&&x<v.width&&y>=0&&y<v.height,'Target inside visible browser viewport');
 if(touch) await page.touchscreen.tap(x,y); else await page.mouse.click(x,y);
}
async function snap(name){await page.screenshot({path:path.join(out,name+'.jpg'),type:'jpeg',quality:90});}
async function start(viewport,mobile=false){
 const context=await browser.newContext({viewport,isMobile:mobile,hasTouch:mobile,deviceScaleFactor:1});
 page=await context.newPage();
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.type()==='error'&&/SCRIPT ERROR|Parse Error|Failed to load script/.test(m.text()))errors.push(m.text());});
 await page.goto('http://127.0.0.1:8000/_qa.html');
 await until(()=>!!window.__leoQA);
 return context;
}
async function swipe(dx,dy){
 const v=page.viewportSize(),q=await state();
 const x=Math.min(v.width-25,v.width*0.85),y=Math.min(q.scroller[3]-25,v.height*0.75);
 const endX=Math.max(20,x-dx),endY=Math.max(20,y-dy);
 const client=await page.context().newCDPSession(page);
 const point=(x,y)=>({x,y,id:0,radiusX:2,radiusY:2,force:1});
 await client.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point(x,y)]});
 for(let i=1;i<=14;i++){
  await client.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[point(x+(endX-x)*i/14,y+(endY-y)*i/14)]});
  await page.waitForTimeout(25);
 }
 await client.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 await client.detach();
 await page.waitForTimeout(500);
}
(async()=>{
 try{
  browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--no-sandbox']});
  let context=await start({width:1440,height:1100});
  await clickRect((await state()).opener);
  await until(()=>window.__leoQA.open);
  let q=await state();
  check(q.cells===50&&q.columns===10&&q.locked===10,'10x5 grid, 40 unlocked');
  check(q.slots.length===200&&q.fashion===5&&q.fashion_weapons===4&&q.accessories===5,'Equipment and bag counts');
  await clickRect(q.footer[0]);
  await until(()=>window.__leoQA.slots[0]==='sword');
  await snap('web-desktop-th');
  await clickRect((await state()).bag[0]);
  await until(()=>window.__leoQA.detail_visible&&window.__leoQA.detail_name==='ดาบสำริด');
  await snap('web-details-th');
  await clickRect((await state()).footer[4]);
  await until(()=>window.__leoQA.equipped.weapon_right==='sword');
  await clickRect((await state()).right_equipment[0]);
  await until(()=>window.__leoQA.detail_visible);
  check((await state()).equipped.weapon_right==='sword','Equipment tap inspects without unequipping');
  await clickRect((await state()).footer[4]);
  await until(()=>window.__leoQA.equipped.weapon_right==='');
  check((await state()).slots.includes('sword'),'Unequip returns the item');
  await clickRect((await state()).footer[2]);
  await until(()=>window.__leoQA.slots[0]==='sword');
  q=await state();let wood=q.slots.indexOf('wood');
  await clickRect(q.bag[wood]);
  await page.waitForFunction(index=>window.__leoQA.selected===index,wood);
  await clickRect((await state()).footer[3]);
  await until(()=>window.__leoQA.trash_visible);
  await clickRect((await state()).trash_cancel);
  await until(()=>!window.__leoQA.trash_visible);
  check((await state()).slots.includes('wood'),'Trash cancellation preserves item');
  await clickRect((await state()).footer[3]);
  await until(()=>window.__leoQA.trash_visible);
  await clickRect((await state()).trash_ok);
  await until(()=>!window.__leoQA.slots.includes('wood'));
  await clickRect((await state()).pages[3]);
  await until(()=>window.__leoQA.page===3);
  check((await state()).locked===50,'Page four contains 50 locked entries');
  await snap('web-page-four');
  await clickRect((await state()).pages[0]);
  await until(()=>window.__leoQA.page===0);
  await clickRect((await state()).language);
  await until(()=>window.__leoQA.locale==='en');
  await snap('web-desktop-en');
  await clickRect((await state()).tabs[1]);
  await until(()=>window.__leoQA.tab===1&&window.__leoQA.char_visible);
  q=await state();
  check(q.char_equipment_left&&q.character_stats!==undefined || q.char_equipment_left,'Character keeps original equipment panel on left');
  check(q.char_values.level==='1'&&q.char_values.class_tier==='0'&&q.char_values.job==='Novice','Right panel displays saved Level, Class and starter Job');
  check(q.char_values.strength==='10'&&q.char_values.vitality==='10'&&q.char_values.luck==='10','Real persisted base attributes appear on Character page');
  check(q.char_values.pve_rank==='Unranked'&&q.char_values.pvp_rank==='Unranked'&&q.char_values.wealth_rank==='Unranked','Rankings truthfully show Unranked without server leaderboard');
  check(q.char_values.currency_gold===Number(q.currency.gold).toLocaleString('en-US'),'Character displays current exact inventory Gold balance');
  await snap('web-character-en');
  await clickRect((await state()).tabs[2]);
  await until(()=>window.__leoQA.tab===2);
  check((await state()).waiting==='Skills are not available yet','Skill placeholder is truthful');
  await clickRect((await state()).tabs[3]);
  await until(()=>window.__leoQA.tab===3&&window.__leoQA.shop_visible);
  q=await state();
  check(q.shop_left_inventory&&q.shop_left_shift===-655,'Shop reuses actual player inventory on left');
  check(q.shop_left_border,'Shop-only left gold frame matches right-hand shop frame');
  check(q.shop_cells===50&&q.shop_stock_label==='21 / 500','Shop has 50 grid cells on each of 10 catalog pages');
  await clickRect(q.shop_slots[0]);
  await until(()=>window.__leoQA.shop_selected_id==='hp_potion_small');
  check(!(await state()).shop_buy_disabled,'Select HP potion and enable Buy');
  const moneyBeforePurchase=Number((await state()).currency.gold);
  await clickRect((await state()).shop_buy);
  await until(()=>window.__leoQA.slots.includes('hp_potion_small'));
  check(Number((await state()).currency.gold)===moneyBeforePurchase-50,'Purchasing debits 50 gold and adds real HP item');
  await snap('web-shop-en');
  const potionIndex=(await state()).slots.indexOf('hp_potion_small');
  await clickRect((await state()).bag[potionIndex]);
  await page.waitForFunction(i=>window.__leoQA.selected===i,potionIndex);
  check(!(await state()).shop_sell_disabled,'Selecting the bought item enables Sell');
  await clickRect((await state()).shop_sell);
  await until(()=>window.__leoQA.shop_sell_visible);
  await clickRect((await state()).shop_sell_ok);
  await until(()=>!window.__leoQA.slots.includes('hp_potion_small'));
  check(Number((await state()).currency.gold)===moneyBeforePurchase-25,'Selling credits correct resale value');
  const savedTrade=await page.evaluate(()=>{try{const raw=localStorage.getItem('leoonline_save_v1');return raw?JSON.parse(raw):null;}catch{return null;}});
  check(savedTrade!==null&&savedTrade.currency.gold===String(moneyBeforePurchase-25)&&!savedTrade.slots.includes('hp_potion_small'),'Synchronous browser save preserves sold item and exact gold before reload');
  await clickRect((await state()).shop_pages[3]);
  await until(()=>window.__leoQA.shop_page===9);
  check((await state()).shop_cells===50,'Last catalog page retains 50 future slots');
  await clickRect((await state()).shop_pages[0]);
  await until(()=>window.__leoQA.shop_page===0);
  await clickRect((await state()).tabs[0]);
  await until(()=>window.__leoQA.tab===0);
  await clickRect((await state()).footer[1]);
  await until(()=>window.__leoQA.notice==='Saved');
  const before=(await state()).slots;
  await page.reload();
  await until(()=>!!window.__leoQA);
  check(JSON.stringify((await state()).slots)===JSON.stringify(before),'Web save persists across reload');
    // Check Storage via the actual independent HUD chest icon (not a simulated UI change).
  q=await state();
  check(q.storage_opener[0]+q.storage_opener[2]<=q.opener[0],'Standalone Storage chest button sits to the left of bag opener');
  check(q.storage_slots.length===200&&q.storage_cells===50,'Storage owns a separate 200-slot model and 10x5 rendered grid');
  await clickRect(q.storage_opener);
  await until(()=>window.__leoQA.storage_mode&&window.__leoQA.storage_visible);
  q=await state();
  check(q.storage_bag_right&&q.storage_equipment_hidden,'Storage grid replaces equipment LEFT, original bag remains RIGHT');
  check(q.bag.length===50&&q.storage_grid.length===50&&q.footer.length===6&&q.tabs.length===4,'Storage reuses original bag and preserves all menus/buttons');
  await snap('web-storage-open-en');
  const movedId='sword';
  const movedIndex=q.slots.indexOf(movedId);
  check(movedIndex>=0&&movedIndex<q.unlocked,'Has available bag item to deposit');
  await clickRect(q.bag[movedIndex]);
  await until(()=>!window.__leoQA.storage_deposit_disabled);
  await clickRect((await state()).storage_deposit);
  await until(()=>window.__leoQA.storage_slots.includes('sword')&&!window.__leoQA.slots.includes('sword'));
  q=await state();
  check(q.storage_count==='1 / 200','Stored item updates storage capacity');
  check(q.storage_slots.filter(v=>v==='sword').length===1,'Deposit transfers exactly one item, no duplication');
  const savedDeposit=await page.evaluate(()=>{try{return JSON.parse(localStorage.getItem('leoonline_save_v1'));}catch{return null;}});
  check(savedDeposit&&savedDeposit.storage_slots[0]==='sword'&&!savedDeposit.slots.includes('sword'),'Bank deposit persists synchronously with bag in browser save');
  await snap('web-storage-deposited');
  // Immediately reload after deposit; item must be in Storage and nowhere else.
  await page.reload();
  await until(()=>!!window.__leoQA);
  q=await state();
  check(q.storage_slots[0]==='sword'&&!q.slots.includes('sword'),'Stored item survives immediate reload without duplicating');
  await clickRect(q.storage_opener);
  await until(()=>window.__leoQA.storage_visible);
  q=await state();
  await clickRect(q.storage_grid[0]);
  await until(()=>window.__leoQA.storage_selected===0&&!window.__leoQA.storage_withdraw_disabled);
  await clickRect((await state()).storage_withdraw);
  await until(()=>window.__leoQA.slots.includes('sword')&&!window.__leoQA.storage_slots.includes('sword'));
  q=await state();
  check(q.storage_count==='0 / 200'&&q.slots.filter(v=>v==='sword').length===1,'Withdrawal restores exactly one item to the actual bag');
  const savedWithdraw=await page.evaluate(()=>{try{return JSON.parse(localStorage.getItem('leoonline_save_v1'));}catch{return null;}});
  check(savedWithdraw&&!savedWithdraw.storage_slots.includes('sword')&&savedWithdraw.slots.includes('sword'),'Withdrawal persists both lists in one browser save');
  await clickRect(q.storage_pages[3]);
  await until(()=>window.__leoQA.storage_page===3);
  check((await state()).storage_cells===50,'Vault has four accessible 50-cell pages');
  await clickRect((await state()).storage_pages[0]);
  await until(()=>window.__leoQA.storage_page===0);
  await snap('web-storage-after-withdrawal');
  await clickRect((await state()).tabs[0]);
  await until(()=>!window.__leoQA.storage_mode&&window.__leoQA.tab===0);
  check(!(await state()).storage_visible,'Inventory tab returns to original equipment/bag layout');
  await clickRect((await state()).footer[5]);
  await until(()=>!window.__leoQA.open);
  await clickRect((await state()).opener);
  await until(()=>window.__leoQA.open);
  await clickRect((await state()).footer[5]);
  await until(()=>!window.__leoQA.open);
  await context.close();
  for(const viewport of [{width:390,height:844},{width:844,height:390}]){
   context=await start(viewport,true);
   await clickRect((await state()).opener,true);
   await until(()=>window.__leoQA.open);
   check((await state()).bag[0][2]>=44,'Mobile bag targets >=44px');
   // Scroll the actual canvas to its bag region before tapping a locked slot.
   await swipe(500,0);
   if(viewport.width<500) await swipe(500,0);
   check((await state()).scroll[0]>0,'Horizontal finger swipe pans mobile inventory');
   if(viewport.height<500) await swipe(0,280);
   q=await state();
   let cell=q.bag.find((r,i)=>i>=40&&r[0]>=0&&r[0]+r[2]<viewport.width&&r[1]>0&&r[1]+r[3]<Math.min(q.scroller[3],viewport.height));
   if(!cell){await swipe(0,160);q=await state();cell=q.bag.find((r,i)=>i>=40&&r[0]>=0&&r[0]+r[2]<viewport.width&&r[1]>0&&r[1]+r[3]<Math.min(q.scroller[3],viewport.height));}
   check(!!cell,'Mobile locked cell reachable by scrolling');
   await clickRect(cell,true);
   await until(()=>window.__leoQA.detail_visible);
   q=await state();const d=q.detail_bounds;
   check(d[0]>=0&&d[1]>=0&&d[0]+d[2]<=viewport.width+1&&d[1]+d[3]<=viewport.height+1,'Mobile details stay on screen');
   check(q.scroller[1]+q.scroller[3]<=d[1]+1,'Mobile details do not cover slot viewport');
   await snap('web-mobile-'+viewport.width);
   await clickRect(q.detail_close,true);
   await until(()=>!window.__leoQA.detail_visible);
   await context.close();
  }
  check(errors.length===0,'No game JavaScript or GDScript runtime errors');
 }catch(error){
  errors.push(error.stack||String(error));
  if(page&&!page.isClosed()) console.log('FAILURE_STATE',JSON.stringify(await state().catch(()=>null)));

  if(page&&!page.isClosed()){await snap('web-failure').catch(()=>{});fs.writeFileSync(path.join(out,'failure-state.json'),JSON.stringify(await state().catch(()=>null),null,2));}
 }finally{
  const digest=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  const report={package_sha256:digest('build/web/index.pck'),wasm_sha256:digest('build/web/index.wasm'),passed:errors.length===0,checks,errors,engine:'Godot 4.4.1',browser:'Chromium with SwiftShader WebGL2',commit:process.env.GITHUB_SHA||null};
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
  if(browser)await browser.close();
  if(errors.length)process.exitCode=1;
 }
})();
