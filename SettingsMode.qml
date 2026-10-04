import QtQuick

ListView {
    id: settingsModeRoot
    width: 340
    height: 177
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 20
    interactive: false
    focus: false
    Keys.enabled: false
    property string currentSubMenu: ""
    property int maxItemsCount: 6
    property bool lightTheme: false
    property color electricBlue: "#00ccff"
    property color volcanoOrange: "#ef7911"
    property string fontName: "Michroma"
    property string currentTheme: lightTheme ? "JASNY" : "CIEMNY"
    property string activeColor: "NIEBIESKI"
    readonly property var colorOptions: ["NIEBIESKI", "VOLCANO", "BIAŁY"]
    property int currentColorIndex: colorOptions.indexOf(activeColor) !== -1 ? colorOptions.indexOf(activeColor) : 0
    property string activeLogo: "MINI"
    readonly property var logoOptions: ["MINI", "COOPER S", "MODERN", "BRAK"]
    property int currentLogoIndex: logoOptions.indexOf(backend.currentLogo) !== -1 ? logoOptions.indexOf(backend.currentLogo) : 0
    readonly property var brightnessOptions: ["100%", "80%", "60%", "40%"]
    property string activeBrightness: "100%"
    property int currentBrightnessIndex: brightnessOptions.indexOf(activeBrightness) !== -1 ? brightnessOptions.indexOf(activeBrightness) : 0
    property bool rpmType : true
    property bool gaugeSweepActive: true
    property bool parkingAssistant: false
    property bool turboBoostSensorActive: true
    property bool oilPressureSensorActive: true
    property bool tpmsSensorActive: false
    property bool perfShiftActive: true
    property bool gearIndicatorActive: false
    property bool showFps: false
    signal themeChanged()
    signal colorChanged(string newColor)
    signal fpsToggled()
    signal logoChanged(string newLogo)
    signal turboCalibrated()
    signal tripReset()
    signal consumptionReset()
    signal oilReset()
    signal brakesReset()
    signal inspectionReset()

    model: mainCategoriesModel
    clip: true
    spacing: 6

    onActiveLogoChanged: {
        var idx = logoOptions.indexOf(activeLogo);
        if (idx !== -1) {
            currentLogoIndex = idx;
        }
    }

    onActiveColorChanged: {
        var idx = colorOptions.indexOf(activeColor);
        if (idx !== -1) {
            currentColorIndex = idx;
        }
    }

    onActiveBrightnessChanged: {
        var idx = brightnessOptions.indexOf(activeBrightness);
        if (idx !== -1) currentBrightnessIndex = idx;
    }

    signal brightnessChanged(string newBrightness)

    function moveUp() {
        currentIndex = (currentIndex - 1 < 0) ? maxItemsCount - 1 : currentIndex - 1;
    }

    function moveDown() {
        currentIndex = (currentIndex + 1) % maxItemsCount;
    }

    function enterSubMenu(catName) {
        filteredOptionsModel.clear();
        for (var i = 0; i < allOptionsModel.count; i++) {
            if (allOptionsModel.get(i).category === catName) {
                filteredOptionsModel.append(allOptionsModel.get(i));
            }
        }

        if (filteredOptionsModel.count === 0) {
            filteredOptionsModel.append({ name: "BRAK DOSTĘPNYCH OPCJI", category: catName, type: "status", optId: "EMPTY" });
        }

        filteredOptionsModel.append({ name: "POWRÓT", category: catName, type: "back", optId: "BACK" });

        currentSubMenu = catName;
        maxItemsCount = filteredOptionsModel.count;
        currentIndex = 0;
        settingsModeRoot.model = filteredOptionsModel;
    }

    function exitSubMenu() {
        currentSubMenu = "";
        maxItemsCount = mainCategoriesModel.count;
        currentIndex = 0;
        settingsModeRoot.model = mainCategoriesModel;
    }

    ListModel {
        id: mainCategoriesModel
        // ListElement { name: "PROFILE"; sub: "PROFILES" }
        ListElement { name: "WYGLĄD"; sub: "APP" }
        ListElement { name: "DODATKI"; sub: "ADD_SYSTEMS" }
        ListElement { name: "PODRÓŻ"; sub: "DIAG" }
        ListElement { name: "SERWIS"; sub: "SERVICE" }
        ListElement { name: "SYSTEM"; sub: "SYSTEM" }
    }
    ListModel {
        id: allOptionsModel
        // Profile
        ListElement { name: "WYBIERZ"; category: "PROFILES"; type: "choice"; optId: "PROF_SELECT" }
        ListElement { name: "NOWY"; category: "PROFILES"; type: "action"; optId: "PROF_NEW" }
        ListElement { name: "USUŃ"; category: "PROFILES"; type: "action"; optId: "PROF_DELETE" }
        // Wygląd
        ListElement { name: "MOTYW"; category: "APP"; type: "choice"; optId: "APP_THEME" }
        ListElement { name: "PODŚW."; category: "APP"; type: "choice"; optId: "APP_COLOR" }
        ListElement { name: "WSK. OBROTÓW"; category: "APP"; type: "toggle"; optId: "APP_RPM_TYPE" }
        ListElement { name: "GAUGE SWEEP"; category: "APP"; type: "toggle"; optId: "APP_SWEEP" }
        ListElement { name: "LOGO"; category: "APP"; type: "choice"; optId: "APP_LOGO" }
        ListElement { name: "*ANIMACJA STARTOWA"; category: "choice"; type: "toggle"; optId: "APP_STARTUP_ANIMATION" }
        ListElement { name: "JASNOŚĆ"; category: "APP"; type: "choice"; optId: "APP_BRIGHTNESS" }
        ListElement { name: "*TRYB DZIEŃ/NOC"; category: "APP"; type: "toggle"; optId: "APP_DAYNIGHTMODE" }
        // Dodatkowe systemy
        ListElement { name: "CZUJ. BIEG"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_GEAR" }
        ListElement { name: "PARK"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_PARKASSIST" }
        ListElement { name: "CIŚN. TURBO"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_TURBO" }
        ListElement { name: "CIŚN. OLEJ"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_OIL_PRESS" }
        ListElement { name: "*TPMS"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_TPMS" }
        ListElement { name: "*PERF. SHIFT"; category: "ADD_SYSTEMS"; type: "toggle"; optId: "SYS_SHIFT" }
        // Trip
        ListElement { name: "PRĘDKOŚĆ"; category: "DIAG"; type: "toggle"; optId: "TRIP_SPEED" }
        ListElement { name: "RESET TRIP"; category: "DIAG"; type: "action"; optId: "TRIP_RESET" }
        ListElement { name: "RESET SPALANIE"; category: "DIAG"; type: "action"; optId: "TRIP_CONS" }
        // Serwis
        ListElement { name: "RESET HAMULCE"; category: "SERVICE"; type: "action"; optId: "SRV_RESET_BRAKES" }
        ListElement { name: "RESET OLEJ"; category: "SERVICE"; type: "action"; optId: "SRV_RESET_OIL" }
        ListElement { name: "RESET PRZEGLĄD"; category: "SERVICE"; type: "action"; optId: "SRV_RESET_INSP" }
        // System
        ListElement { name: "AKTUALIZACJA"; category: "SYSTEM"; type: "action"; optId: "SYS_UPDATE" }
        ListElement { name: "CAN-BUS"; category: "SYSTEM"; type: "status"; optId: "SYS_CAN_STATE" }
        ListElement { name: "*LOG CAN"; category: "SYSTEM"; type: "action"; optId: "SYS_CAN_LOG" }
        ListElement { name: "SIEĆ"; category: "SYSTEM"; type: "status"; optId: "SYS_NET_STATUS" }
        ListElement { name: "WIFI"; category: "SYSTEM"; type: "status"; optId: "SYS_WIFI_STATUS"}
        ListElement { name: "IP"; category: "SYSTEM"; type: "status"; optId: "SYS_LOCAL_IP" }
        ListElement { name: "TEMP. CPU"; category: "SYSTEM"; type: "status"; optId: "SYS_CPU_TEMP" }
        ListElement { name: "CPU LOAD"; category: "SYSTEM"; type: "status"; optId: "SYS_CPU_LOAD" }
        ListElement { name: "TEMP. GPU"; category: "SYSTEM"; type: "status"; optId: "SYS_GPU_TEMP" }
        ListElement { name: "RAM"; category: "SYSTEM"; type: "status"; optId: "SYS_RAM_USAGE" }
        ListElement { name: "PAMIĘĆ"; category: "SYSTEM"; type: "status"; optId: "SYS_STORAGE" }
        ListElement { name: "UPTIME"; category: "SYSTEM"; type: "status"; optId: "SYS_UPTIME" }
        ListElement { name: "THROTTLING"; category: "SYSTEM"; type: "status"; optId: "SYS_THROTTLE" }
        ListElement { name: "VNC"; category: "SYSTEM"; type: "toggle"; optId: "SYS_VNC_SERVER" }
        ListElement { name: "POBÓR"; category: "SYSTEM"; type: "status"; optId: "SYS_POWER_STATUS" }
        ListElement { name: "LICZNIK FPS"; category: "SYSTEM"; type: "toggle"; optId: "SYS_FPS_COUNTER" }
        ListElement { name: "*TEST MODE"; category: "SYSTEM"; type: "action"; optId: "SYS_TESTMODE" }
        ListElement { name: "RESTART DASH"; category: "SYSTEM"; type: "action"; optId: "SYS_RESTART_DASH" }
        ListElement { name: "RESTART"; category: "SYSTEM"; type: "action"; optId: "SYS_RESTART" }
        ListElement { name: "WYŁĄCZ"; category: "SYSTEM"; type: "action"; optId: "SYS_POWEROFF" }
    }
    ListModel { id: filteredOptionsModel }

    function triggerAction() {
        if (typeof SystemMonitor !== "NULL" && SystemMonitor.updateActive) {
            if (SystemMonitor.updateFailed) {
                SystemMonitor.cancelOrDismissUpdate();
            }
            return;
        }
        if (currentSubMenu === "") {
            var currentCategory = mainCategoriesModel.get(currentIndex);
            if (currentCategory && currentCategory.sub) {
                enterSubMenu(currentCategory.sub);
            }
        } else {
            var currentItem = filteredOptionsModel.get(currentIndex);
            if (!currentItem) return;
            if (currentItem.type === "back" || currentItem.optId === "BACK") {
                exitSubMenu();
                return;
            }
            switch(currentItem.optId) {
                // Wygląd
            case "APP_THEME":
                themeChanged();
                break;
            case "APP_COLOR":
                currentColorIndex = (currentColorIndex + 1) % colorOptions.length;
                colorChanged(colorOptions[currentColorIndex]);
                break;
            case "APP_RPM_TYPE":
                rpmType = !rpmType;
                break;
            case "APP_SWEEP":
                gaugeSweepActive = !gaugeSweepActive;
                break;
            case "APP_LOGO":
                currentLogoIndex = (currentLogoIndex + 1) % logoOptions.length;
                logoChanged(logoOptions[currentLogoIndex]);
                break;
            case "APP_BRIGHTNESS":
                currentBrightnessIndex = (currentBrightnessIndex + 1) % brightnessOptions.length;
                brightnessChanged(brightnessOptions[currentBrightnessIndex]);
                break;
                // System (dodatki)
            case "SYS_PARKASSIST":
                parkingAssistant = !parkingAssistant;
                break;
            case "SYS_TURBO":
                turboBoostSensorActive = !turboBoostSensorActive;
                break;
            case "SYS_OIL_PRESS":
                oilPressureSensorActive = !oilPressureSensorActive;
                break;
            case "SYS_TPMS":
                tpmsSensorActive = !tpmsSensorActive;
                break;
            case "SYS_SHIFT":
                perfShiftActive = !perfShiftActive;
                break;
            case "SYS_GEAR":
                gearIndicatorActive = !gearIndicatorActive;
                break;
                // Trip
            case "TRIP_RESET":
                tripReset();
                break;
            case "TRIP_CONS":
                consumptionReset();
                break;
                // Serwis
            case "SRV_RESET_BRAKES":
                brakesReset();
                break;
            case "SRV_RESET_OIL":
                oilReset();
                break;
            case "SRV_RESET_INSP":
                inspectionReset();
                break;
                // System
            case "SYS_UPDATE":
                if (typeof SystemMonitor !== "NULL" && !SystemMonitor.updateActive) {
                    SystemMonitor.runInteractiveUpdate();
                }
                break;
            case "SYS_FPS_COUNTER":
                showFps = !showFps;
                fpsToggled();
                break;
            case "SYS_RESTART_DASH":
                if (typeof SystemMonitor !== "NULL") SystemMonitor.restartDashService();
                break;
            case "SYS_RESTART":
                if (typeof SystemMonitor !== "NULL") SystemMonitor.rebootSystem();
                break;
            case "SYS_POWEROFF":
                if (typeof SystemMonitor !== "NULL") SystemMonitor.shutdownSystem();
                break;
            }
        }
    }

delegate: Rectangle {
    id: itemRow
    width: settingsModeRoot.width
    height: 55
    radius: 6
    property bool isSelected: index == settingsModeRoot.currentIndex
    readonly property color activeAccentColor: mainWindow.customAccentColor
    readonly property color selectedBgColor: Qt.rgba(activeAccentColor.r, activeAccentColor.g, activeAccentColor.b, settingsModeRoot.lightTheme ? 0.20 : 0.18)
    readonly property color idleBgColor: settingsModeRoot.lightTheme ? "#f0f2f5" : "#1f1f1f"
    color: isSelected ? selectedBgColor : idleBgColor
    border.width: isSelected ? 1.5 : (settingsModeRoot.lightTheme ? 1 : 0)
    border.color: isSelected ? activeAccentColor : (settingsModeRoot.lightTheme ? "#d8dce2" : "transparent")

    Text {
        visible: settingsModeRoot.currentSubMenu === ""
        text: model.name ? model.name : ""
        color: itemRow.isSelected ? itemRow.activeAccentColor : (settingsModeRoot.lightTheme ? "#1a1a1a" : "#ffffff")
        font.family: settingsModeRoot.fontName
        font.pixelSize: 22
        font.bold: true
        anchors.centerIn: parent
    }

    Item {
        visible: settingsModeRoot.currentSubMenu !== ""
        anchors.fill: parent

        Text {
            text: model.name ? model.name : ""
            color: model.type === "back" ? "#ff2200" : (itemRow.isSelected
                                                        ? (settingsModeRoot.lightTheme ? "#000000" : "#ffffff")
                                                        : (settingsModeRoot.lightTheme ? "#444444" : "#aaaaaa"))
            font.family: settingsModeRoot.fontName
            font.pixelSize: 16;
            font.bold: true

            anchors.fill: parent
            anchors.leftMargin: model.type === "back" ? 0 : 15
            anchors.rightMargin: 15

            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: model.type === "back" ? Text.AlignHCenter : Text.AlignLeft
        }

        Text {
            visible: model.type !== "back" && model.type !== undefined
            font.family: settingsModeRoot.fontName;
            font.pixelSize: 16;
            font.bold: true
            anchors.right: parent.right;
            anchors.rightMargin: 15;
            anchors.verticalCenter: parent.verticalCenter

            text: {
                if (model.type === "toggle") {
                    switch (model.optId) {
                        // Wygląd
                        case "APP_RPM_TYPE":
                        return settingsModeRoot.rpmType ? "IGŁA" : "ŁUK"
                        case "APP_SWEEP":
                        return settingsModeRoot.gaugeSweepActive ? "WŁ." : "WYŁ."
                        // System (dodatki)
                        case "SYS_PARKASSIST":
                        return settingsModeRoot.parkingAssistant ? "WŁ." : "WYŁ."
                        case "SYS_TURBO":
                        return settingsModeRoot.turboBoostSensorActive ? "WŁ." : "WYŁ."
                        case "SYS_OIL_PRESS":
                        return settingsModeRoot.oilPressureSensorActive ? "WŁ." : "WYŁ."
                        case "SYS_TPMS":
                        return settingsModeRoot.tpmsSensorActive ? "WŁ." : "WYŁ."
                        case "APP_SHIFT":
                        return settingsModeRoot.perfShiftActive ? "WŁ." : "WYŁ."
                        case "SYS_GEAR":
                        return settingsModeRoot.gearIndicatorActive ? "WŁ." : "WYŁ."
                        // System
                        case "SYS_FPS_COUNTER":
                        return settingsModeRoot.showFps ? "WŁ." : "WYŁ."
                        case "SYS_VNC_SERVER":
                        return (typeof SystemMonitor !== "NULL" && SystemMonitor.vncActive) ? "WŁ." : "WYŁ."
                        default:
                        return "WYŁ"
                    }
                }
                if (model.type === "choice") {
                    switch (model.optId) {
                        case "APP_THEME":
                        return settingsModeRoot.lightTheme ? "JASNY" : "CIEMNY"
                        case "APP_COLOR":
                        return settingsModeRoot.colorOptions[settingsModeRoot.currentColorIndex]
                        case "APP_RPM_TYPE":
                        return "IGŁA"
                        case "APP_LOGO":
                        return settingsModeRoot.logoOptions[settingsModeRoot.currentLogoIndex]
                        case "APP_STARTUP_ANIMATION":
                        return "MINI"
                        case "APP_BRIGHTNESS":
                        return settingsModeRoot.brightnessOptions[settingsModeRoot.currentBrightnessIndex]
                        default:
                        return "ZMIEŃ"
                    }
                }
                if (model.type === "status") {
                    switch (model.optId) {
                        // System
                        case "SYS_CAN_STATE":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.canStatus : "--"
                        case "SYS_NET_STATUS":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.networkStatus : "--"
                        case "SYS_WIFI_STATUS":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.wifiSSID : "--"
                        case "SYS_LOCAL_IP":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.localIP: "--"
                        case "SYS_STORAGE":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.diskSpace: "--"
                        case "SYS_CPU_TEMP":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.cpuTemp : "--"
                        case "SYS_GPU_TEMP":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.gpuTemp : "--"
                        case "SYS_CPU_LOAD":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.cpuLoad : "--"
                        case "SYS_RAM_USAGE":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.ramUsage : "--"
                        case "SYS_UPTIME":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.uptime : "--"
                        case "SYS_POWER_DRAW":
                        return typeof SystemMonitor !== "NULL" ? SystemMonitor.powerDraw : "--"
                        case "SYS_THROTTLE":
                        return typeof SystemMonitor !== "NULL" ? SystemMontor.throttling : "--"
                        default:
                        return "OK"
                    }
                }
            }
            color: {
                if (model.optId === "APP_COLOR") {
                    let currentColor = settingsModeRoot.colorOptions[settingsModeRoot.currentColorIndex]
                    if (currentColor === "VOLCANO") return mainWindow.volcanoOrange
                    if (currentColor === "NIEBIESKI") return mainWindow.electricBlue
                    if (currentColor === "BIAŁY") {
                        return settingsModeRoot.lightTheme ? "#333333": "#ffffff"
                    }
                }
                if (model.type === "toggle") {
                    return itemRow.activeAccentColor
                }
                return "#ffaa00"
            }
            style: (model.optId === "APP_COLOR" && settingsModeRoot.colorOptions[settingsModeRoot.currentColorIndex] === "BIAŁY") ? Text.Outline : Text.Normal
            styleColor: settingsModeRoot.lightTheme ? "transparent" : "#222222"
        }
    }
}
}
