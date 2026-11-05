
import '../../domain/models/quran_reading_progress.dart';
import '../../domain/repositories/quran_reading_progress_repository.dart';
import '../datasources/quran_reading_progress_local_data_source.dart';

class QuranReadingProgressRepositoryImpl
    implements QuranReadingProgressRepository {
  final QuranReadingProgressLocalDataSource localDataSource;

  const QuranReadingProgressRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<QuranReadingProgress> getProgress({
    DateTime? date,
  }) {
    return localDataSource.getProgress(date: date);
  }

  @override
  Future<void> saveProgress(QuranReadingProgress progress) {
    return localDataSource.saveProgress(progress);
  }
}
