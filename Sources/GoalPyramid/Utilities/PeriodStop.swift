import Foundation

/// "Бүгін"/"Апта"/"Ай"/"5 Жыл" сайдбар тармақтарының бәрі ортақ пайдаланатын,
/// push-сыз иерархиялық навигация күйі. Мән ауысқанда `PeriodExplorerView`
/// жай ғана қайта renders болады — NavigationLink push жоқ, сондықтан
/// macOS-тың өз "артқа" батырмасы ешқашан қосарланып шықпайды.
enum PeriodStop: Hashable {
    case years
    case year(Int)
    case months(Int)
    case month(Date)
    case weeks(Date)
    case week(Date)
    case days(Date)
    case day(Date)
}
