import 'dart:io';
import 'Util.dart';

WebSocket ws;
int connection_id;

main(List<String> arguments) async{
  
  if(arguments.length < 1){
    print('Please enter user name. for example: dart client.dart Muskan');
    exit(1);
  }
  
  String user_name = arguments[0];
  connection_id = 0;
  
  ws = await WebSocket.connect('ws://127.0.0.1:8888/$user_name');
  ws.listen(onMessage, onDone: connectionClosed);
  
  stdin.listen(onInput);
}

onMessage(String msg){
  List<String> msg_components = msg.split(':');
  if(msg_components[0] == Util.CONNECTION_INFO){
    connection_id = int.parse(msg_components[1]);
  } else {
    print(msg);
  }
}

connectionClosed(){
  print('Connection to server closed.');
}

onInput(List<int> input){
  String message = new String.fromCharCodes(input).trim();
  message = '$message:$connection_id';
  ws.add(message);
}