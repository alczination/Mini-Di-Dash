import QtQuick
import QtQuick.Effects

Item {
    id: gaugeRoot
    width: 720
    height: 720

    // Właściwości zasilane na bieżąco z Main / C++
    property real displayedRpm: 0
    property bool startupSweepActive: true
    property bool isZoomed: false
    property bool lightTheme: false
    property color accentColor: "#00ccff"
    property color redLineColor: "#ff2200"
    property string fontName: "Michroma"
    property int activeWarningLightsCount: 0 // Powiązane ze stanem lampek z góry

    // Tło: Szachownica
    Item {
        id: checkeredFlagLayer
        anchors.fill: parent; opacity: 1; z: 0.5
        Item {
            id: checkeredPatternGrid; anchors.centerIn: parent; width: 720; height: 720
            Grid {
                columns: 8; rows: 8; spacing: 0; anchors.fill: parent
                Repeater {
                    model: 64
                    Rectangle {
                        width: checkeredPatternGrid.width / 8; height: checkeredPatternGrid.height / 8
                        color: (index + Math.floor(index/8)) % 2 === 0 ? (gaugeRoot.lightTheme ? Qt.rgba(0,0,0,0.01) : Qt.rgba(1,1,1,0.01)) : "transparent"
                    }
                }
            }
        }
    }

    // Łuk i podziałki skali obrotomierza
    Item {
        id: elementsLayer; anchors.fill: parent; z: 1

        Canvas {
            id: staticTicksCanvas
            anchors.fill: parent; antialiasing: true; renderTarget: Canvas.Image
            onPaint: {
                var ctx = getContext("2d"); ctx.reset(); ctx.imageSmoothingEnabled = false
                var centerX = 360; var centerY = 360; var radius = 334
                ctx.lineWidth = 23; ctx.lineCap = "butt"
                ctx.beginPath(); ctx.strokeStyle = gaugeRoot.lightTheme ? "#cccccc" : "#555555"
                ctx.arc(centerX, centerY, radius, 135 * Math.PI / 180, 405 * Math.PI / 180, false); ctx.stroke()
                ctx.beginPath(); ctx.strokeStyle = "#ff6600"
                ctx.arc(centerX, centerY, radius, 362.81 * Math.PI / 180, 405 * Math.PI / 180, false); ctx.stroke()
            }
        }

        Repeater {
            model: 17
            Item {
                width: 720; height: 720; anchors.centerIn: parent; z: isMajorTick ? 100 : 50
                property int realTickIndex: index * 5
                rotation: -135 + (realTickIndex * (270 / 80))
                property bool isMajorTick: realTickIndex % 10 === 0
                property bool isRedline: (realTickIndex * 100) >= 6750
                Rectangle {
                    width: isMajorTick ? 9 : 5; height: isMajorTick ? 26 : 18; y: 15
                    anchors.horizontalCenter: parent.horizontalCenter; radius: 1
                    color: isRedline ? gaugeRoot.redLineColor : (gaugeRoot.lightTheme ? "#000000" : "#ffffff")
                }
            }
        }

        // Dynamicznie rysowany pasek obrotów (Color Arc)
        Canvas {
            id: rpmArcCanvas
            anchors.fill: parent; antialiasing: true
            onPaint: {
                var ctx = getContext("2d"); ctx.reset(); ctx.imageSmoothingEnabled = false
                ctx.lineWidth = 23; ctx.lineCap = "butt"
                ctx.strokeStyle = (gaugeRoot.displayedRpm >= 6750 && !gaugeRoot.startupSweepActive) ? gaugeRoot.redLineColor : gaugeRoot.accentColor
                var startRad = 135 * Math.PI / 180
                var sweepAngle = (gaugeRoot.displayedRpm / 8000) * 270
                ctx.arc(360, 360, 334, startRad, startRad + (sweepAngle * Math.PI / 180), false); ctx.stroke()
            }

            // Przerysowanie łuku wywoływane automatycznie zmianą obrotów
            Binding { target: rpmArcCanvas; property: "requestPaintTrigger"; value: gaugeRoot.displayedRpm; onChanged: rpmArcCanvas.requestPaint() }
        }

        Text {
            text: "x1000\nRPM"; anchors.centerIn: parent
            anchors.horizontalCenterOffset: 250; anchors.verticalCenterOffset: 133
            horizontalAlignment: Text.AlignHCenter; font.family: gaugeRoot.fontName; font.pixelSize: 15; font.bold: true
            color: Qt.rgba(1, 0.2, 0.2, 0.7); lineHeight: 0.8
        }
    }

    // Cyfry na tarczy (Skalujące się przy Zoomie)
    Item {
        id: numbersLayer; anchors.fill: parent; z: 5
        scale: gaugeRoot.isZoomed ? 0.5 : 1.0
        Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

        Repeater {
            model: 9
            Item {
                width: 1; height: 1; anchors.centerIn: parent
                rotation: -135 + (index * 10 * (270 / 80))
                Text {
                    text: index; y: gaugeRoot.isZoomed ? -605 : -295
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: gaugeRoot.fontName; font.pixelSize: 49; font.bold: true
                    visible: !(index === 4 && gaugeRoot.isZoomed && gaugeRoot.activeWarningLightsCount > 0)
                    property bool isReached: gaugeRoot.displayedRpm >= (index * 1000)
                    color: {
                        if (gaugeRoot.startupSweepActive) return isReached ? (gaugeRoot.lightTheme ? "black" : "white") : (gaugeRoot.lightTheme ? "#666" : "#aaa")
                        if (gaugeRoot.displayedRpm >= 6750) return gaugeRoot.redLineColor
                        if (index >= 7) return isReached ? gaugeRoot.redLineColor : Qt.rgba(1, 0.3, 0.3, 0.8)
                        return isReached ? (gaugeRoot.lightTheme ? "black" : "white") : (gaugeRoot.lightTheme ? "#666" : "#aaa")
                    }
                    scale: isReached ? 1.15 : 1.0
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on y { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
                }
            }
        }
    }

    // Fizyczna igła (Needle) obrotomierza
    Item {
        id: gaugeLayer; anchors.fill: parent; z: 6
        Item {
            id: rpmNeedleContainer
            width: 14; height: 346; x: 360 - width / 2; y: 360 - height
            transformOrigin: Item.Bottom; rotation: -135 + (gaugeRoot.displayedRpm / 8000) * 270

            Rectangle {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width; height: parent.height - 36; radius: 6
                color: gaugeRoot.lightTheme ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.2)
                border.color: gaugeRoot.lightTheme ? "#777" : "#fff"; border.width: 2
            }
            Rectangle {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                width: 6; height: parent.height; radius: 3
                gradient: Gradient {
                    GradientStop { position: 0.0; color: gaugeRoot.displayedRpm >= 6750 ? gaugeRoot.redLineColor : gaugeRoot.accentColor }
                    GradientStop { position: 1.0; color: "#ccffff" }
                }
            }
        }
    }
}
