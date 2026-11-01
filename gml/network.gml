// Host-authoritative LAN. Native framed TCP; only inputs travel from guest to host.
net_mode = "local";
net_menu = false;
net_status = "Hospede ou informe o IPv4 do anfitriao.";
net_ip = "127.0.0.1";
net_port_text = "6510";
net_field = 0;
net_socket = -1;
net_peer = -1;
net_buffer = -1;
net_connected = false;
net_player = 0;
net_clock = 0;
net_last_rx = 0;
net_started = 0;
net_seq = 0;
net_rx_seq = -1;
net_snapshot_seq = 0;
net_applied_seq = -1;
net_queue = [];
net_remote = undefined;
net_manual_pause = false;
net_local_x = 320;
net_local_y = 280;
net_waiting = false;
net_test = false;
net_test_ticks = 0;
net_test_damage = 0;
net_test_swaps = 0;
net_test_seen_turn = 0;
net_ack = -1;
net_state_ack = -1;
net_sent_at = [];
net_rtt = 0;
net_verified_states = 0;
net_defender_focus = false;
net_protocol = "SOULSWAP-LAN-1/" + mod_version;
// Whitelist: never overwrite methods, socket handles, local preferences or local UI from a packet.
net_fields = ["phase", "phase_ticks", "attacker", "defender", "opening_player", "turn_number", "turn_id",
    "players", "loadouts", "active_slot", "edit_slot", "pattern", "selection_page", "switch_timer",
    "energy", "recovering", "shot_cooldown", "strategy_cooldown", "special_notice", "special_notice_ticks",
    "dragging", "drag_x", "drag_y", "target_x", "target_y", "stroke", "stroke_length", "stitch_reverse",
    "charge_ticks", "soul_x", "soul_y", "dash_available", "dash_remaining", "dash_x", "dash_y",
    "mouse_ready", "keyboard_ready", "role_release_gate", "input_gate", "paused", "winner", "wins",
    "turn_damage", "turn_grazes", "damage_by_pattern", "match_grazes", "perfect_turns", "hit_feedback",
    "hit_x", "hit_y", "hit_amount", "graze_flash", "shot_flash", "ui_tick", "shots_fired", "orbit_sign"];
net_bullet_fields = ["bx", "by", "vx", "vy", "age", "art", "orbit", "route", "returning", "return_x", "return_y", "ox", "oy"];

net_blank = function() {
    return { fire: false, fire_pressed: false, fire_released: false, special: false,
        special_pressed: false, special_released: false, ready: false, ready_held: false,
        focus: false, evade: false, move_x: 0, move_y: 0, wheel: 0, pause: false, mute: false, fullscreen: false };
};
net_epoch = function() { return string(turn_id) + ":" + phase; };
net_close = function(_message) {
    if (net_peer >= 0 && net_peer != net_socket) network_destroy(net_peer);
    if (net_socket >= 0) network_destroy(net_socket);
    if (net_buffer >= 0) buffer_delete(net_buffer);
    net_socket = -1; net_peer = -1; net_buffer = -1;
    net_connected = false; net_mode = "local"; net_menu = true;
    net_queue = []; net_remote = undefined; net_manual_pause = false;
    net_status = _message;
    help_open = false;
    return_to_lobby();
    window_set_caption("DELTARUNE / SOUL SWAP / local PvP " + mod_version);
};
net_ipv4_valid = function(_text) {
    if (!is_string(_text) || string_length(_text) < 7 || string_length(_text) > 15) return false;
    var _parts = string_split(_text, ".");
    if (array_length(_parts) != 4) return false;
    for (var _i = 0; _i < 4; _i++) {
        var _p = _parts[_i];
        if (string_length(_p) < 1 || string_length(_p) > 3) return false;
        for (var _j = 1; _j <= string_length(_p); _j++) {
            var _c = ord(string_char_at(_p, _j));
            if (_c < 48 || _c > 57) return false;
        }
        if (real(_p) > 255) return false;
    }
    return real(_parts[0]) > 0 && real(_parts[0]) < 224 && _text != "255.255.255.255";
};
net_port_valid = function(_text) {
    if (!is_string(_text) || string_length(_text) < 1 || string_length(_text) > 5) return false;
    for (var _i = 1; _i <= string_length(_text); _i++) {
        var _c = ord(string_char_at(_text, _i));
        if (_c < 48 || _c > 57) return false;
    }
    return real(_text) >= 1 && real(_text) <= 65535;
};
net_send = function(_packet) {
    if (net_peer < 0 || net_buffer < 0) return false;
    var _json = json_stringify(_packet);
    buffer_seek(net_buffer, buffer_seek_start, 0);
    buffer_write(net_buffer, buffer_string, _json);
    var _size = buffer_tell(net_buffer);
    if (_size > 262144) { net_close("Estado excedeu o limite de rede."); return false; }
    if (network_send_packet(net_peer, net_buffer, _size) < 0) {
        net_close("Conexao perdida. Hospede ou conecte novamente."); return false;
    }
    return true;
};
net_start = function(_host) {
    if (!net_port_valid(net_port_text)) { net_status = "Porta invalida: use 1 a 65535."; return; }
    if (!_host && !net_ipv4_valid(net_ip)) { net_status = "IPv4 invalido. Exemplo: 192.168.1.10"; return; }
    if (net_mode != "local") net_close("");
    reset_match(); return_to_lobby();
    net_player = _host ? 0 : 1;
    net_mode = _host ? "host" : "client";
    net_connected = false; net_menu = true; net_manual_pause = false;
    net_seq = 0; net_rx_seq = -1; net_snapshot_seq = 0; net_applied_seq = -1;
    net_ack = -1; net_state_ack = -1; net_queue = []; net_remote = undefined; net_sent_at = [];
    net_test_ticks = 0; net_test_damage = 0; net_test_swaps = 0; net_test_seen_turn = 0;
    net_started = current_time; net_last_rx = current_time;
    net_buffer = buffer_create(4096, buffer_grow, 1);
    if (_host) {
        net_socket = network_create_server(network_socket_tcp, real(net_port_text), 2);
        if (net_socket < 0) { net_close("Nao foi possivel hospedar. Porta ocupada?"); return; }
        net_peer = -1;
        net_status = "Hospedando na porta TCP " + net_port_text + ". Aguardando P2...";
    } else {
        net_socket = network_create_socket(network_socket_tcp);
        net_peer = net_socket;
        if (net_socket < 0 || network_connect_async(net_socket, net_ip, real(net_port_text)) < 0) {
            net_close("Falha ao conectar. Confira IPv4 e porta."); return;
        }
        net_status = "Conectando a " + net_ip + ":" + net_port_text + "...";
    }
};
net_capture_state = function() {
    var _state = [];
    for (var _i = 0; _i < array_length(net_fields); _i++)
        array_push(_state, variable_instance_get(id, net_fields[_i]));
    var _shots = [];
    for (var _i = 0; _i < array_length(bullets); _i++) {
        var _row = [];
        for (var _j = 0; _j < array_length(net_bullet_fields); _j++)
            array_push(_row, variable_struct_get(bullets[_i], net_bullet_fields[_j]));
        array_push(_shots, _row);
    }
    return { kind: "state", protocol: net_protocol, seq: net_snapshot_seq++, ack: net_rx_seq,
        values: _state, shots: _shots, hazards: hazards, seeds: seeds,
        test_ticks: net_test_ticks, test_damage: net_test_damage, test_swaps: net_test_swaps,
        signature: net_state_signature(), defender_focus: input.focus };
};
net_state_signature = function() {
    // Read actual gameplay variables directly, independently of the dynamic snapshot field access.
    return phase + ":" + string(phase_ticks) + ":" + string(attacker) + ":" + string(defender) + ":" +
        string(players[0].hp) + ":" + string(players[1].hp) + ":" + string(floor(energy * 100)) + ":" +
        string(floor(soul_x * 100)) + ":" + string(floor(soul_y * 100)) + ":" + string(pattern) + ":" +
        string(array_length(bullets)) + ":" + string(array_length(seeds)) + ":" + string(array_length(hazards));
};
net_apply_state = function(_p) {
    if (!is_array(_p.values) || array_length(_p.values) != array_length(net_fields) ||
        !is_array(_p.shots) || array_length(_p.shots) > bullet_limit ||
        !is_array(_p.hazards) || array_length(_p.hazards) > 8 ||
        !is_array(_p.seeds) || array_length(_p.seeds) > seed_limit) return false;
    var _shots = [];
    for (var _i = 0; _i < array_length(_p.shots); _i++) {
        var _row = _p.shots[_i];
        if (!is_array(_row) || array_length(_row) != array_length(net_bullet_fields)) return false;
        var _b = {};
        for (var _j = 0; _j < array_length(net_bullet_fields); _j++)
            variable_struct_set(_b, net_bullet_fields[_j], _row[_j]);
        if (!is_real(_b.art) || _b.art < 0 || _b.art >= attack_count || floor(_b.art) != _b.art) return false;
        array_push(_shots, _b);
    }
    var _old_damage = turn_damage;
    for (var _i = 0; _i < array_length(net_fields); _i++)
        variable_instance_set(id, net_fields[_i], _p.values[_i]);
    bullets = _shots; hazards = _p.hazards; seeds = _p.seeds;
    net_defender_focus = _p.defender_focus;
    if (net_state_signature() != _p.signature) return false;
    net_verified_states++;
    if (turn_damage > _old_damage) play_sfx(snd_hurt1);
    net_applied_seq = _p.seq;
    net_test_ticks = _p.test_ticks; net_test_damage = _p.test_damage; net_test_swaps = _p.test_swaps;
    net_ack = _p.ack;
    for (var _i = 0; _i < array_length(net_sent_at); _i++) {
        if (net_sent_at[_i][0] == net_ack) net_rtt = current_time - net_sent_at[_i][1];
    }
    return true;
};
net_number = function(_v, _lo, _hi) {
    return is_real(_v) && !is_nan(_v) && !is_infinity(_v) && _v >= _lo && _v <= _hi;
};
net_valid_input = function(_p) {
    if (!variable_struct_exists(_p, "seq") || !net_number(_p.seq, 0, 1000000000) || floor(_p.seq) != _p.seq ||
        !variable_struct_exists(_p, "epoch") || !is_string(_p.epoch) || string_length(_p.epoch) > 50 ||
        !variable_struct_exists(_p, "data") || !is_array(_p.data) || array_length(_p.data) != 18) return false;
    var _d = _p.data;
    if (!net_number(_d[0], -64, 704) || !net_number(_d[1], -64, 544)) return false;
    for (var _i = 2; _i < 18; _i++) {
        if (!net_number(_d[_i], -1, 1)) return false;
        if (_i != 12 && _i != 13 && _d[_i] != 0 && _d[_i] != 1 && _i != 14) return false;
    }
    return floor(_d[14]) == _d[14];
};
net_receive = function(_p) {
    if (!is_struct(_p) || !variable_struct_exists(_p, "kind") || !variable_struct_exists(_p, "protocol")) return;
    if (_p.protocol != net_protocol) { net_close("Versoes diferentes. Usem a mesma versao do mod."); return; }
    if (_p.kind == "bye") { net_close("O outro jogador saiu. Conecte novamente."); return; }
    if (net_mode == "host" && _p.kind == "hello" && !net_connected) {
        net_connected = true; net_menu = false; net_last_rx = current_time;
        return_to_lobby(); net_manual_pause = false;
        net_send({ kind: "welcome", protocol: net_protocol });
        return;
    }
    if (net_mode == "client" && _p.kind == "welcome" && !net_connected) {
        net_connected = true; net_menu = false; net_last_rx = current_time; return;
    }
    if (!net_connected) return;
    if (net_mode == "host" && _p.kind == "input") {
        if (!net_valid_input(_p) || _p.seq <= net_rx_seq) return;
        if (array_length(net_queue) >= 90) { net_close("Atraso excessivo na conexao. Reconecte."); return; }
        net_rx_seq = _p.seq; net_last_rx = current_time;
        if (variable_struct_exists(_p, "state_ack") && net_number(_p.state_ack, -1, net_snapshot_seq - 1)) net_state_ack = max(net_state_ack, _p.state_ack);
        array_push(net_queue, _p);
    } else if (net_mode == "client" && _p.kind == "state") {
        if (!variable_struct_exists(_p, "seq") || !net_number(_p.seq, 0, 1000000000) || _p.seq <= net_applied_seq) return;
        try {
            if (net_apply_state(_p)) net_last_rx = current_time;
            else net_close("Estado de rede invalido. Reconecte.");
        } catch (_error) { net_close("Pacote de estado invalido."); }
    }
};
net_pack_input = function(_block, _command) {
    return { kind: "input", protocol: net_protocol, seq: net_seq++, epoch: net_epoch(), state_ack: net_applied_seq,
        data: [clamp(net_local_x, -64, 704), clamp(net_local_y, -64, 544),
        real(!_block && input.fire), real(!_block && input.fire_pressed), real(!_block && input.fire_released),
        real(!_block && input.special), real(!_block && input.special_pressed), real(!_block && input.special_released),
        real(!_block && input.ready), real(!_block && input.ready_held), real(!_block && input.focus), real(!_block && input.evade),
        _block ? 0 : input.move_x, _block ? 0 : input.move_y, _block ? 0 : input.wheel,
        real(_block), real(_command), real(help_open)] };
};
net_decode = function(_p) {
    var _d = _p.data;
    return { fire: _d[2] == 1, fire_pressed: _d[3] == 1, fire_released: _d[4] == 1,
        special: _d[5] == 1, special_pressed: _d[6] == 1, special_released: _d[7] == 1,
        ready: _d[8] == 1, ready_held: _d[9] == 1, focus: _d[10] == 1, evade: _d[11] == 1,
        move_x: _d[12], move_y: _d[13], wheel: _d[14], pause: false, mute: false, fullscreen: false };
};
net_no_edges = function(_p) {
    _p.data[3] = 0; _p.data[4] = 0; _p.data[6] = 0; _p.data[7] = 0;
    _p.data[8] = 0; _p.data[11] = 0; _p.data[14] = 0; _p.data[16] = 0;
};
net_merge = function(_host, _guest) {
    var _role = phase == "lobby" || phase == "result" ? opening_player : attacker;
    var _attack = _role == 0 ? _host : _guest;
    var _defense = _role == 0 ? _guest : _host;
    input = net_decode(_attack);
    var _keys = net_decode(_defense);
    input.move_x = _keys.move_x; input.move_y = _keys.move_y;
    var _len = sqrt(input.move_x * input.move_x + input.move_y * input.move_y);
    if (_len > 1) { input.move_x /= _len; input.move_y /= _len; }
    input.focus = _keys.focus; input.evade = _keys.evade;
    input.ready = _keys.ready; input.ready_held = _keys.ready_held;
    pointer_x = _attack.data[0]; pointer_y = _attack.data[1];
    // Toolbar and network controls are local, never interpreted as combat/menu input from the other PC.
    if (pointer_y < 40) { input.fire = false; input.fire_pressed = false; input.special_pressed = false; }
    target_x = clamp(pointer_x, arena_left + 12, arena_right - 12);
    target_y = clamp(pointer_y, arena_top + 12, arena_bottom - 12);
};

net_ui_step = function() {
    if (net_field > 0 && net_mode == "local") {
        var _clean = "";
        for (var _i = 1; _i <= min(64, string_length(keyboard_string)); _i++) {
            var _ch = string_char_at(keyboard_string, _i);
            if (string_pos(_ch, net_field == 1 ? "0123456789." : "0123456789") > 0) _clean += _ch;
        }
        _clean = string_copy(_clean, 1, net_field == 1 ? 15 : 5);
        keyboard_string = _clean;
        if (net_field == 1) net_ip = _clean; else net_port_text = _clean;
    }
    if (input.fire_pressed) {
        if (pointer_in(72, 174, 328, 38) && net_mode == "local") { net_field = 1; keyboard_string = net_ip; }
        if (pointer_in(420, 174, 148, 38) && net_mode == "local") { net_field = 2; keyboard_string = net_port_text; }
        if (pointer_in(72, 240, 238, 44) && net_mode == "local") { net_field = 0; net_start(true); }
        else if (pointer_in(330, 240, 238, 44) && net_mode == "local") { net_field = 0; net_start(false); }
        if (pointer_in(180, 390, 280, 38)) {
            if (net_mode != "local") net_close("Conexao cancelada.");
            else { net_menu = false; net_field = 0; input_gate = true; }
        }
    }
};

net_test_input = function() {
    // Explicit integration-test option only. No synthetic input during ordinary LAN play.
    input = net_blank();
    var _role = phase == "lobby" || phase == "result" ? opening_player : attacker;
    if (phase == "lobby" || phase == "handoff" || phase == "result") {
        if (net_clock mod 15 == 0) {
            if (net_player == _role) { input.fire = true; input.fire_pressed = true; pointer_x = 150; pointer_y = 340; }
            else { input.ready = true; input.ready_held = true; }
        }
    } else if (phase == "plan" && net_player == attacker && net_clock mod 15 == 0) {
        pointer_x = 400; pointer_y = 330; input.fire = true; input.fire_pressed = true;
    } else if (phase == "dodge") {
        if (net_player == attacker) {
            pointer_x = soul_x; pointer_y = soul_y;
            input.fire = true; input.fire_pressed = net_clock mod 20 == 0;
            input.special_pressed = net_clock mod 121 == 0;
        } else {
            input.move_x = net_clock mod 120 < 60 ? 0.2 : -0.2;
            input.focus = true;
        }
    }
};

net_frame = function() {
    net_clock++;
    if (net_test && net_connected) net_test_input();
    net_local_x = pointer_x; net_local_y = pointer_y;
    if (net_mode != "local") {
        if ((!net_connected && net_mode == "client" && current_time - net_started > 7000) ||
            (net_peer >= 0 && current_time - net_last_rx > 5000)) {
            net_close("Tempo de conexao esgotado. Confira rede, IPv4 e porta."); return false;
        }
    }
    if (net_menu) { net_ui_step(); return false; }
    if (net_mode == "local") {
        if (phase == "lobby" && input.fire_pressed && pointer_in(450, 438, 150, 32)) {
            net_menu = true; net_status = "Hospede ou informe o IPv4 do anfitriao."; return false;
        }
        return true;
    }
    if (!net_connected) return false;
    var _focused = net_test || window_has_focus();
    var _command = false;
    var _ui = false;
    if (_focused && !net_test) {
        if (input.fullscreen || (input.fire_pressed && pointer_in(550, 8, 72, 26))) {
            window_set_fullscreen(!window_get_fullscreen()); window_set_cursor(cr_arrow); _ui = true;
        }
        if (input.mute || (input.fire_pressed && pointer_in(480, 8, 66, 26))) {
            sound_enabled = !sound_enabled;
            if (music_voice != -1) audio_sound_gain(music_voice, sound_enabled ? 0.32 : 0, 0);
            _ui = true;
        }
        if (help_open) {
            if (input.pause || (input.fire_pressed && pointer_in(230, 392, 180, 36))) help_open = false;
            else if (input.fire_pressed) {
                if (pointer_in(64, 392, 150, 36)) help_page = max(0, help_page - 1);
                if (pointer_in(426, 392, 150, 36)) help_page = min(2, help_page + 1);
            }
            _ui = true;
        } else if (input.fire_pressed && pointer_in(302, 8, 96, 26)) { help_open = true; help_page = 0; _ui = true; }
        else if (input.pause || (input.fire_pressed && pointer_in(410, 8, 66, 26))) { _command = true; _ui = true; }
        if (paused && input.fire_pressed && !help_open) {
            if (pointer_in(180, 168, 280, 34)) { _command = true; _ui = true; }
            if (pointer_in(180, 212, 280, 34)) {
                net_send({kind: "bye", protocol: net_protocol}); net_close("Voce desconectou."); return false;
            }
        }
    }
    var _local = net_pack_input(!_focused || help_open || _ui, _command);
    if (net_mode == "client") {
        array_push(net_sent_at, [_local.seq, current_time]);
        if (array_length(net_sent_at) > 180) array_delete(net_sent_at, 0, 1);
        net_send(_local);
        net_waiting = current_time - net_last_rx > 500;
        return false;
    }
    var _remote = net_remote;
    if (array_length(net_queue) > 0) {
        _remote = net_queue[0]; array_delete(net_queue, 0, 1);
    }
    if (is_undefined(_remote)) { net_waiting = true; return false; }
    net_remote = _remote;
    net_waiting = current_time - net_last_rx > 500;
    if (_local.data[16] == 1 || _remote.data[16] == 1) net_manual_pause = !net_manual_pause;
    var _was_paused = paused;
    paused = net_manual_pause || _local.data[15] == 1 || _remote.data[15] == 1 || net_waiting;
    if (paused || _was_paused) { cancel_gesture(); dragging = false; dash_remaining = 0; input_gate = true; }
    if (_remote.epoch != net_epoch()) {
        // Late controls cannot acknowledge a new role or fire after a phase transition.
        _remote = { data: [320,280,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0] };
    }
    net_merge(_local, _remote);
    net_no_edges(net_remote);
    return !paused;
};

net_end_frame = function() {
    if (net_mode == "host" && net_connected) {
        if (phase == "dodge" && !paused) net_test_ticks++;
        if (turn_id != net_test_seen_turn) { net_test_seen_turn = turn_id; net_test_swaps++; }
        net_test_damage = max(net_test_damage, 200 - players[0].hp - players[1].hp);
        // At most two outstanding snapshots: a slow guest cannot accumulate an unbounded TCP backlog.
        if (net_snapshot_seq - net_state_ack <= 2) net_send(net_capture_state());
    }
    if (net_mode != "local") {
        pointer_x = net_local_x; pointer_y = net_local_y;
        if (net_test) window_set_caption("LANQA " + net_mode + " ticks=" + string(net_test_ticks) + " swaps=" + string(net_test_swaps) + " damage=" + string(net_test_damage) + " seq=" + string(net_mode == "host" ? net_snapshot_seq : net_applied_seq) + " checks=" + string(net_verified_states));
        else window_set_caption("SOUL SWAP " + mod_version + " / LAN P" + string(net_player + 1) + " / " + (net_player == attacker ? "ATACANTE - MOUSE" : "DEFENSOR - TECLADO"));
    }
};

for (var _arg = 1; _arg <= parameter_count(); _arg++) {
    if (parameter_string(_arg) == "--lan-test") net_test = true;
    if (parameter_string(_arg) == "--lan") net_menu = true;
}
if (qa_preview && parameter_count() >= 2 && parameter_string(2) == "lan") net_menu = true;
for (var _arg = 1; _arg <= parameter_count(); _arg++) {
    if (parameter_string(_arg) == "--lan-host" && _arg + 1 <= parameter_count()) {
        net_port_text = parameter_string(_arg + 1); net_start(true); break;
    }
    if (parameter_string(_arg) == "--lan-join" && _arg + 2 <= parameter_count()) {
        net_ip = parameter_string(_arg + 1); net_port_text = parameter_string(_arg + 2); net_start(false); break;
    }
}
