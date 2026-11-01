// Real Chromium QA for a Godot 4.4.1 game running inside a mobile
// portrait-sized iframe; never tests a CSS-stretched game screenshot.
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const fs=require('fs');
const path=require('path');
const out=process.env.QA_OUTPUT || 'build/web/qa';
fs.mkdirSync(out,{recursive:true});
const errors=[], checks=[];
const check=(value,label)=>{checks.push({name:label,passed:!!value});if(!value)throw Error(label);};
const wait=ms=>new Promise(resolve=>setTimeout(resolve,ms));

async function runScenario(browser,{width,height,mobile}){
  const context=await browser.newContext({
    viewport:{width,height},isMobile:mobile,hasTouch:mobile,deviceScaleFactor:1
  });
  const page=await context.newPage();
  page.on('pageerror',e=>errors.push(e.message));
  try{
    await page.goto('http://127.0.0.1:8000/_phone_qa.html');
    const shell=page.locator('#phone-shell');
    const iframe=page.locator('#game-frame');
    await iframe.waitFor();
    const outer=await shell.boundingBox();
    const box=await iframe.boundingBox();
    check(!!outer&&!!box,'Phone frame and game iframe both render');
    check(box.width<box.height,'Game viewport is taller than wide');
    check(Math.abs(box.x+box.width/2-width/2)<5,'Mobile viewport is horizontally centered');
    if(!mobile){
      check(box.width>=270&&box.width<=470,'PC presents an actual 270-470px wide phone screen');
      check(box.height>600&&box.height<height,'PC device preview keeps real portrait height');
      check(Math.abs((box.height/box.width)-2.16)<0.15,'PC phone viewport uses roughly 9:19.5 aspect ratio');
      check(outer.x>50&&outer.x+outer.width<width-50,'Desktop shows dark side margins, not widescreen gameplay');
    }else{
      check(Math.abs(box.width-width)<3,'Phone browser uses the full mobile viewport width');
      check(Math.abs(box.height-height)<3,'Phone browser uses the full mobile viewport height');
      check(outer.x<=1&&outer.y<=1,'Actual phone has no unnecessary mock device bezel');
    }
    await page.waitForFunction(()=>{
      try {
        const frame=document.getElementById('game-frame');
        return frame?.contentWindow?.__leoQA?.hud_row?.length===10;
      }catch(e){return false;}
    },null,{timeout:60000});
    const state=()=>page.evaluate(()=>document.getElementById('game-frame').contentWindow.__leoQA);
    const hud=await state();
    check(hud.hud_row.length===10,'Real Godot game still renders all ten individually clickable PNG icons');
    check(hud.hud_joystick_visible===true,'Mobile-look viewport shows the actual movement joystick even on PC');
    check(hud.hud_touch_jump_visible===true,'Mobile-look viewport shows the real jump button');
    check(hud.hud_touch_pickup_visible===true,'Mobile-look viewport shows the real pickup button');
    check(hud.hud_profile_bounds[2]>100&&hud.hud_minimap_bounds[2]>80,'Portrait viewport retains player card and minimap');
    check(Object.values(hud.hud_notification_badges).every(value=>!value),'Mail and all other icons have no fake red dot');
    for(let i=0;i<10;i++){
      const [x,y,w,h]=hud.hud_row[i];
      check(x>=0&&y>=0&&x+w<=box.width+2,'Menu icon '+(i+1)+' fits inside actual portrait viewport');
    }
    const frame=page.frameLocator('#game-frame');
    const canvas=frame.locator('#canvas');
    await canvas.waitFor({state:'visible'});
    const canvasSize=await canvas.evaluate(el=>({
      cssW:el.getBoundingClientRect().width,
      cssH:el.getBoundingClientRect().height,
      pixelsW:el.width,pixelsH:el.height
    }));
    check(Math.abs(canvasSize.cssW-box.width)<=3&&Math.abs(canvasSize.cssH-box.height)<=3,
          'Godot Adaptive canvas matches real portrait iframe, not a stretched landscape image');
    const shot='web-phone-shell-'+(mobile?'real-mobile':'desktop-preview')+'.jpg';
    await page.screenshot({path:path.join(out,shot),type:'jpeg',quality:90});
    // The Inventory icon opens the REAL existing inventory by tapping/clicking
    // directly on the Godot canvas inside the phone-sized browser.
    const [ix,iy,iw,ih]=hud.opener;
    const hit={position:{x:ix+iw/2,y:iy+ih/2},force:true,timeout:10000};
    if(mobile){
      await page.touchscreen.tap(box.x+ix+iw/2,box.y+iy+ih/2);
    }else{
      await canvas.click(hit);
    }
    await page.waitForFunction(()=>{
      try { return document.getElementById('game-frame')?.contentWindow?.__leoQA?.open === true; }
      catch(e){return false;}
    },null,{timeout:15000});
    check((await state()).open===true,'Inventory really opens from portrait game icon');
    await page.screenshot({
      path:path.join(out,'web-phone-shell-inventory-'+(mobile?'mobile':'desktop')+'.jpg'),
      type:'jpeg',quality:90
    });
    return checks.length;
  }finally{
    await context.close();
  }
}

(async()=>{
  let browser;
  try{
    browser=await chromium.launch({headless:true,args:[
      '--use-angle=swiftshader','--enable-webgl','--enable-unsafe-swiftshader','--no-sandbox'
    ]});
    await runScenario(browser,{width:1440,height:900,mobile:false});
    await runScenario(browser,{width:390,height:844,mobile:true});
  }catch(err){
    errors.push(err.stack||String(err));
  }finally{
    if(browser) await browser.close();
    const report={passed:errors.length===0,checks,errors};
    fs.writeFileSync(path.join(out,'phone-shell-report.json'),JSON.stringify(report,null,2));
    console.log('Mobile portrait shell QA:',checks.length,'checks,',errors.length,'errors');
    if(errors.length)console.error(errors.join('\n'));
    if(errors.length)process.exitCode=1;
  }
})();
