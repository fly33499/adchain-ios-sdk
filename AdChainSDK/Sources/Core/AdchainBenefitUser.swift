import Foundation

/// Buzzville SDK v6 호환 사용자 정보 클래스
/// Builder 패턴을 사용하여 생성합니다
public class AdchainBenefitUser {
    
    // MARK: - Properties
    
    public let userId: String
    public let gender: Gender?
    public let birthYear: Int?
    public let email: String?
    public let phoneNumber: String?
    public let nickname: String?
    public let profileImageUrl: String?
    public let customData: [String: Any]?
    public let interests: [String]?
    public let location: Location?
    public let isPremium: Bool
    public let registrationDate: Date?
    
    // MARK: - Enums
    
    public enum Gender: String {
        case male = "MALE"
        case female = "FEMALE"
        case other = "OTHER"
        case unknown = "UNKNOWN"
    }
    
    public struct Location {
        public let country: String?
        public let region: String?
        public let city: String?
        public let latitude: Double?
        public let longitude: Double?
        
        public init(
            country: String? = nil,
            region: String? = nil,
            city: String? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil
        ) {
            self.country = country
            self.region = region
            self.city = city
            self.latitude = latitude
            self.longitude = longitude
        }
    }
    
    // MARK: - Private Init
    
    private init(builder: Builder) {
        self.userId = builder.userId
        self.gender = builder.gender
        self.birthYear = builder.birthYear
        self.email = builder.email
        self.phoneNumber = builder.phoneNumber
        self.nickname = builder.nickname
        self.profileImageUrl = builder.profileImageUrl
        self.customData = builder.customData
        self.interests = builder.interests
        self.location = builder.location
        self.isPremium = builder.isPremium
        self.registrationDate = builder.registrationDate
    }
    
    // MARK: - Builder
    
    /// Builder 클래스 - Buzzville SDK v6 패턴
    public class Builder {
        
        // Required
        internal let userId: String
        
        // Optional
        internal var gender: Gender?
        internal var birthYear: Int?
        internal var email: String?
        internal var phoneNumber: String?
        internal var nickname: String?
        internal var profileImageUrl: String?
        internal var customData: [String: Any]?
        internal var interests: [String]?
        internal var location: Location?
        internal var isPremium: Bool = false
        internal var registrationDate: Date?
        
        /// Builder 초기화
        /// - Parameter userId: 사용자 ID (필수)
        public init(userId: String) {
            self.userId = userId
        }
        
        /// 성별 설정
        @discardableResult
        public func setGender(_ gender: Gender) -> Builder {
            self.gender = gender
            return self
        }
        
        /// 출생년도 설정
        @discardableResult
        public func setBirthYear(_ year: Int) -> Builder {
            // Validate birth year (1900-current year)
            let currentYear = Calendar.current.component(.year, from: Date())
            if year >= 1900 && year <= currentYear {
                self.birthYear = year
            }
            return self
        }
        
        /// 나이로 출생년도 설정
        @discardableResult
        public func setAge(_ age: Int) -> Builder {
            let currentYear = Calendar.current.component(.year, from: Date())
            let birthYear = currentYear - age
            return setBirthYear(birthYear)
        }
        
        /// 이메일 설정
        @discardableResult
        public func setEmail(_ email: String) -> Builder {
            self.email = email
            return self
        }
        
        /// 전화번호 설정
        @discardableResult
        public func setPhoneNumber(_ phoneNumber: String) -> Builder {
            self.phoneNumber = phoneNumber
            return self
        }
        
        /// 닉네임 설정
        @discardableResult
        public func setNickname(_ nickname: String) -> Builder {
            self.nickname = nickname
            return self
        }
        
        /// 프로필 이미지 URL 설정
        @discardableResult
        public func setProfileImageUrl(_ url: String) -> Builder {
            self.profileImageUrl = url
            return self
        }
        
        /// 커스텀 데이터 설정
        @discardableResult
        public func setCustomData(_ data: [String: Any]) -> Builder {
            self.customData = data
            return self
        }
        
        /// 커스텀 데이터 추가
        @discardableResult
        public func addCustomData(key: String, value: Any) -> Builder {
            if customData == nil {
                customData = [:]
            }
            customData?[key] = value
            return self
        }
        
        /// 관심사 설정
        @discardableResult
        public func setInterests(_ interests: [String]) -> Builder {
            self.interests = interests
            return self
        }
        
        /// 관심사 추가
        @discardableResult
        public func addInterest(_ interest: String) -> Builder {
            if interests == nil {
                interests = []
            }
            interests?.append(interest)
            return self
        }
        
        /// 위치 정보 설정
        @discardableResult
        public func setLocation(_ location: Location) -> Builder {
            self.location = location
            return self
        }
        
        /// 위치 정보 설정 (개별 파라미터)
        @discardableResult
        public func setLocation(
            country: String? = nil,
            region: String? = nil,
            city: String? = nil,
            latitude: Double? = nil,
            longitude: Double? = nil
        ) -> Builder {
            self.location = Location(
                country: country,
                region: region,
                city: city,
                latitude: latitude,
                longitude: longitude
            )
            return self
        }
        
        /// 프리미엄 사용자 설정
        @discardableResult
        public func setIsPremium(_ isPremium: Bool) -> Builder {
            self.isPremium = isPremium
            return self
        }
        
        /// 가입일 설정
        @discardableResult
        public func setRegistrationDate(_ date: Date) -> Builder {
            self.registrationDate = date
            return self
        }
        
        /// User 객체 생성
        public func build() -> AdchainBenefitUser {
            // Validation
            if userId.isEmpty {
                fatalError("AdchainBenefitUser: userId cannot be empty")
            }
            
            return AdchainBenefitUser(builder: self)
        }
    }
    
    // MARK: - Computed Properties
    
    /// 나이 계산
    public var age: Int? {
        guard let birthYear = birthYear else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - birthYear
    }
    
    /// 나이대 계산
    public var ageGroup: String? {
        guard let age = age else { return nil }
        
        switch age {
        case 0..<10: return "0-9"
        case 10..<20: return "10-19"
        case 20..<30: return "20-29"
        case 30..<40: return "30-39"
        case 40..<50: return "40-49"
        case 50..<60: return "50-59"
        case 60..<70: return "60-69"
        default: return "70+"
        }
    }
    
    /// 사용자 정보가 완전한지 확인
    public var isProfileComplete: Bool {
        return gender != nil && birthYear != nil && email != nil
    }
    
    /// Dictionary로 변환
    public func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["userId": userId]
        
        if let gender = gender {
            dict["gender"] = gender.rawValue
        }
        if let birthYear = birthYear {
            dict["birthYear"] = birthYear
        }
        if let email = email {
            dict["email"] = email
        }
        if let phoneNumber = phoneNumber {
            dict["phoneNumber"] = phoneNumber
        }
        if let nickname = nickname {
            dict["nickname"] = nickname
        }
        if let profileImageUrl = profileImageUrl {
            dict["profileImageUrl"] = profileImageUrl
        }
        if let customData = customData {
            dict["customData"] = customData
        }
        if let interests = interests {
            dict["interests"] = interests
        }
        if let location = location {
            var locationDict: [String: Any] = [:]
            if let country = location.country {
                locationDict["country"] = country
            }
            if let region = location.region {
                locationDict["region"] = region
            }
            if let city = location.city {
                locationDict["city"] = city
            }
            if let latitude = location.latitude {
                locationDict["latitude"] = latitude
            }
            if let longitude = location.longitude {
                locationDict["longitude"] = longitude
            }
            dict["location"] = locationDict
        }
        dict["isPremium"] = isPremium
        if let registrationDate = registrationDate {
            dict["registrationDate"] = ISO8601DateFormatter().string(from: registrationDate)
        }
        
        return dict
    }
    
    /// 디버그 정보 출력
    public func debugDescription() -> String {
        return """
        AdchainBenefitUser:
        - User ID: \(userId)
        - Gender: \(gender?.rawValue ?? "Not set")
        - Age: \(age ?? 0) (Birth year: \(birthYear ?? 0))
        - Email: \(email ?? "Not set")
        - Nickname: \(nickname ?? "Not set")
        - Premium: \(isPremium)
        - Profile Complete: \(isProfileComplete)
        """
    }
}

// MARK: - Convenience Initializers

extension AdchainBenefitUser {
    
    /// 최소 정보로 간편 생성
    public static func simple(userId: String) -> AdchainBenefitUser {
        return Builder(userId: userId).build()
    }
    
    /// 기본 정보로 생성
    public static func basic(
        userId: String,
        gender: Gender,
        birthYear: Int
    ) -> AdchainBenefitUser {
        return Builder(userId: userId)
            .setGender(gender)
            .setBirthYear(birthYear)
            .build()
    }
    
    /// 전체 정보로 생성
    public static func full(
        userId: String,
        gender: Gender,
        birthYear: Int,
        email: String,
        nickname: String
    ) -> AdchainBenefitUser {
        return Builder(userId: userId)
            .setGender(gender)
            .setBirthYear(birthYear)
            .setEmail(email)
            .setNickname(nickname)
            .build()
    }
}