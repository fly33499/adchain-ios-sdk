# CLAUDE.md

이 파일은 이 리포지토리의 코드를 작업할 때 Claude Code (claude.ai/code)에 대한 가이드를 제공합니다.

## 빌드 명령어

### 프레임워크 빌드
```bash
# 배포용 XCFramework 빌드 (시뮬레이터 + 기기)
./build_framework.sh

# 검증과 함께 시뮬레이터 및 기기용 빌드
./build.sh

# 테스트용 시뮬레이터 전용 빠른 빌드
./build_simple.sh

# xcodebuild를 직접 사용한 빌드
cd AdChainSDK && xcodebuild -scheme AdChainSDK -destination "generic/platform=iOS Simulator" build
```

### 패키지 관리
```bash
# CocoaPods podspec 검증
pod spec lint AdChainSDK/AdChainSDK.podspec --allow-warnings

# 빠른 검증 (더 빠름)
pod lib lint AdChainSDK/AdChainSDK.podspec --allow-warnings --quick

# Swift Package 종속성 해결
cd AdChainSDK && swift package resolve
```

## 아키텍처 개요

### SDK 구조
AdChain iOS SDK는 프로토콜 기반 아키텍처를 가진 WebView 중심의 모바일 광고 SDK입니다. SDK는 의존성 주입을 사용하며 공개 프로토콜 뒤에 내부 구현을 숨깁니다.

### 핵심 구성 요소

**진입점**: `AdChainSDK` 클래스 (Sources/AdChainSDK.swift)
- `shared` 인스턴스를 가진 싱글톤 패턴
- 내부 `AdChainSDKImpl` 구현에 위임
- 프로토콜 인터페이스를 통해 모든 SDK 하위 시스템에 대한 액세스 제공

**모듈 아키텍처**:
1. **Core** - SDK 초기화, 구성, 오류 처리
   - `AdChainConfig`: 환경 설정(dev/staging/production)을 포함한 SDK 구성
   - `AdChainError`: 오류 코드가 있는 포괄적인 오류 시스템
   - `AdChainPrivacy`: 개인정보 보호 및 추적 관리 (ATT, IDFA, GDPR 준수)

2. **WebView** - WebView 기반 광고 표시
   - `AdChainWebViewProtocol`: WebView 기능을 위한 주요 인터페이스
   - JavaScript 메시지 전달 및 커스텀 이벤트 처리 지원
   - `WebViewConfig`를 통해 구성 가능

3. **Carousel** - 네이티브 캐러셀 광고 컴포넌트
   - `AdChainCarouselProtocol`: 캐러셀 기능을 위한 인터페이스
   - 델리게이트 패턴을 사용한 커스텀 UIView 구현
   - 아이템 클릭 및 노출 추적 지원

4. **Analytics** - 이벤트 추적 및 메트릭
   - `AdChainAnalyticsProtocol`: 애널리틱스 인터페이스
   - 기기 정보 수집 및 세션 관리
   - 배치 처리를 위한 이벤트 큐 시스템

5. **Network** - API 통신
   - `ApiClient`: 네트워크 요청 처리
   - `EventQueue`: 재시도 로직이 있는 배치 이벤트 처리

### 프로토콜 기반 설계
모든 공개 인터페이스는 내부 구현이 있는 프로토콜입니다:
- 공개: `*Protocol` 인터페이스 (예: `AdChainSDKProtocol`)
- 내부: `*Impl` 클래스 (예: `AdChainSDKImpl`)

이 설계는 다음을 가능하게 합니다:
- 깔끔한 API 표면
- 테스트를 위한 쉬운 모킹
- 구현 유연성

### 주요 종속성
- UI 컴포넌트를 위한 UIKit, WebKit
- 개인정보 보호를 위한 AdSupport, AppTrackingTransparency
- Keychain 액세스를 위한 Security 프레임워크

### 빌드 구성
- 최소 iOS: 13.0
- Swift 버전: 5.0+
- CocoaPods와 Swift Package Manager 모두 지원
- XCFramework를 통한 프레임워크 배포

### 중요한 파일
- `AdChainSDK.podspec`: CocoaPods 사양 (버전 1.0.0)
- `Package.swift`: Swift Package Manager 매니페스트
- 빌드 스크립트는 `output/` 디렉토리에 유니버셜 프레임워크 생성

### SDK 초기화 흐름
1. `AdChainConfig`로 구성 (API 키, 환경, 옵션)
2. `AdChainSDK.shared.initialize()`를 통해 초기화
3. SDK가 구성을 검증하고 세션 설정
4. 프로토콜 속성을 통해 컴포넌트 사용 가능

### 오류 처리
특정 오류 코드가 있는 포괄적인 오류 시스템:
- 네트워크 오류 (1xxx 범위)
- 구성 오류 (2xxx 범위)
- WebView 오류 (3xxx 범위)
- 개인정보/권한 오류 (4xxx 범위)

각 오류에는 지역화된 설명과 복구 제안이 포함됩니다.

## 추가 개선사항 제안

### 테스트
- 단위 테스트 커버리지 추가
- UI 테스트를 위한 XCUITest 구현
- 모킹을 위한 프로토콜 기반 테스트 하네스

### 문서화
- 인라인 문서를 위한 Swift DocC 주석 추가
- API 레퍼런스 자동 생성
- 통합 가이드 및 베스트 프랙티스 문서화

### 성능
- 메모리 사용량 프로파일링 및 최적화
- 네트워크 요청 캐싱 전략 개선
- WebView 성능 최적화

### 보안
- 키체인 데이터 암호화 강화
- 인증서 피닝 구현
- 코드 난독화 고려

### CI/CD
- Fastlane을 사용한 자동 빌드 및 배포
- 테스트 자동화 및 코드 커버리지 리포팅
- 자동 버전 관리 및 체인지로그 생성

### 호환성
- iOS 12 지원 고려
- Mac Catalyst 지원 추가
- SwiftUI 통합 컴포넌트 제공