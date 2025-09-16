import Foundation
import TemplateEngine
import PathKit
import Files
import Yams
import XcodeGenKit
import ProjectSpec
import WorkspaceManager
import Utilities
import AppIconGenerator
import PackageGenerator
import enum PackageGenerator.Platform

/// Generates complete iOS MicroApps for isolated feature testing.
///
/// The `MicroAppGenerator` creates standalone iOS applications that can be used to test
/// individual features in isolation. Each MicroApp includes:
/// - Complete iOS app structure with AppDelegate and SceneDelegate
/// - XcodeGen configuration for programmatic project generation
/// - Dependency container for feature integration
/// - Assets and resources
/// - Launch screen and Info.plist
///
/// ## Features
///
/// - **Programmatic Xcode project generation** using XcodeGenKit (no external dependencies)
/// - **Template-based code generation** with Stencil templating engine
/// - **Automatic dependency resolution** for feature modules
/// - **Complete iOS app boilerplate** ready to run
///
/// ## Usage
///
/// ```swift
/// let generator = MicroAppGenerator()
/// let config = MicroAppConfiguration(
///     featureName: "AuthenticationFeature",
///     outputPath: "./MicroApps",
///     bundleIdentifier: "com.example.authapp",
///     author: "John Doe",
///     organizationName: "Example Corp"
/// )
/// try generator.generateMicroApp(config)
/// ```
public class MicroAppGenerator {
    private let templateEngine: TemplateEngine
    private let fileManager: FileManager
    private let iconGenerator: AppIconGenerator

    public init(templateEngine: TemplateEngine = TemplateEngine()) {
        self.templateEngine = templateEngine
        self.fileManager = FileManager.default
        self.iconGenerator = AppIconGenerator()
    }

    /// Generate a MicroApp for a Feature Module.
    ///
    /// Creates a complete iOS application project for testing a specific feature module in isolation.
    /// The generated MicroApp includes all necessary boilerplate code, project configuration,
    /// and assets to run immediately.
    ///
    /// - Parameter configuration: The MicroApp configuration specifying feature name, paths, and metadata
    /// - Throws: ``MicroAppError`` if generation fails due to file system issues or invalid configuration
    public func generateMicroApp(_ configuration: MicroAppConfiguration) throws {
        let microAppPath = Path(configuration.outputPath) + "\(configuration.featureName)App"

        // Create MicroApp directory
        try microAppPath.mkpath()

        // Use TemplateEngine to generate from MicroApp templates
        try generateFromTemplate(configuration, at: microAppPath)

        // Create Assets and Resources (still hardcoded as these aren't templated)
        try createAssetsDirectory(configuration, at: microAppPath)
        try generateLaunchScreen(configuration, at: microAppPath)
        try generateInfoPlist(configuration, at: microAppPath)

        // Generate Xcode project using XcodeGen (if available)
        try generateXcodeProject(at: microAppPath)

        if configuration.addToWorkspace {
            try addToWorkspace(microAppPath: microAppPath, configuration: configuration)
        }
    }

    // MARK: - Template-based Generation

    private func generateFromTemplate(_ configuration: MicroAppConfiguration, at path: Path) throws {
        // Create template variables for MicroApp generation
        let templateVariables = createTemplateVariables(configuration, outputPath: path)

        // Generate MicroApp from templates using the TemplateEngine
        try templateEngine.processTemplateDirectory(
            named: "MicroApp",
            with: templateVariables,
            to: path.string
        )
    }

    private func createTemplateVariables(_ configuration: MicroAppConfiguration, outputPath: Path) -> [String: Any] {
        let currentDate = Date()
        let isoFormatter = ISO8601DateFormatter()
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"

        // Extract iOS deployment target from platform version if available
        let deploymentTarget = extractDeploymentTarget(configuration)

        var variables: [String: Any] = [
            "ModuleName": configuration.featureName,
            "Date": isoFormatter.string(from: currentDate),
            "Year": yearFormatter.string(from: currentDate)
        ]

        let localDependencies = configuration.localDependencies.map { dependency -> [String: Any] in
            let dependencyPath = Path(dependency.packagePath).absolute()
            let relative = relativePath(from: outputPath.absolute(), to: dependencyPath)
            var products = Set(dependency.availableProducts)
            for product in dependency.productNames {
                products.insert(product)
            }
            return [
                "name": dependency.packageName,
                "path": relative,
                "products": Array(products).sorted()
            ]
        }

        variables["LocalDependencies"] = localDependencies

        // Add optional configuration values
        if let author = configuration.author {
            variables["Author"] = author
        }

        if let organizationName = configuration.organizationName {
            variables["OrganizationName"] = organizationName
        }

        if let bundleIdentifier = configuration.bundleIdentifier {
            variables["BundleIdentifier"] = bundleIdentifier
        }

        if let deploymentTarget = deploymentTarget {
            variables["DeploymentTarget"] = deploymentTarget
        }

        return variables
    }

    private func extractDeploymentTarget(_ configuration: MicroAppConfiguration) -> String? {
        // Extract iOS deployment target from platform configuration
        guard let platforms = configuration.platforms else {
            return "15.0" // Default fallback
        }

        // Find the first iOS platform and extract its version
        for platform in platforms {
            switch platform {
            case .iOS(let version):
                switch version {
                case .v12: return "12.0"
                case .v13: return "13.0"
                case .v14: return "14.0"
                case .v15: return "15.0"
                case .v16: return "16.0"
                case .v17: return "17.0"
                }
            default:
                continue // Skip non-iOS platforms
            }
        }

        return "15.0" // Default fallback if no iOS platform found
    }

    // MARK: - Legacy Methods (Removed - Now using templates)


    // MARK: - Assets and Resources

    private func createAssetsDirectory(_ configuration: MicroAppConfiguration, at path: Path) throws {
        let assetsPath = path + "Assets.xcassets"
        try assetsPath.mkpath()

        // Create AppIcon.appiconset
        let appIconPath = assetsPath + "AppIcon.appiconset"
        try appIconPath.mkpath()

        // Generate pig emoji app icons
        do {
            try iconGenerator.generateAppIcons(
                at: appIconPath.url,
                featureName: configuration.featureName
            )
            print("🐷 Generated random pig emoji app icons for \(configuration.featureName)")
        } catch {
            // Fall back to empty icon set if generation fails
            print("⚠️ Could not generate pig emoji icons, using default empty icon set")
            let fallbackContents = """
            {
              "images" : [
                {
                  "idiom" : "universal",
                  "platform" : "ios",
                  "size" : "1024x1024"
                }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """
            let contentsPath = appIconPath + "Contents.json"
            try fallbackContents.write(to: contentsPath.url, atomically: true, encoding: .utf8)
        }

        // Create AccentColor.colorset
        let accentColorPath = assetsPath + "AccentColor.colorset"
        try accentColorPath.mkpath()

        let accentColorContents = """
        {
          "colors" : [
            {
              "idiom" : "universal"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """

        let accentContentsPath = accentColorPath + "Contents.json"
        try accentColorContents.write(to: accentContentsPath.url, atomically: true, encoding: .utf8)

        // Create main Contents.json for xcassets
        let assetsContents = """
        {
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """

        let assetsContentsPath = assetsPath + "Contents.json"
        try assetsContents.write(to: assetsContentsPath.url, atomically: true, encoding: .utf8)
    }

    private func generateLaunchScreen(_ configuration: MicroAppConfiguration, at path: Path) throws {
        let launchScreenContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <document type="com.apple.InterfaceBuilder3.CocoaTouch.Storyboard.XIB" version="3.0" toolsVersion="17701" targetRuntime="iOS.CocoaTouch" propertyAccessControl="none" useAutolayout="YES" launchScreen="YES" useTraitCollections="YES" useSafeAreas="YES" colorMatched="YES" initialViewController="01J-lp-oVM">
            <device id="retina6_1" orientation="portrait" appearance="light"/>
            <dependencies>
                <plugIn identifier="com.apple.InterfaceBuilder.IBCocoaTouchPlugin" version="17703"/>
                <capability name="Safe area layout guides" minToolsVersion="9.0"/>
                <capability name="documents saved in the Xcode 8 format" minToolsVersion="8.0"/>
            </dependencies>
            <scenes>
                <scene sceneID="EHf-IW-A2E">
                    <objects>
                        <viewController id="01J-lp-oVM" sceneMemberID="viewController">
                            <view key="view" contentMode="scaleToFill" id="Ze5-6b-2t3">
                                <rect key="frame" x="0.0" y="0.0" width="414" height="896"/>
                                <autoresizingMask key="autoresizingMask" widthSizable="YES" heightSizable="YES"/>
                                <subviews>
                                    <label opaque="NO" userInteractionEnabled="NO" contentMode="left" horizontalHuggingPriority="251" verticalHuggingPriority="251" text="\(configuration.featureName)" textAlignment="center" lineBreakMode="tailTruncation" baselineAdjustment="alignBaselines" adjustsFontSizeToFit="NO" translatesAutoresizingMaskIntoConstraints="NO" id="GJd-Yh-RWb">
                                        <rect key="frame" x="127" y="438" width="160" height="21"/>
                                        <fontDescription key="fontDescription" type="system" pointSize="17"/>
                                        <color key="textColor" systemColor="labelColor"/>
                                        <nil key="highlightedColor"/>
                                    </label>
                                </subviews>
                                <viewLayoutGuide key="safeArea" id="Bcu-3y-fUS"/>
                                <color key="backgroundColor" systemColor="systemBackgroundColor"/>
                                <constraints>
                                    <constraint firstItem="GJd-Yh-RWb" firstAttribute="centerX" secondItem="Ze5-6b-2t3" secondAttribute="centerX" id="Q3B-4B-g5h"/>
                                    <constraint firstItem="GJd-Yh-RWb" firstAttribute="centerY" secondItem="Ze5-6b-2t3" secondAttribute="centerY" id="akx-eg-2nu"/>
                                </constraints>
                            </view>
                        </viewController>
                        <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
                    </objects>
                    <point key="canvasLocation" x="52.173913043478265" y="375"/>
                </scene>
            </scenes>
            <resources>
                <systemColor name="labelColor">
                    <color white="0.0" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </systemColor>
                <systemColor name="systemBackgroundColor">
                    <color white="1" alpha="1" colorSpace="custom" customColorSpace="genericGamma22GrayColorSpace"/>
                </systemColor>
            </resources>
        </document>
        """

        let launchScreenPath = path + "LaunchScreen.storyboard"
        try launchScreenContent.write(to: launchScreenPath.url, atomically: true, encoding: .utf8)
    }

    private func generateInfoPlist(_ configuration: MicroAppConfiguration, at path: Path) throws {
        let infoPlistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleDevelopmentRegion</key>
            <string>$(DEVELOPMENT_LANGUAGE)</string>
            <key>CFBundleDisplayName</key>
            <string>\(configuration.featureName)</string>
            <key>CFBundleExecutable</key>
            <string>$(EXECUTABLE_NAME)</string>
            <key>CFBundleIdentifier</key>
            <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
            <key>CFBundleInfoDictionaryVersion</key>
            <string>6.0</string>
            <key>CFBundleName</key>
            <string>$(PRODUCT_NAME)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>CFBundleShortVersionString</key>
            <string>1.0</string>
            <key>CFBundleVersion</key>
            <string>1</string>
            <key>LSRequiresIPhoneOS</key>
            <true/>
            <key>UIApplicationSceneManifest</key>
            <dict>
                <key>UIApplicationSupportsMultipleScenes</key>
                <false/>
                <key>UISceneConfigurations</key>
                <dict>
                    <key>UIWindowSceneSessionRoleApplication</key>
                    <array>
                        <dict>
                            <key>UISceneConfigurationName</key>
                            <string>Default Configuration</string>
                            <key>UISceneDelegateClassName</key>
                            <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                        </dict>
                    </array>
                </dict>
            </dict>
            <key>UILaunchScreen</key>
            <dict/>
            <key>UIRequiredDeviceCapabilities</key>
            <array>
                <string>armv7</string>
            </array>
            <key>UISupportedInterfaceOrientations</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
            </array>
            <key>UISupportedInterfaceOrientations~ipad</key>
            <array>
                <string>UIInterfaceOrientationPortrait</string>
                <string>UIInterfaceOrientationLandscapeLeft</string>
                <string>UIInterfaceOrientationLandscapeRight</string>
                <string>UIInterfaceOrientationPortraitUpsideDown</string>
            </array>
        </dict>
        </plist>
        """

        let infoPlistPath = path + "Info.plist"
        try infoPlistContent.write(to: infoPlistPath.url, atomically: true, encoding: .utf8)
    }

    // MARK: - Xcode Project Generation

    private func generateXcodeProject(at path: Path) throws {
        print("🔨 Generating Xcode project using XcodeGenKit...")

        // Ensure project.yml exists
        let projectYmlPath = path + "project.yml"
        guard projectYmlPath.exists else {
            throw MicroAppError.invalidConfiguration("project.yml not found at \(projectYmlPath)")
        }

        do {
            // Use XcodeGenKit to generate the project programmatically
            let project = try Project(path: projectYmlPath)
            let projectGenerator = ProjectGenerator(project: project)

            let generatedProject = try projectGenerator.generateXcodeProject(userName: NSUserName())
            let projectPath = path + "\(project.name).xcodeproj"

            try generatedProject.write(path: projectPath, override: true)
            print("✅ Xcode project generated successfully using XcodeGenKit")
        } catch {
            throw MicroAppError.projectGenerationFailed(error)
        }
    }

    // MARK: - Workspace Integration

    private func addToWorkspace(microAppPath: Path, configuration: MicroAppConfiguration) throws {
        guard let workspacePath = FileManager.default.findWorkspace() else {
            return // No workspace found, skip workspace integration
        }

        let workspaceManager = WorkspaceManager()
        let projectPath = microAppPath + "\(configuration.featureName)App.xcodeproj"

        // Only add if the project exists
        guard FileManager.default.fileExists(atPath: projectPath.string) else {
            return
        }

        do {
            try workspaceManager.addProjectToWorkspace(
                projectPath: projectPath.string,
                workspacePath: workspacePath,
                groupPath: "MicroApps"
            )
            print("✓ Added MicroApp project to workspace")
        } catch {
            print("⚠️  Could not add MicroApp to workspace: \(error.localizedDescription)")
        }
    }
}

// MARK: - Configuration Model

public struct MicroAppConfiguration {
    public let featureName: String
    public let outputPath: String
    public let bundleIdentifier: String?
    public let author: String?
    public let organizationName: String?
    public let platforms: [Platform]?
    public let isLocalPackage: Bool
    public let addToWorkspace: Bool
    public let localDependencies: [LocalPackageDependency]

    public init(
        featureName: String,
        outputPath: String = "./MicroApps",
        bundleIdentifier: String? = nil,
        author: String? = nil,
        organizationName: String? = nil,
        platforms: [Platform]? = nil,
        isLocalPackage: Bool = false,
        addToWorkspace: Bool = false,
        localDependencies: [LocalPackageDependency] = []
    ) {
        self.featureName = featureName
        self.outputPath = outputPath
        self.bundleIdentifier = bundleIdentifier
        self.author = author
        self.organizationName = organizationName
        self.platforms = platforms
        self.isLocalPackage = isLocalPackage
        self.addToWorkspace = addToWorkspace
        self.localDependencies = localDependencies
    }
}

// MARK: - Supporting Types

public enum MicroAppError: LocalizedError {
    case featureModuleNotFound(String)
    case xcodgenNotAvailable
    case projectGenerationFailed(Error)
    case invalidConfiguration(String)

    public var errorDescription: String? {
        switch self {
        case .featureModuleNotFound(let name):
            return "Feature module '\(name)' not found. Make sure it exists before creating a MicroApp."
        case .xcodgenNotAvailable:
            return "XcodeGen is required but not installed. Install with 'brew install xcodegen'."
        case .projectGenerationFailed(let error):
            return "Failed to generate Xcode project: \(error.localizedDescription)"
        case .invalidConfiguration(let reason):
            return "Invalid MicroApp configuration: \(reason)"
        }
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
