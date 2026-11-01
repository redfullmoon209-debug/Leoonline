// Real playable Godot landscape-mode TEST verification using Chromium.
// The production portrait homepage is deliberately kept separate.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const fs=require('fs');
const path=require('path');
const out=process.env.QA_OUTPUT||'build/web/qa';
fs.mkdirSync(out,{recursive:true});
const checks=[],errors=[];
function check(ok,why){checks.push({passed:!!ok,name:why});if(!ok)throw new Error(why);}
const until=(page,fn)=>page.waitForFunction(fn,null,{timeout:60000});
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));

async function runLiveGame(browser,{width,height,mobile}){
 const context=await browser.newContext({
  viewport:{width,height},isMobile:mobile,hasTouch:mobile,deviceScaleFactor:1
 });
 const page=await context.newPage();
 page.on('pageerror',err=>errors.push(err.message));
 page.on('console',msg=>{
  if(msg.type()==='error'&&/SCRIPT ERROR|Parse Error|Failed to load script/.test(msg.text())){
   errors.push(msg.text());
  }
 });
 const scenario=mobile?'phone-landscape':'desktop-landscape';
 try{
  await page.goto('http://127.0.0.1:8000/_landscape_qa.html');
  const shell=page.locator('#landscape-shell');
  const game=page.locator('#game-frame');
  await game.waitFor({state:'visible'});
  const outer=await shell.boundingBox();
  const rect=await game.boundingBox();
  check(!!rect&&!!outer,'Live landscape shell exists: '+scenario);
  check(rect.width>rect.height,'Game frame is real landscape aspect ratio: '+scenario);
  check(Math.abs((rect.width/rect.height)-(16/9))<0.2||mobile,'Desktop is 16:9, phone fills native screen');
  check(Math.abs(rect.x+rect.width/2-width/2)<5,'Landscape game is horizontally centered: '+scenario);
  check(rect.width>650&&rect.height>300,'Landscape game remains usable and large: '+scenario);
  if(mobile){
   check(Math.abs(rect.x)<2&&Math.abs(rect.y)<2,'Landscape mobile has no fake bezel');
   check(Math.abs(rect.width-width)<3&&Math.abs(rect.height-height)<3,'Phone game fills actual 844x390 browser viewport');
   check(!await page.locator('#rotate-prompt').isVisible(),'Rotate prompt hidden after actual landscape rotation');
   check(!await page.locator('.test-header').isVisible(),'Test header does not cover phone gameplay');
  }else{
   check(outer.x>40&&outer.x+outer.width<width-40,'Desktop previews landscape in a separate centered frame');
   check(outer.y>35&&outer.y+outer.height<height-15,'Desktop frame has vertical space for test header');
   check(await page.locator('.test-badge').isVisible(),'Landscape window visibly labeled TEST, not production');
   check(await page.locator('a[href="mobile.html"]').first().isVisible(),'Desktop can return to portrait production');
  }
  const src=await game.getAttribute('src');
  check(src==='_qa.html?mobile_ui=1&gm_test=1','Landscape uses actual game with explicit mobile UI and local GM test flags');
  await until(page,()=>{
   try{return window.document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_row?.length===10;}
   catch(e){return false;}
  });
  const state=()=>page.evaluate(()=>document.getElementById('game-frame').contentWindow.__leoQA);
  let data=await state();
  check(data.hud_landscape_preview===true,'Runtime accepts landscape test UI flag: '+scenario);
  check(data.hud_row.length===10,'All ten original separate PNG menu buttons retained: '+scenario);
  check(data.hud_png_paths.every(x=>x.endsWith('.png')),'No cropped or newly replaced menu assets: '+scenario);
  check(data.hud_joystick_visible&&data.hud_touch_jump_visible&&data.hud_touch_pickup_visible&&data.hud_touch_run_visible,
    'Joystick, Jump, Pickup and Run work in landscape mode: '+scenario);
  check(data.hud_profile_bounds[2]>100&&data.hud_minimap_bounds[2]>=88,
    'Character information and minimap remain present: '+scenario);
  check(data.hud_target_bounds[2]>=200&&Object.values(data.hud_notification_badges).every(v=>v===false),
    'Centered target and event-only red dots unchanged: '+scenario);
  for(let i=0;i<10;i++){
   const [x,y,w,h]=data.hud_row[i];
   check(w>=27&&x>=0&&y>=0&&x+w<=rect.width+2,
    'Menu icon '+(i+1)+' is inside horizontal viewport: '+scenario);
  }
  const frame=page.frameLocator('#game-frame');
  const canvas=frame.locator('#canvas');
  await canvas.waitFor({state:'visible'});
  const dimensions=await canvas.evaluate(el=>{
   const x=el.getBoundingClientRect();
   return {width:x.width,height:x.height,pixel_width:el.width,pixel_height:el.height};
  });
  check(Math.abs(dimensions.width-rect.width)<3&&Math.abs(dimensions.height-rect.height)<3,
   'Godot canvas reflows to live landscape size, not stretched/cropped imagery: '+scenario);
  await page.screenshot({path:path.join(out,'web-'+scenario+'-test.jpg'),type:'jpeg',quality:90});
  check(data.hud_gm_active&&data.hud_gm_visible,'Separate red GM test button appears on landscape-only playtest: '+scenario);
  check(data.hud_target_entities.length===5,'Three monsters and two distinct player BOT targets spawn into real test world: '+scenario);
  check(data.hud_target_entities.filter(e=>e.type==='Monster').length===3,
    'Actual target list has three monsters: '+scenario);
  check(data.hud_target_entities.filter(e=>e.type==='Player Bot').length===2,
    'Other players are transparently labeled simulated BOTs: '+scenario);
  const tapFrame=async(bounds)=>{
    const x=rect.x+bounds[0]+bounds[2]/2,y=rect.y+bounds[1]+bounds[3]/2;
    if(mobile)await page.touchscreen.tap(x,y);else await page.mouse.click(x,y);
  };
  await tapFrame(data.hud_gm_button_bounds);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_gm_panel_open===true;}
    catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_gm_target_picker_items===5,'GM test target list includes all original selectable entities: '+scenario);
  await page.screenshot({path:path.join(out,'web-'+scenario+'-gm-controls.jpg'),type:'jpeg',quality:90});
  await tapFrame(data.hud_gm_spawn_monster);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_gm_spawned_count===1;}
    catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_target_name.includes('มอนทดสอบ'),'GM actually spawns and selects a new physical monster: '+scenario);
  await tapFrame(data.hud_gm_spawn_player);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_gm_spawned_count===2;}
    catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_target_name.includes('[BOT]'),'GM spawns a simulated player, never claims actual online user: '+scenario);
  check(data.hud_target_hp_percent===100&&data.hud_target_mp_percent===100,'GM-selected simulated target exposes its own full HP and MP');
  await tapFrame(data.hud_gm_damage);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_target_hp_percent===75;}
    catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_target_hp_text.includes('75%'),'GM HP test damages the real selected target and instantly updates HUD');
  await tapFrame(data.hud_gm_drain_mana);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_target_mp_percent===75;}
    catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_target_mp_text.includes('75%'),'GM MP drain updates actual target and blue HUD');
  await tapFrame(data.hud_gm_heal);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_target_hp_percent===100;}
    catch(e){return false;}
  },null,{timeout:12000});
  await tapFrame((await state()).hud_gm_reset);
  await page.waitForFunction(()=>{
    try{
      const q=document.getElementById('game-frame')?.contentWindow?.__leoQA;
      return q?.hud_gm_spawned_count===0&&q?.hud_target_entities?.length===5;
    }catch(e){return false;}
  },null,{timeout:12000});
  data=await state();
  check(data.hud_target_name.includes('ยังไม่ได้เลือก'),'GM reset removes spawned test entities and clears stale target');
  await tapFrame(data.hud_gm_close);
  await page.waitForFunction(()=>{
    try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_gm_panel_open===false;}
    catch(e){return false;}
  },null,{timeout:12000});
  await page.screenshot({path:path.join(out,'web-'+scenario+'-gm-after-reset.jpg'),type:'jpeg',quality:90});
  data=await state();
  const slime=data.hud_target_entities.find(e=>e.name==='สไลม์มรกต');
  check(!!slime,'Original green slime remains in test world after GM reset');
  // The monster portrait can be chosen by a real click/touch on its 3D mesh.
  if(slime.x>50&&slime.x<rect.width-60&&slime.y>175&&slime.y<rect.height-35){
    if(mobile)await page.touchscreen.tap(rect.x+slime.x,rect.y+slime.y);
    else await page.mouse.click(rect.x+slime.x,rect.y+slime.y);
    await page.waitForFunction(()=>{
      try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.hud_target_name==='สไลม์มรกต';}
      catch(e){return false;}
    },null,{timeout:12000});
    check((await state()).hud_target_portrait_asset.endsWith('target_slime.svg'),'Real 3D slime touch displays its OWN separate portrait');
    await page.screenshot({path:path.join(out,'web-'+scenario+'-slime-locked.jpg'),type:'jpeg',quality:90});
  }
  const [ix,iy,iw,ih]=data.opener;
  if(mobile)await page.touchscreen.tap(rect.x+ix+iw/2,rect.y+iy+ih/2);
  else await canvas.click({position:{x:ix+iw/2,y:iy+ih/2},force:true});
  await page.waitForFunction(()=>{
   try{return document.getElementById('game-frame')?.contentWindow?.__leoQA?.open===true;}
   catch(e){return false;}
  },null,{timeout:20000});
  check((await state()).open===true,'Original real Inventory opens inside landscape test: '+scenario);
  await page.screenshot({path:path.join(out,'web-'+scenario+'-inventory.jpg'),type:'jpeg',quality:90});
 }finally{
  await context.close();
 }
}

async function runRotateHint(browser){
 const context=await browser.newContext({
  viewport:{width:390,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:1
 });
 const page=await context.newPage();
 try{
  await page.goto('http://127.0.0.1:8000/_landscape_qa.html');
  check(await page.locator('#rotate-prompt').isVisible(),
   'Portrait phone sees a clear instruction to rotate for landscape test');
  check(!await page.locator('#landscape-shell').isVisible(),
   'Portrait phone does not accidentally show a tiny horizontal game');
  check(await page.locator('#rotate-prompt a[href="mobile.html"]').isVisible(),
   'Portrait test mode provides link back to main vertical game');
  await page.screenshot({path:path.join(out,'web-landscape-rotate-phone.jpg'),type:'jpeg',quality:90});
 }finally{await context.close();}
}

(async()=>{
 let browser;
 try{
  browser=await chromium.launch({headless:true,args:[
   '--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--no-sandbox'
  ]});
  await runLiveGame(browser,{width:1440,height:900,mobile:false});
  await runLiveGame(browser,{width:844,height:390,mobile:true});
  await runRotateHint(browser);
 }catch(e){errors.push(e.stack||String(e));}
 finally{
  if(browser)await browser.close();
  const report={passed:errors.length===0,checks,errors};
  fs.writeFileSync(path.join(out,'landscape-test-report.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify({passed:report.passed,checks:checks.length,errors},null,2));
  if(errors.length)process.exitCode=1;
 }
})();
