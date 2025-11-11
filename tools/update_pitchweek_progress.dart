import 'dart:io';

void main(List<String> args) {
  final message = _parseArg(args, '--message') ?? '';
  if (message.isEmpty) {
    stderr.writeln('No commit message provided. Skipping.');
    exit(0);
  }

  final file = File('docs/pitchweek.md');
  if (!file.existsSync()) {
    stderr.writeln('docs/pitchweek.md not found. Skipping.');
    exit(0);
  }

  final content = file.readAsStringSync();
  final updated = _updateProgress(content, message);
  if (updated != null) {
    file.writeAsStringSync(updated);
    stdout.writeln('PitchWeek board updated for commit.');
  } else {
    stdout.writeln('No matching phase tag found in commit. No changes made.');
  }
}

String? _parseArg(List<String> args, String key) {
  final i = args.indexOf(key);
  if (i >= 0 && i + 1 < args.length) {
    return args[i + 1];
  }
  return null;
}

String? _updateProgress(String md, String commitMessage) {
  final msg = commitMessage.toLowerCase();

  final mappings = <String, String>{
    'feat(brand)': '1 Identity & Stability',
    'feat(flow)': '2 Flow of Trust',
    'feat(data)': '3 Data Comes Alive',
    'feat(order)': '4 Order & Admin',
    'chore(qa)': '5 Investor Polish',
    'release(pitch-build)': '6 Demo Armour',
    'release/pitch-v1': '7 Predatory Demo',
  };

  String? phaseName;
  for (final entry in mappings.entries) {
    if (msg.contains(entry.key)) {
      phaseName = entry.value;
      break;
    }
  }

  if (phaseName == null) return null;

  final lines = md.split('\n');
  bool progressChanged = false;

  // Update progress table row for the detected phase: change Done from ☐ to ✅
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    if (line.trimLeft().startsWith('|') && line.contains(phaseName)) {
      // Replace the Done column only (first ☐ in the row)
      final idx = line.indexOf('☐');
      if (idx != -1) {
        final newLine = line.replaceFirst(
          '☐',
          '✅',
        ); // mark Done for the phase row
        lines[i] = newLine;
        progressChanged = true;
        break;
      }
    }
  }

  // Add a quick entry to Nightly CEO Log
  final header = '## 🧩 Nightly CEO Log';
  final headerIdx = lines.indexWhere((l) => l.trim() == header);
  if (headerIdx != -1) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '- $timestamp — ${commitMessage.trim()}';
    // Insert right after the header (or after the next blank line if present)
    final insertAt = headerIdx + 1;
    lines.insert(insertAt, '');
    lines.insert(insertAt + 1, entry);
  }

  if (!progressChanged) {
    // Still return updated CEO log if we added it
    if (headerIdx != -1) {
      return lines.join('\n');
    }
    return null;
  }

  return lines.join('\n');
}
