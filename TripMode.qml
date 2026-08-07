import QtQuick
import QtQuick.Effects

Grid {
    id: tripModeRoot
    columns: 1
    columnSpacing: 8
    rowSpacing: 15

    property real fuelAmount: 0
    property real maxFuelCapacity: 50.0
    property real fuelReserveThreshold: 6.0
    property real rangeKm: 0
    property real avgConsumption: canBusBackend.avgConsumption

    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"

    anchors.centerIn: parent
    anchors.verticalCenterOffset: 25

    Behavior on opacity { NumberAnimation { duration: 400 } }
    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/avg_consumption.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: tripModeRoot.lightTheme ? "black" : "white" }
        }
        Column {
            spacing: 2;
            Text {
                text: "ŚR. SPALANIE";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: tripModeRoot.avgConsumption.toFixed(1) + " L/100km"
                color: tripModeRoot.lightTheme ? "black" : "white";
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
    Row {
        width: 300;
        spacing: 20
        Image {
            source: "control_lights/tank_light.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: tripModeRoot.lightTheme ? "black" : "white" } }
        Column {
            spacing: 2;
            Text {
                text: "ZASIĘG";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true
            }
            Text {
                text: (tripModeRoot.rangeKm < 0 ? "---" : tripModeRoot.rangeKm) + " KM"
                color: tripModeRoot.fuelAmount <= tripModeRoot.fuelReserveThreshold ? tripModeRoot.redLineColor : (tripModeRoot.lightTheme ? "black" : "white")
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
    Row {
        width: 300; spacing: 20
        Image {
            source: "control_lights/tank_light.png";
            width: 40; height: 40;
            fillMode: Image.PreserveAspectFit;
            layer.enabled: true;
            layer.effect: MultiEffect { colorization: 1.0; colorizationColor: tripModeRoot.lightTheme ? "black" : "white" } }
        Column {
            spacing: 2;
            Text {
                text: "PALIWO";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true }
            Text {
                text: tripModeRoot.fuelAmount + " L";
                color: tripModeRoot.fuelAmount <= tripModeRoot.fuelReserveThreshold ? tripModeRoot.redLineColor : (tripModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true
            }
        }
    }
}
