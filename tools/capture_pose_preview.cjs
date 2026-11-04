const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs = require('fs');
(async()=>{
 const browser=await chromium.launch({headless:true,args:['--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--no-sandbox']});
 const page=await browser.newPage({viewport:{width:1280,height:800},deviceScaleFactor:1});
 const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
 try {
  await page.goto('http://127.0.0.1:8000/_pose_qa.html?mobile_ui=1&gm_test=1',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>!!window.__leoQA?.hud_training_target_present,null,{timeout:60000});
  const canvas=page.locator('#canvas');
  await canvas.focus();
  await page.mouse.move(640,400);
  for(let i=0;i<9;i++)await page.mouse.wheel(0,-180);
  await page.waitForTimeout(850);
  console.log('POSE_CAMERA_ZOOM:'+JSON.stringify((await page.evaluate(()=>window.__leoQA)).camera_zoom_distance));
  const rear=await page.screenshot({type:'jpeg',quality:56,clip:{x:390,y:95,width:500,height:590}});
  console.log('POSE_REAR_JPEG_B64:'+rear.toString('base64'));
  await page.mouse.move(1210,405);
  await page.mouse.down({button:'right'});
  await page.mouse.move(160,405,{steps:15});
  await page.mouse.up({button:'right'});
  await page.waitForTimeout(850);
  console.log('POSE_CAMERA_YAW:'+JSON.stringify((await page.evaluate(()=>window.__leoQA)).camera_orbit_yaw));
  const front=await page.screenshot({type:'jpeg',quality:56,clip:{x:390,y:95,width:500,height:590}});
  console.log('POSE_FRONT_JPEG_B64:'+front.toString('base64'));
  console.log('POSE_BROWSER_ERRORS:'+JSON.stringify(errors.slice(0,12)));
 }finally{await browser.close();}
})().catch(e=>{console.error('POSE_CAPTURE_FAILED',e.stack||String(e));process.exitCode=1;});
