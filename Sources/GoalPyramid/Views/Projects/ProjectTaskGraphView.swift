import SwiftUI

/// Жоба ішіндегі тапсырмаларды орталық "жоба" түйінінен тарайтын
/// радиалды ағаш (network graph) түрінде көрсетеді.
///
/// Тарамдалу нақты дерекқор қатынасы емес (жоба тапсырмалары
/// `parentID`-сіз, тәуелсіз жазбалар) — тек period-containment бойынша
/// есептеледі: күндік тапсырма өз аптасының түйініне (ол осы жобада
/// бар болса), апта — өз айына, ай — өз жылына жалғанады; сәйкес
/// аралық түйін болмаса, тікелей орталық "жоба" түйініне қосылады.
/// Уақыты БЕЛГІЛЕНБЕГЕН (`hasDueDate == false`) тапсырмалардың
/// периодтық орны жоқ болғандықтан, олар бөлек "Уақытсыз тапсырмалар"
/// тобы (бір ғана аралық түйін) арқылы орталыққа жалғанады.
/// Осылайша граф құрамы жобаның нақты тапсырмаларына қарай өзінен-өзі
/// бейімделеді (Апталық жобада — күн/апта, Айлық жобада — апта/күн,
/// Жылдық жобада — жыл/ай/апта/күн, нақты не тіркелгеніне сай) және
/// `tasks` параметрі (SwiftData `@Query`-ден келеді) өзгерген сәтте
/// `body` қайта есептеліп, граф дереу жаңарады — қосымша синхрондау
/// коды қажет емес.
struct ProjectTaskGraphView: View {
    let project: ProjectItem
    let tasks: [GoalItem]
    var onSelect: (GoalItem) -> Void

    /// Терезе түбірінен келеді — тіл ауысқанда осы View дереу қайта
    /// салынады (толығырақ түсінік: `Localization.swift`).
    @Environment(\.appLanguage) private var language

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var dragDelta: CGSize = .zero

    /// Барлық жоба беттеріне ортақ — бір жобада жиылса, басқасында да
    /// жиылған күйде ашылады (қалауы бойынша "жалпы теңшеу" нұсқасы).
    @AppStorage(AppSettingsKey.projectTaskGraphCollapsed) private var isCollapsed = false

    private enum NodeKind {
        case center
        case undatedGroup
        /// `level == nil` — уақыты белгіленбеген жеке тапсырма.
        case task(GoalItem, level: GoalLevel?)
    }

    private final class TreeNode {
        let id: UUID
        let kind: NodeKind
        var children: [TreeNode] = []
        init(id: UUID = UUID(), kind: NodeKind) {
            self.id = id
            self.kind = kind
        }
    }

    private struct PositionedNode: Identifiable {
        let id: UUID
        let kind: NodeKind
        let point: CGPoint
    }

    private struct Edge: Identifiable {
        let id = UUID()
        let from: CGPoint
        let to: CGPoint
    }

    /// Дөңгелектердің ІШІНЕ кірмеу үшін, сызықтың екі ұшын да сол
    /// жақтағы түйіннің дәл ШЕТІНЕ дейін қысқартады (орталықтарынан
    /// емес).
    private func trimmedEdge(from: CGPoint, fromRadius: CGFloat, to: CGPoint, toRadius: CGFloat) -> Edge {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = (dx * dx + dy * dy).squareRoot()
        guard distance > 0.001 else { return Edge(from: from, to: to) }
        let ux = dx / distance
        let uy = dy / distance
        let start = CGPoint(x: from.x + ux * fromRadius, y: from.y + uy * fromRadius)
        let end = CGPoint(x: to.x - ux * toRadius, y: to.y - uy * toRadius)
        return Edge(from: start, to: end)
    }

    private var activeTasks: [GoalItem] { tasks.excludingTrashed() }
    private var datedTasks: [GoalItem] { activeTasks.filter(\.hasDueDate) }
    private var undatedTasks: [GoalItem] { activeTasks.filter { !$0.hasDueDate } }

    /// Дерек тапсырманың осы жоба ішіндегі "ата-ана" тапсырмасы.
    /// Пайдаланушы "Байланысты мақсат" арқылы НАҚТЫ таңдау жасаса
    /// (`task.parentID`), сол таңдау әрдайым басым болады. Таңдалмаса
    /// (`nil`), period-containment бойынша автоматты сәйкестік
    /// ізделеді — тек уақыты бар тапсырмалар арасында. Ешбір сәйкес
    /// аралық түйін табылмаса `nil` (орталық түйінге тікелей жалғанады).
    private func parentTask(of task: GoalItem) -> GoalItem? {
        if let parentID = task.parentID, let explicit = datedTasks.first(where: { $0.id == parentID }) {
            return explicit
        }
        switch task.level {
        case .daily:
            let weekStart = PeriodHelper.periodStart(for: .weekly, containing: task.periodStart)
            if let p = datedTasks.first(where: { $0.level == .weekly && $0.periodStart == weekStart }) { return p }
            let monthStart = PeriodHelper.periodStart(for: .monthly, containing: task.periodStart)
            if let p = datedTasks.first(where: { $0.level == .monthly && $0.periodStart == monthStart }) { return p }
            let yearStart = PeriodHelper.yearStart(PeriodHelper.year(of: task.periodStart))
            return datedTasks.first(where: { $0.level == .fiveYear && $0.periodStart == yearStart })
        case .weekly:
            let monthStart = PeriodHelper.periodStart(for: .monthly, containing: task.periodStart)
            if let p = datedTasks.first(where: { $0.level == .monthly && $0.periodStart == monthStart }) { return p }
            let yearStart = PeriodHelper.yearStart(PeriodHelper.year(of: task.periodStart))
            return datedTasks.first(where: { $0.level == .fiveYear && $0.periodStart == yearStart })
        case .monthly:
            let yearStart = PeriodHelper.yearStart(PeriodHelper.year(of: task.periodStart))
            return datedTasks.first(where: { $0.level == .fiveYear && $0.periodStart == yearStart })
        default:
            return nil
        }
    }

    private func buildTree() -> TreeNode {
        let root = TreeNode(kind: .center)

        var nodesByTaskID: [UUID: TreeNode] = [:]
        for task in datedTasks {
            nodesByTaskID[task.id] = TreeNode(id: task.id, kind: .task(task, level: task.level))
        }
        for task in datedTasks {
            guard let node = nodesByTaskID[task.id] else { continue }
            if let parent = parentTask(of: task), let parentNode = nodesByTaskID[parent.id] {
                parentNode.children.append(node)
            } else {
                root.children.append(node)
            }
        }

        if !undatedTasks.isEmpty {
            let group = TreeNode(kind: .undatedGroup)
            for task in undatedTasks {
                group.children.append(TreeNode(id: task.id, kind: .task(task, level: nil)))
            }
            root.children.append(group)
        }

        return root
    }

    /// Деңгейге қарай түйін диаметрі — талап бойынша: Жыл > Ай > Апта > Күн,
    /// ал уақытсыз тапсырма Күндікпен шамалас/одан кішірек.
    private func diameter(for kind: NodeKind) -> CGFloat {
        switch kind {
        case .center: return 45
        case .undatedGroup: return 38
        case .task(_, let level):
            switch level {
            case .fiveYear: return 54
            case .monthly: return 44
            case .weekly: return 34
            case .daily: return 24
            case nil: return 20
            default: return 24
            }
        }
    }

    /// Түйіндер арасындағы қашықтық (сызық ұзындығы) — бұрынғыдан 2 есе
    /// ұзын. Граф өзі zoom/pan болатындықтан, тереңірек деңгейлер бастапқы
    /// көрінетін canvas шегінен шығып кетуі мүмкін — бұл қалыпты, себебі
    /// пайдаланушы кішірейтіп/жылжытып толық көре алады.
    private func radius(forDepth depth: Int, canvasSize: CGSize) -> CGFloat {
        let base = min(canvasSize.width, canvasSize.height) / 2
        switch depth {
        case 1: return base * 0.84
        case 2: return base * 1.32
        case 3: return base * 1.72
        default: return base * 1.96
        }
    }

    private func layout(root: TreeNode, canvasSize: CGSize) -> (nodes: [PositionedNode], edges: [Edge]) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        var nodes: [PositionedNode] = [PositionedNode(id: root.id, kind: .center, point: center)]
        var edges: [Edge] = []

        func place(_ node: TreeNode, depth: Int, startAngle: Double, endAngle: Double, parentPoint: CGPoint, parentRadius: CGFloat) {
            let mid = (startAngle + endAngle) / 2
            let r = radius(forDepth: depth, canvasSize: canvasSize)
            let point = CGPoint(x: center.x + r * cos(mid), y: center.y + r * sin(mid))
            let nodeRadius = diameter(for: node.kind) / 2
            nodes.append(PositionedNode(id: node.id, kind: node.kind, point: point))
            edges.append(trimmedEdge(from: parentPoint, fromRadius: parentRadius, to: point, toRadius: nodeRadius))

            guard !node.children.isEmpty else { return }
            let span = max(endAngle - startAngle, 0.0001)
            let step = span / Double(node.children.count)
            for (index, child) in node.children.enumerated() {
                let childStart = startAngle + step * Double(index)
                place(child, depth: depth + 1, startAngle: childStart, endAngle: childStart + step, parentPoint: point, parentRadius: nodeRadius)
            }
        }

        if !root.children.isEmpty {
            let centerRadius = diameter(for: .center) / 2
            let step = (2 * Double.pi) / Double(root.children.count)
            for (index, child) in root.children.enumerated() {
                let start = Double(index) * step
                place(child, depth: 1, startAngle: start, endAngle: start + step, parentPoint: center, parentRadius: centerRadius)
            }
        }

        return (nodes, edges)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.t(.taskGraphTitle, language))
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isCollapsed.toggle()
                    }
                } label: {
                    Image(systemName: isCollapsed ? "plus" : "minus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help(L10n.t(isCollapsed ? .expandGraphHelp : .collapseGraphHelp, language))
            }
            .padding(.horizontal, 16)

            if !isCollapsed {
                GeometryReader { geo in
                    let built = layout(root: buildTree(), canvasSize: geo.size)

                    ZStack {
                        Canvas { context, _ in
                            for edge in built.edges {
                                var path = Path()
                                path.move(to: edge.from)
                                path.addLine(to: edge.to)
                                context.stroke(path, with: .color(.secondary.opacity(0.35)), lineWidth: 1.5)
                            }
                        }

                        ForEach(built.nodes) { node in
                            nodeView(node)
                                .position(node.point)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale * pinchDelta)
                    .offset(x: offset.width + dragDelta.width, y: offset.height + dragDelta.height)
                    .gesture(
                        MagnificationGesture()
                            .updating($pinchDelta) { value, state, _ in state = value }
                            .onEnded { value in
                                scale = min(max(scale * value, 0.5), 3.0)
                            }
                    )
                    .highPriorityGesture(
                        DragGesture()
                            .updating($dragDelta) { value, state, _ in state = value.translation }
                            .onEnded { value in
                                offset.width += value.translation.width
                                offset.height += value.translation.height
                            }
                    )
                    .clipped()
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .frame(height: isCollapsed ? nil : 420)
        .background(Theme.cardBackground)
    }

    /// Орталық "жоба" түйінінің реңкі — ақшыл акцент түс емес, минимал,
    /// көзге жайлы, қою бейтарап сұр (ақ пен қара аралығы).
    private var centerNodeColor: Color { Color(white: 0.38) }

    @ViewBuilder
    private func nodeView(_ node: PositionedNode) -> some View {
        let d = diameter(for: node.kind)
        switch node.kind {
        case .center:
            labeledCircle(
                diameter: d,
                fill: AnyShapeStyle(centerNodeColor),
                label: project.title.isEmpty ? L10n.t(.untitledProject, language) : project.title,
                labelWeight: .semibold
            )
            .help(project.title)
        case .undatedGroup:
            labeledCircle(
                diameter: d,
                fill: AnyShapeStyle(Color.secondary.opacity(0.25)),
                label: L10n.t(.undatedTasksGroupTitle, language),
                icon: "tray.fill"
            )
            .help(L10n.t(.undatedTasksGroupTitle, language))
        case .task(let task, _):
            labeledCircle(
                diameter: d,
                fill: AnyShapeStyle(task.evaluation.color),
                label: task.title
            )
            .contentShape(Circle())
            .help(task.title)
            .onTapGesture { onSelect(task) }
        }
    }

    /// Дөңгелек + оның ТӨМЕНІНДЕ орналасқан лейбл. Лейбл `.offset`
    /// арқылы дөңгелектің сыртына шығарылады — бұл дөңгелектің өз
    /// өлшемін (демек, `.position(node.point)`-тың нақты орталығын)
    /// өзгертпейді, сондықтан байланыс сызықтарының есептеуі дұрыс қалады.
    @ViewBuilder
    private func labeledCircle(
        diameter d: CGFloat,
        fill: AnyShapeStyle,
        label: String,
        labelWeight: Font.Weight = .regular,
        icon: String? = nil
    ) -> some View {
        ZStack {
            Circle()
                .fill(fill)
                .frame(width: d, height: d)
                .overlay(Circle().stroke(Color.primary.opacity(0.18), lineWidth: 1))

            if let icon {
                Image(systemName: icon)
                    .font(.system(size: d * 0.4))
                    .foregroundStyle(.secondary)
            }

            Text(label)
                .font(.system(size: 10, weight: labelWeight))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 72)
                .offset(y: d / 2 + 11)
        }
    }
}
