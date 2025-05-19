;; Yield Projection Contract
;; Forecasts potential returns

(define-map yield-data
  { pool-id: (string-ascii 64) }
  {
    base-apy: uint,
    reward-apy: uint,
    volatility-factor: uint,
    projected-7d-apy: uint,
    projected-30d-apy: uint,
    last-updated: uint
  }
)

;; Get yield projections for a pool
(define-read-only (get-yield-projection (pool-id (string-ascii 64)))
  (map-get? yield-data { pool-id: pool-id })
)

;; Calculate optimal investment amount based on gas costs and expected returns
(define-read-only (calculate-optimal-investment
    (pool-id (string-ascii 64))
    (gas-cost uint)
    (investment-period uint)
  )
  (match (map-get? yield-data { pool-id: pool-id })
    projection
    (let
      (
        (apy (get base-apy projection))
        ;; Convert APY to the period's return
        (period-return (/ (* apy investment-period) u365))
      )
      ;; Minimum investment where gas costs are <= 10% of expected returns
      (if (> period-return u0)
        (/ (* gas-cost u1000) period-return)
        u0
      )
    )
    u0
  )
)

;; Update yield projections (oracle or admin function)
(define-public (update-yield-projection
    (pool-id (string-ascii 64))
    (base-apy uint)
    (reward-apy uint)
    (volatility-factor uint)
  )
  (let
    (
      ;; Simple projection formulas
      (projected-7d (- (+ base-apy reward-apy) (/ volatility-factor u7)))
      (projected-30d (- (+ base-apy reward-apy) (/ volatility-factor u30)))
    )
    ;; In a real implementation, we would check if caller is authorized
    (ok (map-set yield-data
      { pool-id: pool-id }
      {
        base-apy: base-apy,
        reward-apy: reward-apy,
        volatility-factor: volatility-factor,
        projected-7d-apy: projected-7d,
        projected-30d-apy: projected-30d,
        last-updated: block-height
      }
    ))
  )
)
