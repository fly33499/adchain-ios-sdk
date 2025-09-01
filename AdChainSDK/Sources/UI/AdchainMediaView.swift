import UIKit
import AVFoundation
import AVKit

/// Buzzville SDK v6 호환 미디어 뷰
/// 이미지와 비디오를 자동으로 전환하여 표시합니다
public class AdchainMediaView: UIView {
    
    // MARK: - Properties
    
    private var currentAd: AdchainNativeAd?
    
    // Image view
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    // Video player
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var playerObserver: Any?
    
    // Loading indicator
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        return indicator
    }()
    
    // Play button overlay (for video)
    private lazy var playButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular)
        button.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        button.layer.cornerRadius = 35
        button.isHidden = true
        button.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // Video controls
    private lazy var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "speaker.wave.2.fill"), for: .normal)
        button.setImage(UIImage(systemName: "speaker.slash.fill"), for: .selected)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 15
        button.isHidden = true
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // State
    private var isVideoPlaying = false
    private var isMuted = true
    private var imageLoadingTask: URLSessionDataTask?
    
    // Configuration
    public var autoPlayVideo = true
    public var defaultMuted = true
    public var showPlayButton = true
    public var showMuteButton = true
    
    // Delegate
    public weak var delegate: AdchainMediaViewDelegate?
    
    // MARK: - Initialization
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .systemGray6
        
        // Add image view
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add loading indicator
        addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        
        // Add play button
        addSubview(playButton)
        playButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        // Add mute button
        addSubview(muteButton)
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            muteButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            muteButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            muteButton.widthAnchor.constraint(equalToConstant: 30),
            muteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Set initial mute state
        muteButton.isSelected = defaultMuted
        isMuted = defaultMuted
        
        Logger.shared.log("AdchainMediaView initialized", level: .debug)
    }
    
    // MARK: - Public Methods
    
    /// 광고 로드
    public func loadAd(_ ad: AdchainNativeAd) {
        clear()
        
        self.currentAd = ad
        
        if ad.isVideo, let videoUrl = ad.videoUrl {
            loadVideo(from: videoUrl)
        } else {
            loadImage(from: ad.imageUrl)
        }
        
        delegate?.mediaViewDidStartLoading(self)
    }
    
    /// 미디어 지우기
    public func clear() {
        // Stop video if playing
        stopVideo()
        
        // Cancel image loading
        imageLoadingTask?.cancel()
        imageLoadingTask = nil
        
        // Clear content
        imageView.image = nil
        currentAd = nil
        
        // Hide controls
        playButton.isHidden = true
        muteButton.isHidden = true
        
        Logger.shared.log("Cleared media view", level: .debug)
    }
    
    /// 비디오 재생
    public func play() {
        guard let player = player, !isVideoPlaying else { return }
        
        player.play()
        isVideoPlaying = true
        playButton.isHidden = true
        
        delegate?.mediaViewDidStartPlayingVideo(self)
        
        Logger.shared.log("Started video playback", level: .debug)
    }
    
    /// 비디오 일시정지
    public func pause() {
        guard let player = player, isVideoPlaying else { return }
        
        player.pause()
        isVideoPlaying = false
        playButton.isHidden = !showPlayButton
        
        delegate?.mediaViewDidPauseVideo(self)
        
        Logger.shared.log("Paused video playback", level: .debug)
    }
    
    /// 음소거 토글
    public func toggleMute() {
        isMuted = !isMuted
        player?.isMuted = isMuted
        muteButton.isSelected = isMuted
        
        Logger.shared.log("Toggled mute: \(isMuted)", level: .debug)
    }
    
    // MARK: - Private Methods
    
    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else {
            delegate?.mediaViewDidFailLoading(self, error: AdChainError.invalidUrl(url: urlString))
            return
        }
        
        loadingIndicator.startAnimating()
        
        imageLoadingTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                if let error = error {
                    self.delegate?.mediaViewDidFailLoading(self, error: error)
                    Logger.shared.log("Failed to load image: \(error)", level: .error)
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    self.delegate?.mediaViewDidFailLoading(
                        self,
                        error: AdChainError.invalidData(message: "Invalid image data")
                    )
                    return
                }
                
                self.imageView.image = image
                self.delegate?.mediaViewDidFinishLoading(self)
                
                Logger.shared.log("Loaded image successfully", level: .debug)
            }
        }
        
        imageLoadingTask?.resume()
    }
    
    private func loadVideo(from urlString: String) {
        guard let url = URL(string: urlString) else {
            delegate?.mediaViewDidFailLoading(self, error: AdChainError.invalidUrl(url: urlString))
            return
        }
        
        loadingIndicator.startAnimating()
        
        // Create player
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = isMuted
        
        // Create player layer
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = bounds
        
        // Add player layer
        layer.insertSublayer(playerLayer, at: 0)
        self.playerLayer = playerLayer
        
        // Show controls
        playButton.isHidden = !showPlayButton || autoPlayVideo
        muteButton.isHidden = !showMuteButton
        
        // Observe player status
        playerObserver = playerItem.observe(\.status) { [weak self] item, _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.loadingIndicator.stopAnimating()
                
                switch item.status {
                case .readyToPlay:
                    self.delegate?.mediaViewDidFinishLoading(self)
                    
                    if self.autoPlayVideo {
                        self.play()
                    }
                    
                    Logger.shared.log("Video ready to play", level: .debug)
                    
                case .failed:
                    self.delegate?.mediaViewDidFailLoading(
                        self,
                        error: item.error ?? AdChainError.unknown(message: "Video load failed", underlyingError: nil)
                    )
                    Logger.shared.log("Failed to load video", level: .error)
                    
                default:
                    break
                }
            }
        }
        
        // Observe playback completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(videoDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
    }
    
    private func stopVideo() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        playerObserver = nil
        isVideoPlaying = false
        
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    // MARK: - Actions
    
    @objc private func playButtonTapped() {
        play()
    }
    
    @objc private func muteButtonTapped() {
        toggleMute()
    }
    
    @objc private func videoDidFinishPlaying() {
        isVideoPlaying = false
        playButton.isHidden = !showPlayButton
        
        delegate?.mediaViewDidFinishPlayingVideo(self)
        
        // Loop video if needed
        if autoPlayVideo {
            player?.seek(to: .zero)
            play()
        }
        
        Logger.shared.log("Video finished playing", level: .debug)
    }
    
    // MARK: - Layout
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        // Update player layer frame
        playerLayer?.frame = bounds
    }
    
    // MARK: - View Lifecycle
    
    public override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            // Pause video when view is removed
            if isVideoPlaying {
                pause()
            }
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        clear()
    }
}

// MARK: - Delegate Protocol

public protocol AdchainMediaViewDelegate: AnyObject {
    /// 미디어 로딩 시작
    func mediaViewDidStartLoading(_ view: AdchainMediaView)
    
    /// 미디어 로딩 완료
    func mediaViewDidFinishLoading(_ view: AdchainMediaView)
    
    /// 미디어 로딩 실패
    func mediaViewDidFailLoading(_ view: AdchainMediaView, error: Error)
    
    /// 비디오 재생 시작
    func mediaViewDidStartPlayingVideo(_ view: AdchainMediaView)
    
    /// 비디오 일시정지
    func mediaViewDidPauseVideo(_ view: AdchainMediaView)
    
    /// 비디오 재생 완료
    func mediaViewDidFinishPlayingVideo(_ view: AdchainMediaView)
}

// MARK: - Default Delegate Implementation

public extension AdchainMediaViewDelegate {
    func mediaViewDidStartLoading(_ view: AdchainMediaView) {}
    func mediaViewDidFinishLoading(_ view: AdchainMediaView) {}
    func mediaViewDidFailLoading(_ view: AdchainMediaView, error: Error) {}
    func mediaViewDidStartPlayingVideo(_ view: AdchainMediaView) {}
    func mediaViewDidPauseVideo(_ view: AdchainMediaView) {}
    func mediaViewDidFinishPlayingVideo(_ view: AdchainMediaView) {}
}