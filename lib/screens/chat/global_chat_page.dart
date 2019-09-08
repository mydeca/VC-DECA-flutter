import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vc_deca_flutter/models/chat_message.dart';
import 'package:vc_deca_flutter/models/user.dart';
import 'package:vc_deca_flutter/utils/config.dart';
import 'package:vc_deca_flutter/utils/hex_color.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:vc_deca_flutter/utils/theme.dart';
import 'package:intl/intl.dart';
import '../../user_info.dart';

class GlobalChatPage extends StatefulWidget {
  @override
  _GlobalChatPageState createState() => _GlobalChatPageState();
}

class _GlobalChatPageState extends State<GlobalChatPage> {

  final databaseRef = FirebaseDatabase.instance.reference();
  final storageRef = FirebaseStorage.instance.ref();
  final myController = new TextEditingController();
  FocusNode myFocusNode = new FocusNode();
  ScrollController _scrollController = new ScrollController();
  List<ChatMessage> messageList = new List();
  List<String> noNoWordList = new List();
  bool _nsfw = false;

  Color sendColor = Colors.grey;

  String memberColor = "#F6BB3B";
  String officerColor = "#F6BB3B";
  String botColor = "#F6BB3B";
  String advisorColor = "#F6BB3B";
  String chaperoneColor = "#F6BB3B";

  String type = "text";
  String message = "";

  bool canSendMessage = true;
  bool canDeleteMessage = false;

  _GlobalChatPageState() {
    databaseRef.child("chatColors").once().then((DataSnapshot snapshot) {
      setState(() {
        memberColor = snapshot.value["memberColor"];
        officerColor = snapshot.value["officerColor"];
        botColor = snapshot.value["botColor"];
        advisorColor = snapshot.value["advisorColor"];
        chaperoneColor = snapshot.value["chaperoneColor"];
      });
    });

    // Message Send Perms Check
    if (selectedChat == "global" && !userPerms.contains("CHAT_SEND")) {
      canSendMessage = false;
    }
    else if (selectedChat == "officer" && !userPerms.contains("OFFICER_CHAT_SEND")) {
      canSendMessage = false;
    }
    else if (selectedChat == "leader" && !userPerms.contains("LEADER_CHAT_SEND")) {
      canSendMessage = false;
    }

    if (userPerms.contains("ADMIN") || userPerms.contains("DEV")) {
      canDeleteMessage = true;
    }

    databaseRef.child("chat").child(selectedChat).onChildAdded.listen(onNewMessage);

    databaseRef.child("chatNoNoWords").onChildAdded.listen((Event event) {
      noNoWordList.add(event.snapshot.value.toString());
    });
  }

  void showMessageDetails(int index) async {
    if (Platform.isIOS) {
      showCupertinoModalPopup(context: context, builder: (BuildContext context) {
        return new CupertinoActionSheet(
          title: new Text("Message Options"),
          message: new Text(messageList[index].message),
          actions: <Widget>[
            new CupertinoActionSheetAction(
              child: new Text("Report"),
              onPressed: () {
                databaseRef.child("chat").child("reports").child(selectedChat).child(messageList[index].key).set(messageList[index].message);
                Navigator.pop(context);
              },
            ),
            new Visibility(
              visible: canDeleteMessage,
              child: new CupertinoActionSheetAction(
                child: new Text("Delete Message"),
                isDestructiveAction: true,
                onPressed: () {
                  databaseRef.child("chat").child(selectedChat).child(messageList[index].key).set(null);
                  setState(() {
                    messageList.removeAt(index);
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
          cancelButton: new CupertinoActionSheetAction(
            child: const Text("Cancel"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          )
        );
      });
    }
    else if (Platform.isAndroid) {
      showModalBottomSheet(context: context, builder: (BuildContext context) {
        return new SafeArea(
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new ListTile(
                title: new Text('Message Options', style: TextStyle(fontWeight: FontWeight.bold),),
              ),
              new ListTile(
                title: new Text(messageList[index].message),
              ),
              new ListTile(
                leading: new Icon(Icons.report),
                title: new Text('Report'),
                onTap: () {
                  databaseRef.child("chat").child("reports").child(selectedChat).child(messageList[index].key).set(messageList[index].message);
                  Navigator.pop(context);
                }
              ),
              new ListTile(
                  leading: new Icon(Icons.delete),
                  title: new Text('Delete Message'),
                  onTap: () {
                    databaseRef.child("chat").child(selectedChat).child(messageList[index].key).set(null);
                    setState(() {
                      messageList.removeAt(index);
                    });
                    Navigator.pop(context);
                  }
              ),
              new ListTile(
                leading: new Icon(Icons.clear),
                title: new Text('Cancel'),
                onTap: () {
                  router.pop(context);
                },
              ),
            ],
          ),
        );
      });
    }
  }

  onNewMessage(Event event) async {
    if (event.snapshot.value["nsfw"]) {
      // This message contains a No No Word
      if (role != "Advisor" && role != "Chaperone") {
        setState(() {
          messageList.add(new ChatMessage.fromSnapshot(event.snapshot, false));
        });
      }
    }
    else {
      if (messageList.length >= 1 && messageList.last.authorID == event.snapshot.value["userID"]) {
        setState(() {
          messageList.add(new ChatMessage.fromSnapshot(event.snapshot, true));
        });
      }
      else {
        setState(() {
          messageList.add(new ChatMessage.fromSnapshot(event.snapshot, false));
        });
      }
    }
    await new Future.delayed(const Duration(milliseconds: 300));
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 10.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void sendMessage() {
    if (message != "" && message != " " && message != "  " && message != "  ") {
      // Configure message color
      String messageColor = "#F6BB3B";
      if (userPerms.contains("DEV") && customChatColor != "") {
        messageColor = customChatColor;
      }
      else {
        // Default to role-based color scheme
        if (role == "Officer") {
          messageColor = officerColor;
        }
        else if (role == "Advisor") {
          messageColor = advisorColor;
        }
        else if (role == "Chaperone") {
          messageColor = chaperoneColor;
        }
        else {
          messageColor = memberColor;
        }
      }
      // Check for nsfw content
      noNoWordList.forEach((badWord) {
        if (message.toLowerCase().contains(badWord)) {
          _nsfw = true;
          print("nsfw content detected");
        }
      });
      // Send message
      databaseRef.child("chat").child(selectedChat).push().update({
        "author": name,
        "message": message,
        "userID": userID,
        "date": new DateFormat('MM/dd/yyyy hh:mm aaa').format(new DateTime.now()),
        "role": role,
        "type": type,
        "color": messageColor,
        "profileUrl": profilePic,
        "nsfw": _nsfw
      });
      myController.clear();
      setState(() {
        message = "";
        sendColor = Colors.grey;
      });
      _nsfw = false;
    }
  }

  void textChanged(String input) {
    if (input != "" && input != " " && input != "  " && input != "  ") {
      type = "text";
      setState(() {
        message = input;
        sendColor = mainColor;
      });
    }
    else {
      type = "";
      setState(() {
        message = input;
        sendColor = Colors.grey;
      });
    }
  }

  void showUserSheet(String userID, String roleColor) {
    showModalBottomSheet(context: context, builder: (context) {
      return new UserInfoSheet(userID, roleColor);
    });
  }

  Widget getMessageBody(int index) {
    if (messageList[index].mediaType == "text") {
      return new Container(
        padding: (messageList[index].repeatAuthor) ? EdgeInsets.only(top: 8.0) : EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            new Container(
              padding: EdgeInsets.only(right: 8.0, left: 8.0),
              child: new GestureDetector(
                onTap: () {
//              showUserSheet(messageList[index].authorID, messageList[index].messageColor);
                },
                child: new ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  child: new CachedNetworkImage(
                    imageUrl: messageList[index].profileUrl,
                    height: (messageList[index].repeatAuthor) ? 0.0 : 50.0,
                    width: 50.0,
                  ),
                ),
              ),
            ),
            new Expanded(
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    child: new GestureDetector(
                      onLongPress: () {
                        showMessageDetails(index);
                      },
                      onTap: () {
//                    showUserSheet(messageList[index].authorID, messageList[index].messageColor);
                      },
                      child: new Visibility(
                        visible: !messageList[index].repeatAuthor,
                        child: new Text(
                          messageList[index].author,
                          style: TextStyle(fontSize: 15.0, color: HexColor(messageList[index].messageColor)),
                        ),
                      ),
                    ),
                  ),
                  new Visibility(visible: !messageList[index].repeatAuthor, child: new Padding(padding: EdgeInsets.all(2.0)),),
                  new Container(
                    child: new GestureDetector(
                      onLongPress: () {
                        showMessageDetails(index);
                      },
                      child: new Linkify(
                        onOpen: (url) async {
                          if (await canLaunch(url.url)) {
                            await launch(url.url);
                          } else {
                            throw 'Could not launch $url';
                          }
                        },
                        text: messageList[index].message,
                        style: TextStyle(fontSize: 15.0, color: currTextColor),
                        linkStyle: TextStyle(
                            fontFamily: "Product Sans",
                            color: HexColor(messageList[index].messageColor),
                            fontSize: 15.0
                        ),
                      ),
                    ),
                  ),
//                  new Visibility(visible: messageList[index].repeatAuthor, child: new Padding(padding: EdgeInsets.all(4.0)))
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<Null> focusNodeListener() async {
    if (myFocusNode.hasFocus) {
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 10.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    myFocusNode.addListener(focusNodeListener);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mainColor,
        title: new Text(chatTitle),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Colors.white,
      body: new SafeArea(
        child: Column(
          children: <Widget>[
            new Expanded(
              child: new Container(
                child: new ListView.builder(
                  itemCount: messageList.length,
                  controller: _scrollController,
                  itemBuilder: (BuildContext context, int index) {
                    return getMessageBody(index);
                  },
                ),
              ),
            ),
            new Visibility(
              visible: !canSendMessage,
              child: Container(
                child: new Text("It looks like you don't have permission to send messages in the this chat!\n\nIf this is a mistake, please contact the admin."),
                padding: EdgeInsets.all(15.0),
              ),
            ),
            new Visibility(
              visible: canSendMessage,
              child: new ListTile(
                  title: Container(
                    child: Row(
                      children: <Widget>[
                        // Button send image
                        Material(
                          child: new Container(
                            margin: new EdgeInsets.symmetric(horizontal: 1.0),
                            child: new IconButton(
                              icon: new Icon(Icons.image),
                              color: Colors.grey,
                              onPressed: () {
                                // TODO: Implement Image Sending
                              },
                            ),
                          ),
                          color: Colors.white,
                        ),
                        // Edit text
                        Flexible(
                          child: Container(
                            child: TextField(
                              controller: myController,
                              textInputAction: TextInputAction.newline,
                              textCapitalization: TextCapitalization.sentences,
                              style: TextStyle(fontFamily: "Product Sans", color: Colors.black, fontSize: 15.0),
                              decoration: InputDecoration.collapsed(
                                  hintText: 'Type your message...',
                                  hintStyle: TextStyle(fontFamily: "Product Sans")
                              ),
                              focusNode: myFocusNode,
                              onChanged: textChanged,
                            ),
                          ),
                        ),
                        new Material(
                          child: new Container(
                            margin: new EdgeInsets.symmetric(horizontal: 8.0),
                            child: new IconButton(
                                icon: new Icon(Icons.send),
                                color: sendColor,
                                onPressed: sendMessage
                            ),
                          ),
                          color: Colors.white,
                        )
                      ],
                    ),
                    width: double.infinity,
                    height: 50.0,
                    decoration: new BoxDecoration(
                        border: new Border(top: new BorderSide(color: mainColor, width: 0.5)), color: Colors.white),
                  )
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class UserInfoSheet extends StatefulWidget {

  String userID;
  String roleColor;

  UserInfoSheet(String userID, String roleColor) {
    this.userID = userID;
  }

  @override
  _UserInfoSheetState createState() => _UserInfoSheetState(userID, roleColor);
}

class _UserInfoSheetState extends State<UserInfoSheet> {

  String userID;
  String roleColor;
  DataSnapshot userSnapshot;

  _UserInfoSheetState(String userID, String roleColor) {
    this.userID = userID;
    this.roleColor = roleColor;
    FirebaseDatabase.instance.reference().child("users").child(userID).once().then((DataSnapshot snapshot) {
      userSnapshot = snapshot;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      child: Container(
        padding: EdgeInsets.only(top: 16.0, bottom: 16.0),
        color: currBackgroundColor,
        child: new Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                new ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(150.0)),
                  child: new CachedNetworkImage(
                    imageUrl: userSnapshot.value["profilePicUrl"],
                    height: 100.0,
                  ),
                ),
                new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      userSnapshot.value["name"],
                      style: TextStyle(fontSize: 25.0),
                    ),
                    new Text(
                      userSnapshot.value["email"],
                      style: TextStyle(fontSize: 15.0),
                    )
                  ],
                )
              ],
            ),
            new Container(
              height: 100.0,
//              color: HexColor(roleColor),
              child: new Center(
                child: new Text(
                  userSnapshot.value["role"],
                  style: TextStyle(fontSize: 20.0, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
