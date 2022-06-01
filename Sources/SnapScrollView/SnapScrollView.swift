import SwiftUI

public struct SnapScrollView<SelectionValue: Hashable, Content: View>: View {
    private let content: Content
    @Binding private var selection: SelectionValue
    
    @State private var rects: [SelectionValue: CGRect] = [:]
    @State private var dragOffset: CGFloat = 0
    @State private var width: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    public init(selection: Binding<SelectionValue>, content: @escaping () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    public var body: some View {
        snapScrollView
            .onChange(of: selection) { selection in
                move(to: selection)
            }
            .onPreferenceChange(WidthPreferenceKey.self) { width = $0 }
    }
}

public extension View {
    func snapScrollTag(_ value: Int) -> some View {
        self.anchorPreference(key: AnchorPreferenceKey.self, value: .bounds, transform: { [value: .init(bounds: $0)] })
    }
}

private extension SnapScrollView {
    private var innerSelection: Binding<SelectionValue> {
        Binding<SelectionValue> (
            get: { selection },
            set: {
                let previousSelection = selection
                selection = $0
                
                if previousSelection == selection {
                    move(to: selection)
                }
            }
        )
    }
    
    private var snapScrollView: some View {
        GeometryReader { proxy in
            HStack {
                content
            }
            .preference(key: WidthPreferenceKey.self, value: proxy.size.width)
            .padding(.leading, {
                guard let firstRect = rects.min(by: { $0.value.midX < $1.value.midX })?.value else {
                    return 0
                }
                return width/2 - firstRect.width/2
            }())
            .onPreferenceChange(AnchorPreferenceKey<SelectionValue>.self) { preference in
                rects = preference.reduce(into: [:]) { $0[$1.key] = proxy[$1.value.bounds] }
            }
            .offset(x: currentOffset + dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        DispatchQueue.main.async {
                            self.dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        DispatchQueue.main.async {
                            withAnimation(.spring()){
                                let predictedDragOffset = value.predictedEndTranslation.width
                                let diff = predictedDragOffset - dragOffset
                                let center = width/2
                                currentOffset += dragOffset

                                if let nextSelectedRect = rects.min(by: {
                                    abs(center - ($0.value.midX + diff)) < abs(center - ($1.value.midX + diff))
                                }) {
                                    innerSelection.wrappedValue = nextSelectedRect.key
                                }
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
    }
    
    private func move(to selection: SelectionValue) {
        rects[selection].map { rect in
            DispatchQueue.main.async {
                withAnimation(.spring()){
                    currentOffset += -rect.midX + width/2
                }
            }
        }
    }
}

private struct BoundsAnchor: Equatable {
    let bounds: Anchor<CGRect>
}

private struct AnchorPreferenceKey<T: Hashable>: PreferenceKey {
    typealias Value = [T: BoundsAnchor]
    
    static var defaultValue: Value {
        [:]
    }
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        nextValue().forEach {
            value[$0.key] = $0.value
        }
    }
}

private struct WidthPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    
    static var defaultValue: Value = 0
    
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}
