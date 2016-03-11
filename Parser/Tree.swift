import Foundation

protocol TreeNode: class {

    weak var parent: Self? { get set }
    var children: [Self] { get set }

}

enum TraverseMode {

    case DepthFirst
    case BreadthFirst

}

extension TreeNode {

    var root: Self {
        var node = self
        while let p = node.parent {
            node = p
        }
        return node
    }

    var path: [Self] {
        var path = [Self]()
        var node = self
        while let p = node.parent {
            path.append(p)
            node = p
        }
        return path.reverse()
    }

    func updateChildren() {
        children.forEach { $0.parent = self }
    }

    func traverse(mode: TraverseMode, @noescape body: (node: Self) throws -> ()) rethrows {
        var fringe = [Self]()

        fringe.append(self)
        while fringe.count > 0 {
            let node: Self, children: [Self]
            switch mode {
                case .DepthFirst:
                    node = fringe.removeLast()
                    children = node.children.reverse()
                case .BreadthFirst:
                    node = fringe.removeFirst()
                    children = node.children
            }
            fringe.appendContentsOf(children)
            try body(node: node)
        }
    }

}

extension TreeNode where Self: CustomStringConvertible {

    func treeDescription(includePath includePath: Bool) -> String {
        var s = ""
        traverse(.DepthFirst) { node in
            if includePath {
                let qname = (node.path.map { "\($0)" } + ["\(node)"]).joinWithSeparator("/")
                s += qname + "\n"
            } else {
                let indent = "  "
                s += indent.mul(node.path.count) + "\(node)\n"
            }
        }
        return s
    }

}

final class GenericTreeNode<Value>: TreeNode, CustomStringConvertible {

    weak var parent: GenericTreeNode?

    var children: [GenericTreeNode] {
        didSet {
            updateChildren()
        }
    }

    var value: Value

    init(_ value: Value, _ children: [GenericTreeNode] = []) {
        self.value = value
        self.children = children
        updateChildren()
    }

    // MARK: - CustomStringConvertible

    var description: String {
        return (value as? CustomStringConvertible)?.description
            ?? "\(self.dynamicType)" // Fallback, close to the default behaviour.
    }

}
