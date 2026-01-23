import SwiftUI

struct OnboardingCarouselView: View {
    @Binding var currentStep: Int
    @State private var carouselIndex = 0
    
    // Carousel Data
    struct CarouselCard: Identifiable {
        let id = UUID()
        let headline: String
        let body: String
    }
    
    let cards = [
        CarouselCard(
            headline: "Your screen time can feel better",
            body: "Screen time isn’t bad by default.\nThe problem is mindless scrolling.\nThera helps you pause and choose something better."
        ),
        CarouselCard(
            headline: "Distractions become decision points",
            body: "When you open distracting apps, Thera steps in.\nYou get gentle alternatives instead of a hard stop.\nSmall actions that actually feel good."
        ),
        CarouselCard(
            headline: "You stay in control",
            body: "Set your own limits and preferences.\nPick what Thera suggests to you.\nNo tracking of content, no judgment."
        )
    ]
    
    var body: some View {
        VStack {
            // App Name
            Text("Thera")
                .font(.headline)
                .padding(.top, 20)
            
            Spacer()
            
            // Carousel
            TabView(selection: $carouselIndex) {
                ForEach(0..<cards.count, id: \.self) { index in
                    VStack(spacing: 20) {
                        Text(cards[index].headline)
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
                    .frame(maxWidth: .infinity, maxHeight: 350)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(24)
                    .padding(.horizontal, 24)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // We build our own dots
            .frame(height: 400)
            
            Spacer()
            
            // Dot Indicators
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == carouselIndex ? Color.primary : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 30)
            
            // Primary Button
            Button(action: {
                withAnimation {
                    if carouselIndex < cards.count - 1 {
                        carouselIndex += 1
                    } else {
                        // Move to next onboarding screen
                        currentStep += 1
                    }
                }
            }) {
                Text("Next")
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
    }
}
