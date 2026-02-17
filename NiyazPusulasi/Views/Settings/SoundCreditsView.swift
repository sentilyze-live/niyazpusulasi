import SwiftUI

/// Displays attribution and credits for adhan sounds used in the app.
struct SoundCreditsView: View {
    var body: some View {
        List {
            Section {
                Text("Bu uygulamada kullanılan ezan sesleri, Creative Commons lisansları altında paylaşılmış kaynaklardan alınmıştır.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Ses Kaynakları")
            }

            Section {
                ForEach(AdhanSound.allCases.filter { $0.attribution != nil }) { sound in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(sound.emoji)
                                .font(.title2)
                            Text(sound.displayName)
                                .font(.headline)
                        }

                        if let attribution = sound.attribution {
                            Text(attribution)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Creative Commons CC BY 4.0")
            } footer: {
                Text("CC BY 4.0 lisansı, kaynak belirtilerek ticari kullanıma izin verir.")
                    .font(.caption2)
            }

            Section {
                ForEach(AdhanSound.allCases.filter {
                    $0.attribution == nil && $0 != .default && $0.fileName != nil
                }) { sound in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(sound.emoji)
                                .font(.title2)
                            Text(sound.displayName)
                                .font(.headline)
                        }

                        Text("Public Domain (CC0) - Atıf gerekmez")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Public Domain (CC0)")
            } footer: {
                Text("CC0 lisansı, herhangi bir kısıtlama olmaksızın kullanıma izin verir.")
                    .font(.caption2)
            }

            Section {
                Link(destination: URL(string: "https://freesound.org")!) {
                    HStack {
                        Label("Freesound.org", systemImage: "link")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://creativecommons.org/licenses/by/4.0/")!) {
                    HStack {
                        Label("CC BY 4.0 Lisansı", systemImage: "doc.text")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://creativecommons.org/publicdomain/zero/1.0/")!) {
                    HStack {
                        Label("CC0 (Public Domain)", systemImage: "doc.text")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Bağlantılar")
            }

            Section {
                Text("Tüm sesler telif hakları sahibine aittir ve ilgili Creative Commons lisansları altında kullanılmaktadır. Detaylı bilgi için yukarıdaki bağlantıları ziyaret edebilirsiniz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Yasal Bilgiler")
            }
        }
        .navigationTitle("Ses Kaynakları")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SoundCreditsView()
    }
}
