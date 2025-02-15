import SwiftUI
import UIKit

public struct DynamicList<Section: Hashable, Item: Hashable>: UIViewRepresentable {

  public typealias SelectionAction = DynamicListView<Section, Item>.SelectionAction
  public typealias CellProviderContext = DynamicListView<Section, Item>.CellProviderContext

  private let layout: @MainActor () -> UICollectionViewCompositionalLayout

  private let cellProvider: (CellProviderContext) -> UICollectionViewCell

  private var selectionHandler: (@MainActor (SelectionAction) -> Void)? = nil
  private var incrementalContentLoader: (@MainActor () async throws -> Void)? = nil
  private var onLoadHandler: (@MainActor (DynamicListView<Section, Item>) -> Void)? = nil
  private let snapshot: NSDiffableDataSourceSnapshot<Section, Item>

  public init(
    snapshot: NSDiffableDataSourceSnapshot<Section, Item>,
    layout: @escaping @MainActor () -> UICollectionViewCompositionalLayout,
    cellProvider: @escaping (
      DynamicListView<Section, Item>.CellProviderContext
    ) -> UICollectionViewCell
  ) {
    self.snapshot = snapshot
    self.layout = layout
    self.cellProvider = cellProvider
  }

  public func makeUIView(context: Context) -> DynamicListView<Section, Item> {

    let listView: DynamicListView<Section, Item> = .init(layout: layout())

    listView.setUp(cellProvider: cellProvider)

    if let selectionHandler {
      listView.setSelectionHandler(selectionHandler)
    }

    if let incrementalContentLoader {
      listView.setIncrementalContentLoader(incrementalContentLoader)
    }

    listView.setContents(snapshot: snapshot)

    onLoadHandler?(listView)

    return listView
  }

  public func updateUIView(_ listView: DynamicListView<Section, Item>, context: Context) {
    listView.setContents(snapshot: snapshot)
  }

  public func selectionHandler(
    _ handler: @escaping @MainActor (DynamicListView<Section, Item>.SelectionAction) -> Void
  ) -> Self {
    var modified = self
    modified.selectionHandler = handler
    return modified
  }

  public func incrementalContentLoading(_ loader: @escaping @MainActor () async throws -> Void)
    -> Self
  {
    var modified = self
    modified.incrementalContentLoader = loader
    return modified
  }

  public func onLoad(_ handler: @escaping @MainActor (DynamicListView<Section, Item>) -> Void)
    -> Self
  {
    var modified = self
    modified.onLoadHandler = handler
    return modified
  }
}

#if DEBUG
struct DynamicList_Previews: PreviewProvider {

  enum Section: CaseIterable {
    case a
    case b
    case c
  }

  static let layout: UICollectionViewCompositionalLayout = {

    let item = NSCollectionLayoutItem(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(0.25),
        heightDimension: .estimated(100)
      )
    )

    let group = NSCollectionLayoutGroup.horizontal(
      layoutSize: NSCollectionLayoutSize(
        widthDimension: .fractionalWidth(1.0),
        heightDimension: .estimated(100)
      ),
      subitem: item,
      count: 2
    )

    group.interItemSpacing = .fixed(16)

    // Create a section using the defined group
    let section = NSCollectionLayoutSection(group: group)

    section.contentInsets = .init(top: 0, leading: 24, bottom: 0, trailing: 24)
    section.interGroupSpacing = 24

    // Create a compositional layout using the defined section
    let layout = UICollectionViewCompositionalLayout(section: section)

    return layout
  }()

  static var previews: some View {
    DynamicList<Section, String>(
      snapshot: {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.a, .b, .c])
        snapshot.appendItems(["A"], toSection: .a)
        snapshot.appendItems(["B"], toSection: .b)
        snapshot.appendItems(["C"], toSection: .c)
        return snapshot
      }(),
      layout: { Self.layout }
    ) { context in
      let cell = context.cell { _ in
        Text(context.data)
      }
      .highlightAnimation(.shrink())

      return cell
    }
    .selectionHandler { _ in

    }
    .incrementalContentLoading {

    }
    .onLoad { view in
      print(view)
    }

  }
}
#endif
