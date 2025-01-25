import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    setWindowTitle('Unity Proje Bulucu');
    setWindowMinSize(const Size(800, 600));
  }
  runApp(const UnityProjectFinderApp());
}

class UnityProjectFinderApp extends StatelessWidget {
  const UnityProjectFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Unity Proje Bulucu',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: const ProjectFinderScreen(),
    );
  }
}

class ProjectFinderScreen extends StatefulWidget {
  const ProjectFinderScreen({super.key});

  @override
  State<ProjectFinderScreen> createState() => _ProjectFinderScreenState();
}

class _ProjectFinderScreenState extends State<ProjectFinderScreen> {
  List<String> _unityProjects = [];
  bool _isSearching = false;
  String _selectedDirectory = '';
  int _totalScanned = 0;
  List<String> _skippedFolders = [];
  String _currentFolder = ''; // Şu an taranan klasör
  int _chunkProcessed = 0; // İşlenen chunk sayısı
  String _lastError = ''; // Son hata mesajı

  Future<void> _selectDirectory() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Unity Projelerini Aramak İçin Klasör Seçin',
      );

      if (selectedDirectory != null) {
        setState(() {
          _selectedDirectory = selectedDirectory;
          _totalScanned = 0;
          _skippedFolders = [];
        });
        await _findUnityProjects(Directory(selectedDirectory));
      }
    } catch (e) {
      _showError('Klasör seçiminde hata oluştu', e.toString());
    }
  }

  Future<void> _findUnityProjects(Directory startDir) async {
    setState(() {
      _isSearching = true;
      _unityProjects = [];
    });

    try {
      await _searchDirectory(startDir);
    } finally {
      setState(() {
        _isSearching = false;
      });

      // Eğer erişilemeyen klasörler varsa bilgilendir
      if (_skippedFolders.isNotEmpty) {
        _showSkippedFoldersDialog();
      }
    }
  }

  Future<void> _searchDirectory(Directory dir) async {
    if (!mounted) return;

    try {
      setState(() {
        _currentFolder = dir.path;
        _lastError = '';
      });

      // Önce bu klasörün Unity projesi olup olmadığını kontrol et
      if (await _isUnityProject(dir)) {
        setState(() {
          _unityProjects.add(dir.path);
        });
        return; // Unity projesi bulundu, alt klasörleri taramaya gerek yok
      }

      // Bazı sistem klasörlerini atlayalım
      if (dir.path.contains('Windows') ||
          dir.path.contains('Program Files') ||
          dir.path.contains('ProgramData') ||
          dir.path.contains('AppData') ||
          dir.path.contains('\$Recycle.Bin')) {
        return;
      }

      List<FileSystemEntity> entries;
      try {
        entries = await dir.list(recursive: false, followLinks: false).toList();
      } on FileSystemException catch (e) {
        _skippedFolders.add(dir.path);
        return;
      }

      // Alt klasörleri gruplar halinde işle
      List<Directory> subDirs = [];
      for (var entry in entries) {
        if (!mounted) return;

        if (entry is Directory) {
          subDirs.add(entry);
        }

        setState(() {
          _totalScanned++;
        });

        // Her 50 klasörde bir küçük bir gecikme ekle
        if (_totalScanned % 50 == 0) {
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // Alt klasörleri paralel olarak tara
      final chunks = _chunkList(subDirs, 5); // 5'erli gruplar halinde işle
      for (var chunk in chunks) {
        if (!mounted) return;

        await Future.wait(chunk.map((dir) async {
          try {
            await _searchDirectory(dir);
          } on FileSystemException catch (e) {
            setState(() {
              _skippedFolders.add(dir.path);
              _lastError = e.toString();
            });
          }
        }));

        setState(() {
          _chunkProcessed++;
        });

        // Her chunk sonrası küçük bir gecikme
        await Future.delayed(const Duration(milliseconds: 1));
      }
    } catch (e) {
      setState(() {
        _skippedFolders.add(dir.path);
        _lastError = e.toString();
      });
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
          i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  Future<bool> _isUnityProject(Directory dir) async {
    try {
      // Önce dosya adlarına bakarak hızlı kontrol yapalım
      final String dirPath = dir.path;
      if (!dirPath.contains('Unity') &&
          !dirPath.contains('unity') &&
          !dirPath.toLowerCase().contains('game') &&
          !dirPath.toLowerCase().contains('project')) {
        return false;
      }

      // Bazı klasörleri direkt atlayalım
      final String dirName =
          dir.path.split(Platform.pathSeparator).last.toLowerCase();
      if (dirName.startsWith('.') ||
          dirName == 'node_modules' ||
          dirName == 'bin' ||
          dirName == 'obj' ||
          dirName == 'library' ||
          dirName == 'temp') {
        return false;
      }

      final assetsDir = Directory('${dir.path}\\Assets');
      if (!await assetsDir.exists()) return false;

      final projectSettingsDir = Directory('${dir.path}\\ProjectSettings');
      if (!await projectSettingsDir.exists()) return false;

      final packageFile = File('${dir.path}\\Packages\\manifest.json');
      return await packageFile.exists();
    } catch (e) {
      return false;
    }
  }

  void _openDirectory(String path) async {
    try {
      await Process.run('explorer', [path]);
    } catch (e) {
      _showError('Klasör açılamadı', e.toString());
    }
  }

  void _showError(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showSkippedFoldersDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 500,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarama Sonucu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bazı klasörlere erişilemedi. Bu normal bir durumdur ve genellikle sistem klasörleri için geçerlidir.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                    'Taranan klasör sayısı:', _totalScanned.toString()),
                const SizedBox(height: 8),
                _buildStatRow(
                    'Bulunan Unity projesi:', _unityProjects.length.toString()),
                const SizedBox(height: 8),
                _buildStatRow(
                    'Erişilemeyen klasör:', _skippedFolders.length.toString()),
                const SizedBox(height: 16),
                const Text(
                  'Erişilemeyen Klasörler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _skippedFolders.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.folder_off, size: 20),
                          title: Text(
                            _formatPath(_skippedFolders[index]),
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kapat'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  String _formatPath(String path) {
    return path.replaceAll('\\\\', '\\');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unity Proje Bulucu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seçili Klasör:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedDirectory.isEmpty
                                ? "Henüz klasör seçilmedi"
                                : _formatPath(_selectedDirectory),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSearching ? null : _selectDirectory,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Klasör Seç'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              Center(
                child: SizedBox(
                  width: 400,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: SizedBox(
                              height: 40,
                              width: 40,
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Taranan Klasör Sayısı: $_totalScanned',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          if (_unityProjects.isNotEmpty)
                            Text(
                                'Bulunan Unity Projesi: ${_unityProjects.length}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text('Debug Bilgileri:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Şu an taranan: ${_currentFolder.split('\\').last}'),
                                Text('İşlenen grup sayısı: $_chunkProcessed'),
                                Text(
                                    'Atlanan klasör sayısı: ${_skippedFolders.length}'),
                                if (_lastError.isNotEmpty)
                                  Text('Son hata: $_lastError',
                                      style:
                                          const TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_skippedFolders.isNotEmpty)
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ListView.builder(
                                itemCount: _skippedFolders.length.clamp(0, 5),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: Text(
                                      'Atlanan: ${_skippedFolders[index].split('\\').last}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Card(
                  child: _unityProjects.isEmpty
                      ? const Center(
                          child: Text(
                            'Unity projesi bulunamadı veya henüz arama yapılmadı',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _unityProjects.length,
                          itemBuilder: (context, index) {
                            final path = _unityProjects[index];
                            return ListTile(
                              title: Text(
                                path.split('\\').last,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(_formatPath(path)),
                              leading: const Icon(Icons.folder, size: 32),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _openDirectory(path),
                                tooltip: 'Klasörü Aç',
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
