import SwiftUI

struct OnboardingCarouselView: View {
    @Binding var currentStep: Int
    @State private var carouselIndex = 0
    
    // Carousel Data
    struct CarouselCard: Identifiable {
        let id = UUID()
        let imageName: String
        let headline: String
        let body: String
    }
    
    let cards = [
        CarouselCard(
            imageName: "brain.head.profile",
            headline: "We Forgot How to Be Bored",
            body: "Phones stole our downtime. Now, picking up a screen is an automatic reflex whenever we're bored."
        ),
        CarouselCard(
            imageName: "figure.walk",
            headline: "Break the Loop",
            body: "Thera catches the habit in action. It gently pauses your scrolling and suggests a better alternative, like taking a walk."
        ),
        CarouselCard(
            imageName: "chart.bar.doc.horizontal",
            headline: "Back in Control",
            body: "Reclaim your choice. Pick a fun activity off your phone or a useful one on it. Be the boss of your time."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // App Logo
            Image("TheraLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 40)
                .padding(.top, 20)
            
            Spacer()
            
            // Carousel
            TabView(selection: $carouselIndex) {
                ForEach(0..<cards.count, id: \.self) { index in
                    VStack(spacing: 32) {
                        // Icon Circle
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: cards[index].imageName)
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            Text(cards[index].headline)
                                .font(.system(.title, design: .rounded))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(cards[index].body)
                                .font(.system(.body, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 32)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 40)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 500) // Taller frame for open layout
            
            Spacer()
            
            // Dot Indicators
            HStack(spacing: 8) {
                ForEach(0..<cards.count, id: \.self) { index in
                    Circle()
                        .fill(index == carouselIndex ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(index == carouselIndex ? 1.2 : 1.0)
                        .animation(.spring(), value: carouselIndex)
                }
            }
            .padding(.bottom, 40)
            
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
                Text(carouselIndex < cards.count - 1 ? "Next" : "Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16) // Slightly rounder
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}
