import SwiftUI

struct NativeEditorView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.colorScheme) private var colorScheme

    private var theme: EditorTheme { EditorTheme(colorScheme: colorScheme) }
    private var language: ProgrammingLanguage { ProgrammingLanguage(fileURL: appModel.selectedFileURL) }

    private var textBinding: Binding<String> {
        Binding(
            get: { appModel.fileContent },
            set: { newValue in
                appModel.updateNativeEditorText(newValue)
            }
        )
    }

    var body: some View {
        CodeTextView(
            text: textBinding,
            language: language,
            theme: theme
        )
        .background(Color.ideEditorBackground)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
