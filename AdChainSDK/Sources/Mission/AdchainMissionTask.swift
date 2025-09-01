import Foundation
import UIKit

/// 미션 태스크 프로토콜
public protocol AdchainMissionTask: AnyObject {
    var missionId: String { get }
    var title: String { get }
    var description: String { get }
    var status: MissionStatus { get set }
    var rewardAmount: Int { get }
    var onCompleted: (() -> Void)? { get set }
    
    func execute(completion: @escaping (Bool) -> Void)
    func bind(to view: UIView)
}

/// 미션 상태
public enum MissionStatus {
    case pending
    case inProgress
    case completed
    case failed
    case expired
}

/// 기본 미션 태스크 구현
public class BaseMissionTask: AdchainMissionTask {
    public let missionId: String
    public let title: String
    public let description: String
    public var status: MissionStatus = .pending
    public let rewardAmount: Int
    public var onCompleted: (() -> Void)?
    
    public init(
        missionId: String,
        title: String,
        description: String,
        rewardAmount: Int
    ) {
        self.missionId = missionId
        self.title = title
        self.description = description
        self.rewardAmount = rewardAmount
    }
    
    public func execute(completion: @escaping (Bool) -> Void) {
        // Override in subclasses
        completion(false)
    }
    
    public func bind(to view: UIView) {
        // Override in subclasses
    }
}