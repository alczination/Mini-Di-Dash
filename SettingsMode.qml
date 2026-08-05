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
    property string fontName: "Michroma"

    property string currentTheme: lightTheme ? "JASNY" : "CIEMNY"
    property bool rpmType : true
    property bool gaugeSweepActive: true
    readonly property var logoOptions: ["MINI", "COOPER S", "MODERN", "BRAK"]
    property int currentLogoIndex: 0

    property bool parkingAssistant: false
    property bool turboBoostSensorActive: true
    property bool oilPressureSensorActive: true
    property bool tpmsSensorActive: false
    property bool perfShiftActive: true

    property bool showFps: false

    signal themeChanged()
    signal fpsToggled()
    signal turboCalibrated()
    signal tripReset()
    signal logoChanged(string newLogo)
    signal inspectionReset()

    model: mainCategoriesModel
    clip: true
    spacing: 6

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
            filteredOptionsModel.append({ name: "BRAK DOSTĘPNYCH OPCJI", category: catName, type: "status", idNum: -2 });
        }

        filteredOptionsModel.append({ name: "POWRÓT", category: catName, type: "back", idNum: -1 });

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
        ListElement { name: "SYSTEM CHECK"; sub: "DIAG" }
        ListElement { name: "SERWIS"; sub: "SERVICE" }
        ListElement { name: "SYSTEM"; sub: "SYSTEM" }
    }

    ListModel {
        id: allOptionsModel
        // Profile
        ListElement { name: "WYBIERZ"; category: "PROFILES"; type: "choice"; idNum: 0 }
        ListElement { name: "NOWY"; category: "PROFILES"; type: "action"; idNum: 1 }
        ListElement { name: "USUŃ"; category: "PROFILES"; type: "action"; idNum: 2 }
        // Wygląd
        ListElement { name: "MOTYW"; category: "APP"; type: "choice"; idNum: 3 }
        ListElement { name: "KOLOR"; category: "APP"; type: "choice"; idNum: 4 }
        ListElement { name: "WSK. OBROTÓW"; category: "APP"; type: "toggle"; idNum: 5 }
        ListElement { name: "GAUGE SWEEP"; category: "APP"; type: "toggle"; idNum: 6 }
        ListElement { name: "LOGO"; category: "APP"; type: "choice"; idNum: 7 }
        ListElement { name: "ANIMACJA STARTOWA"; category: "choice"; type: "toggle"; idNum: 8 }
        ListElement { name: "JASNOŚĆ"; category: "APP"; type: "choice"; idNum: 9 }
        // Dodatkowe systemy
        ListElement { name: "AS. PARK."; category: "ADD_SYSTEMS"; type: "toggle"; idNum: 10 }
        ListElement { name: "CIŚN. TURBO"; category: "ADD_SYSTEMS"; type: "toggle"; idNum: 11 }
        ListElement { name: "CIŚN. OLEJ"; category: "ADD_SYSTEMS"; type: "toggle"; idNum: 12 }
        ListElement { name: "TPMS"; category: "ADD_SYSTEMS"; type: "toggle"; idNum: 13 }
        ListElement { name: "PERF. SHIFT"; category: "ADD_SYSTEMS"; type: "toggle"; idNum: 14 }
        // System Check
        // ListElement { name: "ODCZYT BŁĘDÓW"; category: "DIAG"; type: "action"; idNum: 15 }
        // ListElement { name: "KASOWANIE BŁĘDÓW"; category: "DIAG"; type: "action"; idNum: 16 }
        // ListElement { name: "NAPIĘCIE AKU"; category: "DIAG"; type: "status"; idNum: 17 }
        ListElement { name: "RESET TRIP"; category: "DIAG"; type: "action"; idNum: 18 }
        // Serwis
        ListElement { name: "RESET HAMULCE"; category: "SERVICE"; type: "action"; idNum: 19 }
        ListElement { name: "RESET OLEJ"; category: "SERVICE"; type: "action"; idNum: 20 }
        ListElement { name: "RESET PRZEGLĄD"; category: "SERVICE"; type: "action"; idNum: 21 }
        ListElement { name: "RESET FILTR KAB."; category: "SERVICE"; type: "action"; idNum: 22 }
        // System
        ListElement { name: "LICZNIK FPS"; category: "SYSTEM"; type: "toggle"; idNum: 23 }
        ListElement { name: "CAN-BUS"; category: "SYSTEM"; type: "status"; idNum: 24 }
        ListElement { name: "WYŁĄCZ"; category: "SYSTEM"; type: "action"; idNum: 25 }
        ListElement { name: "RESTART"; category: "SYSTEM"; type: "action"; idNum: 26 }
    }
    ListModel { id: filteredOptionsModel }

    function triggerAction() {
        if (currentSubMenu === "") {
            var currentCategory = mainCategoriesModel.get(currentIndex);
            if (currentCategory && currentCategory.sub) {
                enterSubMenu(currentCategory.sub);
            }
        } else {
            var currentItem = filteredOptionsModel.get(currentIndex);
            if (currentItem) {
                if (currentItem.type === "back" || currentItem.idNum === -1) {
                    exitSubMenu();
                } else {
                    switch(currentItem.idNum) {
                    case 3: themeChanged(); break;
                    case 5: rpmType = !rpmType; break;
                    case 6: gaugeSweepActive = !gaugeSweepActive; break;
                    case 7:
                        currentLogoIndex = (currentLogoIndex + 1) % logoOptions.length;
                        logoChanged(logoOptions[currentLogoIndex]);
                        break;
                    case 10: parkingAssistant = !parkingAssistant; break;
                    case 11: turboBoostSensorActive = !turboBoostSensorActive; break;
                    case 12: oilPressureSensorActive = !oilPressureSensorActive; break;
                    case 13: tpmsSensorActive = !tpmsSensorActive; break;
                    case 14: perfShiftActive = !perfShiftActive; break;
                    case 18: tripReset(); break;
                    case 21: inspectionReset(); break;
                    case 23: showFps = !showFps; fpsToggled(); break;
                    case 25: currentCanFreq = (currentCanFreq === "50Hz") ? "100Hz" : "50Hz"; break;
                    }
                }
            }
        }
    }

    delegate: Rectangle {
        id: itemRow
        width: settingsModeRoot.width
        height: 55
        radius: 6

        property bool isSelected: index == settingsModeRoot.currentIndex
        color: isSelected ? Qt.rgba(0, 0.8, 1, 0.18) : (settingsModeRoot.lightTheme ? "#e8e8e8" : "#222222")
        border.color: isSelected ? settingsModeRoot.electricBlue : "transparent"
        border.width: isSelected ? 1.5 : 0

        Text {
            visible: settingsModeRoot.currentSubMenu === ""
            text: model.name ? model.name : ""
            color: itemRow.isSelected ? settingsModeRoot.electricBlue : (settingsModeRoot.lightTheme ? "black" : "white")
            font.family: settingsModeRoot.fontName
            font.pixelSize: 22;
            font.bold: true
            anchors.centerIn: parent
        }

        Item {
            visible: settingsModeRoot.currentSubMenu !== ""
            anchors.fill: parent

            Text {
                text: model.name ? model.name : ""
                color: model.type === "back" ? "#ff2200" : (settingsModeRoot.lightTheme ? "black" : "white")
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
                        switch (model.idNum) {
                        case 5: return settingsModeRoot.rpmType ? "IGŁA" : "ŁUK"
                        case 6: return settingsModeRoot.gaugeSweepActive ? "WŁ." : "WYŁ."
                        case 10: return settingsModeRoot.parkingAssistant ? "WŁ." : "WYŁ."
                        case 11: return settingsModeRoot.turboBoostSensorActive ? "WŁ." : "WYŁ."
                        case 12: return settingsModeRoot.oilPressureSensorActive ? "WŁ." : "WYŁ."
                        case 13: return settingsModeRoot.tpmsSensorActive ? "WŁ." : "WYŁ."
                        case 14: return settingsModeRoot.perfShiftActive ? "WŁ." : "WYŁ."

                        case 23: return settingsModeRoot.showFps ? "WŁ." : "WYŁ."
                        default: return "WYŁ"
                        }
                    }
                    if (model.type === "choice") {
                        if (model.idNum === 3) return settingsModeRoot.lightTheme ? "JASNY" : "CIEMNY"
                        if (model.idNum === 4) return "NIEBIESKI"
                        if (model.idNum === 5) return "IGŁA"
                        if (model.idNum === 7) return settingsModeRoot.logoOptions[settingsModeRoot.currentLogoIndex]
                        if (model.idNum === 8) return "MINI"
                        if (model.idNum === 9) return "AUTO"
                        return "ZMIEŃ"
                    }

                    if (model.type === "status") return "OK"
                    return ""
                }
                color: model.type === "toggle" ? settingsModeRoot.electricBlue : "#ffaa00"
            }
        }
    }
}

