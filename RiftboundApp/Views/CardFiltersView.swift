import SwiftUI

struct CardFiltersView: View {
    @Binding var filters: CardFilters
    @Environment(\.dismiss) private var dismiss

    let availableDomains = ["Fury", "Mind", "Valor", "Spirit", "Wild"]
    let availableTypes = ["Champion", "Action", "Ally", "Equipment", "Battlefield", "Rune"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Domains") {
                    ForEach(availableDomains, id: \.self) { domain in
                        Toggle(domain, isOn: Binding(
                            get: { filters.selectedDomains.contains(domain) },
                            set: { isOn in
                                if isOn {
                                    filters.selectedDomains.insert(domain)
                                } else {
                                    filters.selectedDomains.remove(domain)
                                }
                            }
                        ))
                    }
                }

                Section("Types") {
                    ForEach(availableTypes, id: \.self) { type in
                        Toggle(type, isOn: Binding(
                            get: { filters.selectedTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    filters.selectedTypes.insert(type)
                                } else {
                                    filters.selectedTypes.remove(type)
                                }
                            }
                        ))
                    }
                }

                Section("Cost Range") {
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("Min", value: $filters.minCost, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("Max", value: $filters.maxCost, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section("Might Range") {
                    HStack {
                        Text("Min")
                        Spacer()
                        TextField("Min", value: $filters.minMight, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }

                    HStack {
                        Text("Max")
                        Spacer()
                        TextField("Max", value: $filters.maxMight, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                    }
                }

                Section("Special") {
                    Toggle("Signatures Only", isOn: $filters.signaturesOnly)
                    Toggle("Runes Only", isOn: $filters.runesOnly)
                    Toggle("Battlefields Only", isOn: $filters.battlefieldsOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        filters.reset()
                    }
                    .disabled(!filters.isActive)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CardFiltersView(filters: .constant(CardFilters()))
}
