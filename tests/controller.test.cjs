// Execute actual GML with syntax substitutions and stub APIs; not a runner test.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');
fs.mkdirSync(path.join(root, 'build'), {recursive:true});
const read = p => fs.readFileSync(path.join(root, p), 'utf8');
const rules = JSON.parse(read('rules.json'));
const metadata = JSON.parse(read('assets/game-assets.json'));
const manifest = JSON.parse(read('assets/manifest.json'));
const source = Object.fromEntries(['create', 'step', 'draw'].map(n => [n, read(`gml/${n}.gml`)]));
source.create += '\n' + read('gml/network.gml');
source.end = read('gml/end-step.gml');
source.networkEvent = read('gml/network-event.gml');
source.cleanup = read('gml/cleanup.gml');
const K = { ENTER: 13, SHIFT: 16, SPACE: 32, W: 87, A: 65, S: 83, D: 68, P: 80, RIGHT: 39, UP: 38 };
function game(code = source, args = []) {
  let keys = new Set(), oldKeys = new Set(), buttons = new Set(), oldButtons = new Set();
  let mx = 320, my = 280, wheel = 0;
  const calls = [], audio = [], texts = [], sprites = new Map(), packets = [], destroyed = [];
  const buffers = new Map();let nextBuffer=1,nextSocket=10;
  let font = 3000;
  const c = {
    ...rules, mod_version: rules.version, ord: s => s.charCodeAt(0), real: Number, string: String,
    id: 1, current_time: 0, keyboard_string: '',
    is_string: v=>typeof v==='string', is_real: v=>typeof v==='number', is_nan: Number.isNaN,
    is_infinity: v=>v===Infinity||v===-Infinity, is_array: Array.isArray,
    is_struct: v=>v!==null&&typeof v==='object'&&!Array.isArray(v),is_undefined:v=>v===undefined,
    string_split: (s,d)=>s.split(d),string_char_at:(s,i)=>s.charAt(i-1),string_pos:(needle,s)=>s.indexOf(needle)+1,
    json_stringify: JSON.stringify,json_parse:JSON.parse,
    variable_instance_get: (_,name)=>c[name],variable_instance_set:(_,name,value)=>c[name]=value,
    variable_struct_get:(s,k)=>s[k],variable_struct_set:(s,k,v)=>s[k]=v,
    variable_struct_exists:(s,k)=>Object.hasOwn(s,k),ds_map_find_value:(m,k)=>m[k],
    array_delete:(a,start,count)=>a.splice(start,count),
    network_socket_tcp:0,network_type_connect:1,network_type_disconnect:2,network_type_data:3,network_type_non_blocking_connect:4,
    buffer_grow:1,buffer_string:1,buffer_seek_start:0,buffer_u8:2,
    network_create_server:()=>nextSocket++,network_create_socket:()=>nextSocket++,network_connect_async:()=>0,
    network_destroy:s=>destroyed.push(s),
    buffer_create:()=>{const id=nextBuffer++;buffers.set(id,{text:'',pos:0});return id;},
    buffer_delete:id=>buffers.delete(id),buffer_seek:(id,_,p)=>buffers.get(id).pos=p,
    buffer_write:(id,_,text)=>{buffers.get(id).text=text;buffers.get(id).pos=Buffer.byteLength(text)+1;},
    buffer_tell:id=>buffers.get(id).pos,buffer_read:id=>buffers.get(id).text,
    buffer_peek:()=>0,
    network_send_packet:(socket,id,size)=>{packets.push(JSON.parse(buffers.get(id).text));return size;},
    audio_destroy_stream:()=>{},
    min: Math.min, max: Math.max, floor: Math.floor, ceil: Math.ceil, sqrt: Math.sqrt, abs: Math.abs,
    clamp: (v, lo, hi) => Math.min(hi, Math.max(lo, v)),
    array_length: a => a.length, array_push: (a, ...items) => a.push(...items),
    array_resize: (a, size) => { a.length = size; }, get_timer: () => performance.now() * 1000,
    point_direction: (x,y,tx,ty) => (Math.atan2(y-ty,tx-x)*180/Math.PI+360)%360,
    lengthdir_x: (s,a) => s*Math.cos(a*Math.PI/180), lengthdir_y: (s,a) => -s*Math.sin(a*Math.PI/180),
    keyboard_check: k => keys.has(k), keyboard_check_pressed: k => keys.has(k)&&!oldKeys.has(k),
    mouse_check_button: b => buttons.has(b), mouse_check_button_pressed: b => buttons.has(b)&&!oldButtons.has(b),
    mouse_check_button_released: b => !buttons.has(b)&&oldButtons.has(b),
    device_mouse_x_to_gui: () => mx, device_mouse_y_to_gui: () => my,
    mouse_wheel_up: () => wheel < 0, mouse_wheel_down: () => wheel > 0,
    focused: true, window_has_focus: () => c.focused,
    display_get_width: () => 1920, display_get_height: () => 1080,
    window_get_fullscreen: () => false, audio_group_is_loaded: () => true,
    texturegroup_get_textures: () => [1],
    audio_create_stream: file => { audio.push(['stream',file]); return 50; },
    audio_play_sound: (s,p,l) => { audio.push(['play',s,l]); return 100; },
    audio_sound_gain: (v,g) => audio.push(['gain',v,g]),
    draw_sprite_ext: (...args) => {
      const s = sprites.get(args[0]); assert.ok(s); assert.ok(args[1] >= 0 && args[1] < s.frames);
      calls.push(['sprite',s.name,...args]);
    },
    draw_sprite_stretched_ext: (...args) => { assert.ok(sprites.has(args[0])); calls.push(['panel',...args]); },
    draw_sprite_part_ext: () => assert.fail('Partial drawing is forbidden for the native nine-slice frame'),
    sprite_get_number: id => sprites.get(id).frames, sprite_get_width: id => sprites.get(id).width,
    sprite_get_height: id => sprites.get(id).height, sprite_get_xoffset: id => sprites.get(id).origin_x,
    sprite_get_yoffset: id => sprites.get(id).origin_y,
    draw_set_font: id => { assert.ok([3000,3001].includes(id)); font=id; },
    string_width: s => s.length*(font===3001?14:7),
    string_length: s => s.length, string_copy: (s,start,len) => s.substr(start-1,len),
    parameter_count: () => args.length, parameter_string: i => args[i-1] || '',
    game_end: () => { c.quit = true; }, make_color_rgb: (r,g,b) => r+256*g+65536*b,
    vk_left: 37, vk_right: 39, vk_up: 38, vk_down: 40, vk_enter: 13, vk_shift: 16, vk_space: 32,
    vk_escape: 27, vk_f3: 114, vk_f4: 115, mb_left: 1, mb_right: 2, cr_arrow: -2,
    window_set_cursor: id => { c.native_cursor = id; },
    snd_hurt1: 1, snd_select: 2, snd_menumove: 3, snd_graze: 4, audio_sfx: 1,
    c_white: 0xffffff, c_black: 0, c_lime: 0x00ff00, c_yellow: 0xffff, fa_left: 0, fa_top: 0,
  };
  for (const name of ['window_set_caption','display_set_gui_size','gpu_set_texfilter','window_set_size','window_center',
    'randomize','audio_group_load','texture_prefetch','window_set_fullscreen','draw_set_alpha','draw_set_halign',
    'draw_set_valign','draw_clear','draw_set_color','draw_line','draw_rectangle','draw_circle']) c[name] = () => {};
  c.draw_text_transformed=(x,y,text)=>texts.push({x,y,text,w:c.string_width(text),h:font===3001?24:14});
  metadata.sprites.forEach((s,i) => { c[s.name] = 2000+i; sprites.set(2000+i,s); });
  c.fnt_main = 3000; c.fnt_mainbig = 3001;
  vm.createContext(c);
  const scripts = Object.fromEntries(Object.entries(code).map(([n,s]) => [n,new vm.Script(`(function(){${s.replace(/\bmod\b/g,'%').replace(/\bexit\s*;/g,'return;')}\n})();`)]));
  const run = n => scripts[n].runInContext(c, {timeout: 1000});
  run('create');
  return {
    c, calls, audio, texts, packets, destroyed,
    step({keys: k=[], buttons: b=[], x=mx, y=my, scroll=0}={}) {
      keys=new Set(k); buttons=new Set(b); mx=x; my=y; wheel=scroll;
      c.current_time+=1000/30;run('step');if(scripts.end)run('end');oldKeys=new Set(keys);oldButtons=new Set(buttons);
    },
    draw() { run('draw'); },
    networkEvent(map){c.async_load=map;run('networkEvent');},
    cleanup(){run('cleanup');},
    active() { c.reset_match(); c.phase='dodge'; c.phase_ticks=rules.dodge_ticks; },
    hit(vx=0,offset=0) { c.add_bullet(c.soul_x+offset,c.soul_y,vx,0); c.bullets.at(-1).age=0; },
  };
}
const results=[];
function test(name,fn) { try {fn(); results.push({name,passed:true}); console.log('PASS '+name);} catch(e) {results.push({name,passed:false,error:e.stack}); console.error('FAIL '+name+'\n'+e.stack);} }
const plain = v => JSON.parse(JSON.stringify(v));
const combat = c => plain({phase:c.phase,ticks:c.phase_ticks,players:c.players,bullets:c.bullets,hazards:c.hazards,seeds:c.seeds,stroke:c.stroke,
  energy:c.energy,cooldown:c.strategy_cooldown,x:c.soul_x,y:c.soul_y});

test('lobby requires separate fresh mouse and keyboard confirmations',()=>{
  const g=game(); g.step(); g.step({buttons:[1],x:120,y:340}); assert.equal(g.c.phase,'lobby');
  assert.equal(g.c.mouse_ready,true); g.step({keys:[13]}); assert.equal(g.c.phase,'plan');
  assert.equal(g.c.attacker,0); assert.equal(g.c.input_gate,true);
});
test('handoff waits indefinitely and rejects held confirmation buttons',()=>{
  const g=game(); g.active(); g.step({buttons:[1],keys:[13]}); g.c.advance_turn();
  for(let i=0;i<50;i++)g.step({buttons:[1],keys:[13],x:120,y:340});
  assert.equal(g.c.phase,'handoff'); assert.equal(g.c.mouse_ready,false);
  g.step(); for(let i=0;i<500;i++)g.step(); assert.equal(g.c.phase,'handoff');
  g.step({buttons:[1],keys:[13],x:120,y:340}); assert.equal(g.c.phase,'plan'); assert.equal(g.c.attacker,1);
});
test('mouse wheel and clickable cards select; keyboard cannot select or fire',()=>{
  const g=game();g.c.reset_match();g.c.phase='plan';g.c.phase_ticks=rules.planning_ticks;g.step({keys:[68,70,75]});assert.equal(g.c.pattern,0);
  g.step({scroll:-1});assert.equal(g.c.pattern,9);g.step({scroll:1});assert.equal(g.c.pattern,0);
  g.step({buttons:[1],x:360,y:195});assert.equal(g.c.pattern,1);
  g.step();g.step({buttons:[1],x:400,y:330});assert.equal(g.c.phase,'telegraph');
  g.active();g.step({keys:[70,75]});assert.equal(g.c.shots_fired,0);
});
test('planning and telegraph expire; dodge lasts exactly 15 seconds',()=>{
  const g=game();g.c.reset_match();g.c.phase='plan';g.c.phase_ticks=rules.planning_ticks;
  for(let i=0;i<rules.planning_ticks;i++)g.step();assert.equal(g.c.phase,'telegraph');
  for(let i=0;i<rules.telegraph_ticks;i++)g.step();assert.equal(g.c.phase,'dodge');
  assert.equal(g.c.phase_ticks,450);
  for(let i=0;i<450;i++)g.step();assert.equal(g.c.phase,'swap');
});
test('both key layouts control defender, diagonal normalization and focus survive role swaps',()=>{
  const g=game();g.active(); const x=g.c.soul_x,y=g.c.soul_y;
  g.step({keys:[68,87]});assert.ok(Math.abs(Math.hypot(g.c.soul_x-x,g.c.soul_y-y)-rules.soul_speed)<1e-8);
  const x2=g.c.soul_x;g.step({keys:[39,32]});assert.equal(g.c.soul_x-x2,rules.focus_speed);
  g.c.advance_turn();g.c.phase='dodge';g.c.phase_ticks=450;const x3=g.c.soul_x;
  g.step({keys:[39]});assert.equal(g.c.soul_x-x3,rules.soul_speed);
});
test('mouse movement does not move defender; firing originates at edge and aims at mouse',()=>{
  const g=game();g.active();const x=g.c.soul_x;g.step({buttons:[1],x:200,y:210});
   assert.equal(g.c.soul_x,x);assert.equal(g.c.bullets.length,5);
   assert.equal(g.c.bullets[2].bx,200);assert.equal(g.c.bullets[2].by,rules.arena_top+5);
   assert.ok(Math.abs(g.c.bullets[2].vx)<0.4);assert.ok(g.c.bullets[2].vy>0);
});
test('normal projectile velocity stays fixed when mouse moves',()=>{
  const g=game();g.active();g.step({buttons:[1],x:200,y:210});const b=g.c.bullets[0],vx=b.vx,vy=b.vy;
  for(let i=0;i<20;i++)g.step({x:480,y:370});assert.equal(b.vx,vx);assert.equal(b.vy,vy);
});
test('comets turn at bounded angular speed, then stop tracking',()=>{
  const g=game();g.active();g.c.pattern=1;g.step({buttons:[1],x:200,y:210});const b=g.c.bullets[0];
  b.age=1;const old=g.c.point_direction(0,0,b.vx,b.vy);g.step({x:480,y:300});
  const next=g.c.point_direction(0,0,b.vx,b.vy);assert.ok(Math.abs(((next-old+540)%360)-180)<=rules.comet_turn_degrees+1e-8);
  b.age=rules.comet_steering_ticks;const vx=b.vx,vy=b.vy;g.step({x:150,y:370});assert.equal(b.vx,vx);assert.equal(b.vy,vy);
});
test('energy limits held fire and automatically recovers from exhaustion',()=>{
  const g=game();g.active();g.c.players[1].inv=9999;
  for(let i=0;i<250;i++)g.step({buttons:[1],x:200,y:210});
  assert.ok(g.c.shots_fired>10 && g.c.shots_fired<17);assert.ok(g.c.energy>=0 && g.c.energy<=100);
  for(let i=0;i<40;i++)g.step();assert.ok(g.c.energy>20);
  const n=g.c.shots_fired;g.step({buttons:[1]});assert.equal(g.c.shots_fired,n+1);
});
test('outside-arena clicks and toolbar clicks cannot fire or place attacks',()=>{
  const g=game();g.active();g.step({buttons:[1,2],x:10,y:10});assert.equal(g.c.bullets.length,0);assert.equal(g.c.hazards.length,0);
  g.step();g.step({buttons:[1],x:490,y:20});assert.equal(g.c.sound_enabled,false);assert.equal(g.c.shots_fired,0);
});
test('mine warns, emits two staggered radial waves, and respects cooldown',()=>{
  const g=game();g.active();g.c.pattern=1;g.step({buttons:[2],x:320,y:300});
  assert.equal(g.c.hazards.length,1);assert.equal(g.c.bullets.length,0);
  g.step();g.step({buttons:[2]});assert.equal(g.c.hazards.length,1);
  for(let i=0;i<rules.strategy_warning_ticks-3;i++)g.step();
  assert.equal(g.c.hazards.length,1);assert.equal(g.c.bullets.length,12);assert.equal(g.c.players[1].hp,100);
  for(let i=0;i<24;i++)g.c.step_hazards();
  assert.equal(g.c.hazards.length,0);assert.equal(g.c.bullets.length,24);
  assert.ok(g.c.bullets.slice(12).every(b=>b.age<0));
});
test('extra emitter is on edge and has a finite lifetime',()=>{
  const g=game();g.active();g.c.place_strategy(200,250,true);const h=g.c.hazards[0];
  assert.ok(h.hx===rules.arena_left+5||h.hy===rules.arena_top+5);
  for(let i=0;i<rules.strategy_warning_ticks+100;i++)g.c.step_hazards();
  assert.equal(g.c.hazards.length,0);assert.equal(g.c.bullets.length,15);
});
test('wall drag commits on release, preview matches a safe gap, vertical and horizontal work',()=>{
  for(const horizontal of [true,false]) {
    const g=game();g.active();g.c.pattern=2;
    g.step({buttons:[2],x:320,y:250});assert.equal(g.c.dragging,true);assert.equal(g.c.hazards.length,0);
    g.step({buttons:[2],x:horizontal?400:320,y:horizontal?250:340});
    g.step();assert.equal(g.c.dragging,false);assert.equal(g.c.hazards[0].horizontal,horizontal);
    for(let i=0;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();
    assert.ok(g.c.bullets.length>0);
    assert.ok(g.c.bullets.every(b=>Math.abs((horizontal?b.bx:b.by)-(horizontal?320:250))>26));
  }
});
test('wall release outside cancels; too-late strategies are rejected',()=>{
  const g=game();g.active();g.c.pattern=2;g.step({buttons:[2]});g.step({x:10,y:10});assert.equal(g.c.hazards.length,0);
  g.c.phase_ticks=20;g.c.place_strategy(320,280,true);assert.equal(g.c.hazards.length,0);
});
test('warnings do not damage, swept hits do, overlapping bullets respect invulnerability',()=>{
  const g=game();g.active();g.c.add_bullet(g.c.soul_x,g.c.soul_y,0,0);
  for(let i=0;i<rules.projectile_warning_ticks;i++)g.step();assert.equal(g.c.players[1].hp,100);
  g.step();assert.equal(g.c.players[1].hp,90);
  g.hit();g.hit();g.step();assert.equal(g.c.players[1].hp,90);
  g.c.bullets=[];g.c.players[1].inv=0;g.hit(100,-50);g.step();assert.equal(g.c.players[1].hp,80);
});
test('stale attacks and owner immunity cannot damage the new defender',()=>{
  const g=game();g.active();g.hit();g.c.bullets[0].owner=g.c.defender;
  g.hit();g.c.bullets[1].round_id--;g.c.step_bullets();assert.equal(g.c.players[1].hp,100);
  g.c.place_strategy(320,280,true);g.c.hazards[0].round_id--;g.c.step_hazards();assert.equal(g.c.hazards.length,0);
});
test('pause freezes combat and cancels wall drag; resume click cannot leak into firing',()=>{
  const g=game();g.active();g.c.pattern=2;g.step({buttons:[2]});g.step({keys:[80]});assert.equal(g.c.dragging,false);
  const before=combat(g.c);for(let i=0;i<40;i++)g.step();assert.deepEqual(combat(g.c),before);
  g.step({buttons:[1],x:230,y:180});assert.equal(g.c.paused,false);
  g.step({buttons:[1],x:320,y:280});assert.equal(g.c.shots_fired,0);assert.equal(g.c.phase_ticks,before.ticks-1);
  g.step();g.step({buttons:[1]});assert.equal(g.c.shots_fired,1);
});
test('focus loss pauses simulation',()=>{
  const g=game();g.active();const ticks=g.c.phase_ticks;g.c.focused=false;g.step();assert.equal(g.c.paused,true);assert.equal(g.c.phase_ticks,ticks);
});
test('turn end cleans every attack and waits for next pair of role confirmations',()=>{
  const g=game();g.active();g.c.place_strategy(320,280,true);g.hit();g.c.phase_ticks=1;g.step();
  assert.equal(g.c.hazards.length,0);assert.equal(g.c.bullets.length,0);
  for(let i=0;i<rules.swap_ticks;i++)g.step();assert.equal(g.c.phase,'handoff');assert.equal(g.c.attacker,1);
});
test('KO, fair turn limit, session score and alternating rematch opener',()=>{
  const g=game();g.active();g.c.players[1].hp=10;g.hit();g.step();assert.equal(g.c.phase,'result');assert.equal(g.c.wins[0],1);
  g.step();g.step({buttons:[1],keys:[13],x:120,y:340});assert.equal(g.c.phase,'plan');assert.equal(g.c.attacker,1);assert.equal(g.c.players[1].hp,100);
  const attacks=[0,0];for(let i=0;i<rules.max_turns;i++){attacks[g.c.attacker]++;g.c.advance_turn();}
  assert.deepEqual(attacks,[6,6]);assert.equal(g.c.phase,'result');assert.equal(g.c.winner,-1);
});
test('all menus can be operated with mouse including pause, restart, lobby and quit',()=>{
  const g=game();g.step();g.step({buttons:[1],x:430,y:20});assert.equal(g.c.paused,true);
  g.step();g.step({buttons:[1],x:230,y:220});assert.equal(g.c.phase,'handoff');assert.equal(g.c.paused,false);
  g.step();g.step({buttons:[1],x:430,y:20});g.step();g.step({buttons:[1],x:230,y:270});assert.equal(g.c.phase,'lobby');
  g.step();g.step({buttons:[1],x:430,y:20});g.step();g.step({buttons:[1],x:230,y:310});assert.equal(g.c.quit,true);
});
test('draw is pure in every phase, with actual hazards, native fonts and original sprites',()=>{
  const g=game();g.active();
  for(let p=0;p<7;p++){g.c.pattern=p;g.c.strategy_cooldown=0;g.c.place_strategy(320,250,true);g.c.shot_cooldown=0;g.c.fire_burst();}
  g.c.pattern=4;g.c.dragging=true;g.c.drag_x=220;g.c.drag_y=230;
  for(const phase of ['lobby','handoff','plan','telegraph','dodge','swap','result'])for(const paused of [false,true]){
    g.c.phase=phase;g.c.paused=paused;const before=combat(g.c);g.draw();assert.deepEqual(combat(g.c),before);
  }
  assert.ok(g.calls.some(c=>c[0]==='panel'));assert.ok(g.calls.some(c=>c[1]==='spr_dodgeheart_centered_white'));
});
test('music is created once across rematches and mouse mute controls gain',()=>{
  const g=game();for(let i=0;i<10;i++)g.c.reset_match();assert.equal(g.audio.filter(a=>a[0]==='stream').length,1);
  g.step({buttons:[1],x:490,y:20});assert.equal(g.audio.at(-1)[2],0);
  g.step();g.step({buttons:[1],x:490,y:20});assert.equal(g.audio.at(-1)[2],0.32);
});
test('every sprite is accounted for and no campaign/save APIs are called',()=>{
  const all=Object.values(source).join('\n');assert.deepEqual([...new Set(all.match(/\bspr_[a-zA-Z0-9_]+\b/g))].sort(),Object.keys(manifest.sprites).sort());
  assert.doesNotMatch(all,/\b(?:file_\w+|ini_\w+|buffer_save\w*|game_save|game_load|room_goto\w*|game_change|scr_\w+|ossafe_\w+)\s*\(/);
  assert.doesNotMatch(all,/\bglobal\s*\./);
});
test('held transition buttons never freeze clock or defender movement',()=>{
  const g=game();g.active();g.c.input_gate=true;const x=g.c.soul_x;
  for(let i=0;i<60;i++)g.step({buttons:[1,2],keys:[68,13]});
  assert.equal(g.c.phase_ticks,rules.dodge_ticks-60);assert.ok(g.c.soul_x>x);assert.equal(g.c.shots_fired,0);
  g.step();g.step({buttons:[1]});assert.equal(g.c.shots_fired,1);
});
test('focus loss wins over simultaneous resume and restart inputs',()=>{
  const g=game();g.active();g.c.paused=true;g.c.focused=false;const ticks=g.c.phase_ticks;
  g.step({buttons:[1],keys:[80],x:230,y:220});assert.equal(g.c.paused,true);assert.equal(g.c.phase_ticks,ticks);assert.equal(g.c.phase,'dodge');
});
test('graze rewards a swept near miss exactly once without awarding a collision',()=>{
  const g=game();g.active();g.c.add_bullet(g.c.soul_x+14,g.c.soul_y,0,0);g.c.bullets[0].age=0;
  g.step();assert.equal(g.c.turn_grazes,1);assert.equal(g.c.players[1].hp,100);
  for(let i=0;i<20;i++)g.step();assert.equal(g.c.turn_grazes,1);assert.equal(g.c.match_grazes[1],1);
  g.hit();g.step();assert.equal(g.c.turn_grazes,1);assert.equal(g.c.hit_amount,10);assert.ok(g.c.hit_feedback>0);
});
test('stable compaction removes expired and stale bullets without losing survivors',()=>{
  const g=game();g.active();g.c.players[1].inv=100;
  for(let i=0;i<10;i++)g.c.add_bullet(150+i*10,200,0,0);
  const original=g.c.bullets;g.c.bullets[1].life=1;g.c.bullets[3].round_id--;g.c.bullets[5].bx=-100;
  g.c.step_bullets();assert.equal(g.c.bullets,original);assert.equal(g.c.bullets.length,7);
  assert.deepEqual(plain(g.c.bullets.map(b=>b.bx)),[150,170,190,210,220,230,240]);
});
test('perfect turns, transient feedback and rematch statistics reset correctly',()=>{
  const g=game();g.active();g.c.phase_ticks=1;g.step();assert.equal(g.c.perfect_turns[1],1);
  g.c.reset_match();assert.deepEqual(plain(g.c.perfect_turns),[0,0]);assert.deepEqual(plain(g.c.match_grazes),[0,0]);
  g.c.phase='dodge';g.c.phase_ticks=450;g.hit();g.step();for(let i=0;i<30;i++)g.step();assert.equal(g.c.hit_feedback,0);
});
test('deterministic stress: 36 complete attack turns with mixed input remain bounded',()=>{
  const g=game();let seed=12345,peak=0;
  const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
  for(let turn=0;turn<36;turn++) {
    g.active();g.c.pattern=turn%10;g.c.loadouts[0]=[turn%10,(turn+1)%10];g.c.players[1].inv=10000;
    for(let tick=0;tick<450;tick++) {
      const b=[];if(random()<0.8)b.push(1);if(tick%125<35)b.push(2);
      g.step({buttons:b,keys:random()<0.5?[68,87,81]:[65,83,16],scroll:tick%100===0?1:0,x:112+random()*416,y:180+random()*212});
      peak=Math.max(peak,g.c.bullets.length);
      assert.ok(g.c.bullets.length<=rules.bullet_limit);assert.ok(g.c.hazards.length<=2);
      assert.ok(g.c.seeds.length<=rules.seed_limit);
      assert.ok(g.c.energy>=0&&g.c.energy<=rules.energy_max);
      assert.ok(g.c.soul_x>=rules.arena_left+10&&g.c.soul_x<=rules.arena_right-10);
      assert.ok(g.c.soul_y>=rules.arena_top+10&&g.c.soul_y<=rules.arena_bottom-10);
      assert.ok(g.c.bullets.every(b=>Number.isFinite(b.bx)&&Number.isFinite(b.by)&&b.round_id===g.c.turn_id));
    }
    assert.equal(g.c.phase,'swap');assert.equal(g.c.bullets.length,0);assert.equal(g.c.hazards.length,0);
  }
  console.log('Stress: 16200 simulated combat ticks; peak projectiles '+peak);
});
test('loadout selection keeps two distinct attacks and persists for each player',()=>{
  const g=game();g.active();g.c.edit_slot=0;g.c.select_attack(1);
  assert.deepEqual(plain(g.c.loadouts[0]),[1,0]);g.c.edit_slot=1;g.c.select_attack(6);
  assert.deepEqual(plain(g.c.loadouts[0]),[1,6]);assert.deepEqual(plain(g.c.loadouts[1]),[0,1]);
  g.c.advance_turn();g.c.advance_turn();assert.equal(g.c.pattern,1);
});
test('wheel switch preserves energy, cooldown and existing bullets, and warns before firing',()=>{
  const g=game();g.active();g.c.loadouts[0]=[0,4];g.c.fire_burst();g.c.strategy_cooldown=100;
  const b=g.c.bullets[0],energy=g.c.energy;
  g.step({scroll:1,buttons:[1,2]});assert.equal(g.c.pattern,4);assert.equal(g.c.shots_fired,1);
  assert.equal(g.c.energy,energy);assert.equal(g.c.strategy_cooldown,99);assert.ok(g.c.bullets.includes(b));
  assert.equal(b.art,0);assert.equal(g.c.hazards.length,0);
  for(let i=0;i<rules.switch_warning_ticks;i++)g.step({buttons:[1]});assert.equal(g.c.shots_fired,2);
});
test('delayed strategies retain their own artwork after switching patterns',()=>{
  const g=game();g.active();g.c.pattern=1;g.c.place_strategy(240,240,true);g.c.pattern=4;
  for(let i=0;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();
  assert.equal(g.c.bullets.length,12);assert.ok(g.c.bullets.every(b=>b.art===1&&b.bounces===0));
  for(let i=0;i<24;i++)g.c.step_hazards();
  assert.equal(g.c.bullets.length,24);assert.ok(g.c.bullets.every(b=>b.art===1&&b.bounces===0));
});
test('pulse has a fixed safe angular opening and delayed pulse warns first',()=>{
  const g=game();g.active();g.c.emit_ring(320,280,0);
  assert.equal(g.c.bullets.length,19);
  assert.ok(g.c.bullets.every(b=>{const a=g.c.point_direction(0,0,b.vx,b.vy);return Math.abs(((a+540)%360)-180)>30;}));
  g.c.bullets=[];g.c.pattern=3;g.c.place_strategy(240,240,true);
  g.c.step_hazards();assert.equal(g.c.bullets.length,0);
  for(let i=1;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();assert.ok(g.c.bullets.length>=8);
});
test('ricochet bounces twice at walls and expires instead of bouncing forever',()=>{
  const g=game();g.active();g.c.pattern=4;g.c.add_bullet(rules.arena_right-6,210,2.5,0);
  const b=g.c.bullets[0];b.age=0;g.c.step_bullets();assert.equal(b.bounces,1);assert.ok(b.vx<0);
  b.bx=rules.arena_left+6;g.c.step_bullets();assert.ok(b.vx>0);assert.equal(b.bounces,0);
  b.bx=rules.arena_right-6;g.c.step_bullets();assert.ok(b.vx>0);
  for(let i=0;i<rules.projectile_life_ticks;i++)g.c.step_bullets();assert.equal(g.c.bullets.length,0);
});
test('reflector activates only after warning and reflects a crossing ricochet once',()=>{
  const g=game();g.active();g.c.pattern=4;g.c.place_strategy(250,250,true);
  for(let i=0;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();
  g.c.add_bullet(250,249,0,2.5);const b=g.c.bullets[0];b.age=0;g.c.step_bullets();
  assert.ok(b.vy<0);assert.equal(b.bounces,1);
  g.c.step_bullets();assert.ok(b.vy<0);assert.equal(b.bounces,1,'Must not bounce again on the same reflector');
  for(let i=0;i<100;i++)g.c.step_hazards();assert.equal(g.c.hazards.length,0);
});
test('orbit is harmless during formation, reverses, then launches finitely',()=>{
  const g=game();g.active();g.c.pattern=5;g.c.fire_burst();const b=g.c.bullets[0];
  assert.equal(b.orbit,24);g.c.place_strategy(240,250,true);assert.equal(b.spin,-1);
  g.c.soul_x=b.bx;g.c.soul_old_x=b.bx;g.c.soul_y=b.by;g.c.soul_old_y=b.by;
  for(let i=0;i<24;i++)g.c.step_bullets();assert.equal(g.c.players[1].hp,100);
  assert.equal(b.orbit,0);assert.equal(b.age,-rules.projectile_warning_ticks);
});
test('pincer emits opposite-edge shots and a warned fixed crossing',()=>{
  const g=game();g.active();g.c.pattern=6;g.c.fire_burst();assert.equal(g.c.bullets.length,6);
  assert.equal(g.c.bullets[0].bx+g.c.bullets[1].bx,rules.arena_left+rules.arena_right);
  g.c.bullets=[];g.c.place_strategy(240,240,true);g.c.target_x=450;
  for(let i=0;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();assert.equal(g.c.bullets.length,6);
  for(let i=0;i<18;i++)g.c.step_hazards();assert.equal(g.c.bullets.length,12);
  assert.ok(g.c.bullets.slice(6).every(b=>b.bx===240));
});
test('Q evasion is once per turn, bounded, and does not grant immunity or skip collisions',()=>{
  const g=game();g.active();g.step({keys:[81]});assert.equal(g.c.dash_available,true);
  const x=g.c.soul_x;g.step();g.step({keys:[81,68]});assert.equal(g.c.soul_x-x,rules.dash_speed);
  assert.equal(g.c.players[1].inv,0);assert.equal(g.c.dash_available,false);
  g.c.add_bullet(g.c.soul_x+4,g.c.soul_y,0,0);g.c.bullets.at(-1).age=0;g.step({keys:[68]});assert.equal(g.c.players[1].hp,90);
  for(let i=0;i<10;i++)g.step();g.step({keys:[81,68]});assert.equal(g.c.dash_remaining,0);
  g.c.advance_turn();assert.equal(g.c.dash_available,true);
});
test('damage summary attributes hits to original attack rather than current selection',()=>{
  const g=game();g.active();g.c.pattern=4;g.hit();g.c.pattern=0;g.step();
  assert.equal(g.c.damage_by_pattern[4],10);assert.equal(g.c.damage_by_pattern[0],0);
});
test('reflector catches exact-plane arrivals and preview does not mutate combat',()=>{
  const g=game();g.active();g.c.pattern=4;g.c.place_strategy(250,250,true);
  for(let i=0;i<rules.strategy_warning_ticks;i++)g.c.step_hazards();
  g.c.add_bullet(250,247.5,0,2.5);g.c.bullets[0].age=0;g.c.step_bullets();assert.ok(g.c.bullets[0].vy<0);
  const before=combat(g.c);g.c.draw_bounce_preview(250,185,g.c.c_white);assert.deepEqual(combat(g.c),before);
});
test('fresh right click works while left confirmation remains held across a transition',()=>{
  const g=game();g.active();g.c.pattern=1;g.step({buttons:[1]});g.c.input_gate=true;
  g.step({buttons:[1,2],x:240,y:240});assert.equal(g.c.hazards.length,1);
  assert.equal(g.c.hazards[0].kind,1);assert.equal(g.c.special_notice,'ESPECIAL ATIVADO');
  assert.equal(g.c.right_click_count,1);
});
test('right drag and release work independently of held left and Enter',()=>{
  for(const pattern of [2,4]){
    const g=game();g.active();g.c.pattern=pattern;g.step({buttons:[1],keys:[13]});g.c.input_gate=true;
    g.step({buttons:[1,2],keys:[13],x:240,y:240});assert.equal(g.c.dragging,true);
    g.step({buttons:[1],keys:[13],x:330,y:240});assert.equal(g.c.hazards.length,1);assert.equal(g.c.dragging,false);
  }
});
test('held right across transition does not auto-cast; blocked clicks explain why',()=>{
  const g=game();g.c.phase='telegraph';g.c.phase_ticks=1;
  g.step({buttons:[2]});g.step({buttons:[2]});assert.equal(g.c.hazards.length,0);
  g.step();g.step({buttons:[2],x:5,y:5});assert.equal(g.c.special_notice,'MIRE DENTRO DA ARENA');
  g.step();g.c.strategy_cooldown=60;g.step({buttons:[2],x:240,y:240});assert.equal(g.c.special_notice,'ESPECIAL RECARREGANDO');
  assert.equal(g.c.hazards.length,0);
});
test('cursor is visible above every menu and pause overlay at raw GUI mouse coordinates',()=>{
  const g=game();assert.equal(g.c.native_cursor,g.c.cr_arrow);
  g.step({x:60,y:430}); // Outside arena, still inside the application.
  for(const phase of ['lobby','plan','telegraph','dodge','swap','handoff','result']) {
    for(const paused of [false,true]) {
      g.c.phase=phase;g.c.paused=paused;g.calls.length=0;g.draw();
      const cursor=g.calls.at(-1);assert.equal(cursor[1],'spr_custommenu_arrow');
      assert.equal(cursor[4],60);assert.equal(cursor[5],430);assert.equal(cursor.at(-1),1);
    }
  }
});
test('fullscreen change restores native pointer and outside-window position hides fallback',()=>{
  const g=game();g.c.native_cursor=999;g.step({keys:[115]});assert.equal(g.c.native_cursor,g.c.cr_arrow);
  g.step({x:-30,y:-30});g.calls.length=0;g.draw();
  assert.ok(!g.calls.some(c=>c[1]==='spr_custommenu_arrow'&&c[4]===-30));
});
test('second selection page exposes all creative attacks and keeps slots distinct',()=>{
  const g=game();g.active();g.c.phase='plan';g.c.phase_ticks=300;
  g.step({buttons:[1],x:120,y:325});assert.equal(g.c.selection_page,1);
  g.step();g.step({buttons:[1],x:360,y:195});assert.equal(g.c.pattern,7);
  g.step();g.step({buttons:[1],x:120,y:240});assert.equal(g.c.pattern,8);
  g.step();g.step({buttons:[1],x:360,y:240});assert.equal(g.c.pattern,9);
  g.draw();
});
test('Costura records a bounded path, warns on release and consumes energy once',()=>{
  const g=game();g.active();g.c.pattern=7;
  g.step({buttons:[1],x:160,y:220});g.step({buttons:[1],x:500,y:220});
  assert.ok(g.c.stroke_length<=rules.stitch_max_length);assert.equal(g.c.bullets.length,0);
  g.step();assert.equal(g.c.bullets.length,20);assert.equal(g.c.energy,80);
  assert.ok(g.c.bullets.every(b=>b.age<0&&b.art===7));
  for(let i=0;i<220;i++)g.step();assert.equal(g.c.bullets.length,0);
});
test('Costura reverse changes launch endpoint and no drawing can damage before release',()=>{
  const g=game();g.active();g.c.pattern=7;g.c.place_strategy(250,250,true);
  g.step({buttons:[1],x:180,y:220});g.step({buttons:[1],x:240,y:220});
  g.draw();assert.equal(g.c.players[1].hp,100);g.step();
  assert.equal(g.c.bullets[0].bx,240);assert.equal(g.c.bullets[0].route.at(-1)[0],180);
});
test('creative gestures cancel on outside release, pause and wheel change',()=>{
  for(const pattern of [7,8]){
    const g=game();g.active();g.c.pattern=pattern;
    g.step({buttons:[1],x:180,y:220});g.step({buttons:[1],x:240,y:240});g.step({x:0,y:0});
    assert.equal(g.c.bullets.length,0);assert.equal(g.c.energy,100);
    g.step({buttons:[1],x:180,y:220});g.step({buttons:[1],keys:[80]});assert.equal(g.c.stroke.length,0);assert.equal(g.c.charge_ticks,0);
    g.c.paused=false;g.c.input_gate=false;g.step();g.step({buttons:[1]});g.step({scroll:1});
    assert.equal(g.c.stroke.length,0);assert.equal(g.c.charge_ticks,0);
  }
});
test('Bumerangue charges distance, returns once with harmless warning, and expires',()=>{
  const g=game();g.active();g.c.pattern=8;g.c.players[1].inv=1000;
  g.step({buttons:[1],x:240,y:240});for(let i=0;i<20;i++)g.step({buttons:[1]});g.step();
  const b=g.c.bullets[0];assert.ok(b.outbound>30);assert.equal(b.returning,false);
  for(let i=0;i<rules.projectile_warning_ticks+1;i++)g.step();
  g.step({buttons:[2]});assert.equal(b.returning,true);assert.ok(b.age<0);
  const life=b.life;g.c.strategy_cooldown=0;g.c.place_strategy(240,240,true);assert.equal(b.life,life);assert.equal(g.c.strategy_cooldown,0);
  for(let i=0;i<200;i++)g.step();assert.equal(g.c.bullets.length,0);
});
test('Jardim caps seeds, does not damage in flight and requires mature plants',()=>{
  const g=game();g.active();g.c.pattern=9;
  g.step({buttons:[1],x:240,y:210});g.step({buttons:[2]});assert.equal(g.c.strategy_cooldown,0);
  assert.equal(g.c.seeds[0].fuse,-1);assert.equal(g.c.bullets.length,0);
  for(let i=0;i<80;i++){g.c.energy=100;g.step({buttons:[1]});}
  assert.equal(g.c.seeds.length,3);assert.equal(g.c.players[1].hp,100);
  for(let i=0;i<60;i++)g.step();g.step({buttons:[2]});
  assert.deepEqual(plain(g.c.seeds.map(s=>s.fuse)),[23,35,47]);
  for(let i=0;i<23;i++)g.step();assert.equal(g.c.seeds.length,3);assert.equal(g.c.bullets.length,13);
  assert.equal(g.c.seeds[0].bloom,1);assert.equal(g.c.seeds[0].fuse,24);
  for(let i=0;i<48;i++)g.step();assert.equal(g.c.seeds.length,0);
});
test('garden survives pattern switch, uses original art and is removed at turn end',()=>{
  const g=game();g.active();g.c.pattern=9;g.step({buttons:[1],x:240,y:210});
  for(let i=0;i<70;i++)g.step();g.c.place_strategy(240,210,true);g.c.pattern=0;
  for(let i=0;i<24;i++)g.step();assert.ok(g.c.bullets.every(b=>b.art===9));assert.equal(g.c.bullets.length,13);
  g.c.phase_ticks=1;g.step();assert.equal(g.c.seeds.length,0);assert.equal(g.c.bullets.length,0);
});
test('creative previews are pure with charged boom, route warnings and mature seeds',()=>{
  const g=game();g.active();g.c.pattern=7;g.step({buttons:[1],x:180,y:220});g.step({buttons:[1],x:240,y:220});g.step();
  g.c.pattern=9;g.c.shot_cooldown=0;g.step({buttons:[1],x:240,y:240});
  g.c.charge_ticks=30;g.c.pattern=8;const before=combat(g.c);g.draw();assert.deepEqual(combat(g.c),before);
});
test('combat HUD never draws floating text over the arena or overlaps status messages',()=>{
  const g=game();g.active();
  for(let pattern=0;pattern<10;pattern++) {
    g.c.pattern=pattern;g.c.charge_ticks=30;g.c.stroke=[[180,240],[240,240]];g.c.stroke_length=60;
    g.c.special_notice='ESPECIAL RECARREGANDO';g.c.special_notice_ticks=30;g.c.switch_timer=10;
    g.c.graze_flash=10;g.c.hit_feedback=20;g.c.hit_amount=10;g.c.dragging=true;
    g.c.pointer_x=320;g.c.pointer_y=280;g.texts.length=0;g.draw();
    assert.equal(g.texts.filter(t=>t.y===157).length,1);
    for(const t of g.texts) {
      assert.ok(t.x>=0&&t.x+t.w<=640&&t.y>=0&&t.y+t.h<=480,JSON.stringify(t));
      assert.ok(!(t.x<528&&t.x+t.w>112&&t.y<392&&t.y+t.h>180),'Arena text: '+t.text);
    }
    for(let i=0;i<g.texts.length;i++)for(let j=i+1;j<g.texts.length;j++) {
      const a=g.texts[i],b=g.texts[j];
      assert.ok(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y),a.text+' overlaps '+b.text);
    }
  }
});
test('menu labels fit screen and slot click updates page, details and active attack',()=>{
  const g=game();g.active();g.c.phase='plan';g.c.phase_ticks=300;g.c.loadouts[0]=[0,9];
  g.step({buttons:[1],x:350,y:155});assert.equal(g.c.edit_slot,1);assert.equal(g.c.pattern,9);assert.equal(g.c.selection_page,1);
  for(const phase of ['lobby','plan','handoff','result']) {
    g.c.phase=phase;g.texts.length=0;g.draw();
    for(const t of g.texts)assert.ok(t.x+t.w<=640&&t.y+t.h<=480,JSON.stringify(t));
    for(let i=0;i<g.texts.length;i++)for(let j=i+1;j<g.texts.length;j++) {
      const a=g.texts[i],b=g.texts[j];assert.ok(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y),a.text+' overlaps '+b.text);
    }
  }
});
test('switch clears obsolete special notice and pausing cancels residual evade',()=>{
  const g=game();g.active();g.c.special_notice_ticks=30;g.step({scroll:1});assert.equal(g.c.special_notice_ticks,0);
  g.step({keys:[81,68]});assert.ok(g.c.dash_remaining>0);g.step({keys:[80]});assert.equal(g.c.dash_remaining,0);
});
test('status priority is stable and ignores stale gestures belonging to another attack',()=>{
  const g=game();g.active();g.c.pattern=7;g.c.stroke=[[180,220],[220,220]];g.c.stroke_length=40;
  g.c.special_notice='ESPECIAL ATIVADO';g.c.special_notice_ticks=30;
  assert.ok(g.c.combat_status().startsWith('Desenhe'));
  g.c.switch_timer=10;assert.ok(g.c.combat_status().startsWith('Trocando'));
  g.c.input_gate=true;assert.ok(g.c.combat_status().startsWith('Solte o esquerdo'));
  g.c.input_gate=false;g.c.switch_timer=0;g.c.pattern=9;g.c.charge_ticks=30;
  assert.equal(g.c.combat_status(),'ESPECIAL ATIVADO');
});
test('help pauses combat without changing underlying pause state and consumes close click',()=>{
  const g=game();g.active();g.step({buttons:[1],x:330,y:20});assert.equal(g.c.help_open,true);
  const before=combat(g.c);for(let i=0;i<50;i++)g.step({keys:[68],buttons:[1,2]});
  assert.deepEqual(combat(g.c),before);assert.equal(g.c.paused,false);
  g.step();g.step({buttons:[1],x:300,y:410});assert.equal(g.c.help_open,false);
  g.step({buttons:[1],x:320,y:280});assert.equal(g.c.shots_fired,0);
});
test('help pages navigate within bounds and return to an already paused menu',()=>{
  const g=game();g.c.paused=true;g.step({buttons:[1],x:330,y:20});
  for(let i=0;i<5;i++){g.step();g.step({buttons:[1],x:470,y:410});}assert.equal(g.c.help_page,2);
  for(let i=0;i<5;i++){g.step();g.step({buttons:[1],x:100,y:410});}assert.equal(g.c.help_page,0);
  g.step({keys:[27]});assert.equal(g.c.help_open,false);assert.equal(g.c.paused,true);
});
test('tutorial pages and attack instructions fit without clipping',()=>{
  const g=game();g.c.help_open=true;
  for(let page=0;page<3;page++) {
    g.c.help_page=page;g.texts.length=0;g.draw();
    const title=g.texts.findIndex(t=>t.text==='COMO JOGAR');const texts=g.texts.slice(title);
    for(const t of texts){assert.ok(t.x+t.w<=600&&t.y+t.h<=448);assert.ok(!t.text.endsWith('...'));}
    for(let i=0;i<texts.length;i++)for(let j=i+1;j<texts.length;j++){
      const a=texts[i],b=texts[j];assert.ok(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y));
    }
  }
  g.c.help_open=false;g.c.phase='plan';
  for(let p=0;p<10;p++){g.c.loadouts[0][0]=p;g.texts.length=0;g.draw();
    for(const t of g.texts.filter(t=>t.text.startsWith('ESQ:')||t.text.startsWith('DIR:')))assert.ok(!t.text.endsWith('...'));
  }
});
test('alternating spreads and separated comet lanes remove the old single-shot corridor',()=>{
  const g=game();g.active();g.c.target_x=320;g.c.target_y=240;g.c.fire_burst();
  const angles=g.c.bullets.map(b=>g.c.point_direction(0,0,b.vx,b.vy));
  g.c.shot_cooldown=0;g.c.fire_burst();
  assert.ok(g.c.bullets.slice(5).every((b,i)=>Math.abs(g.c.point_direction(0,0,b.vx,b.vy)-angles[i])>9));
  g.c.bullets=[];g.c.shot_cooldown=0;g.c.pattern=1;g.c.fire_burst();
  assert.equal(new Set(g.c.bullets.map(b=>b.bx)).size,3);
  for(let i=0;i<60;i++)g.c.step_bullets();
  assert.ok(g.c.bullets.every(b=>Number.isFinite(b.vx)&&Number.isFinite(b.vy)));
});
test('wall preview is identical to emitted positions and both waves keep a real passage',()=>{
  for(const horizontal of [true,false])for(const opposite of [true,false]) {
    const g=game();g.active();g.c.draw_wall_preview(320,250,horizontal,g.c.c_white,opposite);
    const preview=g.calls.filter(c=>c[1]==='spr_spadebullet').map(c=>[c[4],c[5]]);
    g.c.emit_wall(320,250,horizontal,opposite);
    assert.deepEqual(plain(g.c.bullets.map(b=>[b.bx,b.by])),preview);
    const coords=g.c.bullets.map(b=>horizontal?b.bx:b.by),gap=horizontal?320:250;
    assert.ok(Math.min(...coords.map(p=>Math.abs(p-gap)))>rules.soul_radius+rules.projectile_radius+12);
    assert.ok(coords.some(p=>p<gap)&&coords.some(p=>p>gap));
  }
  const g=game();g.active();g.c.pattern=2;g.c.place_strategy(320,240,true);
  for(let i=0;i<30;i++)g.c.step_hazards();const h=g.c.hazards[0];
  assert.equal(h.hx,256);assert.equal(h.timer,30);
  const first=g.c.bullets.length;for(let i=0;i<30;i++)g.c.step_hazards();
  assert.ok(g.c.bullets.slice(first).every(b=>b.vy<0&&Math.abs(b.bx-256)>26));
});
test('pulse second wave changes escape sector without tracking the defender',()=>{
  const g=game();g.active();g.c.pattern=3;g.c.fire_burst();
  const a=g.c.bullets.filter(b=>b.age===-24),b=g.c.bullets.filter(b=>b.age===-44);
  assert.ok(a.length>=19&&b.length>=19);
  const headings=bs=>bs.map(b=>Math.round(g.c.point_direction(0,0,b.vx,b.vy)));
  assert.notDeepEqual(headings(a),headings(b));
  const before=plain(g.c.bullets.map(b=>[b.vx,b.vy]));g.c.target_x=500;g.c.target_y=380;
  for(let i=0;i<24;i++)g.c.step_bullets();assert.equal(g.c.players[1].hp,100);
  assert.deepEqual(plain(g.c.bullets.map(b=>[b.vx,b.vy])),before);
});
test('orbit launches from eight distinct positions at staggered times and locks each launch',()=>{
  const g=game();g.active();g.c.pattern=5;g.c.players[1].inv=1000;g.c.fire_burst();
  assert.deepEqual(plain(g.c.bullets.map(b=>b.orbit)),[24,28,32,36,40,44,48,52]);
  const first=g.c.bullets[0];for(let i=0;i<24;i++)g.c.step_bullets();
  const velocity=[first.vx,first.vy];g.c.target_x=500;g.c.target_y=370;
  for(let i=0;i<12;i++)g.c.step_bullets();assert.deepEqual([first.vx,first.vy],velocity);
  assert.ok(g.c.bullets.some(b=>b.orbit>0));
});
test('Costura covers both directions and lateral exits, with no damage while warning',()=>{
  const g=game();g.active();g.c.pattern=7;
  g.step({buttons:[1],x:180,y:280});g.step({buttons:[1],x:400,y:280});g.step();
  const paths=g.c.bullets.filter(b=>b.route.length),thorns=g.c.bullets.filter(b=>!b.route.length);
  assert.equal(paths.length,6);assert.ok(thorns.some(b=>b.vy>0)&&thorns.some(b=>b.vy<0));
  assert.equal(paths[0].route[0][0],180);assert.equal(paths[3].route[0][0],400);
  g.c.soul_x=thorns[0].bx;g.c.soul_y=thorns[0].by;
  for(let i=0;i<rules.stitch_warning_ticks-1;i++)g.step();assert.equal(g.c.players[1].hp,100);
});
test('Bumerangue minimum charge crosses the aim and full charge increases lane coverage',()=>{
  for(const charge of [2,24]) {
    const g=game();g.active();g.c.pattern=8;g.c.players[1].inv=1000;
    g.step({buttons:[1],x:320,y:260});g.c.charge_ticks=charge;g.step();
    assert.equal(g.c.bullets.length,charge>=20?5:3);
    const b=g.c.bullets.find(b=>b.lane===0);
    assert.ok(b.outbound*4.5>Math.hypot(320-b.bx,260-b.by)+50);
    let crossed=false;for(let i=0;i<80;i++){g.step();if(!b.returning&&b.by>270)crossed=true;}
    assert.ok(crossed,'Quick release must threaten beyond the original aim');
  }
});
test('Bumerangue recall locks a new corridor, warns harmlessly, then reaches cursor and origin',()=>{
  const g=game();g.active();g.c.pattern=8;
  g.step({buttons:[1],x:240,y:240});g.step();for(let i=0;i<24;i++)g.step();
  const b=g.c.bullets.find(b=>b.lane===0);
  g.step({buttons:[2],x:440,y:330});const locked=[b.return_x,b.return_y],life=b.life;
  assert.deepEqual(locked,[440,330]);
  g.c.soul_x=b.bx;g.c.soul_y=b.by;
  for(let i=0;i<rules.projectile_warning_ticks-1;i++)g.step({x:150,y:200});
  assert.equal(g.c.players[1].hp,100);assert.deepEqual([b.return_x,b.return_y],locked);
  g.c.players[1].inv=1000;let touched=false;
  for(let i=0;i<300&&g.c.bullets.includes(b);i++) {
    g.step();if(Math.hypot(b.bx-locked[0],b.by-locked[1])<0.01)touched=true;
  }
  assert.ok(touched);assert.ok(Math.hypot(b.bx-b.ox,b.by-b.oy)<0.01);
  assert.ok(b.life<life);assert.equal(g.c.bullets.includes(b),false);
});
test('Jardim locks aim on activation and its second bloom survives an attack switch',()=>{
  const g=game();g.active();g.c.pattern=9;g.step({buttons:[1],x:300,y:260});
  for(let i=0;i<60;i++)g.step();g.step({buttons:[2],x:480,y:320});
  const s=g.c.seeds[0],heading=s.heading;g.c.pattern=0;
  for(let i=0;i<23;i++)g.step({x:130,y:200});assert.equal(s.heading,heading);
  assert.equal(s.bloom,1);assert.equal(g.c.seeds.length,1);
  for(let i=0;i<24;i++)g.step();assert.equal(g.c.seeds.length,0);
  assert.ok(g.c.bullets.length>=10&&g.c.bullets.every(b=>b.art===9));
});
test('full projectile budget cannot mutate an old projectile or spend creative energy',()=>{
  for(const pattern of [7,8,9]) {
    const g=game();g.active();g.c.pattern=pattern;
    for(let i=0;i<rules.bullet_limit;i++)g.c.add_bullet(140,200,0,0,0);
    const before=plain(g.c.bullets);g.c.charge_ticks=24;g.c.stroke=[[180,220],[400,220]];g.c.stroke_length=220;
    g.c.input.fire_released=true;g.c.input.fire=true;g.c.step_creative_input(true);
    assert.deepEqual(plain(g.c.bullets),before);assert.equal(g.c.energy,100);assert.equal(g.c.seeds.length,0);
  }
});
test('switching from a cheap shot to a costly attack cannot deadlock held-fire recovery',()=>{
  for(const pattern of [2,3,7,8,9]) {
    const g=game();g.active();g.c.energy=10;g.c.loadouts[0]=[0,pattern];
    g.step({scroll:1,buttons:[1]});assert.equal(g.c.pattern,pattern);assert.equal(g.c.recovering,true);
    for(let i=0;i<40;i++)g.step({buttons:[1]});
    assert.ok(g.c.shots_fired>0||g.c.energy>=20,`Attack ${pattern} must recover enough energy`);
  }
});
test('all 45 attack pairs survive saturation, special overlap and turn cleanup',()=>{
  const g=game();let peak=0;
  for(let a=0;a<10;a++)for(let b=a+1;b<10;b++) {
    g.active();g.c.loadouts[0]=[a,b];g.c.pattern=a;g.c.players[1].inv=10000;
    for(let t=0;t<450;t++) {
      const buttons=[];if(t%48<28)buttons.push(1);if(t%125<12)buttons.push(2);
      g.step({buttons,scroll:t%90===89?1:0,x:200+(t%48)*5,y:260+Math.sin(t/15)*50});
      peak=Math.max(peak,g.c.bullets.length);
      assert.ok(g.c.bullets.length<=rules.bullet_limit);
      assert.ok(g.c.bullets.every(b=>Number.isFinite(b.bx)&&Number.isFinite(b.by)&&b.life<=320));
      if(t%100===0){const before=combat(g.c);g.draw();assert.deepEqual(combat(g.c),before);g.calls.length=0;}
    }
    assert.equal(g.c.phase,'swap');assert.equal(g.c.bullets.length+g.c.hazards.length+g.c.seeds.length,0);
  }
  console.log('Pairs: 20250 simulated ticks; peak projectiles '+peak);
});

// Same scripted mouse input against the archived, reopened v0.6.2 controller.
// Spatial threat is a proxy for pressure, not a human win-rate or an AI difficulty score.
test('runner attack previews initialize release edges before the first input sample',()=>{
  const initial=game();assert.equal(initial.c.input.fire_released,false);assert.equal(initial.c.input.evade,false);
  for(let p=0;p<10;p++) {
    const g=game(source,['--pvp-ui-check',`attack${p}`,'native']);
    assert.equal(g.c.qa_preview,true);assert.equal(g.c.pattern,p);
    assert.ok(g.c.bullets.length+g.c.seeds.length>0);
    const before=combat(g.c);g.draw();g.step();assert.deepEqual(combat(g.c),before);
    assert.ok(g.c.bullets.every(b=>Number.isFinite(b.bx)&&Number.isFinite(b.by)));
  }
});
test('projectiles leaving the arena never render over the status line or energy bars',()=>{
  const g=game();g.active();g.c.pattern=3;
  for(const [x,y] of [[320,165],[320,410],[100,280],[540,280]])g.c.add_bullet(x,y,0,0,3);
  g.c.add_bullet(320,280,0,0,3);const before=combat(g.c);g.draw();
  const rendered=g.calls.filter(c=>c[1]==='spr_smallbullet');
  assert.equal(rendered.length,1);assert.equal(rendered[0][4],320);assert.equal(rendered[0][5],280);
  assert.deepEqual(combat(g.c),before);
});
test('comparative spatial pressure exceeds v0.6.2 for every reworked attack',()=>{
  const baseline={create:read('tests/baseline-v0.6.2/gml_Object_obj_pvp_match_Create_0.gml'),
    step:read('tests/baseline-v0.6.2/gml_Object_obj_pvp_match_Step_0.gml'),draw:''};
  const measure=(code,p)=>{
    const g=game(code);g.active();g.c.pattern=p;g.c.players[1].inv=10000;
    let cellTicks=0,peak=0;const union=new Set(),cols=33,rows=16,spacing=12;
    for(let t=0;t<450;t++) {
      let x=320+Math.sin(t/40)*100,y=275+Math.sin(t/70)*45,held=t%90<70;
      if(p===7){held=t%60<12;x=180+Math.min(t%60,12)*20;y=270+Math.sin((t%60)/4)*30;}
      if(p===8)held=t%60<24;
      const buttons=[];if(held)buttons.push(1);if(t%120>=70&&t%120<82)buttons.push(2);
      g.step({buttons,x,y});peak=Math.max(peak,g.c.bullets.length);
      const cells=new Set();
      for(const b of g.c.bullets)if(b.age>0) {
        const r=rules.soul_radius+rules.projectile_radius,dx=b.bx-b.px,dy=b.by-b.py,len=dx*dx+dy*dy;
        const x0=Math.max(0,Math.ceil((Math.min(b.bx,b.px)-r-124)/spacing));
        const x1=Math.min(cols-1,Math.floor((Math.max(b.bx,b.px)+r-124)/spacing));
        const y0=Math.max(0,Math.ceil((Math.min(b.by,b.py)-r-192)/spacing));
        const y1=Math.min(rows-1,Math.floor((Math.max(b.by,b.py)+r-192)/spacing));
        for(let row=y0;row<=y1;row++)for(let col=x0;col<=x1;col++) {
          const rx=124+col*spacing-b.px,ry=192+row*spacing-b.py;
          const u=len?Math.max(0,Math.min(1,(rx*dx+ry*dy)/len)):0;
          if((rx-u*dx)**2+(ry-u*dy)**2<=r*r)cells.add(row*cols+col);
        }
      }
      cellTicks+=cells.size;for(const cell of cells)union.add(cell);
    }
    return {unsafe_cell_ticks:cellTicks,covered_cells:union.size,total_cells:cols*rows,peak};
  };
  const rows=[];
  for(let p=0;p<10;p++) {
    const old=measure(baseline,p),current=measure(source,p);
    rows.push({attack:p,name:game().c.pattern_names[p],baseline:old,current,ratio:current.unsafe_cell_ticks/Math.max(1,old.unsafe_cell_ticks)});
  }
  fs.writeFileSync(path.join(root,'build/pressure-comparison.json'),JSON.stringify({
    baseline:'0.6.2 reopened/decompiled controller',version:rules.version,
    method:'15s identical scripted mouse per pattern, invulnerable stationary defender, 528 probe cells, swept active-projectile occupancy. Not human difficulty.',rows},null,2));
  for(const row of rows){console.log(`Pressure ${row.name}: ${row.ratio.toFixed(2)}x occupied cell-ticks`);assert.ok(row.ratio>1.25,row.name);}
});
function lanPair(){
  const host=game(),guest=game();host.c.net_start(true);guest.c.net_start(false);
  host.networkEvent({type:host.c.network_type_connect,id:host.c.net_socket,socket:44});
  guest.networkEvent({type:guest.c.network_type_non_blocking_connect,id:guest.c.net_socket,succeeded:1});
  const deliver=(from,to)=>{for(const p of from.packets.splice(0))to.c.net_receive(plain(p));};
  deliver(guest,host);deliver(host,guest);
  return {host,guest,deliver,tick(h={},g={}){guest.step(g);deliver(guest,host);host.step(h);deliver(host,guest);}};
}
test('LAN IPv4 and port parsing rejects invalid addresses without opening sockets',()=>{
  const g=game();
  for(const ip of ['127.0.0.1','192.168.1.40','10.0.0.3'])assert.equal(g.c.net_ipv4_valid(ip),true);
  for(const ip of ['localhost','256.0.0.1','1.2.3','1..2.3','-1.2.3.4','1e2.0.0.1','0.0.0.0','224.0.0.1'])assert.equal(g.c.net_ipv4_valid(ip),false,ip);
  for(const p of ['1','6510','65535'])assert.equal(g.c.net_port_valid(p),true);
  for(const p of ['0','65536','1.5','-1','1e3',''])assert.equal(g.c.net_port_valid(p),false);
  g.c.net_port_text='0';g.c.net_start(true);assert.equal(g.c.net_socket,-1);
  g.c.net_port_text='6510';g.c.net_ip='bad';g.c.net_start(false);assert.equal(g.c.net_socket,-1);
});
test('LAN handshake admits one guest and rejects incompatible versions and extra peers',()=>{
  const {host,guest}=lanPair();assert.equal(host.c.net_connected,true);assert.equal(guest.c.net_connected,true);
  assert.equal(host.c.net_player,0);assert.equal(guest.c.net_player,1);
  host.networkEvent({type:host.c.network_type_connect,id:host.c.net_socket,socket:45});assert.ok(host.destroyed.includes(45));assert.equal(host.c.net_peer,44);
  guest.c.net_receive({kind:'welcome',protocol:'wrong'});assert.equal(guest.c.net_mode,'local');assert.match(guest.c.net_status,/Versoes/);
});
test('LAN both PCs confirm their roles and guest cannot drive the host attack',()=>{
  const p=lanPair();for(let i=0;i<3;i++)p.tick();
  p.tick({buttons:[1],x:150,y:340});assert.equal(p.host.c.mouse_ready,true);assert.equal(p.host.c.phase,'lobby');
  p.tick({}, {keys:[13]});assert.equal(p.host.c.phase,'plan');assert.equal(p.guest.c.phase,'plan');
  p.tick();p.tick({}, {buttons:[1],x:360,y:195});assert.equal(p.host.c.pattern,0);
  p.tick({buttons:[1],x:400,y:330});assert.equal(p.guest.c.phase,'telegraph');
  for(let i=0;i<40;i++)p.tick();assert.equal(p.guest.c.phase,'dodge');
  const x=p.host.c.soul_x;
  p.tick({buttons:[1],x:250,y:240},{keys:[68],buttons:[1],x:500,y:300});
  assert.equal(p.host.c.shots_fired,1);assert.equal(p.host.c.soul_x,x+rules.soul_speed);
  assert.equal(p.guest.c.soul_x,p.host.c.soul_x);assert.equal(p.guest.c.bullets.length,p.host.c.bullets.length);
  assert.equal(p.guest.c.target_x,250);
});
test('LAN role swap gives guest mouse authority and host keyboard authority',()=>{
  const p=lanPair();p.host.c.reset_match();p.host.c.advance_turn();
  p.host.c.phase='dodge';p.host.c.phase_ticks=450;p.host.c.role_release_gate=false;
  for(let i=0;i<3;i++)p.tick();assert.equal(p.guest.c.attacker,1);
  const x=p.host.c.soul_x;
  p.tick({keys:[65],buttons:[1],x:500,y:300},{buttons:[1],x:210,y:230});
  assert.equal(p.host.c.soul_x,x-rules.soul_speed);assert.equal(p.host.c.shots_fired,1);
  assert.equal(p.host.c.target_x,210);assert.equal(p.guest.c.target_x,210);
});
test('LAN guest draw keeps the authoritative aim when its own mouse moves elsewhere',()=>{
  const p=lanPair();p.host.active();for(let i=0;i<3;i++)p.tick({x:220,y:240});
  assert.equal(p.guest.c.target_x,220);
  p.guest.step({x:500,y:350});assert.equal(p.guest.c.target_x,220);assert.equal(p.guest.c.pointer_x,500);
  assert.equal(p.guest.c.target_y,240);p.guest.draw();
});
test('LAN state roundtrip preserves every attack visual and cannot overwrite methods',()=>{
  const p=lanPair();p.host.active();p.host.c.players[1].inv=1000;
  for(let a=0;a<7;a++){p.host.c.pattern=a;p.host.c.energy=100;p.host.c.shot_cooldown=0;p.host.c.fire_burst();}
  const snapshot=plain(p.host.c.net_capture_state());snapshot.net_close='bad';
  assert.equal(p.guest.c.net_apply_state(snapshot),true);assert.equal(typeof p.guest.c.net_close,'function');
  for(const field of p.host.c.net_fields)assert.deepEqual(plain(p.guest.c[field]),plain(p.host.c[field]),field);
  p.guest.draw();assert.equal(p.guest.c.net_player,1);assert.equal(p.guest.c.net_mode,'client');
  const old=p.guest.c.phase;snapshot.values=[];assert.equal(p.guest.c.net_apply_state(snapshot),false);assert.equal(p.guest.c.phase,old);
});
test('LAN snapshots render all ten attacks including creative paths, returns and seeds',()=>{
  for(let pattern=0;pattern<10;pattern++) {
    const host=game(source,['--pvp-ui-check',`attack${pattern}`,'native']);
    const guest=game();guest.c.net_mode='client';guest.c.net_player=1;
    const snapshot=plain(host.c.net_capture_state());assert.equal(guest.c.net_apply_state(snapshot),true);
    assert.equal(guest.c.net_state_signature(),host.c.net_state_signature());
    const before=combat(guest.c);guest.draw();assert.deepEqual(combat(guest.c),before);
    assert.equal(guest.c.net_verified_states,1);
  }
});
test('LAN manual pause and guest help freeze simulation while snapshots continue',()=>{
  const p=lanPair();p.host.active();for(let i=0;i<3;i++)p.tick();
  p.tick({}, {keys:[80]});assert.equal(p.host.c.paused,true);const t=p.host.c.phase_ticks,s=p.guest.c.net_verified_states;
  for(let i=0;i<10;i++)p.tick();assert.equal(p.host.c.phase_ticks,t);assert.ok(p.guest.c.net_verified_states>s);
  p.tick({}, {keys:[80]});p.tick();assert.equal(p.host.c.paused,false);
  p.tick({}, {buttons:[1],x:330,y:20});assert.equal(p.guest.c.help_open,true);assert.equal(p.host.c.paused,true);
  const pausedTick=p.host.c.phase_ticks;for(let i=0;i<10;i++)p.tick();assert.equal(p.host.c.phase_ticks,pausedTick);
  p.tick({}, {keys:[27]});p.tick();assert.equal(p.guest.c.help_open,false);assert.equal(p.host.c.paused,false);
});
test('LAN consumes remote press edges once, rejects replay, and discards stale phase input',()=>{
  const p=lanPair();p.host.c.reset_match();p.host.c.advance_turn();p.host.c.phase='dodge';p.host.c.phase_ticks=450;
  for(let i=0;i<3;i++)p.tick();
  p.guest.step({buttons:[2],x:250,y:250});const packet=p.guest.packets.shift();
  p.host.c.net_receive(plain(packet));p.host.c.net_receive(plain(packet));assert.equal(p.host.c.net_queue.length,1);
  p.host.step();assert.equal(p.host.c.hazards.length,1);
  p.host.c.strategy_cooldown=0;for(let i=0;i<4;i++)p.host.step();assert.equal(p.host.c.hazards.length,1);
  const stale={...plain(packet),seq:packet.seq+1,epoch:'0:plan'};p.host.c.strategy_cooldown=0;p.host.c.net_receive(stale);p.host.step();assert.equal(p.host.c.hazards.length,1);
  const bad={...plain(packet),seq:packet.seq+2};bad.data[12]=100;const n=p.host.c.net_queue.length;p.host.c.net_receive(bad);assert.equal(p.host.c.net_queue.length,n);
});
test('LAN focus loss freezes both PCs, neutralizes gestures, and resume cannot fire a held click',()=>{
  const p=lanPair();p.host.active();for(let i=0;i<3;i++)p.tick();
  p.guest.c.focused=false;p.tick();const tick=p.host.c.phase_ticks;
  assert.equal(p.host.c.paused,true);assert.equal(p.guest.c.paused,true);
  for(let i=0;i<20;i++)p.tick();assert.equal(p.host.c.phase_ticks,tick);
  p.guest.c.focused=true;p.tick({buttons:[1],x:240,y:300});assert.equal(p.host.c.shots_fired,0);
  p.tick();p.tick({buttons:[1],x:240,y:300});assert.equal(p.host.c.shots_fired,1);
});
test('LAN snapshots have bounded backpressure and stopped peers time out without advancing play',()=>{
  const p=lanPair();p.host.active();for(let i=0;i<3;i++)p.tick();
  const seq=p.host.c.net_snapshot_seq;
  for(let i=0;i<25;i++)p.host.step();assert.ok(p.host.c.net_snapshot_seq-seq<=p.host.c.net_window);
  assert.equal(p.host.c.paused,true);const tick=p.host.c.phase_ticks;
  for(let i=0;i<20;i++)p.host.step();assert.equal(p.host.c.phase_ticks,tick);
  p.host.c.current_time+=6000;p.host.step();assert.equal(p.host.c.net_mode,'local');assert.equal(p.host.c.net_menu,true);
  assert.equal(p.host.c.net_socket,-1);assert.ok(p.host.destroyed.includes(44));
});
test('LAN rejects wrong-socket data, handles connection failure and cleans up resources',()=>{
  const g=game();g.c.net_start(false);g.networkEvent({type:4,id:g.c.net_socket,succeeded:0});
  assert.equal(g.c.net_mode,'local');assert.match(g.c.net_status,/Nao conectou/);
  g.c.net_start(true);g.networkEvent({type:1,id:g.c.net_socket,socket:44});
  g.networkEvent({type:3,id:45,size:999999});assert.equal(g.c.net_mode,'host');
  g.networkEvent({type:3,id:44,size:999999});assert.equal(g.c.net_mode,'local');
  g.c.net_start(true);const s=g.c.net_socket;g.cleanup();assert.ok(g.destroyed.includes(s));
});
test('LAN screen is clickable and editable without modifying gameplay',()=>{
  const g=game();g.step({buttons:[1],x:500,y:450});assert.equal(g.c.net_menu,true);
  g.step();g.step({buttons:[1],x:120,y:190});assert.equal(g.c.net_field,1);
  g.c.keyboard_string='192.168.1.25';g.step();assert.equal(g.c.net_ip,'192.168.1.25');
  g.step({buttons:[1],x:460,y:190});g.c.keyboard_string='16510';g.step();assert.equal(g.c.net_port_text,'16510');
  g.texts.length=0;const before=combat(g.c);g.draw();assert.deepEqual(combat(g.c),before);
  const title=g.texts.findIndex(t=>t.text==='MULTIPLAYER LAN');const labels=g.texts.slice(title);
  for(const t of labels){assert.ok(t.x+t.w<=600&&t.y+t.h<=448);assert.ok(!t.text.endsWith('...'),t.text);}
  for(let i=0;i<labels.length;i++)for(let j=i+1;j<labels.length;j++){
    const a=labels[i],b=labels[j];assert.ok(!(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y));
  }
  g.step({buttons:[1],x:120,y:260});assert.equal(g.c.net_mode,'host');
  g.step();g.step({buttons:[1],x:250,y:410});assert.equal(g.c.net_mode,'local');
});
test('LAN cadence measured with 100ms round trip and a 30Hz guest',()=>{
  const p=lanPair(), pending=[];let received=0;
  for(let frame=0;frame<300;frame++){
    for(let i=pending.length-1;i>=0;i--)if(pending[i].at<=frame){
      const item=pending.splice(i,1)[0];item.to.c.net_receive(item.packet);
      if(item.packet.kind==='state'&&frame>=60)received++;
    }
    p.guest.step();p.host.step();
    for(const [from,to,delay] of [[p.guest,p.host,1],[p.host,p.guest,2]])
      for(const packet of from.packets.splice(0))pending.push({at:frame+delay,to,packet:plain(packet)});
  }
  console.log('LAN 100ms RTT steady snapshot rate: '+(received/8).toFixed(2)+' Hz');
  assert.ok(received/8>=29,'Snapshot flow must sustain the 30Hz simulation at 100ms RTT');
  assert.ok(p.guest.c.net_connected);
});
test('FPS measures elapsed time and HUD exposes local FPS and both peer RTTs',()=>{
  const g=game();for(let i=0;i<60;i++)g.step();assert.equal(g.c.perf_fps,30);
  g.texts.length=0;g.draw();assert.ok(g.texts.some(t=>t.text==='30 FPS'));
  assert.ok(g.texts.some(t=>t.text==='PING --'));
  for(let i=0;i<30;i++){g.c.current_time+=1000/30;g.step();}
  assert.equal(g.c.perf_fps,15);
  const p=lanPair();for(let i=0;i<60;i++)p.tick();
  for(const peer of [p.host,p.guest]){
    assert.ok(peer.c.net_rtt>=0);assert.ok(peer.c.perf_hz>=29);
    peer.draw();assert.ok(peer.texts.some(t=>t.text.startsWith('PING ')&&t.text.endsWith('ms')));
    peer.c.net_start(peer===p.host);assert.equal(peer.c.net_rtt,-1);
  }
});
test('LAN held-input burst latency measurement',()=>{
  const p=lanPair();p.host.active();for(let i=0;i<3;i++)p.tick();
  for(let i=0;i<12;i++)p.guest.step({keys:[68]});
  p.guest.step({keys:[65]});p.deliver(p.guest,p.host);
  let frames=0;do {p.host.step();frames++;} while(p.host.c.input.move_x>=0&&frames<20);
  console.log('Held-input reversal after burst: '+frames+' host ticks');
  assert.equal(frames,1);assert.equal(p.host.c.net_queue.length,0);
});
test('LAN queue compaction preserves press/release actions and ping ignores stale replies',()=>{
  const p=lanPair();for(let i=0;i<3;i++)p.tick();
  const make=(seq)=>({kind:'input',protocol:p.host.c.net_protocol,seq,epoch:p.host.c.net_epoch(),data:[320,280,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]});
  const first=p.host.c.net_rx_seq+1;
  const press=make(first+1);press.data[6]=1;
  const release=make(first+2);release.data[7]=1;
  for(const packet of [make(first),press,release,make(first+3)])p.host.c.net_receive(packet);
  p.host.step();assert.equal(p.host.c.net_remote.seq,first+1);
  p.host.step();assert.equal(p.host.c.net_remote.seq,first+2);
  p.host.step();assert.equal(p.host.c.net_remote.seq,first+3);
  const c=p.guest.c;c.net_probe_pending=123;c.net_probe_sent=c.current_time-67;
  c.net_receive({kind:'pong',protocol:c.net_protocol,probe:122});assert.equal(c.net_probe_pending,123);
  c.net_receive({kind:'pong',protocol:c.net_protocol,probe:123});assert.equal(c.net_rtt,67);
  c.current_time+=100;c.net_receive({kind:'pong',protocol:c.net_protocol,probe:123});assert.equal(c.net_rtt,67);
});
const report={passed:results.filter(r=>r.passed).length,failed:results.filter(r=>!r.passed).length,
  limitations:'Actual GML translated to JS with stub APIs; not GameMaker VM, graphics, audio or hardware verification.',tests:results};
fs.writeFileSync(path.join(root,'build/logic-tests.json'),JSON.stringify(report,null,2));
console.log(`${report.passed} passed, ${report.failed} failed`);if(report.failed)process.exitCode=1;
