import QtQuick

Item {
    id: parkModeRoot
    width: 250; height: 260
    anchors.centerIn: parent
    anchors.verticalCenterOffset: 32

    readonly property real frontLeftDist: (typeof ultrasonicBackend !== "undefined") ? ultrasonicBackend.distance : 200.0

    Image {
        id: carModelImg
        source: "assets/model_electricblue.png"
        anchors.centerIn: parent
        width: 430; height: 700
        fillMode: Image.PreserveAspectFit
    }

    Item {
        id: frontLeftSensorGroup
        anchors.horizontalCenter: carModelImg.horizontalCenter
        anchors.horizontalCenterOffset: -50
        anchors.top: carModelImg.top
        anchors.topMargin: 200
        width: 100
        height: 60
        rotation: -25

        Canvas {
            id: radarCanvas
            anchors.fill: parent
            antialiasing: true
            renderTarget: Canvas.Image
            renderStrategy: Canvas.Immediate

            // Wymuszenie odrysowania przy zmianie odległości
            Connections {
                target: parkModeRoot
                function onFrontLeftDistChanged() { radarCanvas.requestPaint(); }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var centerX = width / 2;
                var centerY = height + 15; // Oś wygięcia poniżej widoku
                var startAngle = Math.PI * 1.28;
                var endAngle = Math.PI * 1.72;

                ctx.lineWidth = 5.5;
                ctx.lineCap = "round";

                // 1. Łuk bliski (< 30 cm)
                ctx.beginPath();
                ctx.arc(centerX, centerY, 30, startAngle, endAngle);
                ctx.strokeStyle = (parkModeRoot.frontLeftDist < 30) ? "#ff2a2a" : "#22ffffff";
                ctx.stroke();

                // 2. Łuk średni (< 70 cm)
                ctx.beginPath();
                ctx.arc(centerX, centerY, 44, startAngle, endAngle);
                ctx.strokeStyle = (parkModeRoot.frontLeftDist < 30) ? "#ff2a2a" :
                                  (parkModeRoot.frontLeftDist < 70) ? "#ffaa00" : "#22ffffff";
                ctx.stroke();

                // 3. Łuk daleki (< 120 cm)
                ctx.beginPath();
                ctx.arc(centerX, centerY, 58, startAngle, endAngle);
                ctx.strokeStyle = (parkModeRoot.frontLeftDist < 30) ? "#ff2a2a" :
                                  (parkModeRoot.frontLeftDist < 70) ? "#ffaa00" :
                                  (parkModeRoot.frontLeftDist < 120) ? "#00e676" : "#22ffffff";
                ctx.stroke();
            }
        }
    }

    Text {
        anchors.bottom: frontLeftSensorGroup.top
        anchors.bottomMargin: 4
        anchors.horizontalCenter: frontLeftSensorGroup.horizontalCenter
        text: (parkModeRoot.frontLeftDist > 0 && parkModeRoot.frontLeftDist < 150)
              ? (parkModeRoot.frontLeftDist.toFixed(0) + " cm") : ""
        font.pixelSize: 13
        font.bold: true
        color: {
            if (parkModeRoot.frontLeftDist < 30) return "#ff2a2a";
            if (parkModeRoot.frontLeftDist < 70) return "#ffaa00";
            return "#00e676";
        }
    }
}
