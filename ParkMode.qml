import QtQuick

Item {
    id: parkModeRoot
    width: 250; height: 260;
    anchors.centerIn: parent;
    anchors.verticalCenterOffset: 32

    Image {
        id: carModelImg;
        source: "assets/model_electricblue.png";
        anchors.centerIn: parent;
        width: 430; height: 700;
        fillMode: Image.PreserveAspectFit
    }
}
