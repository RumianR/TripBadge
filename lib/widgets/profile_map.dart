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
  late MapZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    _data = const <Model>[
      Model("North America", "NA", Colors.teal),
      Model("South America", "SA", Colors.red),
      Model("Europe", "EUR", Colors.pink),
      Model("Asia", "ASIA", Colors.lightGreen),
      Model("Africa", "AFRI", Colors.orange),
      Model("Australia", "AUS", Colors.yellow)
    ];

    _mapSource = MapShapeSource.asset(
      'assets/geojsons/continents.json',
      shapeDataField: 'CONTINENT',
      dataCount: _data.length,
      primaryValueMapper: (int index) => _data[index].continent,
      // dataLabelMapper: (int index) => _data[index].label,
      shapeColorValueMapper: (int index) => _data[index].color,
    );

    _zoomPanBehavior = MapZoomPanBehavior();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 5, right: 5),
      child: Center(
        child: SfMaps(
          layers: <MapShapeLayer>[
            MapShapeLayer(
              source: _mapSource,
              zoomPanBehavior: _zoomPanBehavior,
              loadingBuilder: (context) => CircularProgressIndicator(),
              showDataLabels: false,
              // dataLabelSettings: MapDataLabelSettings(
              //     textStyle: TextStyle(color: Colors.black, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class Model {
  const Model(this.continent, this.label, this.color);

  final String continent;
  final String label;
  final Color color;
}
