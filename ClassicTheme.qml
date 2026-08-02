import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Window {
    id: mainWindow
    width: 720
    height: 720
    visible: true
    color: "#fe0505"
    
    
    FontLoader {
        id: miniFont
        source: "assets/Michroma-Regular.ttf"
    }
    
    // ==========================================
    // ZMIENNE I KONFIGURACJA
    // ==========================================
    property int themeMode: 0
    property bool lightTheme: themeMode === 1
    property bool isZoomed: false
    onIsZoomedChanged: {
        if (isZoomed) {
            centerMode = 0
        }
    }
    
    property bool fuelAlertTriggered: false

    Connections {
        target: canBusBackend
        x: 24
        y: -6
        function onMileageReceived(mileage) {
            mainWindow.totalMileage = mileage
        }
        function onSpeedReceived(value) {
            if(!mainWindow.testMode) {
                mainWindow.speed = value
            }
        }
        function onWheelSpeedsReceived(lf, rf, lr, rr) {
            if (!mainWindow.testMode) {
                mainWindow.speedFL = lf
                mainWindow.speedFR = rf
                mainWindow.speedRL = lr
                mainWindow.speedRR = rr
            }
        }
        function onRpmReceived(value) {
            if(!mainWindow.testMode) {
                mainWindow.rpm = value
            }
        }
        function onTempReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.outdoorTemp = value
            }
        }
        function onFuelReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.fuelAmount = value
            }
        }
        function onFuelReserveChanged(active) {
            if (!mainWindow.testMode) {
                if (active) {
                    // Jeśli rezerwa jest aktywna, ale komunikat jeszcze NIE wyskoczył
                    if (!mainWindow.fuelAlertTriggered && !mainWindow.isAlertActive) {
                        
                        mainWindow.fuelAlertTriggered = true // Blokujemy kolejne uruchomienia
                        mainWindow.wasZoomedBeforeAlert = mainWindow.isZoomed
                        
                        // Konfiguracja Twojego komunikatu
                        mainWindow.alertMessage = mainWindow.alertFuel // "REZERWA"
                        mainWindow.alertSubMessage = "NISKI POZIOM PALIWA"
                        mainWindow.alertColor = "#ffaa00"
                        mainWindow.alertIconSource = "control_lights/tank_light.png"
                        
                        mainWindow.isAlertActive = true
                        mainWindow.isZoomed = true
                        alertTimeout.restart() // Odpala Twój 10-sekundowy timer
                    }
                } else {
                    // Silnik zgasł/auto zatankowane -> resetujemy zatrzask
                    mainWindow.fuelAlertTriggered = false
                }
            }
        }
        function onRangeReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.rangeKm = value
            }
        }
        function onOilTempReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.oilTemp = value
            }
        }
        function onOilPressReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.oilPress = value
            }
        }
        function onEngineTempReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.engineTemp = value
            }
        }
        function onThrottleReceived(value) {
            if (!mainWindow.testMode) {
                mainWindow.throttlePosition = value
            }
        }
        function onAbsWarningReceived(active) {
            if (!mainWindow.testMode) {
                mainWindow._realAbsWarning = active
            }
        }
        function onTractionWarningReceived(active) {
            if (!mainWindow.testMode) {
                mainWindow._realTractionWarning = active
            }
        }
        function onEngineMilStatusReceived(active) {
            if (!mainWindow.testMode) {
                mainWindow._realCheckEngine = active
            }
        }
        function onClusterLightsReceived(leftBlinker, rightBlinker, highBeam, handbrake) {
            if (!mainWindow.testMode) {
                if (leftBlinker !== mainWindow.leftBlinkerActive || rightBlinker !== mainWindow.rightBlinkerActive) {
                    mainWindow.blinkState = true
                }
                mainWindow.leftBlinkerActive = leftBlinker
                mainWindow.rightBlinkerActive = rightBlinker
                mainWindow.highBeamActive = highBeam
                mainWindow.handbrakeActive = handbrake
            }
        }
        function onGForceReceived(xValue, yValue) {
            if (!mainWindow.testMode) {
                mainWindow.gForceX = (xValue - 512) / 512.0
                mainWindow.gForceY = (yValue - 512) / 512.0
            }
        }
        // Nowe, rozbite sygnały (zamiast problematycznego onClusterLightsReceived)
        function onHandbrakeReceived(active) {
            if (!mainWindow.testMode) {
                mainWindow.handbrakeActive = active
            }
        }
        
        function onHoodStatusReceived(open) {
            if (!mainWindow.testMode) {
                mainWindow.hoodOpen = open
            }
        }
        
        function onTrunkStatusReceived(open) {
            if (!mainWindow.testMode) {
                mainWindow.trunkOpen = open
            }
        }
        
        function onDoorLeftStatusReceived(open) {
            if (!mainWindow.testMode) {
                mainWindow.doorLeftOpen = open
            }
        }
        
        function onDoorRightStatusReceived(open) {
            if (!mainWindow.testMode) {
                mainWindow.doorRightOpen = open
            }
        }
    }
    
    property int centerMode: 0
    readonly property var modeNames: ["OSIĄGI", "SILNIK", "TRIP", "TURBO", "INSPEKCJA", "AUTO", "OPONY", "G-SENSOR"]
    
    property color electricBlue: "#00ccff"
    property color redLineColor: "#ff2200"
    property color accentColor: lightTheme ? Qt.darker(electricBlue, 1.2) : electricBlue
    
    property real rpm: 0
    property real displayedRpm: startupSweepActive ? sweepRpm : smoothedRpm
    property real speed: 0
    Behavior on speed { SmoothedAnimation { velocity: 150; duration: 200 } }
    property real totalMileage: 0
    
    property real fuelAmount: 0
    property real maxFuelCapacity: 50.0
    property real fuelReserveThreshold: 8.0
    
    property real outdoorTemp: 0
    property int infoMode: 0
    
    property real oilTemp: 0
    property real oilPress: 0.0
    property real engineTemp: 0
    property real intakeTemp: 0
    property real rangeKm: 0
    
    // --- ZMIENNE KIERUNKOWSKAZÓW ---
    property bool highBeamActive: false
    property bool leftBlinkerActive: false
    property bool rightBlinkerActive: false
    property bool blinkState: false
    
    // --- NOWE ZMIENNE DLA NOWYCH TRYBÓW ---
    property real turboBoost: 0.0
    property real throttlePosition: 0.0
    
    property real serviceOilKm: 8500
    property real serviceBrakesKm: 1200
    property string inspectionDate: "06 / 2028"
    
    property bool doorLeftOpen: false
    property bool doorRightOpen: false
    property bool hoodOpen: false
    property bool trunkOpen: false
    
    property real pressFL: 0.0
    property real pressFR: 0.0
    property real pressRL: 0.0
    property real pressRR: 0.0
    property real speedFL: 0.0
    property real speedFR: 0.0
    property real speedRL: 0.0
    property real speedRR: 0.0
    
    property real gForceX: 0.0
    property real gForceY: 0.0
    
    // --------------------------------------
    // KONTROLKI OSTRZEGAWCZE
    // ==========================================
    property bool isBulbCheckActive: false
    property bool testMode: false
    
    property bool _realCheckEngine: false
    property bool checkEngine: _realCheckEngine || isBulbCheckActive || testMode
    property bool _realAbsWarning: false
    property bool absWarning: _realAbsWarning || isBulbCheckActive || testMode
    property bool _realTractionWarning: false
    property bool tractionWarning: _realTractionWarning || isBulbCheckActive || testMode
    property bool _realAirbagWarning: false
    property bool airbagWarning: _realAirbagWarning || isBulbCheckActive || testMode
    property bool handbrakeActive: false
    property bool handbrake: handbrakeActive || isBulbCheckActive || testMode
    
    property bool anyWarningActive: checkEngine || absWarning || tractionWarning || airbagWarning
    
    property bool startupSweepActive: true
    property real sweepRpm: 0
    property real smoothedRpm: rpm
    property bool blinkStateAlert: false
    property bool wasZoomedBeforeAlert: false
    
    property string alertFuel: "REZERWA"
    property string alertOutsideTemp: "TEMPERATURA\n ZEWNĘTRZNA"
    property string alertOpenHood: "OTWARTA MASKA"
    property string alertOpenTrunk: "OTWARTY BAGAŻNIK"
    property string alertEngineTemp: "TEMPERATURA\n SILNIKA"
    property string alertOilPress: "CIŚNIENIE OLEJU"
    property string alertOilSensor: "AWARIA CZUJNIKA OLEJU"
    property string alertABS: "AWARIA\n SYSTEMU ABS"
    property string alertCheckEngine: "CHECK ENGINE"
    
    property bool isAlertActive: false
    property string alertMessage: ""
    property string alertSubMessage: ""
    property color alertColor: "#ffaa00"
    property string alertIconSource: ""
    
    // ==========================================
    // TIMERY I ANIMACJE
    // ==========================================
    
    // --- STARTUP BULB CHECK ---
    Timer {
        id: startupBulbCheckTimer
        interval: 1500 // Zapala kontrolki na 1.5 sekundy po uruchomieniu
        running: true
        repeat: false
        onTriggered: {
            isBulbCheckActive = false
        }
        Component.onCompleted: {
            isBulbCheckActive = true
        }
    }
    
    // Test-Mode Timer
    Timer {
        id: testTimer
        interval: 16
        running: testMode
        repeat: true
        onTriggered: {
            if (rpm < 7800) rpm += 50
            else rpm = 1000
            
            if (speed < 180) speed += 0.5
            else speed = 0
            
            // G-Sensor Simulation
            gForceX = Math.sin(Date.now() / 400) * 0.6
            gForceY = Math.cos(Date.now() / 600) * 0.4
        }
        onRunningChanged: {
            if (running) {
                highBeamActive = true
                handbrakeActive = true
                doorLeftOpen = true
                doorRightOpen = true
                hoodOpen = true
                trunkOpen = true
            } else {
                highBeamActive = false
                handbrakeActive = false
                doorLeftOpen = false
                doorRightOpen = false
                hoodOpen = false
                trunkOpen = false
            }
        }
    }
    
    // Timer kierunkowskazy
    Timer {
        id: blinkerTimer
        interval: 400
        running: leftBlinkerActive || rightBlinkerActive
        repeat: true
        onTriggered: blinkState = !blinkState
        onRunningChanged: {
            if (running) blinkState = true
            else blinkState = false
        }
    }
    
    Behavior on smoothedRpm { SmoothedAnimation { velocity: 1200; duration: 250 } }
    
    Timer {
        id: alertTimeout
        interval: 10000
        repeat: false
        onTriggered: {
            isAlertActive = false
            isZoomed = wasZoomedBeforeAlert
        }
    }
    
    // Keyboard Listener
    Item {
        focus: true
        Keys.onSpacePressed: themeMode = (themeMode + 1) % 2
        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_T) testMode = !testMode
                            if (event.key === Qt.Key_Tab) infoMode = (infoMode + 1) % 5
                            if (event.key === Qt.Key_J) {
                                if (isAlertActive) {
                                    isAlertActive = false
                                    isZoomed = wasZoomedBeforeAlert
                                    alertTimeout.stop()
                                } else {
                                    isZoomed = !isZoomed
                                }
                            }
                            
                            if (event.key === Qt.Key_Q) {
                                leftBlinkerActive = !leftBlinkerActive
                                if (leftBlinkerActive) rightBlinkerActive = false
                            }
                            if (event.key === Qt.Key_E) {
                                rightBlinkerActive = !rightBlinkerActive
                                if (rightBlinkerActive) leftBlinkerActive = false
                            }
                            
                            if (event.key === Qt.Key_U) {
                                if (!isAlertActive) {
                                    wasZoomedBeforeAlert = isZoomed
                                    alertMessage = alertFuel
                                    alertSubMessage = "POZOSTAŁO 50 KM"
                                    alertColor = "#ffaa00"
                                    alertIconSource = "control_lights/tank_light.png"
                                    isAlertActive = true
                                    isZoomed = true
                                    alertTimeout.restart()
                                } else if (alertMessage === alertFuel) {
                                    alertMessage = alertOutsideTemp
                                    alertSubMessage = "-10°C"
                                    alertIconSource = "control_lights/lowtempoutside_light.png"
                                    alertColor = "#ffaa00"
                                    alertTimeout.restart()
                                } else if (alertMessage === alertOpenHood) {
                                    alertMessage = alertOpenHood
                                    alertColor = "#ffaa00"
                                    alertTimeout.restart()
                                } else if (alertMessage === alertOutsideTemp) {
                                    alertMessage = alertEngineTemp
                                    alertSubMessage = "ZGAŚ SILNIK"
                                    alertIconSource = "control_lights/temp_light.png"
                                    alertColor = redLineColor
                                    alertTimeout.restart()
                                } else if (alertMessage === alertEngineTemp) {
                                    alertMessage = alertOilPress
                                    alertSubMessage = "WYŁĄCZ SILNIK!"
                                    alertIconSource = "control_lights/oil_light.png"
                                    alertColor = redLineColor
                                    alertTimeout.restart()
                                } else {
                                    isAlertActive = false
                                    isZoomed = wasZoomedBeforeAlert
                                    alertTimeout.stop()
                                }
                            }
                            
                            if (isZoomed) {
                                if (event.key === Qt.Key_Left) centerMode = (centerMode - 1 < 0) ? 6 : centerMode - 1
                                if (event.key === Qt.Key_Right) centerMode = (centerMode + 1) % 8
                            }
                        }
        Component.onCompleted: forceActiveFocus()
    }

    Rectangle {
        id: rectangle
        x: 0
        y: 0
        width: 720
        height: 720
        color: "#b9b9b9"
        radius: 360
        border.color: "#2a2a2a"
        border.width: 19

        Repeater {
                id: scaleRepeater
                model: 9

                delegate: Item {
                    width: 720
                    height: 720
                    anchors.centerIn: parent
                    rotation: -120 + (index * 30) // To jest super!

                    Rectangle {
                        width: 10
                        height: 85
                        color: "#323232"

                        // Poniższe dwie linijki są kluczowe dla symetrii:
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 15 // Odstęp od krawędzi (zmniejsz/zwiększ, aby idealnie dotykało ramki)
                    }
                }
            }
        // ==========================================
            // CYFRY PODZIAŁKI (0 - 8) pod kątem
            // ==========================================
            Repeater {
                id: labelRepeater
                model: 9

                delegate: Item {
                    width: 720
                    height: 720
                    anchors.centerIn: parent
                    rotation: -120 + (index * 30)

                    Text {
                        text: index
                        font.pixelSize: 70
                        font.family: "Helvetica"
                        font.bold: true
                        color: "#323232"

                        // Pozycjonowanie: centrujemy w poziomie na samej górze
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top

                        // Margines górny musi być WIĘKSZY niż dla kresek,
                        // aby cyfry wpadły pod kreski, do wnętrza zegara (np. 70-80 pikseli)
                        anchors.topMargin: 100

                        // Magia z MINI: W klasycznym R50 cyfry nie są idealnie obrócone "do góry nogami"
                        // przy wyższych wartościach, tylko są lekko korygowane, żeby łatwiej było je czytać.
                        // Możesz kontrolować obrót samej cyfry względem jej własnej osi:
                        // rotation: -parent.rotation // (jeśli chciałbyś, żeby cyfry były zawsze pionowo)

                        // Jeśli chcesz, żeby szły idealnie po łuku (promieniście), zostawiasz rotation: 0
                        rotation: 0

                        // Ustawiamy środek obrotu tekstu idealnie w jego centrum
                        transformOrigin: Text.Center
                    }
                }
            }

            Rectangle {
                id: rectangle1
                x: 245
                y: 523
                width: 230
                height: 95
                color: "#ffffff"
                radius: 20
            }
    }


    // ==========================================
    // WYGLĄD (Gauge Cluster)
    // ==========================================
}
