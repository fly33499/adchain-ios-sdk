import Foundation
import UIKit

/// 설문조사 미션 태스크
public class SurveyMissionTask: BaseMissionTask {
    
    private let surveyUrl: String
    
    public init(
        missionId: String,
        title: String,
        description: String,
        rewardAmount: Int,
        surveyUrl: String
    ) {
        self.surveyUrl = surveyUrl
        super.init(
            missionId: missionId,
            title: title,
            description: description,
            rewardAmount: rewardAmount
        )
    }
    
    public override func execute(completion: @escaping (Bool) -> Void) {
        // Open survey URL
        if let url = URL(string: surveyUrl) {
            UIApplication.shared.open(url)
            
            // Simulate survey completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.onCompleted?()
                completion(true)
            }
        } else {
            completion(false)
        }
    }
}