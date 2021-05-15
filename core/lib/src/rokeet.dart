import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rokeet_ui/src/constants.dart';
import 'package:rokeet_ui/src/model.dart';
import 'errors.dart';
import 'registry.dart';
import 'network/network.dart';
import 'actions/actions.dart';
import 'pages/page.dart';
import 'widgets/widgets.dart';

class RokeetConfig {
  RokeetConfig(
      {this.clientId,
      this.clientSecret,
      this.widgetBuilders,
      this.actionPerformers});

  final String? clientId;
  final String? clientSecret;
  final Map<String, RWidgetBuilder>? widgetBuilders;
  final Map<String, RActionPerformer>? actionPerformers;
}

class Rokeet {
  static final Rokeet _instance = Rokeet._internal();

  factory Rokeet() {
    return _instance;
  }

  Rokeet._internal()
      : api = RokeetApiBuilder(baseUrl)
            .addInterceptor(
                LogInterceptor(requestBody: true, responseBody: true))
            .build();

  RokeetConfig? _config;
  @visibleForTesting
  RokeetApi? api;

  @visibleForTesting
  final Registry<RWidgetBuilder> widgetBuilderRegistry =
      WidgetBuilderRegistry();
  @visibleForTesting
  final Registry<RActionPerformer> actionPerformerRegistry =
      ActionPerformerRegistry();

  late RState currentState;
  late BuildContext currentContext;

  bool get isLoading {
    if (api == null) {
      return true;
    }

    return api!.isLoading;
  }

  void _configure(RokeetConfig config) {
    _config = config;
    config.widgetBuilders?.entries
        .forEach((e) => _registerWidgetBuilder(e.key, e.value));
    config.actionPerformers?.entries
        .forEach((e) => _registerActionPerformer(e.key, e.value));
  }

  void _registerWidgetBuilder(String key, RWidgetBuilder builder) {
    widgetBuilderRegistry.register(key, builder);
  }

  void _registerActionPerformer(String key, RActionPerformer performer) {
    actionPerformerRegistry.register(key, performer);
  }

  static Future<AppConfig?> init(
      RokeetConfig config, RState initState, BuildContext context) async {
    var rokeet = Rokeet();
    rokeet.currentState = initState;
    rokeet.currentContext = context;
    rokeet._configure(config);
    return rokeet._init();
  }

  Future<AppConfig?> _init() async {
    return await api?.getApp(_config!.clientId!, _config!.clientSecret!);
  }

  void getStep(String id) async {
    var data = await api?.getStep(id);
    currentState.onDataLoaded(data);
  }

  void performAction(RAction action) {
    var type = action.type;

    if (type == null) {
      throw IllegalStateError("Action type must not be null");
    }

    RActionPerformer? possiblePerformer = actionPerformerRegistry.get(type);
    if (possiblePerformer == null) {
      log('Performer for $type not found');
      return;
    }

    possiblePerformer.performAction(this, action);
  }

  Widget? buildWidget(RWidget widget) {
    var uiType = widget.uiType;
    if (uiType == null) {
      throw IllegalStateError("Widget uiType must not be null");
    }
    RWidgetBuilder? builder = widgetBuilderRegistry.get(uiType);

    if (builder == null) {
      log('Builder for $uiType not found');
      return null;
    }
    return builder.build(this, widget);
  }
}
