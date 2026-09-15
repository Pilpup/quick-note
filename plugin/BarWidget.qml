import QtQuick
import QtQuick.Controls

import qs.Commons
import qs.Ui
import "../My/QuickNote"

import Quickshell
import Quickshell.Wayland

BarWidget{
    id: root
    moduleName: "my.quicknote"
    implicitWidth: Style.space(32)
    implicitHeight: barSize

    property var activeStickyNote: ({})
    property int sharedFontSize: Style.font.body + 6
    property var tabColors: ["#FF003C", "#00FF66", "#0088FF", "#FFDD00", "#D900FF", "#FF6600", "#00FFFF"]
    property int bestWpm: 0
    
    property bool isPanelOpen: popup.open
    function createStickyNote(idx) {
        return stickyFactory.createObject(root, { "bufferIndex": idx })
    }
    property var bufferHasContent: [false, false, false, false, false, false, false]

    Component.onCompleted: {
        let arr = []
        for(let i = 0; i < QuickNote.MaxBuffers; i++){
            arr.push(QuickNote.GetBufferTextAt(i).trim() !== "")
        }
        bufferHasContent = arr
    }
    function close(){
        popup.open = false
    }

    WidgetButton{
        id: button
        anchors.fill: parent
        bar: root.bar

        hasVisualContent: true

        onPressed: function(b){
            if(b === Qt.LeftButton){
                popup.open = !popup.open
            }
            else if(b === Qt.RightButton){
                let nextEmptyIdx = -1
                for(let i = 0; i < QuickNote.MaxBuffers; i++){
                    if(QuickNote.GetBufferTextAt(i).trim() === "" && !root.activeStickyNote[i]){
                        nextEmptyIdx = i
                        break
                    }
                }
                if(nextEmptyIdx === -1){
                    for(let i = 0; i < QuickNote.MaxBuffers; i++){
                        if(!root.activeStickyNote[i]){
                            nextEmptyIdx = i
                            break
                        }
                    }
                }
                if(nextEmptyIdx !== -1 && !root.activeStickyNote[nextEmptyIdx]){
                    root.activeStickyNote[nextEmptyIdx] = stickyFactory.createObject(root, { "bufferIndex": nextEmptyIdx })
                }
            }
        }

        Text{
            anchors.centerIn: parent
            text: "󰦧"
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: root.bar.foreground
        }
    }

    KeyboardPanel{
        id: popup
        anchorItem: root
        bar: root.bar
        owner: root
        contentWidth : (mainEditor && mainEditor.isTypingTestActive) ? Style.space(600) : Style.space(300)
        Behavior on contentWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        contentHeight:{
            if(mainEditor){
                return Math.max(Style.space(300), popup.fittedContentHeight(mainEditor.noteHeight))
            }
            return Style.space(300)
        }

        Row{
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: -8

            spacing: 4
            z: 10

            Repeater{
                model: QuickNote.MaxBuffers
                Item {
                    width: QuickNote.BufferIndex === index ? 16 : 8
                    height: 8
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 4
                        color: {
                            if (QuickNote.BufferIndex === index) return root.tabColors[index % root.tabColors.length];
                            if (root.bufferHasContent[index]) return Color.muted;
                            return "transparent";
                        }
                        border.color: Color.muted
                        border.width: (QuickNote.BufferIndex !== index && !root.bufferHasContent[index]) ? 1 : 0
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }
        }

        NoteEditor {
            id: mainEditor
            anchors.fill: parent
            mainWidget: root
        }
    }

    Component{
        id: stickyFactory

        FloatingWindow{
            id: stickyInstance
            property int bufferIndex: 0

            visible: true
            color: "transparent"

            title: "QuickNote Pinned"

            property int dynamicHeight: {
                if(stickyEditor){
                    return Math.min(Style.space(800), Math.max(Style.space(300), stickyEditor.noteHeight + 24))
                }
                return Style.space(300)
            }

            property int dynamicWidth: {
                if(stickyEditor && stickyEditor.isTypingTestActive) {
                    return Style.space(600)
                }
                return Style.space(300)
            }

            minimumSize: Qt.size(dynamicWidth, dynamicHeight)
            maximumSize: Qt.size(dynamicWidth, dynamicHeight)
            width: dynamicWidth
            height: dynamicHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                color: Color.popups.background
                border.color: root.tabColors[bufferIndex % root.tabColors.length]
                border.width: 2
                radius: Style.cornerRadius

                NoteEditor {
                    id: stickyEditor
                    anchors.fill: parent
                    anchors.margins: 12
                    mainWidget: root
                    tabIndex: stickyInstance.bufferIndex
                    isSticky: true
                }
            }
        }
    }
}
