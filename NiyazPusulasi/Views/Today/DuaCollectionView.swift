import SwiftUI

/// Premium feature: Categorized dua (supplication) collection.
struct DuaCollectionView: View {
    @StateObject private var premiumManager = PremiumManager.shared
    @State private var selectedCategory: DuaCategory = .daily
    @State private var showPaywall = false
    @State private var hasAppeared = false

    var body: some View {
        NavigationStack {
            Group {
                if premiumManager.hasAccess(to: .duaCollection) {
                    duaList
                } else {
                    paywallView
                }
            }
            .navigationTitle("Dua Koleksiyonu")
            .sheet(isPresented: $showPaywall) {
                PaywallView(trigger: .duaCollection)
            }
        }
    }
    
    private var duaList: some View {
        List {
            Section {
                Picker("Kategori", selection: $selectedCategory) {
                    ForEach(DuaCategory.allCases) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 4)
            }
            
            Section {
                ForEach(selectedCategory.duas) { dua in
                    duaRow(dua)
                }
            }
        }
    }
    
    private var paywallView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "book.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Dua Koleksiyonu")
                .font(.title2.weight(.semibold))
            Text("Premium üye olarak tüm dualara erişebilirsiniz")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Premium'a Geç") {
                showPaywall = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func duaRow(_ dua: Dua) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dua.title)
                .font(.subheadline.weight(.semibold))

            if let arabic = dua.arabic {
                Text(arabic)
                    .font(.system(size: 20))
                    .environment(\.layoutDirection, .rightToLeft)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.vertical, 4)
            }

            if let transliteration = dua.transliteration {
                Text(transliteration)
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
            }

            Text(dua.meaning)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let source = dua.source {
                Text(source)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

struct Dua: Identifiable {
    let id = UUID()
    let title: String
    let arabic: String?
    let transliteration: String?
    let meaning: String
    let source: String?
}

enum DuaCategory: String, CaseIterable, Identifiable {
    case daily
    case morning
    case evening
    case prayer
    case eating
    case travel

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:   return "Günlük"
        case .morning: return "Sabah"
        case .evening: return "Akşam"
        case .prayer:  return "Namaz"
        case .eating:  return "Yemek"
        case .travel:  return "Yolculuk"
        }
    }

    var duas: [Dua] {
        switch self {
        case .daily:
            return [
                Dua(title: "Besmele", arabic: "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                    transliteration: "Bismillahirrahmanirrahim",
                    meaning: "Rahman ve Rahim olan Allah'ın adıyla",
                    source: nil),
                Dua(title: "Kelime-i Tevhid", arabic: "لَا إِلٰهَ إِلَّا اللَّهُ مُحَمَّدٌ رَسُولُ اللَّهِ",
                    transliteration: "La ilahe illallah Muhammedun Rasulullah",
                    meaning: "Allah'tan başka ilah yoktur, Muhammed O'nun elçisidir",
                    source: nil),
                Dua(title: "İstiğfar", arabic: "أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ",
                    transliteration: "Estağfirullahel azim",
                    meaning: "Yüce Allah'tan bağışlanma dilerim",
                    source: nil),
                Dua(title: "Salavat", arabic: "اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ",
                    transliteration: "Allahumme salli ala Muhammed ve ala ali Muhammed",
                    meaning: "Allah'ım! Muhammed'e ve Muhammed'in ailesine rahmet eyle",
                    source: nil),
            ]
        case .morning:
            return [
                Dua(title: "Sabah Duası", arabic: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
                    transliteration: "Asbahna ve asbahal mulku lillah",
                    meaning: "Sabaha erdik, mülk de Allah'ın olarak sabaha erdi",
                    source: "Müslim"),
                Dua(title: "Sabah Zikri", arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
                    transliteration: "Subhanallahi ve bihamdihi",
                    meaning: "Allah'ı hamd ile tesbih ederim (100 kez)",
                    source: "Buhari, Müslim"),
            ]
        case .evening:
            return [
                Dua(title: "Akşam Duası", arabic: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
                    transliteration: "Emseyna ve emsel mulku lillah",
                    meaning: "Akşama erdik, mülk de Allah'ın olarak akşama erdi",
                    source: "Müslim"),
                Dua(title: "Ayetel Kürsi", arabic: "اللَّهُ لَا إِلَهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
                    transliteration: "Allahu la ilahe illa huvel hayyul kayyum...",
                    meaning: "Allah, O'ndan başka ilah yoktur. O, daima diridir...",
                    source: "Bakara Suresi 255"),
            ]
        case .prayer:
            return [
                Dua(title: "Sübhaneke", arabic: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ",
                    transliteration: "Subhaneke Allahumme ve bihamdike",
                    meaning: "Allah'ım! Sen her türlü noksanlıktan münezzehsin",
                    source: nil),
                Dua(title: "Ettehiyyatü", arabic: "التَّحِيَّاتُ لِلَّهِ وَالصَّلَوَاتُ وَالطَّيِّبَاتُ",
                    transliteration: "Ettehiyyatu lillahi ves salavatu vet tayyibat",
                    meaning: "Her türlü saygı, namaz ve güzellik Allah'a aittir",
                    source: nil),
            ]
        case .eating:
            return [
                Dua(title: "Yemekten Önce", arabic: "بِسْمِ اللَّهِ وَعَلَى بَرَكَةِ اللَّهِ",
                    transliteration: "Bismillahi ve ala bereketi'llah",
                    meaning: "Allah'ın adıyla ve Allah'ın bereketiyle",
                    source: nil),
                Dua(title: "Yemekten Sonra", arabic: "الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنَا وَسَقَانَا",
                    transliteration: "Elhamdulillahillezi et'amena ve sekana",
                    meaning: "Bizi yedirip içiren Allah'a hamdolsun",
                    source: nil),
            ]
        case .travel:
            return [
                Dua(title: "Yolculuk Duası", arabic: "سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا",
                    transliteration: "Subhanellezi sahhara lena haza",
                    meaning: "Bunu bizim hizmetimize veren Allah eksikliklerden münezzehtir",
                    source: "Zuhruf Suresi 13"),
            ]
        }
    }
}

#Preview {
    DuaCollectionView()
}
