import 'package:flutter/material.dart';

AppBar header1(context,
    {bool isAppTitle = false,
    String titleText = "",
    removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? "Trip Badge" : titleText,
      style: TextStyle(
          color: Colors.white,
          fontFamily: isAppTitle ? "Signatra" : "",
          fontSize: isAppTitle ? 50.0 : 22.0),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).colorScheme.secondary,
  );
}

AppBar header2(context, {String titleText = ""}) {
  return AppBar(
      centerTitle: false,
      title: Text(
        titleText,
        style: TextStyle(
            fontFamily: 'Helvetica', color: Colors.black, fontSize: 22),
      ),
      backgroundColor: Colors.white,
      elevation: 0);
}
