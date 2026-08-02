import QtQuick
import QtQuick.Effects

Column {
    id: inspectionModeRoot

    property real serviceOilKm: -12000
    property real serviceBrakesKm: 1200
    property string inspectionDate: "06 / 2028"

    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"

    anchors.centerIn: parent;
    anchors.verticalCenterOffset: 25

    Grid {
        columns: 2;
        spacing: 30;
        anchors.horizontalCenter: parent.horizontalCenter
        Column {
            spacing: 8;
            Text {
                text: "OLEJ";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true;
                anchors.horizontalCenter: parent.horizontalCenter
            } Text {
                text: inspectionModeRoot.serviceOilKm + " KM";
                color: inspectionModeRoot.serviceOilKm < 500 ? inspectionModeRoot.redLineColor : (inspectionModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true;
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        Column {
            spacing: 8;
            Text {
                text: "KLOCKI HAM.";
                color: "#888";
                font.family: "Michroma";
                font.pixelSize: 20;
                font.bold: true;
                anchors.horizontalCenter: parent.horizontalCenter
            } Text {
                text: inspectionModeRoot.serviceBrakesKm + " KM";
                color: inspectionModeRoot.serviceBrakesKm < 500 ? inspectionModeRoot.redLineColor : (inspectionModeRoot.lightTheme ? "black" : "white");
                font.family: "Michroma";
                font.pixelSize: 30;
                font.bold: true;
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    Column {
        spacing: 8;
        anchors.horizontalCenter: parent.horizontalCenter;
        Text {
            text: "OGÓLNA INSPEKCJA (TÜV)";
            color: "#888";
            font.family: "Michroma";
            font.pixelSize: 20;
            font.bold: true;
            anchors.horizontalCenter: parent.horizontalCenter
        } Text {
            text: inspectionModeRoot.inspectionDate;
            color: inspectionModeRoot.lightTheme ? "black" : "white";
            font.family: "Michroma";
            font.pixelSize: 30;
            font.bold: true;
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
