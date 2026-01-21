import SwiftUI

struct OnboardingIntroView: View {
    @Binding var currentStep: Int
    @State private var carouselIndex = 0
    
    let cards = [
        OnboardingCard(title: "Use your screen for the right things", body: "Thera helps you spend more time creating.\nWhen creation becomes the default, junk drops naturally.\nYou stay in control, with clear rules."),
        OnboardingCard(title: "Pick your creation apps", body: "Choose apps where you create real value.\nSet a daily creation goal.\nIf you don’t have creation apps yet, we’ll suggest some."),
        OnboardingCard(title: "Consumption unlocks after creation", body: "Select apps you mainly consume.\nSome apps are pre-set as consumption by default.\nThese apps stay locked until you hit your daily creation goal.")
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Thera")
                .font(.system(size: 24, weight: .semibold))
                .padding(.top, 60)
            
            Spacer()
            
            // Carousel
            TabView(selection: $carouselIndex) {
                ForEach(0..<cards.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Text(cards[index].title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Text(cards[index].body)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .padding(.horizontal, 40)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 400)
            
            Spacer()
            
            // Dots
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == carouselIndex ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 30)
            
            // Button
            Button(action: {
                if carouselIndex < cards.count - 1 {
                    withAnimation {
                        carouselIndex += 1
                    }
                } else {
                    currentStep += 1
                }
            }) {
                Text(carouselIndex == cards.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingCard {
    let title: String
    let body: String
}
