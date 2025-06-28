;; Ionic Information Hub

;; System error code definitions for operational feedback

(define-constant ERR_INSUFFICIENT_PRIVILEGES (err u105))
(define-constant ERR_DURATION_INVALID (err u106))
(define-constant ERR_PERMISSION_MISMATCH (err u107))
(define-constant ERR_ACCESS_DENIED (err u100))
(define-constant ERR_INVALID_INPUT (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_ALREADY_EXISTS (err u103))
(define-constant ERR_CONTENT_INVALID (err u104))
(define-constant ERR_TYPE_INVALID (err u108))

;; Contract deployer reference
(define-constant VAULT_OWNER tx-sender)
(define-constant ACCESS_LEVEL_VIEWER "read")
(define-constant ACCESS_LEVEL_EDITOR "write") 
(define-constant ACCESS_LEVEL_MANAGER "admin")

(define-data-var total-vault-entries uint u0)

;; Permission management structure for access control
(define-map access-permissions
    { memory-id: uint, user: principal }
    {
        permission-level: (string-ascii 10),
        granted-at: uint,
        expires-at: uint,
        can-modify: bool
    }
)

(define-map quantum-memory-vault
    { memory-id: uint }
    {
        title: (string-ascii 50),
        owner: principal,
        hash-signature: (string-ascii 64),
        content: (string-ascii 200),
        created-at: uint,
        updated-at: uint,
        category: (string-ascii 20),
        tags: (list 5 (string-ascii 30))
    }
)

;; Alternative storage implementation for enhanced operations
(define-map optimized-memory-vault
    { memory-id: uint }
    {
        title: (string-ascii 50),
        owner: principal,
        hash-signature: (string-ascii 64),
        content: (string-ascii 200),
        created-at: uint,
        updated-at: uint,
        category: (string-ascii 20),
        tags: (list 5 (string-ascii 30))
    }
)

;; Input validation functions for data integrity

;; Validates title string length and format
(define-private (valid-title? (title (string-ascii 50)))
    (let ((title-length (len title)))
        (and
            (> title-length u0)
            (<= title-length u50)
        )
    )
)

;; Validates hash signature format requirements
(define-private (valid-hash-signature? (hash-signature (string-ascii 64)))
    (let ((hash-length (len hash-signature)))
        (and
            (is-eq hash-length u64)
            (> hash-length u0)
        )
    )
)

;; Validates content string constraints
(define-private (valid-content? (content (string-ascii 200)))
    (let ((content-length (len content)))
        (and
            (>= content-length u1)
            (<= content-length u200)
        )
    )
)

;; Validates category string requirements
(define-private (valid-category? (category (string-ascii 20)))
    (let ((category-length (len category)))
        (and
            (>= category-length u1)
            (<= category-length u20)
        )
    )
)

;; Validates individual tag format
(define-private (valid-tag? (tag (string-ascii 30)))
    (let ((tag-length (len tag)))
        (and
            (> tag-length u0)
            (<= tag-length u30)
        )
    )
)

;; Validates complete tag list structure
(define-private (valid-tags? (tag-list (list 5 (string-ascii 30))))
    (let ((list-length (len tag-list)))
        (and
            (>= list-length u1)
            (<= list-length u5)
            (is-eq (len (filter valid-tag? tag-list)) list-length)
        )
    )
)

;; Validates permission level against allowed values
(define-private (valid-permission-level? (permission-level (string-ascii 10)))
    (or
        (is-eq permission-level ACCESS_LEVEL_VIEWER)
        (is-eq permission-level ACCESS_LEVEL_EDITOR)
        (is-eq permission-level ACCESS_LEVEL_MANAGER)
    )
)

;; Validates time duration parameters
(define-private (valid-duration? (duration uint))
    (and
        (> duration u0)
        (<= duration u52560)
    )
)

;; Validates user principal for permission grants
(define-private (valid-user? (user principal))
    (not (is-eq user tx-sender))
)

;; Validates modification permission flag
(define-private (valid-modification-flag? (can-modify bool))
    (or (is-eq can-modify true) (is-eq can-modify false))
)

;; Authorization check functions

;; Verifies ownership of memory record
(define-private (is-memory-owner? (memory-id uint) (user principal))
    (match (map-get? quantum-memory-vault { memory-id: memory-id })
        memory-record (is-eq (get owner memory-record) user)
        false
    )
)

;; Checks if memory record exists in vault
(define-private (memory-exists? (memory-id uint))
    (is-some (map-get? quantum-memory-vault { memory-id: memory-id }))
)

;; Primary vault operations

;; Creates new memory record in the quantum vault
(define-public (create-memory-record 
    (title (string-ascii 50))
    (hash-signature (string-ascii 64))
    (content (string-ascii 200))
    (category (string-ascii 20))
    (tags (list 5 (string-ascii 30)))
)
    (let
        (
            (new-memory-id (+ (var-get total-vault-entries) u1))
            (current-time block-height)
        )
        ;; Input validation sequence
        (asserts! (valid-title? title) ERR_INVALID_INPUT)
        (asserts! (valid-hash-signature? hash-signature) ERR_INVALID_INPUT)
        (asserts! (valid-content? content) ERR_CONTENT_INVALID)
        (asserts! (valid-category? category) ERR_TYPE_INVALID)
        (asserts! (valid-tags? tags) ERR_CONTENT_INVALID)
        
        ;; Store memory record in vault
        (map-set quantum-memory-vault
            { memory-id: new-memory-id }
            {
                title: title,
                owner: tx-sender,
                hash-signature: hash-signature,
                content: content,
                created-at: current-time,
                updated-at: current-time,
                category: category,
                tags: tags
            }
        )
        
        ;; Update global counter
        (var-set total-vault-entries new-memory-id)
        (ok new-memory-id)
    )
)

;; Updates existing memory record with new information
(define-public (update-memory-record
    (memory-id uint)
    (new-title (string-ascii 50))
    (new-hash-signature (string-ascii 64))
    (new-content (string-ascii 200))
    (new-tags (list 5 (string-ascii 30)))
)
    (let
        (
            (existing-record (unwrap! (map-get? quantum-memory-vault { memory-id: memory-id }) ERR_NOT_FOUND))
            (current-time block-height)
        )
        ;; Authorization and validation
        (asserts! (is-memory-owner? memory-id tx-sender) ERR_ACCESS_DENIED)
        (asserts! (valid-title? new-title) ERR_INVALID_INPUT)
        (asserts! (valid-hash-signature? new-hash-signature) ERR_INVALID_INPUT)
        (asserts! (valid-content? new-content) ERR_CONTENT_INVALID)
        (asserts! (valid-tags? new-tags) ERR_CONTENT_INVALID)
        
        ;; Apply updates to existing record
        (map-set quantum-memory-vault
            { memory-id: memory-id }
            (merge existing-record {
                title: new-title,
                hash-signature: new-hash-signature,
                content: new-content,
                updated-at: current-time,
                tags: new-tags
            })
        )
        (ok true)
    )
)

;; Grants access permissions to external users
(define-public (grant-access-permission
    (memory-id uint)
    (user principal)
    (permission-level (string-ascii 10))
    (duration uint)
    (can-modify bool)
)
    (let
        (
            (current-time block-height)
            (expiration-time (+ current-time duration))
        )
        ;; Comprehensive validation
        (asserts! (memory-exists? memory-id) ERR_NOT_FOUND)
        (asserts! (is-memory-owner? memory-id tx-sender) ERR_ACCESS_DENIED)
        (asserts! (valid-user? user) ERR_INVALID_INPUT)
        (asserts! (valid-permission-level? permission-level) ERR_PERMISSION_MISMATCH)
        (asserts! (valid-duration? duration) ERR_DURATION_INVALID)
        (asserts! (valid-modification-flag? can-modify) ERR_INVALID_INPUT)
        
        ;; Create permission record
        (map-set access-permissions
            { memory-id: memory-id, user: user }
            {
                permission-level: permission-level,
                granted-at: current-time,
                expires-at: expiration-time,
                can-modify: can-modify
            }
        )
        (ok true)
    )
)

;; Enhanced memory creation with streamlined processing
(define-public (streamlined-memory-creation
    (title (string-ascii 50))
    (hash-signature (string-ascii 64))
    (content (string-ascii 200))
    (category (string-ascii 20))
    (tags (list 5 (string-ascii 30)))
)
    (let
        (
            (new-memory-id (+ (var-get total-vault-entries) u1))
            (current-time block-height)
        )
        ;; Consolidated input validation
        (asserts! (valid-title? title) ERR_INVALID_INPUT)
        (asserts! (valid-hash-signature? hash-signature) ERR_INVALID_INPUT)
        (asserts! (valid-content? content) ERR_CONTENT_INVALID)
        (asserts! (valid-category? category) ERR_TYPE_INVALID)
        (asserts! (valid-tags? tags) ERR_CONTENT_INVALID)

        ;; Execute memory storage operation
        (map-set quantum-memory-vault
            { memory-id: new-memory-id }
            {
                title: title,
                owner: tx-sender,
                hash-signature: hash-signature,
                content: content,
                created-at: current-time,
                updated-at: current-time,
                category: category,
                tags: tags
            }
        )

        ;; Increment counter and return result
        (var-set total-vault-entries new-memory-id)
        (ok new-memory-id)
    )
)

;; Alternative memory update implementation with enhanced security
(define-public (secure-memory-modification
    (memory-id uint)
    (new-title (string-ascii 50))
    (new-hash-signature (string-ascii 64))
    (new-content (string-ascii 200))
    (new-tags (list 5 (string-ascii 30)))
)
    (let
        (
            (existing-record (unwrap! (map-get? quantum-memory-vault { memory-id: memory-id }) ERR_NOT_FOUND))
        )
        ;; Multi-layer security verification
        (asserts! (is-memory-owner? memory-id tx-sender) ERR_ACCESS_DENIED)
        (asserts! (valid-title? new-title) ERR_INVALID_INPUT)
        (asserts! (valid-hash-signature? new-hash-signature) ERR_INVALID_INPUT)
        (asserts! (valid-content? new-content) ERR_CONTENT_INVALID)
        (asserts! (valid-tags? new-tags) ERR_CONTENT_INVALID)

        ;; Execute secure modification
        (map-set quantum-memory-vault
            { memory-id: memory-id }
            (merge existing-record {
                title: new-title,
                hash-signature: new-hash-signature,
                content: new-content,
                updated-at: block-height,
                tags: new-tags
            })
        )
        
        (ok true)
    )
)

;; Optimized memory record creation using alternative storage
(define-public (optimized-memory-creation
    (title (string-ascii 50))
    (hash-signature (string-ascii 64))
    (content (string-ascii 200))
    (category (string-ascii 20))
    (tags (list 5 (string-ascii 30)))
)
    (let
        (
            (new-memory-id (+ (var-get total-vault-entries) u1))
            (current-time block-height)
        )
        ;; Complete parameter validation
        (asserts! (valid-title? title) ERR_INVALID_INPUT)
        (asserts! (valid-hash-signature? hash-signature) ERR_INVALID_INPUT)
        (asserts! (valid-content? content) ERR_CONTENT_INVALID)
        (asserts! (valid-category? category) ERR_TYPE_INVALID)
        (asserts! (valid-tags? tags) ERR_CONTENT_INVALID)

        ;; Store in optimized vault structure
        (map-set optimized-memory-vault
            { memory-id: new-memory-id }
            {
                title: title,
                owner: tx-sender,
                hash-signature: hash-signature,
                content: content,
                created-at: current-time,
                updated-at: current-time,
                category: category,
                tags: tags
            }
        )

        ;; Update global state and return
        (var-set total-vault-entries new-memory-id)
        (ok new-memory-id)
    )
)

;; Simplified memory record update with focused validation
(define-public (simplified-memory-update
    (memory-id uint)
    (new-title (string-ascii 50))
    (new-hash-signature (string-ascii 64))
    (new-content (string-ascii 200))
    (new-tags (list 5 (string-ascii 30)))
)
    (let
        (
            (existing-record (unwrap! (map-get? quantum-memory-vault { memory-id: memory-id }) ERR_NOT_FOUND))
        )
        ;; Owner verification
        (asserts! (is-memory-owner? memory-id tx-sender) ERR_ACCESS_DENIED)
        
        ;; Create updated record structure
        (let
            (
                (updated-record (merge existing-record {
                    title: new-title,
                    hash-signature: new-hash-signature,
                    content: new-content,
                    tags: new-tags,
                    updated-at: block-height
                }))
            )
            ;; Save updated record
            (map-set quantum-memory-vault { memory-id: memory-id } updated-record)
            (ok true)
        )
    )
)

