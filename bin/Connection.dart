// Connection information class

library connection;
import 'dart:io';

class Connection {
  int connection_id;
  List<WebSocket> socket_list;
  
  Connection(this.connection_id);
  
  int removeClient(WebSocket disconn_socket){
    return socket_list.remove(disconn_socket) ? connection_id : -1;
  }
}