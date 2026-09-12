import QtQuick
import QtQuick.Controls
import QtCore

import qs.Commons
import qs.Ui

Rectangle {
    id: rootOverlay
    color: Color.popups.background
    anchors.fill: parent
    
    
    property var wordsList: ["the", "of", "to", "and", "a", "in", "is", "it", "you", "that", "he", "was", "for", "on", "are", "with", "as", "I", "his", "they", "be", "at", "one", "have", "this", "from", "or", "had", "by", "not", "word", "but", "what", "some", "we", "can", "out", "other", "were", "all", "there", "when", "up", "use", "your", "how", "said", "an", "each", "she", "which", "do", "their", "time", "if", "will", "way", "about", "many", "then", "them", "write", "would", "like", "so", "these", "her", "long", "make", "thing", "see", "him", "two", "has", "look", "more", "day", "could", "go", "come", "did", "number", "sound", "no", "most", "people", "my", "over", "know", "water", "than", "call", "first", "who", "may", "down", "side", "been", "now", "find"]
    
    property var targetWords: []
    property real startTime: 0
    property bool finished: false
    
    property int correctChars: 0
    property int totalChars: 0
    
    function resetTest() {
        targetWords = []
        for (let i = 0; i < 25; i++) {
            targetWords.push(wordsList[Math.floor(Math.random() * wordsList.length)])
        }
        hiddenInput.text = ""
        startTime = 0
        finished = false
        correctChars = 0
        totalChars = 0
        updateText()
        Qt.callLater(function() { hiddenInput.forceActiveFocus() })
    }
    
    function updateText() {
        let expected = targetWords
        let typed = hiddenInput.text.split(' ')
        let html = ""
        
        let cChars = 0
        let tChars = 0
        
        for (let i = 0; i < expected.length; i++) {
            let expectedWord = expected[i]
            let typedWord = typed[i]
            
            if (typedWord === undefined) {
                html += "<font color='" + Color.muted + "'>" + expectedWord + "</font>"
            } else {
                let maxLen = Math.max(expectedWord.length, typedWord.length)
                for (let j = 0; j < maxLen; j++) {
                    
                    if (i === typed.length - 1 && typedWord === "" && j === 0) {
                         html += "<font color='" + rootOverlay.tabColor + "'>|</font>"
                    }

                    if (j < typedWord.length && j < expectedWord.length) {
                        if (typedWord[j] === expectedWord[j]) {
                            html += "<font color='" + Color.foreground + "'>" + expectedWord[j] + "</font>"
                            cChars++
                        } else {
                            html += "<font color='#FF003C'>" + expectedWord[j] + "</font>"
                        }
                        tChars++
                    } else if (j >= expectedWord.length) {
                        html += "<font color='#FF003C'><u>" + typedWord[j] + "</u></font>"
                        tChars++
                    } else if (j >= typedWord.length) {
                        html += "<font color='" + Color.muted + "'>" + expectedWord[j] + "</font>"
                    }
                    
                    if (i === typed.length - 1 && j === typedWord.length - 1) {
                         html += "<font color='" + rootOverlay.tabColor + "'>|</font>"
                    }
                }
            }
            
            if (i < expected.length - 1) {
                 if (typedWord !== undefined && typedWord.length > 0) {
                      tChars++
                      if (typedWord === expectedWord) cChars++
                 }
                 html += " "
            }
        }
        
        correctChars = cChars
        totalChars = tChars
        displayText.text = html
        
        let lastWordComplete = false;
        if (typed.length === expected.length) {
            let lastTyped = typed[typed.length - 1];
            let lastExpected = expected[expected.length - 1];
            if (lastTyped === lastExpected) {
                lastWordComplete = true;
            }
        }
        
        if (typed.length > expected.length || lastWordComplete) {
            finishTest()
        }
    }
    
    function finishTest() {
        finished = true
        let timeElapsed = Math.max(0.001, (Date.now() - startTime) / 1000 / 60)
        let wpm = Math.round((correctChars / 5) / timeElapsed)
        let acc = Math.round((correctChars / Math.max(1, totalChars)) * 100)
        
        wpmDisplay.text = wpm.toString()
        accDisplay.text = acc + "%"
        
        if (wpm > bestWpm) {
            bestWpm = wpm
            if (typeof root !== "undefined") root.bestWpm = wpm
        }
    }
    
    Component.onCompleted: {
        resetTest()
    }
    
    property int fontSize: Style.font.body + 6
    property color tabColor: Color.accent
    property int bestWpm: 0
    
    Text {
        id: displayText
        anchors.fill: parent
        anchors.margins: 16
        wrapMode: Text.Wrap
        textFormat: Text.RichText
        font.pixelSize: rootOverlay.fontSize
        visible: !finished
    }

    Column {
        anchors.centerIn: parent
        spacing: 16
        visible: finished
        
        Text {
            text: "Test Complete!"
            font.family: Style.font.family
            font.pixelSize: rootOverlay.fontSize + 8
            font.bold: true
            color: rootOverlay.tabColor
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Row {
            spacing: 48
            anchors.horizontalCenter: parent.horizontalCenter
            
            Column {
                spacing: 4
                Text { text: "WPM"; font.family: Style.font.family; font.pixelSize: rootOverlay.fontSize - 2; color: Color.muted; anchors.horizontalCenter: parent.horizontalCenter }
                Text { id: wpmDisplay; font.family: Style.font.family; text: "0"; font.pixelSize: rootOverlay.fontSize + 16; font.bold: true; color: Color.foreground; anchors.horizontalCenter: parent.horizontalCenter }
            }
            
            Column {
                spacing: 4
                Text { text: "ACC"; font.family: Style.font.family; font.pixelSize: rootOverlay.fontSize - 2; color: Color.muted; anchors.horizontalCenter: parent.horizontalCenter }
                Text { id: accDisplay; font.family: Style.font.family; text: "0%"; font.pixelSize: rootOverlay.fontSize + 16; font.bold: true; color: Color.foreground; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
        
        Rectangle {
            width: 200
            height: 1
            color: Color.muted
            opacity: 0.3
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Row {
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter
            Text { text: "Personal Best:"; font.family: Style.font.family; font.pixelSize: rootOverlay.fontSize; color: Color.muted }
            Text { text: rootOverlay.bestWpm + " WPM"; font.family: Style.font.family; font.pixelSize: rootOverlay.fontSize; color: rootOverlay.tabColor; font.bold: true }
        }
        
        Text {
            text: "Press <font color='" + rootOverlay.tabColor + "'>Enter</font> to restart"
            font.family: Style.font.family
            font.pixelSize: rootOverlay.fontSize - 2
            color: Color.muted
            textFormat: Text.RichText
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.7
        }
    }
    
    TextInput {
        id: hiddenInput
        // Make it slightly off-screen or totally transparent instead of visible:false
        // because sometimes visible:false prevents activeFocus
        width: 1
        height: 1
        opacity: 0
        color: "transparent"
        selectionColor: "transparent"
        
        onTextChanged: {
            if (finished) return
            if (startTime === 0 && text.length > 0) {
                startTime = Date.now()
            }
            updateText()
        }
        Keys.onPressed: function(event) {
            if (finished && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                resetTest()
                event.accepted = true
            }
        }
    }
    
    MouseArea {
        anchors.fill: parent
        onClicked: hiddenInput.forceActiveFocus()
    }
}
