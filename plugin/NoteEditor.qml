import QtQuick
import QtQuick.Controls

import qs.Commons
import qs.Ui
import "../My/QuickNote"

        Item {
    property var mainWidget

            property real noteHeight: noteInput.implicitHeight + (saveOverlay.visible ? saveOverlay.height : 0)
            property int tabIndex: QuickNote.BufferIndex
            property bool isSticky: false
            property int localFontSize: Style.font.body + 6
            property bool isPanelOpen: mainWidget ? mainWidget.isPanelOpen : false
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
                selectionColor: mainWidget.tabColors[tabIndex % mainWidget.tabColors.length]

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
                    localFontSize = mainWidget.sharedFontSize
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
                    let arr = mainWidget.bufferHasContent.slice()
                    if (arr[tabIndex] !== (text.trim() !== "")) {
                        arr[tabIndex] = (text.trim() !== "")
                        mainWidget.bufferHasContent = arr
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
                        if(!isSticky) mainWidget.sharedFontSize = localFontSize
                    }
                }
                Shortcut {
                    sequences: [StandardKey.ZoomOut]
                    onActivated: {
                        localFontSize = Math.max(8, localFontSize - 1)
                        if(!isSticky) mainWidget.sharedFontSize = localFontSize
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
                            if(mainWidget.activeStickyNote[tabIndex]){
                                mainWidget.activeStickyNote[tabIndex].destroy()
                                mainWidget.activeStickyNote[tabIndex] = null
                            }
                        }
                        else{
                            let idx = QuickNote.BufferIndex
                            if(mainWidget.activeStickyNote[idx] && mainWidget.activeStickyNote[idx].visible){
                                mainWidget.activeStickyNote[idx].destroy()
                                mainWidget.activeStickyNote[idx] = null
                            }
                            else{
                                if(mainWidget.activeStickyNote[idx]){
                                    mainWidget.activeStickyNote[idx].destroy()
                                }
                                mainWidget.activeStickyNote[idx] = stickyFactory.createObject(root, { "bufferIndex": idx })
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
                            if(mainWidget.activeStickyNote[tabIndex]){
                                mainWidget.activeStickyNote[tabIndex].destroy()
                                mainWidget.activeStickyNote[tabIndex] = null
                            }
                        }
                        else{
                            mainWidget.close()
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
                    selectionColor: mainWidget.tabColors[tabIndex % mainWidget.tabColors.length]
                    selectedTextColor: Color.background

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Color.popups.text
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (QuickNote.SaveBufferToFile(tabIndex, saveInput.text)) {
                            saveInput.text = "Saved!"
                            Qt.callLater(function(){
                                saveOverlay.visible = false
                                saveInput.text = "~/"
                                noteInput.forceActiveFocus()
                            })
                        } else {
                            saveInput.text = "Error: " + QuickNote.lastError
                        }
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
                        typingTestLoader.item.tabColor = mainWidget.tabColors[tabIndex % mainWidget.tabColors.length]
                        typingTestLoader.item.bestWpm = mainWidget.bestWpm
                        typingTestLoader.item.resetTest()
                    }
                }
            }
        }


    }
