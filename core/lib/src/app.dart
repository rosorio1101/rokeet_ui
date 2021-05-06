import 'package:flutter/material.dart';
import 'errors.dart';
import 'model.dart';
import 'pages/pages.dart';
import 'rokeet.dart';

class RokeetApp extends AbstractRokeetPage {
  RokeetApp({
    Key? key,
    this.title = '',
    this.config,
  }) : super(key: key);

  final String title;
  final RokeetConfig? config;

  @override
  _AppState createState() => _AppState();
}

class _AppState extends RState<RokeetApp, AppConfig> {
  @override
  initState() {
   super.initState();
   Rokeet.init(widget.config!, this, context);
  }

  Widget _getHome() {
    if (rokeet.isLoading || data == null) {
        return getLoadingWidget();
    } else {
      if(data!.initStep == null) {
        throw InitStepError();
      }
      return RokeetStepPage(stepId: data!.initStep!,);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      home: _getHome(),
      onGenerateRoute: (settings) {
        var uri = Uri.parse(settings.name!);
        if (uri.pathSegments.first == 'steps' && uri.queryParameters['id'] != null) {
          var stepId = uri.queryParameters['id']!;
          return MaterialPageRoute(
              builder: (context) => RokeetStepPage(
                stepId: stepId,
              ));
        }
        return MaterialPageRoute(builder: (context) => RokeetUnknownPage());
      },
    );
  }

  @override
  void onDataLoaded(AppConfig data) {
    setState(() {
      this.data = data;
    });
  }
}