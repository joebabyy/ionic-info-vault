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