import SwiftUI
import FamilyControls
import DeviceActivity
import ManagedSettings

struct OnboardingLimitSettingView: View {
    @Binding var currentStep: Int
    @EnvironmentObject var screenTimeManager: TheraScreenTimeManager
    @EnvironmentObject var persistenceManager: PersistenceManager
    
    // Limits State: Array of (token, minutes) tuples instead of Dictionary
    // iOS 26 ApplicationToken might not conform to Hashable
    @State private var limits: [(token: ApplicationToken, minutes: Int)] = []
    
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
            
            // List of Apps
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(screenTimeManager.distractingSelection.applicationTokens), id: \.self) { token in
                        AppLimitRow(token: token, limit: binding(for: token))
                    }
                    
                    // Note: Category tokens are trickier to "limit" individually in this UI unless we group them.
                    // For now, we only show Application tokens as per typical user flow.
                    // If categories are selected, we might want to apply a limit to the whole category?
                    // The prompt focuses on "each selected app".
                }
                .padding()
            }
            
            Spacer()
            
            // Continue Button
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
        for token in screenTimeManager.distractingSelection.applicationTokens {
            if !limits.contains(where: { areTokensEqual($0.token, token) }) {
                limits.append((token: token, minutes: 5))
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
        
        // IMPORTANT: Actually start the monitoring!
        screenTimeManager.saveSelectionsAndSchedule(appLimits: appLimits)
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
