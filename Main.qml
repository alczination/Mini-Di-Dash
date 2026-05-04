import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects

Window {
    id: mainWindow
    width: 800
    height: 600
    visible: true
    title: "Mini Digital Electric Dash - Racing Edition"

    color: lightTheme ? "#f0f0f0" : "#1a1a1a"
    Behavior on color { ColorAnimation { duration: 400 } }

    FontLoader {
        id: miniFont
        source: "Michroma-Regular.ttf"
    }

    // ==========================================
    // ZMIENNE I KONFIGURACJA
    // ==========================================
    property int themeMode: 0
    property bool lightTheme: themeMode === 1
    property bool isZoomed: false 

    property int centerMode: 0 
    readonly property var modeNames: ["PERFORMANCE", "ENGINE DATA", "TRIP DATA"]

    property color electricBlue: "#00ccff"
    property color redLineColor: "#ff2200"
    property color accentColor: lightTheme ? Qt.darker(electricBlue, 1.2) : electricBlue
    
    property real rpm: 4000 
    property real displayedRpm: startupSweepActive ? sweepRpm : smoothedRpm
    property real speed: 124 
    property real totalMileage: 125000
    property real fuelAmount: 45
    property real outdoorTemp: 19.5
    property int infoMode: 0 

    property real oilTemp: 105
    property real oilPress: 4.2
    property real intakeTemp: 35
    property real tripDistance: 450.5
    property real rangeKm: 320

    property bool checkEngine: true
    property bool absWarning: true
    property bool tractionWarning: true
    property bool handbrakeActive: true

    property bool startupSweepActive: true
    property real sweepRpm: 0
    property real smoothedRpm: rpm
    property bool blinkState: false
    property bool wasZoomedBeforeAlert: false

    property string alertFuel: "FUEL RESERVE"
    property string alertOutsideTemp: "LOW TEMP OUTSIDE"
    property string alertEngineTemp: "HIGH ENGINE TEMP"
    property string alertOilPress: "LOW OIL PRESSURE"
    
    property bool isAlertActive: false
    property string alertMessage: ""
    property string alertSubMessage: ""
    property color alertColor: "#ffaa00"


    // ==========================================
    // ANIMACJE I LOGIKA
    // ==========================================
    Behavior on smoothedRpm { SmoothedAnimation { velocity: 1200; duration: 250 } }

    SequentialAnimation {
        id: sweepAnimation
        running: false
        PauseAnimation { duration: 500 }
        NumberAnimation { target: mainWindow; property: "sweepRpm"; from: 0; to: 8000; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: mainWindow; property: "sweepRpm"; from: 8000; to: 0; duration: 700; easing.type: Easing.InOutQuad }
        ScriptAction { script: startupSweepActive = false }
    }

    SequentialAnimation {
        id: introBuildUp
        running: true
        ParallelAnimation {
            NumberAnimation { target: dashboardBackground; property: "opacity"; to: 1; duration: 600 }
            NumberAnimation { target: checkeredFlagLayer; property: "opacity"; to: 1; duration: 700 }
            NumberAnimation { target: centerDisplay; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: elementsLayer; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: lcdLayer; property: "opacity"; to: 1; duration: 800 }
        }
        ScriptAction { script: sweepAnimation.start() }
    }
// --- TIMER DLA ALERTÓW ---
    Timer {
        id: alertTimeout
        interval: 10000 
        repeat: false
        onTriggered: {
            isAlertActive = false
            isZoomed = wasZoomedBeforeAlert // Przywrócenie poprzedniego stanu
        }
    }

    Item {
        focus: true
        Keys.onSpacePressed: themeMode = (themeMode + 1) % 2
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) infoMode = (infoMode + 1) % 3
            if (event.key === Qt.Key_J) isZoomed = !isZoomed 
            if (event.key === Qt.Key_U) {
                if (!isAlertActive) {
                    wasZoomedBeforeAlert = isZoomed
                    // 1. REZERWA
                    alertMessage = alertFuel
                    alertSubMessage = "LEVEL LOW"
                    alertColor = "#ffaa00"
                    isAlertActive = true
                    isZoomed = true
                    alertTimeout.restart() // Start odliczania
                } else if (alertMessage === alertFuel) {
                    // 2. NISKA TEMP
                    alertMessage = alertOutsideTemp
                    alertSubMessage = "ICE POSSIBLE"
                    alertColor = "#ffaa00"
                    alertTimeout.restart() // Reset licznika dla nowego błędu
                } else if (alertMessage === alertOutsideTemp) {
                    // 3. TEMP SILNIKA
                    alertMessage = alertEngineTemp
                    alertSubMessage = "PULL OVER SAFELY"
                    alertColor = redLineColor
                    alertTimeout.restart()
                } else if (alertMessage === alertEngineTemp) {
                    // 4. CIŚNIENIE OLEJU
                    alertMessage = alertOilPress
                    alertSubMessage = "STOP ENGINE!"
                    alertColor = redLineColor
                    alertTimeout.restart()
                } else {
                    // 5. RĘCZNE WYŁĄCZENIE
                    isAlertActive = false
                    isZoomed = wasZoomedBeforeAlert // PRZYWRÓĆ poprzedni stan
                    alertTimeout.stop() // Zatrzymaj timer, jeśli wyłączasz ręcznie
                }
            }
            
            if (isZoomed) {
                if (event.key === Qt.Key_Left) centerMode = (centerMode - 1 < 0) ? 2 : centerMode - 1
                if (event.key === Qt.Key_Right) centerMode = (centerMode + 1) % 3
            }
        }
        Component.onCompleted: forceActiveFocus()
    }

    // ==========================================
    // WYGLĄD (Gauge Cluster)
    // ==========================================
    Item {
        id: gaugeCluster
        anchors.centerIn: parent
        width: 500; height: 500
        antialiasing: true

        // --- TŁO ---
        Item {
            id: dashboardBackground; anchors.fill: parent; opacity: 0
            Rectangle {
                anchors.fill: parent; radius: 250
                gradient: Gradient {
                    GradientStop { position: 0.0; color: lightTheme ? "#fafafa" : "#2a2a2a" }
                    GradientStop { position: 1.0; color: lightTheme ? "#c0c0c0" : "#0a0a0a" }
                }
                border.color: lightTheme ? "#999" : "black"
                border.width: 2
            }
        }

        // --- SZACHOWNICA ---
        Item {
            id: checkeredFlagLayer
            anchors.fill: parent; opacity: 0; z: 0.5 
            Rectangle { id: dashboardMask; anchors.fill: parent; radius: 250; color: "black"; visible: false }
            Item {
                id: checkeredPatternGrid; anchors.centerIn: parent; width: 500; height: 500 
                Grid {
                    columns: 16; rows: 16; spacing: 0; anchors.fill: parent
                    Repeater {
                        model: 256 
                        Rectangle {
                            width: checkeredPatternGrid.width / 16; height: checkeredPatternGrid.height / 16
                            color: (index + Math.floor(index/16)) % 2 === 0 ? 
                                   (lightTheme ? Qt.rgba(0,0,0,0.02) : Qt.rgba(1,1,1,0.03)) : "transparent"
                        }
                    }
                }
            }
            MultiEffect { anchors.fill: checkeredPatternGrid; source: checkeredPatternGrid; maskEnabled: true; maskSource: dashboardMask }
        }

        // Item {
        //     id: integratedFuelGauge
        //     anchors.fill: parent
        //     anchors.margins: 10 // Odstęp od krawędzi okręgu

        //     // 1. Tło wskaźnika (szary ślad)
        //     Shape {
        //         anchors.fill: parent
        //         layer.enabled: true
        //         layer.samples: 8
        //         opacity: 0.2
        //         ShapePath {
        //             strokeColor: "gray"
        //             strokeWidth: 8
        //             fillColor: "transparent"
        //             capStyle: ShapePath.RoundCap
        //             PathAngleArc {
        //                 centerX: integratedFuelGauge.width / 2
        //                 centerY: integratedFuelGauge.height / 2 + 25
        //                 radiusX: (integratedFuelGauge.width / 2) - 5
        //                 radiusY: (integratedFuelGauge.height / 2) - 5
        //                 startAngle: 55  // Początek łuku na dole
        //                 sweepAngle: 70  // Szerokość łuku
        //             }
        //         }
        //     }

        //     // 2. Aktywny poziom paliwa (Kolor Amber/Bursztynowy)
        //     Shape {
        //         anchors.fill: parent
        //         layer.enabled: true
        //         layer.samples: 8
                
        //         // Efekt poświaty (Glow)
        //         layer.effect: MultiEffect {
        //             brightness: 0.5
        //         }

        //         ShapePath {
        //             // Zmiana koloru na czerwony przy rezerwie
        //             strokeColor: fuelAmount < 8 ? redLineColor : "#ffaa00" 
        //             strokeWidth: 8
        //             fillColor: "transparent"
        //             capStyle: ShapePath.RoundCap
                    
        //             PathAngleArc {
        //                 centerX: integratedFuelGauge.width / 2
        //                 centerY: (integratedFuelGauge.height / 2)
        //                 radiusX: (integratedFuelGauge.width / 2) - 5
        //                 radiusY: (integratedFuelGauge.height / 2) - 5
        //                 startAngle: 55
        //                 // Dynamiczne obliczanie kąta na podstawie fuelAmount (max 50L)
        //                 sweepAngle: (fuelAmount / 50) * 70
                        
        //                 Behavior on sweepAngle { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }
        //             }
        //         }
        //     }

        //     // 3. Ikona paliwa i oznaczenia
        //     Text {
        //         text: "E"
        //         anchors.bottom: parent.bottom
        //         anchors.bottomMargin: isZoomed ? 25 : 15
        //         anchors.left: parent.left
        //         anchors.leftMargin: parent.width * 0.22
        //         font.pixelSize: 10; font.bold: true
        //         color: fuelAmount < 8 ? redLineColor : "#666"
        //     }

        //     Text {
        //         text: "F"
        //         anchors.bottom: parent.bottom
        //         anchors.bottomMargin: isZoomed ? 25 : 15
        //         anchors.right: parent.right
        //         anchors.rightMargin: parent.width * 0.22
        //         font.pixelSize: 10; font.bold: true
        //         color: "#666"
        //     }

        //     // Mała ikona dystrybutora (opcjonalnie tekstowo)
        //     // Text {
        //     //     text: "⛽"
        //     //     anchors.bottom: parent.bottom
        //     //     anchors.bottomMargin: isZoomed ? 12 : 5
        //     //     anchors.horizontalCenter: parent.horizontalCenter
        //     //     font.pixelSize: 12
        //     //     opacity: 0.5
        //     //     color: fuelAmount < 8 ? redLineColor : "white"
        //     // }
        // }

        // --- ELEMENTY WSKAŹNIKA (RPM) ---
        Item {
            id: elementsLayer; anchors.fill: parent; opacity: 0; z: 1
            Item {
                id: ticksLayer
                anchors.fill: parent
                
                Repeater {
                    model: 81
                    delegate: Shape {
                        id: tickShape
                        anchors.fill: parent
                        vendorExtensionsEnabled: true
                        layer.enabled: true
                        layer.samples: 8 // Wysoki antyaliasing

                        property real angle: -135 + (index * (270 / 80))
                        property bool isActive: (index * 100) <= displayedRpm
                        property bool isRedline: (index * 100) >= 6750
                        
                        // Obliczanie współrzędnych (Promień zewnętrzny i wewnętrzny)
                        property real rad: (angle - 90) * Math.PI / 180
                        property real rOut: 240
                        property real rIn: index % 10 === 0 ? 222 : 230
                        
                        ShapePath {
                            strokeWidth: index % 10 === 0 ? 3.5 : 2 // Ułamkowa grubość dla lepszego wygładzenia
                            capStyle: ShapePath.FlatCap
                            
                            // Kolorowanie zgodne z Twoją logiką "Alarmu"
                            strokeColor: {
                                if (isActive) {
                                    return (displayedRpm >= 6750) ? redLineColor : (isRedline ? redLineColor : accentColor);
                                } else {
                                    return isRedline ? Qt.rgba(1, 0, 0, 0.15) : (lightTheme ? "#555" : "#333");
                                }
                            }

                            // Rysowanie linii od punktu A do B
                            startX: 250 + rOut * Math.cos(rad)
                            startY: 250 + rOut * Math.sin(rad)
                            PathLine {
                                x: 250 + tickShape.rIn * Math.cos(tickShape.rad)
                                y: 250 + tickShape.rIn * Math.sin(tickShape.rad)
                            }
                        }
                    }
                }
            }
Item {
                id: numbersLayer; anchors.fill: parent
                scale: isZoomed ? 0.5 : 1.0 
                Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                
                Repeater {
                    model: 9 
                    Item {
                        width: 1; height: 1; anchors.centerIn: parent
                        rotation: -135 + (index * 10 * (270 / 80))
                        
                        Text {
                            id: rpmDigit
                            text: index; 
                            y: isZoomed ? -420 : -205; 
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: miniFont.name; font.pixelSize: 34; font.bold: true
                            color: {
                                if (displayedRpm >= 6750) return redLineColor
                                return index >= 7 ? redLineColor : (lightTheme ? "black" : "#aaa")
                            }
                            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                        }

                        // --- DODANY NAPIS x1000 RPM ---
                        // Text {
                        //     visible: index === 0 // Pokazuj tylko przy zerze
                        //     text: "x1000"
                        //     anchors.top: rpmDigit.bottom
                        //     // anchors.topMargin: 0
                        //     topPadding: 100
                        //     bottomPadding: -100
                        //     // anchors.horizontalCenter: rpmDigit.horizontalCenter
                        //     font.family: miniFont.name
                        //     font.pixelSize: 14 // Mniejszy, techniczny napis
                        //     font.bold: true
                        //     color: "#666" // Subtelny kolor
                            
                        //     // Ponieważ cały Item jest obrócony o -135 stopni, 
                        //     // musimy "odkręcić" sam napis o 135 stopni, żeby był poziomy
                        //     rotation: 135 
                        // }
                    }
                }
            }
            Item {
                id: gaugeLayer; anchors.fill: parent
                Shape {
                    anchors.fill: parent; layer.enabled: true; layer.samples: 16
                    layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; brightness: 0.2 }
                    opacity: 0.6
                    ShapePath {
                        strokeWidth: 16; capStyle: ShapePath.RoundCap; fillColor: "transparent"
                        strokeColor: displayedRpm >= 6750 ? redLineColor : accentColor
                        Behavior on strokeColor { ColorAnimation { duration: 150 } }
                        PathAngleArc { centerX: 250; centerY: 250; radiusX: 220; radiusY: 220; startAngle: 135; sweepAngle: (displayedRpm / 8000) * 270 }
                    }
                }
            }
        }

    // --- CENTRALNY WYŚWIETLACZ ---
    Rectangle {
        id: centerDisplay
        width: isZoomed ? 340 : 215 ; height: isZoomed ? 340 : 215; radius: width / 2; z: 10; anchors.centerIn: parent
        color: lightTheme ? "#fcfcfc" : "#050505"; opacity: 0
        border.color: displayedRpm >= 6750 ? redLineColor : (lightTheme ? "#ccc" : Qt.darker(accentColor, 1.5))
        border.width: 4
        Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowVerticalOffset: 1; shadowBlur: 2; shadowColor: displayedRpm >= 6750 ? Qt.rgba(1, 0, 0, 0.5) : (lightTheme ? "#99000000" : Qt.rgba(0, 0.8, 1, 0.25)) }

        // STRZAŁKI
        // Text { text: "◀"; color: accentColor; opacity: isZoomed ? 0.8 : 0; font.pixelSize: 24; x: 20; anchors.verticalCenter: parent.verticalCenter; Behavior on opacity { NumberAnimation { duration: 300 } } }
        // Text { text: "▶"; color: accentColor; opacity: isZoomed ? 0.8 : 0; font.pixelSize: 24; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter; Behavior on opacity { NumberAnimation { duration: 300 } } }

        // --- SYSTEM POWIADOMIEŃ (CHECK CONTROL) ---
// --- SYSTEM POWIADOMIEŃ (CHECK CONTROL) ---
        Column {
            id: alertOverlay
            anchors.centerIn: parent
            spacing: 15
            opacity: isAlertActive ? 1 : 0
            visible: opacity > 0
            z: 100 

            Behavior on opacity { NumberAnimation { duration: 400 } }

            // Ikona ostrzegawcza (Kolor reaguje na typ błędu)
            Text {
                text: "⚠"
                color: alertColor 
                font.pixelSize: 60
                anchors.horizontalCenter: parent.horizontalCenter
                
                // Mocniejszy efekt poświaty dla czerwonych błędów
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.5
                    brightness: 0.3
                    // colorInversionEnabled: false
                }

                SequentialAnimation on opacity {
                    running: isAlertActive; loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                }
            }

            Text {
                text: alertMessage
                color: lightTheme ? "black" : "white"
                font.family: "Michroma"; font.pixelSize: 18; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: alertSubMessage
                color: alertColor // Napis pomocniczy też w kolorze błędu
                font.family: "Michroma"; font.pixelSize: 11; font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.8
            }
        }
        // --- PANEL KONTROLEK OSTRZEGAWCZYCH ---
        Row {
            id: warningLightsRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: isZoomed ? 275 : 152
            spacing: 10
            z: 20

            Behavior on anchors.topMargin { NumberAnimation { duration: 450 } }

            // 1. CHECK ENGINE
            Item {
                width: isZoomed ? 30 : 25; height: width
                Rectangle {
                    anchors.fill: parent; radius: width/2
                    color: checkEngine ? "#ffaa00" : "#0a0a0a"
                    border.color: checkEngine ? "#ffcc44" : "#222"
                    border.width: 1
                }
                Text {
                    text: "ENG"; anchors.centerIn: parent
                    font.pixelSize: isZoomed ? 8 : 6; font.bold: true
                    color: checkEngine ? "black" : "#333" // Czarny na jasnym tle, szary na ciemnym
                }
                layer.enabled: checkEngine
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#ffaa00"; shadowBlur: 0.4 }
            }

            // 2. ABS
            Item {
                width: isZoomed ? 30 : 24; height: width
                Rectangle {
                    anchors.fill: parent; radius: width/2
                    color: absWarning ? "#ff0000" : "#0a0a0a"
                    border.color: absWarning ? "#ff4444" : "#222"
                    border.width: 1
                }
                Text {
                    text: "ABS"; anchors.centerIn: parent
                    font.pixelSize: isZoomed ? 8 : 6; font.bold: true
                    color: absWarning ? "white" : "#333"
                }
                layer.enabled: absWarning
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#ff0000"; shadowBlur: 0.4 }
            }

            // 3. TRAKCJA (DSC)
            Item {
                width: isZoomed ? 30 : 24; height: width
                Rectangle {
                    anchors.fill: parent; radius: width/2
                    color: tractionWarning ? "#ffaa00" : "#0a0a0a"
                    border.color: tractionWarning ? "#ffcc44" : "#222"
                    border.width: 1
                }
                Text {
                    text: "DSC"; anchors.centerIn: parent
                    font.pixelSize: isZoomed ? 8 : 6; font.bold: true
                    color: tractionWarning ? "black" : "#333"
                }
                // Pulsowanie dla trakcji
                SequentialAnimation on opacity {
                    running: tractionWarning; loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 200 }
                    NumberAnimation { to: 1.0; duration: 200 }
                }
            }

            // 4. HAMULEC (Ręczny)
            Item {
                width: isZoomed ? 30 : 24; height: width
                Rectangle {
                    anchors.fill: parent; radius: width/2
                    color: handbrakeActive ? "#ff0000" : "#0a0a0a"
                    border.color: handbrakeActive ? "#ff4444" : "#222"
                    border.width: 1
                }
                Text {
                    text: "(!)"; anchors.centerIn: parent
                    font.pixelSize: isZoomed ? 10 : 7; font.bold: true
                    color: handbrakeActive ? "white" : "#333"
                }
                layer.enabled: handbrakeActive
                layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#ff0000"; shadowBlur: 0.4 }
            }
        }

        Image {
                id: sLogo
                source: "mini_logo.png"
                width: isZoomed ? 140 : 96
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: (centerMode === 0) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300 } }
                Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        }
        // ---------------------------------------------------------------------
        // TRYB 0: PERFORMANCE (Prędkość + RPM)
        // ---------------------------------------------------------------------
// ---------------------------------------------------------------------
        // GLOBAL SPEED & RPM (Zawsze widoczne, przesuwa się przy alercie)
        // ---------------------------------------------------------------------
        Column {
            id: globalSpeedColumn
            opacity: 1 // Prędkość już nigdy nie znika
            visible: true
            anchors.centerIn: parent
            
            // LOGIKA POZYCJI: Przesuń do góry (-95), jeśli:
            // Jesteśmy w trybie innym niż 0 LUB gdy wywali alert
            anchors.verticalCenterOffset: (isZoomed && (centerMode !== 0 || isAlertActive)) ? -95 : -10
            
            Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            spacing: isZoomed ? ((centerMode === 0 && !isAlertActive) ? -15 : -5) : 2

            // Jednostka KM/H
            Text { 
                text: "KM/H"
                color: displayedRpm >= 6750 ? redLineColor : accentColor
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                // Zmniejsz czcionkę jednostki podczas alertu w trybie 0
                font.pixelSize: isZoomed ? ((centerMode === 0 && !isAlertActive) ? 22 : 12) : 15
                font.family: "Michroma"
                topPadding: isZoomed ? ((centerMode === 0 && !isAlertActive) ? 20 : 0) : 7 
            }

            // Cyfry Prędkości
            Text { 
                text: Math.floor(speed)
                color: lightTheme ? "black" : "white"
                font.family: miniFont.name
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                // LOGIKA ROZMIARU: Jeśli jest alert w trybie 0, zmniejsz czcionkę do 50, aby zmieściła się na górze
                font.pixelSize: isZoomed ? ((centerMode === 0 && !isAlertActive) ? 110 : 50) : 65
                topPadding: isZoomed ? 0 : -18
                Behavior on font.pixelSize { NumberAnimation { duration: 450 } } 
            }

            // RPM pod prędkością (opcjonalne w trybie alertu)
            Text { 
                text: Math.floor(displayedRpm) + " RPM"
                color: accentColor
                font.family: miniFont.name
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: 18
                // Ukryj mały napis RPM pod prędkością, gdy jest alert, żeby nie robić ścisku
                opacity: (isZoomed && centerMode === 0 && !isAlertActive) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 300 } } 
            }
        }

        // ---------------------------------------------------------------------
        // TRYB 1: ENGINE DATA (Rozwinięte parametry silnika)
        // ---------------------------------------------------------------------
        Column {
            opacity: (!isAlertActive && centerMode === 1 && isZoomed) ? 1 : 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 25
            Behavior on opacity { NumberAnimation { duration: 400 } }
            spacing: 15
            
            Grid {
                columns: 2; spacing: 25; anchors.horizontalCenter: parent.horizontalCenter
                
                // OIL TEMP
                Column {
                    spacing: 4
                    Text { text: "OIL TEMP"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true }
                    Text { text: oilTemp + "°C"; color: oilTemp > 115 ? redLineColor : (lightTheme ? "black" : "white"); font.family: "Michroma"; font.pixelSize: 18; font.bold: true }
                }
                // OIL PRESS
                Column {
                    spacing: 4
                    Text { text: "OIL PRESS"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true }
                    Text { text: oilPress.toFixed(1) + " BAR"; color: lightTheme ? "black" : "white"; font.family: "Michroma"; font.pixelSize: 18; font.bold: true }
                }
                // BOOST
                Column {
                    spacing: 4
                    Text { text: "BOOST"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true }
                    Text { text: "1.2 BAR"; color: electricBlue; font.family: "Michroma"; font.pixelSize: 18; font.bold: true }
                }
                // INTAKE
                Column {
                    spacing: 4
                    Text { text: "INTAKE"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true }
                    Text { text: intakeTemp + "°C"; color: lightTheme ? "black" : "white"; font.family: "Michroma"; font.pixelSize: 18; font.bold: true }
                }
            }

            // Pasek temperatury wody (roboczy)
            Rectangle {
                width: 200; height: 6; color: "#222"; radius: 3; anchors.horizontalCenter: parent.horizontalCenter
                Rectangle {
                    width: parent.width * 0.7; height: parent.height; color: accentColor; radius: 3
                }
            }
        }

        // ---------------------------------------------------------------------
        // TRYB 2: TRIP & FUEL (Dane podróży i paliwo)
        // ---------------------------------------------------------------------
        Column {
            opacity: (!isAlertActive && centerMode === 2 && isZoomed) ? 1 : 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 25
            Behavior on opacity { NumberAnimation { duration: 400 } }
            spacing: 20

            Row {
                spacing: 40; anchors.horizontalCenter: parent.horizontalCenter
                Column {
                    spacing: 5
                    Text { text: "TRIP DISTANCE"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: tripDistance + " KM"; color: lightTheme ? "black" : "white"; font.family: "Michroma"; font.pixelSize: 21; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
                Column {
                    spacing: 5
                    Text { text: "RANGE"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: rangeKm + " KM"; color: electricBlue; font.family: "Michroma"; font.pixelSize: 21; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            // Wizualizacja poziomu paliwa
            Column {
                spacing: 8; anchors.horizontalCenter: parent.horizontalCenter
                Text { text: "FUEL LEVEL"; color: "#888"; font.family: "Michroma"; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                Rectangle {
                    width: 220; height: 14; color: "#111"; radius: 7; border.color: "#333"
                    Rectangle {
                        width: parent.width * (fuelAmount / 50) // Zakładając bak 50L
                        height: parent.height; radius: 7
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: fuelAmount < 10 ? redLineColor : electricBlue }
                            GradientStop { position: 1.0; color: Qt.lighter(electricBlue, 1.2) }
                        }
                    }
                }
                Text { text: fuelAmount + " LITERS REMAINING"; color: "#666"; font.family: "Michroma"; font.pixelSize: 12; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }

        Text { visible: isZoomed; text: modeNames[centerMode]; anchors.bottom: parent.bottom; anchors.bottomMargin: 15; anchors.horizontalCenter: parent.horizontalCenter; color: "#666"; font.pixelSize: 9; font.letterSpacing: 2 }
    }

        // --- NOWY, ZINTEGROWANY LCD PILL ---
        Item {
            id: lcdLayer
            width: isZoomed ? 165: 165
            height: isZoomed ? 35: 70
            opacity: 0
            z: 11
            anchors.horizontalCenter: parent.horizontalCenter
            y: isZoomed ? 435 : 380
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

            // Tło pigułki z mocnym zaokrągleniem i szklanym efektem
            Rectangle {
                anchors.fill: parent; radius: 22
                color: lightTheme ? Qt.rgba(1,1,1,0.85) : Qt.rgba(0.05,0.05,0.05,0.8)
                border.color: lightTheme ? "#ccc" : Qt.rgba(0, 0.8, 1, 0.3)
                border.width: 1
                layer.enabled: true
                layer.effect: MultiEffect { shadowEnabled: !lightTheme; shadowColor: electricBlue; shadowBlur: 0.2; opacity: 0.5 }
            }
            Row {
            anchors.centerIn: parent;
               Text {
                    font.family: miniFont.name; font.pixelSize: 14; font.bold: true; color: electricBlue; bottomPadding: 30; opacity: isZoomed ? 0 : 1; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 300}}
                    text: infoMode === 1 ? "TEMP" : (infoMode === 2 ? "FUEL" : "ODO")
                    }
            }
            Row {
                anchors.centerIn: parent; spacing: 10
               // anchors.verticalCenterOffset: isZoomed ? 0 : 12
                // Rectangle { width: 1; height: 12; color: electricBlue; opacity: 0.3; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    color: lightTheme ? "black" : "white"; font.pixelSize: 16; font.bold: true; font.family: miniFont.name; topPadding: isZoomed ? 0 : 20
                    text: {
                        if (infoMode === 1) return outdoorTemp.toFixed(1) + "°C"
                        if (infoMode === 2) return fuelAmount.toFixed(1) + " L"
                        return totalMileage.toLocaleString(Qt.locale("pl_PL"), 'f', 0) + " KM"
                    }
                }
            }
        }
    }
}  