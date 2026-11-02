// Presentation only. All gameplay state is updated in Step.
draw_set_alpha(1);
draw_set_font(fnt_main);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_clear(c_black);
var _colors = [make_color_rgb(80, 220, 255), make_color_rgb(255, 126, 189)];
var _dim = make_color_rgb(160, 160, 180);
ui_text(22, 12, net_mode == "local" ? "SOUL / SWAP" : "LAN / P" + string(net_player + 1), c_white, 1.5);
ui_text(180, 2, string(perf_fps) + " FPS", _dim, 1, 114);
ui_text(180, 16, "PING " + (net_mode == "local" || !net_connected || net_rtt < 0 ? "--" : string(floor(net_rtt)) + "ms"), _dim, 1, 114);
if (net_connected) ui_text(180, 30, "REDE " + string(perf_hz) + "/s", _dim, 1, 114);
ui_button(302, 8, 96, 26, "AJUDA", c_yellow);
ui_button(410, 8, 66, 26, "PAUSA", c_white);
ui_button(480, 8, 66, 26, sound_enabled ? "SOM" : "MUDO", c_white);
ui_button(550, 8, 72, 26, "TELA", c_white);

draw_panel(18, 48, 604, 48, c_white);
for (var _p = 0; _p < 2; _p++) {
    var _lx = _p == 0 ? 32 : 344;
    ui_text(_lx, 55, character_names[_p] + " / P" + string(_p + 1), _colors[_p], 1);
    ui_text(_lx + 174, 55, string(players[_p].hp) + "/" + string(max_hp), c_white, 1);
    draw_set_color(make_color_rgb(50, 30, 45));
    draw_rectangle(_lx + 28, 77, _lx + 264, 87, false);
    draw_set_color(players[_p].flash > 0 ? c_white : _colors[_p]);
    draw_rectangle(_lx + 28, 77, _lx + 28 + 236 * players[_p].hp / max_hp, 87, false);
    draw_sprite_ext(spr_hpname, 0, _lx, 77, 1, 1, 0, c_white, 1);
}

if (phase == "lobby" || phase == "result" || phase == "handoff") {
    var _next = phase == "handoff" ? attacker : opening_player;
    var _title = "MOUSE ATACA / TECLADO DESVIA";
    if (phase == "handoff") _title = "TROQUEM O MOUSE DE JOGADOR";
    if (net_mode != "local") _title = net_player == _next ? "VOCE ATACA / USE O MOUSE" : "VOCE DEFENDE / USE O TECLADO";
    if (phase == "result") _title = winner < 0 ? "EMPATE!" : character_names[winner] + " VENCEU!";
    ui_text(40, 114, _title, c_white, 1);
    for (var _side = 0; _side < 2; _side++) {
        var _cx = 40 + _side * 290;
        var _player = _side == 0 ? _next : 1 - _next;
        draw_panel(_cx, 144, 270, 166, _colors[_player]);
        ui_text(_cx + 16, 158, "P" + string(_player + 1) + " / " + character_names[_player], _colors[_player], 1, 160);
        ui_text(_cx + 16, 185, _side == 0 ? "ATACANTE" : "DEFENSOR", c_white, 1, 160);
        draw_character(_player, _cx + 218, 242);
        ui_text(_cx + 16, 224, _side == 0 ? "MOUSE" : "TECLADO", c_white, 1, 150);
        ui_text(_cx + 16, 253, _side == 0 ? "Esquerdo: ataque" : "WASD / setas: mover", _dim, 1, 238);
        ui_text(_cx + 16, 275, _side == 0 ? "Direito: especial" : "Shift: foco   Q: evasao", _dim, 1, 238);
    }
    ui_button(40, 320, 270, 50, mouse_ready ? "MOUSE PRONTO" : "CLIQUE PARA CONFIRMAR", mouse_ready ? c_lime : _colors[_next], mouse_ready);
    ui_button(330, 320, 270, 50, keyboard_ready ? "TECLADO PRONTO" : "APERTE ENTER", keyboard_ready ? c_lime : _colors[1 - _next], keyboard_ready);
    ui_text(40, 390, net_mode == "local" ? "Cada jogador confirma o seu controle para comecar." : "Cada um confirma no seu PC. Nao troquem de computador.", _dim, 1);
    ui_text(40, 422, "Primeira vez? Clique em AJUDA para ver como jogar.", c_white, 1);
    if (phase == "result") {
        ui_text(30, 448, "Por pouco: " + string(match_grazes[0]) + " / " + string(match_grazes[1]) + "   Perfeitos: " + string(perfect_turns[0]) + " / " + string(perfect_turns[1]), _dim, 1);
    } else ui_text(30, 450, "Vitorias: " + string(wins[0]) + " - " + string(wins[1]), _dim, 1);
    if (phase == "lobby" && net_mode == "local") ui_button(450, 438, 150, 32, "JOGAR EM LAN", c_lime);
} else if (phase == "plan") {
    ui_text(40, 114, net_mode != "local" && net_player != attacker ? "AGUARDE A ESCOLHA DO ATACANTE" : character_names[attacker] + " / MONTE SUA DUPLA", _colors[attacker], 1);
    ui_text(460, 114, "1. SLOT  2. ATAQUE", _dim, 1, 150);
    for (var _slot = 0; _slot < 2; _slot++) {
        var _sx = 40 + _slot * 290;
        ui_button(_sx, 143, 270, 30, string(_slot + 1) + ": " + pattern_names[loadouts[attacker][_slot]], _colors[attacker], edit_slot == _slot);
    }
    for (var _i = 0; _i < 6; _i++) {
        var _choice = selection_page * 6 + _i;
        if (_choice >= attack_count) continue;
        var _xx = 40 + (_i mod 2) * 290;
        var _yy = 182 + floor(_i / 2) * 43;
        ui_button(_xx, _yy, 270, 38, pattern_names[_choice], _colors[attacker], _choice == loadouts[attacker][edit_slot]);
        draw_sprite_ext(projectile_sprites[_choice], 0, _xx + 246, _yy + 18, 0.7, 0.7, 0, c_white, 1);
    }
    ui_button(40, 311, 270, 38, "PAGINA " + string(selection_page + 1) + "/2 >", c_white);
    ui_button(330, 311, 270, 38, "CONFIRMAR / " + string(ceil(phase_ticks / tick_rate)) + "s", c_lime);
    draw_panel(40, 364, 560, 48, make_color_rgb(75, 80, 98));
    ui_text(54, 374, "ESQ: " + attack_left[loadouts[attacker][edit_slot]], _colors[attacker], 1, 532);
    ui_text(54, 394, "DIR: " + attack_right[loadouts[attacker][edit_slot]], _dim, 1, 532);
    ui_text(40, 438, "Roda: selecionar  /  clique: equipar no slot marcado", _dim, 1);
} else {
    ui_text(24, 108, net_mode == "local" ? "TURNO " + string(turn_number + 1) + "/" + string(max_turns) : "VOCE: " + (net_player == attacker ? "ATACA" : "DESVIA"), c_white, 1);
    ui_text(200, 108, character_names[attacker] + " ATACA > " + character_names[defender], _colors[attacker], 1);
    ui_text(24, 137, pattern_names[pattern], c_white, 1);
    ui_text(550, 137, string(ceil(max(0, phase_ticks) / tick_rate)) + "s", c_white, 1);
    if (phase == "dodge") ui_text(112, 157, combat_status(), c_yellow, 1, 416);
    draw_panel(arena_left - 4, arena_top - 4, arena_right - arena_left + 8, arena_bottom - arena_top + 8, c_white);
    draw_character(0, 54, 309);
    draw_character(1, 586, 309);
    ui_text(18, 329, attacker == 0 ? "MOUSE" : "TECLADO", _colors[0], 1);
    ui_text(550, 329, attacker == 1 ? "MOUSE" : "TECLADO", _colors[1], 1);
    if (phase == "swap") {
        ui_text(162, 246, turn_damage == 0 ? "DEFESA PERFEITA!" : "FIM DO ATAQUE", turn_damage == 0 ? c_lime : c_white, 1.5);
        ui_text(164, 294, string(turn_damage) + " de dano / trocando papeis", _dim, 1);
        ui_text(164, 320, "Esquivas por pouco: " + string(turn_grazes), _colors[defender], 1);
        var _best = 0;
        for (var _i = 1; _i < attack_count; _i++) if (damage_by_pattern[_i] > damage_by_pattern[_best]) _best = _i;
        ui_text(164, 346, turn_damage > 0 ? "Destaque: " + pattern_names[_best] : "Nenhum ataque acertou!", c_white, 1);
    } else {
        // Original game sprites provide emitter, warning, projectile and cursor art.
        if (pattern == 7) draw_route(stroke, c_yellow);
        if (pattern == 8 && charge_ticks > 0) {
            var _origin = edge_position(target_x, target_y);
            var _heading = point_direction(_origin[0], _origin[1], target_x, target_y);
            var _dx = target_x - _origin[0];
            var _dy = target_y - _origin[1];
            var _length = sqrt(_dx * _dx + _dy * _dy) + 60 + charge_ticks * 2;
            draw_set_color(c_yellow);
            draw_set_alpha(0.4);
            var _count = charge_ticks >= 20 ? 2 : 1;
            for (var _fan = -_count; _fan <= _count; _fan++) {
                var _vx = lengthdir_x(1, _heading + _fan * 14);
                var _vy = lengthdir_y(1, _heading + _fan * 14);
                var _tx = abs(_vx) < 0.0001 ? 10000 : ((_vx > 0 ? arena_right - 5 : arena_left + 5) - _origin[0]) / _vx;
                var _ty = abs(_vy) < 0.0001 ? 10000 : ((_vy > 0 ? arena_bottom - 5 : arena_top + 5) - _origin[1]) / _vy;
                var _dist = min(_length, _tx, _ty);
                draw_line(_origin[0], _origin[1], _origin[0] + _vx * _dist, _origin[1] + _vy * _dist);
            }
            draw_set_alpha(1);
        }
        for (var _i = 0; _i < array_length(seeds); _i++) {
            var _s = seeds[_i];
            var _ready = _s.travel <= 0 && _s.mature <= 0;
            var _color = _s.fuse >= 0 ? c_yellow : (_ready ? c_lime : _colors[attacker]);
            draw_sprite_ext(spr_smallbullet, 0, _s.sx, _s.sy, 2, 2, ui_tick * 2, _color, 0.8);
            draw_sprite_ext(spr_custommenu_arrow, 0, _s.sx + lengthdir_x(14, _s.heading), _s.sy + lengthdir_y(14, _s.heading), 1, 1, _s.heading + 90, _color, 0.8);
            if (_s.fuse >= 0) {
                for (var _a = 0; _a < 360; _a += 36)
                    draw_sprite_ext(spr_smallbullet, 0, _s.sx + lengthdir_x(22, _s.heading + _a + _s.bloom * 18), _s.sy + lengthdir_y(22, _s.heading + _a + _s.bloom * 18), 1, 1, 0, c_yellow, 0.5);
            }
        }
        for (var _i = 0; _i < array_length(hazards); _i++) {
            var _h = hazards[_i];
            var _warning = _h.timer > 0;
            if (_h.kind == 2) draw_wall_preview(_h.hx, _h.hy, _h.horizontal, _colors[attacker], _h.wave == 1);
            else if (_h.kind == 4) draw_reflector(_h.hx, _h.hy, _h.horizontal, _warning ? _colors[attacker] : c_yellow);
            else if (_h.kind == 3) {
                for (var _a = 0; _a < 360; _a += 15) {
                    var _delta = ((_a - _h.heading + 540) mod 360) - 180;
                    if (abs(_delta) > 30)
                        draw_sprite_ext(spr_smallbullet, 0, _h.hx + lengthdir_x(20, _a), _h.hy + lengthdir_y(20, _a), 1.5, 1.5, 0, _colors[attacker], 0.5);
                }
            } else if (_h.kind == 6) {
                draw_set_color(_colors[attacker]);
                draw_set_alpha(0.3);
                draw_line(arena_left + 5, _h.hy, arena_right - 5, _h.hy);
                draw_line(_h.hx, arena_top + 5, _h.hx, arena_bottom - 5);
                draw_set_alpha(1);
                draw_sprite_ext(spr_spadebullet, 0, _h.hx, _h.hy, 1, 1, 0, _colors[attacker], 0.6);
            }
            else {
                draw_sprite_ext(projectile_sprites[_h.kind], 0, _h.hx, _h.hy, 1.5, 1.5, ui_tick * 3, _colors[attacker], _warning ? 0.5 : 1);
            }
        }
        for (var _i = 0; _i < array_length(bullets); _i++) {
            var _b = bullets[_i];
            // Off-arena survivors are retained briefly by the simulation, but must not cover the HUD.
            // The SOUL is clamped 10px inside; an outside center cannot reach its 8.2px collision radius.
            if (_b.bx < arena_left || _b.bx > arena_right || _b.by < arena_top || _b.by > arena_bottom) continue;
            if (_b.art == 7 && _b.age <= 0 && _b.age >= -stitch_warning_ticks && array_length(_b.route) > 0) draw_route(_b.route, _colors[attacker]);
            if (_b.art == 8 && _b.returning && _b.age <= 0) {
                draw_set_color(c_yellow);
                draw_set_alpha(0.5);
                draw_line(_b.bx, _b.by, _b.return_x, _b.return_y);
                draw_line(_b.return_x, _b.return_y, _b.ox, _b.oy);
                draw_set_alpha(1);
            }
            if (_b.age <= 0 && _b.age >= -24 && _b.orbit <= 0 && array_length(_b.route) == 0 && !_b.returning) {
                draw_set_color(_b.age >= -12 ? c_yellow : _colors[attacker]);
                draw_set_alpha(0.25);
                draw_line(_b.bx, _b.by, clamp(_b.bx + _b.vx * 12, arena_left + 5, arena_right - 5), clamp(_b.by + _b.vy * 12, arena_top + 5, arena_bottom - 5));
                draw_set_alpha(1);
            }
            var _scale = projectile_scales[_b.art];
            var _angle = point_direction(0, 0, _b.vx, _b.vy);
            draw_sprite_ext(projectile_sprites[_b.art], 0, _b.bx, _b.by, _scale, _scale, _angle, _b.age <= 0 ? _colors[attacker] : c_white, _b.age <= 0 ? 0.4 : 1);
        }
        if (dash_remaining > 0) {
            for (var _trail = 1; _trail <= 3; _trail++)
                draw_sprite_ext(spr_dodgeheart_centered_white, 0, soul_x - dash_x * _trail * 7, soul_y - dash_y * _trail * 7, 1, 1, 0, _colors[defender], 0.35 / _trail);
        }
        if (input.focus) {
            draw_set_color(c_white);
            draw_circle(soul_x, soul_y, soul_radius, true);
        }
        if (graze_flash > 0) {
            draw_sprite_ext(spr_dodgeheart_centered_white, 0, soul_x, soul_y, 1 + (12 - graze_flash) / 18, 1 + (12 - graze_flash) / 18, 0, _colors[defender], graze_flash / 40);
        }
        if (hit_feedback > 0) {
            // Original diamond sprite particles: visual-only, bounded to six draws.
            var _progress = 24 - hit_feedback;
            for (var _spark = 0; _spark < 6; _spark++) {
                draw_sprite_ext(spr_diamondbullet, 0, hit_x + lengthdir_x(12 + _progress * 1.4, _spark * 60), hit_y + lengthdir_y(12 + _progress * 1.4, _spark * 60), 0.25, 0.25, _spark * 60, _colors[defender], hit_feedback / 24);
            }
        }
        // SOUL stays above visual feedback: particles must not hide the defender.
        if (players[defender].inv <= 0 || (players[defender].inv mod 4) < 2)
            draw_heart(soul_x, soul_y, _colors[defender]);
        if (phase == "telegraph") {
            ui_text(186, 242, "PREPAREM-SE", c_white, 1.5);
            ui_text(158, 288, "Mouse ataca / teclado desvia", c_white, 1);
        }
        if (phase == "dodge" && (net_mode != "local" || pointer_in(arena_left, arena_top, arena_right - arena_left, arena_bottom - arena_top))) {
            var _edge = edge_position(target_x, target_y);
            draw_sprite_ext(spr_custommenu_arrow, 0, _edge[0], _edge[1], 1, 1, point_direction(_edge[0], _edge[1], target_x, target_y) + 90, _colors[attacker], 1);
            if (shot_flash > 0) draw_sprite_ext(projectile_sprites[pattern], 0, _edge[0], _edge[1], 1 + shot_flash / 5, 1 + shot_flash / 5, 0, _colors[attacker], shot_flash / 6);
            draw_sprite_ext(spr_diamondbullet, 0, target_x, target_y, 0.65, 0.65, 45, _colors[attacker], 0.75);
            if (dragging) {
                if (pattern == 4) draw_reflector(drag_x, drag_y, abs(target_x - drag_x) >= abs(target_y - drag_y), c_yellow);
                else draw_wall_preview(drag_x, drag_y, abs(target_x - drag_x) >= abs(target_y - drag_y), c_yellow);
            }
            if (pattern == 4) {
                draw_bounce_preview(_edge[0], _edge[1], _colors[attacker]);
            }
        }
    }
    draw_set_color(make_color_rgb(40, 40, 50));
    draw_rectangle(24, 406, 276, 414, false);
    draw_rectangle(300, 406, 552, 414, false);
    draw_set_color(recovering ? c_yellow : _colors[attacker]);
    draw_rectangle(24, 406, 24 + 252 * energy / energy_max, 414, false);
    draw_set_color(strategy_cooldown <= 0 ? c_lime : _dim);
    draw_rectangle(300, 406, 300 + 252 * (1 - strategy_cooldown / strategy_cooldown_ticks), 414, false);
    ui_text(24, 419, recovering ? "RECARREGANDO..." : "ENERGIA " + string(floor(energy)) + "%", _colors[attacker], 1);
    ui_text(300, 419, "ESPECIAL " + (strategy_cooldown > 0 ? string(ceil(strategy_cooldown / tick_rate)) + "s" : "PRONTO"), c_white, 1);
    ui_text(24, 442, "RODA: " + pattern_names[loadouts[attacker][1 - active_slot]], _dim, 1, 260);
    var _defense = hit_feedback > 0 ? "ACERTO: -" + string(hit_amount) + " HP" : (graze_flash > 0 ? "POR POUCO!" : "Q: " + (dash_available ? "EVASAO PRONTA" : "EVASAO USADA"));
    ui_text(300, 442, _defense, hit_feedback > 0 ? c_yellow : _colors[defender], 1, 300);
    ui_text(24, 464, "MOUSE: atacar   /   WASD ou setas: desviar   /   Shift: foco", _dim, 1, 592);
}
if (paused && net_mode == "local") {
    draw_set_color(c_black);
    draw_set_alpha(1);
    draw_rectangle(0, 100, 640, 480, false);
    draw_set_alpha(1);
    ui_text(224, 120, "PAUSADO", c_white, 1.5);
    var _choices = ["CONTINUAR", "REINICIAR PARTIDA", "VOLTAR AO LOBBY", "SAIR"];
    for (var _i = 0; _i < 4; _i++) {
        ui_button(180, 168 + _i * 44, 280, 34, _choices[_i], c_yellow);
    }
    ui_text(144, 367, "Clique para escolher / P ou Esc: voltar", _dim, 1);
}
if (debug_overlay) {
    draw_set_color(c_black);
    draw_rectangle(20, 100, 620, 124, false);
    ui_text(24, 106, "B " + string(array_length(bullets)) + " CPU us " + string(bullet_update_us) + " DIR " + string(right_click_count), c_lime, 1);
}
draw_set_alpha(1);
draw_set_color(c_white);
if (help_open) {
    draw_set_color(c_black);
    draw_rectangle(0, 0, 640, 480, false);
    draw_panel(40, 42, 560, 406, c_white);
    ui_text(64, 64, "COMO JOGAR", c_white, 1.5, 500);
    ui_text(64, 108, help_titles[help_page], c_yellow, 1, 500);
    ui_text(64, 139, "Tutorial aberto: a partida fica parada.", _dim, 1, 500);
    for (var _line = 0; _line < 6; _line++)
        ui_text(64, 182 + _line * 30, net_mode != "local" && help_page == 2 && _line == 4 ? "Apos 15s, trocam os papeis. Cada um fica no seu PC." : help_lines[help_page][_line], c_white, 1, 512);
    ui_text(64, 366, "Pagina " + string(help_page + 1) + "/3   |   Esc: fechar", _dim, 1, 500);
    ui_button(64, 392, 150, 36, "< ANTERIOR", c_white);
    ui_button(230, 392, 180, 36, "ENTENDI / FECHAR", c_lime);
    ui_button(426, 392, 150, 36, "PROXIMA >", c_white);
}
if (net_mode != "local" && paused && !help_open) {
    draw_set_color(c_black); draw_rectangle(0, 100, 640, 480, false);
    ui_text(170, 120, "PARTIDA LAN PAUSADA", c_white, 1.5, 440);
    ui_button(180, 168, 280, 34, "PAUSAR / CONTINUAR", c_lime);
    ui_button(180, 212, 280, 34, "DESCONECTAR", c_yellow);
    ui_text(80, 282, "Os dois precisam estar com o jogo em foco.", _dim, 1, 500);
    ui_text(80, 310, "Feche a AJUDA nos dois PCs para continuar.", _dim, 1, 500);
    ui_text(80, 338, "Se a pausa foi manual, clique em CONTINUAR.", _dim, 1, 500);
}
if (net_mode != "local" && net_waiting && !net_menu) {
    draw_set_color(c_black); draw_rectangle(100, 150, 540, 174, false);
    ui_text(112, 155, "AGUARDANDO REDE...", c_yellow, 1, 416);
}
if (net_menu) {
    draw_set_color(c_black); draw_rectangle(0, 0, 640, 480, false);
    draw_panel(40, 42, 560, 406, c_white);
    ui_text(72, 64, "MULTIPLAYER LAN", c_white, 1.5, 496);
    ui_text(72, 110, "P1 hospeda. P2 usa o IPv4 de P1 e a mesma porta.", c_white, 1, 496);
    ui_text(72, 148, "IPv4 DO ANFITRIAO", c_yellow, 1, 328);
    ui_text(420, 148, "PORTA TCP", c_yellow, 1, 148);
    ui_button(72, 174, 328, 38, net_ip, c_yellow, net_field == 1);
    ui_button(420, 174, 148, 38, net_port_text, c_yellow, net_field == 2);
    ui_button(72, 240, 238, 44, "HOSPEDAR / P1", c_lime);
    ui_button(330, 240, 238, 44, "CONECTAR / P2", c_lime);
    ui_text(72, 302, net_status, c_yellow, 1, 496);
    ui_text(72, 332, "IPv4 do seu PC: comando ipconfig no Windows.", _dim, 1, 496);
    ui_text(72, 354, "Mesma rede; permita o jogo no firewall privado.", _dim, 1, 496);
    ui_button(180, 390, 280, 38, net_mode == "local" ? "VOLTAR AO LOCAL" : "CANCELAR CONEXAO", c_white);
}
// Always last: the original menu arrow remains visible above pause/menu overlays.
// Use raw GUI pointer coordinates, not the arena-clamped targeting coordinates.
if (pointer_in(0, 0, 640, 480)) {
    draw_sprite_ext(spr_custommenu_arrow, 0, pointer_x + 1, pointer_y + 1, 1.5, 1.5, 135, c_black, 1);
    draw_sprite_ext(spr_custommenu_arrow, 0, pointer_x, pointer_y, 1, 1, 135, c_white, 1);
}
