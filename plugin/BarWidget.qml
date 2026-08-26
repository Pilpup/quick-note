import QtQuick
import QtQuick.Controls

import qs.Commons
import qs.Ui
import My.QuickNote 0.1

import Quickshell
import Quickshell.Wayland

BarWidget{
    id: root
    moduleName: "my.quicknote"
    implicitWidth: Style.space(32)
    implicitHeight: barSize

    property var activeStickyNote: ({})
    property int sharedFontSize: Style.font.body

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
        }

        Text{
            anchors.centerIn: parent 
            text: "N"
            font.pixelSize: Style.font.body
            color: root.bar.foreground
        }
    }

    KeyboardPanel{
        id: popup
        anchorItem: root
        bar: root.bar
        owner: root
        contentWidth : Style.space(300)
        contentHeight:{
            if(editorLoader.item){
                return Math.max(Style.space(300), popup.fittedContentHeight(editorLoader.item.noteHeight))
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
                model: 7
                Rectangle{
                    width: 8
                    height: 8
                    radius: 4
                    color: QuickNote.BufferIndex === index ? Color.accent : Color.muted
                }
            }
        }

        Loader{
            id: editorLoader
            anchors.fill: parent
            sourceComponent: noteEditor
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

            minimumSize: Qt.size(300, 300)
            maximumSize: Qt.size(300, 300)

            BorderSurface{
                anchors.fill: parent
                color: Color.popups.background
                borderSpec: Border.flat(Color.accent, 2)
                radius: Style.cornerRadius

                Loader{
                    anchors.fill: parent
                    anchors.margins: 12
                    sourceComponent: noteEditor
                    onLoaded: {
                        item.tabIndex = stickyInstance.bufferIndex
                        item.isSticky = true
                    }
                }
            }
        }
    }

    Component{
        id: noteEditor

        ScrollView{
            clip: true
            property real noteHeight: noteInput.implicitHeight
            property int tabIndex: QuickNote.BufferIndex
            property bool isSticky: false
            
            property int localFontSize: Style.font.body

            TextArea{
                id: noteInput
                padding: 0
                topPadding: 8
                wrapMode: Text.Wrap

                placeholderText: "Hello..."
                placeholderTextColor: Color.muted

                font.pixelSize: localFontSize
                color: Color.popups.text
                selectedTextColor: Color.background
                selectionColor: Color.accent

                background: Item {}

                Component.onCompleted: {
                    localFontSize = root.sharedFontSize
                    noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
                    if(tabIndex === QuickNote.BufferIndex){
                        noteInput.forceActiveFocus()
                    }
                }

                onTextChanged: {
                    if(noteInput.activeFocus){
                        QuickNote.SetBufferTextAt(tabIndex, text)
                    }
                }

                Connections{
                    target: QuickNote

                    function onNoteTextChanged(){
                        if(QuickNote.BufferIndex === tabIndex && !noteInput.activeFocus){
                            noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
                        }
                    }
                }

                Shortcut {
                    sequence: StandardKey.ZoomIn
                    onActivated: {
                        localFontSize = Math.min(32, localFontSize + 1)
                        if (!isSticky) root.sharedFontSize = localFontSize
                    }
                }
                Shortcut {
                    sequence: StandardKey.ZoomOut
                    onActivated: {
                        localFontSize = Math.max(8, localFontSize - 1)
                        if (!isSticky) root.sharedFontSize = localFontSize
                    }
                }
                Shortcut{
                    sequence: "Ctrl+B"
                    onActivated: {
                        QuickNote.NextBuffer()
                        if(!isSticky){
                            noteInput.text = QuickNote.GetBufferTextAt(QuickNote.BufferIndex)
                        }
                    }
                }
                Shortcut {
                    sequence: "Ctrl+P"
                    onActivated: {
                        let idx = QuickNote.BufferIndex
                        
                        if(root.activeStickyNote[idx] && root.activeStickyNote[idx].visible){
                            root.activeStickyNote[idx].destroy()
                            root.activeStickyNote[idx] = null
                        }else{
                            if(root.activeStickyNote[idx]){
                                root.activeStickyNote[idx].destroy()
                            }
                            root.activeStickyNote[idx] = stickyFactory.createObject(root, { "bufferIndex": idx })
                        }
                    }
                }
                Shortcut {
                    sequence: "Ctrl+R"
                    onActivated: noteInput.text = ""
                }
                Shortcut {
                    sequence: "Escape"
                    onActivated: {
                        if(tabIndex === QuickNote.BufferIndex){
                            root.close()
                        }
                        if(root.activeStickyNote[tabIndex]){
                            root.activeStickyNote[tabIndex].destroy()
                            root.activeStickyNote[tabIndex] = null
                        }
                    }
                }
            }
        }
    }
}
