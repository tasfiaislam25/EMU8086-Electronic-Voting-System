.MODEL SMALL

PRINT_MSG MACRO MESSAGE
    LEA DX, MESSAGE
    MOV AH, 09h
    INT 21h
ENDM

.STACK 100H

.DATA
    ; Login Variables
    PASSWORD        DB 'admin', 0       ; Hardcoded password (null terminated)
    INPUT_BUFFER    DB 20 DUP(0)        ; Buffer for user input
    LOGIN_ATTEMPTS  DB 0
    MAX_ATTEMPTS    DB 3

    ; Candidate Variables
    ; We will store up to 5 candidates, each name max 20 chars
    ; 5 * 20 = 100 bytes
    ; Initialized to 0 (empty)
    CANDIDATES      DB 100 DUP(0)
    CAND_COUNT      DB 0
    MAX_CANDIDATES  DB 5
    CAND_NAME_LEN   DB 20           ; Max length per name

    ; Messages
    MSG_ENTER_PASS  DB 0Dh, 0Ah, 'Enter Password: $'
    MSG_WELCOME     DB 0Dh, 0Ah, 'Login Successful! Welcome Admin.', 0Dh, 0Ah, '$'
    MSG_WRONG_PASS  DB 0Dh, 0Ah, 'Invalid Password!', 0Dh, 0Ah, '$'
    MSG_LOCKED      DB 0Dh, 0Ah, 'SYSTEM LOCKED due to too many failed attempts.', 0Dh, 0Ah, '$'

    MSG_ADD_NAME    DB 0Dh, 0Ah, 'Enter Candidate Name: $'
    MSG_FULL        DB 0Dh, 0Ah, 'Error: List is full!', 0Dh, 0Ah, '$'
    MSG_ADDED       DB 0Dh, 0Ah, 'Candidate Added.', 0Dh, 0Ah, '$'

    MSG_SEARCH_PRPT DB 0Dh, 0Ah, 'Enter Name to Search: $'
    MSG_FOUND       DB 0Dh, 0Ah, 'Candidate Found!', 0Dh, 0Ah, '$'
    MSG_NOT_FOUND   DB 0Dh, 0Ah, 'Candidate Not Found.', 0Dh, 0Ah, '$'

    MSG_DEL_PRPT    DB 0Dh, 0Ah, 'Enter Name to Remove: $'
    MSG_DELETED     DB 0Dh, 0Ah, 'Candidate Removed.', 0Dh, 0Ah, '$'

    MSG_EMPTY_LIST  DB 0Dh, 0Ah, 'No candidates in the list.', 0Dh, 0Ah, '$'

    NEWLINE         DB 0Dh, 0Ah, '$'

    ; --- VOTER & VOTING VARIABLES ---
    VOTERS          DB 100 DUP(0)   ; 5 Voters * 20 chars
    VOTER_COUNT     DB 0
    MAX_VOTERS      DB 5
    VOTER_HAS_VOTED DB 5 DUP(0)     ; 0=No, 1=Yes. Index corresponds to implicit ID 1..5

    CANDIDATE_VOTES DB 5 DUP(0)     ; Vote counts kept internally for statistics

    TOTAL_VOTES      DB 0
    WINNER_ID        DB 0
    RUNNER_ID        DB 0
    WINNER_VOTES     DB 0
    RUNNER_VOTES     DB 0
    TIE_COUNT        DB 0
    TIE_PRINTED      DB 0

    ; Election Statistics Messages
    MSG_STATS_HEADER DB 0Dh, 0Ah, '--- ELECTION STATISTICS ---', 0Dh, 0Ah, '$'
    MSG_STATS_REG    DB 'Registered Voters: $'
    MSG_STATS_CAST   DB 0Dh, 0Ah, 'Votes Cast: $'
    MSG_STATS_TURN   DB 0Dh, 0Ah, 'Voter Turnout: $'
    MSG_STATS_CANDS  DB 0Dh, 0Ah, 0Dh, 0Ah, 'Candidate Vote Share:', 0Dh, 0Ah, '$'
    MSG_PERCENT      DB ' - Percentage: $'
    MSG_PERCENT_END  DB '%', 0Dh, 0Ah, '$'
    MSG_WINNER       DB 0Dh, 0Ah, 'Winner: $'
    MSG_RUNNER       DB 0Dh, 0Ah, 'Runner-up: $'
    MSG_TIE          DB 0Dh, 0Ah, 'Election Tie: $'
    MSG_TIE_SEP      DB ', $'
    MSG_NA           DB 'N/A$'
    MSG_NO_VOTES     DB 0Dh, 0Ah, 'No votes have been cast yet.', 0Dh, 0Ah, '$'

    ; Voter Messages
    MSG_REG_NAME    DB 0Dh, 0Ah, 'Enter Voter Name: $'
    MSG_REG_ID      DB 0Dh, 0Ah, 'Registered! Your Voter ID is: $'
    MSG_DUP_VOTER   DB 0Dh, 0Ah, 'Error: Voter already registered!', 0Dh, 0Ah, '$'
    MSG_VOTER_FULL  DB 0Dh, 0Ah, 'Error: Voter list full!', 0Dh, 0Ah, '$'

    ; Voting Messages
    MSG_VOTE_ID_PRPT DB 0Dh, 0Ah, 'Enter your Voter ID (1-5): $'
    MSG_INVALID_ID   DB 0Dh, 0Ah, 'Error: Invalid Voter ID!', 0Dh, 0Ah, '$'
    MSG_ALREADY_VOTED DB 0Dh, 0Ah, 'Error: You have already voted!', 0Dh, 0Ah, '$'
    MSG_SEL_CAND     DB 0Dh, 0Ah, 'Enter Candidate Number to Vote For (1-5): $'
    MSG_VOTE_CAST    DB 0Dh, 0Ah, 'Vote Cast Successfully!', 0Dh, 0Ah, '$'
    MSG_INV_CAND     DB 0Dh, 0Ah, 'Error: Invalid Candidate!', 0Dh, 0Ah, '$'
    MSG_SHOW_VOTES   DB ' - Votes: $' ; Used in View Candidates and Election Statistics

    ; Updated Menu
    MSG_MENU        DB 0Dh, 0Ah, 0Dh, 0Ah, '--- MAIN MENU ---', 0Dh, 0Ah
                    DB '1. Add Candidate', 0Dh, 0Ah
                    DB '2. View Candidates', 0Dh, 0Ah
                    DB '3. Search Candidate', 0Dh, 0Ah
                    DB '4. Remove Candidate', 0Dh, 0Ah
                    DB '5. Exit', 0Dh, 0Ah
                    DB '6. Register Voter', 0Dh, 0Ah
                    DB '7. Cast Vote', 0Dh, 0Ah
                    DB '8. Election Statistics', 0Dh, 0Ah
                    DB 'Select option: $'

.CODE
MAIN PROC
    ; Initialize DS
    MOV AX, @DATA
    MOV DS, AX
    MOV ES, AX          ; Set ES for string operations (required for some instructions)

    ; FEATURE 1 START: ADMIN LOGIN & SECURITY
LOGIN_LOOP:
    ; Check attempts
    MOV AL, LOGIN_ATTEMPTS
    CMP AL, MAX_ATTEMPTS
    JAE SYSTEM_LOCK     ; If attempts >= max, lock system

    ; Prompt Password
    LEA DX, MSG_ENTER_PASS
    MOV AH, 09h
    INT 21h

    ; Read Password
    CALL READ_STRING    ; Reads into INPUT_BUFFER

    ; Verify Password
    ; Compare INPUT_BUFFER with PASSWORD
    LEA SI, INPUT_BUFFER
    LEA DI, PASSWORD

    CALL COMPARE_STRINGS
    CMP AX, 1           ; AX=1 if match, 0 if mismatch
    JE LOGIN_SUCCESS

    ; Failed Login
    LEA DX, MSG_WRONG_PASS
    MOV AH, 09h
    INT 21h

    INC LOGIN_ATTEMPTS
    JMP LOGIN_LOOP

SYSTEM_LOCK:
    LEA DX, MSG_LOCKED
    MOV AH, 09h
    INT 21h
    JMP EXIT_PROGRAM    ; Terminate program

LOGIN_SUCCESS:
    LEA DX, MSG_WELCOME
    MOV AH, 09h
    INT 21h
    ; FEATURE 1 END


    ; --- MAIN MENU LOOP ---
MAIN_MENU:
    LEA DX, MSG_MENU
    MOV AH, 09h
    INT 21h

    ; Read single char for option
    MOV AH, 01h
    INT 21h
    MOV BL, AL          ; Save option in BL

    ; Handle Options
    CMP BL, '1'
    JE OPT_ADD
    CMP BL, '2'
    JE OPT_VIEW
    CMP BL, '3'
    JE OPT_SEARCH
    CMP BL, '4'
    JE OPT_REMOVE
    CMP BL, '5'
    JE EXIT_PROGRAM
    CMP BL, '6'
    JE OPT_REG_VOTER
    CMP BL, '7'
    JE OPT_CAST_VOTE
    CMP BL, '8'
    JE OPT_STATS

    JMP MAIN_MENU       ; Invalid input, loop back

    ; --- OPTION HANDLERS ---
OPT_ADD:
    CALL ADD_CANDIDATE
    JMP MAIN_MENU

OPT_VIEW:
    CALL VIEW_CANDIDATES
    JMP MAIN_MENU

OPT_SEARCH:
    CALL SEARCH_CANDIDATE
    JMP MAIN_MENU

OPT_REMOVE:
    CALL REMOVE_CANDIDATE
    JMP MAIN_MENU

OPT_REG_VOTER:
    CALL REGISTER_VOTER
    JMP MAIN_MENU

OPT_CAST_VOTE:
    CALL CAST_VOTE
    JMP MAIN_MENU

OPT_STATS:
    CALL SHOW_ELECTION_STATISTICS
    JMP MAIN_MENU

EXIT_PROGRAM:
    MOV AX, 4C00H
    INT 21H

MAIN ENDP

; PROCEDURES

; procedure: READ_STRING
; Description: Reads string from user into INPUT_BUFFER until Enter key.
;              Null-terminates the string.
READ_STRING PROC
    PUSH AX
    PUSH BX
    PUSH SI

    LEA SI, INPUT_BUFFER

READ_CHAR_LOOP:
    MOV AH, 01h
    INT 21h

    CMP AL, 0Dh         ; Check for Enter key
    JE END_READ

    MOV [SI], AL        ; Store char
    INC SI
    JMP READ_CHAR_LOOP

END_READ:
    MOV [SI], 0         ; Null terminate
    POP SI
    POP BX
    POP AX
    RET
READ_STRING ENDP


; procedure: COMPARE_STRINGS
; Description: Compares null-terminated strings at SI and DI.
; Output: AX = 1 if match, 0 if mismatch.
COMPARE_STRINGS PROC
    PUSH SI
    PUSH DI
    PUSH CX
    PUSH BX

CMP_LOOP:
    MOV BL, [SI]
    MOV BH, [DI]

    CMP BL, BH
    JNE CMP_MISMATCH

    CMP BL, 0           ; Check if end of string (and they are equal)
    JE CMP_MATCH

    INC SI
    INC DI
    JMP CMP_LOOP

CMP_MISMATCH:
    MOV AX, 0
    JMP CMP_EXIT

CMP_MATCH:
    MOV AX, 1

CMP_EXIT:
    POP BX
    POP CX
    POP DI
    POP SI
    RET
COMPARE_STRINGS ENDP


; FEATURE 2 START: CANDIDATE MANAGEMENT
; Add Candidate
ADD_CANDIDATE PROC
    ; Check if full
    MOV AL, CAND_COUNT
    CMP AL, MAX_CANDIDATES
    JAE LIST_FULL_ERR

    ; Prompt Name
    LEA DX, MSG_ADD_NAME
    MOV AH, 09h
    INT 21h

    ; Find first empty slot
    ; We iterate through CANDIDATES list. An empty slot usually starts with 0.
    ; However, simplified logical mapping: Slot index = specific memory offset.
    ; We need to find *where* to write.

    ; Just use a simple search for first byte 0 in steps of 20
    LEA DI, CANDIDATES
    MOV CX, 5           ; Max 5 candidates
    MOV DX, 20          ; Stride length
    MOV BX, 1           ; ID Counter (1-5)

FIND_EMPTY_SLOT:
    CMP BYTE PTR [DI], 0    ; Check if first byte is 0 (empty)
    JE READ_INTO_SLOT
    ADD DI, 20          ; Move to next slot
    INC BX              ; Increment ID
    LOOP FIND_EMPTY_SLOT

    ; Should not reach here if count check passed, but safety:
    JMP LIST_FULL_ERR

READ_INTO_SLOT:
    ; DI points to the start of the empty slot
    ; We'll reuse logic similar to READ_STRING but write directly to [DI]

    PUSH DI
    ; Read string loop directly into memory pointed by DI
READ_CAND_LOOP:
    MOV AH, 01h
    INT 21h
    CMP AL, 0Dh
    JE FINISH_ADD
    MOV [DI], AL
    INC DI
    JMP READ_CAND_LOOP

FINISH_ADD:
    MOV BYTE PTR [DI], 0   ; Null terminate
    POP DI

    ; Reset this candidate ID's vote counter.
    ; This guarantees that a reused candidate slot always starts at 0 votes.
    PUSH BX
    DEC BX
    LEA SI, CANDIDATE_VOTES
    ADD SI, BX
    MOV BYTE PTR [SI], 0
    POP BX

    INC CAND_COUNT
    LEA DX, MSG_ADDED
    MOV AH, 09h
    INT 21h

    ; Display the Assigned ID
    MOV DL, ' '
    MOV AH, 02h
    INT 21h
    MOV DL, '('
    INT 21h
    MOV DL, 'I'
    INT 21h
    MOV DL, 'D'
    INT 21h
    MOV DL, ':'
    INT 21h
    MOV DL, BL          ; Load Assigned ID
    ADD DL, '0'
    INT 21h
    MOV DL, ')'
    INT 21h
    MOV DL, 0Ah         ; Newline
    INT 21h
    MOV DL, 0Dh
    INT 21h
    RET

LIST_FULL_ERR:
    LEA DX, MSG_FULL
    MOV AH, 09h
    INT 21h
    RET
ADD_CANDIDATE ENDP


; View Candidates
VIEW_CANDIDATES PROC
    LEA DX, NEWLINE
    MOV AH, 09h
    INT 21h

    CMP CAND_COUNT, 0
    JE NO_CANDS_VIEW

    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES ; Point to votes
    MOV CX, 5           ; Loop all possible slots
    MOV BX, 1           ; ID Counter (1-5)

VIEW_LOOP:
    CMP BYTE PTR [SI], 0    ; Is this slot empty?
    JE SKIP_PRINT

    ; --- PRINT ID ---
    MOV DL, BL          ; Load ID
    ADD DL, '0'         ; To ASCII
    MOV AH, 02h
    INT 21h

    MOV DL, '.'         ; Print dot
    MOV AH, 02h
    INT 21h

    MOV DL, ' '         ; Print space
    MOV AH, 02h
    INT 21h

    ; Print string at SI
    PUSH SI

PRINT_NAME_CHAR:
    LODSB               ; Load byte from DS:SI into AL
    CMP AL, 0
    JE DONE_PRINT_NAME
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    JMP PRINT_NAME_CHAR

DONE_PRINT_NAME:
    POP SI

    ; Show current vote count
    LEA DX, MSG_SHOW_VOTES
    MOV AH, 09h
    INT 21h

    XOR AX, AX
    MOV AL, [DI]
    CALL PRINT_NUMBER

    LEA DX, NEWLINE
    MOV AH, 09h
    INT 21h

SKIP_PRINT:
    ADD SI, 20          ; Move to next slot
    INC DI              ; Move to next vote count (1 byte per candidate)
    INC BX              ; Increment ID counter
    LOOP VIEW_LOOP
    RET

NO_CANDS_VIEW:
    LEA DX, MSG_EMPTY_LIST
    MOV AH, 09h
    INT 21h
    RET
VIEW_CANDIDATES ENDP

; Search Candidate
SEARCH_CANDIDATE PROC
    LEA DX, MSG_SEARCH_PRPT
    MOV AH, 09h
    INT 21h

    CALL READ_STRING    ; Input goes to INPUT_BUFFER

    LEA SI, CANDIDATES  ; Array to search
    MOV CX, 5           ; Max slots

SEARCH_LOOP:
    CMP BYTE PTR [SI], 0
    JE SEARCH_NEXT      ; Skip empty slots

    ; Compare INPUT_BUFFER with string at SI
    PUSH SI             ; Save current slot ptr
    LEA DI, INPUT_BUFFER

    ; Inner Compare Routine
    PUSH SI
    PUSH DI

INNER_CMP:
    MOV AL, [SI]
    MOV AH, [DI]
    CMP AL, AH
    JNE INNER_MISMATCH
    CMP AL, 0
    JE FOUND_IT         ; End of both strings and equal
    INC SI
    INC DI
    JMP INNER_CMP

INNER_MISMATCH:
    POP DI
    POP SI
    POP SI              ; Restore outer loop SI
    JMP SEARCH_NEXT

FOUND_IT:
    POP DI
    POP SI              ; Clean stack
    POP SI              ; Clean stack
    LEA DX, MSG_FOUND
    MOV AH, 09h
    INT 21h
    RET

SEARCH_NEXT:
    ADD SI, 20
    LOOP SEARCH_LOOP

    LEA DX, MSG_NOT_FOUND
    MOV AH, 09h
    INT 21h
    RET
SEARCH_CANDIDATE ENDP


; Remove Candidate
REMOVE_CANDIDATE PROC
    LEA DX, MSG_DEL_PRPT
    MOV AH, 09h
    INT 21h

    CALL READ_STRING    ; Input in INPUT_BUFFER

    LEA SI, CANDIDATES
    MOV CX, 5
    XOR BX, BX            ; BX = 0-based candidate slot index

REMOVE_LOOP:
    CMP BYTE PTR [SI], 0
    JE REMOVE_NEXT

    PUSH SI
    LEA DI, INPUT_BUFFER

    ; Compare logic inline
    PUSH SI
    PUSH DI
RM_CMP_LOOP:
    MOV AL, [SI]
    MOV AH, [DI]
    CMP AL, AH
    JNE RM_MISMATCH
    CMP AL, 0
    JE DELETE_IT
    INC SI
    INC DI
    JMP RM_CMP_LOOP

RM_MISMATCH:
    POP DI
    POP SI
    POP SI
    JMP REMOVE_NEXT

DELETE_IT:
    POP DI
    POP SI
    POP SI              ; SI is now pointing to start of slot

    MOV BYTE PTR [SI], 0    ; Mark candidate slot as empty

    ; Clear the vote count belonging to this candidate ID.
    ; BX already contains the 0-based slot index.
    LEA DI, CANDIDATE_VOTES
    ADD DI, BX
    MOV BYTE PTR [DI], 0

    DEC CAND_COUNT

    LEA DX, MSG_DELETED
    MOV AH, 09h
    INT 21h
    RET

REMOVE_NEXT:
    ADD SI, 20
    INC BX                 ; Move to next candidate/vote slot
    LOOP REMOVE_LOOP

    LEA DX, MSG_NOT_FOUND
    MOV AH, 09h
    INT 21h
    RET
REMOVE_CANDIDATE ENDP
; FEATURE 2 END

; FEATURE 3 START: VOTER REGISTRATION
REGISTER_VOTER PROC
    ; Check if full
    MOV AL, VOTER_COUNT
    CMP AL, MAX_VOTERS
    JAE VOTER_FULL_ERR

    LEA DX, MSG_REG_NAME
    MOV AH, 09h
    INT 21h

    CALL READ_STRING    ; In INPUT_BUFFER

    ; Check duplicate name
    LEA SI, VOTERS
    MOV CX, 5

CHECK_DUP_LOOP:
    CMP BYTE PTR [SI], 0
    JE CHECK_NEXT_VOTER

    ; Compare with INPUT_BUFFER
    PUSH SI
    LEA DI, INPUT_BUFFER

    ; Inner compare
    PUSH SI
    PUSH DI
DUP_CMP:
    MOV AL, [SI]
    MOV AH, [DI]
    CMP AL, AH
    JNE DUP_MISMATCH
    CMP AL, 0
    JE IS_DUPLICATE     ; Match found
    INC SI
    INC DI
    JMP DUP_CMP

DUP_MISMATCH:
    POP DI
    POP SI
    POP SI
    JMP CHECK_NEXT_VOTER

IS_DUPLICATE:
    POP DI
    POP SI ; Clean stacks
    POP SI

    LEA DX, MSG_DUP_VOTER
    MOV AH, 09h
    INT 21h
    RET

CHECK_NEXT_VOTER:
    ADD SI, 20
    LOOP CHECK_DUP_LOOP

    ; If safe, find slot
    LEA DI, VOTERS
    MOV CX, 5
    MOV BX, 1           ; ID Counter start at 1

FIND_V_SLOT:
    CMP BYTE PTR [DI], 0
    JE WRITE_VOTER
    ADD DI, 20
    INC BX
    LOOP FIND_V_SLOT

    JMP VOTER_FULL_ERR

WRITE_VOTER:
    ; Copy INPUT_BUFFER to [DI]
    PUSH DI
    LEA SI, INPUT_BUFFER
COPY_V_LOOP:
    MOV AL, [SI]
    MOV [DI], AL
    CMP AL, 0
    JE DONE_COPY_V
    INC SI
    INC DI
    JMP COPY_V_LOOP

DONE_COPY_V:
    POP DI
    INC VOTER_COUNT

    LEA DX, MSG_REG_ID
    MOV AH, 09h
    INT 21h

    MOV DL, BL          ; BL holds ID
    ADD DL, '0'
    MOV AH, 02h
    INT 21h

    LEA DX, NEWLINE
    MOV AH, 09h
    INT 21h
    RET

VOTER_FULL_ERR:
    LEA DX, MSG_VOTER_FULL
    MOV AH, 09h
    INT 21h
    RET
REGISTER_VOTER ENDP
; FEATURE 3 END


; FEATURE 4 START: SECURE VOTE CASTING
; Candidate list used during voting - names only
SHOW_CANDIDATES_FOR_VOTING PROC
    LEA DX, NEWLINE
    MOV AH, 09h
    INT 21h

    CMP CAND_COUNT, 0
    JE NO_CANDS_VOTING

    LEA SI, CANDIDATES
    MOV CX, 5
    MOV BX, 1

VOTING_VIEW_LOOP:
    CMP BYTE PTR [SI], 0
    JE VOTING_VIEW_NEXT

    ; Print Candidate ID
    MOV DL, BL
    ADD DL, '0'
    MOV AH, 02h
    INT 21h

    MOV DL, '.'
    MOV AH, 02h
    INT 21h

    MOV DL, ' '
    MOV AH, 02h
    INT 21h

    ; Print Candidate Name
    PUSH SI

VOTING_NAME_LOOP:
    LODSB
    CMP AL, 0
    JE VOTING_NAME_DONE

    MOV DL, AL
    MOV AH, 02h
    INT 21h
    JMP VOTING_NAME_LOOP

VOTING_NAME_DONE:
    POP SI

    LEA DX, NEWLINE
    MOV AH, 09h
    INT 21h

VOTING_VIEW_NEXT:
    ADD SI, 20
    INC BX
    LOOP VOTING_VIEW_LOOP
    RET

NO_CANDS_VOTING:
    LEA DX, MSG_EMPTY_LIST
    MOV AH, 09h
    INT 21h
    RET
SHOW_CANDIDATES_FOR_VOTING ENDP

CAST_VOTE PROC
    LEA DX, MSG_VOTE_ID_PRPT
    MOV AH, 09h
    INT 21h

    ; Read one numeric char
    MOV AH, 01h
    INT 21h
    SUB AL, '0'         ; Convert ASCII to int
    MOV BL, AL          ; Store ID in BL

    ; ID Validation
    CMP BL, 1
    JL INVALID_VID
    CMP BL, 5
    JG INVALID_VID

    ; Check if ID exists (basically is slot occupied?)
    ; Or just simple logic: ID must be <= MAX_VOTERS?
    ; Better: Check if index has a name. Index = (ID-1) * 20
    XOR AH, AH
    MOV AL, BL
    DEC AL              ; 0-based index
    MOV SI, AX          ; Save index

    ; Check if that voter registered (name not empty)
    PUSH BX             ; Save ID
    MOV AX, 20
    MUL SI              ; AX = index * 20
    LEA DI, VOTERS
    ADD DI, AX
    CMP BYTE PTR [DI], 0
    JE INVALID_VID_POP
    POP BX

    ; FEATURE 5 START: ONE VOTER, ONE VOTE
    ; Check if this voter has already voted
    LEA DI, VOTER_HAS_VOTED
    ADD DI, SI          ; SI is 0-based Voter Index
    CMP BYTE PTR [DI], 1
    JE ALREADY_VOTED_ERR

    PUSH DI             ; Save pointer to HAS_VOTED slot for later update

    ; Show candidates without revealing current vote counts
    CALL SHOW_CANDIDATES_FOR_VOTING

    LEA DX, MSG_SEL_CAND
    MOV AH, 09h
    INT 21h

    MOV AH, 01h
    INT 21h
    SUB AL, '0'
    MOV CL, AL          ; Candidate ID in CL

    ; Validate Candidate ID (1..5)
    CMP CL, 1
    JL INV_CAND_ERR
    CMP CL, 5
    JG INV_CAND_ERR

    ; Check if Candidate Exists (is slot empty?)
    XOR CH, CH
    MOV BL, CL
    DEC BL              ; 0-based index
    MOV AX, 20
    MUL BL              ; AX = offset
    LEA SI, CANDIDATES
    ADD SI, AX
    CMP BYTE PTR [SI], 0
    JE INV_CAND_ERR

    ; FEATURE 6A START: VOTE COUNT UPDATE
    ; Update selected candidate's vote count
    ; Cand Index = CL - 1
    XOR CH, CH
    DEC CL
    LEA SI, CANDIDATE_VOTES
    ADD SI, CX
    INC BYTE PTR [SI]
    ; FEATURE 6A END

    ; Mark Voter as Voted
    POP DI              ; Restore HAS_VOTED ptr
    MOV BYTE PTR [DI], 1
    ; FEATURE 5 END

    LEA DX, MSG_VOTE_CAST
    MOV AH, 09h
    INT 21h
    RET

INVALID_VID_POP:
    POP BX
INVALID_VID:
    LEA DX, MSG_INVALID_ID
    MOV AH, 09h
    INT 21h
    RET

ALREADY_VOTED_ERR:
    LEA DX, MSG_ALREADY_VOTED
    MOV AH, 09h
    INT 21h
    RET

INV_CAND_ERR:
    POP DI              ; Cleanup stuck stack from logic flow
    LEA DX, MSG_INV_CAND
    MOV AH, 09h
    INT 21h
    RET
CAST_VOTE ENDP
; FEATURE 4 END


; FEATURE 6B START: ELECTION STATISTICS & RESULT DISPLAY
; PRINT_NUMBER: prints unsigned AX as decimal
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    CMP AX, 0
    JNE PN_CONVERT

    MOV DL, '0'
    MOV AH, 02h
    INT 21h
    JMP PN_DONE

PN_CONVERT:
    XOR CX, CX
    MOV BX, 10

PN_DIVIDE:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE PN_DIVIDE

PN_PRINT:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP PN_PRINT

PN_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP


; PRINT_CANDIDATE_NAME_BY_ID: prints candidate name for ID in AL
PRINT_CANDIDATE_NAME_BY_ID PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    DEC AL
    MOV BL, 20
    MUL BL                  ; AX = (ID - 1) * 20

    LEA SI, CANDIDATES
    ADD SI, AX

PCN_LOOP:
    MOV DL, [SI]
    CMP DL, 0
    JE PCN_DONE

    MOV AH, 02h
    INT 21h
    INC SI
    JMP PCN_LOOP

PCN_DONE:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
PRINT_CANDIDATE_NAME_BY_ID ENDP


SHOW_ELECTION_STATISTICS PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    PRINT_MSG MSG_STATS_HEADER

    ; Calculate TOTAL_VOTES using only active candidate slots
    MOV TOTAL_VOTES, 0
    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES
    MOV CX, 5

STAT_SUM_LOOP:
    CMP BYTE PTR [SI], 0
    JE STAT_SUM_NEXT

    MOV AL, [DI]
    ADD TOTAL_VOTES, AL

STAT_SUM_NEXT:
    ADD SI, 20
    INC DI
    LOOP STAT_SUM_LOOP

    ; Registered Voters
    PRINT_MSG MSG_STATS_REG

    XOR AX, AX
    MOV AL, VOTER_COUNT
    CALL PRINT_NUMBER

    ; Votes Cast
    PRINT_MSG MSG_STATS_CAST

    XOR AX, AX
    MOV AL, TOTAL_VOTES
    CALL PRINT_NUMBER

    ; Voter Turnout = TOTAL_VOTES * 100 / VOTER_COUNT
    PRINT_MSG MSG_STATS_TURN

    CMP VOTER_COUNT, 0
    JE STAT_TURNOUT_ZERO

    XOR AX, AX
    MOV AL, TOTAL_VOTES
    MOV BL, 100
    MUL BL                  ; AX = TOTAL_VOTES * 100

    MOV BL, VOTER_COUNT
    DIV BL                  ; AL = integer percentage
    XOR AH, AH
    CALL PRINT_NUMBER
    JMP STAT_TURNOUT_DONE

STAT_TURNOUT_ZERO:
    XOR AX, AX
    CALL PRINT_NUMBER

STAT_TURNOUT_DONE:
    PRINT_MSG MSG_PERCENT_END

    ; Candidate Vote Share
    PRINT_MSG MSG_STATS_CANDS

    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES
    MOV CX, 5
    MOV BX, 1               ; Candidate ID

STAT_CAND_LOOP:
    CMP BYTE PTR [SI], 0
    JE STAT_CAND_NEXT

    ; Print Candidate ID
    MOV DL, BL
    ADD DL, '0'
    MOV AH, 02h
    INT 21h

    MOV DL, '.'
    MOV AH, 02h
    INT 21h

    MOV DL, ' '
    MOV AH, 02h
    INT 21h

    ; Print Candidate Name
    PUSH SI

STAT_NAME_LOOP:
    LODSB
    CMP AL, 0
    JE STAT_NAME_DONE

    MOV DL, AL
    MOV AH, 02h
    INT 21h
    JMP STAT_NAME_LOOP

STAT_NAME_DONE:
    POP SI

    ; Print raw vote count for this candidate
    PRINT_MSG MSG_SHOW_VOTES
    XOR AX, AX
    MOV AL, [DI]
    CALL PRINT_NUMBER

    ; Print percentage for this candidate
    PRINT_MSG MSG_PERCENT

    ; Percentage = candidate votes * 100 / TOTAL_VOTES
    CMP TOTAL_VOTES, 0
    JE STAT_PERCENT_ZERO

    XOR AX, AX
    MOV AL, [DI]
    MOV DL, 100
    MUL DL                  ; AX = candidate votes * 100

    MOV DL, TOTAL_VOTES
    DIV DL                  ; AL = integer percentage
    XOR AH, AH
    CALL PRINT_NUMBER
    JMP STAT_PERCENT_DONE

STAT_PERCENT_ZERO:
    XOR AX, AX
    CALL PRINT_NUMBER

STAT_PERCENT_DONE:
    PRINT_MSG MSG_PERCENT_END

STAT_CAND_NEXT:
    ADD SI, 20
    INC DI
    INC BX
    LOOP STAT_CAND_LOOP

    ; If nobody voted, there is no winner/runner-up
    CMP TOTAL_VOTES, 0
    JNE STAT_FIND_RANKING

    PRINT_MSG MSG_NO_VOTES

    PRINT_MSG MSG_WINNER
    PRINT_MSG MSG_NA

    PRINT_MSG MSG_RUNNER
    PRINT_MSG MSG_NA

    PRINT_MSG NEWLINE
    JMP STAT_EXIT

    ; Find the highest vote total first.
    ; If more than one candidate has the same highest total,
    ; the result is displayed as an Election Tie.
STAT_FIND_RANKING:
    MOV WINNER_ID, 0
    MOV RUNNER_ID, 0
    MOV WINNER_VOTES, 0
    MOV RUNNER_VOTES, 0
    MOV TIE_COUNT, 0
    MOV TIE_PRINTED, 0

    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES
    MOV CX, 5
    MOV BX, 1

STAT_FIND_MAX_LOOP:
    CMP BYTE PTR [SI], 0
    JE STAT_FIND_MAX_NEXT

    MOV AL, [DI]

    ; First registered candidate initializes the current maximum
    CMP WINNER_ID, 0
    JE STAT_FIRST_MAX

    CMP AL, WINNER_VOTES
    JA STAT_NEW_MAX
    JE STAT_EQUAL_MAX
    JMP STAT_FIND_MAX_NEXT

STAT_FIRST_MAX:
    MOV WINNER_VOTES, AL
    MOV WINNER_ID, BL
    MOV TIE_COUNT, 1
    JMP STAT_FIND_MAX_NEXT

STAT_NEW_MAX:
    MOV WINNER_VOTES, AL
    MOV WINNER_ID, BL
    MOV TIE_COUNT, 1
    JMP STAT_FIND_MAX_NEXT

STAT_EQUAL_MAX:
    INC TIE_COUNT

STAT_FIND_MAX_NEXT:
    ADD SI, 20
    INC DI
    INC BX
    LOOP STAT_FIND_MAX_LOOP

    ; More than one candidate has the highest vote total
    CMP TIE_COUNT, 1
    JA STAT_PRINT_TIE

    ; Unique winner: now find the runner-up
    MOV RUNNER_ID, 0
    MOV RUNNER_VOTES, 0

    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES
    MOV CX, 5
    MOV BX, 1

STAT_FIND_RUNNER_LOOP:
    CMP BYTE PTR [SI], 0
    JE STAT_FIND_RUNNER_NEXT

    CMP BL, WINNER_ID
    JE STAT_FIND_RUNNER_NEXT

    MOV AL, [DI]

    CMP RUNNER_ID, 0
    JE STAT_SET_RUNNER

    CMP AL, RUNNER_VOTES
    JA STAT_SET_RUNNER
    JMP STAT_FIND_RUNNER_NEXT

STAT_SET_RUNNER:
    MOV RUNNER_VOTES, AL
    MOV RUNNER_ID, BL

STAT_FIND_RUNNER_NEXT:
    ADD SI, 20
    INC DI
    INC BX
    LOOP STAT_FIND_RUNNER_LOOP

    ; Print unique winner
    PRINT_MSG MSG_WINNER

    CMP WINNER_ID, 0
    JE STAT_WINNER_NA

    MOV AL, WINNER_ID
    CALL PRINT_CANDIDATE_NAME_BY_ID
    JMP STAT_PRINT_RUNNER

STAT_WINNER_NA:
    PRINT_MSG MSG_NA

STAT_PRINT_RUNNER:
    PRINT_MSG MSG_RUNNER

    CMP RUNNER_ID, 0
    JE STAT_RUNNER_NA

    MOV AL, RUNNER_ID
    CALL PRINT_CANDIDATE_NAME_BY_ID
    JMP STAT_FINISH

STAT_RUNNER_NA:
    PRINT_MSG MSG_NA
    JMP STAT_FINISH

    ; Print all candidates tied for the highest vote total
STAT_PRINT_TIE:
    PRINT_MSG MSG_TIE
    MOV TIE_PRINTED, 0

    LEA SI, CANDIDATES
    LEA DI, CANDIDATE_VOTES
    MOV CX, 5
    MOV BX, 1

STAT_TIE_LOOP:
    CMP BYTE PTR [SI], 0
    JE STAT_TIE_NEXT

    MOV AL, [DI]
    CMP AL, WINNER_VOTES
    JNE STAT_TIE_NEXT

    CMP TIE_PRINTED, 0
    JE STAT_TIE_PRINT_NAME

    PRINT_MSG MSG_TIE_SEP

STAT_TIE_PRINT_NAME:
    MOV AL, BL
    CALL PRINT_CANDIDATE_NAME_BY_ID
    INC TIE_PRINTED

STAT_TIE_NEXT:
    ADD SI, 20
    INC DI
    INC BX
    LOOP STAT_TIE_LOOP

STAT_FINISH:
    PRINT_MSG NEWLINE

STAT_EXIT:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_ELECTION_STATISTICS ENDP
; FEATURE 6B END

END MAIN
