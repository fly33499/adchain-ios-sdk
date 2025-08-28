import UIKit

/// Protocol for binding native ad data to collection view cells
public protocol CollectionViewBinder {
    func createView() -> UIView
    func bindView(_ view: UIView, ad: NativeAdData, position: Int)
    func getSize(collectionView: UICollectionView) -> CGSize
}

/// Default grid-style binder for collection view ads
public class DefaultCollectionViewBinder: CollectionViewBinder {
    private let aspectRatio: CGFloat
    private let padding: CGFloat
    private let columns: Int
    
    public init(aspectRatio: CGFloat = 1.0, padding: CGFloat = 16, columns: Int = 2) {
        self.aspectRatio = aspectRatio
        self.padding = padding
        self.columns = columns
    }
    
    public func createView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Create card view
        let cardView = UIView()
        cardView.backgroundColor = .secondarySystemBackground
        cardView.layer.cornerRadius = 8
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.08
        cardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        cardView.layer.shadowRadius = 3
        
        containerView.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 4),
            cardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            cardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -4)
        ])
        
        // Add image view
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.tag = 100
        
        cardView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add gradient overlay
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor]
        gradientLayer.locations = [0.5, 1.0]
        imageView.layer.addSublayer(gradientLayer)
        imageView.layer.setValue(gradientLayer, forKey: "gradient")
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.tag = 101
        
        cardView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add CTA badge
        let ctaBadge = UILabel()
        ctaBadge.font = .systemFont(ofSize: 11, weight: .medium)
        ctaBadge.textColor = .white
        ctaBadge.backgroundColor = .systemBlue
        ctaBadge.textAlignment = .center
        ctaBadge.layer.cornerRadius = 4
        ctaBadge.clipsToBounds = true
        ctaBadge.tag = 102
        
        cardView.addSubview(ctaBadge)
        ctaBadge.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -8),
            
            ctaBadge.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            ctaBadge.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            ctaBadge.heightAnchor.constraint(equalToConstant: 20),
            ctaBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
        
        return containerView
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, position: Int) {
        guard let imageView = view.viewWithTag(100) as? UIImageView,
              let titleLabel = view.viewWithTag(101) as? UILabel,
              let ctaBadge = view.viewWithTag(102) as? UILabel else { return }
        
        titleLabel.text = ad.title
        ctaBadge.text = " \(ad.ctaText) "
        
        // Update gradient layer frame
        if let gradientLayer = imageView.layer.value(forKey: "gradient") as? CAGradientLayer {
            DispatchQueue.main.async {
                gradientLayer.frame = imageView.bounds
            }
        }
        
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
    
    public func getSize(collectionView: UICollectionView) -> CGSize {
        let width = (collectionView.frame.width - padding * CGFloat(columns + 1)) / CGFloat(columns)
        let height = width * aspectRatio
        return CGSize(width: width, height: height)
    }
}

/// Full-width card style binder for collection view ads
public class CardCollectionViewBinder: CollectionViewBinder {
    private let height: CGFloat
    
    public init(height: CGFloat = 200) {
        self.height = height
    }
    
    public func createView() -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        
        // Create card
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
        imageView.layer.cornerRadius = 12
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        imageView.backgroundColor = .tertiarySystemBackground
        imageView.tag = 100
        
        cardView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add content container
        let contentContainer = UIView()
        contentContainer.backgroundColor = .secondarySystemBackground
        
        cardView.addSubview(contentContainer)
        contentContainer.translatesAutoresizingMaskIntoConstraints = false
        
        // Add title
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.tag = 101
        
        contentContainer.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add description
        let descriptionLabel = UILabel()
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        descriptionLabel.tag = 102
        
        contentContainer.addSubview(descriptionLabel)
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Add CTA button
        let ctaButton = UIButton(type: .system)
        ctaButton.setTitleColor(.systemBlue, for: .normal)
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        ctaButton.tag = 103
        ctaButton.isUserInteractionEnabled = false
        
        contentContainer.addSubview(ctaButton)
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: cardView.heightAnchor, multiplier: 0.6),
            
            contentContainer.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            contentContainer.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: contentContainer.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            ctaButton.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor, constant: -12),
            ctaButton.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor, constant: -12)
        ])
        
        return containerView
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, position: Int) {
        guard let imageView = view.viewWithTag(100) as? UIImageView,
              let titleLabel = view.viewWithTag(101) as? UILabel,
              let descriptionLabel = view.viewWithTag(102) as? UILabel,
              let ctaButton = view.viewWithTag(103) as? UIButton else { return }
        
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
    
    public func getSize(collectionView: UICollectionView) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: height)
    }
}