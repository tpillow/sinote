import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String TITLE_LIST_KEY = "#titles#!@#&%^*()";

class NoteData {
  String title;
  bool hasPasswordSet;
  List<String> notes;

  NoteData(this.title, this.hasPasswordSet, {this.notes}) {
    if (notes == null) notes = List<String>();
  }

  @override
  String toString() => notes.join("\n");
}

class DataManager {
  static DataManager instance = DataManager._();

  Future<SharedPreferences> get _prefs {
    return SharedPreferences.getInstance();
  }

  DataManager._();

  Future<NoteData> createNoteData(String title) async {
    if (await hasNoteData(title))
      throw Exception("Note data $title already exists.");
    final NoteData data = NoteData(title, false);
    final SharedPreferences prefs = await _prefs;
    final List<String> allTitles =
        prefs.getStringList(TITLE_LIST_KEY) ?? List<String>();
    allTitles.add(title);
    await prefs.setStringList(TITLE_LIST_KEY, allTitles);
    return data;
  }

  Future<void> deleteNoteData(String title) async {
    if (!await hasNoteData(title))
      throw Exception("Note data $title does not exist.");
    final SharedPreferences prefs = await _prefs;
    await prefs.remove(title);
    await setPassword(title, null);
    final List<String> allTitles =
        prefs.getStringList(TITLE_LIST_KEY) ?? List<String>();
    allTitles.remove(title);
    await prefs.setStringList(TITLE_LIST_KEY, allTitles);
  }

  Future<void> renameNoteData(String oldTitle, String newTitle) async {
    if (!await hasNoteData(oldTitle))
      throw Exception("Note data $oldTitle does not exist.");
    if (await hasNoteData(newTitle))
      throw Exception("Note data $newTitle already exists.");

    final NoteData data = await getNoteData(oldTitle, shallow: false);
    if (await hasPasswordSet(oldTitle)) {
      String oldPass = await getPasswordRaw(oldTitle);
      await setPassword(oldTitle, null);
      await setPassword(newTitle, oldPass, setRaw: true);
    }
    await deleteNoteData(oldTitle);
    await createNoteData(newTitle);
    data.title = newTitle;
    await saveNoteData(data);
  }

  Future<void> saveNoteData(NoteData data) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setStringList(data.title, data.notes);
  }

  Future<NoteData> getNoteData(String title, {bool shallow = true}) async {
    if (!await hasNoteData(title))
      throw Exception("Note data $title does not exist.");
    if (shallow) return NoteData(title, await hasPasswordSet(title));

    final SharedPreferences prefs = await _prefs;
    return NoteData(title, await hasPasswordSet(title),
        notes: prefs.getStringList(title) ?? List<String>());
  }

  Future<List<NoteData>> getAllNoteData({bool shallow = true}) async {
    final SharedPreferences prefs = await _prefs;
    List<String> allTitles =
        prefs.getStringList(TITLE_LIST_KEY) ?? List<String>();
    List<NoteData> ret = List<NoteData>();
    for (String title in allTitles)
      ret.add(await getNoteData(title, shallow: shallow));
    return ret;
  }

  Future<bool> hasNoteData(String title) async {
    final SharedPreferences prefs = await _prefs;
    List<String> allTitles =
        prefs.getStringList(TITLE_LIST_KEY) ?? List<String>();
    return allTitles.contains(title);
  }

  /*
    NOTE: THIS IS NOT MEANT TO BE A SECURE PASSWORD
    THE PASSWORD FEATURE IS ONLY USED TO DETER SIMPLE ATTACKS
  */
  Future<void> setPassword(String title, String password,
      {bool setRaw = false}) async {
    final SharedPreferences prefs = await _prefs;
    if (password == null) setRaw = true;
    await prefs.setString("$title\0password\0",
        (setRaw ? password : sha1.convert(utf8.encode(password)).toString()));
  }

  /*
    NOTE: THIS IS NOT MEANT TO BE A SECURE PASSWORD
    THE PASSWORD FEATURE IS ONLY USED TO DETER SIMPLE ATTACKS
  */
  Future<bool> hasPasswordSet(String title) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.containsKey("$title\0password\0");
  }

  /*
    NOTE: THIS IS NOT MEANT TO BE A SECURE PASSWORD
    THE PASSWORD FEATURE IS ONLY USED TO DETER SIMPLE ATTACKS
  */
  Future<String> getPasswordRaw(String title) async {
    final SharedPreferences prefs = await _prefs;
    return prefs.getString("$title\0password\0");
  }

  /*
    NOTE: THIS IS NOT MEANT TO BE A SECURE PASSWORD
    THE PASSWORD FEATURE IS ONLY USED TO DETER SIMPLE ATTACKS
  */
  Future<bool> validatePassword(String title, String password) async {
    return sha1.convert(utf8.encode(password)).toString() ==
        await getPasswordRaw(title);
  }
}
