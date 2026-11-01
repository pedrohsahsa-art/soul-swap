if (net_mode == "local") exit;
var _type = ds_map_find_value(async_load, "type");
var _id = ds_map_find_value(async_load, "id");
if (_type == network_type_connect && net_mode == "host" && _id == net_socket) {
    var _socket = ds_map_find_value(async_load, "socket");
    if (net_peer >= 0) network_destroy(_socket);
    else { net_peer = _socket; net_last_rx = current_time; net_status = "Jogador encontrado. Conferindo versao..."; }
} else if (_type == network_type_non_blocking_connect && net_mode == "client" && _id == net_socket) {
    if (ds_map_find_value(async_load, "succeeded") != 1) net_close("Nao conectou. Confira IPv4, porta e firewall.");
    else { net_last_rx = current_time; net_send({ kind: "hello", protocol: net_protocol }); }
} else if (_type == network_type_disconnect) {
    var _socket = ds_map_find_value(async_load, "socket");
    if (_socket == net_peer || _id == net_peer) net_close("O outro jogador desconectou.");
} else if (_type == network_type_data && _id == net_peer) {
    var _size = ds_map_find_value(async_load, "size");
    var _limit = net_mode == "host" ? 2048 : 262144;
    if (_size <= 1 || _size > _limit) { net_close("Pacote de rede fora do limite."); exit; }
    var _buffer = ds_map_find_value(async_load, "buffer");
    // The event owns this buffer; read only here and never retain/delete its handle.
    if (buffer_peek(_buffer, _size - 1, buffer_u8) != 0) { net_close("Pacote de rede incompleto."); exit; }
    try {
        buffer_seek(_buffer, buffer_seek_start, 0);
        net_receive(json_parse(buffer_read(_buffer, buffer_string)));
    } catch (_error) { net_close("Pacote de rede invalido."); }
}
