// User information bean class

class User {
  String name;
  int hashCode;
  //String ip;
  
  User(this.name){
    hashCode = this.name.hashCode;
  }
  
  bool operator == (User user){
    return user.name == this.name;
  }
}