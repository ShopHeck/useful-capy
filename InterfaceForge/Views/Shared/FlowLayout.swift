import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(proposal: proposal, subviews: subviews)
        return CGSize(
            width: proposal.width ?? rows.map(\.width).max() ?? 0,
            height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(proposal: ProposedViewSize(width: bounds.width, height: proposal.height), subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for element in row.elements {
                element.subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(element.size))
                x += element.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func rows(proposal: ProposedViewSize, subviews: Subviews) -> [FlowRow] {
        let maxWidth = proposal.width ?? 320
        var rows: [FlowRow] = []
        var current = FlowRow()

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if current.width + size.width + (current.elements.isEmpty ? 0 : spacing) > maxWidth, !current.elements.isEmpty {
                rows.append(current)
                current = FlowRow()
            }
            current.elements.append(FlowElement(subview: subview, size: size))
            current.width += size.width + (current.elements.count > 1 ? spacing : 0)
            current.height = max(current.height, size.height)
        }

        if !current.elements.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

private struct FlowRow {
    var elements: [FlowElement] = []
    var width: CGFloat = 0
    var height: CGFloat = 0
}

private struct FlowElement {
    let subview: LayoutSubview
    let size: CGSize
}
