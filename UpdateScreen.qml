import QtQuick

Item {
    id: updateScreenRoot
    width: 340
    height: 177
    anchors.centerIn: parent
    readonly property color accentColor: mainWindow.customAccentColor
    readonly property bool isFailed: typeof SystemMonitor !== "NULL" && SystemMonitor.updateFailed
    readonly property int progressVal: typeof SystemMonitor !== "NULL" ? SystemMonitor.updateProgress : 0
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: updateScreenRoot.isFailed ? Qt.rgba(1, 0.1, 0.1, 0.12) : Qt.rgba(0, 0.8, 1, 0.08)
        border.width: 1.5
        border.color: updateScreenRoot.isFailed ? "#ff3b30" : updateScreenRoot.accentColor
    }
    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Row {
            width: parent.width
            height: 24
            spacing: 8
            Rectangle {
                width: 20
                height: 20
                radius: 4
                color: updateScreenRoot.isFailed ? "#ff3b30" : updateScreenRoot.accentColor
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: updateScreenRoot.isFailed ? "BŁĄD AKTUALIZACJI" : "AKTUALIZACJA SYSTEMU"
                    font.family: settingsModeRoot.fontName
                    font.pixelSize: 13
                    font.bold: true
                    color: updateScreenRoot.isFailed ? "#ff3b30" : "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            Text {
                width: parent.width
                height: 38
                text: typeof SystemMonitor !== "NULL" ? SystemMonitor.updateStep : "Inicjalizacja..."
                font.family: settingsModeRoot.fontName
                font.pixelSize: 11
                color: "#cccccc"
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
            Rectangle {
                width: parent.width
                height: 10
                radius: 5
                color: "#1a1f26"
                border.color: "#2c3440"
                border.width: 1
                Rectangle {
                    height: parent.height
                    radius: 5
                    width: parent.width * Math.max(0.04, Math.min(1.0, updateScreenRoot.progressVal/100.0))
                    color: updateScreenRoot.isFailed ? "#ff3b30" : updateScreenRoot.accentColor
                    Behavior on width {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                Item {
                    width: parent.width
                    height: 24
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: updateScreenRoot.progressVal + "%"
                        font.family: settingsModeRoot.fontName
                        font.pixelSize: 12
                        font.bold: true
                        color: updateScreenRoot.isFailed ? "#ff3b30" : "#ffffff"
                    }
                    Rectangle {
                        visible: updateScreenRoot.isFailed
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 80
                        height: 22
                        radius: 4
                        color: "#ff3b30"
                        Text {
                            anchors.centerIn: parent
                            text: "POWRÓT"
                            font.family: settingsModeRoot.fontName
                            font.pixelSize: 10
                            font.bold: true
                            color: "#ffffff"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (typeof SystemMonitor !== "NULL") SystemMonitor.cancelOrDismissUpdate()
                        }
                    }
                }
            }
        }
    }

}
