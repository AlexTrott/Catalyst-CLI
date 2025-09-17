import Foundation
import CoreGraphics
import AppKit
import Utilities

/// Error types for app icon generation
public enum AppIconError: LocalizedError {
    case failedToFetchEmoji
    case invalidURL
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .failedToFetchEmoji:
            return "Failed to fetch pig emoji from API"
        case .invalidURL:
            return "Invalid URL for emoji API"
        case .invalidImageData:
            return "Invalid image data received from API"
        }
    }
}

/// Thread-safe container for Result to avoid concurrency warnings
private final class ResultBox<T>: @unchecked Sendable {
    var result: Result<T, Error> = .failure(AppIconError.failedToFetchEmoji)
}

/// Generates modern single-size app icons with pig emojis for MicroApps
/// Uses the simplified iOS 14+ approach with a single 1024x1024 icon
public class AppIconGenerator {

    private let iconSize: CGFloat = 1024
    private let randomEmojis: [String] = [
        "20230301/u263a-ufe0f/u263a-ufe0f_u1f437.png",
        "20201001/u2639-ufe0f/u2639-ufe0f_u1f437.png",
        "20201001/u2763-ufe0f/u2763-ufe0f_u1f437.png",
        "20240610/u2764-ufe0f-u200d-u1fa79/u2764-ufe0f-u200d-u1fa79_u1f437.png",
        "20201001/u1f437/u1f437_u1f435.png",
        "20211115/u1f436/u1f436_u1f437.png",
        "20211115/u1f429/u1f429_u1f437.png",
        "20230216/u1f431/u1f431_u1f437.png",
        "20220110/u1f42f/u1f42f_u1f437.png",
        "20230803/u1f42e/u1f42e_u1f437.png",
        "20210521/u1fa84/u1fa84_u1f437.png",
        "20230301/u1f600/u1f600_u1f437.png",
        "20230301/u1f603/u1f603_u1f437.png",
        "20230301/u1f604/u1f604_u1f437.png",
        "20230301/u1f601/u1f601_u1f437.png",
        "20230301/u1f606/u1f606_u1f437.png",
        "20230301/u1f605/u1f605_u1f437.png",
        "20230301/u1f923/u1f923_u1f437.png",
        "20230301/u1f602/u1f602_u1f437.png",
        "20230301/u1f642/u1f642_u1f437.png",
        "20230301/u1f643/u1f643_u1f437.png",
        "20211115/u1fae0/u1fae0_u1f437.png",
        "20230301/u1f609/u1f609_u1f437.png",
        "20230301/u1f60a/u1f60a_u1f437.png",
        "20230301/u1f607/u1f607_u1f437.png",
        "20201001/u1f970/u1f970_u1f437.png",
        "20230301/u1f60d/u1f60d_u1f437.png",
        "20230301/u1f929/u1f929_u1f437.png",
        "20230301/u1f618/u1f618_u1f437.png",
        "20230301/u1f617/u1f617_u1f437.png",
        "20230301/u1f61a/u1f61a_u1f437.png",
        "20230301/u1f619/u1f619_u1f437.png",
        "20230216/u1f437/u1f437_u1f972.png",
        "20230301/u1f60b/u1f60b_u1f437.png",
        "20230301/u1f61b/u1f61b_u1f437.png",
        "20230301/u1f61c/u1f61c_u1f437.png",
        "20230301/u1f92a/u1f92a_u1f437.png",
        "20230301/u1f61d/u1f61d_u1f437.png",
        "20230301/u1f911/u1f911_u1f437.png",
        "20230301/u1f917/u1f917_u1f437.png",
        "20230301/u1f92d/u1f92d_u1f437.png",
        "20211115/u1fae2/u1fae2_u1f437.png",
        "20211115/u1fae3/u1fae3_u1f437.png",
        "20230301/u1f92b/u1f92b_u1f437.png",
        "20201001/u1f914/u1f914_u1f437.png",
        "20211115/u1fae1/u1fae1_u1f437.png",
        "20230301/u1f910/u1f910_u1f437.png",
        "20230301/u1f928/u1f928_u1f437.png",
        "20230301/u1f610/u1f610_u1f437.png",
        "20230301/u1f611/u1f611_u1f437.png",
        "20230301/u1f636/u1f636_u1f437.png",
        "20211115/u1fae5/u1fae5_u1f437.png",
        "20210218/u1f636-u200d-u1f32b-ufe0f/u1f636-u200d-u1f32b-ufe0f_u1f437.png",
        "20230301/u1f60f/u1f60f_u1f437.png",
        "20230301/u1f612/u1f612_u1f437.png",
        "20230301/u1f644/u1f644_u1f437.png",
        "20230301/u1f62c/u1f62c_u1f437.png",
        "20210218/u1f62e-u200d-u1f4a8/u1f62e-u200d-u1f4a8_u1f437.png",
        "20230301/u1f925/u1f925_u1f437.png",
        "20201001/u1f60c/u1f60c_u1f437.png",
        "20230301/u1f614/u1f614_u1f437.png",
        "20230301/u1f62a/u1f62a_u1f437.png",
        "20230301/u1f924/u1f924_u1f437.png",
        "20230301/u1f634/u1f634_u1f437.png",
        "20230301/u1f637/u1f637_u1f437.png",
        "20230301/u1f912/u1f912_u1f437.png",
        "20230301/u1f915/u1f915_u1f437.png",
        "20230301/u1f922/u1f922_u1f437.png",
        "20230301/u1f92e/u1f92e_u1f437.png",
        "20230301/u1f927/u1f927_u1f437.png",
        "20201001/u1f975/u1f975_u1f437.png",
        "20230301/u1f976/u1f976_u1f437.png",
        "20230301/u1f974/u1f974_u1f437.png",
        "20230301/u1f635/u1f635_u1f437.png",
        "20230301/u1f92f/u1f92f_u1f437.png",
        "20230301/u1f920/u1f920_u1f437.png",
        "20230301/u1f973/u1f973_u1f437.png",
        "20230216/u1f437/u1f437_u1f978.png",
        "20230301/u1f60e/u1f60e_u1f437.png",
        "20230301/u1f913/u1f913_u1f437.png",
        "20201001/u1f9d0/u1f9d0_u1f437.png",
        "20230301/u1f615/u1f615_u1f437.png",
        "20211115/u1fae4/u1fae4_u1f437.png",
        "20230301/u1f61f/u1f61f_u1f437.png",
        "20230301/u1f641/u1f641_u1f437.png",
        "20230301/u1f62e/u1f62e_u1f437.png",
        "20230301/u1f62f/u1f62f_u1f437.png",
        "20230301/u1f632/u1f632_u1f437.png",
        "20230301/u1f633/u1f633_u1f437.png",
        "20230301/u1f97a/u1f97a_u1f437.png",
        "20211115/u1f979/u1f979_u1f437.png",
        "20230301/u1f626/u1f626_u1f437.png",
        "20230301/u1f627/u1f627_u1f437.png",
        "20230301/u1f628/u1f628_u1f437.png",
        "20230301/u1f630/u1f630_u1f437.png",
        "20230301/u1f625/u1f625_u1f437.png",
        "20230301/u1f622/u1f622_u1f437.png",
        "20230301/u1f62d/u1f62d_u1f437.png",
        "20230301/u1f631/u1f631_u1f437.png",
        "20230301/u1f616/u1f616_u1f437.png",
        "20230301/u1f623/u1f623_u1f437.png",
        "20230301/u1f61e/u1f61e_u1f437.png",
        "20230301/u1f613/u1f613_u1f437.png",
        "20230301/u1f629/u1f629_u1f437.png",
        "20230301/u1f62b/u1f62b_u1f437.png",
        "20230301/u1f971/u1f971_u1f437.png",
        "20230301/u1f624/u1f624_u1f437.png",
        "20201001/u1f621/u1f621_u1f437.png",
        "20230301/u1f620/u1f620_u1f437.png",
        "20230301/u1f92c/u1f92c_u1f437.png",
        "20201001/u1f608/u1f608_u1f437.png",
        "20201001/u1f47f/u1f47f_u1f437.png",
        "20230216/u1f480/u1f480_u1f437.png",
        "20230216/u1f4a9/u1f4a9_u1f437.png",
        "20230301/u1f921/u1f921_u1f437.png",
        "20201001/u1f47b/u1f47b_u1f437.png",
        "20230216/u1f47d/u1f47d_u1f437.png",
        "20201001/u1f916/u1f916_u1f437.png",
        "20201001/u1f437/u1f437_u1f648.png",
        "20230216/u1f48c/u1f48c_u1f437.png",
        "20230216/u1f498/u1f498_u1f437.png",
        "20241023/u1f49d/u1f49d_u1f437.png",
        "20241023/u1f496/u1f496_u1f437.png",
        "20230818/u1f497/u1f497_u1f437.png",
        "20230216/u1f493/u1f493_u1f437.png",
        "20230216/u1f49e/u1f49e_u1f437.png",
        "20201001/u1f495/u1f495_u1f437.png",
        "20230216/u1f494/u1f494_u1f437.png",
        "20230216/u1f48b/u1f48b_u1f437.png",
        "20220815/u1f4af/u1f4af_u1f437.png",
        "20231113/u1f4a5/u1f4a5_u1f437.png",
        "20230216/u1f4ab/u1f4ab_u1f437.png",
        "20201001/u1f437/u1f437_u1f573-ufe0f.png",
        "20240206/u1f4ac/u1f4ac_u1f437.png",
        "20240206/u1f5ef-ufe0f/u1f5ef-ufe0f_u1f437.png",
        "20231128/u1f44d/u1f44d_u1f437.png",
        "20241021/u1f440/u1f440_u1f437.png",
        "20230216/u1f437/u1f437_u1f441-ufe0f.png",
        "20220203/u1fae6/u1fae6_u1f437.png",
        "20220203/u1fae6/u1fae6_u1f437.png",
        "20220815/u1f937/u1f937_u1f437.png",
        "20241021/u1f5e3-ufe0f/u1f5e3-ufe0f_u1f437.png",
        "20241021/u1f5e3-ufe0f/u1f5e3-ufe0f_u1f437.png",
        "20241021/u1f5e3-ufe0f/u1f5e3-ufe0f_u1f437.png",
        "20240530/u1f463/u1f463_u1f437.png",
        "20221101/u1f43a/u1f43a_u1f437.png",
        "20221101/u1f98a/u1f98a_u1f437.png",
        "20211115/u1f99d/u1f99d_u1f437.png",
        "20230216/u1f437/u1f437_u1f981.png",
        "20210831/u1f984/u1f984_u1f437.png",
        "20201001/u1f437/u1f437_u1f98c.png",
        "20201001/u1f437/u1f437_u1f999.png",
        "20201001/u1f994/u1f994_u1f437.png",
        "20201001/u1f437/u1f437_u1f987.png",
        "20210831/u1f43b/u1f43b_u1f437.png",
        "20230216/u1f437/u1f437_u1f43c.png",
        "20201001/u1f437/u1f437_u1f9a5.png",
        "20231113/u1f54a-ufe0f/u1f54a-ufe0f_u1f437.png",
        "20210831/u1f989/u1f989_u1f437.png",
        "20241021/u1f9a9/u1f9a9_u1f437.png",
        "20221101/u1fabf/u1fabf_u1f437.png",
        "20230803/u1f438/u1f438_u1f437.png",
        "20230418/u1f988/u1f988_u1f437.png",
        "20230216/u1f437/u1f437_u1f577-ufe0f.png",
        "20210218/u1f982/u1f982_u1f437.png",
        "20201001/u1f437/u1f437_u1f9a0.png",
        "20201001/u1f437/u1f437_u1f490.png",
        "20231113/u1f4ae/u1f4ae_u1f437.png",
        "20201001/u1f437/u1f437_u1f951.png",
        "20201001/u1f437/u1f437_u1f9c0.png",
        "20240530/u1f960/u1f960_u1f437.png",
        "20201001/u1f437/u1f437_u1f9c1.png",
        "20231113/u1f9c3/u1f9c3_u1f437.png",
        "20231113/u1f9ca/u1f9ca_u1f437.png",
        "20220406/u1faa8/u1faa8_u1f437.png",
        "20211115/u1fab5/u1fab5_u1f437.png",
        "20240530/u1f69a/u1f69a_u1f437.png",
        "20240530/u1f69a/u1f69a_u1f437.png",
        "20241021/u1f69c/u1f69c_u1f437.png",
        "20240530/u1f6a8/u1f6a8_u1f437.png",
        "20241023/u1f6a6/u1f6a6_u1f437.png",
        "20240206/u1f6d1/u1f6d1_u1f437.png",
        "20231113/u1fa82/u1fa82_u1f437.png",
        "20231113/u1f6f8/u1f6f8_u1f437.png",
        "20201001/u1f437/u1f437_u1f525.png",
        "20231113/u1f947/u1f947_u1f437.png",
        "20231113/u1f948/u1f948_u1f437.png",
        "20231113/u1f949/u1f949_u1f437.png",
        "20241021/u1f94b/u1f94b_u1f437.png",
        "20231113/u1f945/u1f945_u1f437.png",
        "20201001/u1f437/u1f437_u1f52e.png",
        "20240206/u1f9e9/u1f9e9_u1f437.png",
        "20240530/u1faa9/u1faa9_u1f437.png",
        "20231113/u1f5bc-ufe0f/u1f5bc-ufe0f_u1f437.png",
        "20240530/u1f455/u1f455_u1f437.png",
        "20241021/u1faad/u1faad_u1f437.png",
        "20240530/u1f460/u1f460_u1f437.png",
        "20230216/u1f437/u1f437_u1f451.png",
        "20230216/u1f437/u1f437_u1f48e.png",
        "20240530/u1f514/u1f514_u1f437.png",
        "20231113/u1f4df/u1f4df_u1f437.png",
        "20240610/u1f4e0/u1f4e0_u1f437.png",
        "20241021/u1f50b/u1f50b_u1f437.png",
        "20241021/u1faab/u1faab_u1f437.png",
        "20240206/u1f4bb/u1f4bb_u1f437.png",
        "20240206/u1f4be/u1f4be_u1f437.png",
        "20231113/u1f4a1/u1f4a1_u1f437.png",
        "20231113/u1f4da/u1f4da_u1f437.png",
        "20201001/u1f437/u1f437_u1f4f0.png",
        "20241021/u1f4e6/u1f4e6_u1f437.png",
        "20241021/u1f5f3-ufe0f/u1f5f3-ufe0f_u1f437.png",
        "20241021/u1f3a8/u1f3a8_u1f437.png",
        "20240206/u1f58d-ufe0f/u1f58d-ufe0f_u1f437.png",
        "20240530/u1f4c8/u1f4c8_u1f437.png",
        "20240530/u1f4c9/u1f4c9_u1f437.png",
        "20241021/u1f587-ufe0f/u1f587-ufe0f_u1f437.png",
        "20240530/u1f5d1-ufe0f/u1f5d1-ufe0f_u1f437.png",
        "20241021/u1f6e0-ufe0f/u1f6e0-ufe0f_u1f437.png",
        "20241021/u1f9f2/u1f9f2_u1f437.png",
        "20240530/u1f9ea/u1f9ea_u1f437.png",
        "20241021/u1f9ec/u1f9ec_u1f437.png",
        "20240530/u1f30c/u1f30c_u1f437.png",
        "20231113/u1faa4/u1faa4_u1f437.png",
        "20240530/u1f5d1-ufe0f/u1f5d1-ufe0f_u1f437.png",
        "20241021/u1f4f4/u1f4f4_u1f437.png",
        "20230803/u1f47e/u1f47e_u1f437.png",
        "20210831/u1f410/u1f410_u1f437.png",
        "20201001/u1f42d/u1f42d_u1f437.png",
        "20201001/u1f437/u1f437_u1f430.png",
        "20201001/u1f428/u1f428_u1f437.png",
        "20230126/u1f414/u1f414_u1f437.png",
        "20210831/u1f426/u1f426_u1f437.png",
        "20211115/u1f427/u1f427_u1f437.png",
        "20201001/u1f437/u1f437_u1f422.png",
        "20240530/u1f409/u1f409_u1f437.png",
        "20230418/u1f433/u1f433_u1f437.png",
        "20241023/u1f41f/u1f41f_u1f437.png",
        "20201001/u1f437/u1f437_u1f419.png",
        "20230216/u1f40c/u1f40c_u1f437.png",
        "20201001/u1f437/u1f437_u1f41d.png",
        "20230127/u1f338/u1f338_u1f437.png",
        "20230127/u1f339/u1f339_u1f437.png",
        "20241021/u1f33a/u1f33a_u1f437.png",
        "20230216/u1f437/u1f437_u1f33c.png",
        "20230127/u1f337/u1f337_u1f437.png",
        "20201001/u1f437/u1f437_u1f332.png",
        "20201001/u1f437/u1f437_u1f335.png",
        "20220406/u1f344/u1f344_u1f437.png",
        "20220406/u1f349/u1f349_u1f437.png",
        "20211115/u1f34a/u1f34a_u1f437.png",
        "20230127/u1f34b/u1f34b_u1f437.png",
        "20211115/u1f34c/u1f34c_u1f437.png",
        "20201001/u1f437/u1f437_u1f34d.png",
        "20220406/u1f352/u1f352_u1f437.png",
        "20230127/u1f353/u1f353_u1f437.png",
        "20230216/u1f437/u1f437_u1f336-ufe0f.png",
        "20230127/u1f35e/u1f35e_u1f437.png",
        "20201001/u1f437/u1f437_u1f32d.png",
        "20241021/u1f373/u1f373_u1f437.png",
        "20240206/u1f365/u1f365_u1f437.png",
        "20201001/u1f437/u1f437_u1f382.png",
        "20230127/u1f36c/u1f36c_u1f437.png",
        "20201001/u1f437/u1f437_u2615.png",
        "20230216/u1f437/u1f437_u1f37d-ufe0f.png",
        "20240206/u1f3fa/u1f3fa_u1f437.png",
        "20201001/u1f437/u1f437_u1f30d.png",
        "20240206/u1f30b/u1f30b_u1f437.png",
        "20241021/u1f3e0/u1f3e0_u1f437.png",
        "20240206/u1f304/u1f304_u1f437.png",
        "20230127/u1f307/u1f307_u1f437.png",
        "20241021/u1f3a2/u1f3a2_u1f437.png",
        "20231113/u26fd/u26fd_u1f437.png",
        "20241021/u2708-ufe0f/u2708-ufe0f_u1f437.png",
        "20240530/u231a/u231a_u1f437.png",
        "20241021/u23f0/u23f0_u1f437.png",
        "20201001/u1f437/u1f437_u1f31c.png",
        "20201001/u1f437/u1f437_u1f31c.png",
        "20230127/u1f31e/u1f31e_u1f437.png",
        "20201001/u1f437/u1f437_u2b50.png",
        "20201001/u1f437/u1f437_u1f31f.png",
        "20240530/u1f30c/u1f30c_u1f437.png",
        "20221107/u1f437/u1f437_u2601-ufe0f.png",
        "20240530/u26c5/u26c5_u1f437.png",
        "20221101/u1f327-ufe0f/u1f327-ufe0f_u1f437.png",
        "20241021/u1f329-ufe0f/u1f329-ufe0f_u1f437.png",
        "20230216/u1f437/u1f437_u1f32a-ufe0f.png",
        "20241021/u1f32c-ufe0f/u1f32c-ufe0f_u1f437.png",
        "20241021/u1f300/u1f300_u1f437.png",
        "20201001/u1f437/u1f437_u1f308.png",
        "20240206/u2602-ufe0f/u2602-ufe0f_u1f437.png",
        "20201001/u1f437/u1f437_u26c4.png",
        "20240530/u2604-ufe0f/u2604-ufe0f_u1f437.png",
        "20230418/u1f30a/u1f30a_u1f437.png",
        "20201001/u1f437/u1f437_u1f383.png",
        "20231113/u1f386/u1f386_u1f437.png",
        "20230216/u1f437/u1f437_u1f388.png",
        "20201001/u1f437/u1f437_u1f38a.png",
        "20211115/u1f381/u1f381_u1f437.png",
        "20240206/u1f39f-ufe0f/u1f39f-ufe0f_u1f437.png",
        "20211115/u1fae1/u1fae1_u1f437.png",
        "20240610/u1f3c6/u1f3c6_u1f437.png",
        "20240610/u1f3c6/u1f3c6_u1f437.png",
        "20220406/u26bd/u26bd_u1f437.png",
        "20241021/u26be/u26be_u1f437.png",
        "20230126/u1f3c0/u1f3c0_u1f437.png",
        "20231113/u1f3c8/u1f3c8_u1f437.png",
        "20241021/u1f3be/u1f3be_u1f437.png",
        "20240206/u1f3b3/u1f3b3_u1f437.png",
        "20240206/u1f3a3/u1f3a3_u1f437.png",
        "20231113/u1f3bf/u1f3bf_u1f437.png",
        "20240530/u1f3af/u1f3af_u1f437.png",
        "20231113/u1f3b0/u1f3b0_u1f437.png",
        "20201001/u2665-ufe0f/u2665-ufe0f_u1f437.png",
        "20240530/u1f0cf/u1f0cf_u1f437.png",
        "20240530/u1f0cf/u1f0cf_u1f437.png",
        "20241021/u1f3a8/u1f3a8_u1f437.png",
        "20241021/u1f393/u1f393_u1f437.png",
        "20240530/u1f3b6/u1f3b6_u1f437.png",
        "20241021/u1f3a4/u1f3a4_u1f437.png",
        "20230127/u1f3a7/u1f3a7_u1f437.png",
        "20240530/u1f39e-ufe0f/u1f39e-ufe0f_u1f437.png",
        "20240206/u1f3ac/u1f3ac_u1f437.png",
        "20240530/u2702-ufe0f/u2702-ufe0f_u1f437.png",
        "20240530/u1f3af/u1f3af_u1f437.png",
        "20241021/u26d3-ufe0f/u26d3-ufe0f_u1f437.png",
        "20231113/u26a0-ufe0f/u26a0-ufe0f_u1f437.png",
        "20240530/u2622-ufe0f/u2622-ufe0f_u1f437.png",
        "20241021/u262f-ufe0f/u262f-ufe0f_u1f437.png",
        "20241021/u267e-ufe0f/u267e-ufe0f_u1f437.png",
        "20240530/u2757/u2757_u1f437.png",
        "20241021/u267b-ufe0f/u267b-ufe0f_u1f437.png",
        "20241021/u2705/u2705_u1f437.png",
        "20241021/u1f193/u1f193_u1f437.png",
        "20241021/u1f195/u1f195_u1f437.png",
        "20241021/u1f197/u1f197_u1f437.png",
        "20241021/u1f198/u1f198_u1f437.png",
        "20241021/u1f199/u1f199_u1f437.png",
        "20240530/u1f40d/u1f40d_u1f437.png",
        "20240530/u1f40e/u1f40e_u1f437.png"
    ]

    public init() {}

    /// Generate modern single-size app icons with light, dark, and tinted variants
    public func generateAppIcons(at path: URL, featureName: String) throws {
        // Select a random emoji to combine with the pig
        let randomEmoji = randomEmojis.randomElement() ?? "20231113/u1f4a5/u1f4a5_u1f437.png"

        // Fetch the pig emoji combination from the API
        guard let pigEmojiImage = try fetchPigEmojiImage(withEmoji: randomEmoji) else {
            throw AppIconError.failedToFetchEmoji
        }

        // Generate the main (light mode) icon
        if let lightIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .light
        ) {
            let lightIconPath = path.appendingPathComponent("AppIcon.png")
            try lightIconData.write(to: lightIconPath)
        }

        // Generate dark mode icon
        if let darkIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .dark
        ) {
            let darkIconPath = path.appendingPathComponent("AppIcon-Dark.png")
            try darkIconData.write(to: darkIconPath)
        }

        // Generate tinted icon
        if let tintedIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .tinted
        ) {
            let tintedIconPath = path.appendingPathComponent("AppIcon-Tinted.png")
            try tintedIconData.write(to: tintedIconPath)
        }

        // Create the modern single-size Contents.json
        try createSingleSizeContentsJSON(at: path)

        Console.print("🐷 Generated app icon with pig + \(randomEmoji) combination", type: .success)
    }

    /// Fetch pig emoji image from the API
    private func fetchPigEmojiImage(withEmoji emoji: String) throws -> NSImage? {
        // URL encode the emoji
        let urlString = "https://www.gstatic.com/android/keyboard/emojikitchen/\(emoji)"

        guard let url = URL(string: urlString) else {
            throw AppIconError.invalidURL
        }

        // Fetch the image data synchronously using a different approach
        let semaphore = DispatchSemaphore(value: 0)
        let resultBox = ResultBox<Data>()

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                resultBox.result = .failure(error)
            } else if let data = data {
                resultBox.result = .success(data)
            } else {
                resultBox.result = .failure(AppIconError.invalidImageData)
            }
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        let data = try resultBox.result.get()
        guard let image = NSImage(data: data) else {
            throw AppIconError.invalidImageData
        }

        return image
    }

    /// Icon appearance modes
    private enum IconMode {
        case light
        case dark
        case tinted
    }

    /// Create an icon image from the fetched emoji image with the specified mode
    private func createIconFromImage(_ emojiImage: NSImage, size: CGSize, mode: IconMode) -> Data? {
        // Create a bitmap image rep with exact 1024x1024 dimensions
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let bitmap = bitmapRep else {
            return nil
        }

        // Create graphics context for exact pixel control
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        // Set up the background based on mode
        switch mode {
        case .light:
            // White background for light mode
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()
        case .dark:
            // Transparent background for dark mode - no fill needed
            break
        case .tinted:
            // Black background for tinted mode
            NSColor.black.setFill()
            NSRect(origin: .zero, size: size).fill()
        }

        // Calculate the size to draw the emoji (leave some padding)
        let drawSize = size.width * 0.8
        let offset = (size.width - drawSize) / 2

        let drawRect = NSRect(x: offset, y: offset, width: drawSize, height: drawSize)

        // Apply any necessary filters based on mode
        if mode == .tinted {
            // For tinted mode, we'll draw it with some transparency
            emojiImage.draw(in: drawRect, from: NSRect.zero, operation: .sourceOver, fraction: 0.7)
        } else {
            // For light and dark modes, draw normally
            emojiImage.draw(in: drawRect, from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
        }

        NSGraphicsContext.restoreGraphicsState()

        // Convert bitmap to PNG data
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        return pngData
    }

    /// Create modern single-size Contents.json for iOS 14+ / Xcode 14+
    private func createSingleSizeContentsJSON(at path: URL) throws {
        let contents: [String: Any] = [
            "images": [
                // Light mode icon
                [
                    "filename": "AppIcon.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ],
                // Dark mode icon
                [
                    "appearances": [
                        ["appearance": "luminosity", "value": "dark"]
                    ],
                    "filename": "AppIcon-Dark.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ],
                // Tinted icon
                [
                    "appearances": [
                        ["appearance": "luminosity", "value": "tinted"]
                    ],
                    "filename": "AppIcon-Tinted.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ]
            ],
            "info": [
                "author": "catalyst-cli",
                "version": 1
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
        let contentsPath = path.appendingPathComponent("Contents.json")
        try jsonData.write(to: contentsPath)
    }

    /// Create legacy multi-size Contents.json for older Xcode versions
    /// Falls back to single light mode icon repeated for all sizes
    public func createLegacyContentsJSON(at path: URL) throws {
        let contents: [String: Any] = [
            "images": [
                // Just use the single 1024x1024 icon for all sizes
                [
                    "filename": "AppIcon.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ]
            ],
            "info": [
                "author": "catalyst-cli",
                "version": 1
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
        let contentsPath = path.appendingPathComponent("Contents.json")
        try jsonData.write(to: contentsPath)
    }
}
