(define-non-fungible-token dynamic-nft uint)

(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)

(define-data-var platform-fee-rate uint u250)
(define-data-var marketplace-owner principal tx-sender)

(define-constant ERR-INSUFFICIENT-FUNDS (err u402))
(define-constant ERR-INVALID-PRICE (err u400))
(define-constant ERR-LISTING-INACTIVE (err u403))

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


(define-map listings uint {
    seller: principal,
    price: uint,
    active: bool,
    base-price: uint,
    level-multiplier: uint
})

(define-map marketplace-stats principal {
    total-sales: uint,
    total-purchases: uint,
    reputation-score: uint
})



(define-trait nft-trait
    (
        (get-owner (uint) (response (optional principal) uint))
        (transfer (uint principal principal) (response bool uint))
        (get-nft-level (uint) (response uint uint))
    )
)

(define-public (list-nft (nft-contract <nft-trait>) (token-id uint) (base-price uint) (level-multiplier uint))
    (let (
        (owner-result (contract-call? nft-contract get-owner token-id))
        (level-result (contract-call? nft-contract get-nft-level token-id))
    )
    (asserts! (> base-price u0) ERR-INVALID-PRICE)
    (asserts! (> level-multiplier u0) ERR-INVALID-PRICE)
    (match owner-result
        owner-opt (match owner-opt
            owner (begin
                (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
                (match level-result
                    level (let (
                        (dynamic-price (+ base-price (* level level-multiplier)))
                    )
                    (map-set listings token-id {
                        seller: tx-sender,
                        price: dynamic-price,
                        active: true,
                        base-price: base-price,
                        level-multiplier: level-multiplier
                    })
                    (ok dynamic-price))
                    err-level ERR-NOT-FOUND
                )
            )
            ERR-NOT-FOUND
        )
        err-owner ERR-NOT-FOUND
    ))
)

(define-public (purchase-nft (nft-contract <nft-trait>) (token-id uint))
    (let (
        (listing (unwrap! (map-get? listings token-id) ERR-NOT-FOUND))
        (seller (get seller listing))
        (price (get price listing))
        (platform-fee (/ (* price (var-get platform-fee-rate)) u10000))
        (seller-amount (- price platform-fee))
    )
    (asserts! (get active listing) ERR-LISTING-INACTIVE)
    (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-FUNDS)
    (try! (stx-transfer? seller-amount tx-sender seller))
    (try! (stx-transfer? platform-fee tx-sender (var-get marketplace-owner)))
    (try! (contract-call? nft-contract transfer token-id seller tx-sender))
    (map-set listings token-id (merge listing {active: false}))
    (update-marketplace-stats seller true)
    (update-marketplace-stats tx-sender false)
    (ok true)
    )
)

(define-public (cancel-listing (token-id uint))
    (let (
        (listing (unwrap! (map-get? listings token-id) ERR-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get seller listing)) ERR-NOT-AUTHORIZED)
    (asserts! (get active listing) ERR-LISTING-INACTIVE)
    (map-set listings token-id (merge listing {active: false}))
    (ok true)
    )
)

(define-private (update-marketplace-stats (user principal) (is-seller bool))
    (let (
        (current-stats (default-to {total-sales: u0, total-purchases: u0, reputation-score: u0} 
                       (map-get? marketplace-stats user)))
    )
    (if is-seller
        (map-set marketplace-stats user {
            total-sales: (+ (get total-sales current-stats) u1),
            total-purchases: (get total-purchases current-stats),
            reputation-score: (+ (get reputation-score current-stats) u10)
        })
        (map-set marketplace-stats user {
            total-sales: (get total-sales current-stats),
            total-purchases: (+ (get total-purchases current-stats) u1),
            reputation-score: (+ (get reputation-score current-stats) u5)
        })
    )
    )
)

(define-read-only (get-listing (token-id uint))
    (map-get? listings token-id)
)

(define-read-only (get-marketplace-stats (user principal))
    (map-get? marketplace-stats user)
)

(define-public (set-platform-fee (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender (var-get marketplace-owner)) ERR-NOT-AUTHORIZED)
        (asserts! (<= new-rate u1000) ERR-INVALID-PRICE)
        (var-set platform-fee-rate new-rate)
        (ok true)
    )
)