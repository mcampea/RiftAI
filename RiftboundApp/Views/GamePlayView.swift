import SwiftUI

struct GamePlayView: View {
    @ObservedObject var viewModel: GameSessionViewModel
    @State var session: RBGameSession

    @Environment(\.dismiss) var dismiss

    @State private var showEndGameDialog = false
    @State private var selectedWinner: Int? = nil
    @State private var isSaving = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Player 2 (Top - Rotated 180°)
                    PlayerScoreView(
                        playerName: session.player2Name,
                        legendTag: session.player2LegendChampionTag,
                        score: $session.player2Score,
                        battlefield1Might: $session.player2Battlefield1Might,
                        battlefield2Might: $session.player2Battlefield2Might,
                        isRotated: true
                    )
                    .frame(height: geometry.size.height / 2)

                    Divider()
                        .background(Color.white)

                    // Player 1 (Bottom - Normal orientation)
                    PlayerScoreView(
                        playerName: session.player1Name,
                        legendTag: session.player1LegendChampionTag,
                        score: $session.player1Score,
                        battlefield1Might: $session.player1Battlefield1Might,
                        battlefield2Might: $session.player1Battlefield2Might,
                        isRotated: false
                    )
                    .frame(height: geometry.size.height / 2)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    Task {
                        await saveSession()
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Save & Exit")
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("End Game") {
                    showEndGameDialog = true
                }
            }
        }
        .confirmationDialog("End Game", isPresented: $showEndGameDialog) {
            Button("\(session.player1Name) Wins") {
                selectedWinner = 1
                Task {
                    await endGame()
                }
            }

            Button("\(session.player2Name) Wins") {
                selectedWinner = 2
                Task {
                    await endGame()
                }
            }

            Button("Draw") {
                selectedWinner = nil
                Task {
                    await endGame()
                }
            }

            Button("Cancel", role: .cancel) {}
        }
        .statusBar(hidden: true)
        .persistentSystemOverlays(.hidden)
    }

    func saveSession() async {
        _ = await viewModel.updateGameSession(session)
    }

    func endGame() async {
        isSaving = true
        session.isComplete = true
        session.winner = selectedWinner
        session.completedAt = Date()

        let success = await viewModel.updateGameSession(session)
        isSaving = false

        if success {
            dismiss()
        }
    }
}

struct PlayerScoreView: View {
    let playerName: String
    let legendTag: String
    @Binding var score: Int
    @Binding var battlefield1Might: Int
    @Binding var battlefield2Might: Int
    let isRotated: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Player Info
            VStack(spacing: 4) {
                Text(playerName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(legendTag)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Main Score Counter
            VStack(spacing: 8) {
                HStack(spacing: 20) {
                    Button {
                        if score > 0 {
                            score -= 1
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }

                    Text("\(score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 120)

                    Button {
                        score += 1
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                    }
                }

                Text("SCORE")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Battlefield Might Counters
            HStack(spacing: 24) {
                BattlefieldCounter(
                    title: "B1",
                    value: $battlefield1Might
                )

                BattlefieldCounter(
                    title: "B2",
                    value: $battlefield2Might
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .rotationEffect(isRotated ? .degrees(180) : .degrees(0))
    }
}

struct BattlefieldCounter: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                Button {
                    if value > 0 {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }

                Text("\(value)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(minWidth: 50)

                Button {
                    value += 1
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }

            Text("MIGHT")
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}
