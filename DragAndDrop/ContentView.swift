//
//  ContentView.swift
//  DragAndDrop
//
//  Created by paku on 2024/02/29.
//

import SwiftUI

class ViewModel: ObservableObject {
    @Published var items: [Item] = [
        .init(name: "A"),
        .init(name: "B"),
        .init(name: "C")
    ]
    @Published var dragItem: Item?
    @Published var selectedItem: Item?

    func onDrag(_ item: Item) -> NSItemProvider {
        guard
            let url = URL(string: item.id),
            let provider = NSItemDidEndProvider(contentsOf: url)
        else {
            return NSItemProvider()
        }

        provider.didEnd = { [weak self] in
            DispatchQueue.main.async {
                withAnimation {
                    self?.dragItem = nil
                }
            }
        }
        dragItem = item

        return provider
    }

    private class NSItemDidEndProvider: NSItemProvider {
        var didEnd: (() -> Void)?

        deinit {
            didEnd?()
        }
    }
}

struct ContentView: View {
    
    @StateObject var viewModel = ViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.items, id: \.id) { item in
                ItemView(item: item)
                .onDrag({ viewModel.onDrag(item) })
                .onDrop(of: [.url], delegate: DropTodoableDelegate(
                    item: item,
                    items: $viewModel.items,
                    dragItem: $viewModel.dragItem
                ))
            }
        }
        .padding()
    }
}

struct Item {
    var id = UUID().uuidString
    var name: String
}

struct ItemView: View {
    let item: Item

    var body: some View {
        Text(item.name)
            .font(.system(size: 25).bold())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .cornerRadius(4)
            .background(.yellow.opacity(0.8).gradient)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.yellow, lineWidth: 1)
            }
            .contentShape(Rectangle())
        
    }
}

struct DropTodoableDelegate: DropDelegate {
    let item: Item
    @Binding var items: [Item]
    @Binding var dragItem: Item?

    private var fromIndex: Array<Item>.Index {
        items.firstIndex { $0.id == dragItem?.id } ?? 0
    }

    private var toIndex: Array<Item>.Index {
        items.firstIndex { $0.id == item.id } ?? 0
    }

    private var fromOffsets: IndexSet {
        .init(integer: fromIndex)
    }

    private var toOffset: Array<Item>.Index {
        toIndex > fromIndex ? toIndex + 1 : toIndex
    }

    // MARK: - Delegate Methods

    func performDrop(info: DropInfo) -> Bool {
        withAnimation {
            dragItem = nil
        }
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return .init(operation: .move)
    }

    func dropEntered(info: DropInfo) {
        guard fromIndex != toIndex else { return }

        withAnimation {
            items.move(fromOffsets: fromOffsets, toOffset: toOffset)
        }
    }
}

#Preview {
    ContentView()
}
