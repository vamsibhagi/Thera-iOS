import ManagedSettings
import ManagedSettingsUI
import UIKit
import FamilyControls

// iOS 26 implementation - API changed from returning ShieldConfiguration to configuring UIViewController
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    
    func configure(_ viewController: UIViewController) {
        // In iOS 26, we configure the view controller directly instead of returning a ShieldConfiguration
        
        // Set background
        viewController.view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        
        // Create custom shield UI
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.alignment = .center
        containerStack.spacing = 20
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Icon
        let iconImageView = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "Take a quick pause"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        
        // Subtitle
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Before you open this app, want to finish something small?"
        subtitleLabel.font = .systemFont(ofSize: 16)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        
        // Primary Button
        let primaryButton = UIButton(type: .system)
        primaryButton.setTitle("Do a task", for: .normal)
        primaryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        primaryButton.setTitleColor(.white, for: .normal)
        primaryButton.backgroundColor = .systemBlue
        primaryButton.layer.cornerRadius = 12
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        primaryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        primaryButton.widthAnchor.constraint(equalToConstant: 280).isActive = true
        
        // Secondary Button
        let secondaryButton = UIButton(type: .system)
        secondaryButton.setTitle("Open App Anyway", for: .normal)
        secondaryButton.titleLabel?.font = .systemFont(ofSize: 17)
        secondaryButton.setTitleColor(.systemBlue, for: .normal)
        
        // Add to stack
        containerStack.addArrangedSubview(iconImageView)
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(subtitleLabel)
        containerStack.addArrangedSubview(primaryButton)
        containerStack.addArrangedSubview(secondaryButton)
        
        containerStack.setCustomSpacing(30, after: iconImageView)
        containerStack.setCustomSpacing(12, after: titleLabel)
        containerStack.setCustomSpacing(30, after: subtitleLabel)
        containerStack.setCustomSpacing(16, after: primaryButton)
        
        // Add to view
        viewController.view.addSubview(containerStack)
        
        // Center the stack
        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            containerStack.leadingAnchor.constraint(greaterThanOrEqualTo: viewController.view.leadingAnchor, constant: 40),
            containerStack.trailingAnchor.constraint(lessThanOrEqualTo: viewController.view.trailingAnchor, constant: -40)
        ])
    }
}
