import QtQuick
import QtQuick.Effects

Grid {
    id: engineModeRoot
    columns: 1
    columnSpacing: 8
    rowSpacing: 15

    property real oilTemp: 0
    property real oilPress: 0.0
    property real engineTemp: 0
    property bool oilPressureSensorActive: true

    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"

    anchors.centerIn: parent;
    anchors.verticalCenterOffset: 25

    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/oil_light.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: engineModeRoot.lightTheme ? "black" : "white" } }
        Column {
            spacing: 2;
            Text {
                text: "TEMP. OLEJU";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: engineModeRoot.oilTemp.toFixed(1) + "°C";
                color: engineModeRoot.oilTemp > 115 ? engineModeRoot.redLineColor : (engineModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
    Row {
        visible: oilPressureSensorActive
        width: visible ? 300: 0
        height: visible ? implicitHeight : 0
        spacing: 20
        Image {
            source: "control_lights/oil_light.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: engineModeRoot.lightTheme ? "black" : "white" }
        }
        Column {
            spacing: 2;
            Text {
                text: "CIŚ. OLEJU";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: engineModeRoot.oilPress.toFixed(1) + " BAR";
                color: engineModeRoot.lightTheme ? "black" : "white";
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }

    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/temp_light.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: engineModeRoot.lightTheme ? "black" : "white" } }
        Column {
            spacing: 2;
            Text {
                text: "TEMP. CHŁODNICZY";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            } Text {
                text: engineModeRoot.engineTemp.toFixed(0) + "°C";
                color: engineModeRoot.engineTemp >= 105 ? engineModeRoot.redLineColor : engineModeRoot.accentColor;
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
}
