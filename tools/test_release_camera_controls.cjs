// Browser proof of the real Godot Web camera, independent of stubbed tests.
// Desktop: RMB hold/drag/release + wheel. Phone: screen drag and 2-finger pinch.
// The release is blocked if either real browser input path stops working.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert=require('node:assert/strict');

const state=page=>page.evaluate(()=>window.__leoQA);
const wait=(page,fn,arg,ms=18000)=>page.waitForFunction(fn,arg,{timeout:ms,polling:100});
const near=(a,b,tolerance=0.0005)=>Math.abs(a-b)<=tolerance;
const sleep=page=>page.waitForTimeout(230);

async function cameraCheck(browser, mobile){
  const viewport=mobile?{width:844,height:390}:{width:1200,height:760};
  const context=await browser.newContext({viewport,isMobile:mobile,hasTouch:mobile,deviceScaleFactor:1});
  const page=await context.newPage();
  const errors=[];
  page.on('pageerror',err=>errors.push(err.message));
  try{
    await page.goto('http://127.0.0.1:8000/_qa.html?mobile_ui=1&gm_test=1',
      {waitUntil:'domcontentloaded'});
    await wait(page,()=>window.__leoQA?.hud_training_target_present
      && typeof window.__leoQA?.camera_orbit_yaw==='number'
      && typeof window.__leoQA?.camera_zoom_distance==='number',null,40000);
    await page.locator('#canvas').focus();
    const initial=await state(page);
    assert(near(initial.bangkok_actor_scale,0.5),'Actor must use map-relative 50% size');
    assert(near(initial.bangkok_player_capsule_height,1.05),'Collision capsule should be scaled');
    assert(near(initial.bangkok_golem_scale,0.5),'NPC collider and mesh should be scaled');
    assert(near(initial.camera_zoom_distance,5.4),'Initial zoom must match new city scale');
    if(!mobile){
      await page.mouse.move(640,430);
      await page.mouse.move(705,450,{steps:4});
      await sleep(page);
      assert(near((await state(page)).camera_orbit_yaw,initial.camera_orbit_yaw),
        'Moving mouse WITHOUT RMB should not rotate camera');
      await page.mouse.down({button:'right'});
      await page.mouse.move(795,490,{steps:7});
      await sleep(page);
      const turned=await state(page);
      assert(Math.abs(turned.camera_orbit_yaw-initial.camera_orbit_yaw)>0.08,
        'RMB drag must visibly rotate orbit yaw');
      assert(Math.abs(turned.camera_orbit_pitch-initial.camera_orbit_pitch)>0.015,
        'RMB drag must tilt orbit pitch');
      await page.mouse.up({button:'right'});
      await page.mouse.move(700,360,{steps:3});
      await sleep(page);
      const stopped=await state(page);
      assert(near(stopped.camera_orbit_yaw,turned.camera_orbit_yaw),
        'Releasing RMB should preserve camera angle');
      await page.mouse.wheel(0,-350);
      await wait(page,x=>window.__leoQA?.camera_zoom_distance<x,stopped.camera_zoom_distance);
      console.log('PASS desktop real Web RMB orbit, release persistence, wheel zoom and scaled actors');
    }else{
      const cdp=await context.newCDPSession(page);
      const input=(type,points)=>cdp.send('Input.dispatchTouchEvent',{type,
        touchPoints:points.map(([id,x,y])=>({id,x:Math.round(x),y:Math.round(y)}))});
      const one=(x,y)=>[[1,x,y]];
      await input('touchStart',one(340,248));
      await input('touchMove',one(405,272));
      await wait(page,x=>Math.abs(window.__leoQA?.camera_orbit_yaw-x)>0.06,
        initial.camera_orbit_yaw);
      const turned=await state(page);
      await input('touchEnd',[]);
      await sleep(page);
      const stopped=await state(page);
      assert(near(stopped.camera_orbit_yaw,turned.camera_orbit_yaw),
        'Mobile one-finger release must keep the angle');
      assert.equal(stopped.camera_touch_count,0,'Touch release must free pointer');
      const beforePinch=stopped.camera_zoom_distance;
      const originalPoints=[[1,260,240],[2,425,240]];
      await input('touchStart',[originalPoints[0]]);
      await input('touchStart',originalPoints);
      await input('touchMove',[[1,218,240],[2,468,240]]);
      await wait(page,x=>window.__leoQA?.camera_zoom_distance<x-0.25,beforePinch);
      const zoomed=await state(page);
      await input('touchMove',originalPoints);
      await wait(page,x=>window.__leoQA?.camera_zoom_distance>x+0.25,zoomed.camera_zoom_distance);
      await input('touchEnd',[]);
      await wait(page,()=>window.__leoQA?.camera_touch_count===0);
      const final=await state(page);
      assert(near(final.camera_orbit_yaw,stopped.camera_orbit_yaw),
        'Pinch zoom should not spin the camera yaw');
      console.log('PASS landscape-phone real Web one-finger orbit, persistent angle, two-finger pinch, scaled actors');
    }
    assert.equal(errors.length,0,'No browser script errors: '+errors.join('; '));
  }finally{
    await context.close();
  }
}

(async()=>{
  const browser=await chromium.launch({headless:true,
    args:['--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--no-sandbox']});
  try{
    await cameraCheck(browser,false);
    await cameraCheck(browser,true);
  }finally{
    await browser.close();
  }
})().catch(err=>{console.error('BANGKOK CAMERA BROWSER QA FAILED:',err.stack||err);process.exitCode=1;});
