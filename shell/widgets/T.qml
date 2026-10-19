import QtQuick
import qs.config

Text {
    color: Theme.text
    font.family: Theme.font
    font.pixelSize: 13
    textFormat: Text.PlainText // untrusted strings (agent names, commands, notifications) must never render as markup
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
