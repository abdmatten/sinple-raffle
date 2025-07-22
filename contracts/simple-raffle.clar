;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Simple Raffle Smart Contract on Stacks
;; Users enter by paying STX, and owner can pick a winner.
;; Winner receives the entire STX prize pool.
;; Educational / prototype use only.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant entry-fee u10000000) ;; 10 STX
(define-constant max-participants u100) ;; prevent gas blowup

;; Variables
(define-data-var participants (list 100 principal) (list))
(define-data-var raffle-active bool true)
(define-data-var owner principal tx-sender)

;; PUBLIC FUNCTION: Enter the raffle
(define-public (enter)
  (begin
    ;; Must be active
    (asserts! (var-get raffle-active) (err u100))

    ;; Prevent contract calls
    (asserts! (not (is-eq tx-sender (as-contract tx-sender))) (err u101))

    ;; Get current participants
    (let ((current (var-get participants)))
      ;; Check max participants
      (asserts! (< (len current) max-participants) (err u102))

      ;; Transfer STX to contract
      (asserts! (is-ok (stx-transfer? entry-fee tx-sender (as-contract tx-sender))) (err u103))

      ;; Add user to list
      (var-set participants (unwrap! (as-max-len? (append current tx-sender) u100) (err u104)))
      (ok true)
    )
  )
)

;; PUBLIC FUNCTION: Pick a winner (owner-only)
(define-public (pick-winner)
  (begin
    ;; Only owner
    (asserts! (is-eq tx-sender (var-get owner)) (err u200))

    ;; Must be active & have participants
    (asserts! (var-get raffle-active) (err u201))
    (let ((entries (var-get participants)))
      (asserts! (> (len entries) u0) (err u202))

      ;; Simulate randomness
      (let (
            (index (mod stacks-block-height (len entries)))
            (prize (* entry-fee (len entries)))
          )
        (match (element-at? entries index)
          winner-address
            (begin
              ;; Deactivate raffle
              (var-set raffle-active false)

              ;; Send STX to winner
              (try! (as-contract (stx-transfer? prize tx-sender winner-address)))
              (ok true)
            )
          (err u204) ;; Should never occur, added for completeness
        )
      )
    )
  )
)

;; PUBLIC FUNCTION: Reset the raffle (owner-only)
(define-public (reset-raffle)
  (begin
    (asserts! (is-eq tx-sender (var-get owner)) (err u300))
    (var-set participants (list))
    (var-set raffle-active true)
    (ok true)
  )
)

;; READ-ONLY: Get all participants
(define-read-only (get-participants)
  (ok (var-get participants))
)

;; READ-ONLY: Is raffle active?
(define-read-only (is-active)
  (ok (var-get raffle-active))
)

;; READ-ONLY: Get current owner
(define-read-only (get-owner)
  (ok (var-get owner))
)
