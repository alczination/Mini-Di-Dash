import os
import sys
from pathlib import Path
import socket
import time

# --- LEKKI FIX DLA BACKENDU USB NA LAPTOPIE ---
# Szukamy folderu 'libs' niezależnie od tego, czy skrypt jest w głównym katalogu, czy w /scripts
CURRENT_DIR = Path(__file__).parent
if (CURRENT_DIR / "libs").exists():
    LIBS_PATH = CURRENT_DIR / "libs"
elif (CURRENT_DIR.parent / "libs").exists():
    LIBS_PATH = CURRENT_DIR.parent / "libs"
else:
    LIBS_PATH = None

if LIBS_PATH and os.name == 'nt':
    # Wstrzykujemy ścieżkę do folderu z libusb-1.0.dll do zmiennych PATH procesu Pythona
    os.environ['PATH'] = str(LIBS_PATH) + os.pathsep + os.environ.get('PATH', '')
    try:
        # Wymagane dla nowszych wersji Pythona (3.8+), aby załadować dll z lokalnego folderu
        os.add_dll_directory(str(LIBS_PATH))
    except AttributeError:
        pass
# ----------------------------------------------

# Dopiero PO ustawieniu ścieżek importujemy biblioteki USB, żeby nie dostać błędu braku backendu
try:
    from gs_usb.gs_usb import GsUsb
    from gs_usb.gs_usb_frame import GsUsbFrame
except ImportError:
    print("Błąd: Zainstaluj bibliotekę gs_usb na laptopie za pomocą: pip install gs-usb")
    sys.exit(-1)

# Konfiguracja lokalnego mostu sieciowego
UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

def main():
    # Skanowanie urządzeń - dzięki fixowi powyżej, gs_usb bez problemu znajdzie bibliotekę dll
    try:
        devs = GsUsb.scan()
    except Exception as e:
        print(f"Błąd krytyczny PyUSB/libusb: {e}")
        print("Jeśli błąd nadal występuje, uruchom darmowy program Zadig i zmień sterownik urządzenia na Libusb-win32.")
        return

    if len(devs) == 0:
        print("Nie znaleziono InnoMakera przez gs_usb!")
        return
        
    dev = devs[0]
    dev.stop()
    dev.set_bitrate(500000) # Dokładnie 500kbps pod Mini Coopera PT-CAN
    dev.start(0) # GS_CAN_MODE_NORMAL

    print("Backend Pythona żyje! Przechwytuję CAN i nadsyłam do Qt...")
    
    while True:
        iframe = GsUsbFrame()
        if dev.read(iframe, 1):
            # Filtrujemy interesujące nas ID (dorzuciłem tu 0x1F3 pod G-Sensor!)
            # 0x61F, 0x153, 0x1F0, 0x1F3, 0x316, 0x329, 0x545, 0x565, 0x613, 0x615, 0x61A, 
            if iframe.can_id in [0x61F, 0x153, 0x1F0, 0x1F3, 0x316, 0x329, 0x545, 0x565, 0x613, 0x615, 0x61A, 0x615]:
                # Zamieniamy listę na bajty w obu miejscach
                hex_data = "".join(f"{b:02x}" for b in iframe.data)                
                msg = f"{iframe.can_id:X}:{hex_data}"
                sock.sendto(msg.encode(), (UDP_IP, UDP_PORT))
                print(f"Przekazano -> ID: {iframe.can_id:X}, Data: {hex_data}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nZamykanie mostu UDP...")
        try:
            devs = GsUsb.scan()
            if len(devs) > 0: 
                devs[0].stop()
                print("Urządzenie USB-CAN zostało poprawnie zatrzymane.")
        except:
            pass