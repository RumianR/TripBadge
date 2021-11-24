import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

/// This widget is the home page of the application.
class MyHomePage extends StatefulWidget {
  /// Initialize the instance of the [MyHomePage] class.
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState();

  late List<Model> _data;
  late MapShapeSource _mapSource;

  @override
  void initState() {
    _data = const <Model>[
      Model("North America", Colors.pinkAccent),
      Model("South America", Colors.deepPurpleAccent),
      Model("Europe", Colors.deepPurpleAccent),
      Model("Asia", Colors.deepPurpleAccent),
      Model("Africa", Colors.deepPurpleAccent),
      Model("Antarctica", Colors.deepPurpleAccent),
      Model("Oceania", Colors.deepPurpleAccent)
    ];

    _mapSource = MapShapeSource.asset(
      'assets/geojsons/custom.json',
      shapeDataField: 'continent',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].continent,
      dataLabelMapper: (int index) => _data[index].continent,
      shapeColorValueMapper: (int index) => _data[index].color,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(left: 15, right: 15),
        child: Container(
          height: 300,
          child: Center(
            child: SfMaps(
              layers: <MapShapeLayer>[
                MapShapeLayer(
                  source: _mapSource,
                  loadingBuilder: (context) => CircularProgressIndicator(),
                  showDataLabels: true,
                  dataLabelSettings: MapDataLabelSettings(
                      textStyle: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 17)),
                ),
              ],
            ),
          ),
        ));
  }
}

class Model {
  const Model(this.continent, this.color);

  final String continent;
  final Color color;
}
