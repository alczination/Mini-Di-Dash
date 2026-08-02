import QtQuick

Item {
    id: tiresModeRoot
    width: 380; height: 260;
    anchors.centerIn: parent;
    anchors.verticalCenterOffset: 24

    property bool tpmsSensorActive: false

    property real pressFL: 0.0
    property real pressFR: 0.0
    property real pressRL: 0.0
    property real pressRR: 0.0
    property real speedFL: 0.0
    property real speedFR: 0.0
    property real speedRL: 0.0
    property real speedRR: 0.0

    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"

    Rectangle {
        id: tpmsCar;
        anchors.centerIn: parent;
        width: 70; height: 160;
        radius: 20;
        color: "transparent";
        border.color: tiresModeRoot.lightTheme ? "#aaa" : "#444";
        border.width: 2
        Rectangle {
            x: -8; y: 25;
            width: 16; height: 35;
            radius: 4;
            color: "#333"
        }
        Rectangle {
            x: 62; y: 25;
            width: 16; height: 35;
            radius: 4;
            color: "#333"
        }
        Rectangle {
            x: -8; y: 100;
            width: 16; height: 35;
            radius: 4;
            color: "#333"
        }
        Rectangle {
            x: 62; y: 100;
            width: 16; height: 35;
            radius: 4;
            color: "#333"
        }
    }
    Column {
        anchors.right: tpmsCar.left;
        anchors.rightMargin: 20;
        anchors.top: tpmsCar.top;
        anchors.topMargin: 15;
        spacing: 2;
        Text {
            visible: tpmsSensorActive
            text: tiresModeRoot.pressFL.toFixed(1) + " BAR";
            color: tiresModeRoot.pressFL < 2.0 ? tiresModeRoot.redLineColor : (tiresModeRoot.lightTheme ? "black" : "white");
            font.family: "Michroma";
            font.pixelSize: 28;
            font.bold: true
        }
        Text {
            text: tiresModeRoot.speedFL.toFixed(0) + " KM/H";
            color: "#888";
            font.family: "Michroma";
            font.pixelSize: 25;
            font.bold: true
        }
    }
    Column {
        anchors.left: tpmsCar.right;
        anchors.leftMargin: 20;
        anchors.top: tpmsCar.top;
        anchors.topMargin: 15;
        spacing: 2;
        Text {
            visible: tpmsSensorActive
            text: tiresModeRoot.pressFR.toFixed(1) + " BAR";
            color: tiresModeRoot.pressFR < 2.0 ? tiresModeRoot.redLineColor : (tiresModeRoot.lightTheme ? "black" : "white");
            font.family: "Michroma";
            font.pixelSize: 28;
            font.bold: true
        } Text {
            text: tiresModeRoot.speedFR.toFixed(0) + " KM/H";
            color: "#888";
            font.family: "Michroma";
            font.pixelSize: 25;
            font.bold: true
        }
    }
    Column {
        anchors.right: tpmsCar.left;
        anchors.rightMargin: 20;
        anchors.bottom: tpmsCar.bottom;
        anchors.bottomMargin: 15;
        spacing: 2;
        Text {
            visible: tpmsSensorActive
            text: tiresModeRoot.pressRL.toFixed(1) + " BAR";
            color: tiresModeRoot.pressRL < 2.0 ? tiresModeRoot.redLineColor : (tiresModeRoot.lightTheme ? "black" : "white");
            font.family: "Michroma";
            font.pixelSize: 28;
            font.bold: true
        }
        Text {
            text: tiresModeRoot.speedRL.toFixed(0) + " KM/H";
            color: "#888";
            font.family: "Michroma";
            font.pixelSize: 25;
            font.bold: true
        }
    }
    Column {
        anchors.left: tpmsCar.right;
        anchors.leftMargin: 20;
        anchors.bottom: tpmsCar.bottom;
        anchors.bottomMargin: 15;
        spacing: 2;
        Text {
            visible: tpmsSensorActive
            text: tiresModeRoot.pressRR.toFixed(1) + " BAR";
            color: tiresModeRoot.pressRR < 2.0 ? tiresModeRoot.redLineColor : (tiresModeRoot.lightTheme ? "black" : "white");
            font.family: "Michroma";
            font.pixelSize: 28;
            font.bold: true
        } Text {
            text: tiresModeRoot.speedRR.toFixed(0) + " KM/H";
            color: "#888";
            font.family: "Michroma";
            font.pixelSize: 25;
            font.bold: true
        }
    }
}
