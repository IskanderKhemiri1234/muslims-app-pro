
import '../models/quran_reading_progress.dart';

abstract class QuranReadingProgressRepository {
  Future<QuranReadingProgress> getProgress({
    DateTime? date,
  });

  Future<void> saveProgress(QuranReadingProgress progress);
}
