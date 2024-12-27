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