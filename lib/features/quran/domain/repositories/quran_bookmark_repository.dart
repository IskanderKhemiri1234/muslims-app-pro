
import '../models/quran_bookmark.dart';

abstract class QuranBookmarkRepository {
  Future<List<QuranBookmark>> getBookmarks();

  Future<void> addBookmark(QuranBookmark bookmark);

  Future<void> removeBookmark(int pageNumber);

  Future<void> updateBookmark(QuranBookmark bookmark);
}
