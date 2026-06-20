#if canImport(SwiftUI)
import SwiftUI

extension PermissionStatus {
    /// An SF Symbol name representing this status.
    public var symbolName: String {
        switch self {
        case .granted: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        case .notDetermined: return "questionmark.circle.fill"
        }
    }

    /// A colour representing this status.
    public var color: Color {
        switch self {
        case .granted: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        }
    }

    /// A short label for this status.
    public var label: String {
        switch self {
        case .granted: return "Granted"
        case .denied: return "Denied"
        case .notDetermined: return "Not determined"
        }
    }
}

/// A single live permission row: name, status indicator, and a request button.
///
/// Refreshes its status when it appears and after a request. Optional and
/// minimal — drop it into your own settings UI, or use ``PermissionsView``.
@available(macOS 13.0, *)
@MainActor
public struct PermissionRow: View {
    private let permission: Permission
    @State private var status: PermissionStatus
    @State private var isRequesting = false

    public init(_ permission: Permission) {
        self.permission = permission
        _status = State(initialValue: Permissions.status(permission))
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status.symbolName)
                .foregroundStyle(status.color)
            VStack(alignment: .leading, spacing: 1) {
                Text(permission.displayName)
                Text(status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if status == .granted {
                EmptyView()
            } else if isRequesting {
                ProgressView().controlSize(.small)
            } else {
                Button("Grant") { request() }
                Button("Settings") { Permissions.openSettings(for: permission) }
            }
        }
        .onAppear { status = Permissions.status(permission) }
    }

    private func request() {
        isRequesting = true
        Task {
            let result = await Permissions.request(permission)
            await MainActor.run {
                status = result
                isRequesting = false
            }
        }
    }
}

/// A live dashboard listing several permissions, each as a ``PermissionRow``.
@available(macOS 13.0, *)
@MainActor
public struct PermissionsView: View {
    private let permissions: [Permission]

    /// Creates a dashboard for the given permissions.
    public init(_ permissions: [Permission]) {
        self.permissions = permissions
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(permissions.enumerated()), id: \.offset) { _, permission in
                PermissionRow(permission)
            }
        }
    }
}
#endif
