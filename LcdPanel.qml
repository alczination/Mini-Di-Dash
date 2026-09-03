import QtQuick
import QtQuick.Effects

Item {
    id: lcdRoot
    width: 270
    height: isZoomed ? 50 : 115

    property bool isZoomed: false
    property bool lightTheme: false
    property int infoMode: 0
    property double outdoorTemp: 0.0
    property double fuelAmount: 0.0
    property int rangeKm: 0
    property int totalMileage: 0
    property string electricBlue: "#00ccff"
    property string volcanoOrange: "#EF7911"
    property string fontName: "Michroma"

    readonly property color currentAccent: lightTheme ? volcanoOrange : electricBlue

    Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
    Behavior on height { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

    Rectangle {
        id: lcdFrame
        anchors.fill: parent;
        radius: 32;

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0d0a08" }
            GradientStop { position: 0.65; color: "#140f0a" }
            GradientStop { position: 1.0; color: "#1c140c" }
        }

        border.color: lcdRoot.lightTheme ? "#ccc" : Qt.rgba(0, 0.8, 1, 0.3);
        border.width: 2.0;

        Behavior on radius { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: parent.radius - 2
            color: "transparent"
            clip: true
            opacity: 0.15

            Column {
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: Math.floor(lcdRoot.height / 3)
                    Rectangle {
                        width: lcdRoot.width
                        height: 1
                        color: lcdRoot.lightTheme ? lcdRoot.volcanoOrange : lcdRoot.electricBlue
                    }
                }
            }
        }

        Rectangle {
            width: parent.width - 4
            height: parent.height * 0.42
            anchors.top: parent.top
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            radius: parent.radius - 2
            opacity: 0.08
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: lcdRoot.volcanoOrange
            shadowBlur: 0.35
            shadowOpacity: 0.6
            shadowVerticalOffset: 0
            shadowHorizontalOffset: 0
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: lcdRoot.isZoomed ? 0 : 4

        Text {
            id: labelText
            anchors.horizontalCenter: parent.horizontalCenter
            font.family: lcdRoot.fontName
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 2
            color: lcdRoot.lightTheme ? lcdRoot.volcanoOrange : lcdRoot.electricBlue
            opacity: lcdRoot.isZoomed ? 0.0 : 0.95
            visible: opacity > 0

            Behavior on opacity { NumberAnimation { duration: 250 } }

            text: {
                switch (lcdRoot.infoMode) {
                case 1: return "TEMP"
                case 2: return "PALIWO"
                case 3: return "ZASIĘG"
                case 4: return "DATA"
                default: return "PRZEBIEG"
                }
            }
        }

        Text {
            id: valueText
            anchors.horizontalCenter: parent.horizontalCenter
            color: lcdRoot.lightTheme ? "#ffaa33" : "#f5f5f5"
            font.pixelSize: lcdRoot.isZoomed ? 21 : 24
            font.bold: true
            font.family: lcdRoot.fontName

            Behavior on font.pixelSize { NumberAnimation { duration: 300 } }
            Behavior on color { ColorAnimation { duration: 250 } }

            text: {
                switch (lcdRoot.infoMode) {
                case 1: return lcdRoot.outdoorTemp.toFixed(1) + "°C"
                case 2: return lcdRoot.fuelAmount.toFixed(1) + " L"
                case 3: return lcdRoot.rangeKm + " KM"
                case 4: return Qt.formatDate(new Date(), "dd.MM.yyyy")
                default: return lcdRoot.totalMileage.toLocaleString(Qt.locale("pl_PL"), 'f', 0) + " KM"
                }
            }
        }
    }
}
