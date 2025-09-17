;; ReservePoints - Hotel Booking and Loyalty Rewards System with NFT Room Keys
;; A decentralized platform for hotel bookings with integrated loyalty rewards and NFT-based digital room keys

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
(define-constant err-unsupported-currency (err u108))
(define-constant err-payment-failed (err u109))
(define-constant err-nft-exists (err u110))
(define-constant err-nft-not-found (err u111))
(define-constant err-nft-not-valid (err u112))

;; Supported currencies
(define-constant currency-stx "STX")
(define-constant currency-btc "BTC")
(define-constant currency-usdc "USDC")
(define-constant currency-usdt "USDT")

;; NFT Implementation (SIP-009)
(define-non-fungible-token room-key uint)

;; Data Variables
(define-data-var booking-counter uint u0)
(define-data-var hotel-counter uint u0)
(define-data-var room-key-counter uint u0)

;; Data Maps
(define-map hotels
  { hotel-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    location: (string-ascii 100),
    price-per-night: uint,
    accepted-currencies: (list 10 (string-ascii 10)),
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
    currency: (string-ascii 10),
    payment-status: (string-ascii 20),
    status: (string-ascii 20),
    room-key-id: (optional uint),
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

;; Currency exchange rates (in relation to STX, multiplied by 1000000 for precision)
(define-map exchange-rates
  { currency: (string-ascii 10) }
  { rate-to-stx: uint }
)

;; Supported token contracts for payments
(define-map token-contracts
  { currency: (string-ascii 10) }
  { contract: principal }
)

;; NFT Room Key data
(define-map room-key-data
  { token-id: uint }
  {
    booking-id: uint,
    guest: principal,
    hotel-id: uint,
    room-number: (string-ascii 20),
    check-in: uint,
    check-out: uint,
    metadata-uri: (optional (string-utf8 200)),
    issued-at: uint
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

(define-private (is-supported-currency (currency (string-ascii 10)))
  (or
    (is-eq currency currency-stx)
    (or
      (is-eq currency currency-btc)
      (or
        (is-eq currency currency-usdc)
        (is-eq currency currency-usdt)
      )
    )
  )
)

(define-private (currency-accepted-by-hotel (hotel-currencies (list 10 (string-ascii 10))) (currency (string-ascii 10)))
  (is-some (index-of hotel-currencies currency))
)

(define-private (convert-currency-amount (amount uint) (from-currency (string-ascii 10)) (to-currency (string-ascii 10)))
  (if (is-eq from-currency to-currency)
    amount
    (let
      (
        (from-rate (default-to u1000000 (get rate-to-stx (map-get? exchange-rates { currency: from-currency }))))
        (to-rate (default-to u1000000 (get rate-to-stx (map-get? exchange-rates { currency: to-currency }))))
      )
      (/ (* amount from-rate) to-rate)
    )
  )
)

(define-private (is-room-key-currently-valid (token-id uint))
  (match (map-get? room-key-data { token-id: token-id })
    room-key-info
    (let
      (
        (check-in (get check-in room-key-info))
        (check-out (get check-out room-key-info))
        (current-height stacks-block-height)
        ;; Add 1 day buffer (approximately 144 blocks) after check-out
        (expiry-height (+ check-out u144))
      )
      (and
        (<= check-in current-height)
        (< current-height expiry-height)
      )
    )
    false
  )
)

;; NFT Standard Functions (SIP-009)
(define-read-only (get-last-token-id)
  (ok (var-get room-key-counter))
)

(define-read-only (get-token-uri (token-id uint))
  (match (map-get? room-key-data { token-id: token-id })
    room-key-info (ok (get metadata-uri room-key-info))
    (err err-nft-not-found)
  )
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? room-key token-id))
)

;; Public Functions

;; Initialize exchange rates (contract owner only)
(define-public (set-exchange-rate (currency (string-ascii 10)) (rate-to-stx uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-supported-currency currency) err-unsupported-currency)
    (asserts! (> rate-to-stx u0) err-invalid-input)
    
    (map-set exchange-rates
      { currency: currency }
      { rate-to-stx: rate-to-stx }
    )
    (ok true)
  )
)

;; Set token contract for a currency (contract owner only)
(define-public (set-token-contract (currency (string-ascii 10)) (contract principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-supported-currency currency) err-unsupported-currency)
    (asserts! (is-valid-contract contract) err-invalid-input)
    
    (map-set token-contracts
      { currency: currency }
      { contract: contract }
    )
    (ok true)
  )
)

;; Register a new hotel with accepted currencies
(define-public (register-hotel (name (string-ascii 50)) (location (string-ascii 100)) (price-per-night uint) (accepted-currencies (list 10 (string-ascii 10))))
  (let
    (
      (hotel-id (+ (var-get hotel-counter) u1))
    )
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len location) u0) err-invalid-input)
    (asserts! (> price-per-night u0) err-invalid-input)
    (asserts! (> (len accepted-currencies) u0) err-invalid-input)
    
    (map-set hotels
      { hotel-id: hotel-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        price-per-night: price-per-night,
        accepted-currencies: accepted-currencies,
        active: true
      }
    )
    (var-set hotel-counter hotel-id)
    (ok hotel-id)
  )
)

;; Create a new booking with specific currency
(define-public (create-booking (hotel-id uint) (check-in uint) (check-out uint) (currency (string-ascii 10)))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (asserts! (is-supported-currency currency) err-unsupported-currency)
    
    (match (map-get? hotels { hotel-id: hotel-id })
      hotel
      (let
        (
          (booking-id (+ (var-get booking-counter) u1))
          (nights (- check-out check-in))
          (base-cost (* nights (get price-per-night hotel)))
          (total-cost (convert-currency-amount base-cost currency-stx currency))
          (loyalty-points (calculate-loyalty-points base-cost))
          (current-loyalty (default-to { total-points: u0, total-bookings: u0, tier: "Bronze" }
                            (map-get? guest-loyalty { guest: tx-sender })))
        )
        (asserts! (get active hotel) err-not-found)
        (asserts! (is-valid-date-range check-in check-out) err-invalid-dates)
        (asserts! (> nights u0) err-invalid-input)
        (asserts! (currency-accepted-by-hotel (get accepted-currencies hotel) currency) err-unsupported-currency)
        
        ;; Create booking
        (map-set bookings
          { booking-id: booking-id }
          {
            guest: tx-sender,
            hotel-id: hotel-id,
            check-in: check-in,
            check-out: check-out,
            total-cost: total-cost,
            currency: currency,
            payment-status: "pending",
            status: "confirmed",
            room-key-id: none,
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
      err-not-found
    )
  )
)

;; Mint room key NFT for confirmed booking (hotel owner only)
(define-public (mint-room-key (booking-id uint) (room-number (string-ascii 20)) (metadata-uri (optional (string-utf8 200))))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
    (asserts! (> (len room-number) u0) err-invalid-input)
    
    (match (map-get? bookings { booking-id: booking-id })
      booking
      (let
        (
          (hotel-id (get hotel-id booking))
          (token-id (+ (var-get room-key-counter) u1))
        )
        (match (map-get? hotels { hotel-id: hotel-id })
          hotel
          (begin
            (asserts! (is-eq (get owner hotel) tx-sender) err-unauthorized)
            (asserts! (is-eq (get payment-status booking) "completed") err-booking-not-active)
            (asserts! (is-none (get room-key-id booking)) err-nft-exists)
            
            ;; Mint NFT to guest
            (try! (nft-mint? room-key token-id (get guest booking)))
            
            ;; Store room key data
            (map-set room-key-data
              { token-id: token-id }
              {
                booking-id: booking-id,
                guest: (get guest booking),
                hotel-id: hotel-id,
                room-number: room-number,
                check-in: (get check-in booking),
                check-out: (get check-out booking),
                metadata-uri: (if (is-some metadata-uri) metadata-uri none),
                issued-at: stacks-block-height
              }
            )
            
            ;; Update booking with room key ID
            (map-set bookings
              { booking-id: booking-id }
              (merge booking { room-key-id: (some token-id) })
            )
            
            (var-set room-key-counter token-id)
            (ok token-id)
          )
          err-not-found
        )
      )
      err-not-found
    )
  )
)

;; Process payment for a booking and automatically mint room key
(define-public (process-payment (booking-id uint))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
    
    (match (map-get? bookings { booking-id: booking-id })
      booking
      (let
        (
          (hotel-id (get hotel-id booking))
        )
        (match (map-get? hotels { hotel-id: hotel-id })
          hotel
          (begin
            (asserts! (is-eq (get guest booking) tx-sender) err-unauthorized)
            (asserts! (is-eq (get payment-status booking) "pending") err-booking-not-active)
            
            ;; Process STX payment
            (if (is-eq (get currency booking) currency-stx)
              (try! (stx-transfer? (get total-cost booking) tx-sender (get owner hotel)))
              ;; For other currencies, mark as paid (actual token transfer would be handled by frontend/relayer)
              true
            )
            
            ;; Update payment status
            (map-set bookings
              { booking-id: booking-id }
              (merge booking { payment-status: "completed" })
            )
            
            ;; Auto-mint room key with default room number
            (let
              (
                (token-id (+ (var-get room-key-counter) u1))
              )
              (try! (nft-mint? room-key token-id (get guest booking)))
              
              (map-set room-key-data
                { token-id: token-id }
                {
                  booking-id: booking-id,
                  guest: (get guest booking),
                  hotel-id: hotel-id,
                  room-number: "AUTO-ASSIGNED",
                  check-in: (get check-in booking),
                  check-out: (get check-out booking),
                  metadata-uri: none,
                  issued-at: stacks-block-height
                }
              )
              
              (map-set bookings
                { booking-id: booking-id }
                (merge booking { 
                  payment-status: "completed",
                  room-key-id: (some token-id)
                })
              )
              
              (var-set room-key-counter token-id)
              (ok token-id)
            )
          )
          err-not-found
        )
      )
      err-not-found
    )
  )
)

;; Transfer room key NFT
(define-public (transfer-room-key (token-id uint) (recipient principal))
  (begin
    (asserts! (> token-id u0) err-invalid-input)
    (asserts! (not (is-eq tx-sender recipient)) err-invalid-input)
    
    (match (nft-get-owner? room-key token-id)
      owner
      (begin
        (asserts! (is-eq tx-sender owner) err-unauthorized)
        (try! (nft-transfer? room-key token-id tx-sender recipient))
        (ok true)
      )
      err-nft-not-found
    )
  )
)

;; Burn room key NFT (for cancellations or expired keys)
(define-public (burn-room-key (token-id uint))
  (begin
    (asserts! (> token-id u0) err-invalid-input)
    
    (match (nft-get-owner? room-key token-id)
      owner
      (match (map-get? room-key-data { token-id: token-id })
        room-key-info
        (let
          (
            (booking-id (get booking-id room-key-info))
          )
          (match (map-get? bookings { booking-id: booking-id })
            booking
            (let
              (
                (hotel-id (get hotel-id booking))
              )
              (match (map-get? hotels { hotel-id: hotel-id })
                hotel
                (begin
                  ;; Allow burning by owner (guest), hotel owner, or if key is expired
                  (asserts! (or 
                            (is-eq tx-sender owner)
                            (is-eq tx-sender (get owner hotel))
                            (not (is-room-key-currently-valid token-id))
                          ) err-unauthorized)
                  
                  (try! (nft-burn? room-key token-id owner))
                  (map-delete room-key-data { token-id: token-id })
                  (ok true)
                )
                err-not-found
              )
            )
            err-not-found
          )
        )
        err-nft-not-found
      )
      err-nft-not-found
    )
  )
)

;; Cancel a booking with potential refund and room key burning
(define-public (cancel-booking (booking-id uint))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
    
    (match (map-get? bookings { booking-id: booking-id })
      booking
      (let
        (
          (hotel-id (get hotel-id booking))
        )
        (match (map-get? hotels { hotel-id: hotel-id })
          hotel
          (begin
            (asserts! (is-eq (get guest booking) tx-sender) err-unauthorized)
            (asserts! (is-eq (get status booking) "confirmed") err-booking-not-active)
            
            ;; Burn room key if exists
            (match (get room-key-id booking)
              token-id
              (begin
                (try! (nft-burn? room-key token-id tx-sender))
                (map-delete room-key-data { token-id: token-id })
                true
              )
              true
            )
            
            ;; Process refund if payment was completed and cancellation is before check-in
            (if (and 
                  (is-eq (get payment-status booking) "completed")
                  (> (get check-in booking) stacks-block-height))
              (if (is-eq (get currency booking) currency-stx)
                (try! (stx-transfer? (get total-cost booking) (get owner hotel) tx-sender))
                ;; For other currencies, mark for refund processing
                true
              )
              true
            )
            
            (map-set bookings
              { booking-id: booking-id }
              (merge booking { 
                status: "cancelled",
                room-key-id: none
              })
            )
            (ok true)
          )
          err-not-found
        )
      )
      err-not-found
    )
  )
)

;; Update hotel details including accepted currencies
(define-public (update-hotel (hotel-id uint) (name (string-ascii 50)) (location (string-ascii 100)) (price-per-night uint) (accepted-currencies (list 10 (string-ascii 10))))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    
    (match (map-get? hotels { hotel-id: hotel-id })
      hotel
      (begin
        (asserts! (is-eq (get owner hotel) tx-sender) err-unauthorized)
        (asserts! (> (len name) u0) err-invalid-input)
        (asserts! (> (len location) u0) err-invalid-input)
        (asserts! (> price-per-night u0) err-invalid-input)
        (asserts! (> (len accepted-currencies) u0) err-invalid-input)
        
        (map-set hotels
          { hotel-id: hotel-id }
          (merge hotel {
            name: name,
            location: location,
            price-per-night: price-per-night,
            accepted-currencies: accepted-currencies
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Toggle hotel active status
(define-public (toggle-hotel-status (hotel-id uint))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    
    (match (map-get? hotels { hotel-id: hotel-id })
      hotel
      (begin
        (asserts! (is-eq (get owner hotel) tx-sender) err-unauthorized)
        
        (map-set hotels
          { hotel-id: hotel-id }
          (merge hotel { active: (not (get active hotel)) })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Read-only functions

;; Get hotel details
(define-read-only (get-hotel (hotel-id uint))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (ok (map-get? hotels { hotel-id: hotel-id }))
  )
)

;; Get booking details
(define-read-only (get-booking (booking-id uint))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
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
    hotel-counter: (var-get hotel-counter),
    room-key-counter: (var-get room-key-counter)
  }
)

;; Get room key data
(define-read-only (get-room-key (token-id uint))
  (begin
    (asserts! (> token-id u0) err-invalid-input)
    (ok (map-get? room-key-data { token-id: token-id }))
  )
)

;; Get room key by booking ID
(define-read-only (get-room-key-by-booking (booking-id uint))
  (begin
    (asserts! (> booking-id u0) err-invalid-input)
    (match (map-get? bookings { booking-id: booking-id })
      booking
      (ok (get room-key-id booking))
      err-not-found
    )
  )
)

;; Check if room key is valid for current date
(define-read-only (is-room-key-valid (token-id uint))
  (begin
    (asserts! (> token-id u0) err-invalid-input)
    (ok (is-room-key-currently-valid token-id))
  )
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

;; Get exchange rate for a currency
(define-read-only (get-exchange-rate (currency (string-ascii 10)))
  (map-get? exchange-rates { currency: currency })
)

;; Additional validation helper for token contracts
(define-private (is-valid-contract (contract principal))
  (and
    (not (is-eq contract 'ST000000000000000000002AMW42H)) ;; Not burn address
    (not (is-eq contract contract-owner)) ;; Not the same as contract owner to prevent confusion
  )
)

;; Get token contract for a currency with validation
(define-read-only (get-token-contract (currency (string-ascii 10)))
  (begin
    (asserts! (is-supported-currency currency) err-unsupported-currency)
    (ok (map-get? token-contracts { currency: currency }))
  )
)

;; Get supported currencies
(define-read-only (get-supported-currencies)
  (list currency-stx currency-btc currency-usdc currency-usdt)
)

;; Calculate booking cost in specific currency
(define-read-only (calculate-booking-cost (hotel-id uint) (nights uint) (currency (string-ascii 10)))
  (begin
    (asserts! (> hotel-id u0) err-invalid-input)
    (asserts! (> nights u0) err-invalid-input)
    (asserts! (is-supported-currency currency) err-unsupported-currency)
    
    (match (map-get? hotels { hotel-id: hotel-id })
      hotel
      (let
        (
          (base-cost (* nights (get price-per-night hotel)))
          (converted-cost (convert-currency-amount base-cost currency-stx currency))
        )
        (ok converted-cost)
      )
      err-not-found
    )
  )
)