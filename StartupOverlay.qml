import QtQuick 2.15

Rectangle {
    id: root
    anchors.fill: parent
    color: lightTheme ? "#bcbcbc" : "#1a1a1a"
    z: 10000
    opacity: 1.0
    visible: opacity > 0.0

    property bool lightTheme: false
    property string logoSource: ""
    property real logoWidth: 200

    signal revealStarted()
    signal startupFinished()

    Image {
        id: startupLogo
        source: root.logoSource
        anchors.centerIn: parent
        width: root.logoWidth * 1.6
        fillMode: Image.PreserveAspectFit
        opacity: 0.0
        scale: 0.7
        antialiasing: true
        smooth: true
    }

    SequentialAnimation {
        running: true

        ParallelAnimation {
            NumberAnimation { target: startupLogo; property: "opacity"; from: 0; to: 1; duration: 800; easing.type: Easing.OutCubic }
            NumberAnimation { target: startupLogo; property: "scale"; from: 0.7; to: 1.0; duration: 1200; easing.type: Easing.OutQuint }
        }

        PauseAnimation { duration: 600 }

        ScriptAction { script: root.revealStarted() }

        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 700; easing.type: Easing.InOutQuad }
            NumberAnimation { target: startupLogo; property: "scale"; to: 1.3; duration: 700; easing.type: Easing.InQuint }
        }

        ScriptAction { script: root.startupFinished() }
    }
}

