import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nodeql/features/tutorial/learning_path_authoring.dart';
import 'package:nodeql/features/tutorial/learning_path_studio.dart';
import 'package:nodeql/features/tutorial/remote_workshop.dart';
import 'package:nodeql/features/tutorial/workshop_admin_extension.dart';
import 'package:nodeql/features/workbench/presentation/engine/sql_mode.dart';
import 'package:nodeql/features/workbench/presentation/engine/workspace_engine.dart';
import 'package:nodeql/localization/translation_controller.dart';

import 'classroom_share_panel.dart';

class WorkshopAdminLauncher extends ConsumerWidget {
  const WorkshopAdminLauncher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authoring = ref.watch(workshopAuthoringProvider);
    final catalog = ref.watch(translationControllerProvider).catalog;
    return FilledButton.tonalIcon(
      key: const ValueKey('workshop-learning-path-studio'),
      onPressed: authoring
          ? null
          : () => ref.read(workshopAuthoringProvider.notifier).state = true,
      icon: const Icon(Icons.edit_outlined),
      label: Text(catalog.text('tutorial.studio.returnToEditor')),
    );
  }
}

class WorkshopAdminPanel extends ConsumerStatefulWidget {
  const WorkshopAdminPanel({required this.onStart, super.key});

  final Future<void> Function(AuthoredLearningPath) onStart;

  @override
  ConsumerState<WorkshopAdminPanel> createState() => _WorkshopAdminPanelState();
}

class _WorkshopAdminPanelState extends ConsumerState<WorkshopAdminPanel> {
  AuthoredLearningPath? _sharing;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(translationControllerProvider).catalog;
    ref.watch(workspaceProvider.select((state) => state.revision));
    final mode = ref.watch(sqlModeProvider);
    final library = ref.watch(learningPathLibraryProvider);
    final controller = ref.read(learningPathLibraryProvider.notifier);
    if (library.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (library.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Text(
              catalog.text('tutorial.studio.libraryLoadFailed'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }
    final drafts = controller.drafts.toList(growable: false);
    final draftIds = drafts.map((path) => path.id).toSet();
    return Stack(
      children: [
        ExcludeFocus(
          excluding: _sharing != null,
          child: Offstage(
            offstage: _sharing != null,
            child: LearningPathStudioPanel(
              catalog: catalog,
              paths: [
                ...drafts,
                for (final path in library.paths)
                  if (!draftIds.contains(path.id)) path,
              ],
              draftIds: draftIds,
              workspaceNodes: ref.read(workspaceProvider.notifier).allBlocks(),
              workspaceMode: mode == SqlAbstractionMode.advanced
                  ? LearningPathMode.advanced
                  : LearningPathMode.simple,
              onHighlightsChanged: (ids) =>
                  ref.read(workshopAuthoringHighlightsProvider.notifier).state =
                      ids,
              onStart: widget.onStart,
              onSave: controller.save,
              onDelete: controller.delete,
              onImport: _importBundle,
              onImportSave: controller.addDrafts,
              onExport: (paths) => _saveBundle(
                encodeLearningPathBundle(paths),
                'workshops.json',
                dialogTitle: catalog.text('tutorial.studio.export'),
              ),
              onExportRemote: (path) => _exportRemoteBundle(
                path,
                dialogTitle: catalog.text('tutorial.download.export'),
              ),
              onShareClassroom: (path) => setState(() => _sharing = path),
            ),
          ),
        ),
        if (_sharing case final path?)
          Positioned.fill(
            child: ClassroomSharePanel(
              catalog: catalog,
              path: path,
              onClose: () => setState(() => _sharing = null),
              onSaveFile: () => _exportRemoteBundle(
                path,
                dialogTitle: catalog.text('tutorial.classroom.saveFile'),
              ),
            ),
          ),
      ],
    );
  }

  Future<List<AuthoredLearningPath>> _importBundle() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    if (picked == null) return const [];

    return decodeLearningPathDraftBundle(
      utf8.decode(await picked.readAsBytes()),
    );
  }

  Future<void> _exportRemoteBundle(
    AuthoredLearningPath path, {
    required String dialogTitle,
  }) async {
    final source = encodeLearningPathBundle([path]);
    validateRemoteWorkshopBundle(source);
    await _saveBundle(source, '${path.id}.json', dialogTitle: dialogTitle);
  }

  Future<void> _saveBundle(
    String source,
    String fileName, {
    required String dialogTitle,
  }) async {
    await FilePicker.saveFile(
      dialogTitle: dialogTitle,
      fileName: fileName,
      bytes: utf8.encode(source),
      mimeType: 'application/json',
    );
  }
}
