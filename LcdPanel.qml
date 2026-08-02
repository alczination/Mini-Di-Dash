import QtQuick
import QtQuick.Effects

Item {
    id: lcdRoot
    width: 270
    height: isZoomed ? 50 : 110

    property bool isZoomed: false
    property bool lightTheme: false
    property int infoMode: 0
    property double outdoorTemp: 0.0
    property double fuelAmount: 0.0
    property int rangeKm: 0
    property int totalMileage: 0
    property string electricBlue: "#00ccff"
    property string fontName: "Michroma"

    Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
    Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

    Rectangle {
        anchors.fill: parent;
        radius: 32;
        color: lcdRoot.lightTheme ? Qt.rgba(1,1,1,0.85) : Qt.rgba(0.05,0.05,0.05,0.8);
        border.color: lcdRoot.lightTheme ? "#ccc" : Qt.rgba(0, 0.8, 1, 0.3);
        border.width: 1.5;
        layer.enabled: true;
        layer.effect: MultiEffect {
            shadowEnabled: !lcdRoot.lightTheme;
            shadowColor: lcdRoot.electricBlue;
            shadowBlur: 0.2;
            opacity: 0.5
        }
    }

    Row {
        anchors.centerIn: parent;
        Text {
            font.family: lcdRoot.fontName;
            font.pixelSize: 22;
            font.bold: true;
            color: lcdRoot.electricBlue;
            bottomPadding: 47;
            opacity: lcdRoot.isZoomed ? 0 : 1;
            visible: opacity > 0;
            Behavior on opacity { NumberAnimation { duration: 300 } }
            text: lcdRoot.infoMode === 1 ? "TEMP" : lcdRoot.infoMode === 2 ? "PALIWO" : lcdRoot.infoMode === 3 ? "ZASIĘG" : lcdRoot.infoMode === 4 ? "DATA" : "PRZEBIEG"
        }
    }

    Row {
        anchors.centerIn: parent;
        Text {
            color: lcdRoot.lightTheme ? "black" : "white";
            font.pixelSize: 24;
            font.bold: true;
            font.family: lcdRoot.fontName;
            topPadding: lcdRoot.isZoomed ? 0 : 38;
            text: lcdRoot.infoMode === 1 ? lcdRoot.outdoorTemp.toFixed(1) + "°C"
                : lcdRoot.infoMode === 2 ? lcdRoot.fuelAmount.toFixed(1) + " L"
                : lcdRoot.infoMode === 3 ? lcdRoot.rangeKm + " KM"
                : lcdRoot.infoMode === 4 ? Qt.formatDate(new Date(), "dd.MM.yyyy")
                : lcdRoot.totalMileage.toLocaleString(Qt.locale("pl_PL"), 'f', 0) + " KM"
        }
    }
}
