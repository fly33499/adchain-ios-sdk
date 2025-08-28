import UIKit

/// Protocol for customizing how carousel items are displayed
public protocol CarouselViewBinder {
    func createView() -> UIView
    func bindView(_ view: UIView, ad: NativeAdData, at position: Int)
    func getViewType() -> Int
}

public extension CarouselViewBinder {
    func getViewType() -> Int { 0 }
}

/// Default implementation of CarouselViewBinder
/// Creates a standard card layout for carousel items
public class DefaultCarouselViewBinder: CarouselViewBinder {
    
    public init() {}
    
    public func createView() -> UIView {
        return DefaultCarouselItemView()
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, at position: Int) {
        guard let itemView = view as? DefaultCarouselItemView else { return }
        itemView.configure(with: ad)
    }
}

/// Default carousel item view
private class DefaultCarouselItemView: UIView {
    
    private let containerView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let sponsorLabel = UILabel()
    private let ctaButton = UIButton(type: .system)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Container setup
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 4
        
        // Image view setup
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        imageView.layer.cornerRadius = 12
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Title label setup
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        
        // Description label setup
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 3
        
        // Sponsor label setup
        sponsorLabel.font = .systemFont(ofSize: 12)
        sponsorLabel.textColor = .tertiaryLabel
        
        // CTA button setup
        ctaButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.backgroundColor = .systemBlue
        ctaButton.layer.cornerRadius = 6
        ctaButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(sponsorLabel)
        containerView.addSubview(ctaButton)
        
        // Setup constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        sponsorLabel.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Image
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 200),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            descriptionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Sponsor
            sponsorLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 4),
            sponsorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            sponsorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // CTA Button
            ctaButton.topAnchor.constraint(equalTo: sponsorLabel.bottomAnchor, constant: 12),
            ctaButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            ctaButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
        ])
    }
    
    func configure(with ad: NativeAdData) {
        titleLabel.text = ad.title
        descriptionLabel.text = ad.description
        ctaButton.setTitle(ad.ctaText, for: .normal)
        
        if let sponsorName = ad.sponsorName {
            sponsorLabel.text = "Sponsored by \(sponsorName)"
            sponsorLabel.isHidden = false
        } else {
            sponsorLabel.isHidden = true
        }
        
        // Load image
        if let url = URL(string: ad.imageUrl) {
            loadImage(from: url)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }
        }.resume()
    }
}

/// Simple list-style view binder for carousel
public class SimpleListViewBinder: CarouselViewBinder {
    
    public init() {}
    
    public func createView() -> UIView {
        return SimpleListItemView()
    }
    
    public func bindView(_ view: UIView, ad: NativeAdData, at position: Int) {
        guard let itemView = view as? SimpleListItemView else { return }
        itemView.configure(with: ad)
    }
    
    public func getViewType() -> Int { 1 }
}

/// Simple list item view
private class SimpleListItemView: UIView {
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        
        // Icon setup
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.layer.cornerRadius = 8
        iconImageView.backgroundColor = .systemGray6
        
        // Title setup
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        
        // Description setup
        descriptionLabel.font = .systemFont(ofSize: 12)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 2
        
        // Add subviews
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        
        // Constraints
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Icon
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Description
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            descriptionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with ad: NativeAdData) {
        titleLabel.text = ad.title
        descriptionLabel.text = ad.description
        
        // Load icon or use main image as icon
        let imageUrl = ad.iconUrl ?? ad.imageUrl
        if let url = URL(string: imageUrl) {
            loadImage(from: url)
        }
    }
    
    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.iconImageView.image = image
                }
            }
        }.resume()
    }
}