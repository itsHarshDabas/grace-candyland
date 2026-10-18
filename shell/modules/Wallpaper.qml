import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.config

// Default background: neutral dark with a soft glow in the accent color.
// Set `wallpaper = /path/to/image` in desktop.conf to use a picture instead.
PanelWindow {
    id: root
    required property ShellScreen modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "grace-wallpaper"
    color: Theme.desktop

    Shape {
        anchors.fill: parent
        visible: !image.visible

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width * 0.12
                centerY: root.height * 0.08
                centerRadius: root.width * 0.75
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0; color: Theme.accent.tint }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle { width: root.width; height: root.height }
        }
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: root.width * 0.92
                centerY: root.height * 0.95
                centerRadius: root.width * 0.55
                focalX: centerX
                focalY: centerY
                GradientStop { position: 0; color: "#232733" }
                GradientStop { position: 1; color: "transparent" }
            }
            PathRectangle { width: root.width; height: root.height }
        }
    }

    Image {
        id: image
        anchors.fill: parent
        source: Config.get("wallpaper", "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: status === Image.Ready
    }
}
