import 'dart:io';

void main(List<String> args) {
  final roots = <Directory>[Directory('lib'), Directory('test')];

  final regex = RegExp(r'withOpacity\(([^)]+)\)');
  int changedFiles = 0;

  for (final root in roots) {
    if (!root.existsSync()) continue;
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final content = entity.readAsStringSync();
      if (!content.contains('withOpacity(')) continue;

      final updated = content.replaceAllMapped(
        regex,
        (m) => 'withValues(alpha: ${m.group(1)})',
      );

      if (updated != content) {
        entity.writeAsStringSync(updated);
        changedFiles++;
        stdout.writeln('Updated: ${entity.path}');
      }
    }
  }

  stdout.writeln('Done. Changed files: $changedFiles');
}
