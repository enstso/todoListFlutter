import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Uploader un fichier
  static Future<String> uploadFile({
    required String path,
    required dynamic file,
    String? fileName,
    Map<String, String>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final ref = _storage.ref().child('users/${user.uid}/$path');

      UploadTask uploadTask;

      if (file is File) {
        uploadTask = ref.putFile(file);
      } else if (file is Uint8List) {
        uploadTask = ref.putData(file);
      } else {
        throw Exception('Type de fichier non supporté');
      }

      // Ajouter des métadonnées si fournies
      if (metadata != null) {
        final metadataObj = SettableMetadata(customMetadata: metadata);
        uploadTask = ref.putData(
          file is File ? await file.readAsBytes() : file,
          metadataObj,
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (kDebugMode) {
        print('Storage: File uploaded successfully - $downloadUrl');
      }

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error uploading file - $e');
      }
      rethrow;
    }
  }

  // Télécharger un fichier
  static Future<Uint8List> downloadFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final data = await ref.getData();

      if (data == null) {
        throw Exception('Fichier non trouvé');
      }

      if (kDebugMode) {
        print('Storage: File downloaded successfully - $path');
      }

      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error downloading file - $e');
      }
      rethrow;
    }
  }

  // Obtenir l'URL de téléchargement
  static Future<String> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final url = await ref.getDownloadURL();

      if (kDebugMode) {
        print('Storage: Download URL obtained - $url');
      }

      return url;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error getting download URL - $e');
      }
      rethrow;
    }
  }

  // Supprimer un fichier
  static Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();

      if (kDebugMode) {
        print('Storage: File deleted successfully - $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error deleting file - $e');
      }
      rethrow;
    }
  }

  // Lister les fichiers dans un dossier
  static Future<List<Reference>> listFiles(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();

      if (kDebugMode) {
        print(
          'Storage: Files listed successfully - ${result.items.length} files',
        );
      }

      return result.items;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error listing files - $e');
      }
      rethrow;
    }
  }

  // Obtenir les métadonnées d'un fichier
  static Future<FullMetadata> getFileMetadata(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = await ref.getMetadata();

      if (kDebugMode) {
        print('Storage: File metadata obtained - $path');
      }

      return metadata;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error getting file metadata - $e');
      }
      rethrow;
    }
  }

  // Mettre à jour les métadonnées d'un fichier
  static Future<void> updateFileMetadata(
    String path,
    Map<String, String> customMetadata,
  ) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(customMetadata: customMetadata);
      await ref.updateMetadata(metadata);

      if (kDebugMode) {
        print('Storage: File metadata updated - $path');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error updating file metadata - $e');
      }
      rethrow;
    }
  }

  // Méthodes spécifiques à l'application TodoList

  // Uploader une image de profil
  static Future<String> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    return await uploadFile(
      path: 'profile_images/${user.uid}.jpg',
      file: imageFile,
      metadata: {
        'uploadedAt': DateTime.now().toIso8601String(),
        'type': 'profile_image',
      },
    );
  }

  // Uploader une pièce jointe de todo
  static Future<String> uploadTodoAttachment(File file, String todoId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final fileName = file.path.split('/').last;

    return await uploadFile(
      path: 'todo_attachments/${user.uid}/$todoId/$fileName',
      file: file,
      metadata: {
        'todoId': todoId,
        'uploadedAt': DateTime.now().toIso8601String(),
        'type': 'todo_attachment',
      },
    );
  }

  // Supprimer une pièce jointe de todo
  static Future<void> deleteTodoAttachment(
    String todoId,
    String fileName,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    await deleteFile('todo_attachments/${user.uid}/$todoId/$fileName');
  }

  // Lister les pièces jointes d'un todo
  static Future<List<Reference>> listTodoAttachments(String todoId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    return await listFiles('todo_attachments/${user.uid}/$todoId');
  }

  // Sauvegarder une exportation de todos
  static Future<String> saveTodoExport(Uint8List exportData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final timestamp = DateTime.now().toIso8601String();

    return await uploadFile(
      path: 'exports/${user.uid}/todos_$timestamp.json',
      file: exportData,
      metadata: {
        'exportedAt': timestamp,
        'type': 'todo_export',
        'format': 'json',
      },
    );
  }

  // Obtenir la taille d'un fichier
  static Future<int> getFileSize(String path) async {
    try {
      final metadata = await getFileMetadata(path);
      return metadata.size ?? 0;
    } catch (e) {
      if (kDebugMode) {
        print('Storage: Error getting file size - $e');
      }
      return 0;
    }
  }

  // Vérifier si un fichier existe
  static Future<bool> fileExists(String path) async {
    try {
      await getFileMetadata(path);
      return true;
    } catch (e) {
      return false;
    }
  }
}
