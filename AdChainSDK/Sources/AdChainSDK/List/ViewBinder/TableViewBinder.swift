import UIKit

/// Protocol for binding native ad data to table view cells
public protocol TableViewBinder {
    func createView() -> UIView
    func bindView(_ view: UIView, ad: NativeAdData, position: Int)
    func getHeight() -> CGFloat
}

/// Default implementation of TableViewBinder
public class DefaultTableViewBinder: TableViewBinder {
    private let height: CGFloat
    
    public init(height: CGFloat = 120) {
        self.height = height
    }
    
    public func createView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Create card view
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 12
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.1
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 4
        
        containerView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            cardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // Add image view
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.tag = 100 // For binding
        
        cardView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.tag = 101 // For binding
        
        cardView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add description label
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.tag = 102 // For binding
        
        cardView.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add CTA button
        let ctaButton = UIButton(type: .system)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        ctaButton.setTitleColor(.systemBlue, for: .normal)
        ctaButton.tag = 103 // For binding
        ctaButton.isUserInteractionEnabled = false // Handled by cell tap
        
        cardView.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup constraints for labels and button
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            ctaButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            ctaButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4)
        ])
        
        return containerView
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, position: Int) {
        guard let imageView = view.viewWithTag(100) as? UIImageView,
              let titleLabel = view.viewWithTag(101) as? UILabel,
              let descriptionLabel = view.viewWithTag(102) as? UILabel,
              let ctaButton = view.viewWithTag(103) as? UIButton else { return }
        
        // Bind data
        titleLabel.text = ad.title
        descriptionLabel.text = ad.description
        ctaButton.setTitle(ad.ctaText, for: .normal)
        
        // Load image
        if let url = URL(string: ad.imageUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    public func getHeight() -> CGFloat {
        return height
    }
}

/// Compact style binder for list ads
public class CompactTableViewBinder: TableViewBinder {
    private let height: CGFloat
    
    public init(height: CGFloat = 80) {
        self.height = height
    }
    
    public func createView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Create horizontal stack
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.alignment = .center
        
        containerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // Add image
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.tag = 100
        
        stackView.addArrangedSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64)
        ])
        
        // Add text container
        let textContainer = UIView()
        stackView.addArrangedSubview(textContainer)
        
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.tag = 101
        
        textContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.tag = 102
        
        textContainer.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: textContainer.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            descriptionLabel.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: textContainer.bottomAnchor)
        ])
        
        // Add CTA
        let ctaLabel = UILabel()
        ctaLabel.font = .systemFont(ofSize: 12, weight: .medium)
        ctaLabel.textColor = .systemBlue
        ctaLabel.tag = 103
        
        stackView.addArrangedSubview(ctaLabel)
        ctaLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        return containerView
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, position: Int) {
        guard let imageView = view.viewWithTag(100) as? UIImageView,
              let titleLabel = view.viewWithTag(101) as? UILabel,
              let descriptionLabel = view.viewWithTag(102) as? UILabel,
              let ctaLabel = view.viewWithTag(103) as? UILabel else { return }
        
        titleLabel.text = ad.title
        descriptionLabel.text = ad.description
        ctaLabel.text = ad.ctaText
        
        // Load image
        if let url = URL(string: ad.imageUrl) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    public func getHeight() -> CGFloat {
        return height
    }
}