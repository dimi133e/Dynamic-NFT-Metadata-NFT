(define-non-fungible-token dynamic-nft uint)

(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)

(define-map token-metadata uint {
    name: (string-ascii 64),
    description: (string-ascii 256),
    image-base-uri: (string-ascii 256),
    level: uint,
    experience: uint,
    last-activity: uint
})

(define-map token-owners uint principal)

(define-map user-activity principal {
    total-transactions: uint,
    last-interaction: uint,
    activity-score: uint
})

(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-ALREADY-EXISTS (err u409))
(define-constant ERR-INVALID-INPUT (err u400))

(define-constant LEVEL-UP-THRESHOLD u100)
(define-constant ACTIVITY-DECAY-BLOCKS u1000)
(define-constant MAX-LEVEL u10)

(define-read-only (get-last-token-id)
    (var-get last-token-id)
)

(define-read-only (get-token-uri (token-id uint))
    (match (map-get? token-metadata token-id)
        metadata (ok (some (generate-metadata-uri token-id metadata)))
        (ok none)
    )
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? dynamic-nft token-id))
)

(define-read-only (get-token-metadata (token-id uint))
    (ok (map-get? token-metadata token-id))
)

(define-read-only (get-user-activity (user principal))
    (ok (map-get? user-activity user))
)

(define-private (generate-metadata-uri (token-id uint) (metadata {name: (string-ascii 64), description: (string-ascii 256), image-base-uri: (string-ascii 256), level: uint, experience: uint, last-activity: uint}))
    (concat 
        (concat 
            (concat (get image-base-uri metadata) "/level-")
            (uint-to-string (get level metadata))
        )
        ".json"
    )
)

(define-private (uint-to-string (value uint))
    (if (is-eq value u0) "0"
    (if (is-eq value u1) "1"
    (if (is-eq value u2) "2"
    (if (is-eq value u3) "3"
    (if (is-eq value u4) "4"
    (if (is-eq value u5) "5"
    (if (is-eq value u6) "6"
    (if (is-eq value u7) "7"
    (if (is-eq value u8) "8"
    (if (is-eq value u9) "9"
    (if (is-eq value u10) "10"
    "unknown")))))))))))
)

(define-private (calculate-new-level (current-exp uint))
    (let ((new-level (/ current-exp LEVEL-UP-THRESHOLD)))
        (if (> new-level MAX-LEVEL)
            MAX-LEVEL
            new-level
        )
    )
)

(define-private (calculate-activity-score (user principal))
    (match (map-get? user-activity user)
        activity (let (
            (blocks-since-last (- stacks-block-height (get last-interaction activity)))
            (decay-factor (if (> blocks-since-last ACTIVITY-DECAY-BLOCKS) u0 u1))
            (base-score (get total-transactions activity))
        )
        (* base-score decay-factor))
        u0
    )
)

(define-public (mint-nft (recipient principal) (name (string-ascii 64)) (description (string-ascii 256)) (image-base-uri (string-ascii 256)))
    (let (
        (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (try! (nft-mint? dynamic-nft token-id recipient))
    (map-set token-metadata token-id {
        name: name,
        description: description,
        image-base-uri: image-base-uri,
        level: u1,
        experience: u0,
        last-activity: stacks-block-height
    })
    (map-set token-owners token-id recipient)
    (var-set last-token-id token-id)
    (ok token-id)
    )
)

;; (define-public (transfer (token-id uint) (sender principal) (recipient principal))
;;     (begin
;;         (asserts! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
;;         (asserts! (is-some (nft-get-owner? dynamic-nft token-id)) ERR-NOT-FOUND)
;;         (try! (update-activity sender))
;;         (try! (update-activity recipient))
;;         (try! (update-nft-metadata token-id))
;;         (map-set token-owners token-id recipient)
;;         (nft-transfer? dynamic-nft token-id sender recipient)
;;     )
;; )

;; (define-public (interact-with-nft (token-id uint))
;;     (let (
;;         (owner (unwrap! (nft-get-owner? dynamic-nft token-id) ERR-NOT-FOUND))
;;     )
;;     (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
;;     (try! (update-activity tx-sender))
;;     (try! (update-nft-metadata token-id))
;;     (ok true)
;;     )
;; )

(define-private (update-activity (user principal))
    (let (
        (current-activity (default-to {total-transactions: u0, last-interaction: u0, activity-score: u0} 
                          (map-get? user-activity user)))
        (new-total (+ (get total-transactions current-activity) u1))
        (new-score (calculate-activity-score user))
    )
    (map-set user-activity user {
        total-transactions: new-total,
        last-interaction: stacks-block-height,
        activity-score: (+ new-score u10)
    })
    (ok u1)
    )
)

(define-public (update-nft-metadata (token-id uint))
    (let (
        (current-metadata (unwrap! (map-get? token-metadata token-id) ERR-NOT-FOUND))
        (owner (unwrap! (nft-get-owner? dynamic-nft token-id) ERR-NOT-FOUND))
        (user-stats (default-to {total-transactions: u0, last-interaction: u0, activity-score: u0} 
                    (map-get? user-activity owner)))
        (new-experience (+ (get experience current-metadata) (get activity-score user-stats)))
        (new-level (calculate-new-level new-experience))
    )
    (map-set token-metadata token-id (merge current-metadata {
        level: new-level,
        experience: new-experience,
        last-activity: stacks-block-height
    }))
    (ok true)
    )
)

(define-public (force-update-metadata (token-id uint))
    (let (
        (owner (unwrap! (nft-get-owner? dynamic-nft token-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (update-nft-metadata token-id)
    )
)

(define-public (set-contract-owner (new-owner principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (var-set contract-owner new-owner)
        (ok true)
    )
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-nft-level (token-id uint))
    (match (map-get? token-metadata token-id)
        metadata (ok (get level metadata))
        ERR-NOT-FOUND
    )
)

(define-read-only (get-nft-experience (token-id uint))
    (match (map-get? token-metadata token-id)
        metadata (ok (get experience metadata))
        ERR-NOT-FOUND
    )
)

(define-public (bulk-update-activity (users (list 10 principal)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
        (ok (map update-activity users))
    )
)

(define-read-only (get-activity-summary (user principal))
    (let (
        (activity (default-to {total-transactions: u0, last-interaction: u0, activity-score: u0} 
                  (map-get? user-activity user)))
        (current-score (calculate-activity-score user))
    )
    (ok {
        user: user,
        total-transactions: (get total-transactions activity),
        last-interaction: (get last-interaction activity),
        current-activity-score: current-score,
        blocks-since-last: (- stacks-block-height (get last-interaction activity))
    })
    )
)