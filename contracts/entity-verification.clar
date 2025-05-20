;; entity-verification.clar
;; This contract validates participating businesses in the regulatory sandbox

(define-data-var admin principal tx-sender)

;; Map to store verified entities
(define-map verified-entities principal
  {
    name: (string-utf8 100),
    registration-number: (string-utf8 50),
    verification-date: uint,
    is-active: bool
  }
)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Verify a new entity
(define-public (verify-entity (entity principal) (name (string-utf8 100)) (registration-number (string-utf8 50)))
  (begin
    (asserts! (is-admin) (err u1))
    (asserts! (not (is-some (map-get? verified-entities entity))) (err u2))

    (map-set verified-entities entity {
      name: name,
      registration-number: registration-number,
      verification-date: block-height,
      is-active: true
    })

    (ok true)
  )
)

;; Deactivate an entity
(define-public (deactivate-entity (entity principal))
  (begin
    (asserts! (is-admin) (err u1))
    (asserts! (is-some (map-get? verified-entities entity)) (err u3))

    (let ((current-data (unwrap-panic (map-get? verified-entities entity))))
      (map-set verified-entities entity (merge current-data { is-active: false }))
    )

    (ok true)
  )
)

;; Check if an entity is verified and active
(define-read-only (is-verified (entity principal))
  (match (map-get? verified-entities entity)
    entity-data (ok (get is-active entity-data))
    (err u3)
  )
)

;; Get entity details
(define-read-only (get-entity-details (entity principal))
  (map-get? verified-entities entity)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err u1))
    (var-set admin new-admin)
    (ok true)
  )
)
