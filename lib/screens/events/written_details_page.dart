import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vc_deca_flutter/user_info.dart';
import 'package:vc_deca_flutter/utils/config.dart';
import 'package:vc_deca_flutter/utils/theme.dart';
import 'package:http/http.dart' as http;

class WrittenDetailsPage extends StatefulWidget {
  @override
  _WrittenDetailsPageState createState() => _WrittenDetailsPageState();
}

class _WrittenDetailsPageState extends State<WrittenDetailsPage> {

  String participants = "";
  String pages = "";
  String presentationTime = "";
  String guidelinesUrl = "";
  String sampleUrl = "";
  String penaltyUrl = "";

  @override
  void initState() {
    super.initState();
    refreshAnnouncementCount();
  }

  void refreshAnnouncementCount() async {
    try {
      await http.get(getDbUrl("events/$selectedType/$selectedCluster/${selectedEvent.eventShort}")).then((response) {
        var responseJson = jsonDecode(response.body);
        setState(() {
          participants = responseJson['participants'].toString();
          pages = responseJson['pages'].toString();
          presentationTime = responseJson['presentationTime'].toString();
          guidelinesUrl = responseJson['guidelines'].toString();
          sampleUrl = responseJson['sample'].toString();
          penaltyUrl = responseJson['penalty'].toString();
        });
      });
    }
    catch (error) {
      print("Failed to pull announcement count! - $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          backgroundColor: eventColor,
          title: new Text(selectedEvent.eventShort),
          elevation: 0.0,
        ),
        backgroundColor: currBackgroundColor,
        body: new Stack(
          children: <Widget>[
            new Container(
              color: eventColor,
              height: 100.0,
            ),
            new Container(
              child: new SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    new Hero(
                      tag: "${selectedEvent.eventName}-card",
                      child: new Card(
                        elevation: 6.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
                        color: currCardColor,
                        child: new Container(
                          padding: EdgeInsets.all(16.0),
                          child: new Column(
                            children: <Widget>[
                              new Text(
                                  selectedEvent.eventName,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)
                              ),
                              new Container(
                                width: double.infinity,
                                height: 100.0,
                                child: new Row(
                                  children: <Widget>[
                                    new Expanded(
                                      flex: 3,
                                      child: new Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          new Text(
                                            participants,
                                            style: TextStyle(fontSize: 35.0),
                                          ),
                                          new Text(
                                            "Participants",
                                            style: TextStyle(fontSize: 15.0),
                                          )
                                        ],
                                      ),
                                    ),
                                    new Expanded(
                                      flex: 3,
                                      child: new Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          new Text(
                                            pages,
                                            style: TextStyle(fontSize: 35.0),
                                          ),
                                          new Text(
                                            "Pages",
                                            style: TextStyle(fontSize: 15.0),
                                          )
                                        ],
                                      ),
                                    ),
                                    new Expanded(
                                      flex: 3,
                                      child: new Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: <Widget>[
                                          new Text(
                                            presentationTime,
                                            style: TextStyle(fontSize: 35.0),
                                          ),
                                          new Text(
                                            "Minutes",
                                            style: TextStyle(fontSize: 15.0),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              new Text(
                                selectedEvent.eventBody,
                                style: TextStyle(fontSize: 15.0),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    new Padding(padding: EdgeInsets.all(4.0)),
                    new Card(
                      elevation: 6.0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
                      color: currCardColor,
                      child: new Container(
                        padding: EdgeInsets.all(16.0),
                        child: new Column(
                          children: <Widget>[

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
    );
  }
}
