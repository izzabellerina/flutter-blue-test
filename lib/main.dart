import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_blue/flutter_blue.dart' as prefix0;
import 'package:hex/hex.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter Demo Home Page'),
        routes: {('next_page'): (context) => next_page()});
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  FlutterBlue flutterBlue;

  BluetoothDevice devices;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, listResult) => Column(
                        children: listResult.data
                            .map((result) => Card(
                                  child: ListTile(
                                    title: checkName(result),
                                    onTap: () {
                                      onTap(result);
                                    },
                                    subtitle:
                                        StreamBuilder<BluetoothDeviceState>(
                                      stream: result.device.state,
                                      initialData:
                                          BluetoothDeviceState.connecting,
                                      builder: (c, state) {
                                        String text;
                                        switch (state.data) {
                                          case BluetoothDeviceState.connected:
                                            text = 'CONNECT';
                                            break;
                                          case BluetoothDeviceState
                                              .disconnected:
                                            text = 'DISCONNECT';
                                            break;
                                          default:
                                            text = state.data
                                                .toString()
                                                .substring(21)
                                                .toUpperCase();
                                            break;
                                        }
                                        return Text(text);
                                      },
                                    ),
                                    trailing: Icon(
                                      Icons.bluetooth_connected,
                                      color: Colors.deepPurpleAccent,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ))
            ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          CreateTextData();
        },
        tooltip: 'Increment',
        backgroundColor: Colors.teal,
        child: Icon(Icons.bluetooth_searching),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void CreateTextData() {
    FlutterBlue.instance
        .startScan(timeout: Duration(seconds: 6), scanMode: ScanMode.balanced);
  }

  void onTap(ScanResult scanResult) {
    BluetoothDevice device = scanResult.device;
    device.connect();

    Stream<BluetoothDeviceState> service = device.state;
    service.listen((state) {
      if (state == BluetoothDeviceState.connected) {
        Future<List<BluetoothService>> service = device.discoverServices();
        service.then((listservice) {
          listservice.forEach((services) {
            print("SERVICES : " + services.uuid.toString());
          });
        });
        Navigator.pushNamed(context, 'next_page', arguments: device);
      }
    });

//    BluetoothDeviceState deviceState = device.;
  }

  Text checkName(ScanResult scanResult) {
    BluetoothDevice device = scanResult.device;
    String deviceName = device.name;
    if (deviceName.isEmpty) {
      return Text("No Device");
    } else {
      return Text(deviceName);
    }
  }
}

class next_page extends StatefulWidget {
  @override
  _next_pageState createState() => _next_pageState();
}

class _next_pageState extends State<next_page> {
  String serviceSPTK = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  String writeChar = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  String readNotif = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String descriptorChara = "00002902-0000-1000-8000-00805f9b34fb";
  BluetoothService servicesJA;
  BluetoothDevice device;
  StreamController<String> streamController = StreamController<String>
    ();
  @override
  Widget build(BuildContext context) {
    BluetoothDevice device = ModalRoute.of(context).settings.arguments;

    this.device = device;
    /*
Stream<List<BluetoothService>>streamService=device.services;
streamService.listen((listService){
  listService.forEach((service){
    if(service.uuid.toString().contains(serviceSPTK)){
      this.servicesJA=service;
      print("SERVICE JAAAAA : "+servicesJA.uuid.toString());
    }
  });
});

*/

    /*
    Future<List<BluetoothService>> services =  device.discoverServices();
    services.then((value)=>(){
      value.forEach((service)=>(){
        print("UUID SERVICES : "+service.uuid.toString());
       // if(service.uuid.toString().contains(serviceSPTK)){}
      });
    }).catchError((error)=>(){});
    services.whenComplete((){});
*/

    return Scaffold(
      appBar: AppBar(
        title: Text("Send And Recieve"),
        backgroundColor: Colors.deepPurpleAccent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            device.disconnect();
            Navigator.of(context).pop();
//          Navigator.push(context,MaterialPageRoute(builder: (context)=>MyHomePage()));
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              child: Card(
                child: ListTile(
                  title: Text("Device : " + device.name),
                  subtitle: Row(
                    children: <Widget>[
                      Text("UUID : " + device.id.id),
                      Text("     "),
                      StreamBuilder<BluetoothDeviceState>(
                        stream: device.state,
                        initialData: BluetoothDeviceState.connecting,
                        builder: (c, state) {
                          String text;
                          switch (state.data) {
                            case BluetoothDeviceState.connected:
                              text = 'CONNECT';
                              break;
                            case BluetoothDeviceState.disconnected:
                              text = 'DISCONNECT';
                              break;
                            default:
                              text = state.data
                                  .toString()
                                  .substring(21)
                                  .toUpperCase();
                              break;
                          }
                          return Text("STATUS : " + text);
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Container(
                child: Center(
                    child: StreamBuilder(
                  stream: streamController.stream,
                  initialData: "0.0",
                  builder: (c, text) {
                    textReciev(device);
                    return Text(text.data,
                        style:
                            TextStyle(fontSize: 125, color: Colors.deepPurple));
                  },
                )),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ButtonTheme(
                    child: RaisedButton(
                      onPressed: () => onBlankClicked(device),
                      child: Text(
                        "Blank",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    minWidth: 95,
                    height: 55,
                    buttonColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  ButtonTheme(
                    child: RaisedButton(
                      onPressed: () => onMeasureClicked(device),
                      child: Text(
                        "Measure",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    minWidth: 95,
                    height: 55,
                    buttonColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  ButtonTheme(
                    child: RaisedButton(
                      onPressed: () {
                        onNextClicked(device);
                      },
                      child: Text(
                        "Next",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                    minWidth: 95,
                    height: 55,
                    buttonColor: Colors.deepPurpleAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  void textReciev(BluetoothDevice device) {
    if (device != null) {
      Future<List<BluetoothService>> fservice = device.discoverServices();
      List<BluetoothCharacteristic> listchar;
      List<BluetoothDescriptor> listDes;
      BluetoothDescriptor des;
      fservice.then((listService) {
        listService.forEach((services) {
          print("SERVICES NEXT PAGE : " + services.uuid.toString());
          if (services.uuid.toString() == serviceSPTK) {
            listchar = services.characteristics;
            listchar.forEach((charact) {
              print("CHARACTERISTIC : " + charact.uuid.toString());
              if (charact.uuid.toString() == writeChar) {
                //charact.setNotifyValue(true);
              }
              if (charact.uuid.toString() == readNotif) {
//              Future<List<int>> intReadNot = charact.read();

                listDes = charact.descriptors;
                listDes.forEach((desc) {
                  if (desc.uuid.toString() == descriptorChara) {
                    des = desc;
                    print("CHARACTERISTIC uuid : " + des.uuid.toString());

                    charact.setNotifyValue(true);
                    Stream<List<int>> dataRead = charact.value;
                    dataRead.listen((listint) {
                      String asci = ascii.decode(listint);

                      print("CHARACTERISTIC asci : " + asci);
                      List<String> spiltData = asci.split(",");
                      switch (spiltData.elementAt(0)) {
                        case "bla":
                          streamController.sink.add(spiltData.elementAt(1));
                          break;
                        case "mea":
                          streamController.sink.add(spiltData.elementAt(2));

                          break;
                        case "nex":
                          streamController.sink.add("--");
                          break;

                      }
                    });
                  }
                });
              }
            });
          }
        });
      });
    }
  }

  void onNextClicked(BluetoothDevice device) {
    writeDataBlue(device, "nex");
  }

  void onMeasureClicked(BluetoothDevice device) {
    writeDataBlue(device, "mea");
  }

  void onBlankClicked(BluetoothDevice device) {
    writeDataBlue(device, "bla");
  }

  void writeDataBlue(BluetoothDevice device, String data) {
    List<BluetoothCharacteristic> listwritechar;
    BluetoothCharacteristic writechar;

    if (device != null) {
      Future<List<BluetoothService>> fservice = device.discoverServices();
      fservice.then((listservices) {
        listservices.forEach((service) {
          if (service.uuid.toString().compareTo(serviceSPTK) == 0) {
            listwritechar = service.characteristics;
            listwritechar.forEach((char) {
              if (char.uuid.toString().compareTo(writeChar) == 0) {
                writechar = char;
                List<int> writedata = ascii.encode(data);
                writechar.write(writedata);
              }
            });
          }
        });
      });
    }
  }
}

class CallbackService {
  String data;

  String ReCallBackData() {
    return data;
  }

  void AddData(String data) => this.data = data;
}
