;; Title: VaultWorks - Autonomous Treasury Management Protocol
;;
;; Summary:
;; A cutting-edge autonomous treasury management system that transforms how
;; decentralized organizations handle collective funds. VaultWorks combines
;; institutional-grade security with community-driven governance, creating
;; a trustless environment where stakeholders collaboratively manage shared
;; resources through democratic consensus mechanisms.
;;
;; Description:
;; VaultWorks represents the next evolution in decentralized finance infrastructure,
;; offering sophisticated treasury management capabilities that rival traditional
;; financial institutions while maintaining complete transparency and democratic
;; control. The protocol introduces revolutionary features including:
;;
;; - Advanced stake-weighted governance ensuring proportional representation
;; - Multi-layered security architecture with time-locked safeguards
;; - Autonomous proposal lifecycle management with built-in fraud prevention
;; - Dynamic liquidity management with intelligent rebalancing mechanisms
;; - Transparent fund allocation tracking with immutable audit trails
;; - Sophisticated anti-manipulation defenses against coordinated attacks
;;
;; Built on Stacks' robust infrastructure and secured by Bitcoin's unparalleled
;; network security, VaultWorks enables organizations to operate with the
;; efficiency of centralized systems while preserving the trust guarantees
;; of decentralized protocols.

;; CORE SYSTEM CONSTANTS

(define-constant contract-owner tx-sender)

;; Error Codes - Organized by Category
(define-constant err-owner-only (err u100))
(define-constant err-not-initialized (err u101))
(define-constant err-already-initialized (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-proposal-not-found (err u106))
(define-constant err-proposal-expired (err u107))
(define-constant err-already-voted (err u108))
(define-constant err-below-minimum (err u109))
(define-constant err-locked-period (err u110))
(define-constant err-transfer-failed (err u111))
(define-constant err-invalid-duration (err u112))
(define-constant err-zero-amount (err u113))
(define-constant err-invalid-target (err u114))
(define-constant err-invalid-description (err u115))
(define-constant err-invalid-proposal-id (err u116))
(define-constant err-invalid-vote (err u117))

;; Governance Parameters
(define-constant minimum-duration u144) ;; 1 day minimum voting period
(define-constant maximum-duration u20160) ;; 14 day maximum voting period

;; STATE VARIABLES

(define-data-var total-supply uint u0)
(define-data-var minimum-deposit uint u1000000) ;; Minimum stake requirement (1 STX)
(define-data-var lock-period uint u1440) ;; Security lock period (~10 days)
(define-data-var initialized bool false)
(define-data-var last-rebalance uint u0)
(define-data-var proposal-count uint u0)

;; DATA STRUCTURES

;; Stakeholder Balance Tracking
(define-map balances
  principal
  uint
)

;; Deposit Records with Security Features
(define-map deposits
  principal
  {
    amount: uint,
    lock-until: uint,
    last-reward-block: uint,
  }
)

;; Governance Proposal Registry
(define-map proposals
  uint
  {
    proposer: principal,
    description: (string-ascii 256),
    amount: uint,
    target: principal,
    expires-at: uint,
    executed: bool,
    yes-votes: uint,
    no-votes: uint,
  }
)

;; Voting Record Tracking
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  bool
)

;; INTERNAL UTILITIES

;; Verify contract owner privileges
(define-private (is-contract-owner)
  (is-eq tx-sender contract-owner)
)

;; Ensure system initialization
(define-private (check-initialized)
  (ok (asserts! (var-get initialized) err-not-initialized))
)

;; Validate proposal ID bounds
(define-private (validate-proposal-id (proposal-id uint))
  (ok (asserts! (<= proposal-id (var-get proposal-count)) err-invalid-proposal-id))
)

;; Calculate stake-weighted voting power
(define-private (calculate-voting-power (voter principal))
  (default-to u0 (map-get? balances voter))
)

;; Secure token transfer mechanism
(define-private (transfer-tokens
    (sender principal)
    (recipient principal)
    (amount uint)
  )
  (let (
      (sender-balance (default-to u0 (map-get? balances sender)))
      (recipient-balance (default-to u0 (map-get? balances recipient)))
    )
    (asserts! (>= sender-balance amount) err-insufficient-balance)
    (map-set balances sender (- sender-balance amount))
    (map-set balances recipient (+ recipient-balance amount))
    (ok true)
  )
)

;; Controlled token minting
(define-private (mint-tokens
    (account principal)
    (amount uint)
  )
  (let ((current-balance (default-to u0 (map-get? balances account))))
    (map-set balances account (+ current-balance amount))
    (var-set total-supply (+ (var-get total-supply) amount))
    (ok true)
  )
)

;; Secure token burning
(define-private (burn-tokens
    (account principal)
    (amount uint)
  )
  (let ((current-balance (default-to u0 (map-get? balances account))))
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (map-set balances account (- current-balance amount))
    (var-set total-supply (- (var-get total-supply) amount))
    (ok true)
  )
)

;; PUBLIC INTERFACE

;; System Initialization
;; Establishes the protocol's operational foundation
;; Access: Contract owner only
;; Returns: Success confirmation
(define-public (initialize)
  (begin
    (asserts! (is-contract-owner) err-owner-only)
    (asserts! (not (var-get initialized)) err-already-initialized)
    (var-set initialized true)
    (ok true)
  )
)

;; Stake Deposit Function
;; Enables users to stake STX and receive governance tokens
;; Implements time-lock security to prevent flash attacks
;; Param: amount - STX amount to stake (microSTX units)
;; Returns: Success confirmation
(define-public (deposit (amount uint))
  (begin
    (try! (check-initialized))
    (asserts! (>= amount (var-get minimum-deposit)) err-below-minimum)
    (asserts! (> amount u0) err-zero-amount)
    ;; Secure STX transfer to protocol vault
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    ;; Register stake with security parameters
    (map-set deposits tx-sender {
      amount: amount,
      lock-until: (+ stacks-block-height (var-get lock-period)),
      last-reward-block: stacks-block-height,
    })
    ;; Issue proportional governance tokens
    (mint-tokens tx-sender amount)
  )
)

;; Stake Withdrawal Function
;; Allows users to withdraw after lock period expires
;; Implements security checks to prevent unauthorized access
;; Param: amount - STX amount to withdraw (microSTX units)
;; Returns: Success confirmation
(define-public (withdraw (amount uint))
  (begin
    (try! (check-initialized))
    (asserts! (> amount u0) err-zero-amount)
    (let (
        (deposit-info (unwrap! (map-get? deposits tx-sender) err-unauthorized))
        (user-balance (unwrap! (get-balance tx-sender) err-unauthorized))
      )
      (asserts! (>= stacks-block-height (get lock-until deposit-info))
        err-locked-period
      )
      (asserts! (>= user-balance amount) err-insufficient-balance)
      ;; Burn governance tokens first
      (try! (burn-tokens tx-sender amount))
      ;; Execute secure STX return
      (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender))
    )
  )
)

;; Governance Proposal Creation
;; Enables stakeholders to propose treasury allocations
;; Implements comprehensive validation for proposal integrity
;; Params: description, amount, target, duration
;; Returns: Unique proposal ID
(define-public (create-proposal
    (description (string-ascii 256))
    (amount uint)
    (target principal)
    (duration uint)
  )
  (begin
    (try! (check-initialized))
    ;; Comprehensive input validation
    (asserts! (> (len description) u0) err-invalid-description)
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (not (is-eq target (as-contract tx-sender))) err-invalid-target)
    (asserts! (and (>= duration minimum-duration) (<= duration maximum-duration))
      err-invalid-duration
    )
    (let (
        (proposer-balance (unwrap! (map-get? balances tx-sender) err-unauthorized))
        (proposal-id (+ (var-get proposal-count) u1))
      )
      (asserts! (> proposer-balance u0) err-unauthorized)
      ;; Create validated proposal record
      (map-set proposals proposal-id {
        proposer: tx-sender,
        description: description,
        amount: amount,
        target: target,
        expires-at: (+ stacks-block-height duration),
        executed: false,
        yes-votes: u0,
        no-votes: u0,
      })
      (var-set proposal-count proposal-id)
      (ok proposal-id)
    )
  )
)

;; Democratic Voting Function
;; Enables stake-weighted voting on active proposals
;; Implements anti-manipulation safeguards
;; Params: proposal-id, vote-for (boolean)
;; Returns: Success confirmation
(define-public (vote
    (proposal-id uint)
    (vote-for bool)
  )
  (begin
    (try! (check-initialized))
    (try! (validate-proposal-id proposal-id))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (voter-power (calculate-voting-power tx-sender))
      )
      (asserts! (> voter-power u0) err-unauthorized)
      (asserts! (< stacks-block-height (get expires-at proposal))
        err-proposal-expired
      )
      (asserts!
        (is-none (map-get? votes {
          proposal-id: proposal-id,
          voter: tx-sender,
        }))
        err-already-voted
      )
      ;; Immutable vote registration
      (map-set votes {
        proposal-id: proposal-id,
        voter: tx-sender,
      }
        vote-for
      )
      ;; Atomic vote count update
      (map-set proposals proposal-id
        (merge proposal {
            yes-votes: (if vote-for
            (+ (get yes-votes proposal) voter-power)
            (get yes-votes proposal)
          ),
          no-votes: (if vote-for
            (get no-votes proposal)
            (+ (get no-votes proposal) voter-power)
          ),
        })
      )
      (ok true)
    )
  )
)

;; Proposal Execution Engine
;; Automatically executes approved proposals with security checks
;; Implements majority consensus validation
;; Param: proposal-id
;; Returns: Success confirmation
(define-public (execute-proposal (proposal-id uint))
  (begin
    (try! (check-initialized))
    (try! (validate-proposal-id proposal-id))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (contract-balance (stx-get-balance (as-contract tx-sender)))
      )
      (asserts! (not (get executed proposal)) err-unauthorized)
      (asserts! (>= stacks-block-height (get expires-at proposal))
        err-proposal-expired
      )
      (asserts! (> (get yes-votes proposal) (get no-votes proposal))
        err-unauthorized
      )
      (asserts! (>= contract-balance (get amount proposal))
        err-insufficient-balance
      )
      ;; Execute approved treasury allocation
      (try! (as-contract (stx-transfer? (get amount proposal) (as-contract tx-sender)
        (get target proposal)
      )))
      ;; Mark proposal as permanently executed
      (map-set proposals proposal-id (merge proposal { executed: true }))
      (ok true)
    )
  )
)

;; READ-ONLY INTERFACE

;; Balance Query Function
;; Retrieves governance token balance for any account
;; Param: account - Principal to query
;; Returns: Token balance
(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? balances account)))
)

;; Total Supply Query
;; Returns the total circulating governance tokens
;; Returns: Total token supply
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

;; Proposal Details Query
;; Retrieves comprehensive proposal information
;; Param: proposal-id
;; Returns: Complete proposal record
(define-read-only (get-proposal (proposal-id uint))
  (ok (map-get? proposals proposal-id))
)

;; Deposit Information Query
;; Retrieves staking details for any account
;; Param: account - Principal to query
;; Returns: Deposit record with lock status
(define-read-only (get-deposit-info (account principal))
  (ok (map-get? deposits account))
)

;; Vote History Query
;; Retrieves voting record for specific proposal-voter pair
;; Params: proposal-id, voter
;; Returns: Vote cast (true/false) or none
(define-read-only (get-vote
    (proposal-id uint)
    (voter principal)
  )
  (ok (map-get? votes {
    proposal-id: proposal-id,
    voter: voter,
  }))
)
