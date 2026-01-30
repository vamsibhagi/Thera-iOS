import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

struct OnboardingLimitSettingView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    // Limits State
    @State private var limits: [(token: ApplicationToken, minutes: Int)] = []
    @State private var categoryLimits: [(token: ActivityCategoryToken, minutes: Int)] = []
    
    // Allowed increments
    let allowedLimits = [1, 5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Set time limits")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                Text("We’ll show you alternatives when time’s up.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            
            // List of Apps & Categories
            ScrollView {
                VStack(spacing: 16) {
                    // Apps
                    if !screenTimeManager.distractingSelection.applicationTokens.isEmpty {
                        ForEach(Array(screenTimeManager.distractingSelection.applicationTokens), id: \.self) { token in
                            AppLimitRow(token: token, limit: binding(for: token))
                        }
                    }
                    
                    // Categories
                    if !screenTimeManager.distractingSelection.categoryTokens.isEmpty {
                        ForEach(Array(screenTimeManager.distractingSelection.categoryTokens), id: \.self) { token in
                            CategoryLimitRow(token: token, limit: categoryBinding(for: token))
                        }
                    }
                }
                .padding()
            }
            
            Spacer()
            
            Text("We start counting now. Time spent earlier today doesn't count.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 10)
            
            // Navigation Buttons
            VStack(spacing: 12) {
                Button(action: {
                    saveLimits()
                    currentStep += 1
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    // Go back to app selection
                    currentStep -= 1
                }) {
                    Text("Back")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .onAppear {
            initializeLimits()
        }
    }
    
    func binding(for token: ApplicationToken) -> Binding<Int> {
        return Binding(
            get: {
                limits.first(where: { areTokensEqual($0.token, token) })?.minutes ?? 5
            },
            set: { newValue in
                if let index = limits.firstIndex(where: { areTokensEqual($0.token, token) }) {
                    limits[index].minutes = newValue
                } else {
                    limits.append((token: token, minutes: newValue))
                }
            }
        )
    }
    
    func categoryBinding(for token: ActivityCategoryToken) -> Binding<Int> {
        return Binding(
            get: {
                categoryLimits.first(where: { $0.token == token })?.minutes ?? 5
            },
            set: { newValue in
                if let index = categoryLimits.firstIndex(where: { $0.token == token }) {
                    categoryLimits[index].minutes = newValue
                } else {
                    categoryLimits.append((token: token, minutes: newValue))
                }
            }
        )
    }
    
    func areTokensEqual(_ lhs: ApplicationToken, _ rhs: ApplicationToken) -> Bool {
        // ApplicationToken doesn't conform to Equatable in iOS 26
        // We compare by converting to Data
        guard let lhsData = try? JSONEncoder().encode(lhs),
              let rhsData = try? JSONEncoder().encode(rhs) else {
            return false
        }
        return lhsData == rhsData
    }
    
    func initializeLimits() {
        // Init Apps
        for token in screenTimeManager.distractingSelection.applicationTokens {
            if !limits.contains(where: { areTokensEqual($0.token, token) }) {
                limits.append((token: token, minutes: 5))
            }
        }
        
        // Init Categories
        for token in screenTimeManager.distractingSelection.categoryTokens {
            if !categoryLimits.contains(where: { $0.token == token }) {
                categoryLimits.append((token: token, minutes: 5))
            }
        }
    }
    
    func saveLimits() {
        // Save to PersistenceManager
        var appLimits: [AppLimit] = []
        for limit in limits {
            appLimits.append(AppLimit(token: limit.token, dailyLimitMinutes: limit.minutes))
        }
        persistenceManager.appLimits = appLimits
        
        var catLimits: [CategoryLimit] = []
        for limit in categoryLimits {
            catLimits.append(CategoryLimit(token: limit.token, dailyLimitMinutes: limit.minutes))
        }
        persistenceManager.categoryLimits = catLimits
        
        // IMPORTANT: Actually start the monitoring!
        screenTimeManager.saveSelectionsAndSchedule(appLimits: appLimits, categoryLimits: catLimits)
    }
}

struct CategoryLimitRow: View {
    let token: ActivityCategoryToken
    @Binding var limit: Int
    
    let allowedLimits = [1, 5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120]
    
    var body: some View {
        HStack {
            // Category Icon & Name
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(1.5)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.headline)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 0) {
                Button(action: decrease) {
                    Image(systemName: "minus")
                    .frame(width: 30, height: 30)
                    .background(Color(UIColor.systemGray5))
                }
                .disabled(limit <= 1)
                
                Text("\(limit) m")
                    .font(.headline)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                
                Button(action: increase) {
                    Image(systemName: "plus")
                    .frame(width: 30, height: 30)
                    .background(Color(UIColor.systemGray5))
                }
                .disabled(limit >= 120)
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    func increase() {
        if let idx = allowedLimits.firstIndex(of: limit), idx < allowedLimits.count - 1 {
            limit = allowedLimits[idx + 1]
        }
    }
    
    func decrease() {
        if let idx = allowedLimits.firstIndex(of: limit), idx > 0 {
            limit = allowedLimits[idx - 1]
        }
    }
    }

struct AppLimitRow: View {
    let token: ApplicationToken
    @Binding var limit: Int
    @State private var filter = DeviceActivityFilter()
    
    let allowedLimits = [1, 5, 10, 15, 20, 25, 30, 45, 60, 75, 90, 105, 120]
    
    var body: some View {
        HStack {
            // App Icon & Name
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(1.5)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading) {
                Label(token)
                    .labelStyle(.titleOnly)
                    .font(.headline)
                
                // Mini Report for Usage - Disabled for iOS 26 (miniUsage context removed)
                // DeviceActivityReport(.miniUsage, filter: filter)
                //     .frame(height: 15)
            }
            
            Spacer()
            
            // Controls
            HStack(spacing: 0) {
                Button(action: decrease) {
                    Image(systemName: "minus")
                        .frame(width: 30, height: 30)
                        .background(Color(UIColor.systemGray5))
                }
                .disabled(limit <= 1)
                
                Text("\(limit) m")
                    .font(.headline)
                    .frame(width: 50)
                    .multilineTextAlignment(.center)
                
                Button(action: increase) {
                    Image(systemName: "plus")
                        .frame(width: 30, height: 30)
                        .background(Color(UIColor.systemGray5))
                }
                .disabled(limit >= 120)
            }
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.systemGray4), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .onAppear {
            // Configure filter for this specific app
            filter = DeviceActivityFilter(
                segment: .daily(during: Calendar.current.dateInterval(of: .day, for: Date())!),
                users: .all,
                devices: .init([.iPhone, .iPad]),
                applications: Set([token]),
                categories: Set()
            )
        }
    }
    
    func increase() {
        if let idx = allowedLimits.firstIndex(of: limit), idx < allowedLimits.count - 1 {
            limit = allowedLimits[idx + 1]
        }
    }
    
    func decrease() {
        if let idx = allowedLimits.firstIndex(of: limit), idx > 0 {
            limit = allowedLimits[idx - 1]
        }
    }
}
