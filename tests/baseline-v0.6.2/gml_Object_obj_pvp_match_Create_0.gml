mod_version = "0.6.2";
stitch_max_length = 160;
stitch_warning_ticks = 24;
seed_limit = 3;
tick_rate = 30;
max_hp = 100;
hit_damage = 10;
invulnerability_ticks = 24;
planning_ticks = 300;
telegraph_ticks = 36;
dodge_ticks = 450;
swap_ticks = 90;
switch_warning_ticks = 18;
dash_ticks = 6;
dash_speed = 8;
shot_cooldown_ticks = 15;
energy_max = 100;
energy_cost = 10;
energy_regen = 0.9;
energy_resume = 30;
graze_radius = 18;
bullet_limit = 256;
strategy_cooldown_ticks = 120;
strategy_warning_ticks = 30;
projectile_life_ticks = 180;
projectile_speed = 2.5;
comet_steering_ticks = 30;
comet_turn_degrees = 3;
max_turns = 12;
soul_speed = 4;
focus_speed = 2;
soul_radius = 3.2;
projectile_radius = 5;
projectile_warning_ticks = 12;
arena_left = 112;
arena_right = 528;
arena_top = 180;
arena_bottom = 392;
window_set_caption("DELTARUNE / SOUL SWAP / local PvP " + mod_version);
display_set_gui_size(640, 480);
gpu_set_texfilter(false);
var window_scale = max(1, floor(min((display_get_width() - 80) / 640, (display_get_height() - 120) / 480)));
window_set_size(640 * window_scale, 480 * window_scale);
window_center();
window_set_cursor(cr_arrow);
randomize();
audio_group_load(audio_sfx);
var _asset_textures = texturegroup_get_textures("Default");
for (var _tex = 0; _tex < array_length(_asset_textures); _tex++)
{
    texture_prefetch(_asset_textures[_tex]);
}
music_stream = audio_create_stream("battle.ogg");
music_voice = -1;
if (music_stream != -1)
{
    music_voice = audio_play_sound(music_stream, 1, true);
    if (music_voice != -1)
    {
        audio_sound_gain(music_voice, 0.32, 0);
    }
}
character_names = ["KRIS", "SUSIE"];
character_idle = [1429, 1444];
character_attack = [1421, 1458];
character_defend = [1430, 1451];
character_hurt = [1427, 1450];
character_victory = [1418, 1442];
projectile_sprites = [1384, 1558, 2264, 1558, 1384, 1384, 2264, 1384, 2264, 1558];
projectile_scales = [0.75, 1.5, 0.5, 1.5, 0.75, 0.75, 0.5, 0.65, 0.6, 1.5];
players = [
{
    hp: max_hp,
    inv: 0,
    flash: 0
}, 
{
    hp: max_hp,
    inv: 0,
    flash: 0
}];
pattern_names = ["RAJADA", "COMETA", "MURALHA", "PULSO", "RICOCHETE", "ORBITA", "PINCA", "COSTURA", "BUMERANGUE", "JARDIM"];
pattern_hints = ["Direito: emissor extra", "Direito: mina radial", "Direito: arraste muralha", "Direito: pulso atrasado", "Direito: arraste refletor", "Direito: inverta a orbita", "Direito: marque cruzamento", "Esq: desenhe / Dir: inverta", "Esq: carregue / Dir: retorne", "Esq: plante / Dir: floresca"];
attack_count = array_length(pattern_names);
selection_page = 0;
qa_preview = false;
help_open = false;
help_page = 0;
help_titles = ["1 / ESCOLHER ATAQUES", "2 / ATACAR COM O MOUSE", "3 / DESVIAR NO TECLADO"];
help_lines = [["No lobby: atacante clica; defensor aperta Enter.", "Na selecao, clique primeiro no SLOT 1 ou SLOT 2.", "Depois clique no nome do ataque para equipa-lo.", "PAGINA mostra mais ataques. Escolha dois diferentes.", "Confira os slots e clique em CONFIRMAR.", "A roda seleciona no menu; em combate, troca a dupla."], ["Mova o cursor DENTRO da caixa de batalha.", "Esquerdo: ataque principal. Direito: especial.", "Costura: segure, desenhe e solte o esquerdo.", "Bumerangue: segure para carregar e solte para lancar.", "Muralha/Refletor: arraste e solte o direito.", "Veja as barras: energia e especial precisam recarregar."], ["WASD ou setas movem o coracao (SOUL).", "Segure Shift ou espaco para mover devagar e mirar a fuga.", "Q + direcao: evasao rapida, uma vez por turno.", "A evasao NAO da invulnerabilidade. Evite os projeteis.", "Apos 15 segundos, passem o mouse e troquem de papel.", "Os dois confirmam de novo. HP zero perde a partida."]];
attack_left = ["Segure para disparar um leque.", "Segure: cometas seguem a mira por um instante.", "Segure para disparar um leque aberto.", "Segure para lancar aneis com uma abertura.", "Segure: cada tiro rebate uma vez.", "Segure: tiros giram e depois sao lancados.", "Segure: tiros partem de duas bordas.", "Segure, desenhe um caminho e solte para disparar.", "Segure para carregar alcance; solte para lancar.", "Segure para plantar ate tres sementes."];
attack_right = ["Clique para posicionar um emissor extra na borda.", "Clique para colocar uma mina com aviso.", "Arraste e solte: direcao da muralha e abertura.", "Clique para posicionar um pulso atrasado.", "Arraste e solte para colocar um refletor.", "Clique para inverter o giro em formacao.", "Clique para marcar um cruzamento de rajadas.", "Clique para inverter o sentido da proxima costura.", "Clique para antecipar a volta de um tiro ativo.", "Clique para ativar as sementes VERDES em sequencia."];
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
input = 
{
    fire: false,
    fire_pressed: false,
    special: false,
    special_pressed: false,
    special_released: false,
    ready: false,
    ready_held: false,
    focus: false,
    move_x: 0,
    move_y: 0,
    wheel: 0,
    pause: false,
    mute: false,
    fullscreen: false
};
shot_cooldown = 0;
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

play_sfx = function(arg0)
{
    if (sound_enabled && audio_group_is_loaded(audio_sfx))
    {
        audio_play_sound(arg0, 0, false);
    }
};

sample_inputs = function()
{
    pointer_x = device_mouse_x_to_gui(0);
    pointer_y = device_mouse_y_to_gui(0);
    target_x = clamp(pointer_x, arena_left + 12, arena_right - 12);
    target_y = clamp(pointer_y, arena_top + 12, arena_bottom - 12);
    input.fire = mouse_check_button(mb_left);
    input.fire_pressed = mouse_check_button_pressed(mb_left);
    input.fire_released = mouse_check_button_released(mb_left);
    input.special = mouse_check_button(mb_right);
    input.special_pressed = mouse_check_button_pressed(mb_right);
    if (input.special_pressed)
    {
        right_click_count++;
    }
    input.special_released = mouse_check_button_released(mb_right);
    input.ready = keyboard_check_pressed(vk_enter);
    input.ready_held = keyboard_check(vk_enter);
    input.focus = keyboard_check(vk_shift) || keyboard_check(vk_space);
    input.evade = keyboard_check_pressed(ord("Q"));
    input.move_x = real(keyboard_check(ord("D")) || keyboard_check(vk_right)) - real(keyboard_check(ord("A")) || keyboard_check(vk_left));
    input.move_y = real(keyboard_check(ord("S")) || keyboard_check(vk_down)) - real(keyboard_check(ord("W")) || keyboard_check(vk_up));
    var _len = sqrt((input.move_x * input.move_x) + (input.move_y * input.move_y));
    if (_len > 1)
    {
        input.move_x /= _len;
        input.move_y /= _len;
    }
    input.wheel = real(mouse_wheel_down()) - real(mouse_wheel_up());
    input.pause = keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("P"));
    input.mute = keyboard_check_pressed(ord("M"));
    input.fullscreen = keyboard_check_pressed(vk_f4);
};

pointer_in = function(arg0, arg1, arg2, arg3)
{
    return pointer_x >= arg0 && pointer_x < (arg0 + arg2) && pointer_y >= arg1 && pointer_y < (arg1 + arg3);
};

clear_attacks = function()
{
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

await_roles = function()
{
    mouse_ready = false;
    keyboard_ready = false;
    role_release_gate = true;
};

begin_turn = function()
{
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

reset_match = function()
{
    loadouts = [[0, 1], [0, 1]];
    match_grazes = [0, 0];
    perfect_turns = [0, 0];
    for (var _p = 0; _p < 2; _p++)
    {
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

return_to_lobby = function()
{
    phase = "lobby";
    paused = false;
    input_gate = false;
    clear_attacks();
    await_roles();
    for (var _p = 0; _p < 2; _p++)
    {
        players[_p].hp = max_hp;
        players[_p].inv = 0;
        players[_p].flash = 0;
    }
};

finish_match = function()
{
    phase = "result";
    clear_attacks();
    await_roles();
    winner = -1;
    if (players[0].hp > players[1].hp)
    {
        winner = 0;
    }
    if (players[1].hp > players[0].hp)
    {
        winner = 1;
    }
    if (winner >= 0)
    {
        wins[winner]++;
    }
    opening_player = 1 - opening_player;
};

advance_turn = function()
{
    clear_attacks();
    turn_number++;
    if (players[0].hp <= 0 || players[1].hp <= 0 || turn_number >= max_turns)
    {
        finish_match();
    }
    else
    {
        attacker = 1 - attacker;
        defender = 1 - attacker;
        begin_turn();
    }
};

add_bullet = function(arg0, arg1, arg2, arg3, arg4 = -1)
{
    if (array_length(bullets) >= bullet_limit)
    {
        exit;
    }
    if (arg4 < 0)
    {
        arg4 = pattern;
    }
    array_push(bullets, 
    {
        px: arg0,
        py: arg1,
        bx: arg0,
        by: arg1,
        vx: arg2,
        vy: arg3,
        age: -projectile_warning_ticks,
        life: projectile_life_ticks,
        owner: attacker,
        round_id: turn_id,
        alive: true,
        art: arg4,
        guided: false,
        grazed: false,
        bounces: (arg4 == 4) ? 1 : 0,
        orbit: 0,
        ox: arg0,
        oy: arg1,
        angle: 0,
        spin: orbit_sign,
        route: [],
        waypoint: 0,
        outbound: 0,
        returning: false
    });
};

select_attack = function(arg0)
{
    var _other = 1 - edit_slot;
    if (loadouts[attacker][_other] == arg0)
    {
        loadouts[attacker][_other] = loadouts[attacker][edit_slot];
    }
    loadouts[attacker][edit_slot] = arg0;
    pattern = arg0;
    active_slot = edit_slot;
    selection_page = floor(arg0 / 6);
};

emit_ring = function(arg0, arg1, arg2)
{
    for (var _a = 0; _a < 360; _a += 30)
    {
        var _delta = (((_a - arg2) + 540) % 360) - 180;
        if (abs(_delta) > 45)
        {
            add_bullet(arg0, arg1, lengthdir_x(2, _a), lengthdir_y(2, _a), 3);
        }
    }
};

edge_position = function(arg0, arg1)
{
    var _left = arg0 - arena_left;
    var _right = arena_right - arg0;
    var _top = arg1 - arena_top;
    var _bottom = arena_bottom - arg1;
    var _nearest = min(_left, _right, _top, _bottom);
    if (_nearest == _left)
    {
        return [arena_left + 5, arg1];
    }
    if (_nearest == _right)
    {
        return [arena_right - 5, arg1];
    }
    if (_nearest == _top)
    {
        return [arg0, arena_top + 5];
    }
    return [arg0, arena_bottom - 5];
};

fire_burst = function()
{
    if (pattern >= 7)
    {
        exit;
    }
    if (energy < energy_cost || recovering || switch_timer > 0 || shot_cooldown > 0 || phase != "dodge" || array_length(bullets) > (bullet_limit - 12))
    {
        exit;
    }
    energy -= energy_cost;
    if (energy < energy_cost)
    {
        recovering = true;
    }
    shot_flash = 5;
    shots_fired++;
    shot_cooldown = shot_cooldown_ticks;
    var _edge = edge_position(target_x, target_y);
    var _dir = point_direction(_edge[0], _edge[1], target_x, target_y);
    if (pattern == 3)
    {
        emit_ring(_edge[0], _edge[1], _dir);
        shot_cooldown = shot_cooldown_ticks * 2;
        play_sfx(260);
        exit;
    }
    if (pattern == 6)
    {
        var _opposite_x = (arena_left + arena_right) - _edge[0];
        var _opposite_y = (arena_top + arena_bottom) - _edge[1];
        var _other_dir = point_direction(_opposite_x, _opposite_y, target_x, target_y);
        add_bullet(_edge[0], _edge[1], lengthdir_x(2.3, _dir), lengthdir_y(2.3, _dir));
        add_bullet(_opposite_x, _opposite_y, lengthdir_x(2.3, _other_dir), lengthdir_y(2.3, _other_dir));
        play_sfx(260);
        exit;
    }
    var _spread = (pattern == 2) ? 18 : 9;
    var _count = (pattern == 1 || pattern == 4) ? 0 : 1;
    var _fan = -_count;
    while (_fan <= _count)
    {
        var _before = array_length(bullets);
        add_bullet(_edge[0], _edge[1], lengthdir_x(projectile_speed, _dir + (_fan * _spread)), lengthdir_y(projectile_speed, _dir + (_fan * _spread)));
        if (pattern == 1 && array_length(bullets) > _before)
        {
            bullets[_before].guided = true;
        }
        if (pattern == 5 && array_length(bullets) > _before)
        {
            var _orb = bullets[_before];
            _orb.orbit = 30;
            _orb.ox = clamp(_edge[0], arena_left + 28, arena_right - 28);
            _orb.oy = clamp(_edge[1], arena_top + 28, arena_bottom - 28);
            _orb.angle = _fan * 120;
            _orb.age = -30;
            _orb.bx = _orb.ox + lengthdir_x(18, _orb.angle);
            _orb.by = _orb.oy + lengthdir_y(18, _orb.angle);
        }
        _fan++;
    }
    play_sfx(260);
};

place_strategy = function(arg0, arg1, arg2)
{
    if (phase != "dodge" || switch_timer > 0 || strategy_cooldown > 0 || phase_ticks < (strategy_warning_ticks + 30))
    {
        exit;
    }
    if (pattern >= 7)
    {
        var _activated = false;
        if (pattern == 7)
        {
            stitch_reverse = !stitch_reverse;
            _activated = true;
            special_notice = stitch_reverse ? "PROXIMA COSTURA: INVERSA" : "PROXIMA COSTURA: NORMAL";
        }
        else if (pattern == 8)
        {
            for (var _i = 0; _i < array_length(bullets); _i++)
            {
                var _b = bullets[_i];
                if (_b.art == 8 && !_b.returning && _b.age > 0)
                {
                    return_boomerang(_b);
                    _activated = true;
                }
            }
            if (!_activated)
            {
                special_notice = "LANCE UM BUMERANGUE PRIMEIRO";
            }
        }
        else
        {
            var _sequence = 0;
            for (var _i = 0; _i < array_length(seeds); _i++)
            {
                var _s = seeds[_i];
                if (_s.travel <= 0 && _s.mature <= 0 && _s.fuse < 0)
                {
                    _s.fuse = 24 + (_sequence * 12);
                    _sequence++;
                }
            }
            _activated = _sequence > 0;
            if (!_activated)
            {
                special_notice = "AGUARDE SEMENTES MADURAS";
            }
        }
        if (_activated)
        {
            strategy_cooldown = strategy_cooldown_ticks;
            play_sfx(261);
        }
        exit;
    }
    if (pattern == 5)
    {
        orbit_sign = -orbit_sign;
        for (var _i = 0; _i < array_length(bullets); _i++)
        {
            if (bullets[_i].orbit > 0)
            {
                bullets[_i].spin = orbit_sign;
            }
        }
        strategy_cooldown = strategy_cooldown_ticks;
        play_sfx(261);
        exit;
    }
    var _edge = edge_position(arg0, arg1);
    array_push(hazards, 
    {
        kind: pattern,
        hx: (pattern == 0) ? _edge[0] : arg0,
        hy: (pattern == 0) ? _edge[1] : arg1,
        horizontal: arg2,
        heading: point_direction(320, (arena_top + arena_bottom) / 2, arg0, arg1),
        timer: strategy_warning_ticks,
        life: 90,
        pulse: 0,
        round_id: turn_id,
        owner: attacker
    });
    strategy_cooldown = strategy_cooldown_ticks;
    play_sfx(261);
};

step_hazards = function()
{
    var _keep = [];
    for (var _i = 0; _i < array_length(hazards); _i++)
    {
        var _h = hazards[_i];
        if (_h.round_id != turn_id || _h.owner != attacker)
        {
            continue;
        }
        _h.timer--;
        if (_h.timer > 0)
        {
            array_push(_keep, _h);
        }
        else if (_h.kind == 0)
        {
            if (_h.pulse <= 0)
            {
                var _dir = point_direction(_h.hx, _h.hy, target_x, target_y);
                add_bullet(_h.hx, _h.hy, lengthdir_x(projectile_speed, _dir), lengthdir_y(projectile_speed, _dir), 0);
                _h.pulse = 24;
            }
            _h.pulse--;
            _h.life--;
            if (_h.life > 0)
            {
                array_push(_keep, _h);
            }
        }
        else if (_h.kind == 1)
        {
            for (var _angle = 0; _angle < 360; _angle += 45)
            {
                add_bullet(_h.hx, _h.hy, lengthdir_x(2, _angle), lengthdir_y(2, _angle), 1);
            }
        }
        else if (_h.kind == 3)
        {
            emit_ring(_h.hx, _h.hy, _h.heading);
        }
        else if (_h.kind == 4)
        {
            _h.life--;
            if (_h.life > 0)
            {
                array_push(_keep, _h);
            }
        }
        else if (_h.kind == 6)
        {
            for (var _side = 0; _side < 4; _side++)
            {
                var _xx = (_side == 0) ? (arena_left + 5) : ((_side == 1) ? (arena_right - 5) : _h.hx);
                var _yy = (_side == 2) ? (arena_top + 5) : ((_side == 3) ? (arena_bottom - 5) : _h.hy);
                var _dir = point_direction(_xx, _yy, _h.hx, _h.hy);
                for (var _fan = -1; _fan <= 1; _fan++)
                {
                    add_bullet(_xx, _yy, lengthdir_x(2, _dir + (_fan * 12)), lengthdir_y(2, _dir + (_fan * 12)), 6);
                }
            }
        }
        else if (_h.kind == 2)
        {
            if (_h.horizontal)
            {
                var _from_top = _h.hy < ((arena_top + arena_bottom) / 2);
                var _xx = arena_left + 16;
                while (_xx < arena_right)
                {
                    if (abs(_xx - _h.hx) > 34)
                    {
                        add_bullet(_xx, _from_top ? (arena_top + 5) : (arena_bottom - 5), 0, _from_top ? 2 : -2, 2);
                    }
                    _xx += 24;
                }
            }
            else
            {
                var _from_left = _h.hx < ((arena_left + arena_right) / 2);
                var _yy = arena_top + 16;
                while (_yy < arena_bottom)
                {
                    if (abs(_yy - _h.hy) > 34)
                    {
                        add_bullet(_from_left ? (arena_left + 5) : (arena_right - 5), _yy, _from_left ? 2 : -2, 0, 2);
                    }
                    _yy += 24;
                }
            }
        }
    }
    hazards = _keep;
};

step_bullets = function()
{
    var _start_us = get_timer();
    var _count = array_length(bullets);
    var _write = 0;
    var _victim = players[defender];
    for (var _i = 0; _i < _count; _i++)
    {
        var _b = bullets[_i];
        if (_b.round_id != turn_id)
        {
            continue;
        }
        _b.age++;
        _b.life--;
        if (_b.art == 8 && !_b.returning && _b.age > 0)
        {
            _b.outbound--;
            if (_b.outbound <= 0 || (_b.bx + _b.vx) < (arena_left + 5) || (_b.bx + _b.vx) > (arena_right - 5) || (_b.by + _b.vy) < (arena_top + 5) || (_b.by + _b.vy) > (arena_bottom - 5))
            {
                return_boomerang(_b);
            }
        }
        if (_b.orbit > 0)
        {
            _b.orbit--;
            _b.angle += _b.spin * 9;
            _b.bx = _b.ox + lengthdir_x(18, _b.angle);
            _b.by = _b.oy + lengthdir_y(18, _b.angle);
            _b.px = _b.bx;
            _b.py = _b.by;
            if (_b.orbit == 0)
            {
                var _launch = point_direction(_b.bx, _b.by, target_x, target_y);
                _b.vx = lengthdir_x(projectile_speed, _launch);
                _b.vy = lengthdir_y(projectile_speed, _launch);
                _b.age = -projectile_warning_ticks;
            }
        }
        if (_b.age > 0)
        {
            if (array_length(_b.route) > 0)
            {
                var _point = _b.route[_b.waypoint];
                var _rx_path = _point[0] - _b.bx;
                var _ry_path = _point[1] - _b.by;
                var _remaining = sqrt((_rx_path * _rx_path) + (_ry_path * _ry_path));
                if (_remaining <= 2.5)
                {
                    _b.vx = _rx_path;
                    _b.vy = _ry_path;
                    _b.waypoint++;
                    if (_b.waypoint >= array_length(_b.route))
                    {
                        _b.life = 0;
                    }
                }
                else
                {
                    _b.vx = (_rx_path / _remaining) * 2.5;
                    _b.vy = (_ry_path / _remaining) * 2.5;
                }
            }
            if (_b.art == 8 && _b.returning)
            {
                var _dx_home = _b.ox - _b.bx;
                var _dy_home = _b.oy - _b.by;
                var _home_dist = sqrt((_dx_home * _dx_home) + (_dy_home * _dy_home));
                if (_home_dist <= 3)
                {
                    _b.vx = _dx_home;
                    _b.vy = _dy_home;
                    _b.life = 0;
                }
                else
                {
                    _b.vx = (_dx_home / _home_dist) * 3;
                    _b.vy = (_dy_home / _home_dist) * 3;
                }
            }
            if (_b.guided && _b.age <= comet_steering_ticks)
            {
                var _heading = point_direction(0, 0, _b.vx, _b.vy);
                var _desired = point_direction(_b.bx, _b.by, target_x, target_y);
                var _delta = (((_desired - _heading) + 540) % 360) - 180;
                _heading += clamp(_delta, -comet_turn_degrees, comet_turn_degrees);
                _b.vx = lengthdir_x(projectile_speed, _heading);
                _b.vy = lengthdir_y(projectile_speed, _heading);
            }
            _b.px = _b.bx;
            _b.py = _b.by;
            _b.bx += _b.vx;
            _b.by += _b.vy;
            if (_b.bounces > 0)
            {
                var _flip_x = (_b.bx < (arena_left + 5) && _b.vx < 0) || (_b.bx > (arena_right - 5) && _b.vx > 0);
                var _flip_y = (_b.by < (arena_top + 5) && _b.vy < 0) || (_b.by > (arena_bottom - 5) && _b.vy > 0);
                for (var _hi = 0; _hi < array_length(hazards); _hi++)
                {
                    var _reflector = hazards[_hi];
                    if (_reflector.kind != 4 || _reflector.timer > 0)
                    {
                        continue;
                    }
                    if (_reflector.horizontal)
                    {
                        if (((_b.py < _reflector.hy && _b.by >= _reflector.hy) || (_b.py > _reflector.hy && _b.by <= _reflector.hy)) && abs(_b.bx - _reflector.hx) <= 40)
                        {
                            _flip_y = true;
                        }
                    }
                    else if (((_b.px < _reflector.hx && _b.bx >= _reflector.hx) || (_b.px > _reflector.hx && _b.bx <= _reflector.hx)) && abs(_b.by - _reflector.hy) <= 40)
                    {
                        _flip_x = true;
                    }
                }
                if (_flip_x || _flip_y)
                {
                    if (_flip_x)
                    {
                        _b.vx = -_b.vx;
                    }
                    if (_flip_y)
                    {
                        _b.vy = -_b.vy;
                    }
                    _b.bounces--;
                }
            }
            if (_b.owner != defender && _victim.inv <= 0)
            {
                var _rx = _b.px - soul_old_x;
                var _ry = _b.py - soul_old_y;
                var _vx = _b.bx - _b.px - (soul_x - soul_old_x);
                var _vy = _b.by - _b.py - (soul_y - soul_old_y);
                var _len2 = (_vx * _vx) + (_vy * _vy);
                var _t = (_len2 > 0) ? clamp(-((_rx * _vx) + (_ry * _vy)) / _len2, 0, 1) : 0;
                var _hx = _rx + (_vx * _t);
                var _hy = _ry + (_vy * _t);
                var _r = soul_radius + projectile_radius;
                if (((_hx * _hx) + (_hy * _hy)) <= (_r * _r))
                {
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
                    play_sfx(171);
                }
                else if (!_b.grazed && ((_hx * _hx) + (_hy * _hy)) <= (graze_radius * graze_radius))
                {
                    _b.grazed = true;
                    turn_grazes++;
                    match_grazes[defender]++;
                    if (graze_flash <= 0)
                    {
                        play_sfx(169);
                    }
                    graze_flash = 12;
                }
            }
        }
        if (_b.bx < (arena_left - 32) || _b.bx > (arena_right + 32) || _b.by < (arena_top - 32) || _b.by > (arena_bottom + 32) || _b.life <= 0)
        {
            _b.alive = false;
        }
        if (_b.alive)
        {
            if (_write != _i)
            {
                bullets[_write] = _b;
            }
            _write++;
        }
    }
    if (_write < _count)
    {
        array_resize(bullets, _write);
    }
    bullet_update_us = get_timer() - _start_us;
    bullet_peak_us = max(bullet_peak_us, bullet_update_us);
};

ui_text = function(arg0, arg1, arg2, arg3, arg4, arg5 = -1)
{
    draw_set_font((arg4 >= 1.4) ? fnt_mainbig : fnt_main);
    if (arg5 < 0)
    {
        arg5 = 622 - arg0;
    }
    if (string_width(arg2) > arg5)
    {
        while (string_length(arg2) > 0 && string_width(arg2 + "...") > arg5)
        {
            arg2 = string_copy(arg2, 1, string_length(arg2) - 1);
        }
        arg2 += "...";
    }
    draw_set_color(arg3);
    draw_text_transformed(arg0, arg1, arg2, 1, 1, 0);
};

ui_button = function(arg0, arg1, arg2, arg3, arg4, arg5, arg6 = false)
{
    var _hover = pointer_in(arg0, arg1, arg2, arg3);
    draw_panel(arg0, arg1, arg2, arg3, (arg6 || _hover) ? arg5 : make_color_rgb(80, 82, 100));
    draw_set_color(arg6 ? make_color_rgb(25, 31, 48) : (_hover ? make_color_rgb(24, 24, 34) : make_color_rgb(12, 12, 20)));
    draw_rectangle(arg0 + 3, arg1 + 3, (arg0 + arg2) - 3, (arg1 + arg3) - 3, false);
    if (arg6)
    {
        draw_sprite_ext(spr_custommenu_arrow, 0, arg0 + 13, arg1 + (arg3 / 2), 1, 1, 90, arg5, 1);
    }
    ui_text(arg0 + (arg6 ? 26 : 14), arg1 + floor((arg3 - 14) / 2), arg4, (arg6 || _hover) ? 16777215 : make_color_rgb(185, 185, 200), 1, arg2 - (arg6 ? 40 : 28));
};

combat_status = function()
{
    if (input_gate)
    {
        return "Solte o esquerdo para habilitar o disparo";
    }
    if (switch_timer > 0)
    {
        return "Trocando para " + pattern_names[pattern] + "...";
    }
    if (pattern == 7 && array_length(stroke) > 0)
    {
        return "Desenhe e solte | trajeto " + string(floor(stroke_length)) + "/160";
    }
    if (pattern == 8 && charge_ticks > 0)
    {
        return "Solte para lancar | carga " + string(floor((charge_ticks * 100) / 45)) + "%";
    }
    if (dragging)
    {
        return "Arraste e solte o direito | fora da arena cancela";
    }
    if (special_notice_ticks > 0)
    {
        return special_notice;
    }
    return pattern_hints[pattern];
};

draw_heart = function(arg0, arg1, arg2)
{
    draw_sprite_ext(spr_dodgeheart_centered_white, 0, arg0, arg1, 1, 1, 0, arg2, 1);
};

draw_panel = function(arg0, arg1, arg2, arg3, arg4)
{
    draw_sprite_stretched_ext(spr_battlebg_stretch, 0, arg0, arg1, arg2, arg3, arg4, 1);
};

draw_character = function(arg0, arg1, arg2)
{
    var _sprite = character_idle[arg0];
    if (phase == "result")
    {
        if (winner == arg0)
        {
            _sprite = character_victory[arg0];
        }
        else if (winner >= 0)
        {
            _sprite = character_hurt[arg0];
        }
    }
    else if (phase == "lobby")
    {
        if (arg0 == opening_player && mouse_ready)
        {
            _sprite = character_attack[arg0];
        }
    }
    else if (phase != "swap")
    {
        _sprite = (arg0 == attacker) ? character_attack[arg0] : character_defend[arg0];
    }
    if (players[arg0].flash > 0)
    {
        _sprite = character_hurt[arg0];
    }
    var _frame = floor(ui_tick / 6) % sprite_get_number(_sprite);
    var _facing = (arg0 == 0) ? 1 : -1;
    var _draw_x = floor(arg1 + ((sprite_get_xoffset(_sprite) - (sprite_get_width(_sprite) / 2)) * _facing));
    var _draw_y = floor((arg2 - sprite_get_height(_sprite)) + sprite_get_yoffset(_sprite));
    draw_sprite_ext(_sprite, _frame, _draw_x, _draw_y, _facing, 1, 0, c_white, 1);
};

draw_wall_preview = function(arg0, arg1, arg2, arg3)
{
    if (arg2)
    {
        var _top = arg1 < ((arena_top + arena_bottom) / 2);
        var _xx = arena_left + 16;
        while (_xx < arena_right)
        {
            if (abs(_xx - arg0) > 34)
            {
                draw_sprite_ext(spr_spadebullet, 0, _xx, _top ? (arena_top + 5) : (arena_bottom - 5), 0.5, 0.5, _top ? 270 : 90, arg3, 0.45);
            }
            _xx += 24;
        }
    }
    else
    {
        var _left = arg0 < ((arena_left + arena_right) / 2);
        var _yy = arena_top + 16;
        while (_yy < arena_bottom)
        {
            if (abs(_yy - arg1) > 34)
            {
                draw_sprite_ext(spr_spadebullet, 0, _left ? (arena_left + 5) : (arena_right - 5), _yy, 0.5, 0.5, _left ? 0 : 180, arg3, 0.45);
            }
            _yy += 24;
        }
    }
};

draw_reflector = function(arg0, arg1, arg2, arg3)
{
    for (var _offset = -40; _offset <= 40; _offset += 10)
    {
        draw_sprite_ext(spr_diamondbullet, 0, arg0 + (arg2 ? _offset : 0), arg1 + (arg2 ? 0 : _offset), 0.4, 0.4, 45, arg3, 0.65);
    }
};

draw_bounce_preview = function(arg0, arg1, arg2)
{
    var _dir = point_direction(arg0, arg1, target_x, target_y);
    var _vx = lengthdir_x(1, _dir);
    var _vy = lengthdir_y(1, _dir);
    var _tx = (abs(_vx) < 0.0001) ? 10000 : ((((_vx > 0) ? (arena_right - 5) : (arena_left + 5)) - arg0) / _vx);
    var _ty = (abs(_vy) < 0.0001) ? 10000 : ((((_vy > 0) ? (arena_bottom - 5) : (arena_top + 5)) - arg1) / _vy);
    var _distance = min(_tx, _ty);
    var _horizontal = _ty <= _tx;
    for (var _i = 0; _i < (array_length(hazards) + 1); _i++)
    {
        var _rx = drag_x;
        var _ry = drag_y;
        var _flat = abs(target_x - drag_x) >= abs(target_y - drag_y);
        if (_i < array_length(hazards))
        {
            var _h = hazards[_i];
            if (_h.kind != 4 || _h.timer > 0)
            {
                continue;
            }
            _rx = _h.hx;
            _ry = _h.hy;
            _flat = _h.horizontal;
        }
        else if (!dragging)
        {
            continue;
        }
        var _component = _flat ? _vy : _vx;
        if (abs(_component) < 0.0001)
        {
            continue;
        }
        var _t = (_flat ? (_ry - arg1) : (_rx - arg0)) / _component;
        var _offset = _flat ? ((arg0 + (_vx * _t)) - _rx) : ((arg1 + (_vy * _t)) - _ry);
        if (_t > 0 && _t < _distance && abs(_offset) <= 40)
        {
            _distance = _t;
            _horizontal = _flat;
        }
    }
    var _bx = arg0 + (_vx * _distance);
    var _by = arg1 + (_vy * _distance);
    draw_set_color(arg2);
    draw_set_alpha(0.35);
    draw_line(arg0, arg1, _bx, _by);
    if (_horizontal)
    {
        _vy = -_vy;
    }
    else
    {
        _vx = -_vx;
    }
    draw_line(_bx, _by, clamp(_bx + (_vx * 80), arena_left + 5, arena_right - 5), clamp(_by + (_vy * 80), arena_top + 5, arena_bottom - 5));
    draw_set_alpha(1);
};

cancel_gesture = function()
{
    stroke = [];
    stroke_length = 0;
    charge_ticks = 0;
};

return_boomerang = function(arg0)
{
    arg0.returning = true;
    arg0.age = -projectile_warning_ticks;
    arg0.vx = 0;
    arg0.vy = 0;
};

pay_creative_shot = function()
{
    energy -= (energy_cost * 2);
    if (energy < (energy_cost * 2))
    {
        recovering = true;
    }
    shots_fired++;
    shot_flash = 5;
    shot_cooldown = 24;
    play_sfx(260);
};

step_creative_input = function(arg0)
{
    if (!arg0)
    {
        cancel_gesture();
        exit;
    }
    if (switch_timer > 0 || input_gate)
    {
        cancel_gesture();
        exit;
    }
    var _can = energy >= (energy_cost * 2) && !recovering && shot_cooldown <= 0 && array_length(bullets) <= (bullet_limit - 3);
    if (pattern == 7)
    {
        if (input.fire_pressed && _can)
        {
            stroke = [[target_x, target_y]];
            stroke_length = 0;
        }
        if (input.fire && array_length(stroke) > 0 && array_length(stroke) < 32)
        {
            var _last = stroke[array_length(stroke) - 1];
            var _dx = target_x - _last[0];
            var _dy = target_y - _last[1];
            var _distance = sqrt((_dx * _dx) + (_dy * _dy));
            var _allowed = min(_distance, stitch_max_length - stroke_length);
            if (_distance >= 6 && _allowed > 0)
            {
                array_push(stroke, [_last[0] + ((_dx / _distance) * _allowed), _last[1] + ((_dy / _distance) * _allowed)]);
                stroke_length += _allowed;
            }
        }
        if (input.fire_released && array_length(stroke) > 0)
        {
            if (_can && stroke_length >= 12 && phase_ticks > (stitch_warning_ticks + 30))
            {
                var _route = [];
                for (var _i = 0; _i < array_length(stroke); _i++)
                {
                    var _idx = stitch_reverse ? (array_length(stroke) - 1 - _i) : _i;
                    array_push(_route, stroke[_idx]);
                }
                for (var _n = 0; _n < 3; _n++)
                {
                    add_bullet(_route[0][0], _route[0][1], 0, 0, 7);
                    var _b = bullets[array_length(bullets) - 1];
                    _b.route = _route;
                    _b.waypoint = 1;
                    _b.age = -stitch_warning_ticks - (_n * 8);
                }
                pay_creative_shot();
            }
            cancel_gesture();
        }
    }
    else if (pattern == 8)
    {
        if (input.fire_pressed && _can)
        {
            charge_ticks = 1;
        }
        if (input.fire && charge_ticks > 0)
        {
            charge_ticks = min(45, charge_ticks + 1);
        }
        if (input.fire_released && charge_ticks > 0)
        {
            if (_can)
            {
                var _edge = edge_position(target_x, target_y);
                var _heading = point_direction(_edge[0], _edge[1], target_x, target_y);
                add_bullet(_edge[0], _edge[1], lengthdir_x(3, _heading), lengthdir_y(3, _heading), 8);
                bullets[array_length(bullets) - 1].outbound = 12 + charge_ticks;
                pay_creative_shot();
            }
            charge_ticks = 0;
        }
    }
    else if (pattern == 9 && input.fire && _can && array_length(seeds) < seed_limit && phase_ticks > 90)
    {
        var _edge = edge_position(target_x, target_y);
        var _dx = target_x - _edge[0];
        var _dy = target_y - _edge[1];
        var _travel = max(1, ceil(sqrt((_dx * _dx) + (_dy * _dy)) / 2));
        array_push(seeds, 
        {
            sx: _edge[0],
            sy: _edge[1],
            tx: target_x,
            ty: target_y,
            vx: _dx / _travel,
            vy: _dy / _travel,
            travel: _travel,
            mature: 24,
            fuse: -1,
            life: 240,
            heading: point_direction(_edge[0], _edge[1], target_x, target_y),
            round_id: turn_id
        });
        pay_creative_shot();
    }
};

step_seeds = function()
{
    var _keep = [];
    for (var _i = 0; _i < array_length(seeds); _i++)
    {
        var _s = seeds[_i];
        if (_s.round_id != turn_id)
        {
            continue;
        }
        _s.life--;
        if (_s.travel > 0)
        {
            _s.sx += _s.vx;
            _s.sy += _s.vy;
            _s.travel--;
        }
        else if (_s.mature > 0)
        {
            _s.mature--;
        }
        if (_s.fuse > 0)
        {
            _s.fuse--;
            if (_s.fuse == 0)
            {
                for (var _fan = -1; _fan <= 1; _fan++)
                {
                    add_bullet(_s.sx, _s.sy, lengthdir_x(2.2, _s.heading + (_fan * 25)), lengthdir_y(2.2, _s.heading + (_fan * 25)), 9);
                }
                continue;
            }
        }
        if (_s.life > 0)
        {
            array_push(_keep, _s);
        }
    }
    seeds = _keep;
};

draw_route = function(arg0, arg1)
{
    draw_set_color(arg1);
    draw_set_alpha(0.4);
    for (var _i = 1; _i < array_length(arg0); _i++)
    {
        draw_line(arg0[_i - 1][0], arg0[_i - 1][1], arg0[_i][0], arg0[_i][1]);
    }
    draw_set_alpha(1);
    if (array_length(arg0) > 0)
    {
        draw_sprite_ext(spr_custommenu_arrow, 0, arg0[0][0], arg0[0][1], 1, 1, 0, arg1, 1);
    }
};

if (parameter_count() >= 2 && parameter_string(1) == "--pvp-ui-check")
{
    qa_preview = true;
    if (parameter_count() >= 3 && parameter_string(3) == "native")
    {
        window_set_size(640, 480);
        window_center();
    }
    var _case = parameter_string(2);
    pointer_x = 390;
    pointer_y = 200;
    if (_case == "help")
    {
        help_open = true;
        help_page = 0;
    }
    else if (_case != "lobby")
    {
        reset_match();
        loadouts[0] = [7, 9];
        if (_case == "menu")
        {
            phase = "plan";
            phase_ticks = 270;
            edit_slot = 1;
            active_slot = 1;
            pattern = 9;
            selection_page = 1;
        }
        else
        {
            phase = "dodge";
            phase_ticks = 330;
            pattern = (_case == "garden") ? 8 : 7;
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
            if (_case == "garden")
            {
                cancel_gesture();
                array_push(seeds, 
                {
                    sx: 300,
                    sy: 260,
                    travel: 0,
                    mature: 0,
                    fuse: 18,
                    heading: 35
                });
                charge_ticks = 30;
            }
            if (_case == "pause")
            {
                paused = true;
            }
        }
    }
}
if (parameter_count() >= 1 && parameter_string(1) == "--pvp-help")
{
    help_open = true;
}
