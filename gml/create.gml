// Compiled after a generated rules.json header. No campaign or save APIs.
window_set_caption("DELTARUNE / SOUL SWAP / local PvP " + mod_version);
display_set_gui_size(640, 480);
gpu_set_texfilter(false);
var window_scale = max(1, floor(min((display_get_width() - 80) / 640, (display_get_height() - 120) / 480)));
window_set_size(640 * window_scale, 480 * window_scale);
window_center();
// Arena boot bypasses campaign cursor setup: explicitly restore the native pointer.
window_set_cursor(cr_arrow);
randomize();
audio_group_load(1);
// Prefetch the original embedded textures without starting campaign controllers.
var _asset_textures = texturegroup_get_textures("Default");
for (var _tex = 0; _tex < array_length(_asset_textures); _tex++) texture_prefetch(_asset_textures[_tex]);
music_stream = audio_create_stream("battle.ogg");
music_voice = -1;
if (music_stream != -1) {
    music_voice = audio_play_sound(music_stream, 1, true);
    if (music_voice != -1) audio_sound_gain(music_voice, 0.32, 0);
}
character_names = ["KRIS", "SUSIE"];
character_idle = [spr_krisb_idle, spr_susieb_idle];
character_attack = [spr_krisb_attackready, spr_susieb_attackready];
character_defend = [spr_krisb_defend, spr_susieb_defend];
character_hurt = [spr_krisb_hurt, spr_susieb_hurt];
character_victory = [spr_krisb_victory, spr_susieb_victory];
projectile_sprites = [spr_diamondbullet, spr_smallbullet, spr_spadebullet, spr_smallbullet, spr_diamondbullet, spr_diamondbullet, spr_spadebullet, spr_diamondbullet, spr_spadebullet, spr_smallbullet];
projectile_scales = [0.75, 1.5, 0.5, 1.5, 0.75, 0.75, 0.5, 0.65, 0.6, 1.5];

players = [
    { hp: max_hp, inv: 0, flash: 0 },
    { hp: max_hp, inv: 0, flash: 0 }
];
pattern_names = ["RAJADA", "COMETA", "MURALHA", "PULSO", "RICOCHETE", "ORBITA", "PINCA", "COSTURA", "BUMERANGUE", "JARDIM"];
pattern_hints = ["Direito: emissor extra", "Direito: mina radial", "Direito: arraste muralha", "Direito: pulso atrasado", "Direito: arraste refletor", "Direito: inverta a orbita", "Direito: marque cruzamento", "Esq: desenhe / Dir: inverta", "Esq: carregue / Dir: retorne", "Esq: plante / Dir: floresca"];
attack_count = array_length(pattern_names);
// Stable internal artwork IDs; only this curated roster is selectable.
available_attacks = [0, 1, 2, 4, 7, 8, 9];
attack_index = function(_id) {
    for (var _i = 0; _i < array_length(available_attacks); _i++) if (available_attacks[_i] == _id) return _i;
    return -1;
};
selection_page = 0;
qa_preview = false;
help_open = false;
help_page = 0;
help_titles = ["1 / ESCOLHER ATAQUES", "2 / ATACAR COM O MOUSE", "3 / DESVIAR NO TECLADO"];
help_lines = [
    ["No lobby: atacante clica; defensor aperta Enter.",
     "Na selecao, clique primeiro no SLOT 1 ou SLOT 2.",
     "Depois clique no nome do ataque para equipa-lo.",
     "PAGINA mostra mais ataques. Escolha dois diferentes.",
     "Confira os slots e clique em CONFIRMAR.",
     "A roda seleciona no menu; em combate, troca a dupla."],
    ["Mova o cursor DENTRO da caixa de batalha.",
     "Esquerdo: ataque principal. Direito: especial.",
     "Costura: segure, desenhe e solte o esquerdo.",
     "Bumerangue: solte; direito traz a volta pela mira.",
     "Muralha/Refletor: arraste e solte o direito.",
     "Veja as barras: energia e especial precisam recarregar."],
    ["WASD ou setas movem o coracao (SOUL).",
     "Segure Shift ou espaco para mover devagar e mirar a fuga.",
     "Q + direcao: evasao rapida, uma vez por turno.",
     "A evasao NAO da invulnerabilidade. Evite os projeteis.",
     "Apos 15 segundos, passem o mouse e troquem de papel.",
     "Os dois confirmam de novo. HP zero perde a partida."]
];
attack_left = ["Segure: leques alternados de cinco tiros.", "Segure: tres cometas guiados por pouco tempo.", "Segure: parede com passagem na linha da mira.", "Segure: dois aneis; a abertura muda entre eles.", "Segure: tres tiros, cada um rebate duas vezes.", "Segure: oito tiros orbitam a mira e saem em serie.", "Segure: leques cruzados de bordas opostas.", "Desenhe e solte: costura dupla e espinhos laterais.", "Carregue e solte: 3 laminas; carga alta lanca 5.", "Segure: plante ate tres sementes; espere o verde."];
attack_right = ["Clique: emissor extra dispara leques na borda.", "Clique: mina radial em duas ondas alternadas.", "Arraste: duas paredes opostas, passagens deslocadas.", "Clique: dois aneis com aberturas alternadas.", "Arraste e solte para colocar um refletor.", "Clique para inverter o giro em formacao.", "Clique: cruzamento em dois tempos, fixo na mira.", "Clique para inverter a ordem da proxima costura.", "Clique: antecipe a volta PELO CURSOR, depois origem.", "Clique: sementes verdes florescem em duas ondas."];
attack_left[0] = "Segure: leque curto para pressionar a mira.";
attack_left[1] = "Segure: cometas corrigem a rota por pouco tempo.";
attack_left[2] = "Segure: parede com passagem na linha da mira.";
attack_left[4] = "Segure: tiros rebatem duas vezes; controle os cantos.";
attack_left[7] = "Desenhe e solte: bloqueie uma rota com espinhos.";
attack_left[8] = "Solte: laminas de ida e volta; carregar amplia alcance.";
attack_left[9] = "Plante ate tres sementes para preparar uma emboscada.";
attack_right[1] = "Clique: cometas em voo travam rumo ao cursor.";
pattern_hints[1] = "Direito: trave a rota dos cometas";
stroke = [];
stroke_length = 0;
stitch_reverse = false;
charge_ticks = 0;
seeds = [];
loadouts = [[0, 1], [0, 1]];
active_slot = 0;
edit_slot = 0;
switch_timer = 0;
dash_available = true;
dash_remaining = 0;
dash_x = 0;
dash_y = 0;
orbit_sign = 1;
damage_by_pattern = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
phase = "lobby";
phase_ticks = 0;
attacker = 0;
defender = 1;
opening_player = 0;
turn_number = 0;
turn_id = 0;
pattern = 0;
energy = energy_max;
recovering = false;
turn_grazes = 0;
graze_flash = 0;
shot_flash = 0;
hit_feedback = 0;
hit_x = 0;
hit_y = 0;
hit_amount = 0;
match_grazes = [0, 0];
perfect_turns = [0, 0];
debug_overlay = false;
bullet_update_us = 0;
bullet_peak_us = 0;
strategy_cooldown = 0;
special_notice = "";
special_notice_ticks = 0;
right_click_count = 0;
hazards = [];
dragging = false;
drag_x = 320;
drag_y = 280;
mouse_ready = false;
keyboard_ready = false;
role_release_gate = true;
pointer_x = 320;
pointer_y = 280;
target_x = 320;
target_y = 280;
input = { fire: false, fire_pressed: false, fire_released: false, special: false, special_pressed: false,
    special_released: false, ready: false, ready_held: false, focus: false,
    move_x: 0, move_y: 0, wheel: 0, pause: false, mute: false, fullscreen: false, evade: false };
shot_cooldown = 0;
fire_buffer = 0;
shots_fired = 0;
turn_damage = 0;
bullets = [];
soul_x = 320;
soul_y = 300;
soul_old_x = soul_x;
soul_old_y = soul_y;
paused = false;
input_gate = false;
pause_reason = "PAUSED";
pause_choice = 0;
winner = -1;
wins = [0, 0];
ui_tick = 0;
sound_enabled = true;

play_sfx = function(_sound) {
    if (sound_enabled && audio_group_is_loaded(1)) audio_play_sound(_sound, 0, false);
};

sample_inputs = function() {
    // Convert window/fullscreen mouse coordinates to the fixed GUI space.
    pointer_x = device_mouse_x_to_gui(0);
    pointer_y = device_mouse_y_to_gui(0);
    target_x = clamp(pointer_x, arena_left + 12, arena_right - 12);
    target_y = clamp(pointer_y, arena_top + 12, arena_bottom - 12);
    input.fire = mouse_check_button(mb_left);
    input.fire_pressed = mouse_check_button_pressed(mb_left);
    input.fire_released = mouse_check_button_released(mb_left);
    input.special = mouse_check_button(mb_right);
    input.special_pressed = mouse_check_button_pressed(mb_right);
    if (input.special_pressed) right_click_count++;
    input.special_released = mouse_check_button_released(mb_right);
    input.ready = keyboard_check_pressed(vk_enter);
    input.ready_held = keyboard_check(vk_enter);
    input.focus = keyboard_check(vk_shift) || keyboard_check(vk_space);
    input.evade = keyboard_check_pressed(ord("Q"));
    input.move_x = real(keyboard_check(ord("D")) || keyboard_check(vk_right)) - real(keyboard_check(ord("A")) || keyboard_check(vk_left));
    input.move_y = real(keyboard_check(ord("S")) || keyboard_check(vk_down)) - real(keyboard_check(ord("W")) || keyboard_check(vk_up));
    var _len = sqrt(input.move_x * input.move_x + input.move_y * input.move_y);
    if (_len > 1) { input.move_x /= _len; input.move_y /= _len; }
    input.wheel = real(mouse_wheel_down()) - real(mouse_wheel_up());
    input.pause = keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P"));
    input.mute = keyboard_check_pressed(ord("M"));
    input.fullscreen = keyboard_check_pressed(vk_f4);
};

pointer_in = function(_x, _y, _w, _h) {
    return pointer_x >= _x && pointer_x < _x + _w && pointer_y >= _y && pointer_y < _y + _h;
};

clear_attacks = function() {
    dash_remaining = 0;
    cancel_gesture();
    seeds = [];
    special_notice_ticks = 0;
    bullets = [];
    hazards = [];
    dragging = false;
    shot_flash = 0;
    hit_feedback = 0;
    graze_flash = 0;
};

await_roles = function() {
    mouse_ready = false;
    keyboard_ready = false;
    role_release_gate = true;
};

begin_turn = function() {
    turn_id++;
    phase = "handoff";
    phase_ticks = 0;
    await_roles();
    active_slot = 0;
    edit_slot = 0;
    pattern = loadouts[attacker][0];
    selection_page = floor(pattern / 6);
    stitch_reverse = false;
    switch_timer = 0;
    dash_available = true;
    dash_remaining = 0;
    orbit_sign = 1;
    damage_by_pattern = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    energy = energy_max;
    recovering = false;
    turn_grazes = 0;
    bullet_peak_us = 0;
    strategy_cooldown = 0;
    shots_fired = 0;
    shot_cooldown = 0;
    turn_damage = 0;
    clear_attacks();
    soul_x = (arena_left + arena_right) / 2;
    soul_y = arena_bottom - 60;
    soul_old_x = soul_x;
    soul_old_y = soul_y;
    players[defender].inv = 0;
};

reset_match = function() {
    loadouts = [[0, 1], [0, 1]];
    match_grazes = [0, 0];
    perfect_turns = [0, 0];
    for (var _p = 0; _p < 2; _p++) {
        players[_p].hp = max_hp;
        players[_p].inv = 0;
        players[_p].flash = 0;
    }
    attacker = opening_player;
    defender = 1 - attacker;
    turn_number = 0;
    winner = -1;
    paused = false;
    input_gate = false;
    begin_turn();
};

return_to_lobby = function() {
    phase = "lobby";
    paused = false;
    input_gate = false;
    clear_attacks();
    await_roles();
    for (var _p = 0; _p < 2; _p++) {
        players[_p].hp = max_hp;
        players[_p].inv = 0;
        players[_p].flash = 0;
    }
};

finish_match = function() {
    phase = "result";
    clear_attacks();
    await_roles();
    winner = -1;
    if (players[0].hp > players[1].hp) winner = 0;
    if (players[1].hp > players[0].hp) winner = 1;
    if (winner >= 0) wins[winner]++;
    opening_player = 1 - opening_player;
};

advance_turn = function() {
    clear_attacks();
    turn_number++;
    if (players[0].hp <= 0 || players[1].hp <= 0 || turn_number >= max_turns) {
        finish_match();
    } else {
        attacker = 1 - attacker;
        defender = 1 - attacker;
        begin_turn();
    }
};

add_bullet = function(_x, _y, _vx, _vy, _art = -1) {
    if (array_length(bullets) >= bullet_limit) return;
    if (_art < 0) _art = pattern;
    array_push(bullets, { px: _x, py: _y, bx: _x, by: _y, vx: _vx, vy: _vy,
        age: -projectile_warning_ticks, life: _art == 8 ? 320 : projectile_life_ticks, owner: attacker,
        round_id: turn_id, alive: true, art: _art, guided: false, grazed: false,
        bounces: _art == 4 ? 2 : 0, orbit: 0, ox: _x, oy: _y, angle: 0, spin: orbit_sign,
        route: [], waypoint: 0, outbound: 0, returning: false,
        return_x: _x, return_y: _y, return_stage: 0, lane: 0, route_speed: 4 });
};

select_attack = function(_choice) {
    if (attack_index(_choice) < 0) return;
    var _other = 1 - edit_slot;
    if (loadouts[attacker][_other] == _choice) loadouts[attacker][_other] = loadouts[attacker][edit_slot];
    loadouts[attacker][edit_slot] = _choice;
    pattern = _choice;
    active_slot = edit_slot;
    selection_page = floor(attack_index(_choice) / 6);
};

emit_ring = function(_x, _y, _gap_angle, _delay = 24) {
    // A fixed 60-degree opening; the second ring advertises its new opening.
    for (var _a = 0; _a < 360; _a += 15) {
        var _delta = ((_a - _gap_angle + 540) mod 360) - 180;
        if (abs(_delta) > 30 && array_length(bullets) < bullet_limit) {
            add_bullet(_x, _y, lengthdir_x(2.9, _a), lengthdir_y(2.9, _a), 3);
            bullets[array_length(bullets) - 1].age = -_delay;
        }
    }
};

emit_wall = function(_x, _y, _horizontal, _opposite = false) {
    var _positive = _horizontal ? _y < (arena_top + arena_bottom) / 2 : _x < (arena_left + arena_right) / 2;
    if (_opposite) _positive = !_positive;
    var _start = _horizontal ? arena_left + 12 : arena_top + 12;
    var _end = _horizontal ? arena_right : arena_bottom;
    var _gap = _horizontal ? _x : _y;
    for (var _p = _start; _p < _end; _p += 16) {
        if (abs(_p - _gap) <= 26 || array_length(bullets) >= bullet_limit) continue;
        add_bullet(_horizontal ? _p : (_positive ? arena_left + 5 : arena_right - 5),
            _horizontal ? (_positive ? arena_top + 5 : arena_bottom - 5) : _p,
            _horizontal ? 0 : (_positive ? 3.2 : -3.2), _horizontal ? (_positive ? 3.2 : -3.2) : 0, 2);
        bullets[array_length(bullets) - 1].age = -18;
    }
};

edge_position = function(_x, _y) {
    // Closest edge; projectiles never originate directly on the defender.
    var _left = _x - arena_left;
    var _right = arena_right - _x;
    var _top = _y - arena_top;
    var _bottom = arena_bottom - _y;
    var _nearest = min(_left, _right, _top, _bottom);
    if (_nearest == _left) return [arena_left + 5, _y];
    if (_nearest == _right) return [arena_right - 5, _y];
    if (_nearest == _top) return [_x, arena_top + 5];
    return [_x, arena_bottom - 5];
};

fire_burst = function() {
    if (pattern >= 7) return;
    var _cost = pattern == 2 || pattern == 3 ? energy_cost * 2 : energy_cost;
    if (energy < _cost || recovering || switch_timer > 0 || shot_cooldown > 0 || phase != "dodge" || array_length(bullets) > bullet_limit - 48) return;
    energy -= _cost;
    if (energy < _cost) recovering = true;
    shot_flash = 5;
    shots_fired++;
    shot_cooldown = shot_cooldown_ticks;
    var _edge = edge_position(target_x, target_y);
    var _dir = point_direction(_edge[0], _edge[1], target_x, target_y);
    if (pattern == 2) {
        emit_wall(target_x, target_y, _edge[1] == arena_top + 5 || _edge[1] == arena_bottom - 5);
        shot_cooldown = 24;
        play_sfx(snd_menumove);
        return;
    }
    if (pattern == 3) {
        emit_ring(target_x, target_y, _dir + 180, 24);
        emit_ring(target_x, target_y, _dir + 240, 44);
        shot_cooldown = 40;
        play_sfx(snd_menumove);
        return;
    }
    if (pattern == 6) {
        var _opposite_x = arena_left + arena_right - _edge[0];
        var _opposite_y = arena_top + arena_bottom - _edge[1];
        var _other_dir = point_direction(_opposite_x, _opposite_y, target_x, target_y);
        for (var _fan = -1; _fan <= 1; _fan++) {
            add_bullet(_edge[0], _edge[1], lengthdir_x(3.6, _dir + _fan * 18), lengthdir_y(3.6, _dir + _fan * 18));
            add_bullet(_opposite_x, _opposite_y, lengthdir_x(3.6, _other_dir + _fan * 18), lengthdir_y(3.6, _other_dir + _fan * 18));
            bullets[array_length(bullets) - 1].age -= 8;
        }
        shot_cooldown = 16;
        play_sfx(snd_menumove);
        return;
    }
    var _count = pattern == 0 ? 5 : (pattern == 5 ? 8 : 3);
    for (var _n = 0; _n < _count; _n++) {
        var _fan = _n - (_count - 1) / 2;
        var _spread = pattern == 4 ? 28 : (pattern == 0 ? 9 : 12);
        var _heading = _dir + _fan * _spread + (pattern == 0 ? ((shots_fired mod 2) * 2 - 1) * 5 : 0);
        var _before = array_length(bullets);
        var _sx = _edge[0];
        var _sy = _edge[1];
        if (pattern == 1) {
            if (_sy == arena_top + 5 || _sy == arena_bottom - 5) _sx = clamp(_sx + _fan * 26, arena_left + 5, arena_right - 5);
            else _sy = clamp(_sy + _fan * 26, arena_top + 5, arena_bottom - 5);
        }
        add_bullet(_sx, _sy, lengthdir_x(projectile_speed, _heading), lengthdir_y(projectile_speed, _heading));
        if (pattern == 1 && array_length(bullets) > _before) bullets[_before].guided = true;
        if (pattern == 5 && array_length(bullets) > _before) {
            var _orb = bullets[_before];
            _orb.orbit = 24 + _n * 4;
            _orb.ox = clamp(target_x, arena_left + 48, arena_right - 48);
            _orb.oy = clamp(target_y, arena_top + 48, arena_bottom - 48);
            _orb.angle = _n * 45;
            _orb.lane = _n;
            _orb.age = -_orb.orbit;
            _orb.bx = _orb.ox + lengthdir_x(42, _orb.angle);
            _orb.by = _orb.oy + lengthdir_y(42, _orb.angle);
        }
    }
    if (pattern == 1) shot_cooldown = 15;
    if (pattern == 4) shot_cooldown = 18;
    if (pattern == 5) shot_cooldown = 24;
    play_sfx(snd_menumove);
};

place_strategy = function(_x, _y, _horizontal) {
    if (phase != "dodge" || switch_timer > 0 || strategy_cooldown > 0 || phase_ticks < strategy_warning_ticks + 30) return;
    if (pattern >= 7) {
        var _activated = false;
        if (pattern == 7) {
            stitch_reverse = !stitch_reverse;
            _activated = true;
            special_notice = stitch_reverse ? "PROXIMA COSTURA: INVERSA" : "PROXIMA COSTURA: NORMAL";
        } else if (pattern == 8) {
            for (var _i = 0; _i < array_length(bullets); _i++) {
                var _b = bullets[_i];
                if (_b.art == 8 && !_b.returning && _b.age > 0) {
                    return_boomerang(_b);
                    _activated = true;
                }
            }
            if (!_activated) special_notice = "LANCE UM BUMERANGUE PRIMEIRO";
        } else {
            var _sequence = 0;
            for (var _i = 0; _i < array_length(seeds); _i++) {
                var _s = seeds[_i];
                if (_s.travel <= 0 && _s.mature <= 0 && _s.fuse < 0) {
                    _s.fuse = 24 + _sequence * 12;
                    _s.heading = point_direction(_s.sx, _s.sy, target_x, target_y);
                    _sequence++;
                }
            }
            _activated = _sequence > 0;
            if (!_activated) special_notice = "AGUARDE SEMENTES MADURAS";
        }
        if (_activated) { strategy_cooldown = pattern == 7 ? 6 : (pattern == 8 ? 12 : 30); play_sfx(snd_select); }
        return;
    }
    if (pattern == 1) {
        var _locked = false;
        for (var _i = 0; _i < array_length(bullets); _i++) {
            var _b = bullets[_i];
            if (_b.art != 1 || !_b.guided || _b.age <= 0) continue;
            var _heading = point_direction(_b.bx, _b.by, _x, _y);
            _b.vx = lengthdir_x(projectile_speed, _heading);
            _b.vy = lengthdir_y(projectile_speed, _heading);
            _b.guided = false;
            _b.age = -projectile_warning_ticks;
            _locked = true;
        }
        special_notice = _locked ? "ROTA TRAVADA NA MIRA" : "LANCE COMETAS PRIMEIRO";
        if (_locked) { strategy_cooldown = 30; play_sfx(snd_select); }
        return;
    }
    if (pattern == 5) {
        orbit_sign = -orbit_sign;
        for (var _i = 0; _i < array_length(bullets); _i++)
            if (bullets[_i].orbit > 0) bullets[_i].spin = orbit_sign;
        strategy_cooldown = strategy_cooldown_ticks;
        play_sfx(snd_select);
        return;
    }
    var _edge = edge_position(_x, _y);
    array_push(hazards, { kind: pattern, hx: pattern == 0 ? _edge[0] : _x,
        hy: pattern == 0 ? _edge[1] : _y, horizontal: _horizontal,
        heading: point_direction(320, (arena_top + arena_bottom) / 2, _x, _y),
        timer: strategy_warning_ticks, life: 90, pulse: 0, wave: 0,
        round_id: turn_id, owner: attacker });
    strategy_cooldown = strategy_cooldown_ticks;
    play_sfx(snd_select);
};

step_hazards = function() {
    var _keep = [];
    for (var _i = 0; _i < array_length(hazards); _i++) {
        var _h = hazards[_i];
        if (_h.round_id != turn_id || _h.owner != attacker) continue;
        _h.timer--;
        if (_h.timer > 0) { array_push(_keep, _h); continue; }
        if (_h.kind == 0) {
            if (_h.pulse <= 0) {
                var _dir = point_direction(_h.hx, _h.hy, target_x, target_y);
                for (var _fan = -1; _fan <= 1; _fan++)
                    add_bullet(_h.hx, _h.hy, lengthdir_x(projectile_speed, _dir + _fan * 16), lengthdir_y(projectile_speed, _dir + _fan * 16), 0);
                _h.pulse = 20;
            }
            _h.pulse--;
            _h.life--;
            if (_h.life > 0) array_push(_keep, _h);
        } else if (_h.kind == 1) {
            for (var _angle = 0; _angle < 360; _angle += 30)
                add_bullet(_h.hx, _h.hy, lengthdir_x(3, _angle + _h.wave * 15), lengthdir_y(3, _angle + _h.wave * 15), 1);
            if (_h.wave == 0) { _h.wave = 1; _h.timer = 24; array_push(_keep, _h); }
        } else if (_h.kind == 3) {
            emit_ring(_h.hx, _h.hy, _h.heading);
            emit_ring(_h.hx, _h.hy, _h.heading + 60, 44);
        } else if (_h.kind == 4) {
            _h.life--;
            if (_h.life > 0) array_push(_keep, _h);
        } else if (_h.kind == 6) {
            for (var _side = 0; _side < 4; _side++) {
                if ((_side < 2 && _h.wave == 1) || (_side >= 2 && _h.wave == 0)) continue;
                var _xx = _side == 0 ? arena_left + 5 : (_side == 1 ? arena_right - 5 : _h.hx);
                var _yy = _side == 2 ? arena_top + 5 : (_side == 3 ? arena_bottom - 5 : _h.hy);
                var _dir = point_direction(_xx, _yy, _h.hx, _h.hy);
                for (var _fan = -1; _fan <= 1; _fan++)
                    add_bullet(_xx, _yy, lengthdir_x(3.8, _dir + _fan * 16), lengthdir_y(3.8, _dir + _fan * 16), 6);
            }
            if (_h.wave == 0) { _h.wave = 1; _h.timer = 18; array_push(_keep, _h); }
        } else if (_h.kind == 2) {
            emit_wall(_h.hx, _h.hy, _h.horizontal, _h.wave == 1);
            if (_h.wave == 0) {
                _h.wave = 1;
                _h.timer = 30;
                if (_h.horizontal) _h.hx = clamp(_h.hx + (_h.hx < 320 ? 64 : -64), arena_left + 32, arena_right - 32);
                else _h.hy = clamp(_h.hy + (_h.hy < (arena_top + arena_bottom) / 2 ? 48 : -48), arena_top + 32, arena_bottom - 32);
                array_push(_keep, _h);
            }
        }
    }
    hazards = _keep;
};

step_bullets = function() {
    var _start_us = get_timer();
    // Stable in-place compaction: no new survivor array on every simulation tick.
    var _count = array_length(bullets);
    var _write = 0;
    var _victim = players[defender];
    for (var _i = 0; _i < _count; _i++) {
        var _b = bullets[_i];
        if (_b.round_id != turn_id) continue;
        _b.age++;
        _b.life--;
        if (_b.art == 8 && !_b.returning && _b.age > 0) {
            _b.outbound--;
            if (_b.outbound <= 0 || _b.bx + _b.vx < arena_left + 5 || _b.bx + _b.vx > arena_right - 5 || _b.by + _b.vy < arena_top + 5 || _b.by + _b.vy > arena_bottom - 5) return_boomerang(_b);
        }
        if (_b.orbit > 0) {
            _b.orbit--;
            _b.angle += _b.spin * 9;
            _b.bx = _b.ox + lengthdir_x(42, _b.angle);
            _b.by = _b.oy + lengthdir_y(42, _b.angle);
            _b.px = _b.bx;
            _b.py = _b.by;
            if (_b.orbit == 0) {
                var _launch = point_direction(_b.bx, _b.by, target_x, target_y) + ((_b.lane mod 2) * 2 - 1) * 15;
                _b.vx = lengthdir_x(projectile_speed, _launch);
                _b.vy = lengthdir_y(projectile_speed, _launch);
                _b.age = -projectile_warning_ticks;
            }
        }
        if (_b.age > 0) {
            if (array_length(_b.route) > 0) {
                var _point = _b.route[_b.waypoint];
                var _rx_path = _point[0] - _b.bx;
                var _ry_path = _point[1] - _b.by;
                var _remaining = sqrt(_rx_path * _rx_path + _ry_path * _ry_path);
                if (_remaining <= _b.route_speed) {
                    _b.vx = _rx_path;
                    _b.vy = _ry_path;
                    _b.waypoint++;
                    if (_b.waypoint >= array_length(_b.route)) _b.life = 0;
                } else {
                    _b.vx = _rx_path / _remaining * _b.route_speed;
                    _b.vy = _ry_path / _remaining * _b.route_speed;
                }
            }
            if (_b.art == 8 && _b.returning) {
                var _dx_home = (_b.return_stage == 0 ? _b.return_x : _b.ox) - _b.bx;
                var _dy_home = (_b.return_stage == 0 ? _b.return_y : _b.oy) - _b.by;
                var _home_dist = sqrt(_dx_home * _dx_home + _dy_home * _dy_home);
                if (_home_dist <= 5.2) {
                    _b.vx = _dx_home; _b.vy = _dy_home;
                    if (_b.return_stage == 0) _b.return_stage = 1; else _b.life = 0;
                } else { _b.vx = _dx_home / _home_dist * 5.2; _b.vy = _dy_home / _home_dist * 5.2; }
            }
            if (_b.guided && _b.age <= comet_steering_ticks) {
                var _heading = point_direction(0, 0, _b.vx, _b.vy);
                var _desired = point_direction(_b.bx, _b.by, target_x, target_y);
                var _delta = ((_desired - _heading + 540) mod 360) - 180;
                _heading += clamp(_delta, -comet_turn_degrees, comet_turn_degrees);
                _b.vx = lengthdir_x(projectile_speed, _heading);
                _b.vy = lengthdir_y(projectile_speed, _heading);
            }
            _b.px = _b.bx;
            _b.py = _b.by;
            _b.bx += _b.vx;
            _b.by += _b.vy;
            if (_b.bounces > 0) {
                var _flip_x = (_b.bx < arena_left + 5 && _b.vx < 0) || (_b.bx > arena_right - 5 && _b.vx > 0);
                var _flip_y = (_b.by < arena_top + 5 && _b.vy < 0) || (_b.by > arena_bottom - 5 && _b.vy > 0);
                for (var _hi = 0; _hi < array_length(hazards); _hi++) {
                    var _reflector = hazards[_hi];
                    if (_reflector.kind != 4 || _reflector.timer > 0) continue;
                    if (_reflector.horizontal) {
                        if (((_b.py < _reflector.hy && _b.by >= _reflector.hy) || (_b.py > _reflector.hy && _b.by <= _reflector.hy)) && abs(_b.bx - _reflector.hx) <= 40) {
                            _flip_y = true;
                            _b.by = _reflector.hy;
                        }
                    } else {
                        if (((_b.px < _reflector.hx && _b.bx >= _reflector.hx) || (_b.px > _reflector.hx && _b.bx <= _reflector.hx)) && abs(_b.by - _reflector.hy) <= 40) {
                            _flip_x = true;
                            _b.bx = _reflector.hx;
                        }
                    }
                }
                if (_flip_x || _flip_y) {
                    if (_flip_x) { _b.vx = -_b.vx; _b.bx = clamp(_b.bx, arena_left + 5, arena_right - 5); }
                    if (_flip_y) { _b.vy = -_b.vy; _b.by = clamp(_b.by, arena_top + 5, arena_bottom - 5); }
                    _b.bounces--;
                }
            }
            if (_b.owner != defender) {
                // Swept relative motion: both the SOUL and projectile moved this tick.
                var _rx = _b.px - soul_old_x;
                var _ry = _b.py - soul_old_y;
                var _vx = (_b.bx - _b.px) - (soul_x - soul_old_x);
                var _vy = (_b.by - _b.py) - (soul_y - soul_old_y);
                var _len2 = _vx * _vx + _vy * _vy;
                var _t = _len2 > 0 ? clamp(-(_rx * _vx + _ry * _vy) / _len2, 0, 1) : 0;
                var _hx = _rx + _vx * _t;
                var _hy = _ry + _vy * _t;
                var _r = soul_radius + projectile_radius;
                if (_hx * _hx + _hy * _hy <= _r * _r) {
                    // Contact consumes every live projectile, including during damage immunity.
                    _b.alive = false;
                    if (_victim.inv <= 0) {
                    var _damage = min(hit_damage, _victim.hp);
                    _victim.hp = max(0, _victim.hp - _damage);
                    _victim.inv = invulnerability_ticks;
                    _victim.flash = 12;
                    turn_damage += _damage;
                    damage_by_pattern[_b.art] += _damage;
                    hit_feedback = 24;
                    hit_x = soul_x;
                    hit_y = soul_y;
                    hit_amount = _damage;
                    _b.alive = false;
                    play_sfx(snd_hurt1);
                    }
                } else if (_victim.inv <= 0 && !_b.grazed && _hx * _hx + _hy * _hy <= graze_radius * graze_radius) {
                    _b.grazed = true;
                    turn_grazes++;
                    match_grazes[defender]++;
                    if (graze_flash <= 0) play_sfx(snd_graze);
                    graze_flash = 12;
                }
            }
        }
        if (_b.bx < arena_left - 32 || _b.bx > arena_right + 32 || _b.by < arena_top - 32 || _b.by > arena_bottom + 32 || _b.life <= 0) _b.alive = false;
        if (_b.alive) {
            if (_write != _i) bullets[_write] = _b;
            _write++;
        }
    }
    if (_write < _count) array_resize(bullets, _write);
    bullet_update_us = get_timer() - _start_us;
    bullet_peak_us = max(bullet_peak_us, bullet_update_us);
};

ui_text = function(_x, _y, _text, _color, _scale, _width = -1) {
    // Native embedded pixel fonts, without fractional resampling of glyphs.
    draw_set_font(_scale >= 1.4 ? fnt_mainbig : fnt_main);
    if (_width < 0) _width = 622 - _x;
    if (string_width(_text) > _width) {
        while (string_length(_text) > 0 && string_width(_text + "...") > _width)
            _text = string_copy(_text, 1, string_length(_text) - 1);
        _text += "...";
    }
    draw_set_color(_color);
    draw_text_transformed(_x, _y, _text, 1, 1, 0);
};

ui_button = function(_x, _y, _w, _h, _label, _accent, _selected = false) {
    var _hover = pointer_in(_x, _y, _w, _h);
    draw_panel(_x, _y, _w, _h, _selected || _hover ? _accent : make_color_rgb(80, 82, 100));
    draw_set_color(_selected ? make_color_rgb(25, 31, 48) : (_hover ? make_color_rgb(24, 24, 34) : make_color_rgb(12, 12, 20)));
    draw_rectangle(_x + 3, _y + 3, _x + _w - 3, _y + _h - 3, false);
    if (_selected) draw_sprite_ext(spr_custommenu_arrow, 0, _x + 13, _y + _h / 2, 1, 1, 90, _accent, 1);
    ui_text(_x + (_selected ? 26 : 14), _y + floor((_h - 14) / 2), _label, _selected || _hover ? c_white : make_color_rgb(185, 185, 200), 1, _w - (_selected ? 40 : 28));
};

combat_status = function() {
    if (input_gate) return "Solte o esquerdo para habilitar o disparo";
    if (switch_timer > 0) return "Trocando para " + pattern_names[pattern] + "...";
    if (pattern == 7 && array_length(stroke) > 0) return "Desenhe e solte | trajeto " + string(floor(stroke_length)) + "/" + string(stitch_max_length);
    if (pattern == 8 && charge_ticks > 0) return "Solte: " + (charge_ticks >= 20 ? "5" : "3") + " laminas | direito: volta pela mira";
    if (dragging) return "Arraste e solte o direito | fora da arena cancela";
    if (special_notice_ticks > 0) return special_notice;
    return pattern_hints[pattern];
};

draw_heart = function(_x, _y, _color) {
    draw_sprite_ext(spr_dodgeheart_centered_white, 0, _x, _y, 1, 1, 0, _color, 1);
};

draw_panel = function(_x, _y, _width, _height, _color) {
    // This original sprite has native nine-slice enabled; partial draws are forbidden.
    draw_sprite_stretched_ext(spr_battlebg_stretch, 0, _x, _y, _width, _height, _color, 1);
};

draw_character = function(_p, _center_x, _feet_y) {
    var _sprite = character_idle[_p];
    if (phase == "result") {
        if (winner == _p) _sprite = character_victory[_p];
        else if (winner >= 0) _sprite = character_hurt[_p];
    } else if (phase == "lobby") {
        if (_p == opening_player && mouse_ready) _sprite = character_attack[_p];
    } else if (phase != "swap") {
        _sprite = _p == attacker ? character_attack[_p] : character_defend[_p];
    }
    if (players[_p].flash > 0) _sprite = character_hurt[_p];
    var _frame = floor(ui_tick / 6) mod sprite_get_number(_sprite);
    var _facing = _p == 0 ? 1 : -1;
    var _draw_x = floor(_center_x + (sprite_get_xoffset(_sprite) - sprite_get_width(_sprite) / 2) * _facing);
    var _draw_y = floor(_feet_y - sprite_get_height(_sprite) + sprite_get_yoffset(_sprite));
    draw_sprite_ext(_sprite, _frame, _draw_x, _draw_y, _facing, 1, 0, c_white, 1);
};

draw_wall_preview = function(_x, _y, _horizontal, _color, _opposite = false) {
    // Same spacing and gap as the actual wall; the warning has no collision.
    if (_horizontal) {
        var _top = _y < (arena_top + arena_bottom) / 2;
        if (_opposite) _top = !_top;
        for (var _xx = arena_left + 12; _xx < arena_right; _xx += 16)
            if (abs(_xx - _x) > 26)
                draw_sprite_ext(spr_spadebullet, 0, _xx, _top ? arena_top + 5 : arena_bottom - 5, 0.5, 0.5, _top ? 270 : 90, _color, 0.45);
    } else {
        var _left = _x < (arena_left + arena_right) / 2;
        if (_opposite) _left = !_left;
        for (var _yy = arena_top + 12; _yy < arena_bottom; _yy += 16)
            if (abs(_yy - _y) > 26)
                draw_sprite_ext(spr_spadebullet, 0, _left ? arena_left + 5 : arena_right - 5, _yy, 0.5, 0.5, _left ? 0 : 180, _color, 0.45);
    }
};

draw_reflector = function(_x, _y, _horizontal, _color) {
    for (var _offset = -40; _offset <= 40; _offset += 10)
        draw_sprite_ext(spr_diamondbullet, 0, _x + (_horizontal ? _offset : 0), _y + (_horizontal ? 0 : _offset), 0.4, 0.4, 45, _color, 0.65);
};

draw_bounce_preview = function(_x, _y, _color) {
    var _dir = point_direction(_x, _y, target_x, target_y);
    var _vx = lengthdir_x(1, _dir);
    var _vy = lengthdir_y(1, _dir);
    var _tx = abs(_vx) < 0.0001 ? 10000 : ((_vx > 0 ? arena_right - 5 : arena_left + 5) - _x) / _vx;
    var _ty = abs(_vy) < 0.0001 ? 10000 : ((_vy > 0 ? arena_bottom - 5 : arena_top + 5) - _y) / _vy;
    var _distance = min(_tx, _ty);
    var _horizontal = _ty <= _tx;
    for (var _i = 0; _i < array_length(hazards) + 1; _i++) {
        var _rx = drag_x;
        var _ry = drag_y;
        var _flat = abs(target_x - drag_x) >= abs(target_y - drag_y);
        if (_i < array_length(hazards)) {
            var _h = hazards[_i];
            if (_h.kind != 4 || _h.timer > 0) continue;
            _rx = _h.hx;
            _ry = _h.hy;
            _flat = _h.horizontal;
        } else if (!dragging) continue;
        var _component = _flat ? _vy : _vx;
        if (abs(_component) < 0.0001) continue;
        var _t = (_flat ? _ry - _y : _rx - _x) / _component;
        var _offset = _flat ? _x + _vx * _t - _rx : _y + _vy * _t - _ry;
        if (_t > 0 && _t < _distance && abs(_offset) <= 40) {
            _distance = _t;
            _horizontal = _flat;
        }
    }
    var _bx = _x + _vx * _distance;
    var _by = _y + _vy * _distance;
    draw_set_color(_color);
    draw_set_alpha(0.35);
    draw_line(_x, _y, _bx, _by);
    if (_horizontal) _vy = -_vy; else _vx = -_vx;
    draw_line(_bx, _by, clamp(_bx + _vx * 80, arena_left + 5, arena_right - 5), clamp(_by + _vy * 80, arena_top + 5, arena_bottom - 5));
    draw_set_alpha(1);
};

cancel_gesture = function() {
    fire_buffer = 0;
    stroke = [];
    stroke_length = 0;
    charge_ticks = 0;
};

return_boomerang = function(_b) {
    if (_b.returning) return;
    _b.returning = true;
    _b.age = -projectile_warning_ticks;
    // Lock the cursor waypoint once. Moving the mouse during the warning cannot retarget it.
    var _heading = point_direction(_b.bx, _b.by, _b.ox, _b.oy);
    _b.return_x = clamp(target_x + lengthdir_x(_b.lane * 22, _heading + 90), arena_left + 12, arena_right - 12);
    _b.return_y = clamp(target_y + lengthdir_y(_b.lane * 22, _heading + 90), arena_top + 12, arena_bottom - 12);
    _b.return_stage = 0;
    _b.vx = 0;
    _b.vy = 0;
};

pay_creative_shot = function() {
    energy -= energy_cost * 2;
    if (energy < energy_cost * 2) recovering = true;
    shots_fired++;
    shot_flash = 5;
    shot_cooldown = 18;
    play_sfx(snd_menumove);
};

step_creative_input = function(_inside) {
    if (!_inside) { cancel_gesture(); return; }
    if (switch_timer > 0 || input_gate) { cancel_gesture(); return; }
    var _can = phase == "dodge" && energy >= energy_cost * 2 && !recovering && shot_cooldown <= 0 && array_length(bullets) <= bullet_limit - 24;
    if (pattern == 7) {
        if (input.fire_pressed && _can) {
            stroke = [[target_x, target_y]];
            stroke_length = 0;
        }
        if (input.fire && array_length(stroke) > 0 && array_length(stroke) < 32) {
            var _last = stroke[array_length(stroke) - 1];
            var _dx = target_x - _last[0];
            var _dy = target_y - _last[1];
            var _distance = sqrt(_dx * _dx + _dy * _dy);
            var _allowed = min(_distance, stitch_max_length - stroke_length);
            if (_distance >= 6 && _allowed > 0) {
                array_push(stroke, [_last[0] + _dx / _distance * _allowed, _last[1] + _dy / _distance * _allowed]);
                stroke_length += _allowed;
            }
        }
        if (input.fire_released && array_length(stroke) > 0) {
            if (_can && stroke_length >= 12 && phase_ticks > stitch_warning_ticks + 30) {
                var _route = [];
                for (var _i = 0; _i < array_length(stroke); _i++) {
                    var _idx = stitch_reverse ? array_length(stroke) - 1 - _i : _i;
                    array_push(_route, stroke[_idx]);
                }
                var _reverse = [];
                for (var _i = array_length(_route) - 1; _i >= 0; _i--) array_push(_reverse, _route[_i]);
                for (var _n = 0; _n < 6; _n++) {
                    var _path = _n < 3 ? _route : _reverse;
                    add_bullet(_path[0][0], _path[0][1], 0, 0, 7);
                    var _b = bullets[array_length(bullets) - 1];
                    _b.route = _path;
                    _b.waypoint = 1;
                    _b.age = -stitch_warning_ticks - _n * 8;
                }
                // Equidistant thorns cover the sides of the drawn route, not just its endpoints.
                var _next = 20;
                var _walked = 0;
                for (var _i = 1; _i < array_length(_route); _i++) {
                    var _a = _route[_i - 1];
                    var _z = _route[_i];
                    var _dx = _z[0] - _a[0];
                    var _dy = _z[1] - _a[1];
                    var _len = sqrt(_dx * _dx + _dy * _dy);
                    while (_len > 0 && _next <= _walked + _len) {
                        var _t = (_next - _walked) / _len;
                        for (var _side = -1; _side <= 1; _side += 2) {
                            add_bullet(_a[0] + _dx * _t, _a[1] + _dy * _t, -_dy / _len * 3.3 * _side, _dx / _len * 3.3 * _side, 7);
                            bullets[array_length(bullets) - 1].age = -stitch_warning_ticks - 12;
                        }
                        _next += 40;
                    }
                    _walked += _len;
                }
                pay_creative_shot();
                shot_cooldown = 24;
            }
            cancel_gesture();
        }
    } else if (pattern == 8) {
        if (input.fire_pressed && _can) charge_ticks = 1;
        if (input.fire && charge_ticks > 0) charge_ticks = min(30, charge_ticks + 1);
        if (input.fire_released && charge_ticks > 0) {
            if (_can) {
                var _edge = edge_position(target_x, target_y);
                var _heading = point_direction(_edge[0], _edge[1], target_x, target_y);
                var _dx = target_x - _edge[0];
                var _dy = target_y - _edge[1];
                var _distance = sqrt(_dx * _dx + _dy * _dy) + 60 + charge_ticks * 2;
                var _count = charge_ticks >= 20 ? 2 : 1;
                for (var _fan = -_count; _fan <= _count; _fan++) {
                    add_bullet(_edge[0], _edge[1], lengthdir_x(4.5, _heading + _fan * 14), lengthdir_y(4.5, _heading + _fan * 14), 8);
                    var _b = bullets[array_length(bullets) - 1];
                    _b.outbound = ceil(_distance / 4.5);
                    _b.lane = _fan;
                }
                pay_creative_shot();
            }
            charge_ticks = 0;
        }
    } else if (pattern == 9 && input.fire && _can && array_length(seeds) < seed_limit && phase_ticks > 90) {
        var _edge = edge_position(target_x, target_y);
        var _dx = target_x - _edge[0];
        var _dy = target_y - _edge[1];
        var _travel = max(1, ceil(sqrt(_dx * _dx + _dy * _dy) / 4));
        array_push(seeds, { sx: _edge[0], sy: _edge[1], tx: target_x, ty: target_y,
            vx: _dx / _travel, vy: _dy / _travel, travel: _travel, mature: 12,
            fuse: -1, bloom: 0, life: 240, heading: point_direction(_edge[0], _edge[1], target_x, target_y), round_id: turn_id });
        pay_creative_shot();
    }
};

step_seeds = function() {
    var _keep = [];
    for (var _i = 0; _i < array_length(seeds); _i++) {
        var _s = seeds[_i];
        if (_s.round_id != turn_id) continue;
        _s.life--;
        if (_s.travel > 0) {
            _s.sx += _s.vx;
            _s.sy += _s.vy;
            _s.travel--;
        } else if (_s.mature > 0) _s.mature--;
        if (_s.fuse > 0) {
            _s.fuse--;
            if (_s.fuse == 0) {
                for (var _angle = 0; _angle < 360; _angle += 36)
                    add_bullet(_s.sx, _s.sy, lengthdir_x(2.8, _s.heading + _angle + _s.bloom * 18), lengthdir_y(2.8, _s.heading + _angle + _s.bloom * 18), 9);
                if (_s.bloom == 0) {
                    for (var _fan = -1; _fan <= 1; _fan++)
                        add_bullet(_s.sx, _s.sy, lengthdir_x(4.2, _s.heading + _fan * 14), lengthdir_y(4.2, _s.heading + _fan * 14), 9);
                    _s.bloom = 1;
                    _s.fuse = 24;
                } else continue;
            }
        }
        if (_s.life > 0) array_push(_keep, _s);
    }
    seeds = _keep;
};

draw_route = function(_route, _color) {
    draw_set_color(_color);
    draw_set_alpha(0.4);
    for (var _i = 1; _i < array_length(_route); _i++)
        draw_line(_route[_i - 1][0], _route[_i - 1][1], _route[_i][0], _route[_i][1]);
    draw_set_alpha(1);
    if (array_length(_route) > 0)
        draw_sprite_ext(spr_custommenu_arrow, 0, _route[0][0], _route[0][1], 1, 1, 0, _color, 1);
};

// Deterministic visual QA: explicitly opt in via runner arguments; never active in normal play.
if (parameter_count() >= 2 && parameter_string(1) == "--pvp-ui-check") {
    qa_preview = true;
    if (parameter_count() >= 3 && parameter_string(3) == "native") {
        window_set_size(640, 480);
        window_center();
    }
    var _case = parameter_string(2);
    pointer_x = 390;
    pointer_y = 200;
    if (_case == "help") { help_open = true; help_page = 0; }
    else if (_case != "lobby") {
        reset_match();
        loadouts[0] = [7, 9];
        if (_case == "menu") {
            phase = "plan";
            phase_ticks = 270;
            edit_slot = 1;
            active_slot = 1;
            pattern = 9;
            selection_page = 1;
        } else {
            phase = "dodge";
            phase_ticks = 330;
            pattern = _case == "garden" ? 8 : 7;
            stroke = [[190, 230], [280, 250], [300, 300]];
            stroke_length = 150;
            special_notice = "ESPECIAL RECARREGANDO";
            special_notice_ticks = 40;
            graze_flash = 10;
            hit_feedback = 20;
            hit_amount = 10;
            hit_x = soul_x;
            hit_y = soul_y;
            energy = 42;
            strategy_cooldown = 70;
            if (_case == "garden") {
                cancel_gesture();
                array_push(seeds, {sx: 300, sy: 260, travel: 0, mature: 0, fuse: 18, heading: 35, bloom: 0});
                charge_ticks = 30;
            }
            if (_case == "pause") paused = true;
            // Actual attack helpers and simulation, frozen after a reproducible launch.
            if (string_copy(_case, 1, 6) == "attack") {
                clear_attacks();
                pattern = real(string_copy(_case, 7, 1));
                loadouts[0] = [pattern, (pattern + 1) mod attack_count];
                energy = energy_max;
                strategy_cooldown = 0;
                target_x = 320; target_y = 270;
                pointer_x = target_x; pointer_y = target_y;
                players[defender].inv = 1000;
                if (pattern < 7) fire_burst();
                else {
                    input.fire_pressed = true; input.fire = true;
                    step_creative_input(true);
                    input.fire_pressed = false;
                    if (pattern == 7) { target_x = 460; target_y = 320; step_creative_input(true); }
                    if (pattern == 8) charge_ticks = 24;
                    input.fire = false; input.fire_released = true;
                    step_creative_input(true);
                }
                for (var _tick = 0; _tick < 40; _tick++) { step_seeds(); step_hazards(); step_bullets(); }
                if (pattern == 8 || pattern == 9) { target_x = 380; target_y = 310; place_strategy(target_x, target_y, true); }
                if (pattern == 2 || pattern == 3) place_strategy(280, 240, true);
                if (string_copy(_case, 8, 4) == "late") {
                    for (var _tick = 0; _tick < 32; _tick++) { step_seeds(); step_hazards(); step_bullets(); }
                }
                shot_flash = 0;
            }
        }
    }
}
if (parameter_count() >= 1 && parameter_string(1) == "--pvp-help") help_open = true;
