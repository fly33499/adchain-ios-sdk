import Foundation

/// 미션 상태 관리자
public class AdchainMissionStateManager {
    
    private let userDefaults = UserDefaults.standard
    private let completedMissionsKey = "adchain.missions.completed"
    private let bonusClaimedKey = "adchain.missions.bonus"
    private let progressKey = "adchain.missions.progress"
    
    public init() {}
    
    /// 완료된 미션 ID 목록 가져오기
    public func getCompletedMissions() -> Set<String> {
        let array = userDefaults.stringArray(forKey: completedMissionsKey) ?? []
        return Set(array)
    }
    
    /// 미션 완료 표시
    public func markCompleted(_ missionId: String) {
        var completed = getCompletedMissions()
        completed.insert(missionId)
        userDefaults.set(Array(completed), forKey: completedMissionsKey)
    }
    
    /// 보너스 청구 여부 확인
    public func isBonusClaimed(for packId: String) -> Bool {
        let key = "\(bonusClaimedKey).\(packId)"
        return userDefaults.bool(forKey: key)
    }
    
    /// 보너스 청구 표시
    public func markBonusClaimed(for packId: String) {
        let key = "\(bonusClaimedKey).\(packId)"
        userDefaults.set(true, forKey: key)
    }
    
    /// 진행률 저장
    public func saveProgress(_ progress: AdchainMissionProgress) {
        let data: [String: Any] = [
            "total": progress.totalMissions,
            "completed": progress.completedMissions,
            "bonus": progress.bonusReward,
            "bonusClaimed": progress.bonusClaimed
        ]
        userDefaults.set(data, forKey: progressKey)
    }
    
    /// 진행률 로드
    public func loadProgress() -> AdchainMissionProgress? {
        guard let data = userDefaults.dictionary(forKey: progressKey) else { return nil }
        
        return AdchainMissionProgress(
            totalMissions: data["total"] as? Int ?? 0,
            completedMissions: data["completed"] as? Int ?? 0,
            bonusReward: data["bonus"] as? Int ?? 0,
            bonusClaimed: data["bonusClaimed"] as? Bool ?? false
        )
    }
    
    /// 모든 상태 초기화
    public func clearAll() {
        userDefaults.removeObject(forKey: completedMissionsKey)
        userDefaults.removeObject(forKey: bonusClaimedKey)
        userDefaults.removeObject(forKey: progressKey)
    }
    
    /// 서버 동기화
    public func syncToServer(completion: @escaping (Bool) -> Void) {
        // Simulate server sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true)
        }
    }
}