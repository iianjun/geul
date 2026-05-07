import SwiftUI

struct FindBar: View {
    @Binding var query: String
    let result: FindResult
    let focusRequestID: Int
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void

    @FocusState private var isFocused: Bool

    private var canNavigate: Bool {
        result.hasMatches
    }

    private var resultColor: Color {
        query.isEmpty || result.hasMatches ? .secondary : .red
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Find", text: $query)
                .textFieldStyle(.plain)
                .frame(width: 220)
                .focused($isFocused)
                .onSubmit(onNext)

            Text(result.displayText)
                .font(.caption)
                .foregroundStyle(resultColor)
                .frame(minWidth: 64, alignment: .trailing)

            Button(action: onPrevious) {
                Image(systemName: "chevron.up")
            }
            .disabled(!canNavigate)
            .help("Find Previous")

            Button(action: onNext) {
                Image(systemName: "chevron.down")
            }
            .disabled(!canNavigate)
            .help("Find Next")

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .help("Close")
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
        .onAppear {
            focusTextField()
        }
        .onChange(of: focusRequestID) { _, _ in
            focusTextField()
        }
        .onExitCommand(perform: onClose)
    }

    private func focusTextField() {
        DispatchQueue.main.async {
            isFocused = true
        }
    }
}
