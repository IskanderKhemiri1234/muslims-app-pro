
import '../../domain/models/quran_bookmark.dart';
import '../../domain/repositories/quran_bookmark_repository.dart';
import '../datasources/quran_bookmark_local_data_source.dart';

class QuranBookmarkRepositoryImpl implements QuranBookmarkRepository {
  final QuranBookmarkLocalDataSource localDataSource;

  const QuranBookmarkRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<List<QuranBookmark>> getBookmarks() {
    return localDataSource.getBookmarks();
  }

  @override
  Future<void> addBookmark(QuranBookmark bookmark) {
    return localDataSource.addBookmark(bookmark);
  }

  @override
  Future<void> removeBookmark(int pageNumber) {
    return localDataSource.removeBookmark(pageNumber);
  }

  @override
  Future<void> updateBookmark(QuranBookmark bookmark) {
    return localDataSource.updateBookmark(bookmark);
  }
}
