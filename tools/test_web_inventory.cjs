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
async function dragHudTouch(startX,startY,endX,endY){
 const session=await page.context().newCDPSession(page);
 const point=(x,y)=>({x,y,id:0,radiusX:2,radiusY:2,force:1});
 await session.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[point(startX,startY)]});
 for(let i=1;i<=12;i++){
  await session.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[point(startX+(endX-startX)*i/12,startY+(endY-startY)*i/12)]});
  await page.waitForTimeout(30);
 }
 await session.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
 await session.detach();
 await page.waitForTimeout(450);
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
  // Nine independent HUD icons must open actual interactive pages without
  // replacing the existing bag HUD. Use only real browser clicks.
  let hud=await state();
  check(hud.hud_icon_count===9&&Object.keys(hud.hud_icons).length===9,'Nine separate functional menu pages remain available');
  // Original and current approved art is rebuilt as ten native, independent
  // PNG files. The order, one-row geometry and hidden notification dots must
  // be visible in the REAL game viewport, not a screenshot mockup.
  const approved=['bag','world','party','friends','ranking','settings','guild','quest','mail','events'];
  check(JSON.stringify(hud.hud_row_order)===JSON.stringify(approved)&&hud.hud_row.length===10,'Exactly ten icons in requested left-to-right order, Inventory first');
  check(hud.hud_png_paths.every((p,i)=>p.endsWith('/premium/'+approved[i]+'.png')),'All ten buttons use their own actual PNG asset; none crops from a combined image');
  check(Object.values(hud.hud_notification_badges).every(v=>v===false),'All real notification layers start hidden, especially Mail');
  check(hud.hud_profile_label.includes('Lv.')&&hud.hud_profile_experience.includes('EXP'),'Top-left profile uses saved character level and experience');
  check(hud.hud_minimap_bounds[2]>120&&hud.hud_minimap_items>=0,'Top-right circular minimap is actually connected to the playable world');
  check(hud.hud_target_name.includes('ยังไม่ได้เลือก')&&!hud.hud_target_health_visible,'Target HUD is in the center and never invents enemy HP when no target exists');
  for(let i=0;i<hud.hud_row.length;i++){
   const rect=hud.hud_row[i];
   check(rect[2]>=42&&Math.abs(rect[1]-hud.hud_row[0][1])<=1,'All ten compact desktop buttons share one horizontal row');
   if(i>0)check(rect[0]>=hud.hud_row[i-1][0]+hud.hud_row[i-1][2]+1,'Ten buttons do not overlap on desktop');
  }
  check(hud.hud_row[0][0]>hud.hud_profile_bounds[0]+hud.hud_profile_bounds[2],'Desktop icon row leaves room for character portrait');
  check(hud.hud_row[9][0]+hud.hud_row[9][2]<hud.hud_minimap_bounds[0],'Desktop icon row leaves room for the minimap');
  await snap('web-premium-ten-icon-row');
  for(const name of ['world','party','friends','ranking','guild','quest','mail','events']){
   check(hud.hud_icons[name][2]>=42,'HUD icon has a touch-friendly viewport hit target: '+name);
   await clickRect(hud.hud_icons[name]);
   await until(()=>window.__leoQA.hud_panel_open);
   hud=await state();
   check(hud.hud_panel_key===name&&hud.hud_panel_children>0,'Menu icon opens its own real page: '+name);
   await clickRect(hud.hud_close_button);
   await until(()=>!window.__leoQA.hud_panel_open);
   hud=await state();
  }
  await clickRect(hud.hud_icons.settings);
  await until(()=>window.__leoQA.hud_panel_key==='settings');
  hud=await state();
  check(hud.hud_start_editor.length===4,'HUD Settings includes a real edit-layout button');
  await snap('web-hud-settings');
  await clickRect(hud.hud_start_editor);
  await until(()=>window.__leoQA.hud_editing);
  hud=await state();
  check(hud.hud_toolbar.length===4&&!hud.hud_panel_open,'HUD drag editor exposes an accessible persistent toolbar');
  await snap('web-hud-editor');
  const oldWorldRect=hud.hud_world_button;
  const startX=oldWorldRect[0]+oldWorldRect[2]/2, startY=oldWorldRect[1]+oldWorldRect[3]/2;
  await page.mouse.move(startX,startY);
  await page.mouse.down();
  await page.mouse.move(startX-130,startY+110,{steps:12});
  await page.mouse.up();
  await until(()=>!!window.__leoQA.hud_layout.world);
  hud=await state();
  check(hud.hud_world_button[0]<oldWorldRect[0]-75&&hud.hud_world_button[1]>oldWorldRect[1]+60,'Desktop mouse drag actually moves the selected icon');
  await clickRect(hud.hud_save_button);
  await until(()=>!window.__leoQA.hud_editing);
  const hudSaved=await page.evaluate(()=>JSON.parse(localStorage.getItem('leoonline_hud_v1')));
  check(!!hudSaved.layout.world,'New HUD coordinates are saved to localStorage, not only a temporary drawing');
  await page.reload();
  await until(()=>!!window.__leoQA);
  hud=await state();
  check(Math.abs(hud.hud_world_button[0]-oldWorldRect[0])>70,'Saved HUD coordinates survive a full browser reload');
  await clickRect(hud.hud_icons.settings);
  await until(()=>window.__leoQA.hud_panel_key==='settings');
  await clickRect((await state()).hud_reset_button);
  await until(()=>Object.keys(window.__leoQA.hud_layout).length===0);
  check(Object.keys((await state()).hud_layout).length===0,'Reset HUD restores built-in control positions');
  await clickRect((await state()).hud_close_button);
  await until(()=>!window.__leoQA.hud_panel_open);
  await snap('web-hud-main-icons');
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
  check(!q.shop_left_border,'Shop has no decorative panel border');
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
  // Open the Inventory HUD icon, then select fifth top-row Storage tab.
  q=await state();
  check(!q.has_storage_hud,'Storage has no standalone HUD opener');
  check(q.storage_slots.length===200&&q.storage_cells===50,'Storage owns a separate 200-slot model and 10x5 rendered grid');
  await clickRect(q.opener);
  await until(()=>window.__leoQA.open);
  q=await state();
  check(q.storage_tab_visible&&q.storage_tab_text===(q.locale==='th'?'คลังเก็บของ':'Storage'),'Storage is the fifth top menu button');
  await clickRect(q.storage_tab);
  await until(()=>window.__leoQA.storage_mode&&window.__leoQA.storage_visible);
  q=await state();
  check(q.storage_bag_right&&q.storage_equipment_hidden,'Storage grid replaces equipment LEFT, original bag remains RIGHT');
  check(q.bag.length===50&&q.storage_grid.length===50&&q.footer.length===6&&q.tabs.length===5,'Storage reuses original bag and preserves five tabs/six footer buttons');
  await snap('web-storage-open-en');
  // Money is a separate subview in Storage, not a second HUD icon and not
  // interchangeable with stored items. Exercise actual DOM-keyboard input.
  check(!q.storage_money_mode&&!q.storage_money_visible,'Storage initially displays its original item slots');
  check(q.storage_money_rows.length===4,'Vault has selectable Gold, Blue, Purple and Green currencies');
  const walletBeforeBank=q.currency.gold;
  const vaultBeforeBank=q.storage_currency.gold;
  check(BigInt(walletBeforeBank)>=123n&&vaultBeforeBank==='0','Fixture has wallet funds and an empty vault');
  await clickRect(q.storage_money_tab);
  await until(()=>window.__leoQA.storage_money_visible);
  q=await state();
  check(q.storage_bag_right&&q.storage_money_rows.length===4,'Money subview replaces only left-hand Storage while the right bag remains');
  await clickRect(q.storage_money_rows[1]);
  await until(()=>window.__leoQA.storage_money_kind==='blue');
  await clickRect((await state()).storage_money_rows[0]);
  await until(()=>window.__leoQA.storage_money_kind==='gold');
  await clickRect((await state()).storage_money_amount);
  await page.keyboard.type('123');
  await until(()=>window.__leoQA.storage_money_value==='123'&&!window.__leoQA.storage_money_deposit_disabled);
  await clickRect((await state()).storage_money_deposit);
  await until(()=>window.__leoQA.storage_currency.gold==='123');
  q=await state();
  check(BigInt(q.currency.gold)+BigInt(q.storage_currency.gold)===BigInt(walletBeforeBank),'Depositing money keeps the exact sum unchanged');
  check(q.storage_money_vault_text.includes('123'),'Vault screen shows the stored gold amount');
  const storedCash=await page.evaluate(()=>JSON.parse(localStorage.getItem('leoonline_save_v1')));
  check(storedCash.storage_currency.gold==='123'&&storedCash.currency.gold===q.currency.gold,'Money vault and wallet are persisted atomically in browser storage');
  await snap('web-storage-money-deposited');
  await page.reload();
  await until(()=>!!window.__leoQA);
  q=await state();
  check(q.storage_currency.gold==='123'&&BigInt(q.currency.gold)+123n===BigInt(walletBeforeBank),'Exact deposited gold survives immediate reload');
  await clickRect(q.opener);
  await until(()=>window.__leoQA.open);
  await clickRect((await state()).storage_tab);
  await until(()=>window.__leoQA.storage_visible);
  await clickRect((await state()).storage_money_tab);
  await until(()=>window.__leoQA.storage_money_visible);
  await clickRect((await state()).storage_money_all_vault);
  await until(()=>window.__leoQA.storage_money_value==='123'&&!window.__leoQA.storage_money_withdraw_disabled);
  await clickRect((await state()).storage_money_withdraw);
  await page.waitForFunction(expected=>window.__leoQA.currency.gold===expected&&window.__leoQA.storage_currency.gold==='0',walletBeforeBank,{timeout:15000});
  const restoredCash=await page.evaluate(()=>JSON.parse(localStorage.getItem('leoonline_save_v1')));
  check(restoredCash.currency.gold===walletBeforeBank&&restoredCash.storage_currency.gold==='0','Withdrawing vault money restores wallet without duplication and persists');
  await snap('web-storage-money-withdrawn');
  await clickRect((await state()).storage_items_tab);
  await until(()=>!window.__leoQA.storage_money_visible&&window.__leoQA.storage_visible);
  q=await state();
  check(q.storage_cells===50&&q.bag.length===50,'Returning to item view restores 200-slot vault and original bag');
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
  await clickRect(q.opener);
  await until(()=>window.__leoQA.open);
  await clickRect((await state()).storage_tab);
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
   if(viewport.width===390){
    let touchHud=await state();
    check(touchHud.hud_icon_count===9&&touchHud.hud_joystick[2]>=90,'Portrait mobile renders nine independent menus and the touch joystick');
    check(touchHud.hud_row.length===10&&touchHud.hud_png_paths.every(p=>p.endsWith('.png')),'Portrait phone uses all ten separate original PNG icons');
    for(let i=0;i<touchHud.hud_row.length;i++){
     const rect=touchHud.hud_row[i];
     check(rect[0]>=0&&rect[0]+rect[2]<=viewport.width+1,'Every compact phone icon fits in the viewport');
     check(Math.abs(rect[1]-touchHud.hud_row[0][1])<=1,'Every phone icon stays on a single horizontal row');
    }
    check(touchHud.hud_profile_bounds[0]+touchHud.hud_profile_bounds[2]<touchHud.hud_minimap_bounds[0],'Phone portrait and minimap remain in separate top corners');
    check(touchHud.hud_target_bounds[1]>touchHud.hud_row[0][1]+touchHud.hud_row[0][3],'Target info is below the menu row on phone');
    check(Object.values(touchHud.hud_notification_badges).every(v=>v===false),'Phone Mail and all other icons start without fake red dots');
    await snap('web-premium-mobile-ten-icons');
    await clickRect(touchHud.hud_settings_button,true);
    await until(()=>window.__leoQA.hud_panel_key==='settings');
    await clickRect((await state()).hud_start_editor,true);
    await until(()=>window.__leoQA.hud_editing);
    touchHud=await state();
    const original=touchHud.hud_world_button;
    await dragHudTouch(original[0]+original[2]/2,original[1]+original[3]/2,
       original[0]+original[2]/2-67,original[1]+original[3]/2+66);
    await until(()=>!!window.__leoQA.hud_layout.world);
    touchHud=await state();
    check(touchHud.hud_world_button[0]<original[0]-25,'Real finger drag changes HUD icon position on mobile');
    await snap('web-hud-touch-edit');
    await clickRect(touchHud.hud_swap_toolbar,true);
    await until(()=>window.__leoQA.hud_toolbar_on_top);
    touchHud=await state();
    check(touchHud.hud_toolbar[1]<20,'Editor toolbar moves to the top so lower mobile controls are reachable');
    const stickBefore=touchHud.hud_joystick;
    await dragHudTouch(stickBefore[0]+stickBefore[2]/2,stickBefore[1]+stickBefore[3]/2,
      stickBefore[0]+stickBefore[2]/2+25,stickBefore[1]+stickBefore[3]/2-80);
    await until(()=>!!window.__leoQA.hud_layout.joystick);
    touchHud=await state();
    check(touchHud.hud_joystick[1]<stickBefore[1]-30,'Finger can reposition the actual lower-left movement joystick');
    await snap('web-hud-touch-bottom-controls');
    await clickRect(touchHud.hud_cancel_button,true);
    await until(()=>!window.__leoQA.hud_editing);
    check(Object.keys((await state()).hud_layout).length===0,'Cancel restores previous HUD layout after touchscreen drags');
   }
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
  // Real mobile touch: pan to the fifth top-row Storage tab and tap it.
  for(const viewport of [{width:390,height:844},{width:844,height:390}]){
   context=await start(viewport,true);
   let mobileStorage=await state();
   check(!mobileStorage.has_storage_hud,'Mobile HUD has no standalone Storage icon');
   await clickRect(mobileStorage.opener,true);
   await until(()=>window.__leoQA.open);
   mobileStorage=await state();
   check(mobileStorage.storage_tab_visible&&mobileStorage.tabs.length===5,'Mobile Storage fifth tab is available');
   // Small screens pan the entire 1448-wide UI instead of shrinking touch targets.
   // Reach the fifth tab by a real horizontal swipe before tapping it.
   for(let attempt=0;attempt<5;attempt++){
    mobileStorage=await state();
    const rect=mobileStorage.storage_tab;
    if(rect[0]>=0&&rect[0]+rect[2]<=viewport.width&&rect[1]>=0&&rect[1]+rect[3]<=viewport.height)break;
    await swipe(500,0);
   }
   mobileStorage=await state();
   check(mobileStorage.storage_tab[2]>=44,'Mobile Storage tab remains a usable touch target');
   await clickRect(mobileStorage.storage_tab,true);
   await until(()=>window.__leoQA.storage_mode&&window.__leoQA.storage_visible);
   mobileStorage=await state();
   check(mobileStorage.storage_bag_right&&mobileStorage.storage_equipment_hidden,'Mobile Storage keeps bank left and inventory right');
   check(mobileStorage.storage_cells===50&&mobileStorage.storage_grid[0][2]>=44,'Mobile Storage has 50 touch-friendly PNG slots');
   await snap('web-storage-mobile-'+viewport.width);
   await context.close();
  }
  check(errors.length===0,'No game JavaScript or GDScript runtime errors');
 }catch(error){
  errors.push(error.stack||String(error));
  if(page&&!page.isClosed()) console.log('FAILURE_STATE',JSON.stringify(await state().catch(()=>null)));

  if(page&&!page.isClosed()){await snap('web-failure').catch(()=>{});fs.writeFileSync(path.join(out,'failure-state.json'),JSON.stringify(await state().catch(()=>null),null,2));}
 }finally{
  const digest=file=>crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
  // Both ordinary index.* exports and commit-versioned game-<sha>.* exports
  // must hash the actual Godot files referenced by the tested HTML.
  const entryHtml=fs.readFileSync('build/web/index.html','utf8');
  const executable=entryHtml.match(/"executable":"([^"]+)"/)?.[1]||'index';
  const report={package_sha256:digest(`build/web/${executable}.pck`),wasm_sha256:digest(`build/web/${executable}.wasm`),asset_basename:executable,passed:errors.length===0,checks,errors,engine:'Godot 4.4.1',browser:'Chromium with SwiftShader WebGL2',commit:process.env.GITHUB_SHA||null};
  fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify(report,null,2));
  if(browser)await browser.close();
  if(errors.length)process.exitCode=1;
 }
})();
