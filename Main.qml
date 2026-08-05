import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick 2.15

Window {
    id: mainWindow
    width: 720
    height: 720
    visible: true
    color: lightTheme ? "#f0f0f0" : "#1a1a1a"

    // FPS-Counter
    Item {
        id: fpsCounter
        property int frames: 0
        property int fps: 0
        visible: mainWindow.showFps
        anchors.rightMargin: 200

        Timer {
            interval: 16
            repeat: true
            running: fpsCounter.visible
            onTriggered: fpsCounter.frames++
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 500
            width: 200; height: 40
            color: "red"
            opacity: fpsCounter.visible ? 1.0 : 0.0

            Text {
                anchors.centerIn: parent
                text: "FPS: " + fpsCounter.fps
                color: "yellow"
                font.pixelSize: 22
                font.family: miniFont.name
                style: Text.Outline
                styleColor: "black"
            }
        }
    }

    FontLoader {
        id: miniFont
        source: "assets/Michroma-Regular.ttf"
    }

    /*
    Connections {
        target: canBusBackend
        function onMileageReceived(mileage) { mainWindow.totalMileage = mileage }
        function onTempReceived(value) { if(!mainWindow.testMode) mainWindow.outdoorTemp = value }
        function onThrottleReceived(value) { if(!mainWindow.testMode) mainWindow.throttlePosition = value }
        function onAbsWarningReceived(active) { if(!mainWindow.testMode) mainWindow._realAbsWarning = active }
        function onTractionWarningReceived(active) { if(!mainWindow.testMode) mainWindow._realTractionWarning = active }
        function onEngineMilStatusReceived(active) { if(!mainWindow.testMode) mainWindow._realCheckEngine = active }
        function onClusterLightsReceived(leftBlinker, rightBlinker, headlights, handbrake) {
            if (!mainWindow.testMode) {
                if (leftBlinker !== mainWindow.leftBlinkerActive || rightBlinker !== mainWindow.rightBlinkerActive) {
                    mainWindow.blinkState = true
                }
                mainWindow.leftBlinkerActive = leftBlinker
                mainWindow.rightBlinkerActive = rightBlinker
                mainWindow.headlightsActive = headlights
                mainWindow.handbrakeActive = handbrake
            }
        }
        function onLightsStatusReceived(enabled) {
            headlightsActive = enabled;
        }
        function onFuelReserveChanged(active) {
            if (!mainWindow.testMode) {
                if (active) {
                    if (!mainWindow.fuelAlertTriggered && !mainWindow.isAlertActive) {
                        mainWindow.fuelAlertTriggered = true
                        mainWindow.wasZoomedBeforeAlert = mainWindow.isZoomed
                        mainWindow.alertMessage = mainWindow.alertFuel
                        mainWindow.alertSubMessage = "NISKI POZIOM PALIWA"
                        mainWindow.alertColor = "#ffaa00"
                        mainWindow.alertIconSource = "control_lights/tank_light.png"
                        mainWindow.isAlertActive = true
                        mainWindow.isZoomed = true
                        alertTimeout.restart()
                    }
                } else {
                    mainWindow.fuelAlertTriggered = false
                }
            }
        }
    }
    */

    property int centerMode: 0
    readonly property var modeNames: ["OSIĄGI", "SILNIK", "TRIP", "TURBO", "INSPEKCJA", "PARK", "OPONY", "USTAWIENIA"]

    // Themes
    property color electricBlue: "#00ccff"
    property color redLineColor: "#ff2200"
    property color accentColor: lightTheme ? Qt.darker(electricBlue, 1.2) : electricBlue
    property int themeMode: 0
    property bool lightTheme: themeMode === 1

    // Main
    property real rpm: testMode ? 0 : canBusBackend.rpm
    property real displayedRpm: testMode ? rpm : (startupSweepActive ? sweepRpm : smoothedRpm)
    property real speed: testMode ? 0 : canBusBackend.speed
    Behavior on speed { SmoothedAnimation { velocity: 150; duration: 200 } }
    property real totalMileage: canBusBackend.mileage
    property real outdoorTemp: testMode ? 0 : canBusBackend.outdoorTemp
    property int infoMode: 0

    // Engine-Mode
    property double oilTemp: testMode ? 0 : canBusBackend.oilTemp
    property double oilPress: testMode ? 0 : canBusBackend.oilPress
    property double engineTemp: testMode ? 0 : canBusBackend.engineTemp

    // Trip-Mode
    property real fuelAmount: testMode ? 0 : canBusBackend.fuelAmount
    property real rangeKm: testMode ? 0 : canBusBackend.rangeKm
    property real fuelReserveThreshold: 5.0
    property real maxFuelCapacity: 50

    // Turbo-Mode
    property real throttlePosition: testMode ? 0 : canBusBackend.throttle

    // Service-Mode
    property real serviceBrakesKm: 0
    property var inspectionDate: new Date(2028, 5, 1)

    function resetInspectionDate() {
        var currentDate = new Date()
        inspectionDate = new Date(currentDate.getFullYear() + 2, currentDate.getMonth(), 1)
    }

    // Settings-Mode
    property string activeLogoOption: "MODERN"

    property bool isZoomed: false
    onIsZoomedChanged: {
        if (isZoomed) {
            centerMode = 0
        }
    }

    // Blinkers
    property bool headlightsActive: canBusBackend.headlightsActive
    // property bool leftBlinkerActive: false
    // property bool rightBlinkerActive: false
    // property bool blinkState: false

    // Doors and Hood
    property bool doorLeftOpen: canBusBackend.doorLeft
    property bool doorRightOpen: canBusBackend.doorRight
    property bool hoodOpen: canBusBackend.hoodOpen
    property bool trunkOpen: canBusBackend.trunkOpen

    // MISC
    property bool isBulbCheckActive: false
    property bool testMode: false
    property bool showFps: false

    // Check Controls
    property bool _realCheckEngine: canBusBackend.checkEngine
    property bool checkEngine: _realCheckEngine || isBulbCheckActive || testMode
    property bool _realAbsWarning: canBusBackend.absWarning
    property bool absWarning: _realAbsWarning || isBulbCheckActive || testMode
    property bool _realTractionWarning: canBusBackend.tractionWarning
    property bool tractionWarning: _realTractionWarning || isBulbCheckActive || testMode
    property bool _realAirbagWarning: false
    property bool airbagWarning: _realAirbagWarning || isBulbCheckActive || testMode
    property bool handbrakeActive: testMode ? _testHandbrake : canBusBackend.handbrake

    // Startup and Zoom
    property bool startupSweepActive: true
    property real sweepRpm: 0
    property real smoothedRpm: rpm
    property bool blinkStateAlert: false
    property bool wasZoomedBeforeAlert: false
    property int selectedSettingIndex: 0
    property bool useArcInsteadOfNeedle: !nestedMenuContainer.rpmType

    // Alerts
    property string alertFuel: "REZERWA"
    property string alertOutsideTemp: "TEMPERATURA\n ZEWNĘTRZNA"
    property string alertOpenHood: "OTWARTA MASKA"
    property string alertOpenTrunk: "OTWARTY BAGAŻNIK"
    property string alertEngineTemp: "TEMPERATURA\n SILNIKA"
    property string alertOilPress: "CIŚNIENIE OLEJU"
    property string alertOilSensor: "AWARIA CZUJNIKA OLEJU"
    property string alertABS: "AWARIA\n SYSTEMU ABS"
    property string alertCheckEngine: "CHECK ENGINE"
    property bool fuelAlertTriggered: false
    property bool anyWarningActive: checkEngine || absWarning || tractionWarning || airbagWarning
    property bool isAlertActive: false
    property string alertMessage: ""
    property string alertSubMessage: ""
    property color alertColor: "#ffaa00"
    property string alertIconSource: ""

    onFuelAmountChanged: {
        if (!testMode && canBusBackend.fuelReserve) {
            if (!fuelAlertTriggered && !isAlertActive) {
                fuelAlertTriggered = true
                wasZoomedBeforeAlert = isZoomed
                alertMessage = alertFuel
                alertSubMessage = "NISKI POZIOM PALIWA"
                alertColor = "#ffaa00"
                alertIconSource = "control_lights/tank_light.png"
                isAlertActive = true
                isZoomed = true
                alertTimeout.restart()
            }
        } else if (!canBusBackend.fuelReserve) {
            fuelAlertTriggered = false
        }
    }

    Timer {
        id: startupBulbCheckTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: { mainWindow.isBulbCheckActive = false }
        Component.onCompleted: { mainWindow.isBulbCheckActive = true }
    }

    // TESTMODE
    Item {
        id: testTimer
        readonly property bool running: mainWindow.testMode

        Connections {
            target: mainWindow
            function onTestModeChanged() {
                if (mainWindow.testMode) {
                    headlightsActive = true; handbrakeActive = true; doorLeftOpen = true
                    doorRightOpen = true; hoodOpen = true; trunkOpen = true
                    sweepAnimation.stop()
                    mainWindow.startupSweepActive = false
                    mainWindow.sweepRpm = 0

                    rpmAnimation.start()
                    speedAnimation.start()
                } else {
                    headlightsActive = false; handbrakeActive = false; doorLeftOpen = false
                    doorRightOpen = false; hoodOpen = false; trunkOpen = false

                    rpmAnimation.stop()
                    speedAnimation.stop()

                    mainWindow.rpm = 0
                    mainWindow.speed = 0
                    mainWindow.sweepRpm = 0
                }
            }
        }

        SequentialAnimation {
            id: rpmAnimation
            loops: Animation.Infinite

            NumberAnimation {
                target: mainWindow;
                property: "rpm"
                from: 1000; to: 7500
                duration: 1800; easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: mainWindow;
                property: "rpm"
                from: 7500; to: 1000
                duration: 1200; easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            id: speedAnimation
            loops: Animation.Infinite

            NumberAnimation {
                target: mainWindow; property: "speed"
                from: 0; to: 180
                duration: 4500; easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: mainWindow; property: "speed"
                from: 180; to: 0
                duration: 3500; easing.type: Easing.InOutQuad
            }
        }
    }

    Behavior on smoothedRpm {
        SmoothedAnimation {
            velocity: 1200;
            duration: 250
        }
    }

    SequentialAnimation {
        id: sweepAnimation
        running: false
        PauseAnimation {
            duration: 500
        }
        NumberAnimation {
            target: mainWindow;
            property: "sweepRpm";
            from: 0; to: 8000;
            duration: 900;
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: mainWindow;
            property: "sweepRpm";
            from: 8000; to: 0;
            duration: 700;
            easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: startupSweepActive = false
        }
    }

    SequentialAnimation {
        id: introBuildUp
        running: true
        ParallelAnimation {
            NumberAnimation { target: checkeredFlagLayer; property: "opacity"; to: 1; duration: 700 }
            NumberAnimation { target: centerDisplay; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: elementsLayer; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: bottomLcdDisplay; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: topOuterWarningLights; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: leftWarningLights; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: rightWarningLights; property: "opacity"; to: 1; duration: 800 }
        }
        PauseAnimation { duration: 800 }
        NumberAnimation { target: rpmNeedleContainer; property: "opacity"; to: 1; duration: 400; easing.type: Easing.InOutQuad}
        ScriptAction {
            script: {
                if (nestedMenuContainer.gaugeSweepActive) {
                    sweepAnimation.start();
                } else {
                    startupSweepActive = false;
                }
            }
        }
    }

    Timer {
        id: alertTimeout
        interval: 10000
        repeat: false
        onTriggered: {
            isAlertActive = false
            isZoomed = wasZoomedBeforeAlert
        }
    }

    Item {
        id: keyboardHandler
        focus: true
        z: 999
        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_F) showFps = !showFps
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
                            if (event.key === Qt.Key_L) headlightsActive = !headlightsActive

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

                                if (centerMode === 7) {
                                    if (event.key === Qt.Key_Up) {
                                        nestedMenuContainer.moveUp();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Down) {
                                        nestedMenuContainer.moveDown();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        nestedMenuContainer.triggerAction();
                                        return;
                                    }
                                }
                                if (centerMode !== 7 || nestedMenuContainer.currentSubMenu === "") {
                                    if (event.key === Qt.Key_Left) {
                                        centerMode = (centerMode - 1 < 0) ? 7 : centerMode - 1
                                        mainWindow.selectedSettingIndex = 0
                                        event.accepted = true;
                                    }
                                    if (event.key === Qt.Key_Right) {
                                        centerMode = (centerMode + 1) % 8
                                        mainWindow.selectedSettingIndex = 0
                                        event.accepted = true;
                                    }
                                }
                            }
                        }

        Component.onCompleted: forceActiveFocus()
    }

    // Gauge Cluster
    Item {
        id: gaugeCluster
        width: 720; height: 720
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 10

        // Szachownica
        Item {
            id: checkeredFlagLayer
            anchors.fill: parent; opacity: 0; z: 0.5
            Rectangle { id: dashboardMask; anchors.fill: parent; radius: 360; color: "black"; visible: false }
            Item {
                id: checkeredPatternGrid; anchors.centerIn: parent; width: 720; height: 720
                Grid {
                    columns: 8; rows: 8; spacing: 0; anchors.fill: parent
                    Repeater {
                        model: 64
                        Rectangle {
                            width: checkeredPatternGrid.width / 8; height: checkeredPatternGrid.height / 8
                            color: (index + Math.floor(index/8)) % 2 === 0 ?
                                       (mainWindow.lightTheme ? Qt.rgba(0,0,0,0.01) : Qt.rgba(1,1,1,0.01)) : "transparent"
                        }
                    }
                }
            }
        }

        // Arc
        Item {
            id: elementsLayer; anchors.fill: parent; opacity: 1; z: 1

            // Normal Arc
            Canvas {
                id: staticTicksCanvas
                anchors.fill: parent;
                antialiasing: true;
                renderTarget: Canvas.Image
                visible: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.imageSmoothingEnabled = false
                    ctx.mozImageSmoothingEnabled = false

                    var centerX = 360; var centerY = 360; var radius = 334
                    ctx.lineWidth = 16; ctx.lineCap = "butt"

                    var startRad = 160 * Math.PI / 180
                    var sweepRad = 193 * Math.PI / 180
                    var endRad = startRad + sweepRad

                    ctx.beginPath()
                    ctx.strokeStyle = mainWindow.lightTheme ? "#cccccc" : "#555555"
                    ctx.arc(centerX, centerY, radius, startRad, endRad, false)
                    ctx.stroke()

                    var orangeStartRad = -8 * Math.PI / 180
                    var orangeSweepRad = 28 * Math.PI / 180
                    var orangeEndRad = orangeStartRad + orangeSweepRad

                    ctx.beginPath()
                    ctx.strokeStyle = "#ff6600"
                    ctx.arc(centerX, centerY, radius, orangeStartRad, orangeEndRad, false)
                    ctx.stroke()
                }
            }

            // Ticks on Arc
            Repeater {
                model: 17
                Item {
                    width: 720; height: 720; anchors.centerIn: parent
                    z: isMajorTick ? 100 : 50
                    property int realTickIndex: index * 5
                    rotation: -110 + (realTickIndex * (27.5 / 10))

                    property bool isMajorTick: realTickIndex % 10 === 0
                    property bool isRedline: (realTickIndex * 100) >= 6750

                    Rectangle {
                        width: isMajorTick ? 9 : 5
                        height: isMajorTick ? 50 : 22
                        y: 17
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 1
                        antialiasing: true
                        color: {
                            if (isRedline) {
                                return mainWindow.redLineColor;
                            }
                            return headlightsActive ? "#ffffff" : "#474747";
                        }
                        visible: true
                        border.width: 1;
                        border.color: "transparent"
                    }
                }
            }
            // Stripes on Arc before Redline
            Repeater {
                model: [6250, 6750]
                Item {
                    width: 720; height: 720; anchors.centerIn: parent

                    property int currentRpm: modelData
                    property bool isRedline: currentRpm >= 6750

                    visible: currentRpm % 500 !== 0
                    rotation: -110 + (currentRpm * 0.0275)
                    z: 49

                    Rectangle {
                        width: 4
                        height: 22
                        y: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 1
                        antialiasing: true
                        color: isRedline ? mainWindow.redLineColor : (mainWindow.lightTheme ? "#000000" : "#ffffff")
                    }
                }
            }

            Canvas {
                id: rpmArcCanvas
                anchors.fill: parent; antialiasing: true
                visible: true

                Connections {
                    target: mainWindow
                    function onDisplayedRpmChanged() { rpmArcCanvas.requestPaint() }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.imageSmoothingEnabled = false
                    ctx.mozImageSmoothingEnabled = false

                    ctx.lineWidth = 20; ctx.lineCap = "butt"
                    ctx.strokeStyle = (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive) ? mainWindow.redLineColor : mainWindow.accentColor
                    var startAngleInDegrees = 160
                    var startRad = startAngleInDegrees * Math.PI / 180
                    var sweepAngleInDegrees = (mainWindow.displayedRpm / 8000) * 220
                    var endRad = startRad + (sweepAngleInDegrees * Math.PI / 180)

                    ctx.beginPath()
                    ctx.arc(360, 360, 334, startRad, endRad, false)
                    ctx.stroke()
                }
            }

            // x1000 RPM label
            Item {
                id: rpmLabelLayer; anchors.fill: parent; z: 6
                Text {
                    text: "x1000\nRPM"; anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -250; anchors.verticalCenterOffset: 155
                    horizontalAlignment: Text.AlignHCenter
                    font.family: miniFont.name;
                    font.pixelSize: mainWindow.isZoomed ? 17 : 22;
                    font.bold: true
                    lineHeightMode: Text.ProportionalHeight;
                    lineHeight: 0.8
                    color: Qt.rgba(1, 0.2, 0.2, 0.7)
                }
            }
        }

        // Numbers on Cluster
        Item {
            id: numbersLayer;
            anchors.fill: parent;
            z: 5
            scale: mainWindow.isZoomed ? 0.5 : 1.0

            Repeater {
                model: 9
                Item {
                    width: 1;
                    height: 1;
                    anchors.centerIn: parent
                    rotation: -110 + (index * 27.5)

                    Text {
                        id: rpmDigit;
                        text: index;
                        y: mainWindow.isZoomed ? -573 : -295
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: miniFont.name;
                        font.pixelSize: mainWindow.isZoomed ? 55 : 47;
                        font.bold: true
                        visible: !(index === 4 && mainWindow.isZoomed && topOuterWarningLights.activeLights.length > 0)
                        renderType: Text.QtRendering
                        smooth: false

                        property bool isReached: mainWindow.displayedRpm >= (index * 1000)
                        color: {
                            if (index === 7 || index === 8) {
                                return isReached ? mainWindow.redLineColor : Qt.rgba(1, 0.3, 0.3, 0.8)
                            }
                            if (!headlightsActive) {
                                return "#474747";
                            }
                            else {
                                return "#ffffff";
                            }
                        }
                        scale: isReached ? 1.20 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on y { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }

        // Arc Pie
        Canvas {
            id: rpmPieArcCanvas
            anchors.fill: parent
            z: 0
            visible: mainWindow.useArcInsteadOfNeedle
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.imageSmoothingEnabled = true

                var centerX = 360
                var centerY = 360
                var radius = 334

                var startAngleRad = 159 * Math.PI / 180
                var sweepAngleDeg = (mainWindow.displayedRpm / 8000) * 220
                var endAngleRad = startAngleRad + (sweepAngleDeg * Math.PI / 180)

                ctx.beginPath()
                ctx.moveTo(centerX, centerY)
                ctx.arc(centerX, centerY, radius, startAngleRad, endAngleRad, false)
                ctx.lineTo(centerX, centerY)
                ctx.closePath()

                if (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive) {
                    ctx.fillStyle = Qt.rgba(1, 0, 0, 0.45)
                } else {
                    ctx.fillStyle = Qt.rgba(0, 0.8, 1, 0.50)
                }

                ctx.fill()
            }

            Connections {
                target: mainWindow
                function onDisplayedRpmChanged() { rpmPieArcCanvas.requestPaint() }
            }
        }

        // Needle
        Item {
            id: rpmNeedleContainer
            width: 18
            height: 330
            x: 360 - width / 2
            y: 360 - height
            transformOrigin: Item.Bottom
            rotation: -110 + (displayedRpm / 8000) * 220
            visible: true

            property color needleColor: (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive)
                                        ? mainWindow.redLineColor
                                        : mainWindow.electricBlue

            // Glow
            Shape {
                id: needleGlow
                anchors.fill: parent
                z: 0
                opacity: 0.6
                antialiasing: true

                ShapePath {
                    strokeColor: Qt.rgba(rpmNeedleContainer.needleColor.r,
                                         rpmNeedleContainer.needleColor.g,
                                         rpmNeedleContainer.needleColor.b, 0.35)
                    strokeWidth: 8
                    fillColor: Qt.rgba(rpmNeedleContainer.needleColor.r,
                                       rpmNeedleContainer.needleColor.g,
                                       rpmNeedleContainer.needleColor.b, 0.18)
                    joinStyle: ShapePath.RoundJoin
                    capStyle: ShapePath.RoundCap

                    startX: 2; startY: 315
                    PathLine { x: 7; y: 8 }
                    PathLine { x: 11; y: 8 }
                    PathLine { x: 16; y: 315 }
                    PathLine { x: 2; y: 315 }
                }
            }

            // Main needle
            Shape {
                id: nativeNeedleShape
                anchors.fill: parent
                z: 1
                antialiasing: true

                ShapePath {
                    strokeColor: rpmNeedleContainer.needleColor
                    strokeWidth: 1.8
                    fillColor: rpmNeedleContainer.needleColor
                    joinStyle: ShapePath.MiterJoin
                    capStyle: ShapePath.RoundCap

                    startX: 3; startY: 315
                    PathLine { x: 7.5; y: 12 }
                    PathLine { x: 9;   y: 0 }
                    PathLine { x: 10.5; y: 12 }
                    PathLine { x: 15;  y: 315 }
                    PathLine { x: 3;   y: 315 }
                }
                layer.enabled: true
                layer.samples: 8
                layer.smooth: true
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: rpmNeedleContainer.needleColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -2
                opacity: 0.9
                z: 2
            }
        }

        // Top Warning Lights
        Item {
            id: topOuterWarningLights; anchors.centerIn: parent; z: 30
            property real arcRadius: mainWindow.isZoomed ? (centerDisplay.width / 2 + 20) : (centerDisplay.width / 2 - 30)
            property real centerAngle: -90
            property real angleSpacing: mainWindow.isZoomed ? 12 : 30
            property var lightsModel: [
                { src: "control_lights/highbeam_light.png",  color: "#0066ff",  active: mainWindow.headlightsActive || mainWindow.isBulbCheckActive || mainWindow.testMode, isFullWidth: true },
                { src: "control_lights/handbrake_light.png", color: mainWindow.redLineColor, active: mainWindow.handbrake, isFullWidth: false },
                { src: "control_lights/dooropen_light.png",  color: mainWindow.redLineColor, active: mainWindow.doorLeftOpen || mainWindow.doorRightOpen || mainWindow.isBulbCheckActive, isFullWidth: false },
                { src: "control_lights/hoodopen_light.png",   color: "#ffaa00",  active: mainWindow.hoodOpen || mainWindow.isBulbCheckActive, isFullWidth: false },
                { src: "control_lights/trunkopen_light.png",  color: "#ffaa00",  active: mainWindow.trunkOpen || mainWindow.isBulbCheckActive, isFullWidth: false }
            ]

            property var activeLights: {
                var filtered = []
                for (var i = 0; i < lightsModel.length; i++) {
                    if (lightsModel[i].active) filtered.push(lightsModel[i])
                }
                return filtered
            }

            Repeater {
                model: topOuterWarningLights.activeLights
                Item {
                    property var lightData: modelData;
                    property int activeIndex: index;
                    property int totalActive: topOuterWarningLights.activeLights.length
                    property real targetAngle: {
                        if (totalActive <= 1) return topOuterWarningLights.centerAngle
                        var startAngle = topOuterWarningLights.centerAngle - ((totalActive - 1) * topOuterWarningLights.angleSpacing) / 2
                        return startAngle + (activeIndex * topOuterWarningLights.angleSpacing)
                    }
                    property real rad: targetAngle * Math.PI / 180

                    x: topOuterWarningLights.arcRadius * Math.cos(rad) - width / 2
                    y: mainWindow.isZoomed ? (topOuterWarningLights.arcRadius * Math.sin(rad) - height / 2 - 15) : (topOuterWarningLights.arcRadius * Math.sin(rad) - height / 2 + 20)

                    Behavior on x { SmoothedAnimation { velocity: 150; duration: 250 } }
                    Behavior on y { SmoothedAnimation { velocity: 150; duration: 250 } }

                    width: lightData.isFullWidth ? (mainWindow.isZoomed ? 48 : 52) : (mainWindow.isZoomed ? 42 : 50)
                    height: lightData.isFullWidth ? width * 0.75 : width
                    Behavior on width { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

                    Image { id: imgSource; source: lightData.src; anchors.fill: parent; fillMode: Image.PreserveAspectFit; visible: false }
                    /*
                MultiEffect {
                    anchors.fill: imgSource; source: imgSource; colorization: 1.0; colorizationColor: lightData.color
                    brightness: 1.0; contrast: 0.2; shadowEnabled: true; shadowColor: lightData.color; shadowBlur: 0.8; blurEnabled: true; blur: 0.08
                }
                */
                }
            }
        }

        // Center Display (with KM/H)
        Item {
            id: centerDisplay;
            width: 490;
            height: 490;
            z: 10;
            anchors.centerIn: parent;
            opacity: 0;
            scale: mainWindow.isZoomed ? 1.0 : 0.63

            Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
            property real currentAngle: -135 + (mainWindow.displayedRpm / 8000) * 270
            property real mathAngle: currentAngle - 90
            property real rad: mathAngle * Math.PI / 180
            property real notchDepth: width * 0.052
            property real notchSpanAngle: 14
            property real bottomSpanAngle: 8
            property real spanRad: notchSpanAngle * Math.PI / 180
            property real bottomRad: bottomSpanAngle * Math.PI / 180
            property real r: width / 2

            Item {
                id: hardwareRotatedShape
                anchors.fill: parent
                property color currentBorderColor: (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive)
                                                   ? mainWindow.redLineColor
                                                   : (mainWindow.lightTheme ? "#cccccc" : Qt.darker(mainWindow.accentColor, 1.2))

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
                            GradientStop { position: 0.0; color: mainWindow.lightTheme ? "#ffffff" : "#141414" }
                            GradientStop { position: 1.0; color: mainWindow.lightTheme ? "#e4e4e4" : "#050505" }
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
                    readonly property var logoMap: ({
                                                        "MINI"  	:   "assets/mini_logo.png",
                                                        "COOPER S"  :   "assets/mini_slogo.png",
                                                        "MODERN"    :   "assets/minimodern_logo.png",
                                                        "BRAK"      :   ""
                                                    })
                    readonly property var widthMap: ({
                                                        "MINI"      :   310,
                                                        "COOPER S"  :   105,
                                                        "MODERN"    :   240,
                                                        "BRAK"      :   0
                                                    })
                    source: logoMap[mainWindow.activeLogoOption] || ""
                    width: widthMap[mainWindow.activeLogoOption] || 200
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    readonly property bool shouldBeVisible: source !== "" && !mainWindow.isZoomed
                    opacity: shouldBeVisible ? 1.0 : 0.0
                    visible: opacity > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -135
                    Behavior on opacity {
                        NumberAnimation { duration: 250 }
                    }
                }
            }


            // Fuel Arc
            Shape {
                anchors.fill: parent
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.5
                    shadowColor: mainWindow.fuelAmount < 10 ? mainWindow.redLineColor : "#ffaa00"
                }

                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeWidth: 6
                        strokeColor: mainWindow.lightTheme ? "#000000" : "#ffffff"
                        startX: centerDisplay.r + (centerDisplay.r) * Math.cos(90 * Math.PI / 180)
                        startY: centerDisplay.r + (centerDisplay.r - 12.5) * Math.sin(90 * Math.PI / 180)

                        PathLine {
                            x: centerDisplay.r + (centerDisplay.r) * Math.cos(90 * Math.PI / 180)
                            y: centerDisplay.r + (centerDisplay.r + 2.5) * Math.sin(90 * Math.PI / 180)
                        }
                    }
                }

                ShapePath {
                    fillColor: "transparent"
                    strokeColor: mainWindow.lightTheme ? "#e0e0e0" : "#111111"
                    strokeWidth: 18
                    capStyle: ShapePath.RoundCap

                    PathAngleArc {
                        centerX: centerDisplay.r
                        centerY: centerDisplay.r
                        radiusX: centerDisplay.r - 5
                        radiusY: centerDisplay.r - 5
                        startAngle: 130
                        sweepAngle: -80
                    }
                }

                ShapePath {
                    fillColor: "transparent";
                    strokeColor: mainWindow.fuelAmount < 10 ? '#ff0000' : '#ffaa00';
                    strokeWidth: 18;
                    capStyle: ShapePath.RoundCap
                    Behavior on strokeColor { ColorAnimation { duration: 300 } }
                    PathAngleArc {
                        centerX: centerDisplay.r;
                        centerY: centerDisplay.r;
                        radiusX: centerDisplay.r - 5;
                        radiusY: centerDisplay.r - 5;
                        startAngle: 120;
                        sweepAngle: -60 * (mainWindow.fuelAmount / mainWindow.maxFuelCapacity)
                    }
                }
            }

            Text {
                text: "0";
                color: mainWindow.fuelAmount <= mainWindow.fuelReserveThreshold ? mainWindow.redLineColor : (mainWindow.lightTheme ? "#888" : "#aaa")
                font.family: miniFont.name
                font.pixelSize: isZoomed ? 15 : 30
                font.bold: true
                x: centerDisplay.r - 20 + (centerDisplay.r) * Math.cos(120 * Math.PI / 180) - width/2
                y: isZoomed ? centerDisplay.r - 25 + (centerDisplay.r - 25) * Math.sin(120 * Math.PI / 180) - height/2 : centerDisplay.r - 45 + (centerDisplay.r - 25) * Math.sin(120 * Math.PI / 180) - height/2
            }

            Item {
                width: 45;
                height: 45;
                x: centerDisplay.r - width/2;
                y: centerDisplay.r - 30 + (centerDisplay.r - 25) - height/2
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
                x: centerDisplay.r + 20 + (centerDisplay.r - 15) * Math.cos(60 * Math.PI / 180) - width/2;
                y: isZoomed ? centerDisplay.r - 25 + (centerDisplay.r - 25) * Math.sin(60 * Math.PI / 180) - height/2 : centerDisplay.r - 45 + (centerDisplay.r - 25) * Math.sin(60 * Math.PI / 180) - height/2
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
                opacity: mainWindow.isAlertActive ? 1 : 0;
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
                id: globalSpeedColumn;
                anchors.centerIn: parent;
                anchors.verticalCenterOffset: mainWindow.isZoomed ? ((mainWindow.centerMode !== 0 || mainWindow.isAlertActive) ? -137 : -14) : 28
                Behavior on anchors.verticalCenterOffset {
                    NumberAnimation {
                        duration: 450;
                        easing.type: Easing.InOutQuad
                    }
                }
                spacing: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? -22 : -7) : 3

                Text {
                    text: Math.floor(mainWindow.speed);
                    color: mainWindow.lightTheme ? "black" : "white";
                    font.family: miniFont.name;
                    font.bold: true;
                    anchors.horizontalCenter: parent.horizontalCenter;
                    font.pixelSize: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 150 : 72) : 140;
                    topPadding: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 30 : -30) : -10;

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
                    text: "KM/H"; color: mainWindow.displayedRpm >= 6750 ? mainWindow.redLineColor : mainWindow.accentColor; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; font.family: "Michroma"
                    font.pixelSize: mainWindow.isZoomed ? ((mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 32 : 17) : 30;
                    visible: (mainWindow.isZoomed && mainWindow.centerMode !== 0) ? 0.0 : 1.0;
                    transform: Translate {
                        y: mainWindow.isZoomed ? -230 : 0

                        Behavior on y {
                            NumberAnimation { duration: 450; easing.type: Easing.InOutQuad }
                        }
                    }
                    Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                Text { text: (mainWindow.startupSweepActive ? 0 : Math.floor(mainWindow.displayedRpm)) + " RPM"; color: mainWindow.accentColor; font.family: miniFont.name; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 30; opacity: (mainWindow.isZoomed && mainWindow.centerMode === 0 && !mainWindow.isAlertActive) ? 1 : 0; visible: opacity > 0; Behavior on opacity { NumberAnimation { duration: 300 } } }
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
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 1 && mainWindow.isZoomed) ? 1 : 0;
                visible: opacity > 0;
                Behavior on opacity { NumberAnimation { duration: 400 } } spacing: 15
            }

            TripMode {
                fuelAmount: mainWindow.fuelAmount
                maxFuelCapacity: mainWindow.maxFuelCapacity
                fuelReserveThreshold: mainWindow.fuelReserveThreshold
                rangeKm: mainWindow.rangeKm
                lightTheme: mainWindow.lightTheme
                accentColor: mainWindow.accentColor
                redLineColor: mainWindow.redLineColor
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 2 && mainWindow.isZoomed) ? 1 : 0;
                visible: opacity > 0;
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            TurboMode {
                id: turboModeScreen
                turboBoostSensorActive: nestedMenuContainer.turboBoostSensorActive
                turboBoost: canBusBackend.hasOwnProperty("turboBoost") ? canBusBackend.turboBoost : 0.0
                throttlePosition: mainWindow.throttlePosition
                intakeTemp: mainWindow.intakeTemp
                lightTheme: mainWindow.lightTheme
                accentColor: mainWindow.accentColor
                redLineColor: mainWindow.redLineColor
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 3 && mainWindow.isZoomed) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            ParkMode {
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 5 && mainWindow.isZoomed) ? 1 : 0;
                visible: opacity > 0;
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            InspectionMode {
                serviceOilKm: mainWindow.serviceOilKm
                serviceBrakesKm: mainWindow.serviceBrakesKm
                inspectionDate: mainWindow.inspectionDate
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 4 && mainWindow.isZoomed) ? 1 : 0;
                visible: opacity > 0;
                Behavior on opacity { NumberAnimation { duration: 400 } } spacing: 25
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
                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 6 && mainWindow.isZoomed) ? 1 : 0;
                visible: opacity > 0;
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            SettingsMode {
                id: nestedMenuContainer
                lightTheme: mainWindow.lightTheme
                electricBlue: mainWindow.electricBlue
                fontName: miniFont.name

                // Nasłuchiwanie akcji z wnętrza menu
                onThemeChanged: mainWindow.themeMode = (mainWindow.themeMode + 1) % 2
                onFpsToggled: mainWindow.showFps = !mainWindow.showFps
                onTurboCalibrated: if (mainWindow.hasOwnProperty("turboBoost")) mainWindow.turboBoost = 0.0
                onTripReset: {
                    if (mainWindow.hasOwnProperty("rangeKm")) mainWindow.rangeKm = 0
                    nestedMenuContainer.exitSubMenu()
                }
                onLogoChanged: (newLogo) => {
                                   mainWindow.activeLogoOption = newLogo
                               }
                onInspectionReset: {
                    mainWindow.resetInspectionDate()
                    nestedMenuContainer.exitSubMenu()
                }

                opacity: (!mainWindow.isAlertActive && mainWindow.centerMode === 7 && mainWindow.isZoomed) ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }

            Text {
                visible: mainWindow.isZoomed;
                text: mainWindow.modeNames[mainWindow.centerMode];
                anchors.bottom: parent.bottom;
                anchors.bottomMargin: 35;
                anchors.horizontalCenter: parent.horizontalCenter;
                color: "#666";
                font.pixelSize: 13;
                font.letterSpacing: 2
            }
        }

        // LCD Panel on the bottom
        LcdPanel {
            id: bottomLcdDisplay
            isZoomed: mainWindow.isZoomed
            lightTheme: mainWindow.lightTheme
            infoMode: mainWindow.infoMode
            outdoorTemp: mainWindow.outdoorTemp
            fuelAmount: mainWindow.fuelAmount
            rangeKm: mainWindow.rangeKm
            totalMileage: mainWindow.totalMileage
            electricBlue: mainWindow.electricBlue
            fontName: miniFont.name
            z: 11
            y: mainWindow.isZoomed ? 626 : 545
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // Left Warning Lights
        Row {
            id: leftWarningLights;
            anchors.horizontalCenter: parent.horizontalCenter;
            anchors.horizontalCenterOffset: mainWindow.isZoomed ? -200 : -200
            anchors.top: parent.top;
            anchors.topMargin: mainWindow.isZoomed ? 600 : 550;
            spacing: 7;
            z: 20
            Item {
                width: 50;
                height: 40;
                opacity: mainWindow.checkEngine ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    source: "control_lights/check_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit
                }
                layer.enabled: true;
                layer.effect: MultiEffect {
                    shadowEnabled: true;
                    shadowColor: "#ffaa00";
                    shadowBlur: 0.4
                }
            }
            Item {
                width: 50;
                height: width;
                opacity: mainWindow.absWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    source: "control_lights/abs_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit } layer.enabled: true;
                layer.effect: MultiEffect {
                    shadowEnabled: true;
                    shadowColor: "#ff0000";
                    shadowBlur: 0.4
                }
            }
        }

        // Right Warning Lights
        Row {
            id: rightWarningLights;
            anchors.horizontalCenter: parent.horizontalCenter;
            anchors.horizontalCenterOffset: mainWindow.isZoomed ? 200 : 200
            anchors.top: parent.top;
            anchors.topMargin: mainWindow.isZoomed ? 600 : 550;
            spacing: 7; z: 20
            Item {
                width: 50; height: width;
                opacity: mainWindow.tractionWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    source: "control_lights/dsc_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit;
                }
            }
            Item {
                width: 50;
                height: 40;
                opacity: mainWindow.airbagWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    source: "control_lights/airbag_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit
                }
                layer.enabled: true;
                layer.effect: MultiEffect {
                    shadowEnabled: true;
                    shadowColor: "#ff0000";
                    shadowBlur: 0.4
                }
            }
        }
    }
}
