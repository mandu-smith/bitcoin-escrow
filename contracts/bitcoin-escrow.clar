;; Bitcoin Escrow Smart Contract
;; Description: A secure escrow service for Bitcoin transactions with dispute resolution

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_ESCROW_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_INVALID_STATE (err u104))
(define-constant ERR_INSUFFICIENT_FUNDS (err u105))
(define-constant ERR_UNAUTHORIZED_ARBITRATOR (err u106))
(define-constant ERR_TIMEOUT_NOT_REACHED (err u107))

;; Data Variables
(define-data-var arbitrator-fee uint u25) ;; 2.5% fee in basis points
(define-data-var min-escrow-amount uint u1000000) ;; Minimum amount in microSTX (1 STX)
(define-data-var escrow-timeout uint u1440) ;; Default timeout in blocks (approximately 10 days)
(define-data-var last-escrow-id uint u0)

;; Data Maps
(define-map EscrowDetails
    { escrow-id: uint }
    {
        seller: principal,
        buyer: principal,
        arbitrator: (optional principal),
        amount: uint,
        state: (string-ascii 20),
        created-at: uint,
        timeout: uint,
        dispute-reason: (optional (string-utf8 500))
    }
)

(define-map ArbitratorRegistry
    { arbitrator: principal }
    {
        active: bool,
        cases-handled: uint,
        rating: uint
    }
)

;; Private Functions
(define-private (is-authorized (caller principal) (escrow-id uint))
    (match (map-get? EscrowDetails { escrow-id: escrow-id })
        escrow (or 
            (is-eq caller CONTRACT_OWNER)
            (is-eq caller (get seller escrow))
            (is-eq caller (get buyer escrow))
            (is-some (get arbitrator escrow)))
        false
    )
)

(define-private (calculate-fee (amount uint))
    (/ (* amount (var-get arbitrator-fee)) u1000)
)

(define-private (transfer-stx (recipient principal) (amount uint))
    (if (>= (stx-get-balance tx-sender) amount)
        (stx-transfer? amount tx-sender recipient)
        ERR_INSUFFICIENT_FUNDS
    )
)

;; Public Functions
(define-public (create-escrow (buyer principal) (amount uint) (timeout uint))
    (let (
        (escrow-id (+ (var-get last-escrow-id) u1))
        (current-block block-height)
    )
        (asserts! (>= amount (var-get min-escrow-amount)) ERR_INVALID_AMOUNT)
        (asserts! (> timeout u0) ERR_INVALID_AMOUNT)
        (asserts! (is-none (map-get? EscrowDetails { escrow-id: escrow-id })) ERR_ALREADY_EXISTS)
        
        ;; Lock the funds
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        ;; Create escrow entry
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            {
                seller: tx-sender,
                buyer: buyer,
                arbitrator: none,
                amount: amount,
                state: "PENDING",
                created-at: current-block,
                timeout: (+ current-block timeout),
                dispute-reason: none
            }
        )
        
        ;; Update last escrow ID
        (var-set last-escrow-id escrow-id)
        (ok escrow-id)
    )
)

(define-public (release-funds (escrow-id uint))
    (let (
        (escrow (unwrap! (map-get? EscrowDetails { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    )
        (asserts! (is-authorized tx-sender escrow-id) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get state escrow) "PENDING") ERR_INVALID_STATE)
        
        ;; Transfer funds to buyer
        (try! (as-contract (transfer-stx (get buyer escrow) (get amount escrow))))
        
        ;; Update escrow state
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            (merge escrow { state: "COMPLETED" })
        )
        (ok true)
    )
)

(define-public (refund-seller (escrow-id uint))
    (let (
        (escrow (unwrap! (map-get? EscrowDetails { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    )
        (asserts! (is-authorized tx-sender escrow-id) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get state escrow) "PENDING") ERR_INVALID_STATE)
        (asserts! (>= block-height (get timeout escrow)) ERR_TIMEOUT_NOT_REACHED)
        
        ;; Transfer funds back to seller
        (try! (as-contract (transfer-stx (get seller escrow) (get amount escrow))))
        
        ;; Update escrow state
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            (merge escrow { state: "REFUNDED" })
        )
        (ok true)
    )
)

(define-public (raise-dispute (escrow-id uint) (reason (string-utf8 500)))
    (let (
        (escrow (unwrap! (map-get? EscrowDetails { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
    )
        (asserts! (is-eq tx-sender (get buyer escrow)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get state escrow) "PENDING") ERR_INVALID_STATE)
        
        ;; Update escrow state with dispute
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            (merge escrow {
                state: "DISPUTED",
                dispute-reason: (some reason)
            })
        )
        (ok true)
    )
)

(define-public (assign-arbitrator (escrow-id uint) (arbitrator-principal principal))
    (let (
        (escrow (unwrap! (map-get? EscrowDetails { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
        (arbitrator-info (unwrap! (map-get? ArbitratorRegistry { arbitrator: arbitrator-principal }) ERR_UNAUTHORIZED_ARBITRATOR))
    )
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (get active arbitrator-info) ERR_UNAUTHORIZED_ARBITRATOR)
        (asserts! (is-eq (get state escrow) "DISPUTED") ERR_INVALID_STATE)
        
        ;; Assign arbitrator
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            (merge escrow {
                arbitrator: (some arbitrator-principal),
                state: "ARBITRATION"
            })
        )
        (ok true)
    )
)

(define-public (resolve-dispute (escrow-id uint) (refund-to-buyer bool))
    (let (
        (escrow (unwrap! (map-get? EscrowDetails { escrow-id: escrow-id }) ERR_ESCROW_NOT_FOUND))
        (amount (get amount escrow))
        (fee (calculate-fee amount))
        (final-amount (- amount fee))
    )
        (asserts! (is-some (get arbitrator escrow)) ERR_UNAUTHORIZED_ARBITRATOR)
        (asserts! (is-eq tx-sender (unwrap! (get arbitrator escrow) ERR_NOT_AUTHORIZED)) ERR_NOT_AUTHORIZED)
        (asserts! (is-eq (get state escrow) "ARBITRATION") ERR_INVALID_STATE)
        
        ;; Transfer funds based on arbitrator's decision
        (if refund-to-buyer
            (try! (as-contract (transfer-stx (get buyer escrow) final-amount)))
            (try! (as-contract (transfer-stx (get seller escrow) final-amount)))
        )
        
        ;; Pay arbitrator fee
        (try! (as-contract (transfer-stx (unwrap! (get arbitrator escrow) ERR_NOT_AUTHORIZED) fee)))
        
        ;; Update escrow state
        (map-set EscrowDetails
            { escrow-id: escrow-id }
            (merge escrow {
                state: "RESOLVED"
            })
        )
        (ok true)
    )
)

;; Read-only Functions
(define-read-only (get-escrow-details (escrow-id uint))
    (map-get? EscrowDetails { escrow-id: escrow-id })
)

(define-read-only (get-arbitrator-info (arbitrator principal))
    (map-get? ArbitratorRegistry { arbitrator: arbitrator })
)

;; Contract Owner Functions
(define-public (set-arbitrator-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= new-fee u1000) ERR_INVALID_AMOUNT) ;; Max 100%
        (var-set arbitrator-fee new-fee)
        (ok true)
    )
)

(define-public (register-arbitrator (arbitrator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (map-set ArbitratorRegistry
            { arbitrator: arbitrator }
            {
                active: true,
                cases-handled: u0,
                rating: u0
            }
        )
        (ok true)
    )
)

(define-public (deactivate-arbitrator (arbitrator principal))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (let (
            (arbitrator-info (unwrap! (map-get? ArbitratorRegistry { arbitrator: arbitrator }) ERR_UNAUTHORIZED_ARBITRATOR))
        )
            (map-set ArbitratorRegistry
                { arbitrator: arbitrator }
                (merge arbitrator-info { active: false })
            )
            (ok true)
        )
    )
)