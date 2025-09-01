import Foundation
import UIKit

/// 커스텀 미션 태스크
public class CustomMissionTask: BaseMissionTask {
    
    private let actionUrl: String
    
    public init(
        missionId: String,
        title: String,
        description: String,
        rewardAmount: Int,
        actionUrl: String
    ) {
        self.actionUrl = actionUrl
        super.init(
            missionId: missionId,
            title: title,
            description: description,
            rewardAmount: rewardAmount
        )
    }
    
    public override func execute(completion: @escaping (Bool) -> Void) {
        // Open action URL
        if let url = URL(string: actionUrl) {
            UIApplication.shared.open(url)
            
            // Simulate action completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.onCompleted?()
                completion(true)
            }
        } else {
            completion(false)
        }
    }
}