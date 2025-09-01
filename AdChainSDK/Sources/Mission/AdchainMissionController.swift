import Foundation
import UIKit

/// Buzzville SDK v6 호환 미션 시스템 컨트롤러
/// 미션팩을 로드하고 관리합니다
public class AdchainMissionController {
    
    // MARK: - Properties
    
    public let unitId: String
    private var currentMissionPack: AdchainMissionPack?
    private var activeTasks: [AdchainMissionTask] = []
    private var completedTaskIds: Set<String> = []
    
    // State
    private var isLoading = false
    private var isExecutingMission = false
    
    // Managers
    private let stateManager: AdchainMissionStateManager
    private let apiClient: ApiClient
    
    // Callbacks
    public var onMissionComplete: ((String, Int) -> Void)?
    public var onBonusEarned: ((Int) -> Void)?
    public var onProgressUpdate: ((AdchainMissionProgress) -> Void)?
    
    // MARK: - Initialization
    
    public init(unitId: String) {
        self.unitId = unitId
        self.stateManager = AdchainMissionStateManager()
        
        guard let apiClient = AdchainBenefit.shared.getApiClient() else {
            fatalError("AdchainMissionController: AdchainBenefit must be initialized first")
        }
        self.apiClient = apiClient
        
        // Load saved state
        completedTaskIds = stateManager.getCompletedMissions()
        
        Logger.shared.log("AdchainMissionController initialized for unit: \(unitId)", level: .debug)
    }
    
    // MARK: - Mission Pack Management
    
    /// 미션팩 로드
    public func loadMissionPack(
        completion: @escaping (Result<AdchainMissionPack, Error>) -> Void
    ) {
        guard !isLoading else {
            completion(.failure(AdchainError.loadInProgress(message: "Mission pack is already loading")))
            return
        }
        
        isLoading = true
        
        // Simulate mission pack loading from server
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.isLoading = false
            
            // Create sample mission pack
            let missionPack = self.createSampleMissionPack()
            self.currentMissionPack = missionPack
            
            // Create tasks
            self.createTasksFromPack(missionPack)
            
            // Update progress
            self.updateProgress()
            
            Logger.shared.log("Loaded mission pack with \(missionPack.missions.count) missions", level: .debug)
            completion(.success(missionPack))
        }
    }
    
    /// 미션 실행
    public func executeMission(
        missionId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard !isExecutingMission else {
            completion(.failure(AdchainError.operationInProgress(message: "Another mission is in progress")))
            return
        }
        
        guard let task = activeTasks.first(where: { $0.missionId == missionId }) else {
            completion(.failure(AdchainError.notFound(message: "Mission not found: \(missionId)")))
            return
        }
        
        guard task.status != .completed else {
            completion(.failure(AdchainError.invalidState(message: "Mission already completed")))
            return
        }
        
        isExecutingMission = true
        task.status = .inProgress
        
        Logger.shared.log("Executing mission: \(missionId)", level: .debug)
        
        // Execute the task
        task.execute { [weak self] success in
            guard let self = self else { return }
            
            self.isExecutingMission = false
            
            if success {
                task.status = .completed
                self.completedTaskIds.insert(missionId)
                self.stateManager.markCompleted(missionId)
                
                // Calculate reward
                let reward = task.rewardAmount
                self.onMissionComplete?(missionId, reward)
                
                // Update progress
                self.updateProgress()
                
                // Check for bonus
                self.checkAndClaimBonus()
                
                Logger.shared.log("Mission completed: \(missionId), reward: \(reward)", level: .debug)
                completion(.success(()))
            } else {
                task.status = .pending
                completion(.failure(AdchainError.unknown(message: "Mission execution failed", underlyingError: nil)))
            }
        }
    }
    
    /// 보너스 보상 청구
    public func claimBonusReward() {
        guard let pack = currentMissionPack else { return }
        
        let progress = calculateProgress()
        guard progress.isCompleted && !progress.bonusClaimed else { return }
        
        // Mark bonus as claimed
        stateManager.markBonusClaimed(for: pack.id)
        
        // Give bonus reward
        let bonusAmount = pack.bonusReward
        onBonusEarned?(bonusAmount)
        
        Logger.shared.log("Bonus reward claimed: \(bonusAmount)", level: .debug)
        
        // Update progress
        updateProgress()
    }
    
    // MARK: - Progress Management
    
    /// 진행률 계산
    public func calculateProgress() -> AdchainMissionProgress {
        guard let pack = currentMissionPack else {
            return AdchainMissionProgress(
                totalMissions: 0,
                completedMissions: 0,
                bonusReward: 0,
                bonusClaimed: false
            )
        }
        
        let completed = activeTasks.filter { $0.status == .completed }.count
        let bonusClaimed = stateManager.isBonusClaimed(for: pack.id)
        
        return AdchainMissionProgress(
            totalMissions: pack.missions.count,
            completedMissions: completed,
            bonusReward: pack.bonusReward,
            bonusClaimed: bonusClaimed
        )
    }
    
    /// 진행률 업데이트
    private func updateProgress() {
        let progress = calculateProgress()
        onProgressUpdate?(progress)
        stateManager.saveProgress(progress)
    }
    
    /// 보너스 확인 및 청구
    private func checkAndClaimBonus() {
        let progress = calculateProgress()
        
        if progress.isCompleted && !progress.bonusClaimed {
            // Auto-claim bonus when all missions are completed
            claimBonusReward()
        }
    }
    
    // MARK: - Task Creation
    
    /// 미션팩으로부터 태스크 생성
    private func createTasksFromPack(_ pack: AdchainMissionPack) {
        activeTasks.removeAll()
        
        for mission in pack.missions {
            let task: AdchainMissionTask
            
            switch mission.type {
            case .ad:
                task = AdMissionTask(
                    missionId: mission.id,
                    title: mission.title,
                    description: mission.description,
                    rewardAmount: mission.reward,
                    adUnitId: mission.metadata?["adUnitId"] as? String ?? unitId
                )
                
            case .survey:
                task = SurveyMissionTask(
                    missionId: mission.id,
                    title: mission.title,
                    description: mission.description,
                    rewardAmount: mission.reward,
                    surveyUrl: mission.metadata?["surveyUrl"] as? String ?? ""
                )
                
            case .custom:
                task = CustomMissionTask(
                    missionId: mission.id,
                    title: mission.title,
                    description: mission.description,
                    rewardAmount: mission.reward,
                    actionUrl: mission.metadata?["actionUrl"] as? String ?? ""
                )
            }
            
            // Set initial status
            task.status = completedTaskIds.contains(mission.id) ? .completed : .pending
            
            activeTasks.append(task)
        }
    }
    
    /// 샘플 미션팩 생성 (테스트용)
    private func createSampleMissionPack() -> AdchainMissionPack {
        let missions = [
            AdchainMission(
                id: "mission_1",
                type: .ad,
                title: "광고 시청하기",
                description: "광고를 끝까지 시청하세요",
                reward: 10,
                metadata: ["adUnitId": unitId]
            ),
            AdchainMission(
                id: "mission_2",
                type: .ad,
                title: "광고 2개 시청",
                description: "추가 광고를 시청하세요",
                reward: 20,
                metadata: ["adUnitId": unitId]
            ),
            AdchainMission(
                id: "mission_3",
                type: .survey,
                title: "설문조사 참여",
                description: "간단한 설문에 참여하세요",
                reward: 30,
                metadata: ["surveyUrl": "https://example.com/survey"]
            ),
            AdchainMission(
                id: "mission_4",
                type: .custom,
                title: "앱 평가하기",
                description: "앱스토어에서 평가를 남겨주세요",
                reward: 50,
                metadata: ["actionUrl": "https://apps.apple.com"]
            )
        ]
        
        return AdchainMissionPack(
            id: "pack_\(Date().timeIntervalSince1970)",
            missions: missions,
            bonusReward: 100,
            expiresAt: Date().addingTimeInterval(86400) // 24 hours
        )
    }
    
    // MARK: - Getters
    
    /// 현재 미션팩 반환
    public func getCurrentPack() -> AdchainMissionPack? {
        return currentMissionPack
    }
    
    /// 활성 태스크 반환
    public func getActiveTasks() -> [AdchainMissionTask] {
        return activeTasks
    }
    
    /// 특정 태스크 반환
    public func getTask(missionId: String) -> AdchainMissionTask? {
        return activeTasks.first { $0.missionId == missionId }
    }
    
    // MARK: - State Management
    
    /// 상태 초기화
    public func resetState() {
        completedTaskIds.removeAll()
        stateManager.clearAll()
        currentMissionPack = nil
        activeTasks.removeAll()
        updateProgress()
        
        Logger.shared.log("Mission controller state reset", level: .debug)
    }
    
    /// 서버와 동기화
    public func syncToServer(completion: @escaping (Bool) -> Void) {
        stateManager.syncToServer { success in
            Logger.shared.log("Mission state sync: \(success ? "success" : "failed")", level: .debug)
            completion(success)
        }
    }
}

// MARK: - Mission Data Models

/// 미션팩
public struct AdchainMissionPack {
    public let id: String
    public let missions: [AdchainMission]
    public let bonusReward: Int
    public let expiresAt: Date
    
    public var isExpired: Bool {
        return Date() > expiresAt
    }
}

/// 개별 미션
public struct AdchainMission {
    public let id: String
    public let type: MissionType
    public let title: String
    public let description: String
    public let reward: Int
    public let metadata: [String: Any]?
    
    public enum MissionType {
        case ad
        case survey
        case custom
    }
}

/// 미션 진행률
public struct AdchainMissionProgress {
    public let totalMissions: Int
    public let completedMissions: Int
    public let bonusReward: Int
    public let bonusClaimed: Bool
    
    public var percentage: Float {
        guard totalMissions > 0 else { return 0 }
        return Float(completedMissions) / Float(totalMissions)
    }
    
    public var isCompleted: Bool {
        return completedMissions >= totalMissions && totalMissions > 0
    }
}