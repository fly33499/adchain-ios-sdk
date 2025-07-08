import UIKit

internal class AdChainCarouselImpl: AdChainCarouselProtocol {
    private let apiClient: ApiClient
    private let deviceInfoCollector: DeviceInfoCollector
    
    init(apiClient: ApiClient, deviceInfoCollector: DeviceInfoCollector) {
        self.apiClient = apiClient
        self.deviceInfoCollector = deviceInfoCollector
    }
    
    func createCarousel(
        in container: UIView,
        config: CarouselConfig,
        delegate: CarouselDelegate?
    ) -> CarouselView {
        let carouselView = CarouselViewImpl(
            config: config,
            apiClient: apiClient,
            delegate: delegate
        )
        
        container.subviews.forEach { $0.removeFromSuperview() }
        container.addSubview(carouselView)
        
        carouselView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            carouselView.topAnchor.constraint(equalTo: container.topAnchor),
            carouselView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            carouselView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            carouselView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return carouselView
    }
}