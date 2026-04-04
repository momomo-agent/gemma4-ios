import SwiftUI
import Speech
import PhotosUI

@main
struct Gemma4App: App {
    var body: some Scene {
        WindowGroup { ChatView() }
    }
}

struct ChatView: View {
    @State private var messages: [Message] = []
    @State private var input = ""
    @State private var model = GemmaModel()
    @State private var isGenerating = false
    @State private var selectedModel: ModelChoice = .gemma4_e2b
    @State private var showModelPicker = false
    @State private var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var isRecording = false
    @State private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            if !model.isLoaded {
                loadingView
            } else {
                chatView
            }
        }
        .sheet(isPresented: $showModelPicker) { modelPickerSheet }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImage = img
                }
            }
        }
    }

    // MARK: - Toolbar

    var toolbar: some View {
        HStack {
            Text("Gemma 4").font(.headline)
            Spacer()
            Button(selectedModel.rawValue) { showModelPicker = true }
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal).padding(.top, 8).padding(.bottom, 4)
    }

    // MARK: - Loading

    var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(selectedModel.rawValue).font(.title2).bold()
            Text(selectedModel.subtitle)
                .font(.caption).foregroundColor(.secondary)

            ProgressView(value: model.loadProgress, total: 1.0)
                .padding(.horizontal, 40)

            if model.loadProgress < 0.95 {
                Text("下载模型 \(Int(model.loadProgress * 100))%")
                    .font(.caption).foregroundColor(.secondary)
            } else if model.loadProgress < 1.0 {
                Text("加载中...")
                    .font(.caption).foregroundColor(.secondary)
            }

            if let error = model.error {
                Text(error)
                    .foregroundColor(.red).font(.caption)
                    .padding(.horizontal)

                Button("重试") {
                    Task { await model.load(choice: selectedModel) }
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .task { await model.load(choice: selectedModel) }
    }

    // MARK: - Chat

    var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(messages) { msg in
                            MessageRow(message: msg).id(msg.id)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Image preview
            if let img = selectedImage {
                HStack(spacing: 8) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 56, height: 56)
                        .cornerRadius(8).clipped()

                    Button { selectedImage = nil; photoItem = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal).padding(.top, 4)
            }

            // Input bar
            inputBar
        }
    }

    var inputBar: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "photo")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }

            Button {
                if isRecording { stopRecording() } else { startRecording() }
            } label: {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic")
                    .foregroundColor(isRecording ? .red : .blue)
                    .font(.system(size: 18))
            }

            TextField("Message", text: $input)
                .textFieldStyle(.roundedBorder)

            Button {
                Task { await sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(canSend ? .blue : .gray)
            }
            .disabled(!canSend || isGenerating)
        }
        .padding(.horizontal).padding(.vertical, 8)
    }

    var canSend: Bool {
        !input.trimmingCharacters(in: .whitespaces).isEmpty || selectedImage != nil
    }

    // MARK: - Model Picker

    var modelPickerSheet: some View {
        NavigationView {
            List(ModelChoice.allCases) { choice in
                Button {
                    if choice != selectedModel {
                        selectedModel = choice
                        messages.removeAll()
                        Task { await model.load(choice: choice) }
                    }
                    showModelPicker = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(choice.rawValue).foregroundColor(.primary)
                            Text(choice.subtitle)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if choice == selectedModel {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("选择模型")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("关闭") { showModelPicker = false }
                }
            }
        }
    }

    // MARK: - Actions

    func sendMessage() async {
        let text = input.trimmingCharacters(in: .whitespaces)
        let img = selectedImage
        input = ""
        selectedImage = nil
        photoItem = nil

        if text.isEmpty && img == nil { return }

        messages.append(Message(text: text, isUser: true, image: img))
        isGenerating = true

        let aiMsg = Message(text: "", isUser: false)
        messages.append(aiMsg)
        let idx = messages.count - 1

        await model.generate(prompt: text.isEmpty ? "Describe this image" : text, image: img?.cgImage) { token in
            Task { @MainActor in
                messages[idx].text += token
            }
        }
        isGenerating = false
    }

    func startRecording() {
        isRecording = true
        speechRecognizer.start { text in
            input = text
        }
    }

    func stopRecording() {
        isRecording = false
        speechRecognizer.stop()
    }
}

// MARK: - Message

struct Message: Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
    var image: UIImage? = nil
}

struct MessageRow: View {
    let message: Message

    var body: some View {
        HStack(alignment: .bottom) {
            if message.isUser { Spacer(minLength: 48) }
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if let img = message.image {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(maxWidth: 200).cornerRadius(12)
                }
                if !message.text.isEmpty {
                    Text(message.text)
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(message.isUser ? Color.blue : Color(.systemGray5))
                        .foregroundColor(message.isUser ? .white : .primary)
                        .cornerRadius(16)
                }
            }
            if !message.isUser { Spacer(minLength: 48) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
    }
}
