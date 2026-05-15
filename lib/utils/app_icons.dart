import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Centralized icon registry. All icons in the app must come from here.
/// Never use Icons. or CupertinoIcons. directly.
abstract class AppIcons {
  // ─── Status ─────────────────────────────────────────────────────────────
  static const checkpointOpen = PhosphorIconsFill.checkCircle;
  static const checkpointCrowded = PhosphorIconsFill.warning;
  static const checkpointClosed = PhosphorIconsFill.prohibit;

  // ─── Navigation & Location ──────────────────────────────────────────────
  static const location = PhosphorIconsBold.mapPin;
  static const place = PhosphorIconsRegular.mapPinLine;
  static const gpsFixed = PhosphorIconsBold.crosshairSimple;
  static const myLocation = PhosphorIconsFill.navigationArrow;
  static const locationSearching = PhosphorIconsRegular.crosshairSimple;
  static const addLocation = PhosphorIconsBold.mapPinPlus;
  static const globe = PhosphorIconsRegular.globe;

  // ─── Arrows & Direction ─────────────────────────────────────────────────
  static const arrowForward = PhosphorIconsBold.arrowRight;
  static const arrowBack = PhosphorIconsBold.arrowLeft;
  static const arrowForwardIos = PhosphorIconsBold.caretRight;
  static const arrowBackIos = PhosphorIconsBold.caretLeft;
  static const caretDown = PhosphorIconsBold.caretDown;
  static const caretUp = PhosphorIconsBold.caretUp;
  static const backNav = PhosphorIconsBold.arrowLeft;

  // ─── Actions ────────────────────────────────────────────────────────────
  static const refresh = PhosphorIconsBold.arrowsClockwise;
  static const close = PhosphorIconsBold.x;
  static const clear = PhosphorIconsRegular.x;
  static const check = PhosphorIconsBold.check;
  static const send = PhosphorIconsFill.paperPlaneTilt;
  static const delete = PhosphorIconsRegular.trash;
  static const filter = PhosphorIconsFill.funnel;
  static const logout = PhosphorIconsBold.signOut;

  // ─── Voting ─────────────────────────────────────────────────────────────
  static const vote = PhosphorIconsFill.handFist;
  static const voteOutlined = PhosphorIconsRegular.handFist;

  // ─── App Sections ───────────────────────────────────────────────────────
  static const map = PhosphorIconsFill.mapTrifold;
  static const list = PhosphorIconsBold.listBullets;
  static const settings = PhosphorIconsBold.gear;

  // ─── Info & Feedback ────────────────────────────────────────────────────
  static const info = PhosphorIconsRegular.info;
  static const error = PhosphorIconsRegular.warningCircle;
  static const notification = PhosphorIconsFill.bell;
  static const comment = PhosphorIconsRegular.chatText;
  static const clock = PhosphorIconsRegular.clock;

  // ─── Connectivity ───────────────────────────────────────────────────────
  static const cloudOff = PhosphorIconsRegular.cloudSlash;
  static const wifiOff = PhosphorIconsBold.wifiSlash;

  // ─── Theme ──────────────────────────────────────────────────────────────
  static const themeSolar = PhosphorIconsRegular.sunHorizon;
  static const themeSystem = PhosphorIconsRegular.circleHalf;
  static const themeLight = PhosphorIconsFill.sun;
  static const themeDark = PhosphorIconsFill.moon;
  static const sunOutlined = PhosphorIconsRegular.sun;
}
