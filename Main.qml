import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick 2.15
import QtCore

Window {
    id: mainWindow
    width: 720
    height: 720
    visible: true
    color: lightTheme ? "#bcbcbc" : "#1a1a1a"

    Settings {
        id: appSettings
        category: "ClusterData"
        property alias totalMileage: mainWindow.totalMileage
        // property alias fuelAmount: mainWindow.fuelAmount
        property alias rangeKm: mainWindow.rangeKm
        property alias themeMode: mainWindow.themeMode
        property alias activeColorOption: mainWindow.activeColorOption
        property alias activeLogoOption: mainWindow.activeLogoOption
        property alias brightnessSetting: mainWindow.brightnessSetting
        property alias rpmType: centerDisplay.rpmType
        property alias gaugeSweepActive: centerDisplay.gaugeSweepActive
        property alias gearIndicatorActive: centerDisplay.gearIndicatorActive
        property alias parkingAssistant: centerDisplay.parkingAssistant
        property alias tpmsSensorActive: centerDisplay.tpmsSensorActive
        property alias turboBoostSensorActive: centerDisplay.turboBoostSensorActive
        property alias oilPressureSensorActive: centerDisplay.oilPressureSensorActive
        property alias perfShiftActive: centerDisplay.perfShiftActive
        property alias serviceOilKm: mainWindow.serviceOilKm
        property alias serviceBrakesKm: mainWindow.serviceBrakesKm
        property alias infoMode: mainWindow.infoMode
    }

    StartupOverlay {
        id: startupOverlay
        lightTheme: mainWindow.lightTheme
        logoSource: centerDisplay.miniLogoSource
        logoWidth: centerDisplay.miniLogoWidth

        onRevealStarted: {
            gaugeRevealAnimation.start()
        }

        onStartupFinished: {
            if (centerDisplay.gaugeSweepActive) {
                sweepAnimation.start();
            } else {
                startupSweepActive = false;
            }
        }
    }

    SequentialAnimation {
        id: gaugeRevealAnimation
        running: false

        ParallelAnimation {
            NumberAnimation { target: centerDisplay; property: "opacity"; to: 1; duration: 800; easing.type: Easing.InOutQuad }
            NumberAnimation {
                target: centerDisplay;
                property: "scale";
                from: mainWindow.isZoomed ? 0.7 : 0.4;
                to: mainWindow.isZoomed ? 1.0 : 0.63;
                duration: 1000;
                easing.type: Easing.OutBack;
                easing.overshoot: 1.3
            }
            NumberAnimation { target: checkeredFlagLayer; property: "opacity"; to: 1; duration: 800 }
            NumberAnimation { target: elementsLayer; property: "opacity"; to: 1; duration: 900 }
            NumberAnimation { target: bottomLcdDisplay; property: "opacity"; to: 1; duration: 1000 }
        }

        SequentialAnimation {
            NumberAnimation { target: topOuterWarningLights; property: "opacity"; to: 1; duration: 150 }
            NumberAnimation { target: leftWarningLights; property: "opacity"; to: 1; duration: 150 }
            NumberAnimation { target: rightWarningLights; property: "opacity"; to: 1; duration: 150 }
        }

        NumberAnimation { target: rpmNeedleContainer; property: "opacity"; to: 1; duration: 300; easing.type: Easing.InOutQuad }
    }

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

    Connections {
        target: canBusBackend
        //function onAbsWarningReceived(active) { if(!mainWindow.testMode) mainWindow._realAbsWarning = active }
        // function onTractionWarningReceived(active) { if(!mainWindow.testMode) mainWindow._realTractionWarning = active }
        // function onEngineMilStatusReceived(active) { if(!mainWindow.testMode) mainWindow._realCheckEngine = active }
        /*
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
        */
        function onLeftBlinkerChanged() {
            if (!mainWindow.testMode) {
                mainWindow.leftBlinkerActive = canBusBackend.leftBlinker
            }
        }

        function onRightBlinkerChanged() {
            if (!mainWindow.testMode) {
                mainWindow.rightBlinkerActive = canBusBackend.rightBlinker
            }
        }

        function onLightsStatusChanged() {
            if (!mainWindow.testMode) {
                mainWindow.headlightsActive = canBusBackend.headlightsActive
            }
        }

        function onIsSleepingChanged() {
            if (!mainWindow.testMode) {
                if (canBusBackend.isSleeping) {
                    mainWindow.fuelAlertShownThisTrip = false
                    if (!mainWindow.standbyAlertTriggered && !mainWindow.isAlertActive) {
                        mainWindow.standbyAlertTriggered = true
                        mainWindow.wasZoomedBeforeAlert = mainWindow.isZoomed
                        mainWindow.alertMessage = mainWindow.alertStandby
                        mainWindow.alertSubMessage = "SYSTEM ZOSTANIE\nWKRÓTCE UŚPIONY"
                        mainWindow.alertColor = "#ffaa00"
                        // mainWindow.alertIconSource = ???
                        mainWindow.isAlertActive = true
                        mainWindow.isZoomed = true
                        alertTimeout.restart()
                    }
                } else {
                    mainWindow.standbyAlertTriggered = false
                    if (mainWindow.alertMessage === mainWindow.alertStandby) {
                        mainWindow.isAlertActive = false
                        mainWindow.isZoomed = mainWindow.wasZoomedBeforeAlert
                        alertTimeout.stop()
                    }
                }
            }
        }
    }

    property int centerMode: 0
    readonly property var modeNames: ["OSIĄGI", "SILNIK", "TRIP", "TURBO", "INSPEKCJA", "PARK", "OPONY", "USTAWIENIA"]

    /*
    readonly property var allModesDefintion: [
    { id: 0, name: "OSIĄGI" },
    { id: 1, name: "SILNIK" },
    { id: 2, name: "TRIP" },
    { id: 3, name: "TURBO" },
    { id: 4, name: "INSPEKCJA" },
    { id: 5, name: "PARK", conditional: true },
    { id: 6, name: "OPONY" },
    { id: 7, name: "USTAWIENIA" }
    ]

    readonly property var availableModes: {
        var list = []
        for (var i = 0; i < allModesDefintion.length; i++) {
            var m = allModesDefintion
        }
    }
    */

    onCenterModeChanged: {
        if (centerMode !== 7) {
            centerDisplay.exitSubMenu();
        }
    }

    property string brightnessSetting: "100%"
    readonly property real effectiveBrightness: {
        switch (brightnessSetting) {
        case "100%": return 1.0;
        case "80%": return 0.80;
        case "60%": return 0.60;
        case "40%": return 0.40;
        default: return 1.0;
        }
    }

    Rectangle {
        id: screenDimmerOverlay
        anchors.fill: parent
        color: "black"
        z: 99999
        opacity: Math.max(0.0, Math.min(1.0, 1.0 - mainWindow.effectiveBrightness))
        visible: opacity > 0.0

        // Płynne ściemnianie i rozjaśnianie
        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
        }
    }


    // Themes
    property color electricBlue: "#00ccff"
    property color volcanoOrange: "#ef7911"
    property color redLineColor: "#ff2200"
    property string activeColorOption: "NIEBIESKI"

    property color accentColor: {
        switch (activeColorOption) {
        case "NIEBIESKI": return "#00ccff";
        case "VOLCANO": return "#ef7911";
        case "BIAŁY": return "#ffffff";
        default: return electricBlue;
        }
    }

    readonly property alias customAccentColor: mainWindow.accentColor

    property int themeMode: 0
    property bool lightTheme: themeMode === 1

    // Main



    // Test-params
    // property real rpm: 3000

    property real rpm: testMode ? 0 : canBusBackend.rpm
    property real displayedRpm: testMode ? rpm : (startupSweepActive ? sweepRpm : (rpm === 0 ? 0 : smoothedRpm))
    property real speed: testMode ? 0 : canBusBackend.speed
    Behavior on speed { SmoothedAnimation { velocity: 150; duration: 200 } }
    property string _testManualGear: "N"
    property bool manualGearOverride: false
    property string currentGear: (testMode || manualGearOverride || typeof gearReceiver === "undefined")
                                 ? _testManualGear
                                 : gearReceiver.currentGear
    property real totalMileage: canBusBackend.mileage
    property real outdoorTemp: testMode ? 0 : canBusBackend.outdoorTemp
    property int infoMode: 0
    property bool fuelAlertShownThisTrip: false

    // Engine-Mode
    property double oilTemp: testMode ? 0 : canBusBackend.oilTemp
    property double oilPress: testMode ? 0 : canBusBackend.oilPress
    property double engineTemp: testMode ? 0 : canBusBackend.engineTemp

    // Trip-Mode
    property real fuelAmount: testMode ? 0 : canBusBackend.fuelAmount
    // property real fuelAmount: 5
    property real rangeKm: testMode ? 0 : canBusBackend.rangeKm
    property real fuelReserveThreshold: 5.0
    property real maxFuelCapacity: 50

    onFuelAmountChanged: {
        if (!mainWindow.testMode) {
            if (fuelAmount <= fuelReserveThreshold && !mainWindow.fuelAlertShownThisTrip) {
                mainWindow.fuelAlertShownThisTrip = true
                mainWindow.wasZoomedBeforeAlert = mainWindow.isZoomed
                mainWindow.alertMessage = mainWindow.alertFuel
                mainWindow.alertSubMessage = "NISKI POZIOM PALIWA"
                mainWindow.alertColor = "#ffaa00"
                mainWindow.alertIconSource = "control_lights/tank_light.png"
                mainWindow.isAlertActive = true
                mainWindow.isZoomed = true
                alertTimeout.restart()
            }
            else if (fuelAmount > fuelReserveThreshold) {
                mainWindow.fuelAlertTriggered = false
                if (alertMessage === alertFuel) {
                    mainWindow.isAlertActive = false
                    mainWindow.isZoomed = mainWindow.wasZoomedBeforeAlert
                    alertTimeout.stop()
                }
            }
        }
    }

    // Turbo-Mode
    property real throttlePosition: testMode ? 0 : canBusBackend.throttle

    // Service-Mode
    property int serviceOilKm: 15000
    property int serviceBrakesKm: 30000
    property var inspectionDate: new Date(2028, 5, 1)

    readonly property int daysToInspection: {
        var now = new Date()
        var diffTime = inspectionDate.getTime() - now.getTime()
        return Math.floor(diffTime / (1000 * 60 * 60 * 24))
    }

    readonly property int oilStatus: serviceOilKm < 0 ? 2 : (serviceOilKm <= 2000 ? 1 : 0)
    readonly property int brakesStatus: serviceBrakesKm < 0 ? 2 : (serviceBrakesKm <= 2000 ? 1 : 0)
    readonly property int inspectionStatus: daysToInspection < 0 ? 2 : (daysToInspection <= 30 ? 1 : 0)

    function getServiceColor(status) {
        if (status === 2) return mainWindow.redLineColor
        if (status === 1) return "#ffaa00"
        return mainWindow.lightTheme ? "#444444" : "#ffffff"
    }

    function resetInspectionDate() {
        var currentDate = new Date()
        inspectionDate = new Date(currentDate.getFullYear() + 2, currentDate.getMonth(), 1)
    }

    function resetOilService() {
        serviceOilKm = 15000
    }

    function resetBrakesService() {
        serviceBrakesKm = 30000
    }

    property int _lastTrackedMileage: totalMileage
    onTotalMileageChanged: {
        if (_lastTrackedMileage > 0 && totalMileage > _lastTrackedMileage) {
            var diff = totalMileage - _lastTrackedMileage
            serviceOilKm -= diff
            serviceBrakesKm -= diff
        }
        _lastTrackedMileage = totalMileage
    }

    function checkStartupServiceAlert() {
        if (oilStatus === 2) {
            triggerServiceAlert("WYMIEŃ OLEJ!", (serviceOilKm) + " KM", redlineColor)
        } else if (brakesStatus === 2) {
            triggerServiceAlert("SERWIS HAMULCÓW!", (serviceBrakesKm) + " KM", redlineColor)
        } else if (inspectionStatus === 2) {
            triggerServiceAlert("PRZEGLĄD!", "MINĄŁ TERMIN", redlineColor)
        } else if (oilStatus === 1) {
            triggerServiceAlert("SERWIS OLEJOWY", "ZA " + serviceOilKm + " KM", "#ffaa00")
        } else if (brakesStatus === 1) {
            triggerServiceAlert("SERWIS HAMULCOWY", "ZA " + serviceBrakesKm + " KM", "#ffaa00")
        } else if (inspectionStatus === 1) {
            triggerServiceAlert("PRZEGLĄD", "ZA " + daysToInspection + " DNI", "#ffaa00")
        }
    }

    function triggerServiceAlert(msg, subMsg, alertCol) {
        mainWindow.wasZoomedBeforeAlert = mainWindow.isZoomed
        mainWindow.alertMessage = msg
        mainWindow.alertSubMessage = subMsg
        mainWindow.alertColor = alertCol
        mainWindow.alertIconSource = "control_lights/temp_light.png"
        mainWindow.isAlertActive = true
        mainWindow.isZoomed = true
        alertTimeout.restart()
    }

    // Settings-Mode
    property string activeLogoOption: "MINI"

    property bool isZoomed: false
    onIsZoomedChanged: {
        if (!isZoomed) {
            centerDisplay.exitSubMenu();
        } else if (centerMode !== 7) {
            centerMode = 0;
        }
    }

    // Blinkers
    property bool headlightsActive: canBusBackend.headlightsActive
    property bool leftBlinkerActive: canBusBackend.leftBlinker
    property bool rightBlinkerActive: canBusBackend.rightBlinker
    property bool blinkState: true

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
    property bool useArcInsteadOfNeedle: !centerDisplay.rpmType
    property bool gearIndicatorActive: centerDisplay.gearIndicatorActive

    // Alerts
    property string alertStandby: "TRYB UŚPIENIA"
    property string alertFuel: "REZERWA"
    property string alertOutsideTemp: "TEMPERATURA\n ZEWNĘTRZNA"
    property string alertOpenHood: "MASKA"
    property string alertOpenTrunk: "OTWARTY BAGAŻNIK"
    property string alertOpenDoor: "OTWARTE DRZWI"
    property string alertHandbrake: "RĘCZNY"
    property string alertEngineTemp: "TEMP. SILNIKA"
    property string alertOilPress: "CIŚNIENIE OLEJU"
    property string alertOilSensor: "AWARIA CZUJNIKA OLEJU"
    property string alertABS: "AWARIA ABS"
    property string alertCheckEngine: "CHECK ENGINE"

    property bool fuelAlertTriggered: false
    property bool standbyAlertTriggered: false

    property bool anyWarningActive: checkEngine || absWarning || tractionWarning || airbagWarning
    property bool isAlertActive: false
    property int _currentTestAlertIndex: 0

    property string alertMessage: ""
    property string alertSubMessage: ""
    property color alertColor: "#ffaa00"
    property string alertIconSource: ""

    Timer {
        id: startupBulbCheckTimer
        interval: 1500
        running: true
        repeat: false
        onTriggered: {
            mainWindow.isBulbCheckActive = false
            mainWindow.checkStartupServiceAlert()
        }
        Component.onCompleted: {
            mainWindow.isBulbCheckActive = true
        }
    }

    // TESTMODE
    Item {
        id: testTimer
        readonly property bool running: mainWindow.testMode

        Connections {
            target: mainWindow
            function onTestModeChanged() {
                if (mainWindow.testMode) {
                    headlightsActive = true;
                    handbrakeActive = true;
                    doorLeftOpen = true
                    doorRightOpen = true;
                    hoodOpen = true;
                    trunkOpen = true

                    sweepAnimation.stop()
                    mainWindow.startupSweepActive = false
                    mainWindow.sweepRpm = 0
                    rpmAnimation.start()
                    speedAnimation.start()
                } else {
                    headlightsActive = false;
                    handbrakeActive = false;
                    doorLeftOpen = false
                    doorRightOpen = false;
                    hoodOpen = false;
                    trunkOpen = false

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
        NumberAnimation {
            duration: mainWindow.rpm === 0 ? 150 : 100 // Szybki opad przy 0 RPM
            easing.type: mainWindow.rpm === 0 ? Easing.InQuad : Easing.OutQuad
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

        Timer {
            id: btn1LongPressTimer
            interval: 800
            repeat: false
            onTriggered: {
                if (mainWindow.isAlertActive) {
                    mainWindow.isAlertActive = false
                    mainWindow.isZoomed = mainWindow.wasZoomedBeforeAlert
                    alertTimeout.stop()
                } else {
                    mainWindow.isZoomed = !mainWindow.isZoomed
                }
            }
        }

        Timer {
            id: btn2LongPressTimer
            interval: 800
            repeat: false
            onTriggered: {
                if (mainWindow.isZoomed && mainWindow.centerMode === 7) {
                    centerDisplay.exitSubMenu()
                } else {
                    mainWindow.isZoomed = true
                    mainWindow.centerMode = 7
                }
            }
        }

        Keys.onPressed: (event) => {
                            if (event.isAutoRepeat) {
                                event.accepted = true
                                return
                            }

                            if (event.key === Qt.Key_G) {
                                mainWindow.manualGearOverride = true;
                                var gears = ["N", "1", "2", "3", "4", "5", "6", "R"]
                                var nextIndex = (gears.indexOf(mainWindow._testManualGear) + 1) % gears.length
                                mainWindow._testManualGear = gears[nextIndex]
                                event.accepted = true
                            }

                            if (event.key === Qt.Key_F) showFps = !showFps
                            if (event.key === Qt.Key_T) testMode = !testMode
                            if (event.key === Qt.Key_Tab) infoMode = (infoMode + 1) % 5

                            if (event.key === Qt.Key_J) {
                                btn1LongPressTimer.start()
                                event.accepted = true
                            } else if (event.key === Qt.Key_K) {
                                btn2LongPressTimer.start()
                                event.accepted = true
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

                                var testAlerts = [
                                    { msg: alertStandby, sub: "SYSTEM ZOSTANIE\nWKRÓTCE UŚPIONY", icon: "control_lights/tank_light.png", color: "#ffaa00" },
                                    { msg: alertFuel, sub: "POZOSTAŁO 50 KM", icon: "control_lights/tank_light.png", color: "#ffaa00" },
                                    { msg: alertOutsideTemp, sub: "-10°C", icon: "control_lights/lowtempoutside_light.png", color: "#ffaa00" },
                                    { msg: alertOpenHood, sub: "SPRAWDŹ ZAMKNIĘCIE", icon: "control_lights/hoodopen_light.png", color: "#ffaa00" },
                                    { msg: alertHandbrake, sub: "ZACIĄGNIĘTY", icon: "control_lights/handbrake_light.png", color: redLineColor },
                                    { msg: alertOpenDoor, sub: "SPRAWDŹ DRZWI", icon: "control_lights/dooropen_light.png", color: redLineColor },
                                    { msg: alertCheckEngine, sub: "SPRAWDŹ SILNIK!", icon: "control_lights/check_light.png", color: "#ffaa00" },
                                    { msg: alertEngineTemp, sub: "ZGAŚ SILNIK", icon: "control_lights/temp_light.png", color: redLineColor },
                                    { msg: alertOilPress, sub: "WYŁĄCZ SILNIK!", icon: "control_lights/oil_light.png", color: redLineColor },
                                    { msg: alertABS, sub: "JEDŹ OSTROŻNIE!", icon: "control_lights/abs_light.png", color: redLineColor }
                                ]

                                if (!isAlertActive) {
                                    mainWindow._currentTestAlertIndex=0
                                } else {
                                    mainWindow._currentTestAlertIndex = (mainWindow._currentTestAlertIndex + 1) % (testAlerts.length + 1)
                                }

                                if (mainWindow._currentTestAlertIndex < testAlerts.length) {
                                    var current = testAlerts[mainWindow._currentTestAlertIndex]
                                    if (!isAlertActive) wasZoomedBeforeAlert = isZoomed
                                    alertMessage = current.msg
                                    alertSubMessage = current.sub
                                    alertIconSource = current.icon
                                    alertColor = current.color
                                    isAlertActive = true
                                    isZoomed = true
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
                                        centerDisplay.moveUp();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Down) {
                                        centerDisplay.moveDown();
                                        event.accepted = true;
                                        return;
                                    }
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true;
                                        centerDisplay.triggerAction();
                                        return;
                                    }
                                }
                                if (centerMode !== 7 || centerDisplay.currentSubMenu === "") {
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
        Keys.onReleased: (event) => {
                             if (event.isAutoRepeat) {
                                 event.accepted = true
                                 return
                             }

                             if (event.key === Qt.Key_J) {

                                 if (btn1LongPressTimer.running) {
                                     btn1LongPressTimer.stop()

                                     if (mainWindow.isAlertActive) {
                                         mainWindow.isAlertActive = false
                                         mainWindow.isZoomed = mainWindow.wasZoomedBeforeAlert
                                         alertTimeout.stop()
                                     } else if (mainWindow.isZoomed) {
                                         if (mainWindow.centerMode === 7) {
                                             centerDisplay.triggerAction()
                                         } else {
                                             mainWindow.centerMode = (mainWindow.centerMode + 1) % 8
                                             mainWindow.selectedSettingIndex = 0
                                         }
                                     } else {
                                         mainWindow.infoMode = (mainWindow.infoMode + 1) % 5
                                     }
                                 }
                                 event.accepted = true
                             }

                             else if (event.key === Qt.Key_K) {
                                 if (btn2LongPressTimer.running) {
                                     btn2LongPressTimer.stop()

                                     if (mainWindow.isZoomed) {
                                         if (mainWindow.centerMode === 7) {
                                             centerDisplay.moveDown()
                                         } else {
                                             mainWindow.centerMode = (mainWindow.centerMode - 1 < 0) ? 7 : (mainWindow.centerMode - 1)
                                             mainWindow.selectedSettingIndex = 0
                                         }
                                     } else {
                                         mainWindow.infoMode = (mainWindow.infoMode - 1 < 0) ? 4 : (mainWindow.infoMode - 1)
                                     }
                                 }
                                 event.accepted = true
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
            visible: !mainWindow.lightTheme
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
            id: elementsLayer
            anchors.fill: parent
            opacity: 1
            z: 1

            // Normal Arc
            Canvas {
                id: staticTicksCanvas
                anchors.fill: parent;
                antialiasing: true;
                renderTarget: Canvas.Image
                visible: !mainWindow.lightTheme

                Connections {
                    target: mainWindow
                    function onLightThemeChanged() {
                        staticTicksCanvas.requestPaint()
                    }
                }

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
                        height: isMajorTick ? 50 : 18
                        y: mainWindow.lightTheme ? 8 : 17
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 1
                        antialiasing: true
                        color: {
                            if (isRedline) {
                                return mainWindow.redLineColor;
                            }
                            if (!headlightsActive) {
                                return "#474747";
                            }
                            return mainWindow.customAccentColor;
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
                        color: {
                            if (isRedline) {
                                return mainWindow.redLineColor
                            }
                            return headlightsActive ? "#ffffff" : "#474747";
                        }
                    }
                }
            }

            Canvas {
                id: rpmArcCanvas
                anchors.fill: parent;
                antialiasing: true
                opacity: (!mainWindow.lightTheme) ? 1.0 : 0.0
                visible: opacity > 0

                Connections {
                    target: mainWindow
                    enabled: rpmArcCanvas.visible
                    function onDisplayedRpmChanged() {
                        if (rpmArcCanvas.visible) rpmArcCanvas.requestPaint()
                    }
                    function onLightThemeChanged() { rpmArcCanvas.requestPaint() }
                }

                onVisibleChanged: {
                    if (visible) requestPaint()
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.imageSmoothingEnabled = false
                    ctx.mozImageSmoothingEnabled = false

                    ctx.lineWidth = 20; ctx.lineCap = "butt"
                    ctx.strokeStyle = (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive) ? mainWindow.redLineColor : mainWindow.customAccentColor
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
            id: numbersLayer
            anchors.fill: parent
            z: 5
            scale: mainWindow.isZoomed ? 0.5 : 1.0

            Repeater {
                model: 9
                Item {
                    width: 1
                    height: 1
                    anchors.centerIn: parent
                    rotation: -110 + (index * 27.5)

                    Text {
                        id: rpmDigit
                        text: index
                        y: mainWindow.isZoomed ? -573 : -295
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.family: miniFont.name
                        font.pixelSize: mainWindow.isZoomed ? 55 : 47
                        font.bold: true
                        visible: !(index === 4 && mainWindow.isZoomed && topOuterWarningLights.activeLights.length > 0)

                        renderType: Text.QtRendering
                        smooth: true
                        antialiasing: true

                        property bool isReached: mainWindow.displayedRpm >= (index * 1000)

                        style: mainWindow.lightTheme ? Text.Outline : (isReached ? Text.Outline : Text.Normal)
                        styleColor: {
                            if (mainWindow.lightTheme) {
                                return isReached ? Qt.rgba(0, 0, 0, 0.75) : Qt.rgba(0, 0, 0, 0.35);
                            }
                            return isReached ? Qt.rgba(0, 0, 0, 0.9) : "transparent";
                        }

                        color: {
                            if (index === 7 || index === 8) {
                                return isReached ? mainWindow.redLineColor : Qt.rgba(1, 0.25, 0.25, 0.85);
                            }

                            if (!headlightsActive) {
                                return mainWindow.lightTheme ? "#1b1b1b" : "#4a4a4a";
                            }
                            else {
                                return mainWindow.customAccentColor;
                            }
                        }

                        scale: isReached ? 1.22 : 1.0

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on styleColor { ColorAnimation { duration: 150 } }
                        Behavior on y { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
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
                    ctx.fillStyle = Qt.rgba(mainWindow.redLineColor.r,
                                            mainWindow.redLineColor.g,
                                            mainWindow.redLineColor.b,
                                            0.45)
                } else {
                    // W motywie jasnym stosujemy volcanoOrange, w ciemnym electricBlue (czyli mainWindow.accentColor)
                    // z dopasowanym poziomem przezroczystości (alpha)
                    ctx.fillStyle = Qt.rgba(mainWindow.accentColor.r,
                                            mainWindow.accentColor.g,
                                            mainWindow.accentColor.b,
                                            mainWindow.lightTheme ? 0.40 : 0.50)
                }

                ctx.fill()
            }

            Connections {
                target: mainWindow
                enabled: rpmArcCanvas.visible
                function onDisplayedRpmChanged() {
                    if (rpmPieArcCanvas.visible) rpmPieArcCanvas.requestPaint()
                }
                function onLightThemeChanged() {
                    if (rpmPieArcCanvas.visible) rpmPieArcCanvas.requestPaint()
                }
                function onAccentColorChanged() {
                    if (rpmPieArcCanvas.visible) rpmPieArcCanvas.requestPaint()
                }
            }
        }

        // Needle
        Item {
            id: rpmNeedleContainer
            width: 24
            height: 330
            x: 360 - width / 2
            y: 360 - height
            transformOrigin: Item.Bottom
            rotation: -110 + (displayedRpm / 8000) * 220
            visible: true

            property color needleColor: {
                if (mainWindow.displayedRpm >= 6750 && !mainWindow.startupSweepActive) {
                    return mainWindow.redLineColor;
                }
                return mainWindow.customAccentColor;
            }

            Shape {
                id: glowShape
                anchors.fill: parent
                z: 0
                antialiasing: true
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: rpmNeedleContainer.needleColor

                    startX: 12; startY: 0
                    PathLine { x: 20; y: 20 }
                    PathLine { x: 18; y: 310 }
                    PathLine { x: 6; y: 310 }
                    PathLine { x: 4; y: 20 }
                }

                layer.enabled: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    shadowEnabled: false
                    blurEnabled: true
                    blur: 0.6
                    brightness: 1.0
                    saturation: 1.5
                    colorization: 1.0
                    colorizationColor: rpmNeedleContainer.needleColor
                }
            }

            Shape {
                id: innerGlowShape
                anchors.fill: parent
                z: 0
                opacity: 0.8
                antialiasing: true
                ShapePath {
                    strokeColor: "transparent"
                    fillColor: "#ffffff"

                    startX: 12; startY: 2
                    PathLine { x: 15; y: 20 }
                    PathLine { x: 14; y: 310 }
                    PathLine { x: 10; y: 310 }
                    PathLine { x: 9; y: 20 }
                }

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.2 // Wąskie rozmycie samego środka igły
                    colorization: 1.0
                    colorizationColor: rpmNeedleContainer.needleColor
                }
            }

            // Main needle
            Shape {
                id: nativeNeedleShape
                anchors.fill: parent
                z: 1
                antialiasing: true

                ShapePath {
                    strokeColor: Qt.darker(rpmNeedleContainer.needleColor, 1.2)
                    strokeWidth: 1.0
                    joinStyle: ShapePath.MiterJoin
                    capStyle: ShapePath.RoundCap

                    fillGradient: LinearGradient {
                        y1: 0; y2: 330
                        GradientStop { position: 0.0; color: "#ffffff" }
                        GradientStop { position: 0.15; color: rpmNeedleContainer.needleColor }
                        GradientStop { position: 0.9; color: Qt.darker(rpmNeedleContainer.needleColor, 1.8) }
                    }

                    startX: 12; startY: 2
                    PathLine { x: 16; y: 20 }
                    PathLine { x: 15; y: 315 }
                    PathLine { x: 9; y: 315 }
                    PathLine { x: 8; y: 20 }
                }
                layer.enabled: true
                layer.samples: 8
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: mainWindow.lightTheme ? Qt.rgba(0,0,0, 0.6) : Qt.rgba(0,0,0, 0.9)
                    shadowBlur: 0.5
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 4
                    shadowOpacity: 0.7
                }
            }

            Item {
                width: 42
                height: 42
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -21
                z: 5

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: mainWindow.lightTheme ? "#e4e4e4" : "#141414"
                    border.width: 1
                    border.color: mainWindow.lightTheme ? "#a0a0a0" : "#2a2a2a"

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowBlur: 0.6
                        shadowOpacity: 0.8
                        shadowVerticalOffset: 3
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 26
                    height: 26
                    radius: width / 2
                    color: "transparent"
                    border.width: 2
                    border.color: rpmNeedleContainer.needleColor
                    opacity: 0.9
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: width / 2
                    color: mainWindow.lightTheme ? "#333333" : "#050505"

                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: "#ffffff"
                        opacity: 0.35
                        x: 2
                        y: 2
                    }
                }
            }
        }

        // Top Warning Lights
        Item {
            id: topOuterWarningLights; anchors.centerIn: parent; z: 30
            property real arcRadius: mainWindow.isZoomed ? (centerDisplay.width / 2 + 20) : (centerDisplay.width / 2 - 30)
            property real centerAngle: -90
            property real angleSpacing: mainWindow.isZoomed ? 12 : 30
            property var lightsModel: [
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

        // Center Display
        CenterDisplay {
            id: centerDisplay
            width: 490
            height: 490
            z: 10
            anchors.centerIn: parent
            opacity: 0
            scale: mainWindow.isZoomed ? 1.0 : 0.63

            Behavior on scale {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutQuad
                }
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
            accentColor: mainWindow.accentColor
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
                width: 60;
                height: width;
                opacity: mainWindow.checkEngine ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    id: checkIcon
                    source: "control_lights/check_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit
                }
                layer.enabled: true;
                layer.effect: MultiEffect {
                    source: checkIcon
                    shadowEnabled: true
                    shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.55) : "#ffaa00"
                    shadowBlur: mainWindow.lightTheme ? 0.2 : 0.4
                    shadowVerticalOffset: mainWindow.lightTheme ? 1 : 0
                    shadowHorizontalOffset: mainWindow.lightTheme ? 1 : 0
                    contrast: mainWindow.lightTheme ? 0.15 : 0.0
                    brightness: mainWindow.lightTheme ? -0.05 : 0.0
                }
            }
            Item {
                width: 60;
                height: width;
                opacity: mainWindow.absWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    id: absIcon
                    source: "control_lights/abs_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit } layer.enabled: true;
                layer.effect: MultiEffect {
                    source: absIcon
                    shadowEnabled: true
                    shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.55) : "#ffaa00"
                    shadowBlur: mainWindow.lightTheme ? 0.2 : 0.4
                    shadowVerticalOffset: mainWindow.lightTheme ? 1 : 0
                    shadowHorizontalOffset: mainWindow.lightTheme ? 1 : 0
                    contrast: mainWindow.lightTheme ? 0.15 : 0.0
                    brightness: mainWindow.lightTheme ? -0.05 : 0.0
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
                width: 60;
                height: width;
                opacity: mainWindow.tractionWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    id: dscLight
                    source: "control_lights/dsc_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit } layer.enabled: true;
                layer.effect: MultiEffect {
                    source: dscLight
                    shadowEnabled: true
                    shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.55) : "#ffaa00"
                    shadowBlur: mainWindow.lightTheme ? 0.2 : 0.4
                    shadowVerticalOffset: mainWindow.lightTheme ? 1 : 0
                    shadowHorizontalOffset: mainWindow.lightTheme ? 1 : 0
                    contrast: mainWindow.lightTheme ? 0.15 : 0.0
                    brightness: mainWindow.lightTheme ? -0.05 : 0.0
                }
            }
            Item {
                width: 60;
                height: width;
                opacity: mainWindow.airbagWarning ? 1.0 : 0.0;
                visible: opacity > 0;
                Image {
                    id: airbagLight
                    source: "control_lights/airbag_light.png";
                    anchors.centerIn: parent;
                    width: parent.width; height: width;
                    fillMode: Image.PreserveAspectFit
                }
                layer.enabled: true;
                layer.effect: MultiEffect {
                    source: airbagLight
                    shadowEnabled: true
                    shadowColor: mainWindow.lightTheme ? Qt.rgba(0, 0, 0, 0.55) : "#ffaa00"
                    shadowBlur: mainWindow.lightTheme ? 0.2 : 0.4
                    shadowVerticalOffset: mainWindow.lightTheme ? 1 : 0
                    shadowHorizontalOffset: mainWindow.lightTheme ? 1 : 0
                    contrast: mainWindow.lightTheme ? 0.15 : 0.0
                    brightness: mainWindow.lightTheme ? -0.05 : 0.0
                }
            }
        }
    }
}
