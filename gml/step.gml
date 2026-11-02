if (qa_preview) exit;
var _net_aim_x = target_x;
var _net_aim_y = target_y;
sample_inputs();
if (!net_frame()) {
    if (net_mode == "client") { target_x = _net_aim_x; target_y = _net_aim_y; input.focus = net_defender_focus; }
    exit;
}
if (keyboard_check_pressed(vk_f3)) debug_overlay = !debug_overlay;
if (net_mode == "local") {
// Focus loss wins over every menu action: never resume from a stale click.
if (!window_has_focus()) {
    paused = true;
    cancel_gesture();
    dragging = false;
    dash_remaining = 0;
    input_gate = true;
    exit;
}
// All menus are clickable: the attacker never needs the keyboard.
if (help_open) {
    if (input.pause || (input.fire_pressed && pointer_in(230, 392, 180, 36))) {
        help_open = false;
        input_gate = true;
    } else if (input.fire_pressed) {
        if (pointer_in(64, 392, 150, 36)) help_page = max(0, help_page - 1);
        if (pointer_in(426, 392, 150, 36)) help_page = min(2, help_page + 1);
    }
    exit;
}
if (input.fire_pressed && pointer_in(302, 8, 96, 26)) {
    help_open = true;
    help_page = 0;
    cancel_gesture();
    dragging = false;
    dash_remaining = 0;
    exit;
}
var _pause_click = input.fire_pressed && pointer_in(410, 8, 66, 26);
var _mute_click = input.fire_pressed && pointer_in(480, 8, 66, 26);
var _full_click = input.fire_pressed && pointer_in(550, 8, 72, 26);
if (input.fullscreen || _full_click) {
    window_set_fullscreen(!window_get_fullscreen());
    window_set_cursor(cr_arrow);
}
if (input.mute || _mute_click) {
    sound_enabled = !sound_enabled;
    if (music_voice != -1) audio_sound_gain(music_voice, sound_enabled ? 0.32 : 0, 0);
}
if (input.pause || _pause_click) {
    paused = !paused;
    dash_remaining = 0;
    cancel_gesture();
    dragging = false;
    input_gate = true;
    exit;
}
if (_mute_click || _full_click) exit;
if (paused) {
    if (input.fire_pressed) {
        if (pointer_in(180, 168, 280, 34)) { paused = false; input_gate = true; }
        if (pointer_in(180, 212, 280, 34)) reset_match();
        if (pointer_in(180, 256, 280, 34)) return_to_lobby();
        if (pointer_in(180, 300, 280, 34)) game_end();
    }
    exit;
}
}
if (input_gate) {
    if (!input.fire) input_gate = false;
    // Only the confirming left click needs release. Right-button edges are independent.
    // A stale held right button has no pressed edge and cannot start a new special.
    input.fire = false;
    input.fire_pressed = false;
    input.fire_released = false;
}
ui_tick++;

if (phase == "lobby" || phase == "result" || phase == "handoff") {
    // A held click/Enter from the preceding phase cannot acknowledge a new role.
    if (role_release_gate) {
        if (input.fire || input.special || input.ready_held) exit;
        role_release_gate = false;
    }
    if (input.fire_pressed && pointer_in(40, 320, 270, 50)) mouse_ready = true;
    if (input.ready) keyboard_ready = true;
    if (mouse_ready && keyboard_ready) {
        if (phase != "handoff") {
            reset_match();
        }
        // The two confirmations already acknowledge the displayed opening roles.
        phase = "plan";
        phase_ticks = planning_ticks;
        input_gate = true;
    }
    exit;
}

if (phase == "plan") {
    if (input.fire_pressed) {
        for (var _slot = 0; _slot < 2; _slot++) {
            if (pointer_in(40 + _slot * 290, 143, 270, 30)) {
                edit_slot = _slot;
                active_slot = _slot;
                pattern = loadouts[attacker][_slot];
                selection_page = floor(attack_index(pattern) / 6);
            }
        }
    }
    if (input.wheel != 0) {
        var _count = array_length(available_attacks);
        select_attack(available_attacks[(attack_index(loadouts[attacker][edit_slot]) + input.wheel + _count) mod _count]);
        play_sfx(snd_menumove);
    }
    if (input.fire_pressed) {
        if (pointer_in(40, 311, 270, 38)) selection_page = 1 - selection_page;
        for (var _i = 0; _i < 6; _i++) {
            if (pointer_in(40 + (_i mod 2) * 290, 182 + floor(_i / 2) * 43, 270, 38)) {
                var _choice = selection_page * 6 + _i;
                if (_choice >= array_length(available_attacks)) continue;
                select_attack(available_attacks[_choice]);
                play_sfx(snd_menumove);
            }
        }
    }
    phase_ticks--;
    if ((input.fire_pressed && pointer_in(330, 311, 270, 38)) || phase_ticks <= 0) {
        phase = "telegraph";
        phase_ticks = telegraph_ticks;
        input_gate = true;
        play_sfx(snd_select);
    }
    exit;
}

if (phase == "telegraph") {
    phase_ticks--;
    if (phase_ticks <= 0) {
        phase = "dodge";
        phase_ticks = dodge_ticks;
        input_gate = true;
    }
    exit;
}

if (phase == "dodge") {
    if (special_notice_ticks > 0) special_notice_ticks--;
    if (switch_timer > 0) switch_timer--;
    if (input.wheel != 0 && switch_timer <= 0) {
        active_slot = 1 - active_slot;
        cancel_gesture();
        special_notice_ticks = 0;
        pattern = loadouts[attacker][active_slot];
        switch_timer = switch_warning_ticks;
        dragging = false;
        play_sfx(snd_select);
    }
    if (shot_flash > 0) shot_flash--;
    if (graze_flash > 0) graze_flash--;
    if (hit_feedback > 0) hit_feedback--;
    for (var _p = 0; _p < 2; _p++) {
        if (players[_p].flash > 0) players[_p].flash--;
        if (players[_p].inv > 0) players[_p].inv--;
    }
    soul_old_x = soul_x;
    soul_old_y = soul_y;
    var _speed = input.focus ? focus_speed : soul_speed;
    if (input.evade && dash_available && (input.move_x != 0 || input.move_y != 0)) {
        dash_available = false;
        dash_remaining = dash_ticks;
        var _length = sqrt(input.move_x * input.move_x + input.move_y * input.move_y);
        dash_x = input.move_x / _length;
        dash_y = input.move_y / _length;
        play_sfx(snd_graze);
    }
    var _dx = input.move_x * _speed;
    var _dy = input.move_y * _speed;
    if (dash_remaining > 0) {
        _dx = dash_x * dash_speed;
        _dy = dash_y * dash_speed;
        dash_remaining--;
    }
    soul_x = clamp(soul_x + _dx, arena_left + 10, arena_right - 10);
    soul_y = clamp(soul_y + _dy, arena_top + 10, arena_bottom - 10);
    if (shot_cooldown > 0) shot_cooldown--;
    if (strategy_cooldown > 0) strategy_cooldown--;
    var _inside = pointer_in(arena_left, arena_top, arena_right - arena_left, arena_bottom - arena_top);
    if (fire_buffer > 0) fire_buffer--;
    if (!_inside) fire_buffer = 0;
    if (_inside && input.fire_pressed && pattern < 7) fire_buffer = 4;
    var _required_energy = pattern == 2 || pattern == 3 || pattern >= 7 ? energy_cost * 2 : energy_cost;
    if (energy < _required_energy) recovering = true;
    if (!input.fire || recovering) energy = min(energy_max, energy + energy_regen);
    if (recovering && energy >= energy_resume) recovering = false;
    if (pattern >= 7) step_creative_input(_inside);
    else if (_inside && (input.fire || fire_buffer > 0)) {
        var _before = shots_fired;
        fire_burst();
        if (shots_fired > _before) fire_buffer = 0;
    }
    if (input.special_pressed) {
        special_notice = "";
        if (!_inside) special_notice = "MIRE DENTRO DA ARENA";
        else if (switch_timer > 0) special_notice = "AGUARDE A TROCA DO ATAQUE";
        else if (strategy_cooldown > 0) special_notice = "ESPECIAL RECARREGANDO";
        else if (phase_ticks < strategy_warning_ticks + 30) special_notice = "TURNO TERMINANDO";
        else if (pattern == 2 || pattern == 4) special_notice = "ARRASTE E SOLTE O DIREITO";
        else special_notice = "ESPECIAL ATIVADO";
        special_notice_ticks = 45;
    }
    if (_inside && input.special_pressed && switch_timer <= 0 && strategy_cooldown <= 0 && phase_ticks >= strategy_warning_ticks + 30) {
        if (pattern == 2 || pattern == 4) {
            dragging = true;
            drag_x = target_x;
            drag_y = target_y;
        } else place_strategy(target_x, target_y, true);
    }
    if (dragging && input.special_released) {
        var _can_place = _inside && phase_ticks >= strategy_warning_ticks + 30;
        if (_can_place) place_strategy(drag_x, drag_y, abs(target_x - drag_x) >= abs(target_y - drag_y));
        special_notice = !_inside ? "CANCELADO: FORA DA ARENA" : (_can_place ? "ESPECIAL POSICIONADO" : "TURNO TERMINANDO");
        special_notice_ticks = 45;
        dragging = false;
    }
    step_seeds();
    step_hazards();
    step_bullets();
    phase_ticks--;
    if (players[defender].hp <= 0) { finish_match(); exit; }
    if (phase_ticks <= 0) {
        if (turn_damage == 0) perfect_turns[defender]++;
        clear_attacks();
        phase = "swap";
        phase_ticks = swap_ticks;
    }
    exit;
}

if (phase == "swap") {
    phase_ticks--;
    if (phase_ticks <= 0) advance_turn();
}
