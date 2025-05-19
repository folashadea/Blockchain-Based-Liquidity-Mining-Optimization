;; Position Management Contract
;; Handles asset allocation

(define-map user-positions
  { user: principal, position-id: uint }
  {
    pool-id: (string-ascii 64),
    amount-x: uint,
    amount-y: uint,
    entry-height: uint,
    last-harvested: uint,
    active: bool
  }
)

(define-data-var next-position-id uint u1)

;; Get user position
(define-read-only (get-position (user principal) (position-id uint))
  (map-get? user-positions { user: user, position-id: position-id })
)

;; Get all position IDs for a user (simplified - in reality would use a list or set)
(define-read-only (get-user-position-count (user principal))
  (var-get next-position-id)
)

;; Create a new liquidity position
(define-public (create-position
    (pool-id (string-ascii 64))
    (amount-x uint)
    (amount-y uint)
  )
  (let
    (
      (position-id (var-get next-position-id))
    )
    ;; In a real implementation, we would transfer tokens here
    (map-set user-positions
      { user: tx-sender, position-id: position-id }
      {
        pool-id: pool-id,
        amount-x: amount-x,
        amount-y: amount-y,
        entry-height: block-height,
        last-harvested: block-height,
        active: true
      }
    )
    (var-set next-position-id (+ position-id u1))
    (ok position-id)
  )
)

;; Close a position
(define-public (close-position (position-id uint))
  (match (map-get? user-positions { user: tx-sender, position-id: position-id })
    position
    (begin
      ;; In a real implementation, we would transfer tokens back to the user
      (map-set user-positions
        { user: tx-sender, position-id: position-id }
        (merge position { active: false })
      )
      (ok true)
    )
    (err u404)
  )
)

;; Rebalance a position
(define-public (rebalance-position
    (position-id uint)
    (new-amount-x uint)
    (new-amount-y uint)
  )
  (match (map-get? user-positions { user: tx-sender, position-id: position-id })
    position
    (begin
      (asserts! (get active position) (err u403))
      ;; In a real implementation, we would handle token transfers
      (map-set user-positions
        { user: tx-sender, position-id: position-id }
        (merge position {
          amount-x: new-amount-x,
          amount-y: new-amount-y
        })
      )
      (ok true)
    )
    (err u404)
  )
)
