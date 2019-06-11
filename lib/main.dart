import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vc_deca_flutter/screens/auth/auth_checker.dart';
import 'package:vc_deca_flutter/screens/auth/login_page.dart';
import 'package:vc_deca_flutter/screens/auth/register_page.dart';
import 'package:vc_deca_flutter/screens/chat/global_chat_page.dart';
import 'package:vc_deca_flutter/screens/settings/about_page.dart';
import 'package:vc_deca_flutter/screens/startup/network_cheker.dart';
import 'package:vc_deca_flutter/screens/startup/onboarding_page.dart';
import 'package:vc_deca_flutter/utils/config.dart';
import 'user_info.dart';
import 'package:fluro/fluro.dart';
import 'package:vc_deca_flutter/tab_bar_controller.dart';
import 'package:vc_deca_flutter/utils/theme.dart';

void main() {
  // STARTUP ROUTES
  router.define('/check-connection', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new NetworkChecker();
  }));
  router.define('/onboarding', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new OnboardingPage();
  }));

  // AUTH ROUTES
  router.define('/check-auth', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new AuthChecker();
  }));
  router.define('/register', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new RegisterPage();
  }));
  router.define('/login', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new LoginPage();
  }));

  // HOME ROUTES
  router.define('/home', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new TabBarController();
  }));

  // CONFERENCE ROUTES

  // EVENT ROUTES

  // CHAT ROUTES
  router.define('/chat/global', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new GlobalChatPage();
  }));
  // SETTINGS ROUTES
  router.define('/settings/about', handler: new Handler(handlerFunc: (BuildContext context, Map<String, dynamic> params) {
    return new AboutPage();
  }));

  runApp(new MaterialApp(
    title: "VC DECA",
    home: NetworkChecker(),
    onGenerateRoute: router.generator,
    debugShowCheckedModeBanner: false,
    theme: mainTheme,
  ));
}