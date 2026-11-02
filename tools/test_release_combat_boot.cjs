// Short, release-critical browser QA: the real Web build must LOAD, LOCK,
// RUN toward a target and allow ATK to stop. Longer HUD/inventory visual
// regression suites remain in the independent hud-browser-check workflow.
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');

const state = page => page.evaluate(() => window.__leoQA);
const wait = (page, test, arg, ms=12000) =>
  page.waitForFunction(test, arg, {timeout:ms, polling:100});

async function scenario(browser, name, viewport, mobile) {
  const ctx = await browser.newContext({
    viewport, deviceScaleFactor:1, isMobile:mobile, hasTouch:mobile
  });
  const page=await ctx.newPage();
  page.setDefaultTimeout(15000);
  page.setDefaultNavigationTimeout(25000);
  const failures=[];
  page.on('pageerror',e=>failures.push(e.message));
  page.on('console',m=>{
    if(m.type()==='error' && /SCRIPT ERROR|Parse Error|Failed to load script/.test(m.text()))
      failures.push(m.text());
  });
  try{
    await page.goto('http://127.0.0.1:8000/_qa.html?mobile_ui=1&gm_test=1',
      {waitUntil:'domcontentloaded'});
    await wait(page,()=>window.__leoQA?.hud_training_target_present &&
      Array.isArray(window.__leoQA?.novice_player_xz),null,30000);
    await page.locator('#canvas').focus();
    await page.keyboard.press('KeyT');
    await wait(page,()=>window.__leoQA?.hud_target_name==='อสูรหินฝึก');
    const initial=await state(page);
    assert(initial.novice_locked_distance>5,
      'Training target must start outside normal melee range');
    assert(initial.novice_basic_atk_visible,'ATK must be visible in real game HUD');
    assert.equal(initial.novice_auto_active,false,'No attack until user presses');
    if(mobile){
      const [x,y,w,h]=initial.novice_basic_atk_bounds;
      assert(w>=40 && h>=40,'ATK must have a touch-sized hit target');
      assert(x>=0&&y>=0&&x+w<=viewport.width+2&&y+h<=viewport.height+2,
        'ATK must be inside mobile viewport');
      await page.touchscreen.tap(x+w/2,y+h/2);
    }else{
      await page.keyboard.press('KeyJ');
    }
    await wait(page,()=>window.__leoQA?.novice_auto_active === true);
    // This is the regression that previously escaped the release: a
    // UI label is not enough. The REAL CharacterBody must move in 3D.
    await wait(page,d=>window.__leoQA?.novice_locked_distance < d-2.0,
      initial.novice_locked_distance,8000);
    const moving=await state(page);
    assert(moving.novice_locked_distance<initial.novice_locked_distance-2.0,
      'Pressing ATK MUST run player closer to selected enemy');
    if(mobile){
      assert.equal(moving.novice_basic_atk_label,'หยุด','ATK must show Stop when active');
      const [x,y,w,h]=moving.novice_basic_atk_bounds;
      await page.touchscreen.tap(x+w/2,y+h/2);
    }else{
      await page.keyboard.press('KeyJ');
    }
    await wait(page,()=>window.__leoQA?.novice_auto_active===false);
    const stopped=await state(page);
    assert.equal(stopped.novice_basic_atk_label,'ATK','ATK resets after toggle off');
    if(!mobile){
      // The skill key must also approach from distance, cast once in
      // range, and return to repeated normal attacks as requested.
      assert(stopped.novice_locked_distance>3.6,
        'Stop regression must occur before the player reaches sword range');
      const hp=stopped.novice_locked_hp;
      await page.keyboard.press('Digit1');
      await wait(page,()=>window.__leoQA?.novice_auto_active===true);
      await wait(page,h=>window.__leoQA?.novice_locked_hp<h,hp,8500);
      assert((await state(page)).novice_locked_hp<hp,
        'Skill 1 MUST physically approach and inflict real target damage');
      await page.keyboard.press('KeyJ');
      await wait(page,()=>window.__leoQA?.novice_auto_active===false);
    }
    assert.equal(failures.length,0,'No browser JavaScript or GDScript errors');
    console.log('PASS '+name+' real Web ATK pursuit, movement, cancel'+
      (mobile?' and touchscreen':' and queued Slash'));
  }finally{
    await ctx.close();
  }
}

(async()=>{
  const browser=await chromium.launch({
    headless:true,
    args:['--use-angle=swiftshader','--enable-webgl',
          '--enable-unsafe-swiftshader','--no-sandbox']
  });
  try{
    await scenario(browser,'desktop',{width:1200,height:760},false);
    await scenario(browser,'landscape-touch',{width:844,height:390},true);
  }finally{
    await browser.close();
  }
})().catch(e=>{console.error('RELEASE WEB COMBAT QA FAILED:',e.stack||e);process.exitCode=1;});
