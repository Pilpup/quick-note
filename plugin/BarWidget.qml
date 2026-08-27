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
    property var tabColors: ["#FF003C", "#00FF66", "#0088FF", "#FFDD00", "#D900FF", "#FF6600", "#00FFFF"]

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
                model: QuickNote.MaxBuffers
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

            property int dynamicHeight: {
                if(stickyLoader.item){
                    return Math.min(800, Math.max(300, stickyLoader.item.noteHeight + 24))
                }
                return 300
            }

            minimumSize: Qt.size(300, dynamicHeight)
            maximumSize: Qt.size(300, dynamicHeight)
            width: 300
            height: dynamicHeight

            Rectangle {
                anchors.fill: parent
                color: Color.popups.background
                border.color: root.tabColors[bufferIndex % root.tabColors.length]
                border.width: 2
                radius: Style.cornerRadius

                Loader{
                    id: stickyLoader
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
            property bool isPanelOpen: root.opened

            onIsPanelOpenChanged: {
                if (isPanelOpen && !isSticky) {
                    noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
                }
            }

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

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: {
                        let pos = noteInput.positionAt(mouseX, mouseY)
                        let txt = noteInput.text
                        let lineStart = txt.lastIndexOf('\n', pos - 1) + 1
                        let lineEnd = txt.indexOf('\n', pos)
                        if(lineEnd === -1){
                            lineEnd = txt.length
                        }
                        let line = txt.substring(lineStart, lineEnd)
                        let match = line.match(/^([\s#-]*?)\[([ xX])\]/)
                        if(match){
                            let boxStart = lineStart + match[1].length
                            let boxEnd = boxStart + 3
                            if(pos >= boxStart && pos <= boxEnd){
                                return Qt.PointingHandCursor
                            }
                        }
                        return Qt.IBeamCursor
                    }
                }

                TapHandler {
                    onTapped: function(eventPoint){
                        let pos = noteInput.positionAt(eventPoint.position.x, eventPoint.position.y)
                        let txt = noteInput.text
                        let lineStart = txt.lastIndexOf('\n', pos - 1) + 1
                        let lineEnd = txt.indexOf('\n', pos)
                        if(lineEnd === -1){
                            lineEnd = txt.length
                        }
                        let line = txt.substring(lineStart, lineEnd)
                        let match = line.match(/^([\s#-]*?)\[([ xX])\]/)
                        if(match){
                            let boxStart = lineStart + match[1].length
                            let boxEnd = boxStart + 3
                            if(pos >= boxStart && pos <= boxEnd){
                                let newChar = (match[2] === ' ' ? 'x' : ' ')
                                let newText = txt.substring(0, boxStart + 1) + newChar + txt.substring(boxStart + 2)
                                noteInput.text = newText
                                noteInput.cursorPosition = pos
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    localFontSize = root.sharedFontSize
                    noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
                    if(tabIndex === QuickNote.BufferIndex){
                        noteInput.forceActiveFocus()
                    }
                }

                onActiveFocusChanged: {
                    if(activeFocus && !isSticky){
                        let currentText = QuickNote.GetBufferTextAt(tabIndex)
                        if(noteInput.text !== currentText){
                            noteInput.text = currentText
                        }
                    }
                }

                onTextChanged: {
                    if(noteInput.activeFocus){
                        QuickNote.SetBufferTextAt(tabIndex, text)
                    }
                }

                DropArea {
                    anchors.fill: parent
                    onDropped: function(drop) {
                        if(drop.hasUrls){
                            let path = drop.urls[0].toString()
                            if(path.startsWith("file://")){
                                path = path.substring(7)
                            }
                            noteInput.insert(noteInput.cursorPosition, path)
                            drop.accept()
                        }
                    }
                }

                Shortcut {
                    sequence: StandardKey.ZoomIn
                    onActivated: {
                        localFontSize = Math.min(32, localFontSize + 1)
                        if(!isSticky) root.sharedFontSize = localFontSize
                    }
                }
                Shortcut {
                    sequence: StandardKey.ZoomOut
                    onActivated: {
                        localFontSize = Math.max(8, localFontSize - 1)
                        if(!isSticky) root.sharedFontSize = localFontSize
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
                        if(isSticky){
                            if(root.activeStickyNote[tabIndex]){
                                root.activeStickyNote[tabIndex].destroy()
                                root.activeStickyNote[tabIndex] = null
                            }
                        }
                        else{
                            let idx = QuickNote.BufferIndex
                            if(root.activeStickyNote[idx] && root.activeStickyNote[idx].visible){
                                root.activeStickyNote[idx].destroy()
                                root.activeStickyNote[idx] = null
                            }
                            else{
                                if(root.activeStickyNote[idx]){
                                    root.activeStickyNote[idx].destroy()
                                }
                                root.activeStickyNote[idx] = stickyFactory.createObject(root, { "bufferIndex": idx })
                            }
                        }
                    }
                }
                Shortcut {
                    sequence: "Ctrl+T"
                    onActivated: {
                        if(noteInput.selectedText.length > 0){
                            QuickNote.RunStringInTerminal(noteInput.selectedText)
                        }
                        else{
                            QuickNote.RunBufferInTerminal(tabIndex)
                        }
                    }
                }
                Shortcut {
                    sequence: "Ctrl+R"
                    onActivated: {
                        if(noteInput.selectedText.length > 0){
                            noteInput.remove(noteInput.selectionStart, noteInput.selectionEnd)
                        }
                        else{
                            noteInput.text = ""
                        }
                    }
                }

                Shortcut {
                    sequence: "Escape"
                    onActivated: {
                        if(isSticky){
                            if(root.activeStickyNote[tabIndex]){
                                root.activeStickyNote[tabIndex].destroy()
                                root.activeStickyNote[tabIndex] = null
                            }
                        }
                        else{
                            root.close()
                        }
                    }
            }
        }
    }
}
}
