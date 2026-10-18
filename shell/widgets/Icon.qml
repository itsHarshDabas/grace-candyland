import QtQuick
import QtQuick.Shapes
import qs.config
import "icons.js" as Icons

// A line icon from icons.js, drawn as vector paths so it takes any color at any size.
Item {
    id: root
    property string name
    property real size: 16
    property color color: Theme.textControl

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: 1.7
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Icons.stroke[root.name] || "" }
        }
        ShapePath {
            strokeWidth: -1
            fillColor: root.color
            PathSvg { path: Icons.fill[root.name] || "" }
        }
    }
}
