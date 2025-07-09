;; ReservePoints - Hotel Booking and Loyalty Rewards System
;; A decentralized platform for hotel bookings with integrated loyalty rewards

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))
(define-constant err-booking-not-active (err u105))
(define-constant err-insufficient-payment (err u106))
(define-constant err-invalid-dates (err u107))

;; Data Variables
(define-data-var booking-counter uint u0)
(define-data-var hotel-counter uint u0)

;; Data Maps
(define-map hotels
  { hotel-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    location: (string-ascii 100),
    price-per-night: uint,
    active: bool
  }
)

(define-map bookings
  { booking-id: uint }
  {
    guest: principal,
    hotel-id: uint,
    check-in: uint,
    check-out: uint,
    total-cost: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map guest-loyalty
  { guest: principal }
  {
    total-points: uint,
    total-bookings: uint,
    tier: (string-ascii 20)
  }
)

;; Private Functions
(define-private (calculate-loyalty-points (amount uint))
  (/ (* amount u10) u100) ;; 10% of booking amount as points
)

(define-private (determine-loyalty-tier (points uint))
  (if (>= points u10000)
    "Platinum"
    (if (>= points u5000)
      "Gold"
      (if (>= points u2000)
        "Silver"
        "Bronze"
      )
    )
  )
)

(define-private (is-valid-date-range (check-in uint) (check-out uint))
  (and
    (> check-in stacks-block-height)
    (> check-out check-in)
  )
)

;; Public Functions

;; Register a new hotel
(define-public (register-hotel (name (string-ascii 50)) (location (string-ascii 100)) (price-per-night uint))
  (let
    (
      (hotel-id (+ (var-get hotel-counter) u1))
    )
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len location) u0) err-invalid-input)
    (asserts! (> price-per-night u0) err-invalid-input)
    
    (map-set hotels
      { hotel-id: hotel-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        price-per-night: price-per-night,
        active: true
      }
    )
    (var-set hotel-counter hotel-id)
    (ok hotel-id)
  )
)

;; Create a new booking
(define-public (create-booking (hotel-id uint) (check-in uint) (check-out uint))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (let
      (
        (hotel (unwrap! (map-get? hotels { hotel-id: hotel-id }) err-not-found))
        (booking-id (+ (var-get booking-counter) u1))
        (nights (- check-out check-in))
        (total-cost (* nights (get price-per-night hotel)))
        (loyalty-points (calculate-loyalty-points total-cost))
        (current-loyalty (default-to { total-points: u0, total-bookings: u0, tier: "Bronze" }
                          (map-get? guest-loyalty { guest: tx-sender })))
      )
      (asserts! (get active hotel) err-not-found)
      (asserts! (is-valid-date-range check-in check-out) err-invalid-dates)
      (asserts! (> nights u0) err-invalid-input)
      
      ;; Create booking
      (map-set bookings
        { booking-id: booking-id }
        {
          guest: tx-sender,
          hotel-id: hotel-id,
          check-in: check-in,
          check-out: check-out,
          total-cost: total-cost,
          status: "confirmed",
          created-at: stacks-block-height
        }
      )
      
      ;; Update loyalty points
      (let
        (
          (new-points (+ (get total-points current-loyalty) loyalty-points))
          (new-bookings (+ (get total-bookings current-loyalty) u1))
          (new-tier (determine-loyalty-tier new-points))
        )
        (map-set guest-loyalty
          { guest: tx-sender }
          {
            total-points: new-points,
            total-bookings: new-bookings,
            tier: new-tier
          }
        )
      )
      
      (var-set booking-counter booking-id)
      (ok booking-id)
    )
  )
)

;; Cancel a booking
(define-public (cancel-booking (booking-id uint))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
    (let
      (
        (booking (unwrap! (map-get? bookings { booking-id: booking-id }) err-not-found))
      )
      (asserts! (is-eq (get guest booking) tx-sender) err-unauthorized)
      (asserts! (is-eq (get status booking) "confirmed") err-booking-not-active)
      
      (map-set bookings
        { booking-id: booking-id }
        (merge booking { status: "cancelled" })
      )
      (ok true)
    )
  )
)

;; Update hotel details (owner only)
(define-public (update-hotel (hotel-id uint) (name (string-ascii 50)) (location (string-ascii 100)) (price-per-night uint))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (let
      (
        (hotel (unwrap! (map-get? hotels { hotel-id: hotel-id }) err-not-found))
      )
      (asserts! (is-eq (get owner hotel) tx-sender) err-unauthorized)
      (asserts! (> (len name) u0) err-invalid-input)
      (asserts! (> (len location) u0) err-invalid-input)
      (asserts! (> price-per-night u0) err-invalid-input)
      
      (map-set hotels
        { hotel-id: hotel-id }
        (merge hotel {
          name: name,
          location: location,
          price-per-night: price-per-night
        })
      )
      (ok true)
    )
  )
)

;; Toggle hotel active status
(define-public (toggle-hotel-status (hotel-id uint))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (let
      (
        (hotel (unwrap! (map-get? hotels { hotel-id: hotel-id }) err-not-found))
      )
      (asserts! (is-eq (get owner hotel) tx-sender) err-unauthorized)
      
      (map-set hotels
        { hotel-id: hotel-id }
        (merge hotel { active: (not (get active hotel)) })
      )
      (ok true)
    )
  )
)

;; Read-only functions

;; Get hotel details
(define-read-only (get-hotel (hotel-id uint))
  (begin
    (asserts! (> hotel-id u0) (err u103))
    (ok (map-get? hotels { hotel-id: hotel-id }))
  )
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (begin
    (asserts! (> booking-id u0) (err u103))
    (ok (map-get? bookings { booking-id: booking-id }))
  )
)

;; Get guest loyalty info
(define-read-only (get-guest-loyalty (guest principal))
  (map-get? guest-loyalty { guest: guest })
)

;; Get current counters
(define-read-only (get-counters)
  {
    booking-counter: (var-get booking-counter),
    hotel-counter: (var-get hotel-counter)
  }
)

;; Get loyalty tier benefits
(define-read-only (get-tier-benefits (tier (string-ascii 20)))
  (if (is-eq tier "Platinum")
    { discount: u20, bonus-points: u50 }
    (if (is-eq tier "Gold")
      { discount: u15, bonus-points: u30 }
      (if (is-eq tier "Silver")
        { discount: u10, bonus-points: u20 }
        { discount: u5, bonus-points: u10 }
      )
    )
  )
)