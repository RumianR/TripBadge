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
            fontFamily: 'Helvetica',
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0);
}

AppBar profileAppBar(context,
    {String username = "", removeBackButton = false}) {
  return AppBar(
    title: Text(username, style: TextStyle(color: Colors.black)),
    backgroundColor: Colors.transparent,
    automaticallyImplyLeading: removeBackButton ? false : true,
    elevation: 0,
    leading: removeBackButton
        ? Icon(Icons.person, color: Colors.black)
        : IconButton(
            icon: (Icon(Icons.arrow_back_ios_new, color: Colors.black)),
            onPressed: () => Navigator.pop(context),
          ),
  );
}
