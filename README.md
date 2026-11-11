# NodeQL Workshop Admin

Desktop-App zum Erstellen, Testen und Teilen interaktiver SQLite-Workshops mit
[NodeQL](https://github.com/Kartoffelspalt/NodeQL).

- [Release-Seite mit Downloads und Unterrichtsmaterial](https://kartoffelspalt.github.io/NodeQL-Workshop-Admin/)
- [Alle GitHub Releases](https://github.com/Kartoffelspalt/NodeQL-Workshop-Admin/releases)
- [Anleitung für Lehrkräfte](dist/materialien/NodeQL-Workshops-erstellen.pdf)
- [Unterrichtsmaterial zum Projizieren und Ausdrucken](dist/materialien/NodeQL-Unterrichtsmaterial.pdf)

## Lokal bauen

Der Workshop Admin verwendet NodeQL als Flutter-Paket. Die Datei
`nodeql-revision` hält den vollständigen Commit für reproduzierbare Builds fest.
Das Setup holt ihn in das lokale Verzeichnis `.nodeql`.

```sh
bash tool/bootstrap-nodeql.sh
flutter pub get
flutter test
flutter run -d macos
```

Für Windows und Linux entsprechend `flutter run -d windows` oder
`flutter run -d linux` verwenden. Die Release-Workflowdatei legt Flutter-Version
und Plattformabhängigkeiten fest.

## Release vorbereiten

1. Die Version in `pubspec.yaml` pflegen und den Stand auf `main` bringen.
2. Unter **Actions → Workshop Admin → Run workflow** die Option
   `create_release_draft` aktivieren. Der Workflow testet und baut macOS,
   Windows und Linux und legt die Pakete mit `SHA256SUMS.txt` in einem
   gemeinsamen Release-Entwurf ab.
3. Versionshinweise und Pakete im Entwurf prüfen und den Release auf GitHub
   veröffentlichen. Die Release-Seite aktualisiert ihre Downloadlinks und den
   Versionsverlauf beim Veröffentlichungsereignis.

Die Release-Seite wird über GitHub Pages bereitgestellt. Unter **Settings →
Pages → Build and deployment** ist **GitHub Actions** als Quelle eingestellt.
Für eine lokale Vorschau genügt `python3 -m http.server --bind 127.0.0.1 --directory dist 8765`.
