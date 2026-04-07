import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Effects

Window {
    id: mainWindow
    width: 800
    height: 600
    visible: true
    title: "Mini Digital Electric Dash"

    color: lightTheme ? "#d6d6d6" : "#050505"
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
    readonly property var modeNames: ["PERFORMANCE", "ENGINE DATA", "ENTERTAINMENT"]

    property color electricBlue: "#00ccff"
    property color accentColor: lightTheme ? Qt.darker(electricBlue, 1.2) : electricBlue
    
    property real rpm: 0
    property real displayedRpm: startupSweepActive ? sweepRpm : smoothedRpm
    property real speed: 124 
    property real totalMileage: 125000
    property real fuelAmount: 45
    property real outdoorTemp: 19.5
    property int infoMode: 0 

    property bool startupSweepActive: true
    property real sweepRpm: 0
    property real smoothedRpm: rpm
    property bool blinkState: false

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
            NumberAnimation { target: centerDisplay; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: elementsLayer; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: lcdLayer; property: "opacity"; to: 1; duration: 800 }
        }
        ScriptAction { script: sweepAnimation.start() }
    }

    Item {
        focus: true
        Keys.onSpacePressed: themeMode = (themeMode + 1) % 2
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Tab) infoMode = (infoMode + 1) % 3
            if (event.key === Qt.Key_J) isZoomed = !isZoomed 
            
            if (isZoomed) {
                if (event.key === Qt.Key_Left) {
                    centerMode = (centerMode - 1 < 0) ? 2 : centerMode - 1
                }
                if (event.key === Qt.Key_Right) {
                    centerMode = (centerMode + 1) % 3
                }
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

        Item {
            id: dashboardBackground; anchors.fill: parent; opacity: 0
            Rectangle {
                anchors.fill: parent; radius: 250
                gradient: Gradient {
                    GradientStop { position: 0.0; color: lightTheme ? "#f0f0f0" : "#1a1a1a" }
                    GradientStop { position: 1.0; color: lightTheme ? "#aaa" : "#010101" }
                }
                border.color: lightTheme ? "#777" : "black"
                border.width: 2
            }
        }

        Item {
            id: elementsLayer; anchors.fill: parent; opacity: 0; z: 1

            Item {
                id: ticksLayer; anchors.fill: parent
                Repeater {
                    model: 81
                    Item {
                        width: 1; height: 1; anchors.centerIn: parent
                        rotation: -135 + (index * (270 / 80))
                        Rectangle {
                            property bool isActive: (index * 100) <= displayedRpm
                            width: index % 10 === 0 ? 4 : 2
                            height: index % 10 === 0 ? 16 : 8
                            y: -238; anchors.horizontalCenter: parent.horizontalCenter
                            color: isActive ? accentColor : (lightTheme ? "#333" : "#555")
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
                            text: index
                            y: isZoomed ? -433 : -205
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.family: miniFont.name === "" ? "Arial" : miniFont.name
                            font.pixelSize: 34; font.bold: true
                            color: lightTheme ? (index >= 6 ? "#d00" : "black") : (index >= 6 ? electricBlue : "#aaa")
                            style: Text.Outline; styleColor: "black"
                            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                        }
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
                        strokeWidth: 16; strokeColor: accentColor; fillColor: "transparent"; capStyle: ShapePath.RoundCap
                        PathAngleArc { centerX: 250; centerY: 250; radiusX: 220; radiusY: 220; startAngle: 135; sweepAngle: (displayedRpm / 8000) * 270 }
                    }
                }
            }
        }

        Item {
            id: grooveEffect
            anchors.centerIn: parent
            width: centerDisplay.width + 20
            height: centerDisplay.height + 20
            z: 5 
            Rectangle {
                anchors.fill: parent; radius: width/2; color: "transparent"
                border.width: 14; border.color: lightTheme ? "#50000000" : "black"
                layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blur: 0.5 }
            }
            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        }

        Rectangle {
            id: centerDisplay
            width: isZoomed ? 340 : 215 
            height: isZoomed ? 340 : 215
            radius: width / 2
            z: 10; anchors.centerIn: parent
            color: lightTheme ? "#f5f5f5" : "#050505"
            border.color: lightTheme ? "#bbb" : "#1a1a1a"; border.width: 1; opacity: 0

            Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowVerticalOffset: 6; shadowBlur: 0.4; shadowColor: "#DD000000" }

            // STRZAŁKI NAWIGACJI
            Text {
                text: "◀"; color: accentColor; opacity: isZoomed ? 0.8 : 0
                font.pixelSize: 24; x: 20; anchors.verticalCenter: parent.verticalCenter
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }
            Text {
                text: "▶"; color: accentColor; opacity: isZoomed ? 0.8 : 0
                font.pixelSize: 24; anchors.right: parent.right; anchors.rightMargin: 20; anchors.verticalCenter: parent.verticalCenter
                Behavior on opacity { NumberAnimation { duration: 300 } }
            }

            // --- TRYB 0: SPEED ---
            Column {
                opacity: centerMode === 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                anchors.centerIn: parent; spacing: isZoomed ? -40 : -8; z: 11
                Text {
                    text: "KM/H"; color: accentColor
                    font.pixelSize: isZoomed ? 24 : 15; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
                    Behavior on font.pixelSize { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                }
                Text {
                    text: Math.floor(speed)
                    color: lightTheme ? "black" : "white"
                    font.family: miniFont.name === "" ? "Arial" : miniFont.name
                    font.pixelSize: isZoomed ? 95 : 70; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
                    // ANIMACJA CZCIONKI PRĘDKOŚCI
                    Behavior on font.pixelSize { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                }
            }

            // --- TRYB 1: TECH ---
            Column {
                opacity: centerMode === 1 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                anchors.centerIn: parent; spacing: 10
                Text { text: "ENGINE STATUS"; color: accentColor; font.pixelSize: 14; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                
                Row {
                    spacing: 20; anchors.horizontalCenter: parent.horizontalCenter
                    Column { 
                        Text { text: "TEMP"; color: "#888"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "92°C"; color: "white"; font.pixelSize: 22; font.bold: true }
                    }
                    Column { 
                        Text { text: "BOOST"; color: "#888"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "1.2 Bar"; color: electricBlue; font.pixelSize: 22; font.bold: true }
                    }
                }
                Rectangle { width: 150; height: 2; color: "#333" }
                Column { 
                    Text { text: "OIL PRESSURE"; color: "#888"; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "4.5 BAR"; color: "white"; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            // --- TRYB 2: MEDIA ---
            Column {
                opacity: centerMode === 2 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
                anchors.centerIn: parent; spacing: 15
                Text { text: "NOW PLAYING"; color: accentColor; font.pixelSize: 12; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                
                Rectangle {
                    width: 80; height: 80; color: "#111"; radius: 10; anchors.horizontalCenter: parent.horizontalCenter
                    border.color: electricBlue; border.width: 1
                    Text { text: "♫"; color: electricBlue; font.pixelSize: 40; anchors.centerIn: parent }
                }
                
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text { text: "Chemical Brothers"; color: "white"; font.pixelSize: 16; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: "Galvanize"; color: "#888"; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }

            Text {
                visible: isZoomed
                text: modeNames[centerMode]
                anchors.bottom: parent.bottom; anchors.bottomMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#666"; font.pixelSize: 10; font.letterSpacing: 2
            }
        }

        Rectangle {
            id: lcdLayer; width: 190; height: 44; color: "#020202"; radius: 6; opacity: 0
            anchors.horizontalCenter: parent.horizontalCenter; y: isZoomed ? 455 : 395; z: 11
            border.color: "#111"
            Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

            Text {
                anchors.centerIn: parent; color: electricBlue; font.pixelSize: 20; font.bold: true
                text: {
                    switch(infoMode) {
                        case 1: return outdoorTemp.toFixed(1) + "°C"
                        case 2: return fuelAmount.toFixed(1) + " L"
                        default: return totalMileage + " KM"
                    }
                }
            }
        }
    }
}