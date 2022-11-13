

import 'dart:convert' ;
import "package:hex/hex.dart";
import 'package:convert/convert.dart';
import 'package:turkish/turkish.dart' as tr;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'globals.dart' as global;
import 'package:dmrtd/dmrtd.dart';
import 'package:dmrtd/extensions.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'photo.dart' as photo;
import "package:http/http.dart" as http;

Map dictTr ={};

class MrtdData {
  EfCardAccess? cardAccess;
  EfCardSecurity? cardSecurity;
  EfCOM? com;
  EfSOD? sod;
  EfDG1? dg1;
  EfDG2? dg2;
  EfDG3? dg3;
  EfDG4? dg4;
  EfDG5? dg5;
  EfDG6? dg6;
  EfDG7? dg7;
  EfDG8? dg8;
  EfDG9? dg9;
  EfDG10? dg10;
  EfDG11? dg11;
  EfDG12? dg12;
  EfDG13? dg13;
  EfDG14? dg14;
  EfDG15? dg15;
  EfDG16? dg16;
  Uint8List? aaSig;
}

final Map<DgTag, String> dgTagToString = {
  EfDG1.TAG: 'EF.DG1',
  EfDG2.TAG: 'EF.DG2',
  EfDG3.TAG: 'EF.DG3',
  EfDG4.TAG: 'EF.DG4',
  EfDG5.TAG: 'EF.DG5',
  EfDG6.TAG: 'EF.DG6',
  EfDG7.TAG: 'EF.DG7',
  EfDG8.TAG: 'EF.DG8',
  EfDG9.TAG: 'EF.DG9',
  EfDG10.TAG: 'EF.DG10',
  EfDG11.TAG: 'EF.DG11',
  EfDG12.TAG: 'EF.DG12',
  EfDG13.TAG: 'EF.DG13',
  EfDG14.TAG: 'EF.DG14',
  EfDG15.TAG: 'EF.DG15',
  EfDG16.TAG: 'EF.DG16'
};

String formatEfCom(final EfCOM efCom) {
  var str = "version: ${efCom.version}\n"
      "unicode version: ${efCom.unicodeVersion}\n"
      "DG tags:";

  for (final t in efCom.dgTags) {
    try {
      str += " ${dgTagToString[t]!}";
    } catch (e) {
      str += " 0x${t.value.toRadixString(16)}";
    }
  }
  return str;
}

String formatMRZ(final MRZ mrz) {
  return "MRZ\n"
          "  version: ${mrz.version}\n" +
      "  doc code: ${mrz.documentCode}\n" +
      "  doc No.: ${mrz.documentNumber}\n" +
      "  country: ${mrz.country}\n" +
      "  nationality: ${mrz.nationality}\n" +
      "  name: ${mrz.firstName}\n" +
      "  surname: ${mrz.lastName}\n" +
      "  gender: ${mrz.gender}\n" +
      "  date of birth: ${DateFormat.yMd().format(mrz.dateOfBirth)}\n" +
      "  date of expiry: ${DateFormat.yMd().format(mrz.dateOfExpiry)}\n" +
      "  add. data: ${mrz.optionalData}\n" +
      "  add. data: ${mrz.optionalData2}";
}

String formatProgressMsg(String message, int percentProgress) {
  final p = (percentProgress / 20).round();
  final full = "🟢 " * p;
  final empty = "⚪️ " * (5 - p);
  return message + "\n\n" + full + empty;
}

class MrtdHomePage extends StatefulWidget {
  final Map dict; 
  const MrtdHomePage({Key? key, required this.dict}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MrtdHomePageState createState() => _MrtdHomePageState();
}

class _MrtdHomePageState extends State<MrtdHomePage> {
  bool read = false;
  var _alertMessage = "";
  final _log = Logger("mrtdeg.app");
  var _isNfcAvailable = false;
  var _isReading = false;
  final _mrzData = GlobalKey<FormState>();
  
  MrtdData? _mrtdData;

  final NfcProvider _nfc = NfcProvider();
  late Timer _timerStateUpdater;
  final _scrollController = ScrollController();


  
  requestSend(dict) async {
    String id = global.process_id;
    final url=global.url+"process/$id/identity";
    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(dict),
    );
    return response.statusCode;
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    _initPlatformState();

    _timerStateUpdater = Timer.periodic(const Duration(seconds: 3), (Timer t) {
      _initPlatformState();
    });
  }


  Future<void> _initPlatformState() async {
    bool isNfcAvailable;
    try {
      NfcStatus status = await NfcProvider.nfcStatus;
      isNfcAvailable = status == NfcStatus.enabled;
    } on PlatformException {
      isNfcAvailable = false;
    }

    if (!mounted) return;

    setState(() {
      _isNfcAvailable = isNfcAvailable;
    });
  }

  void _readMRTD() async {
    
    try {
      setState(() {
        _mrtdData = null;
        _alertMessage = "Waiting for Passport tag ...";
        _isReading = true;
      });

      await _nfc.connect();

      final passport = Passport(_nfc);

      setState(() {
        _alertMessage = "Reading Passport ...";
      });

      _nfc.setIosAlertMessage("Trying to read EF.CardAccess ...");
      final mrtdData = MrtdData();


      _nfc.setIosAlertMessage("Initiating session ...");

      final bacKeySeed = DBAKeys(
        widget.dict['documentNumber'],
        DateFormat.yMd().parse(widget.dict['birthdate']),
        DateFormat.yMd().parse(widget.dict['expiryDate']),
      );
      await passport.startSession(bacKeySeed);

      _nfc.setIosAlertMessage(formatProgressMsg("Reading EF.COM ...", 0));
      mrtdData.com = await passport.readEfCOM();

      _nfc.setIosAlertMessage(formatProgressMsg("Reading Data Groups ...", 20));

      if (mrtdData.com!.dgTags.contains(EfDG1.TAG)) {
        mrtdData.dg1 = await passport.readEfDG1();
      }

      if (mrtdData.com!.dgTags.contains(EfDG2.TAG)) {
        mrtdData.dg2 = await passport.readEfDG2();
      }

      if (mrtdData.com!.dgTags.contains(EfDG11.TAG)) {
        mrtdData.dg11 = await passport.readEfDG11();
        var aa = mrtdData.dg11;
        print(aa);
      }

      setState(() {
        _mrtdData = mrtdData;
        _alertMessage = "";
      });
    } on Exception catch (e) {
      final se = e.toString().toLowerCase();
      String alertMsg = "An error has occurred while reading Passport!";
      if (e is PassportError) {
        if (se.contains("security status not satisfied")) {
          alertMsg = "Failed to initiate session with passport.\nTry Again!";
        }
        _log.error("PassportError: ${e.message}");
      } else {
        _log.error(
            "An exception was encountered while trying to read Passport: $e");
      }

      if (se.contains('timeout')) {
        alertMsg = "Timeout while waiting for Passport tag";
      } else if (se.contains("tag was lost")) {
        alertMsg = "Tag was lost. Please try again!";
      } else if (se.contains("invalidated by user")) {
        alertMsg = "";
      }

      setState(() {
        _alertMessage = alertMsg;
      });
    } finally {
      if (_alertMessage.isNotEmpty) {
        await _nfc.disconnect(iosErrorMessage: _alertMessage);
      } else {
        await _nfc.disconnect(
            iosAlertMessage: formatProgressMsg("Finished", 100));
      }
      setState(() {
        _isReading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("read nfc id")),
        body:
            FutureBuilder(builder: (context, snapshot) => _buildPage(context)));
            
  }

  Widget _makeMrtdDataWidget(
      {required String header,
      required String collapsedText,
      required dataText}) {
    return ExpandablePanel(
        theme: const ExpandableThemeData(
          headerAlignment: ExpandablePanelHeaderAlignment.center,
          tapBodyToCollapse: true,
          hasIcon: true,
          iconColor: Colors.red,
        ),
        header: Text(header),
        collapsed: Text(collapsedText,
            softWrap: true, maxLines: 2, overflow: TextOverflow.ellipsis),
        expanded: Container(
            padding: const EdgeInsets.all(18),
            color: const Color.fromARGB(255, 239, 239, 239),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    child: const Text('Copy'),
                    style:
                        TextButton.styleFrom(padding: const EdgeInsets.all(5)),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: dataText)),
                  ),
                  
                  SelectableText(dataText, textAlign: TextAlign.left)
                ])));
  }

  List<Widget> _mrtdDataWidgets() {
    List<Widget> list = [];
    if (_mrtdData == null) return list;

    if (_mrtdData!.cardAccess != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.CardAccess',
          collapsedText: '',
          dataText: _mrtdData!.cardAccess!.toBytes().hex()));
    }

    if (_mrtdData!.cardSecurity != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.CardSecurity',
          collapsedText: '',
          dataText: _mrtdData!.cardSecurity!.toBytes().hex()));
    }

    if (_mrtdData!.sod != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.SOD',
          collapsedText: '',
          dataText: _mrtdData!.sod!.toBytes().hex()));
    }

    if (_mrtdData!.com != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.COM',
          collapsedText: '',
          dataText: formatEfCom(_mrtdData!.com!)));
    }
//bilgiler
    if (_mrtdData!.dg1 != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.DG1',
          collapsedText: '',
          dataText: formatMRZ(_mrtdData!.dg1!.mrz)));
    }
//resim
    if (_mrtdData!.dg2 != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.DG2',
          collapsedText: '',
          dataText: _mrtdData!.dg2!.toBytes().hex()));

      String dataHex = _mrtdData!.dg2!.toBytes().hex();
      String dataHex2 ="";
      if(dataHex.indexOf("5f2e") > -1 ){
        int index = dataHex.indexOf("5f2e");
        dataHex2 = dataHex.substring(index+102);
      }
      else if(dataHex.indexOf("7f2e") > -1){
        int index = dataHex.indexOf("5f2e");
        dataHex2 = dataHex.substring(index+102);
      }
      var encoded = hex.decode(dataHex2);
      String base64string = base64Encode(encoded);
      widget.dict["bio_image"] = base64string;
      dictTr = widget.dict;
      read = true;
    }

//türkçe karakter
    if (_mrtdData!.dg11 != null) {
      list.add(_makeMrtdDataWidget(
          header: 'EF.DG11',
          collapsedText: '',
          dataText: _mrtdData!.dg11!.toBytes().hex())); 
          int surnameLastIndex = _mrtdData!.dg11!.toBytes().hex().substring(30).indexOf("3c3c") + 30;
          dictTr["surnames"] = utf8.decode(Uint8List.fromList(HEX.decode(_mrtdData!.dg11!.toBytes().hex().substring(30, surnameLastIndex))));       
          int nameFirstIndex = surnameLastIndex+4;
          int nameLastIndex = _mrtdData!.dg11!.toBytes().hex().substring(nameFirstIndex).indexOf("5f") + nameFirstIndex;
          if(_mrtdData!.dg11!.toBytes().hex().substring(nameFirstIndex, nameLastIndex).contains("3c")){
            Uint8List bytes = Uint8List.fromList(HEX.decode(_mrtdData!.dg11!.toBytes().hex().substring(nameFirstIndex, nameLastIndex).replaceFirst("3c", "20")));
            dictTr["givenNames"] = utf8.decode(bytes);
          }
          else{
            Uint8List bytes = Uint8List.fromList(HEX.decode(_mrtdData!.dg11!.toBytes().hex().substring(nameFirstIndex,nameLastIndex)));
            dictTr["givenNames"] = utf8.decode(bytes);
          }
          
    }

    return list;
  }

  Widget _buildPage(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const SizedBox(height: 20),
          Row(children: <Widget>[
            const Text('NFC available:',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text(_isNfcAvailable ? "Yes" : "No",
                style: const TextStyle(fontSize: 18.0))
          ]),
          const SizedBox(height: 40),
          const SizedBox(height: 20),
          TextButton(
            // btn Read MRTD
            onPressed: _readMRTD,
            child: Text(_isReading ? 'Reading ...' : 'Read Passport'),
          ),
          const SizedBox(height: 4),
          Text(_alertMessage,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_mrtdData != null ? "Passport Data:" : "",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.bold)),
                Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, top: 8.0, bottom: 8.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _mrtdDataWidgets())),
                        if(read)
                        TextButton(
                            // btn Read MRTD
                            onPressed: (){
                              requestSend(widget.dict);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) =>
                                    const photo.HomePage())),
                                    (root) => false
                              );   
                            },
                            child: Text("Next"),
                          )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
