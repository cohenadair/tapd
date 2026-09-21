import 'package:flutter/material.dart';
import 'package:mobile/tapd_game.dart';
import 'package:mobile/overlays/continue_countdown.dart';
import 'package:mobile/overlays/continue_offer.dart';
import 'package:mobile/overlays/instructions.dart';
import 'package:mobile/overlays/menu.dart';
import 'package:mobile/overlays/scoreboard.dart';

const overlayIdMainMenu = "main_menu";
const overlayIdGameOver = "game_over";
const overlayIdScoreboard = "scoreboard";
const overlayIdInstructions = "instructions";
const overlayIdContinueOffer = "continue_offer";
const overlayIdContinueCountdown = "continue_countdown";

Widget buildMainMenu(BuildContext context, TapdGame game) => Menu.main(game);

Widget buildGameOver(BuildContext context, TapdGame game) =>
    Menu.gameOver(game);

Widget buildScoreboard(BuildContext context, TapdGame game) => Scoreboard(game);

Widget buildInstructions(BuildContext context, TapdGame game) =>
    Instructions(game);

Widget buildContinueOffer(BuildContext context, TapdGame game) =>
    ContinueOffer(game);

Widget buildContinueCountdown(BuildContext context, TapdGame game) =>
    ContinueCountdown(game.world.continueSecondsLeft);
