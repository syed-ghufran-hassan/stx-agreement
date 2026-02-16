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

(define-map agreement-payment-escrow
  { agreement-identifier: uint }
  { escrowed-amount: uint }
)

(define-map agreement-disputes
  { agreement-identifier: uint }
  {
    dispute-reason: (string-utf8 200),
    dispute-initiator: principal,
    dispute-resolution: (optional (string-utf8 200)),
  }
)

;; Read-only functions
(define-read-only (get-agreement-details (agreement-identifier uint))
  (map-get? service-agreement-details { agreement-identifier: agreement-identifier })
)

(define-read-only (get-escrowed-payment (agreement-identifier uint))
  (default-to { escrowed-amount: u0 }
    (map-get? agreement-payment-escrow { agreement-identifier: agreement-identifier })
  )
)

(define-read-only (get-dispute-details (agreement-identifier uint))
  (map-get? agreement-disputes { agreement-identifier: agreement-identifier })
)

;; Private functions
(define-private (verify-participant-authorization (agreement-identifier uint))
  (let ((agreement-info (unwrap! (get-agreement-details agreement-identifier) false)))
    (or
      (is-eq tx-sender contract-administrator)
      (is-eq tx-sender (get service-provider-address agreement-info))
      (is-eq tx-sender (get client-address agreement-info))
    )
  )
)

(define-private (milestone-completed? (milestone {
  milestone-description: (string-utf8 100),
  milestone-payment: uint,
  milestone-completed: bool,
}))
  (get milestone-completed milestone)
)

(define-private (verify-all-milestones-complete (service-milestones (list
  5
  {
    milestone-description: (string-utf8 100),
    milestone-payment: uint,
    milestone-completed: bool,
  }
)))
  (and
    (milestone-completed? (unwrap-panic (element-at service-milestones u0)))
    (milestone-completed? (unwrap-panic (element-at service-milestones u1)))
    (milestone-completed? (unwrap-panic (element-at service-milestones u2)))
    (milestone-completed? (unwrap-panic (element-at service-milestones u3)))
    (milestone-completed? (unwrap-panic (element-at service-milestones u4)))
  )
)

(define-private (validate-milestone-payments
    (milestones (list
      5
      {
        milestone-description: (string-utf8 100),
        milestone-payment: uint,
        milestone-completed: bool,
      }
    ))
    (total-cost uint)
  )
  (let ((total-milestone-payments (+ (get milestone-payment (unwrap-panic (element-at milestones u0)))
      (get milestone-payment (unwrap-panic (element-at milestones u1)))
      (get milestone-payment (unwrap-panic (element-at milestones u2)))
      (get milestone-payment (unwrap-panic (element-at milestones u3)))
      (get milestone-payment (unwrap-panic (element-at milestones u4)))
    )))
    (and
      (is-eq total-milestone-payments total-cost) ;; Sum of milestone payments must equal total cost
      (>
        (len (get milestone-description (unwrap-panic (element-at milestones u0))))
        u0
      )
      ;; Validate descriptions
      (>
        (len (get milestone-description (unwrap-panic (element-at milestones u1))))
        u0
      )
      (>
        (len (get milestone-description (unwrap-panic (element-at milestones u2))))
        u0
      )
      (>
        (len (get milestone-description (unwrap-panic (element-at milestones u3))))
        u0
      )
      (>
        (len (get milestone-description (unwrap-panic (element-at milestones u4))))
        u0
      )
    )
  )
)