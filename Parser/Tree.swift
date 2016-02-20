import Foundation

enum TraverseMode {

    case DepthFirst
    case BreadthFirst

}

enum DumpMode {
    case Flat
    case Indent
}

class TreeNode<Value> {

    weak var parent: TreeNode?

    var childs: [TreeNode] {
        didSet {
            updateChilds()
        }
    }

    func updateChilds() {
        childs.forEach { $0.parent = self }
    }

    var value: Value

    init(_ value: Value, _ childs: [TreeNode] = []) {
        self.value = value
        self.childs = childs
        updateChilds()
    }

    var path: [TreeNode] {
        var path = [TreeNode]()
        var node = self
        while let p = node.parent {
            path.append(p)
            node = p
        }
        return path.reverse()
    }

    func traverse(mode: TraverseMode, @noescape action: (node: TreeNode<Value>) throws -> ()) rethrows {
        var fringe = [TreeNode]()

        fringe.append(self)
        while fringe.count > 0 {
            let node: TreeNode, childs: [TreeNode]
            switch mode {
                case .DepthFirst:
                    node = fringe.removeLast()
                    childs = node.childs.reverse()
                case .BreadthFirst:
                    node = fringe.removeFirst()
                    childs = node.childs
            }
            fringe.appendContentsOf(childs)
            try action(node: node)
        }
    }

    func dump(mode: DumpMode) -> String {
        var s = ""
        switch mode {
            case .Flat:
                traverse(.DepthFirst) { node in
                    let qname = (node.path.map { "\($0.value)" } + ["\(node.value)"]).joinWithSeparator("/")
                    s += qname + "\n"
                }
            case .Indent:
                traverse(.DepthFirst) { node in
                    let indent = "  "
                    s += indent.mul(node.path.count) + "\(node.value)\n"
                }
        }
        return s
    }

}
