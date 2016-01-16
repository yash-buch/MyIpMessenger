// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.


import 'dart:io';
import 'dart:math';
import 'User.dart';
import 'Connection.dart';
import 'Util.dart';

User clientInfo;
Map<User, WebSocket> clientMap = new Map<User, WebSocket>();
Map<WebSocket, User> clientMapReverse = new Map<WebSocket, User>();
Map<int, Connection> connection_map = new Map<int, Connection>();

main(List<String> arguments) async {
  HttpServer server = await HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 8888);
  print('Server is listening...');
  server.listen(onDone, onError: error);
}

onDone(HttpRequest request) async{
  clientInfo = new User(request.uri.pathSegments.last);
  if(WebSocketTransformer.isUpgradeRequest(request)){
    handleWebSocket(await WebSocketTransformer.upgrade(request));
  } else{
    print("Regular ${request.method} request for: ${request.uri.path}");
    serverRequest(request);
  }
}

error(){
  print('Error occured!');
}

handleWebSocket(WebSocket socket){
  print('${clientInfo.name} connected!');
  String user_list = sendActiveUserList();
  addUser(clientInfo, socket);
  socket.add(user_list);
  
  socket.listen((String str){
    String msg = handleConnection(str, socket);
    if(msg != null)
      socket.add(msg);
  },
  onDone: (){
    print('Client disconnected!');
    removeClient(socket);
  });
}

String handleConnection(String client_msg, WebSocket socket){
  List<String> inp = client_msg.split(':');   // get input message components
  int temp_conn_id = int.parse(inp.last);   // check for connection id
  inp = inp.sublist(0,inp.length-1);          // remove conection id component from the input message
  
  List<WebSocket> chat_member_list = new List<WebSocket>();   // List of sockets of members in the chat
  if(temp_conn_id == 0){
    for(String i in inp){
      User tUser = new User(i);
      if(!clientMap.containsKey(tUser)){
        chat_member_list.clear();
        return 'User $i is not online.';
      }
      chat_member_list.add(clientMap[tUser]);
    }
    chat_member_list.add(socket);
    int connection_id = generateConnId();
    Connection mConnection = new Connection(connection_id);   // new connection has been established
    mConnection.socket_list = chat_member_list;
    connection_map.putIfAbsent(connection_id, () => mConnection);
    for(WebSocket soc in chat_member_list){   // send connection id to all the chat members coz it is a fresh chat
      soc.add('${Util.CONNECTION_INFO}:$connection_id');
    }
    socket.add('${Util.CONNECTION_INFO}:$connection_id');
  } else {
    Connection mActiveConnection = connection_map[temp_conn_id];
    chat_member_list = mActiveConnection.socket_list;
    // send message to all the members in the chat
    for(WebSocket soc in chat_member_list){
      if(soc == socket)
        continue;
      soc.add('${clientMapReverse[socket].name}:${client_msg.substring(0,client_msg.lastIndexOf(':'))}');
    }
    
  }
  
  
  return null;
}

String sendActiveUserList(){
  String user_list = '';
  for(User user in clientMap.keys){
    user_list = user_list + user.name + ':';
  }
  return user_list;
}

addUser(User user, WebSocket socket){
  clientMap.putIfAbsent(user, () => socket);
  clientMapReverse.putIfAbsent(socket, () => user);
}

removeClient(WebSocket socket){
  User user_info = clientMapReverse.remove(socket);
  if(user_info != null)
    clientMap.remove(user_info);
  List<int> conn_ids = new List<int>();
  for(Connection conn in connection_map.values){
    int tConnId = conn.removeClient(socket);
    if(tConnId != -1){
      conn_ids.add(tConnId);
    }
  }
  /*for(int id in conn_ids){
    connection_map.remove(id);
  }*/
}

serverRequest(HttpRequest req){
  req.response.statusCode = HttpStatus.FORBIDDEN;
  req.response.reasonPhrase = 'Websockets only!';
  req.response.close();
}

int generateConnId(){
  var rnd = new Random();
  return rnd.nextInt(1000);
}