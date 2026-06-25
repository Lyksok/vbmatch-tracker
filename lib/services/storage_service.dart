import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/match_model.dart';

class StorageService {
  static const String _filePrefix = 'match_';
  static const String _fileExtension = '.json';

  // Get local directory path where we can write files
  Future<Directory> get _localDir async {
    return await getApplicationDocumentsDirectory();
  }

  // Get path for a specific match ID
  Future<File> _getFileForMatch(String matchId) async {
    final dir = await _localDir;
    return File('${dir.path}/$_filePrefix$matchId$_fileExtension');
  }

  // Save a match to a file
  Future<void> saveMatch(VolleyballMatch match) async {
    try {
      final file = await _getFileForMatch(match.id);
      final jsonStr = jsonEncode(match.toMap());
      await file.writeAsString(jsonStr);
    } catch (e) {
      print('Error saving match: $e');
    }
  }

  // Load a match by ID
  Future<VolleyballMatch?> loadMatch(String matchId) async {
    try {
      final file = await _getFileForMatch(matchId);
      if (await file.exists()) {
        final jsonStr = await file.readAsString();
        final map = jsonDecode(jsonStr);
        return VolleyballMatch.fromMap(map);
      }
    } catch (e) {
      print('Error loading match: $e');
    }
    return null;
  }

  // Delete a match by ID
  Future<void> deleteMatch(String matchId) async {
    try {
      final file = await _getFileForMatch(matchId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting match: $e');
    }
  }

  // List all matches saved on the device, sorted by date (newest first)
  Future<List<VolleyballMatch>> getAllMatches() async {
    final List<VolleyballMatch> matches = [];
    try {
      final dir = await _localDir;
      if (await dir.exists()) {
        final List<FileSystemEntity> entities = dir.listSync();
        for (var entity in entities) {
          if (entity is File) {
            final fileName = entity.path.split('/').last;
            if (fileName.startsWith(_filePrefix) && fileName.endsWith(_fileExtension)) {
              try {
                final jsonStr = await entity.readAsString();
                final map = jsonDecode(jsonStr);
                matches.add(VolleyballMatch.fromMap(map));
              } catch (e) {
                // If one file is corrupted, print error but continue loading other matches
                print('Error parsing match file ${entity.path}: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error listing matches: $e');
    }
    // Sort matches by date, newest first
    matches.sort((a, b) => b.date.compareTo(a.date));
    return matches;
  }
}
