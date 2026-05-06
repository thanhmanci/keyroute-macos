import AppKit

enum StatusBarIcon {
    static func make() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setStroke()
            NSColor.black.setFill()

            let keyboardRect = NSRect(x: 2.4, y: 2.6, width: 13.2, height: 8.8)
            let keyboard = NSBezierPath(roundedRect: keyboardRect, xRadius: 2.0, yRadius: 2.0)
            keyboard.lineWidth = 1.55
            keyboard.stroke()

            drawKey(x: 5.0, y: 8.1)
            drawKey(x: 8.2, y: 8.1)
            drawKey(x: 11.4, y: 8.1)
            drawSpacebar()

            let route = NSBezierPath()
            route.move(to: NSPoint(x: 4.2, y: 14.1))
            route.line(to: NSPoint(x: 13.4, y: 14.1))
            route.lineWidth = 1.55
            route.lineCapStyle = .round
            route.stroke()

            let arrowHead = NSBezierPath()
            arrowHead.move(to: NSPoint(x: 11.6, y: 16.0))
            arrowHead.line(to: NSPoint(x: 14.2, y: 14.1))
            arrowHead.line(to: NSPoint(x: 11.6, y: 12.2))
            arrowHead.lineWidth = 1.55
            arrowHead.lineCapStyle = .round
            arrowHead.lineJoinStyle = .round
            arrowHead.stroke()

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "KeyRoute"
        return image
    }

    private static func drawKey(x: CGFloat, y: CGFloat) {
        let rect = NSRect(x: x, y: y, width: 1.35, height: 1.35)
        NSBezierPath(roundedRect: rect, xRadius: 0.45, yRadius: 0.45).fill()
    }

    private static func drawSpacebar() {
        let rect = NSRect(x: 6.0, y: 5.1, width: 6.0, height: 1.25)
        NSBezierPath(roundedRect: rect, xRadius: 0.55, yRadius: 0.55).fill()
    }
}
