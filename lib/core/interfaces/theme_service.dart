abstract class IThemeService {
  Future<bool> isDarkMode();
  Future<void> setDarkMode(bool isDarkMode);
  Future<void> toggleTheme();
}