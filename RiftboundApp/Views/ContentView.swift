import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.authState {
            case .checking:
                LoadingView()

            case .needsiCloudSignIn:
                iCloudRequiredView()

            case .needsUsernameSetup:
                UsernameSetupView()

            case .authenticated:
                MainTabView()
            }
        }
        .alert("Error", isPresented: .constant(appState.errorMessage != nil)) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let error = appState.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading Riftbound...")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - iCloud Required View

struct iCloudRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.slash")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            VStack(spacing: 12) {
                Text("iCloud Required")
                    .font(.title.bold())

                Text("Riftbound requires an iCloud account to store and sync your decks.\n\nPlease sign in to iCloud in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding(32)
    }
}

// MARK: - Username Setup View

struct UsernameSetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var username = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)

                Text("Choose Your Username")
                    .font(.title.bold())

                Text("This will be your public display name")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .disabled(isLoading)

                Text("3-20 characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task {
                    await createUsername()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Continue")
                }
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(username.count >= 3 ? Color.blue : Color.gray)
            .foregroundStyle(.white)
            .cornerRadius(12)
            .disabled(username.count < 3 || isLoading)
        }
        .padding(32)
    }

    private func createUsername() async {
        isLoading = true
        errorMessage = nil

        do {
            try await appState.setUsername(username)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CardBrowserView()
                .tabItem {
                    Label("Browse", systemImage: "square.grid.2x2")
                }
                .tag(0)

            MyDecksView()
                .tabItem {
                    Label("Decks", systemImage: "rectangle.stack")
                }
                .tag(1)

            PublicDecksView()
                .tabItem {
                    Label("Public", systemImage: "globe")
                }
                .tag(2)

            AIAssistantView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(3)

            ScoreCounterView()
                .tabItem {
                    Label("Score", systemImage: "number")
                }
                .tag(4)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
