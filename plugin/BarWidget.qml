import QtQuick
import QtQuick.Controls
import qs.Commons
import qs.Ui
import My.QuickNote 0.1

BarWidget{
    id: root
    moduleName: "my.quicknote"
    implicitWidth: Style.space(32)
    implicitHeight: barSize

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
        contentHeight: Math.max(Style.space(300), popup.fittedContentHeight(noteInput.implicitHeight))

        onOpenChanged: {
            if(open){
                noteInput.text = QuickNote.NoteText
                Qt.callLater(noteInput.forceActiveFocus)
            }
        }

        ScrollView{
            anchors.fill: parent
            clip: true

            TextArea{
                id: noteInput
                padding: 0
                wrapMode: Text.Wrap

                placeholderText: "Hello..."
                placeholderTextColor: Color.muted

                font.pixelSize: Style.font.body
                color: Color.popups.text
                selectedTextColor: Color.background
                selectionColor: Color.accent

                background: Item {}

                onTextChanged: {
                    QuickNote.NoteText = text
                }

                Shortcut {
                    sequence: StandardKey.ZoomIn
                    onActivated: noteInput.font.pixelSize = Math.min(32, noteInput.font.pixelSize + 1)
                }
                Shortcut {
                    sequence: StandardKey.ZoomOut
                    onActivated: noteInput.font.pixelSize = Math.max(8, noteInput.font.pixelSize - 1)
                }
                Shortcut {
                    sequence: "Ctrl+R"
                    onActivated: noteInput.text = ""
                }
                Shortcut {
                    sequence: "Escape"
                    onActivated: root.close()
                }
            }
        }
    }
}
