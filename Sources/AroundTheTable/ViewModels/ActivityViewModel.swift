import Foundation

/**
 View model for **game.stencil**.
 */
struct ActivityViewModel: Codable {
    
    let base: BaseViewModel
    
    struct UserViewModel: Codable {
        
        let id: String
        let name: String
        let picture: String
        
        init(_ user: User) {
            self.id = user.id
            self.name = user.name
            self.picture = user.picture?.absoluteString ?? Settings.defaultProfilePicture
        }
    }
    
    struct ActivityViewModel: Codable {
        
        let id: String
        let host: UserViewModel
        let name: String
        let picture: String

        let game: Int?
        let playingTime: CountableClosedRange<Int>?
        let playerCount: CountableClosedRange<Int>
        let prereservedSeats: Int
        let availableSeats: Int
        let requiredPlayerCountReached: Bool
        let seatOptions: [Int]

        let date: String
        let time: String
        let isOver: Bool
        let deadlineDate: String
        let deadlineTime: String
        let deadlineHasPassed: Bool

        let location: Location
        let distance: Int

        let info: String
        let isCancelled: Bool
        
        init(_ activity: Activity) throws {
            guard let id = activity.id,
                  let distance = activity.distance else {
                throw log(ServerError.unpersistedEntity)
            }
            self.id = id.hexString
            self.host = UserViewModel(activity.host)
            self.name = activity.name
            self.picture = activity.game?.picture?.absoluteString ?? Settings.defaultGamePicture
            self.game = activity.game?.id
            self.playingTime = activity.game?.playingTime
            self.playerCount = activity.playerCount
            self.prereservedSeats = activity.prereservedSeats
            self.availableSeats = activity.availableSeats
            self.requiredPlayerCountReached = playerCount.upperBound - availableSeats >= playerCount.lowerBound
            self.seatOptions = availableSeats > 0 ? Array(1...availableSeats) : Array(1...playerCount.upperBound)
            self.date = activity.date.formatted(dateStyle: .full)
            self.time = activity.date.formatted(timeStyle: .short)
            self.isOver = activity.date.compare(Date()) == .orderedAscending
            self.deadlineDate = activity.deadline.formatted(dateStyle: .full)
            self.deadlineTime = activity.deadline.formatted(timeStyle: .short)
            self.deadlineHasPassed = activity.deadline.compare(Date()) == .orderedAscending
            self.location = activity.location
            self.distance = Int(ceil(distance / 1000))
            self.info = activity.info
            self.isCancelled = activity.isCancelled
        }
    }
    
    let activity: ActivityViewModel
    
    struct RegistrationViewModel: Codable {
        
        let player: UserViewModel
        let seats: Int
        let willCauseOverBooking: Bool
        
        init(_ registration: Activity.Registration, for activity: Activity) throws {
            self.player = UserViewModel(registration.player)
            self.seats = registration.seats
            self.willCauseOverBooking = registration.seats > activity.availableSeats
        }
    }
    
    let approvedRegistrations: [RegistrationViewModel]
    let pendingRegistrations: [RegistrationViewModel]
    
    let userIsHost: Bool
    let userIsPlayer: Bool
    let userIsPending: Bool
    
    init(base: BaseViewModel, user: User?, activity: Activity) throws {
        self.base = base
        self.activity = try ActivityViewModel(activity)
        self.approvedRegistrations = try activity.approvedRegistrations.map { try RegistrationViewModel($0, for: activity) }
        self.pendingRegistrations = try activity.pendingRegistrations.map { try RegistrationViewModel($0, for: activity) }
        self.userIsHost = activity.host == user
        self.userIsPlayer = activity.approvedRegistrations.contains { $0.player == user }
        self.userIsPending = activity.pendingRegistrations.contains { $0.player == user }
    }
}
