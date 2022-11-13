import 'package:flutter/material.dart';
import 'dart:io';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import "package:http/http.dart" as http;
import 'dart:convert';
import 'NFC.dart' as nfc;
import 'globals.dart' as global;

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, }) : super(key: key);
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  Map map = {};

  @override
  initState() {
    super.initState();
    String id = global.process_id;
    
    final url= global.url+"process/$id";

    http.get(
      Uri.parse(url),
    ).then((response) {
      setState(() {
        map = json.decode(response.body);
      });
      
    }); 

    
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      //controller!.pauseCamera();
    } else if (Platform.isIOS) {
      //controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (map.isEmpty) {
      return Container();
    }

    return Scaffold(
      body: 
      Center(child: Column(
    
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(75.0),
            child: Image.memory(base64Decode(nfc.dictTr["bio_image"]))) ,
          Container(
            padding: EdgeInsets.all(10.0),
            child: Text("Name: "+nfc.dictTr["givenNames"])),
          Container(
            padding: EdgeInsets.all(10.0),
            child: Text("Surname: "+nfc.dictTr["surnames"])),
          Container(
            padding: EdgeInsets.all(10.0),
            child: Text("Started at: "+map["started_at"])),
          Container(
            padding: EdgeInsets.all(10.0),
            child:Text("Finised at: "+map["finished_at"])),
          Container(
            padding: EdgeInsets.all(10.0),
            child:Text("Result: %"+((1-map["avg_distance"])*100).toString())),
          Container(
            padding: EdgeInsets.all(10.0),
            child: (1-map["avg_distance"])*100 > 50 ? Text("Verification successful") : Text("Verification failed"),),
        ],
      ),
      ),
    );
  }

}
