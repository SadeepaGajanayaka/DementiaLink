import 'dart:async';

import 'package:dementialink/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_speech/flutter_speech.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:permission_handler/permission_handler.dart';

// Define the AppLanguage enum
enum AppLanguage { english, sinhala }

// Define the Message class
@immutable
class Message {
  final String id;
  final String message;
  final DateTime createdAt;
  final bool isMine;

  const Message({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.isMine,
  });

  String get formattedMessage => message.formatBoldText();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isMine': isMine,
    };
  }