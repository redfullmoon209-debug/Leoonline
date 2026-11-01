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
async function pan(dx,dy){
 // Real wheel events, useful for desktop and for positioning before touch tests.
 const q=await state(),r=q.scroller;
 await page.mouse.move(Math.min(page.viewportSize().width-20,r[2]/2),Math.min(r[3]-20,200));
 await page.mouse.wheel(dx,dy);
 await page.waitForTimeout(350);
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
  await clickRect((await state()).tabs[2]);
  await until(()=>window.__leoQA.tab===2);
  check((await state()).waiting==='Skills are not available yet','Skill placeholder is truthful');
  await clickRect((await state()).tabs[3]);
  await until(()=>window.__leoQA.tab===3);
  check((await state()).waiting==='Shop is not available yet','Shop placeholder is truthful');
  await clickRect((await state()).tabs[0]);
  await until(()=>window.__leoQA.tab===0);
  await clickRect((await state()).footer[1]);
  await until(()=>window.__leoQA.notice==='Saved');
  const before=(await state()).slots;
  await page.reload();
  await until(()=>!!window.__leoQA);
  check(JSON.stringify((await state()).slots)===JSON.stringify(before),'Web save persists across reload');
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
   await pan(900,viewport.height<500?290:0);
   q=await state();
   let cell=q.bag.find((r,i)=>i>=40&&r[0]>=0&&r[0]+r[2]<viewport.width&&r[1]>0&&r[1]+r[3]<Math.min(q.scroller[3],viewport.height));
   if(!cell){await pan(-250,160);q=await state();cell=q.bag.find((r,i)=>i>=40&&r[0]>=0&&r[0]+r[2]<viewport.width&&r[1]>0&&r[1]+r[3]<Math.min(q.scroller[3],viewport.height));}
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
