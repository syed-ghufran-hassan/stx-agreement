;; title: stx-sla
;; version:
;; summary:
;; description:

;; Service Agreement Smart Contract
;; Implements a service agreement between a service provider and client
;; with payment escrow, dispute resolution, and milestone tracking

;; Constants
(define-constant contract-administrator tx-sender)
(define-constant agreement-status-awaiting-payment u0)
(define-constant agreement-status-active u1)
(define-constant agreement-status-delivered u2)
(define-constant agreement-status-terminated u3)
(define-constant agreement-status-under-dispute u4)

;; Error constants
(define-constant ERROR_UNAUTHORIZED_ACCESS (err u100))
(define-constant ERROR_INVALID_AGREEMENT_STATUS (err u101))
(define-constant ERROR_INSUFFICIENT_PAYMENT (err u102))
(define-constant ERROR_AGREEMENT_ALREADY_EXISTS (err u103))
(define-constant ERROR_AGREEMENT_NOT_FOUND (err u104))
(define-constant ERROR_INVALID_MILESTONE_INDEX (err u105))
(define-constant ERROR_INVALID_INPUT (err u106))
(define-constant ERROR_INVALID_SERVICE_PROVIDER (err u107))
(define-constant ERROR_INVALID_MILESTONE_DATA (err u108))

;; Data structures
(define-map service-agreement-details
  { agreement-identifier: uint }
  {
    service-provider-address: principal,
    client-address: principal,
    total-service-cost: uint,
    agreement-status: uint,
    agreement-start-block: uint,
    agreement-end-block: uint,
    dispute-filing-deadline-block: uint,
    service-milestones: (list
      5
      {
        milestone-description: (string-utf8 100),
        milestone-payment: uint,
        milestone-completed: bool,
      }
    ),
  }
)