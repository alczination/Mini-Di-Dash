import sys
import os
import can
import usb.core
import usb.backend.libusb1
# Importy PySide6, których brakowało:
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QTimer

# --- 1. WYMUSZENIE ŚCIEŻKI DO LIBUSB ---
script_dir = os.path.dirname(os.path.abspath(__file__))
dll_path = os.path.join(script_dir, "libusb-1.0.dll")

if hasattr(os, 'add_dll_directory'):
    try:
        os.add_dll_directory(script_dir)
    except:
        pass

# --- 2. KONFIGURACJA BACKENDU ---
backend = usb.backend.libusb1.get_backend(find_library=lambda x: dll_path)

# --- 3. PRÓBA POŁĄCZENIA Z ADAPTEREM ---
bus = None
try:
    # Próbujemy otworzyć adapter
    bus = can.interface.Bus(interface='gs_usb', channel=0, bitrate=500000, backend=backend)
    print("SUKCES: Połączono z Inno-Maker przez gs_usb!")
except Exception as e:
    print(f"BŁĄD ADAPTERA: {e}")
    print("Sprawdź czy adapter nie jest używany przez inny program.")
    bus = None

# --- 4. START APLIKACJI QML ---
app = QGuiApplication(sys.argv)
engine = QQmlApplicationEngine()

# Ładowanie pliku QML
qml_file = os.path.join(script_dir, "Main.qml")
engine.load(qml_file)

if not engine.rootObjects():
    sys.exit(-1)

root_qml = engine.rootObjects()[0]

# --- 5. FUNKCJA ODBIERANIA DANYCH ---
def update_data():
    if bus is not None:
        try:
            msg = bus.recv(timeout=0.001)
            if msg:
                root_qml.updateCanBus(msg.arbitration_id, list(msg.data))
        except:
            pass

timer = QTimer()
timer.timeout.connect(update_data)
timer.start(1)

print("Mostek aktywny. Czekam na dane CAN...")
sys.exit(app.exec())