import QtQuick
import QtQuick.Effects

Grid {
    id: turboModeRoot
    columns: 1
    columnSpacing: 8
    rowSpacing: 15

    property bool turboBoostSensorActive: true

    property real turboBoost: 0.0
    property real throttlePosition: 0.0
    property real intakeTemp: 0.0

    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"

    anchors.centerIn: parent
    anchors.verticalCenterOffset: 25

    Row {
        visible: turboBoostSensorActive
        width: 300; spacing: 20
        Image {
            id: turboIcon;
            source: "control_lights/turbo_symbol.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: turboModeRoot.lightTheme ? "black" : "white"; brightness: 0.7 }
        }
        Column {
            spacing: 2;
            Text {
                text: "DOŁADOWANIE";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: (turboModeRoot.turboBoost >= 0 ? "+" : "") + turboModeRoot.turboBoost.toFixed(2) + " BAR";
                color: turboModeRoot.turboBoost > 1.2 ? turboModeRoot.redLineColor : (turboModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/intake_symbol.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: turboModeRoot.lightTheme ? "black" : "white"; brightness: 0.7 }
        }
        Column {
            spacing: 2;
            Text {
                text: "DOLOT";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: turboModeRoot.intakeTemp.toFixed(0) + " BAR";
                color: turboModeRoot.intakeTemp > 50 ? turboModeRoot.redLineColor : (turboModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/gas_symbol.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: turboModeRoot.lightTheme ? "black" : "white" }
        }
        Column {
            spacing: 2;
            topPadding: -2
            Item {
                width: 240; height: 22
                Text {
                    text: "GAZ";
                    color: "#888";
                    font.family: "Michroma";
                    font.pixelSize: 20;
                    font.bold: true;
                    anchors.left: parent.left;
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Math.floor(turboModeRoot.throttlePosition) + "%";
                    color: turboModeRoot.lightTheme ? "black" : "white";
                    font.family: "Michroma";
                    font.pixelSize: 20;
                    font.bold: true;
                    anchors.right: parent.right;
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                id: gasSliderBg;
                width: 240; height: 10;
                color: turboModeRoot.lightTheme ? "#e0e0e0" : "#111111";
                border.color: turboModeRoot.lightTheme ? "#bbb" : "#333";
                border.width: 1;
                radius: 3
                Rectangle { width: parent.width * (Math.max(0, Math.min(100, turboModeRoot.throttlePosition)) / 100.0); height: parent.height; radius: 2; color: turboModeRoot.throttlePosition > 85 ? turboModeRoot.redLineColor : turboModeRoot.accentColor;
                    Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutQuad } } }
            }
        }
    }
}
