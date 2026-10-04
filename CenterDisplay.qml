import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: centerDisplayRoot
    width: 490
    height: 490
    property alias miniLogoSource: miniLogo.source
    property alias miniLogoWidth: miniLogo.width
    property alias rpmType: nestedMenuContainer.rpmType
    property alias gaugeSweepActive: nestedMenuContainer.gaugeSweepActive
    property alias gearIndicatorActive: nestedMenuContainer.gearIndicatorActive
    property alias parkingAssistant: nestedMenuContainer.parkingAssistant
    property alias tpmsSensorActive: nestedMenuContainer.tpmsSensorActive
    property alias turboBoostSensorActive: nestedMenuContainer.turboBoostSensorActive
    property alias oilPressureSensorActive: nestedMenuContainer.oilPressureSensorActive
    property alias perfShiftActive: nestedMenuContainer.perfShiftActive
    property alias currentSubMenu: nestedMenuContainer.currentSubMenu
    function exitSubMenu() { nestedMenuContainer.exitSubMenu() }
    function moveUp() { nestedMenuContainer.moveUp() }
    function moveDown() { nestedMenuContainer.moveDown() }
    function triggerAction() { nestedMenuContainer.triggerAction() }
    property real currentAngle: -135 + (mainWindow.displayedRpm / 8000) * 270
    property real mathAngle: currentAngle - 90
    property real rad: mathAngle * Math.PI / 180
    property real notchDepth: width * 0.052
    property real notchSpanAngle: 14
    property real bottomSpanAngle: 8
    property real spanRad: notchSpanAngle * Math.PI / 180
    property real bottomRad: bottomSpanAngle * Math.PI / 180
    property real r: width / 2
    Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
    readonly property bool isUpdateRunning: typeof SystemMonitor !== "NULL" && SystemMonitor.updateActive
    Item {
        id: hardwareRotatedShape
        anchors.fill: parent
        property color currentBorderColor: (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive)
                                           ? mainWindow.redLineColor
                                           : mainWindow.customAccentColor
        Item {
            anchors.fill: parent
            Rectangle {
                id: subtleGlow
                anchors.fill: parent
                anchors.margins: mainWindow.displayedRpm >= 6750 ? -4 : -2
                radius: width / 2
                color: "transparent"
                antialiasing: true
                border.width: mainWindow.displayedRpm >= 6750 ? 3 : 2
                border.color: hardwareRotatedShape.currentBorderColor
                opacity: mainWindow.displayedRpm >= 6750 ? 0.8 : 0.35
                Behavior on opacity { NumberAnimation { duration: 100 } }
                Behavior on anchors.margins { NumberAnimation { duration: 100 } }
            }
            Rectangle {
                id: mainCircleBody
                anchors.fill: parent
                radius: width / 2
                border.width: 8
                border.color: hardwareRotatedShape.currentBorderColor
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: mainWindow.lightTheme ? "#f7f9fa" : "#141414" }
                    GradientStop { position: 0.7; color: mainWindow.lightTheme ? "#e2e6ea" : "#0d0d0d" }
                    GradientStop { position: 1.0; color: mainWindow.lightTheme ? "#cfd4da" : "#050505" }
                }
                Rectangle {
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    radius: width / 2
                    antialiasing: true
                    opacity: mainWindow.lightTheme ? 0.25 : 0.13
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#ffffff" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
                Behavior on border.color { ColorAnimation { duration: 120 } }
            }
        }
        Image {
            id: miniLogo
            function resolveLogoSource(option, isGearActive, isLight, isStartup) {
                let showGearVersion = isGearActive && !isStartup
                if (option === "MINI") {
                    return showGearVersion ? "assets/mini_gear.png" : "assets/mini_logo.png"
                }
                if (option === "MODERN") {
                    if (showGearVersion) {
                        return isLight ? "assets/minimodern_gear_lightmode.png" : "assets/minimodern_gear_darkmode.png"
                    } else {
                        return isLight ? "assets/minimodern_logo_lightmode.png" : "assets/minimodern_logo_darkmode.png"
                    }
                }
                if (option === "COOPER S") {
                    return "assets/mini_slogo.png"
                }
                return ""
            }
            readonly property var widthMap: ({
                                                 "MINI"      :   400,
                                                 "COOPER S"  :   105,
                                                 "MODERN"    :   280,
                                                 "BRAK"      :   0
                                             })
            source: resolveLogoSource(mainWindow.activeLogoOption, centerDisplayRoot.gearIndicatorActive, mainWindow.lightTheme, mainWindow.startupSweepActive)
            width: widthMap[mainWindow.activeLogoOption] || 200
            fillMode: Image.PreserveAspectFit
            antialiasing: true
            readonly property bool allowedWithGear: mainWindow.activeLogoOption === "MINI" || mainWindow.activeLogoOption === "MODERN"
            readonly property bool shouldBeVisible: source !== "" && !mainWindow.isZoomed && !centerDisplayRoot.isUpdateRunning && (mainWindow.startupSweepActive || !centerDisplayRoot.gearIndicatorActive || allowedWithGear)
            opacity: shouldBeVisible ? 1.0 : 0.0
            visible: opacity > 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -135
            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                }
            }
        }
        Item {
            // Test
            id: modernGearIndicator
            width: 110
            height: 80
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: 0
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: mainWindow.isZoomed ? -145 : -140
            z: 25
            scale: mainWindow.isZoomed ? 1.2 : 1.4
            Behavior on anchors.verticalCenterOffset {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutQuad
                }
            }
            property bool shouldBeVisible: centerDisplayRoot.gearIndicatorActive
                                           && !mainWindow.isAlertActive
                                           && !centerDisplayRoot.isUpdateRunning
                                           && (!mainWindow.isZoomed || mainWindow.currentModeKey === "MAIN")
            opacity: shouldBeVisible ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutQuad
                }
            }
            property color gearColor: {
                if (mainWindow.currentGear === "R") return mainWindow.redLineColor
                if (mainWindow.currentGear === "N") return "#888888"
                return mainWindow.lightTheme ? "#1a1a1a" : mainWindow.customAccentColor
            }
            MultiEffect {
                anchors.fill: racingBg
                source: racingBg
                shadowEnabled: true
                shadowColor: mainWindow.currentGear === "N" ? "transparent" : modernGearIndicator.gearColor
                shadowBlur: 0.8
                opacity: 0.8
            }
            Text {
                id: gearTextCurrent
                anchors.centerIn: parent
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.horizontalCenterOffset: 10
                text: mainWindow.currentGear
                font.family: miniFont.name
                font.pixelSize: 55
                font.bold: true
                font.italic: false
                color: {
                    if (mainWindow.currentGear === "R") {
                        return mainWindow.redLineColor
                    }
                    if (mainWindow.currentGear === "N") {
                        return "#ffffff"
                    }
                    return mainWindow.customAccentColor
                }
                style: Text.Outline
                styleColor: {
                    if (mainWindow.currentGear === "R") {
                        return mainWindow.redLineColor
                    }
                    return mainWindow.customAccentColor
                }
                Behavior on styleColor { ColorAnimation { duration: 200 } }
                Behavior on styleColor { ColorAnimation { duration: 200 } }
                onTextChanged: {
                    gearPopAnim.restart()
                }
                SequentialAnimation {
                    id: gearPopAnim
                    ParallelAnimation {
                        NumberAnimation {
                            target: gearTextCurrent
                            property: "anchors.horizontalCenterOffset"
                            from: 6
                            to: 0
                            duration: 160
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: gearTextCurrent
                            property: "opacity"
                            from: 0.2
                            to: 1.0
                            duration: 140
                        }
                        NumberAnimation {
                            target: gearTextCurrent
                            property: "scale"
                            from: 0.95
                            to: 1.0
                            duration: 160
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
    // Fuel Arc
    Shape {
        anchors.fill: parent
        antialiasing: true
        smooth: true
        preferredRendererType: Shape.CurveRenderer
        // Dark-Background
        ShapePath {
            fillColor: "transparent"
            strokeColor: mainWindow.lightTheme ? "#e0e0e0" : "#111111"
            strokeWidth: 13
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: centerDisplay.r
                centerY: centerDisplay.r
                radiusX: centerDisplay.r - 4
                radiusY: centerDisplay.r - 4
                startAngle: 130
                sweepAngle: -80
            }
        }
    }
    // Fuel Arc
    Shape {
        anchors.fill: parent
        antialiasing: true
        smooth: true
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.smooth: true
        layer.samples: 8
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.5
            shadowColor: mainWindow.fuelAmount < 4 ? mainWindow.redLineColor : "#ffaa00"
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: mainWindow.fuelAmount < 4 ? mainWindow.redLineColor : '#ffaa00'
            strokeWidth: 8
            capStyle: ShapePath.RoundCap
            Behavior on strokeColor { ColorAnimation { duration: 300 } }
            PathAngleArc {
                centerX: centerDisplay.r
                centerY: centerDisplay.r
                radiusX: centerDisplay.r - 4
                radiusY: centerDisplay.r - 4
                startAngle: 130
                sweepAngle: -80 * Math.max(0.001, Math.min(1.0, mainWindow.fuelAmount / mainWindow.maxFuelCapacity))
                Behavior on sweepAngle {
                    SmoothedAnimation { velocity: 60; duration: 250 }
                }
            }
        }
    }
    Text {
        text: "0";
        color: mainWindow.fuelAmount <= mainWindow.fuelReserveThreshold ? mainWindow.redLineColor : (mainWindow.lightTheme ? "#888" : "#aaa")
        font.family: miniFont.name
        font.pixelSize: isZoomed ? 15 : 30
        font.bold: true
        x: centerDisplay.r - 35 + (centerDisplay.r) * Math.cos(120 * Math.PI / 180) - width/2
        y: isZoomed ? centerDisplay.r - 30 + (centerDisplay.r - 25) * Math.sin(120 * Math.PI / 180) - height/2 : centerDisplay.r - 45 + (centerDisplay.r - 25) * Math.sin(120 * Math.PI / 180) - height/2
    }
    Item {
        width: 45;
        height: 45;
        x: centerDisplay.r - width/2;
        y: centerDisplay.r - 15 + (centerDisplay.r - 25) - height/2
        visible: !mainWindow.isZoomed
        Image {
            id: smallFuelIcon;
            source: "control_lights/tank_light.png";
            anchors.fill: parent;
            fillMode: Image.PreserveAspectFit;
            visible: false
        }
        MultiEffect {
            anchors.fill: smallFuelIcon;
            source: smallFuelIcon;
            colorization: 1.0;
            colorizationColor: mainWindow.fuelAmount <= mainWindow.fuelReserveThreshold ? mainWindow.redLineColor : (mainWindow.lightTheme ? "#888" : "#aaa")
        }
    }
    Text {
        text: "1";
        color: mainWindow.lightTheme ? "#888" : "#aaa";
        font.family: miniFont.name;
        font.pixelSize: isZoomed ? 15 : 30
        font.bold: true;
        x: centerDisplay.r + 35 + (centerDisplay.r - 15) * Math.cos(60 * Math.PI / 180) - width/2;
        y: isZoomed ? centerDisplay.r - 30 + (centerDisplay.r - 25) * Math.sin(60 * Math.PI / 180) - height/2 : centerDisplay.r - 45 + (centerDisplay.r - 25) * Math.sin(60 * Math.PI / 180) - height/2
    }
    Item {
        id: leftBlinkerItem;
        width: 40;
        height: 30;
        anchors.top: parent.top;
        anchors.topMargin: mainWindow.isZoomed ? 120 : 60;
        anchors.horizontalCenter: parent.horizontalCenter;
        anchors.horizontalCenterOffset: mainWindow.isZoomed ? -140 : -80;
        z: 15
        opacity: (mainWindow.leftBlinkerActive && mainWindow.blinkState) ? 1.0 : 0.0;
        visible: opacity > 0
        Shape {
            anchors.fill: parent;
            ShapePath {
                fillColor: "#00ff00"
                strokeColor: "transparent"
                startX: 40
                startY: 10
                PathLine { x: 18; y: 10}
                PathLine { x: 18; y: 0}
                PathLine { x: 0; y: 15}
                PathLine { x: 18; y: 30}
                PathLine { x: 18; y: 20}
                PathLine { x: 40; y: 20}
                PathLine { x: 40; y: 10}
            }
        }
    }
    Item {
        id: rightBlinkerItem; width: 40; height: 30; anchors.top: parent.top; anchors.topMargin: mainWindow.isZoomed ? 120 : 60; anchors.horizontalCenter: parent.horizontalCenter; anchors.horizontalCenterOffset: mainWindow.isZoomed ? 140 : 80; z: 15
        opacity: (mainWindow.rightBlinkerActive && mainWindow.blinkState) ? 1.0 : 0.0; visible: opacity > 0
        Shape { anchors.fill: parent; ShapePath { fillColor: "#00ff00"; strokeColor: "transparent"; startX: 0; startY: 10; PathLine { x: 22; y: 10 } PathLine { x: 22; y: 0 } PathLine { x: 40; y: 15 } PathLine { x: 22; y: 30 } PathLine { x: 22; y: 20 } PathLine { x: 0; y: 20 } PathLine { x: 0; y: 10 } } }
    }
    Column {
        id: alertOverlay;
        anchors.centerIn: parent;
        anchors.verticalCenterOffset: 25;
        spacing: 15;
        opacity: (mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning) ? 1 : 0;
        visible: opacity > 0;
        z: 100
        Behavior on opacity {
            NumberAnimation {
                duration: 400
            }
        }
        Item {
            width: 86;
            height: 86;
            anchors.horizontalCenter: parent.horizontalCenter
            Image {
                id: alertIconImg;
                source: mainWindow.alertIconSource;
                anchors.fill: parent;
                fillMode: Image.PreserveAspectFit;
                visible: false
            }
            MultiEffect {
                anchors.fill: alertIconImg;
                source: alertIconImg;
                colorization: 1.0;
                colorizationColor: mainWindow.alertColor;
                shadowEnabled: true;
                shadowColor: mainWindow.alertColor;
                shadowBlur: 1.0;
                brightness: 0.8
            }
            SequentialAnimation on opacity {
                running: mainWindow.isAlertActive;
                loops: Animation.Infinite;
                NumberAnimation {
                    to: 0.2;
                    duration: 400;
                    easing.type: Easing.InOutQuad
                } NumberAnimation {
                    to: 1.0;
                    duration: 400;
                    easing.type: Easing.InOutQuad
                }
            }
        }
        Text { text: mainWindow.alertMessage; color: mainWindow.alertColor === mainWindow.redLineColor ? mainWindow.redLineColor : (mainWindow.lightTheme ? "black" : "white"); font.family: "Michroma"; font.pixelSize: 35; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; Behavior on color { ColorAnimation { duration: 250 } } }
        Text { text: mainWindow.alertSubMessage; color: mainWindow.alertColor; font.family: "Michroma"; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; opacity: 0.8 }
    }

    Column {
        id: updateScreenOverlay
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 15
        spacing: 12
        width: 340
        opacity: centerDisplayRoot.isUpdateRunning ? 1 : 0
        visible: opacity > 0
        z: 101
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }
        readonly property bool isFailed: typeof SystemMonitor !== "NULL" && SystemMonitor.updateFailed
        readonly property bool isUpToDate: typeof SystemMonitor !== "NULL" && SystemMonitor.alreadyUpToDate
        readonly property color statusColor: isFailed ? mainWindow.redLineColor : mainWindow.customAccentColor
        Item {
            width: 70
            height: 70
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Qt.rgba(updateScreenOverlay.statusColor.r, updateScreenOverlay.statusColor.g, updateScreenOverlay.statusColor.b, 0.15)
                border.width: 2.5
                border.color: updateScreenOverlay.statusColor
            }
            Text {
                anchors.centerIn: parent
                text: updateScreenOverlay.isFailed ? "!" : "▲"
                font.family: miniFont.name
                font.pixelSize: 32
                font.bold: true
                color: updateScreenOverlay.statusColor
            }
            SequentialAnimation on opacity {
                running: centerDisplayRoot.isUpdateRunning && !updateScreenOverlay.isFailed
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 500; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 500; easing.type: Easing.InOutQuad }
            }
        }
        Text {
            text: {
                if (updateScreenOverlay.isFailed) return "BŁĄD AKTUALIZACJI"
                if (updateScreenOverlay.isUpToDate) return "BRAK AKTUALIZACJI"
                return "AKTUALIZACJA..."
            }
            color: updateScreenOverlay.statusColor
            font.family: miniFont.name
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            width: parent.width - 20
            text: {
                if (updateScreenOverlay.isUpToDate) return "System jest aktualny.\nPosiadasz najnowszą wersję."
                if (updateScreenOverlay.isFailed) return typeof SystemMonitor !== "NULL" ? SystemMonitor.updateStep : "Wystąpił błąd."
                return typeof SystemMonitor !== "NULL" ? SystemMonitor.updateStep : "Pobieranie informacji..."
            }
            color: mainWindow.lightTheme ? "#333333" : "#cccccc"
            font.family: miniFont.name
            font.pixelSize: 13
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Rectangle {
            visible: !updateScreenOverlay.isUpToDate && !updateScreenOverlay.isFailed
            width: parent.width - 30
            height: 10
            radius: 5
            color: mainWindow.lightTheme ? "#d8dce2" : "#1a1f26"
            border.color: mainWindow.lightTheme ? "#b0b6bf" : "#2c3440"
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            Rectangle {
                height: parent.height
                radius: 5
                width: parent.width * Math.max(0.04, Math.min(1.0, (typeof SystemMonitor !== "NULL" ? SystemMonitor.updateProgress : 0) / 100.0))
                color: updateScreenOverlay.statusColor
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                }
            }
        }
        Rectangle {
            visible: updateAlertOverlay.isUpToDate || updateAlertOverlay.isFailed
            width: 140
            height: 28
            radius: 4
            color: updateAlertOverlay.isFailed ? mainWindow.redLineColor : mainWindow.customAccentColor
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.centerIn: parent
                text: "POWRÓT [OK]"
                font.family: "Michroma"
                font.pixelSize: 12
                font.bold: true
                color: updateAlertOverlay.isFailed ? "#ffffff" : "#000000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: if (typeof sysMon !== "undefined") sysMon.cancelOrDismissUpdate()
            }
        }
    }

Column {
    id: globalSpeedColumn;
    anchors.centerIn: parent;
    anchors.verticalCenterOffset: mainWindow.isZoomed ? ((mainWindow.centerMode !== 0 || mainWindow.isAlertActive || centerDisplayRoot.isUpdateRunning) ? -137 : -14) : 28
    Behavior on anchors.verticalCenterOffset {
        NumberAnimation {
            duration: 450;
            easing.type: Easing.InOutQuad
        }
    }
    spacing: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? -22 : -7) : 3
    Text {
        id: speedValueText
        text: Math.floor(mainWindow.speed);
        color: mainWindow.lightTheme ? volcanoOrange : "white";
        font.family: miniFont.name;
        font.bold: true;
        anchors.horizontalCenter: parent.horizontalCenter;
        font.pixelSize: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 150 : 72) : 140;
        topPadding: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 30 : -30) : -10;
        antialiasing: true
        smooth: true
        renderType: Text.QtRendering
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(0, 0, 0, 0.95)
            shadowBlur: 0.35
            shadowHorizontalOffset: 2
            shadowVerticalOffset: 4
            shadowOpacity: 1.0
        }
        Behavior on font.pixelSize {
            NumberAnimation {
                duration: 450
            }
        }
        Behavior on topPadding {
            NumberAnimation {
                duration: 450
                easing.type: Easing.InOutQuad
            }
        }
    }
    Text {
        text: "KM/H";
        color: mainWindow.lightTheme ? volcanoOrange : mainWindow.customAccentColor;
        font.bold: true;
        anchors.horizontalCenter: parent.horizontalCenter;
        font.family: "Michroma"
        font.pixelSize: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 32 : 17) : 30;
        visible: mainWindow.isZoomed ? 0.0 : 1.0;
        transform: Translate {
            y: mainWindow.isZoomed ? -230 : 0
            Behavior on y {
                NumberAnimation { duration: 450; easing.type: Easing.InOutQuad }
            }
        }
        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }
    Text {
        text: (mainWindow.startupSweepActive ? 0 : Math.floor(mainWindow.displayedRpm)) + " RPM";
        color: mainWindow.accentColor;
        font.family: miniFont.name;
        font.bold: true;
        anchors.horizontalCenter: parent.horizontalCenter;
        font.pixelSize: 30;
        opacity: (mainWindow.isZoomed && mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 1 : 0;
        visible: opacity > 0;
        antialiasing: true
        smooth: true
        renderType: Text.QtRendering
        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(0, 0, 0, 0.95)
            shadowBlur: 0.25
            shadowHorizontalOffset: 1
            shadowVerticalOffset: 2
            shadowOpacity: 1.0
        }
        Behavior on opacity { NumberAnimation { duration: 300 } } }
}
// Modes
EngineMode {
    id: engineModeScreen
    oilPressureSensorActive: nestedMenuContainer.oilPressureSensorActive
    oilTemp: canBusBackend.oilTemp
    oilPress: canBusBackend.oilPress
    engineTemp: canBusBackend.engineTemp
    lightTheme: mainWindow.lightTheme
    accentColor: mainWindow.accentColor
    redLineColor: mainWindow.redLineColor
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "ENGINE" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    spacing: 15
}
TripMode {
    fuelAmount: mainWindow.fuelAmount
    maxFuelCapacity: mainWindow.maxFuelCapacity
    fuelReserveThreshold: mainWindow.fuelReserveThreshold
    rangeKm: mainWindow.rangeKm
    lightTheme: mainWindow.lightTheme
    accentColor: mainWindow.accentColor
    redLineColor: mainWindow.redLineColor
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "TRIP" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
}
TurboMode {
    id: turboModeScreen
    turboBoostSensorActive: nestedMenuContainer.turboBoostSensorActive
    turboBoost: canBusBackend.hasOwnProperty("turboBoost") ? canBusBackend.turboBoost : 0.0
    throttlePosition: mainWindow.throttlePosition
    intakeTemp: 0.0
    lightTheme: mainWindow.lightTheme
    accentColor: mainWindow.accentColor
    redLineColor: mainWindow.redLineColor
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "TURBO" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
}
ParkMode {
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "PARK" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
}
InspectionMode {
    lightTheme: mainWindow.lightTheme
    serviceOilKm: mainWindow.serviceOilKm
    serviceBrakesKm: mainWindow.serviceBrakesKm
    inspectionDate: mainWindow.inspectionDate
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "INSPECTION" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
    spacing: 25
}
TiresMode {
    id: tiresModeScreen
    tpmsSensorActive: nestedMenuContainer.tpmsSensorActive
    pressFL: canBusBackend.hasOwnProperty("pressFL") ? canBusBackend.pressFL : 0
    pressFR: canBusBackend.hasOwnProperty("pressFR") ? canBusBackend.pressFR : 0
    pressRL: canBusBackend.hasOwnProperty("pressRL") ? canBusBackend.pressRL : 0
    pressRR: canBusBackend.hasOwnProperty("pressRR") ? canBusBackend.pressRR : 0
    speedFL: canBusBackend.hasOwnProperty("speedFL") ? canBusBackend.speedFL : 0
    speedFR: canBusBackend.hasOwnProperty("speedFR") ? canBusBackend.speedFR : 0
    speedRL: canBusBackend.hasOwnProperty("speedRL") ? canBusBackend.speedRL : 0
    speedRR: canBusBackend.hasOwnProperty("speedRR") ? canBusBackend.speedRR : 0
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "TIRES" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
}
SettingsMode {
    id: nestedMenuContainer
    lightTheme: mainWindow.lightTheme
    electricBlue: mainWindow.electricBlue
    fontName: miniFont.name
    activeLogo: mainWindow.activeLogoOption
    activeColor: mainWindow.activeColorOption
    activeBrightness: mainWindow.brightnessSetting
    onThemeChanged: mainWindow.themeMode = (mainWindow.themeMode + 1) % 2
    onFpsToggled: mainWindow.showFps = !mainWindow.showFps
    onTurboCalibrated: if (mainWindow.hasOwnProperty("turboBoost")) mainWindow.turboBoost = 0.0
    onTripReset: {
        if (mainWindow.hasOwnProperty("rangeKm")) mainWindow.rangeKm = 0
        nestedMenuContainer.exitSubMenu()
    }
    onConsumptionReset: {
        canBusBackend.resetTripConsumption()
        nestedMenuContainer.exitSubMenu()
    }
    onColorChanged: (newColor) => {
                        mainWindow.activeColorOption = newColor
                    }
    onLogoChanged: (newLogo) => {
                       mainWindow.activeLogoOption = newLogo
                   }
    onBrightnessChanged: (newVal) => {
                             mainWindow.brightnessSetting = newVal
                         }
    onOilReset: {
        mainWindow.resetOilService()
        nestedMenuContainer.exitSubMenu()
    }
    onBrakesReset: {
        mainWindow.resetBrakesService()
        nestedMenuContainer.exitSubMenu()
    }
    onInspectionReset: {
        mainWindow.resetInspectionDate()
        nestedMenuContainer.exitSubMenu()
    }
    opacity: (!mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning && mainWindow.currentModeKey === "SETTINGS" && mainWindow.isZoomed) ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: 400 } }
}
Column {
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 36
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 8
    z: 35
    visible: mainWindow.isZoomed && !mainWindow.isAlertActive
    Text {
        id: modeNameText
        anchors.horizontalCenter: parent.horizontalCenter
        text: (mainWindow?.activeModes && mainWindow.activeModes[mainWindow.centerMode]) ? mainWindow.activeModes[mainWindow.centerMode].name : ""
        color: mainWindow.lightTheme ? "#222222" : "#dddddd"
        font.family: miniFont.name
        font.pixelSize: 16
        font.letterSpacing: 2
        font.bold: true
        style: Text.Outline
        styleColor: mainWindow.lightTheme ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(0, 0, 0, 0.8)
        onTextChanged: modeFadeAnim.restart()
        SequentialAnimation {
            id: modeFadeAnim
            NumberAnimation { target: modeNameText; property: "opacity"; from: 0.2; to: 1.0; duration: 150 }
        }
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        visible: mainWindow.isZoomed && !mainWindow.isAlertActive && !centerDisplayRoot.isUpdateRunning
        Repeater {
            model: mainWindow?.activeModes ? mainWindow.activeModes.length : 0
            Rectangle {
                required property int index
                readonly property bool isCurrent: index === mainWindow.centerMode
                width: isCurrent ? 14 : 5
                height: 5
                radius: 2.5
                color: isCurrent ? mainWindow.customAccentColor : (mainWindow.lightTheme ? "#bbbbbb" : "#333333")
                Behavior on width {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
            }
        }
    }
}
}
