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
        contentWidth : (editorLoader.item && editorLoader.item.isTypingTestActive) ? Style.space(600) : Style.space(300)
        Behavior on contentWidth { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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
                    return Math.min(Style.space(800), Math.max(Style.space(300), stickyLoader.item.noteHeight + 24))
                }
                return Style.space(300)
            }

            property int dynamicWidth: {
                if(stickyLoader.item && stickyLoader.item.isTypingTestActive) {
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

        Item {
            property real noteHeight: noteInput.implicitHeight + (saveOverlay.visible ? saveOverlay.height : 0)
            property int tabIndex: QuickNote.BufferIndex
            property bool isSticky: false
            property int localFontSize: Style.font.body + 6
            property bool isPanelOpen: popup.open
            property bool isTypingTestActive: false
            
            function getInteractiveElementAt(pos) {
                let txt = noteInput.text
                let lineStart = txt.lastIndexOf('\n', pos - 1) + 1
                let lineEnd = txt.indexOf('\n', pos)

                if(lineEnd === -1) lineEnd = txt.length

                let line = txt.substring(lineStart, lineEnd)
                let match = line.match(/^([\s#-]*?)\[([ xX])\]/)

                if(match){
                    let boxStart = lineStart + match[1].length
                    let boxEnd = boxStart + 3
                    if(pos >= boxStart && pos <= boxEnd){
                        return { type: "checkbox", match: match, start: boxStart }
                    }
                }

                let wordStart = Math.max(txt.lastIndexOf(' ', pos - 1), txt.lastIndexOf('\n', pos - 1)) + 1
                let wordEnd = txt.indexOf(' ', pos)
                let nlEnd = txt.indexOf('\n', pos)

                if(wordEnd === -1) wordEnd = txt.length
                if(nlEnd !== -1 && nlEnd < wordEnd) wordEnd = nlEnd

                let word = txt.substring(wordStart, wordEnd).trim()
                if(word.match(/^https?:\/\//)){
                    return { type: "link", url: word }
                }

                return null
            }

            onTabIndexChanged: {
                if(noteInput) noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
            }

            onIsPanelOpenChanged: {
                if (!isPanelOpen) {
                    saveOverlay.visible = false
                }
                if (isPanelOpen && !isSticky) {
                    noteInput.text = QuickNote.GetBufferTextAt(tabIndex)
                }
            }

            ScrollView{
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: saveOverlay.visible ? saveOverlay.top : parent.bottom
                clip: true

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
                selectionColor: root.tabColors[tabIndex % root.tabColors.length]

                background: Item {}

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: {
                        let el = getInteractiveElementAt(noteInput.positionAt(mouseX, mouseY))
                        return el ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }

                TapHandler {
                    onTapped: function(eventPoint){
                        let pos = noteInput.positionAt(eventPoint.position.x, eventPoint.position.y)
                        let el = getInteractiveElementAt(pos)
                        if (el) {
                            if (el.type === "checkbox") {
                                let newChar = (el.match[2] === ' ' ? 'x' : ' ')
                                let txt = noteInput.text
                                noteInput.text = txt.substring(0, el.start + 1) + newChar + txt.substring(el.start + 2)
                                noteInput.cursorPosition = pos
                            } else if (el.type === "link") {
                                Qt.openUrlExternally(el.url)
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
                    if(activeFocus){
                        let currentText = QuickNote.GetBufferTextAt(tabIndex)
                        if(noteInput.text !== currentText){
                            noteInput.text = currentText
                        }
                    }
                }

                onTextChanged: {
                    QuickNote.SetBufferTextAt(tabIndex, text)
                    let arr = root.bufferHasContent.slice()
                    if (arr[tabIndex] !== (text.trim() !== "")) {
                        arr[tabIndex] = (text.trim() !== "")
                        root.bufferHasContent = arr
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
                        else if(drop.hasText){
                            noteInput.insert(noteInput.cursorPosition, drop.text)
                            drop.accept()
                        }
                    }
                }

                Shortcut {
                    sequences: [StandardKey.ZoomIn]
                    onActivated: {
                        localFontSize = Math.min(32, localFontSize + 1)
                        if(!isSticky) root.sharedFontSize = localFontSize
                    }
                }
                Shortcut {
                    sequences: [StandardKey.ZoomOut]
                    onActivated: {
                        localFontSize = Math.max(8, localFontSize - 1)
                        if(!isSticky) root.sharedFontSize = localFontSize
                    }
                }
                Shortcut{
                    sequence: "Ctrl+B"
                    onActivated: {
                        QuickNote.NextBuffer()
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
                        if(isTypingTestActive){
                            isTypingTestActive = false
                            hideTimer.start()
                            return
                        }
                        if(helpOverlay.visible){
                            helpOverlay.visible = false
                            noteInput.forceActiveFocus()
                            return
                        }
                        if(saveOverlay.visible){
                            saveOverlay.visible = false
                            noteInput.forceActiveFocus()
                            return
                        }
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

        Rectangle {
            id: saveOverlay
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: saveRow.implicitHeight + 16
            color: Color.popups.background
            visible: false

            Row {
                id: saveRow
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    id: saveLabel
                    text: "Save as:"
                    color: Color.popups.text
                    font.pixelSize: localFontSize
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextInput {
                    id: saveInput
                    clip: true
                    color: Color.popups.text
                    font.pixelSize: localFontSize
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - saveLabel.width - 8
                    text: "~/"
                    selectionColor: root.tabColors[tabIndex % root.tabColors.length]
                    selectedTextColor: Color.background

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Color.popups.text
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            QuickNote.SaveBufferToFile(tabIndex, saveInput.text)
                            let oldText = saveInput.text
                            saveInput.text = "Saved!"
                            Qt.callLater(function(){
                                saveOverlay.visible = false
                                saveInput.text = "~/"
                                noteInput.forceActiveFocus()
                            })
                            event.accepted = true
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+S"
            onActivated: {
                if(saveOverlay.visible){
                    saveOverlay.visible = false
                    noteInput.forceActiveFocus()
                }
                else{
                    saveOverlay.visible = true
                    saveInput.forceActiveFocus()
                    saveInput.cursorPosition = saveInput.text.length
                }
            }
        }
        Rectangle {
            id: helpOverlay
            anchors.fill: parent
            color: Color.popups.background
            visible: false

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    text: "QuickNote Shortcuts"
                    color: Color.accent
                    font.pixelSize: Style.font.body + 6
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Ctrl+P : Pin/Unpin Tab\nCtrl+B : Next Tab\nCtrl+T : Run in Terminal\nCtrl+R : Clear Note\nCtrl+S : Save to File\nCtrl+K : Typing Test\nCtrl+H : Show Help\nEscape : Close/Hide"
                    color: Color.popups.text
                    font.pixelSize: Style.font.body + 4
                    lineHeight: 1.5
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+H"
            onActivated: {
                if(helpOverlay.visible){
                    helpOverlay.visible = false
                    noteInput.forceActiveFocus()
                }
                else{
                    helpOverlay.visible = true
                }
            }
        }

        Loader {
            id: typingTestLoader
            anchors.fill: parent
            active: true
            visible: false
            source: "TypingTestOverlay.qml"
            
            Timer {
                id: hideTimer
                interval: 150
                onTriggered: {
                    typingTestLoader.visible = false
                    noteInput.forceActiveFocus()
                }
            }
        }

        Shortcut {
            sequence: "Ctrl+K"
            onActivated: {
                if(isTypingTestActive){
                    isTypingTestActive = false
                    hideTimer.start()
                }
                else{
                    isTypingTestActive = true
                    typingTestLoader.visible = true
                    if (typingTestLoader.item) {
                        typingTestLoader.item.fontSize = localFontSize
                        typingTestLoader.item.tabColor = root.tabColors[tabIndex % root.tabColors.length]
                        typingTestLoader.item.bestWpm = root.bestWpm
                        typingTestLoader.item.resetTest()
                    }
                }
            }
        }


    }
} 
}
