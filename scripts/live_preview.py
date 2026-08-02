import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl, QFileSystemWatcher, QTimer

# ==========================================
# KONFIGURACJA EKRANU
# 0 = Główny monitor, 1 = Drugi monitor
# ==========================================
TARGET_SCREEN_INDEX = 1 
QML_FILE = str(Path(__file__).parent.joinpath("main.qml").resolve())

class LiveReloader:
    def __init__(self, app):
        self.app = app
        self.engine = QQmlApplicationEngine()
        
        # Odkłócacz (Debouncer) zapobiegający podwójnym odświeżeniom
        self.debounce_timer = QTimer()
        self.debounce_timer.setSingleShot(True)
        self.debounce_timer.setInterval(200)
        self.debounce_timer.timeout.connect(self.reload)

        # Obserwator pliku
        self.watcher = QFileSystemWatcher()
        self.watcher.addPath(QML_FILE)
        self.watcher.fileChanged.connect(self.on_file_changed)

        self.first_load()

    def on_file_changed(self, path):
        self.debounce_timer.start()

    def force_position(self):
        root_objects = self.engine.rootObjects()
        if not root_objects:
            return
            
        window = root_objects[-1] 
        screens = self.app.screens()
        
        if TARGET_SCREEN_INDEX < len(screens):
            target_screen = screens[TARGET_SCREEN_INDEX]
            
            window.setScreen(target_screen)
            
            screen_geo = target_screen.geometry()
            x = screen_geo.x() + (screen_geo.width() - window.width()) // 2
            y = screen_geo.y() + (screen_geo.height() - window.height()) // 2
            
            window.setPosition(x, y)
            window.setProperty("x", x)
            window.setProperty("y", y)

    def first_load(self):
        self.engine.load(QUrl.fromLocalFile(QML_FILE))
        QTimer.singleShot(100, self.force_position)

    def reload(self):
        print("[Live Reload] Przeładowywanie interfejsu (Omijanie błędu Qt6)...")
        
        # 1. Zamiast czyścić cache, tworzymy całkowicie nowy, czysty silnik QML
        new_engine = QQmlApplicationEngine()
        new_engine.load(QUrl.fromLocalFile(QML_FILE))
        
        # 2. Jeśli kod QML ma błąd składniowy (literówkę), nowy silnik się nie wczyta.
        # Wtedy przerywamy akcję i zostawiamy stare, działające okno.
        if not new_engine.rootObjects():
            print("[Błąd] Nie udało się wczytać pliku QML. Popraw błąd w pliku main.qml!")
            return

        # 3. Jeśli nowe okno wczytało się bez błędu, niszczymy stare okna
        for obj in self.engine.rootObjects():
            obj.deleteLater()
            
        # 4. Nadpisujemy starą referencję nowym silnikiem
        self.engine = new_engine
        
        # 5. Blokujemy okno na zdefiniowanym ekranie
        QTimer.singleShot(100, self.force_position)

def main():
    app = QGuiApplication(sys.argv)
    reloader = LiveReloader(app)
    
    print(f"[*] Live Preview aktywne na monitorze {TARGET_SCREEN_INDEX}.")
    sys.exit(app.exec())

if __name__ == "__main__":
    main()