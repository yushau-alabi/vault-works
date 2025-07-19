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