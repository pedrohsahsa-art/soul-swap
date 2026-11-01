if (net_peer >= 0 && net_peer != net_socket) network_destroy(net_peer);
if (net_socket >= 0) network_destroy(net_socket);
if (net_buffer >= 0) buffer_delete(net_buffer);
if (music_stream != -1) audio_destroy_stream(music_stream);
