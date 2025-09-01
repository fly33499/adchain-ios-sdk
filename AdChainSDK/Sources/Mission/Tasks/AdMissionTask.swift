import Foundation
import UIKit

/// 광고 미션 태스크
public class AdMissionTask: BaseMissionTask {
    
    private let adUnitId: String
    private var native: AdchainNative?
    
    public init(
        missionId: String,
        title: String,
        description: String,
        rewardAmount: Int,
        adUnitId: String
    ) {
        self.adUnitId = adUnitId
        super.init(
            missionId: missionId,
            title: title,
            description: description,
            rewardAmount: rewardAmount
        )
    }
    
    public override func execute(completion: @escaping (Bool) -> Void) {
        // Create native ad instance
        native = AdchainNative(unitId: adUnitId)
        
        // Load and show ad
        native?.load(
            onSuccess: { [weak self] ad in
                // Simulate ad participation
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self?.onCompleted?()
                    completion(true)
                }
            },
            onFailure: { error in
                completion(false)
            }
        )
    }
    
    public override func bind(to view: UIView) {
        // Bind native ad to view if needed
    }
}