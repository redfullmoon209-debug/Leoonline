// Browser QA for the actual game settings buttons and same-origin page switch.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE||'playwright');
const checks=[],errors=[];
const check=(ok,name)=>{checks.push({passed:!!ok,name});if(!ok)throw new Error(name);};
const base='http://127.0.0.1:8000';

async function waitForGame(page){
 await page.waitForFunction(()=>{
  const frame=document.getElementById('game-frame');
  return frame?.contentWindow?.__leoQA?.hud_row?.length===10;
 },null,{timeout:60000});
}
const getState=page=>page.evaluate(()=>document.getElementById('game-frame').contentWindow.__leoQA);
async function tap(page,rect,frameBox,touch){
 const x=frameBox.x+rect[0]+rect[2]/2,y=frameBox.y+rect[1]+rect[3]/2;
 if(touch) await page.touchscreen.tap(x,y); else await page.mouse.click(x,y);
}
async function choose(page,mode,touch){
 const frame=page.locator('#game-frame');
 const frameBox=await frame.boundingBox();
 let state=await getState(page);
 check(!!frameBox&&state.hud_icons.settings?.length===4,'Settings icon is present in live game');
 await tap(page,state.hud_icons.settings,frameBox,touch);
 await page.waitForFunction(()=>{
  const s=document.getElementById('game-frame')?.contentWindow?.__leoQA;
  return s?.hud_popup_visible&&s.hud_screen_mode_portrait?.length===4&&s.hud_screen_mode_landscape?.length===4;
 },null,{timeout:10000});
 state=await getState(page);
 await tap(page,mode==='portrait'?state.hud_screen_mode_portrait:state.hud_screen_mode_landscape,frameBox,touch);
 const target=mode==='portrait'?'mobile.html':'landscape.html';
 await page.waitForURL(url=>url.pathname.endsWith('/'+target),{timeout:15000});
 check(await page.evaluate(()=>localStorage.getItem('orientation-switch-probe'))==='retained',
       'Same-origin browser storage survives the screen mode switch');
}

async function runDesktop(browser){
 const context=await browser.newContext({viewport:{width:1440,height:900},deviceScaleFactor:1});
 const page=await context.newPage();
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(base+'/landscape.html');
 check(!!await page.locator('#landscape-shell').count(),'Landscape page opens');
 await page.evaluate(()=>localStorage.setItem('orientation-switch-probe','retained'));
 await waitForGame(page);
 await choose(page,'portrait',false);
 check(!!await page.locator('#phone-shell').count(),'Portrait page opens from the game settings');
 await waitForGame(page);
 const box=await page.locator('#game-frame').boundingBox();
 check(box.height>box.width,'PC portrait choice loads a real tall game viewport');
 const state=await getState(page);
 check(state.hud_joystick_visible&&state.novice_basic_atk_visible,
       'Portrait viewport retains the joystick and basic attack control');
 await context.close();
}

async function runPhone(browser){
 const context=await browser.newContext({viewport:{width:390,height:844},isMobile:true,hasTouch:true,deviceScaleFactor:1});
 const page=await context.newPage();
 page.on('pageerror',e=>errors.push(e.message));
 await page.goto(base+'/mobile.html');
 check(!!await page.locator('#phone-shell').count(),'Portrait page opens on the phone viewport');
 await page.evaluate(()=>localStorage.setItem('orientation-switch-probe','retained'));
 await waitForGame(page);
 await choose(page,'landscape',true);
 check(!!await page.locator('#rotate-prompt').count(),'iPhone-style portrait screen shows manual rotation guidance');
 await page.setViewportSize({width:844,height:390});
 await page.waitForFunction(()=>getComputedStyle(document.getElementById('landscape-shell')).display!=='none',null,{timeout:10000});
 await waitForGame(page);
 const box=await page.locator('#game-frame').boundingBox();
 check(box.width>box.height,'Landscape choice loads a real wide game viewport after rotation');
 const state=await getState(page);
 check(state.hud_joystick_visible&&state.novice_basic_atk_visible&&state.hud_minimap_bounds[2]>0,
       'Landscape viewport retains joystick, basic attack and minimap');
 await context.close();
}

(async()=>{
 let browser;
 try{
  browser=await chromium.launch({headless:true});
  await runDesktop(browser);
  await runPhone(browser);
  check(errors.length===0,'No JavaScript page errors: '+errors.join('; '));
  console.log(JSON.stringify({passed:checks.length,checks},null,2));
 }catch(error){
  console.error(JSON.stringify({error:error.stack,checks,errors},null,2));
  process.exitCode=1;
 }finally{if(browser)await browser.close();}
})();
