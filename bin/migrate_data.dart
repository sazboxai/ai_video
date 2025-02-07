import 'package:firebase_core/firebase_core.dart';
import '../lib/features/trainer/utils/data_migration.dart';

void main() async {
  // Initialize Firebase
  await Firebase.initializeApp();

  final migration = DataMigration();
  
  print('Starting data migration...');
  try {
    await migration.migrateToExerciseCollection();
    print('Migration completed successfully!');
  } catch (e) {
    print('Error during migration: $e');
    print('Rolling back changes...');
    try {
      await migration.rollbackMigration();
      print('Rollback completed successfully!');
    } catch (e) {
      print('Error during rollback: $e');
    }
  }
}
