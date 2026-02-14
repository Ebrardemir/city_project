import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebase servislerinin çalışıp çalışmadığını test eder
class FirebaseTestService {
  /// Firebase Core'un başlatılıp başlatılmadığını kontrol eder
  static Future<Map<String, dynamic>> testFirebaseConnection() async {
    final Map<String, dynamic> results = {};

    try {
      // 1. Firebase Core Test
      final app = Firebase.app();
      results['firebase_core'] = {
        'status': 'OK',
        'app_name': app.name,
        'options': {
          'projectId': app.options.projectId,
          'appId': app.options.appId,
          'storageBucket': app.options.storageBucket,
        },
      };
    } catch (e) {
      results['firebase_core'] = {'status': 'ERROR', 'error': e.toString()};
    }

    try {
      // 2. Firebase Auth Test
      final auth = FirebaseAuth.instance;
      results['firebase_auth'] = {
        'status': 'OK',
        'current_user': auth.currentUser?.uid ?? 'None',
      };
    } catch (e) {
      results['firebase_auth'] = {'status': 'ERROR', 'error': e.toString()};
    }

    try {
      // 3. Firestore Test
      final firestore = FirebaseFirestore.instance;
      results['cloud_firestore'] = {'status': 'OK', 'app': firestore.app.name};
    } catch (e) {
      results['cloud_firestore'] = {'status': 'ERROR', 'error': e.toString()};
    }

    try {
      // 4. Firebase Storage Test
      final storage = FirebaseStorage.instance;
      results['firebase_storage'] = {'status': 'OK', 'bucket': storage.bucket};
    } catch (e) {
      results['firebase_storage'] = {'status': 'ERROR', 'error': e.toString()};
    }

    return results;
  }

  /// Test sonuçlarını konsola yazdırır
  static void printTestResults(Map<String, dynamic> results) {
    print('\n════════════════════════════════════════');
    print('       FIREBASE TEST SONUÇLARI');
    print('════════════════════════════════════════\n');

    results.forEach((service, result) {
      final status = result['status'];
      final icon = status == 'OK' ? '✅' : '❌';

      print('$icon $service: $status');

      if (status == 'OK' && result.containsKey('options')) {
        print('   📦 Project ID: ${result['options']['projectId']}');
        print('   📦 App ID: ${result['options']['appId']}');
        print('   📦 Storage Bucket: ${result['options']['storageBucket']}');
      } else if (status == 'ERROR') {
        print('   ⚠️  Error: ${result['error']}');
      }
      print('');
    });

    print('════════════════════════════════════════\n');
  }
}
