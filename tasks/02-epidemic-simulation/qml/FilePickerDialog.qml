import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtCore
import "."

Item {
    id: dlg
    anchors.fill: parent
    visible: false
    z: 1000
    focus: true
    Keys.onReleased: (event) => {
        if (event.key === Qt.Key_Escape) {
            dlg.visible = false
        }
    }

    signal accepted(string filePath)
    property string currentPath: ""

    function open() {
        folderModel.folder = StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
        currentPath = ""
        visible = true
    }

    // dim background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.6)
        MouseArea { anchors.fill: parent; onClicked: dlg.visible = false }
    }

    // dialog box
    Rectangle {
        id: box
        anchors.centerIn: parent
        width: 640; height: 460
        radius: 10
        color: Theme.surface
        border.color: Theme.border; border.width: 1
        layer.enabled: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // title bar
            Rectangle {
                Layout.fillWidth: true; height: 48
                color: Theme.card
                radius: 10
                // cover bottom radius
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 10; color: Theme.card }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 16; spacing: 12
                    Text {
                        text: "📂"
                        font.pixelSize: 16
                    }
                    Text {
                        text: "Select graph file"
                        color: Theme.txt; font.pixelSize: 14; font.bold: true
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        width: 28; height: 28; radius: 4
                        color: closeMa.containsMouse ? Theme.danger : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: Theme.muted; font.pixelSize: 13 }
                        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dlg.visible = false }
                    }
                }
            }

            // path bar
            Rectangle {
                Layout.fillWidth: true; height: 38
                color: Theme.bg
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 14
                    spacing: 4

                    // Up button
                    Rectangle {
                        width: 28; height: 28; radius: 4
                        color: upMa.containsMouse ? Theme.card : "transparent"
                        anchors.verticalCenter: parent.verticalCenter
                        Text { anchors.centerIn: parent; text: "↑"; color: Theme.accent; font.pixelSize: 14; font.bold: true }
                        MouseArea {
                            id: upMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var cur = folderModel.folder.toString().replace("file://", "")
                                var parts = cur.split("/").filter(function(p){ return p !== "" })
                                if (parts.length > 0) {
                                    parts.pop()
                                    folderModel.folder = "file:///" + parts.join("/")
                                }
                            }
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: folderModel.folder.toString().replace("file://", "")
                        color: Theme.muted; font.pixelSize: 11
                        elide: Text.ElideLeft; width: 520
                    }
                }
            }

            // file list
            Rectangle {
                Layout.fillWidth: true; Layout.fillHeight: true
                color: Theme.bg

                FolderListModel {
                    id: folderModel
                    folder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
                    showDirsFirst: true
                    showDotAndDotDot: false
                    nameFilters: ["*.txt", "*.csv", "*"]
                }

                ListView {
                    id: fileList
                    anchors.fill: parent
                    anchors.margins: 8
                    model: folderModel
                    clip: true
                    spacing: 2

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle { radius: 3; color: Theme.border }
                    }

                    delegate: Rectangle {
                        width: fileList.width - 8
                        height: 38; radius: 6
                        color: dlg.currentPath === filePath
                            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                            : rowMa.containsMouse ? Theme.card : "transparent"
                        border.color: dlg.currentPath === filePath ? Theme.accent : "transparent"
                        border.width: 1

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left; anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                text: fileIsDir ? "📁" : "📄"
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: fileName
                                color: fileIsDir ? Theme.accent : Theme.txt
                                font.pixelSize: 13
                                font.bold: fileIsDir
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: rowMa; anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (fileIsDir) {
                                    folderModel.folder = "file://" + filePath
                                    dlg.currentPath = ""
                                } else {
                                    dlg.currentPath = filePath
                                }
                            }
                            onDoubleClicked: {
                                if (!fileIsDir && filePath !== "") {
                                    dlg.accepted(filePath)
                                    dlg.visible = false
                                }
                            }
                        }
                    }
                }
            }

            // path input + buttons
            Rectangle {
                Layout.fillWidth: true; height: 60
                color: Theme.card
                radius: 10
                Rectangle { anchors.top: parent.top; width: parent.width; height: 10; color: Theme.card }
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 12; spacing: 10

                    Rectangle {
                        Layout.fillWidth: true; height: 36; radius: 6
                        color: Theme.bg; border.color: pathField.activeFocus ? Theme.accent : Theme.border; border.width: 1

                        TextInput {
                            id: pathField
                            anchors.fill: parent; anchors.margins: 10
                            color: Theme.txt; font.pixelSize: 12
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            clip: true
                            text: dlg.currentPath
                            onTextChanged: dlg.currentPath = text
                            Text {
                                anchors.fill: parent
                                text: "File path..."
                                color: Theme.muted; font.pixelSize: 12
                                verticalAlignment: Text.AlignVCenter
                                visible: dlg.currentPath === ""
                            }
                        }
                    }

                    // Cancel
                    Rectangle {
                        width: 80; height: 36; radius: 6
                        color: cancelBtnMa.containsMouse ? Theme.card : "transparent"
                        border.color: Theme.border; border.width: 1
                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.muted; font.pixelSize: 13 }
                        MouseArea { id: cancelBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: dlg.visible = false }
                    }

                    // Open
                    Rectangle {
                        width: 80; height: 36; radius: 6
                        color: openBtnMa.containsMouse ? Theme.accent.darker(120) : Theme.accent
                        opacity: dlg.currentPath !== "" ? 1.0 : 0.4
                        Text { anchors.centerIn: parent; text: "Open"; color: Theme.txt; font.pixelSize: 13; font.bold: true }
                        MouseArea {
                            id: openBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (dlg.currentPath !== "") {
                                    dlg.accepted(dlg.currentPath)
                                    dlg.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
