;----------------------------- ASSEMBLER SOURCE -----------------------------
;Name            : SORCERER.ASM
;Author          : Cyberfish of The Lost Souls
;Last update     : 02.05.1995
;Action          : A beautiful BBS-intro
;
;
;Using Libraries             : -
;Using external object files : PAL.OBJ
;                              LOGO.OBJ
;                              INT_DATA.OBJ
;                              FONT.OBJ
;
;Notes : Nothing to say. In a few months I've probably forgotten how this
;mess works anyway.
;----------------------------------------------------------------------------

DOSSEG
.Model  Small
.STACK  200h

ASSUME          ds : MyData, cs : MyCode

;-------------------------------- CONSTANTS ----------------------------------
IntXMove        EQU 1                           ;The angle to internally
IntYMove        EQU 3                           ;rotate the object each frame
IntZMove        EQU 1

MaxVertices     EQU 10                          ;Maximum vertices for n-polys

XSize           EQU 8
YSize           EQU 8
TextLength      EQU 165         + 27            ;Add 27 spaces

Area            EQU XSize * YSize


;------------------------------ DATA SEGMENT ---------------------------------


MyData        SEGMENT
EXTRN           SinTabl : WORD
EXTRN           Font : WORD
EXTRN           Palette : BYTE
EXTRN           StarTabl : BYTE, Col : WORD
EXTRN           Logo : BYTE

;----------------------------------------------------------------------------
;The three values are the vertices to draw the triangle between. Remember
;to change the constant.
;----------------------------------------------------------------------------

NumOfPolys      EQU 17
PolyVerts       DB  04, 00, 01, 02, 03
                DB  04, 03, 04, 05, 06
                DB  04, 06, 07, 08, 09
                DB  04, 09, 10, 11, 00

                DB  04, 00, 03, 06, 09

                DB  03, 11, 01, 00
                DB  03, 03, 02, 04
                DB  03, 07, 06, 05
                DB  03, 10, 09, 08

                DB  03,  1, 11, 12
                DB  03, 12,  2,  1
                DB  03, 12,  4,  2
                DB  03,  5,  4, 12
                DB  03,  7,  5, 12

                DB  03, 12,  8,  7
                DB  03, 12, 10,  8
                DB  03, 12, 11, 10

;----------------------------------------------------------------------------
;The coordinates in order X, Y, Z. The object must be constructed around
;origo, or else it'll be some strange rotating here. You must also change
;the constant so it corresponds with the number of vertices.
;----------------------------------------------------------------------------

NumOfPoints     EQU 13
PointCoords     DW   50, -50, -50            ;A
                DW   50,   0,-100
                DW  -50,   0,-100
                DW  -50, -50, -50

                DW -100,   0, -50
                DW -100,   0,  50
                DW  -50, -50,  50

                DW  -50,   0, 100
                DW   50,   0, 100
                DW   50, -50,  50

                DW  100,   0, 50
                DW  100,   0,-50

                DW    0, 150,  0

ObjAngleX       DW 0                            ;The rotation of the WHOLE
ObjAngleY       DW 0                            ;object
ObjAngleZ       DW 0
IntAngleX       DW 0                            ;The internal rotation
IntAngleY       DW 0                            ;of the object
IntAngleZ       DW 0
ObjXOrig        DW 1000                         ;The coordinates of the
ObjYOrig        DW 50                           ;object
ObjZOrig        DW -150

ObjXMove        DW 0
ObjYMove        DW 0
ObjZMove        DW 0

ObjX            DW 0
ObjY            DW 0
ObjZ            DW 0

StartUpSeq      DB 1
EndSeq          DB 0

Text            DB 27 DUP (44)
                DB 19, 15, 18, 3, 5, 18, 5, 18, 44, 2, 2, 19, 44, 48, 44, 46, 44, 30, 33, 44, 33, 28, 44, 34, 33, 44, 28, 34, 44, 33, 30, 44, 48, 44, 20, 8, 5, 44, 12, 15, 19, 20, 44, 19, 15, 21, 12, 19, 44, 23, 15, 18, 12, 4, 44, 8, 17, 44, 48, 44, 20, 5, 18, 13, 9, 14, 1, 20, 5, 44, 19, 21, 16, 16, 15, 18, 20, 44, 19, 9, 20, 5, 44, 48, 44, 2, 9, 12, 12, 9, 15, 14, 19, 44, 15, 6, 44, 2, 25, 20, 5, 19, 44, 15, 14, 12, 9, 14, 5, 37, 44, 16, 18, 15, 7, 18, 1, 13, 13, 9, 14, 7, 44, 18, 5, 12, 1, 20, 5, 4, 44, 6, 9, 12, 5, 19, 44, 1, 14, 4, 44, 3, 15, 14, 6, 5, 18, 5, 14, 3, 5, 19, 44, 48, 44, 46, 33, 28, 34, 33, 28, 34, 33, 30, 46

TempStr         DB 27 DUP (44)                  ;44 = space
StrCounter      DW 0
WaveCounter     DW 0
TextY           DW 0

EndString1      DB '-------------------- Sorcerer BBS +47 72 87 28 74 -intro ---------------------', 0Dh, 0Ah, '$'
EndString2      DB '+666+ Coding and graphics by Cyberfish of TLS. Object by Kezoomer of TLS. +666+', 0Dh, 0Ah, '$'
EndString3      DB '                       A product of The Lost Souls 1995.', 0Dh, 0Ah, '$'

;-----------------------------------------------------------------------------
;These are the variables needed for the Poly - procedure
;-----------------------------------------------------------------------------

P_Col           DW 0                            ;
P_X1Inc         DW 0                            ;
P_X2Inc         DW 0                            ;
P_DeltaX1       DW 0                            ;
P_DeltaY1       DW 0                            ;
P_DeltaX2       DW 0                            ;
P_DeltaY2       DW 0                            ;
P_StartOffs     DW 0                            ;Variables for procedure
P_EndOffs       DW 0                            ;"POLY"
P_NextX1        DW 0                            ;Next X clockwise
P_NextX2        DW 0                            ;Next X counterclockwise
P_COffs1        DW 0                            ;
P_COffs2        DW 0                            ;
P_UpperOffs     DW 0                            ;
P_LowestY       DW 0                            ;
P_YCounter      DW 0                            ;
P_Vertices      DB 0                            ;Number of Vertices

;-----------------------------------------------------------------------------
;These are the variables needed for the Rotate -procedure
;-----------------------------------------------------------------------------

_X              DW 0                            ;
_Y              DW 0                            ;
_Z              DW 0                            ;Variables for procedure
X_Angle         DW 0                            ;"ROTATE"
Y_Angle         DW 0                            ;Storage variables for the
Z_Angle         DW 0                            ;input values
NewX            DW 0                            ;
NewY            DW 0                            ;
NewZ            DW 0                            ;

MyData        ENDS

;----------------------- UNINITIALIZED DATA SEGMENT -------------------------
UnIntData     SEGMENT                           ;Uninitialized data

TempCoords      DB NumOfPoints * 4 DUP (?)      ;4 bytes for XY-coordinates
TempPoly        DB (2 * 2 * MaxVertices) + 1 DUP (?) ;Can hold up to 10-vertice-polygons

UnIntData     ENDS

;------------------------------ CODE SEGMENT --------------------------------
MyCode        SEGMENT

.386

Initialize    PROC
                mov  ax, MyData                ;Point ds to data-segment
                mov  ds, ax

                mov  ax, UnIntData             ;Point fs to the ?-datasegment
                mov  fs, ax

                mov  ax, Canvas
                mov  es, ax

                mov  al, 13h                   ;320x200x256
                mov  ah, 00h                   ;set screenmode
                int  10h

                mov   dx,3C8h                   ;Port to send out startingcolor
                xor   al,al                     ;Starting color = 0

                out   dx, al                    ;Poek det ut!

                inc   dx                        ;Neste port sendes RGB verdiene
                mov   si, OFFSET Palette

                mov   cx,768                    ;3*256 (RGB)=768 colors
                rep   outsb

                mov   TextY, 8                  ;Initialize scroller

                ret
Initialize    ENDP

ShutDown      PROC
                mov  al, 03h                    ;80x25x16
                mov  ah, 00h                    ;set screenmode
                int  10h

                mov   dx, OFFSET EndString1
                mov   ah, 9h                    ;Write string
                int   21h
                mov   dx, OFFSET EndString2
                mov   ah, 9h                    ;Write string
                int   21h
                mov   dx, OFFSET EndString3
                mov   ah, 9h                    ;Write string
                int   21h

                ret
ShutDown      ENDP

WaitForRaster  PROC    NEAR

               PUSH    AX
               PUSH    DX
               MOV     DX,3dah
.loop1:        IN      AL,DX
               and    AL,08h
               JNz     .loop1
;.loop2:        IN      Al,DX
;               TEST    AL,8
;               JE      .loop2
               POP     DX
               POP     AX
               RET

WaitForRaster  ENDP

Scroll        PROC
                pusha
                pushf

                mov   ax, Dings
                mov   es, ax

SinLoop :
                mov   di, TextY                 ;Drawstring, start
                shl   di, 3
                xor   bx, bx
                xor   ax, ax
CharLoop :
                mov   al, BYTE PTR TempStr[bx]
                dec   al
                mov   si, ax
                shl   si, 6
                add   si, OFFSET Font

                mov   cx, Area / 4
                rep   movsd
                mov   cx, 2
                xor   eax, eax
                rep   stosd
                inc   bx
                cmp   bx, 27
                jb    CharLoop                  ;DrawString, end

                mov   ax, Canvas                ;Transfer, start
                mov   es, ax

                mov   ax, Dings
                mov   ds, ax

                mov   ax, MyData
                mov   fs, ax

                xor   bp, bp
                xor   dx, dx
                mov   si, 64

HorLoop :
                mov   di, bp

                mov   bx, dx
                add   bx, fs:WaveCounter
                cmp   bx, 360
                jle   SinOK
                sub   bx, 360
SinOK :
                shl   bx, 1
                mov   bx, fs:[SinTabl + bx]
                sar   bx, 3
                add   di, bx
                add   di, 50
                mov   cx, XSize
MoveLoop :
                lodsb
                add   al, 64
                cmp   al, 64
                jne   BackGround
                mov   al, es:[di]
                jmp   Store
BackGround :
                sub   al, 64
                mov   ah, al
                mov   al, es:[di]
                shr   al, 2
                add   al, ah
Store :
                mov   ah, al
                stosw
                Loop  MoveLoop
                add   bp, 320
                inc   dx
                cmp   dx, 200
                jb    HorLoop

                mov   ax, MyData
                mov   ds, ax

                mov   ax, Dings
                mov   es, ax                    ;Transfer, end

                mov   ax, UnIntData
                mov   fs, ax

                dec   TextY                     ;Update, start
                jnz   TextYOK
                mov   TextY, 9
                mov   bx, StrCounter
                mov   si, OFFSET TempStr
                mov   cx, 27

TextLoop :
                mov   al, Text[bx]
                mov   [si], al
                inc   bx
                inc   si
                cmp   bx, TextLength
                jb    StartOver
                xor   bx, bx
StartOver :
                Loop  TextLoop

                inc   StrCounter
                cmp   StrCounter, TextLength - 1
                jb    TextYOK
                mov   StrCounter, -1
TextYOK :                                       ;Update, end

                add   WaveCounter, 5
                cmp   WaveCounter, 360
                jb    WaveOK
                sub   WaveCounter, 360
WaveOK :

                mov   ax, Canvas
                mov   es, ax

                popf
                popa
                ret
Scroll        ENDP

ViewLogo      PROC
                mov   si, OFFSET Logo
                mov   di, 238
                mov   ax, 29

LogoLoop :
                mov   cx, 21
                rep   movsd
                add   di, 236

                dec   ax
                jnz   LogoLoop
                ret
ViewLogo      ENDP


;----------------------------------------------------------------------------
;A procedure which manages the calculating of the points.
;----------------------------------------------------------------------------

Rotation      PROC
                mov   si, OFFSET PointCoords
                mov   di, OFFSET TempCoords
                mov   cx, NumOfPoints

RotateLoop :
                push  cx                        ;Save counter

                mov   ax, [si]                  ;Load X
                mov   bx, [si + 2]              ;Load Y
                mov   cx, [si + 4]              ;Load Z
                add   si, 6

                push  si
                push  di

                mov   dx, IntAngleX
                mov   si, IntAngleY
                mov   di, IntAngleZ

                call  Rotate                    ;Rotate the coordinates

                pop   di
                pop   si

                add   ax, ObjX
                add   bx, ObjY
                add   cx, ObjZ                  ;Move along Z
                sar   cx, 1
                add   cx, 50

                call  F3DTo2D                   ;ax=InX, bx=InY, cx=InZ, ax=OutX, bx=OutY

                add   ax, 160                   ;Move to center  (Add X)
                add   bx, 100                   ;of screen       (Add Y)

                mov   fs:[di], ax               ;Put the calculated X
                mov   fs:[di+2], bx             ;and Y in TempCoords
                add   di, 4                     ;Point to next record

                pop   cx                        ;Restore counter
                Loop  RotateLoop                ;Next coordinate

                ret                             ;Go home!
Rotation      ENDP

;----------------------------------------------------------------------------
;Takes care of drawing the Triangles on the screen. The calculated points are
;now in the array TempCoords.
;----------------------------------------------------------------------------

DrawPolys     PROC
                mov   si, OFFSET PolyVerts
                mov   di, OFFSET TempCoords

                mov   cx, NumOfPolys            ;Load counter

TriangleLoop :
                mov   bp, OFFSET TempPoly

                xor   ah, ah                    ;Zero upper bits of ax
                mov   al, [si]                  ;Load verticesnumber
                inc   si                        ;Point to coordinates
                mov   fs:[bp], al               ;Save verticesnumber
                inc   bp                        ;Point to coordinates
                push  cx                        ;Save polycounter
                mov   cx, ax                    ;Put verticecounter in cx
LoadLoop :
                xor   bh, bh                    ;Zero upper bits of bx
                mov   bl, BYTE PTR [si]         ;Load first vertice
                shl   bx, 2                     ;Make two word-values(*4 bytes)
                mov   ax, fs:[di+bx]            ;Put X-coordinate in cx
                mov   dx, fs:[di+bx+2]          ;Put Y-coordinate in dx
                mov   fs:[bp], ax               ;Put X-coordinate in TempPoly
                mov   fs:[bp + 2], dx           ;Put Y-coordinate in TempPoly
                add   bp, 4                     ;Next record in TempPoly
                inc   si                        ;Next vertice
                loop  LoadLoop                  ;Do next vertice

                push  si                        ;Save pointer to PolyVerts

                mov   si, OFFSET TempPoly
                inc   si                        ;Dump verticenumber

                call  Visible                  ;Test if triangle is visible
                cmp   ax, 0
                jl    NotDraw                   ;If not, drop it!

                shr   ax, 8                     ;
                add   ax, 10
                mov   bp, ax

                mov   si, OFFSET TempPoly       ;Point to n-polygon-data
                call  Poly

NotDraw :
                pop   si                        ;Restore si
                pop   cx                        ;Restore counter
                Loop  TriangleLoop              ;Do next Triangle

                ret                             ;Go home!
DrawPolys     ENDP


Main          PROC                              ;The main procedure
                call  Initialize

VecLoop :
                mov   ax, ObjXMove
                add   ObjAngleX, ax       ;Rotate the coordinate
                cmp   ObjAngleX, 360
                jb    ObjXReset
                sub   ObjAngleX, 360
ObjXReset :
                mov   ax, ObjYMove
                add   ObjAngleY, ax
                cmp   ObjAngleY, 360
                jb    ObjYReset
                sub   ObjAngleY, 360
ObjYReset :
                mov   ax, ObjZMove
                add   ObjAngleZ, ax
                cmp   ObjAngleZ, 360
                jb    ObjZReset
                sub   ObjAngleZ, 360
ObjZReset :

                mov   ax, ObjXOrig              ;Load coordinates
                mov   bx, ObjYOrig
                mov   cx, ObjZOrig
                mov   dx, ObjAngleX             ;Load angles
                mov   si, ObjAngleY
                mov   di, ObjAngleZ
                call  Rotate                    ;Rotate it
                mov   ObjX, ax                  ;Save the new object-coords
                mov   ObjY, bx
                mov   ObjZ, cx

                add   IntAngleX, IntXMove
                cmp   IntAngleX, 360
                jb    IntXReset
                sub   IntAngleX, 360
IntXReset :
                add   IntAngleY, IntYMove
                cmp   IntAngleY, 360
                jb    IntYReset
                sub   IntAngleY, 360
IntYReset :
                add   IntAngleZ, IntZMove
                cmp   IntAngleZ, 360
                jb    IntZReset
                sub   IntAngleZ, 360
IntZReset :

                cmp   StartUpSeq, 0
                je    NoStartSeq
                sub   ObjXOrig, 5
                cmp   ObjXOrig, 0
                jg    NoStartSeq
                mov   ObjXMove, 2
                mov   ObjYMove, 3
                mov   ObjZMove, 1
                mov   StartUpSeq, 0
NoStartSeq :

                cmp   EndSeq, 0
                je    NoEndSeq

                xor   ah, ah
                mov   cx, 768
                mov   si, OFFSET Palette
FadeDownLoop :
                mov   al, [si]
                cmp   al, 0
                je    NoFade
                mov   ah, 1
                dec   al
                mov   [si], al
NoFade :
                inc   si
                Loop  FadeDownLoop

                mov   dx,3C8h                   ;Port to send out startingcolor
                xor   al,al                     ;Starting color = 0

                out   dx, al                    ;Poek det ut!

                inc   dx                        ;Neste port sendes RGB verdiene
                mov   si, OFFSET Palette

                mov   cx,768                    ;3*256 (RGB)=768 colors
                rep   outsb

                cmp   ah, 0
                je    ExitProg

                sub   ObjXOrig, 5
                cmp   ObjXOrig, -500
                jg    NoEndSeq
                jmp   ExitProg
NoEndSeq :
                xor   di, di
                mov   cx, 16000
                xor   eax, eax
                rep   stosd

                call  StarField2
                call  Rotation
                call  DrawPolys
                call  Scroll
                call  ViewLogo
                call  WaitForRaster

                mov   ax, Canvas
                mov   ds, ax
                mov   ax, 0A000h
                mov   es, ax

                xor   di, di
                xor   si, si
                mov   cx, 16000

                rep   movsd

                mov   ax, MyData
                mov   ds, ax
                mov   ax, Canvas
                mov   es, ax

                mov   ah, 0Bh                   ;Check keyboard
                int   21h                       ;
                cmp   al, 00h                   ;Have somebody pressed a key?
                jne   Done                      ;OK, go home!
                jmp   VecLoop                   ;No? Let's do another roll!
Done :
                mov   EndSeq, 1
                jmp   VecLoop
ExitProg :
                call  ShutDown

                mov   ah, 4Ch                   ;Terminate program
                int   21h                       ;Do it!
Main          ENDP

;----------------------------------------------------------------------------
;Name         : F3DTO2D
;Type         : Procedure
;Last update  : 09.01.95
;Action       : Projects 3D-coordinates (X, Y, Z) into the visible
;               X, Y - coordinates for the screen.
;Optimized    : Yes
;
;Input variables : ax = X   bx = Y   cx = Z
;
;Output variables : ax = NewX bx = NewY
;
;Registers changed : ax, bx, cx, dx, bp
;
;Notes : The coordinates are calculated using origo as center.
;----------------------------------------------------------------------------

F3DTo2D       PROC
                add   cx, 256
                cmp   ax, 0                     ;Below CenterX?
                je    _DoneX
                jg    _XPositive

_XNegative :
                xor   dx, dx                    ;Zero dx
                neg   ax                        ;Make ax positive
                mov   dl, ah                    ;\
                mov   ah, al                    ;Shift left by 8=multiply by 256
                xor   al, al                    ;/

                idiv  cx                        ;dx:ax / bx
                neg   ax                        ;Make ax negative again
                jmp   _DoneX

_XPositive :
                xor   dx, dx                    ;Zero dx

                mov   dl, ah                    ;\
                mov   ah, al                    ;Shift left by 8=multiply by 256
                xor   al, al                    ;/

                idiv  cx                        ;dx:ax / bx

_DoneX :
                cmp   bx, 0                     ;Is Y positive?
                je    _DoneY
                mov   bp, ax                    ;Save ax (NewX)
                jg    _YPositive

_YNegative :
                mov   ax, bx                    ;Put Y in ax
                neg   ax                        ;Make ax (Y) positive
                xor   dx, dx
                mov   dl, ah                    ;\
                mov   ah, al                    ;Shift left by 8=multiply by 256
                xor   al, al                    ;/

                idiv  cx
                neg   ax                        ;Make ax (Y) negative again
                mov   bx, ax                    ;Put NewY in bx
                mov   ax, bp                    ;Restore ax (NewX)

                ret                             ;Go home!

_YPositive :
                mov   ax, bx                    ;Put Y in ax
                xor   dx, dx                    ;Zero dx

                mov   dl, ah                    ;\
                mov   ah, al                    ;Shift left by 8=multiply by 256
                xor   al, al                    ;/

                idiv  cx                        ;dx:ax / bx
                mov   bx, ax                    ;Put NewY in bx
                mov   ax, bp                    ;Restore ax (NewX)

_DoneY :
                ret                             ;Go home!

F3DTo2D       ENDP

;----------------------------------------------------------------------------
;Name         : Rotate
;Type         : Procedure
;Last update  : 25.12.94
;Action       : Rotates a point around origo
;Optimized    : No. How do I a reduce the muls to 9???
;
;Input variables : ax = X   bx = Y   cx = Z
;                  dx = X_Angle si = Y_Angle di = Z_Angle
;
;Output variables : ax = NewX  bx = NewY  cx = NewZ
;
;Registers changed : ax, bx, cx
;
;Notes : Yes! Yes! Yes! At last : Rotating in assembler.
;----------------------------------------------------------------------------

Rotate        PROC
                pusha                           ;Save registers
                mov   _X, ax                    ;Save coordinates
                mov   _Y, bx                     ;
                mov   _Z, cx                     ;

                shl   dx, 1                     ;Make word values(*2)
                shl   si, 1                     ;
                shl   di, 1                     ;

                mov   X_Angle, dx               ;Save angles
                mov   Y_Angle, si               ;
                mov   Z_Angle, di               ;


;----------------------------------------------------------------------------
;Let's rock around the X-axis first :
;----------------------------------------------------------------------------

                mov   si, OFFSET SinTabl + 180  ;Point si to the Cos-values
                add   si, dx                    ;Point to value [X_Angle]
                mov   cx, [si]                  ;Load cosinus(X_angle) in cx
                mov   si, OFFSET SinTabl        ;Point si to the Sin-values
                add   si, dx                    ;Point to value [X_Angle]
                mov   bp, [si]                  ;Load sinus(X_angle) in bp

                mov   ax, _Y                     ;Put Y-coordinate in ax

                imul  cx                        ;Multiply Y with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   X_YPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   X_YDone1                  ;Done!

X_YPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

X_YDone1 :                                      ;The final result is now in ax
                mov   di, ax                    ;Save ax in di

                mov   ax, _Z                     ;Put Z-coordinate in ax

                imul  bp                        ;Multiply Z (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   X_YPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx                        ;
                                                ;
                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   X_YDone2                  ;Done!


X_YPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

X_YDone2 :
                sub   di, ax                    ;Done
                mov   NewY, di                  ;Save NewY

;----------------------------------------------------------------------------
;Done calculating the new Y-coordinate rotated X_Angle degrees
;----------------------------------------------------------------------------

                mov   ax, _Y                     ;Put Y-coordinate in ax

                imul  bp                        ;Multiply Y (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   X_ZPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   X_ZDone1                  ;Done!


X_ZPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

X_ZDone1 :                                      ;The final answer is now in ax
                mov   di, ax                    ;Save ax in di

                mov   ax, _Z

                imul  cx                        ;Multiply Z (ax) with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   X_ZPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   X_ZDone2                  ;Done!

X_ZPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

X_ZDone2 :                                      ;The final answer is now in ax
                add   di, ax
                mov   NewZ, di                  ;Save NewZ

;----------------------------------------------------------------------------
;Done calculating the new Z-coordinate rotated X_Angle degrees
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
;Let's do the Z-axis :
;----------------------------------------------------------------------------

                mov   dx, Z_Angle

                mov   si, OFFSET SinTabl + 180  ;Point si to the Cos-values
                add   si, dx                    ;Point to value [Z_Angle]
                mov   cx, [si]                  ;Load cosinus(Z_angle) in cx
                mov   si, OFFSET SinTabl        ;Point si to the Sin-values
                add   si, dx                    ;Point to value [Z_Angle]
                mov   bp, [si]                  ;Load sinus(Z_angle) in bp

                mov   ax, _X                     ;Put X-coordinate in ax

                imul  cx                        ;Multiply X with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Z_XPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Z_XDone1                  ;Done!

Z_XPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Z_XDone1 :                                      ;The final result is now in ax
                mov   di, ax                    ;Save ax in di

                mov   ax, NewY                  ;Put Y-coordinate in ax

                imul  bp                        ;Multiply Y (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Z_XPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx                        ;
                                                ;
                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Z_XDone2                  ;Done!


Z_XPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

Z_XDone2 :
                sub   di, ax
                mov   NewX, di                  ;Save NewX

;----------------------------------------------------------------------------
;Done calculating the new X-coordinate rotated Z_Angle degrees
;----------------------------------------------------------------------------

                mov   ax, NewY                  ;Put Y-coordinate in ax

                imul  cx                        ;Multiply Y (ax) with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Z_YPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Z_YDone1                  ;Done!


Z_YPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Z_YDone1 :                                      ;The final answer is now in ax
                mov   di, ax
                mov   ax, _X                     ;Load X-coordinate

                imul  bp                        ;Multiply X (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Z_YPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Z_YDone2                  ;Done!

Z_YPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Z_YDone2 :                                      ;The final answer is now in ax
                add   di, ax
                mov   NewY, di                  ;Save NewY

;----------------------------------------------------------------------------
;Done calculating the new Y-coordinate rotated Z_Angle degrees
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
;Let's swing the Y-axis :
;----------------------------------------------------------------------------

                mov   dx, Y_Angle

                mov   si, OFFSET SinTabl + 180  ;Point si to the Cos-values
                add   si, dx                    ;Point to value [Z_Angle]
                mov   cx, [si]                  ;Load cosinus(Z_angle) in cx
                mov   si, OFFSET SinTabl        ;Point si to the Sin-values
                add   si, dx                    ;Point to value [Z_Angle]
                mov   bp, [si]                  ;Load sinus(Z_angle) in bp

                mov   ax, NewZ                  ;Put Z-coordinate in ax

                imul  cx                        ;Multiply Z with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Y_ZPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Y_ZDone1                  ;Done!

Y_ZPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Y_ZDone1 :                                      ;The final result is now in ax
                mov   di, ax                    ;Save ax in di

                mov   ax, NewX                  ;Put X-coordinate in ax

                imul  bp                        ;Multiply X (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Y_ZPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx                        ;
                                                ;
                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Y_ZDone2                  ;Done!


Y_ZPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

Y_ZDone2 :
                sub   di, ax                    ;Done
                mov   ax, NewZ                  ;Put "old" Z-coordinate in ax
                                                ;cause I can't use the newly
                                                ;calculated Z-coordinate here
                mov   NewZ, di                  ;Save NewZ

;----------------------------------------------------------------------------
;Done calculating the new Z-coordinate rotated Y_Angle degrees
;----------------------------------------------------------------------------

                imul  bp                        ;Multiply Z (ax) with Sinvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Y_XPositive1              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Y_XDone1                  ;Done!


Y_XPositive1 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Y_XDone1 :                                      ;The final answer is now in ax
                mov   di, ax                    ;Save ax in di

                mov   ax, NewX                  ;Put X-coordinate in ax

                imul  cx                        ;Multiply X (ax) with Cosvalue

                cmp   dx, 0                     ;Test if result is positive
                jge   Y_XPositive2              ;Jump if positive

                neg   dx                        ;Make answer positive
                dec   dx

                neg   ax                        ;

                mov   al, ah                    ;Shift right by 8
                mov   ah, dl

                neg   ax                        ;Make it negative again
                jmp   Y_XDone2                  ;Done!

Y_XPositive2 :
                mov   al, ah                    ;Shift right by 8
                mov   ah, dl                    ;

Y_XDone2 :                                      ;The final answer is now in ax
                add   di, ax
                mov   NewX, di                  ;Save NewX

;----------------------------------------------------------------------------
;Done calculating the new X-coordinate rotated Y_Angle degrees
;----------------------------------------------------------------------------

                popa                            ;Load registers

                mov   ax, NewX                  ;Put the calculated
                mov   bx, NewY                  ;values back in to the
                mov   cx, NewZ                  ;registers

                ret

Rotate        ENDP

;--------------------------- ASSEMBLER ROUTINE -------------------------------
;Name         : Visible
;Type         : Procedure
;Last update  : 10.04.95
;Action       : Tests if a triangle is visible for the crowd
;Optimized    : No. I know there is some improvements to be done.
;
;Input variables : [si] - [si+10] (6 Word values, 12 bytes)
;
;Output variables : ax
;
;Registers changed : ax, bx, cx, dx
;
;Notes : The input values are three XY-coords. If the triangle is visible,
;ax is returned with a positive value, if not it's coming home negative.
;The value of ax may be used for something useful, light-sourcing f.ex.
;PS : If the triangle is very big, you'll get an overflow on the ax-value,
;so you may want to divide the input-values down here before calculating.
;----------------------------------------------------------------------------

Visible       PROC
                push  bx
                push  cx
                push  dx
                push  si
                push  di
                pushf

                mov   ax, fs:[si]
                add   si, 2
                mov   bx, fs:[si]
                add   si, 2
                mov   cx, fs:[si]
                add   si, 2
                mov   dx, fs:[si]
                add   si, 2
                mov   di, fs:[si]
                add   si, 2
                mov   si, fs:[si]

                sar   ax, 1
                sar   bx, 1
                sar   cx, 1
                sar   dx, 1
                sar   si, 1
                sar   di, 1

                sub   cx, ax                    ;X2-X1
                sub   si, bx                    ;Y3-Y1
                sub   dx, bx                    ;Y2-Y1
                sub   di, ax                    ;X3-X1

                mov   ax, di
                imul  dx
                mov   bx, ax

                mov   ax, si
                imul  cx

                sub   ax, bx

                popf
                pop   di
                pop   si
                pop   dx
                pop   cx
                pop   bx
                ret
Visible       ENDP

;--------------------------- ASSEMBLER ROUTINE -------------------------------
;Name         : Poly
;Author       : Cyberfish of The Lost Souls
;Type         : Procedure
;Last update  : 10.04.95
;Action       : Draws a filled n-polygon
;Optimized    : Well, I don't know. In my way, it is.
;
;Input variables : [si] = number of vertices (n)
;                  [si + 1] -> [si * n]
;                  bp = color
;
;Registers changed : None.
;
;Notes : Well... Nothing much to say. It works!
;The line-calculating algoritm is the same as in my line-procedure.
;In short, it works like this :
;BEFORE LOOP :
;1. Find DeltaX, DeltaY
;2. Save DeltaX and DeltaY, and put a copy of DeltaX in a counter
;INSIDE LOOP
;3. Test if the counter is below DeltaY. If so, increase by DeltaX, draw a
;   vertical pixel and do loop over again.
;4. If the counter is above DeltaY, then sub the counter by DeltaY and draw
;   a horisontal pixel.
;5. Test if the lineX, Y-counters has passed the line ending-vertice.
;----------------------------------------------------------------------------

Poly          PROC
                pusha                           ;Save registers
                pushf                           ;Save flags state
                cld
                clc

                mov   ax, bp                    ;Make both high and low byte
                mov   ah, al                    ;contain the same color
                mov   P_Col, ax                 ;Save color

                xor   dx, dx

                mov   dl, fs:[si]               ;Load number of vertices
                mov   P_Vertices, dl            ;Save vertices
                inc   si                        ;Point si to the coordinates

                dec   dl                        ;svada
                mov   cl, dl                    ;Put counter in cl

                mov   P_StartOffs, si           ;Save offset to coordinates
                mov   bp, si                    ;Take a copy of startoffs

                shl   dl, 2                     ;Vertices * 2 (word) * 2 (X,Y)
                add   dx, si                    ;Add input-offset
                mov   P_EndOffs, dx             ;Save end-offs to coordinates

                mov   bx, si
                add   si, 4
                mov   bp, WORD PTR fs:[bx + 2]
                mov   P_YCounter, bp
                mov   P_LowestY, bp

P_Upper :
                mov   ax, fs:[si + 2]
                add   si, 4
                cmp   ax, P_YCounter
                jg    P_Under
                mov   bx, si
                sub   bx, 4
                mov   P_YCounter, ax
P_Under :
                cmp   ax, P_LowestY
                jl    P_Over
                mov   P_LowestY, ax
P_Over :
                loop  P_Upper

                mov   P_UpperOffs, bx           ;Save offs of upper coordinate
                mov   si, bx                    ;Load upper coord-offs
                mov   di, bx                    ;Save upper coord-offs

                mov   ax, fs:[si]                  ;Load X1
                mov   bx, fs:[si + 2]              ;Load Y1

                cmp   si, P_EndOffs             ;Test if si is at end of
                jb    P_NotEnd                  ;coordinate list

                mov   si, P_StartOffs           ;If so, point to start
                sub   si, 4                     ;Neutralize the adding
                stc                             ;Indicate no further testing is needed
P_NotEnd :
                add   si, 4                     ;Point to next coordinates
                mov   P_COffs1, si
                mov   cx, fs:[si]                  ;Load X2
                mov   dx, fs:[si + 2]              ;Load Y2
                mov   P_NextX1, cx              ;Save next X-value clockwise

                mov   si, di                    ;Load upper coord-offs
                jc    P_NotStart                ;No testing necessary
                cmp   si, P_StartOffs           ;Test if si is at the start
                jg    P_NotStart                ;of the coordinate list

                mov   si, P_EndOffs             ;If so, point to end
                add   si, 4                     ;Neutralize subtraction
P_NotStart :
                sub   si, 4                     ;Point to next coordinates
                mov   P_COffs2, si
                mov   di, fs:[si]                  ;Load X3
                mov   si, fs:[si + 2]              ;Load Y3
                mov   P_NextX2, di              ;Save next X-value c-clockwise

;--------- About to calculate DeltaX and direction of X1, Y1 - X2, Y2 ---------

                mov   P_X1Inc, 1                ;Count X1 right
                mov   bp, 1
                cmp   ax, cx
                jle   P_Right1                  ;X1 < X2 = count right
                mov   P_X1Inc, -1               ;Count X1 left
                mov   bp, -1
P_Right1 :
                add   P_NextX1, bp
                sub   cx, ax                    ;DeltaX1
                cmp   cx, 0                     ;Make-
                jge   P_DeltX1Pos               ;DeltaX1-
                neg   cx                        ;positive!
P_DeltX1Pos :

                sub   dx, bx                    ;DeltaY1
                inc   cx                        ;Fix
                inc   dx                        ;Fix
                mov   P_DeltaX1, cx             ;Save DeltaX1
                mov   P_DeltaY1, dx             ;Save DeltaY1

;--------- Done calculating direction and delta of X1, Y1 - X2, Y2 ---------


                mov   P_X2Inc, 1                ;Count X2 right
                mov   bp, 1
                cmp   ax, di                    ;X1, X3
                jle   P_Right2                  ;X1 < X3 = count right
                mov   P_X2Inc, -1               ;Count X2 left
                mov   bp, -1
P_Right2 :
                add   P_NextX2, bp
                sub   di, ax                    ;DeltaX2
                cmp   di, 0                     ;Make-
                jg    P_DeltX2Pos               ;DeltaX2-
                neg   di                        ;Positive!
P_DeltX2Pos :

                sub   si, bx                    ;DeltaY
                inc   di                        ;Fix
                inc   si                        ;Fix
                mov   P_DeltaX2, di             ;Save DeltaX2
                mov   P_DeltaY2, si             ;Save DeltaY2

;--------- Done calculating direction and delta of X1, Y1 - X3, Y3 ---------

                mov   dx, bx
                shl   dx, 6                     ;Multiply by 320 to calc di's
                add   dh, bl                    ;pos in VGA-segment
                add   dx, ax                    ;Add X
                mov   di, dx                    ;Point di to the start-offs
                mov   si, dx                    ;Point si to the start-offs

                mov   dx, P_DeltaX1             ;Put DeltaX1 in dx to save time
                mov   bp, P_DeltaX2             ;Put DeltaX2 in bp to save time
                mov   bx, ax                    ;values


P_Loop :                                        ;Here starts the loop
                cmp   dx, P_DeltaY1
                jb    P_TestFin

                sub   dx, P_DeltaY1
                add   ax, P_X1Inc               ;Increase/decrease X-counter

                add   di, P_X1Inc
                cmp   ax, P_NextX1

                jne   P_Loop

;-------------------- Here goes the new verticecalculating ------------------

                sub   di, P_X1Inc

                push  di
                push  si

                mov   di, P_COffs1
                mov   si, P_COffs1

                cmp   si, P_EndOffs             ;Test if si is at the start
                jl    P_LNotEnd                 ;of the coordinate list

                mov   si, P_StartOffs           ;If so, point to end
                sub   si, 4                     ;Neutralize following sub
P_LNotEnd :
                add   si, 4                     ;Point to next coordinates
                mov   dx, fs:[si]                  ;Can't move directly <|-(
                mov   P_NextX1, dx              ;Save next X-value c-clockwise
                mov   P_COffs1, si

                mov   ax, fs:[si]
                mov   P_X1Inc, 1                ;Count X2 right
                mov   dx, 1
                cmp   fs:[di], ax               ;X - NextX
                jle   P_LRight1
                mov   P_X1Inc, -1               ;Count X2 left
                mov   dx, -1
P_LRight1 :
                add   P_NextX1, dx
                sub   ax, fs:[di]               ;DeltaX2
                cmp   ax, 0
                jge   P__DeltX1Pos
                neg   ax
P__DeltX1Pos :
                inc   ax
                mov   P_DeltaX1, ax
                mov   dx, ax

                mov   ax, fs:[si + 2]
                sub   ax, fs:[di + 2]
                inc   ax
                mov   P_DeltaY1, ax

                mov   ax, fs:[di]

                pop   si
                pop   di

P_TestFin :
                push  ax

                mov   ax, P_YCounter
                cmp   ax, P_LowestY
                jl    P_NotFinish

                pop   ax
                popf                            ;Restore flags
                popa                            ;Restore registers
                ret                             ;Go home!
P_NotFinish :
                pop   ax

P_TestC2 :
                cmp   bp, P_DeltaY2
                jb    P_IncY

                sub   bp, P_DeltaY2
                add   bx, P_X2Inc               ;Increase/decrease X-counter
                add   si, P_X2Inc

                cmp   bx, P_NextX2              ;Finish?
                jne   P_TestC2                  ;Way to go!

;-------------------- Here goes the new verticecalculating ------------------

                sub   si, P_X2Inc

                push  di
                push  si

                mov   di, P_COffs2
                mov   si, P_COffs2

                cmp   si, P_StartOffs           ;Test if si is at the start
                jg    P_LNotStart               ;of the coordinate list

                mov   si, P_EndOffs             ;If so, point to end
                add   si, 4                     ;Neutralize following sub
P_LNotStart :
                sub   si, 4                     ;Point to next coordinates
                mov   bp, fs:[si]                  ;Can't move directly <|-(
                mov   P_NextX2, bp              ;Save next X-value c-clockwise
                mov   P_COffs2, si

                mov   bx, fs:[si]
                mov   P_X2Inc, 1                ;Count X2 right
                mov   bp, 1
                cmp   fs:[di], bx               ;X - NextX
                jle   P_LRight2
                mov   P_X2Inc, -1               ;Count X2 left
                mov   bp, -1
P_LRight2 :
                add   P_NextX2, bp
                sub   bx, fs:[di]               ;DeltaX2
                cmp   bx, 0
                jge   P__DeltX2Pos
                neg   bx
P__DeltX2Pos :
                inc   bx
                mov   P_DeltaX2, bx
                mov   bp, bx

                mov   bx, fs:[si + 2]
                sub   bx, fs:[di + 2]
                inc   bx
                mov   P_DeltaY2, bx

                mov   bx, fs:[di]

                pop   si
                pop   di

P_IncY :
                add   dx, P_DeltaX1
                add   bp, P_DeltaX2

                push  ax                        ;Save some all-purpose-regs
                push  bx
                push  cx
                push  di                        ;...and the pointers
                push  si

                cmp   P_YCounter, 0            ;Clip at top
                jl    P_DoneFill               ;Above? Then done.
                cmp   P_YCounter, 200          ;Clip at bottom
                jge   P_DoneFill               ;Below? Then done.

;------ Test X1-counter against left side of the screen (X-value = 0) --------

                cmp   ax, 0                     ;Clip against left side
                jg    Cl_TestX1Right
                mov   cx, P_YCounter
                shl   cx, 6                     ;Multiply by 320 to calc di's
                add   ch, BYTE PTR P_YCounter  ;pos in VGA-segment
                mov   di, cx                    ;Put new mem-position in di

                cmp   bx, 0                     ;Test if both pointers is
                jg    Cl_TestX2Right            ;outside at left side

                mov   al, 1
                mov   si, di
                jmp   P_DoneClip

;------ Test X1-counter against right side of the screen (X-value = 0) -------

Cl_TestX1Right :
                cmp   ax, 319                   ;Clip against right side
                jl    Cl_TestX2Left
                mov   cx, P_YCounter
                shl   cx, 6                     ;Multiply by 320 to calc di's
                add   ch, BYTE PTR P_YCounter  ;pos in the VGA-segment
                add   cx, 319                   ;Move to screen's right side
                mov   di, cx                    ;Put new mem-position in di

                cmp   bx, 319                   ;Test if both pointers is
                jl    Cl_TestX2Left             ;outside at right side

                mov   al, 1
                mov   si, di
                jmp   P_DoneClip

;------- Test X2-counter against left side of the screen (X-value = 0) -------

Cl_TestX2Left :
                cmp   bx, 0                     ;Clip against left side
                jg    Cl_TestX2Right
                mov   cx, P_YCounter
                shl   cx, 6                     ;Multiply by 320 to calc si's
                add   ch, BYTE PTR P_YCounter  ;pos in the VGA-segment
                mov   si, cx

;------ Test X2-counter against right side of the screen (X-value = 0) -------

Cl_TestX2Right :
                cmp   bx, 319                   ;Clip against right side
                jl    P_DoneClip
                mov   cx, P_YCounter
                shl   cx, 6                     ;Multiply by 320 to calc si's
                add   ch, BYTE PTR P_YCounter  ;pos in the VGA-segment
                add   cx, 319                   ;Move to screen's right side
                mov   si, cx

P_DoneClip :

;----------- Done all clipping, both against sides and top/bottom -----------

                std
                mov   bl, -1
                mov   bh, -1
                mov   cx, di
                sub   cx, si

                mov   ah, -1

                cmp   cx, 0
                jge   P_CountPos
                neg   cx
                cld
                mov   bl, 1
                mov   bh, 1
                mov   ah, 1
P_CountPos :
                cmp   al, 1
                je    P_Clipping
                inc   cx
P_Clipping :

                mov   ax, P_Col

                test  cx, 0000000000000001b
                jz    P_WordFill
                stosb
                dec   cx
P_WordFill :
                test  cx, 0000000000000010b
                jz    P_DWordFill

                cmp   bl, -1
                jne   P_NoFix1
                dec   di
P_NoFix1 :
                stosw
                sub  cx, 2
                mov  bh, 1
P_DWordFill :
                cmp   cx, 0
                jle   P_DoneFill

                cmp   bl, -1
                jne   P_NoFix3
                sub   di, 2
P_NoFix2 :

                cmp   bh, -1
                jne   P_NoFix3
                dec   di
P_NoFix3 :
                shl   eax, 16
                mov   al, BYTE PTR P_Col
                mov   ah, al

                shr   cx, 2
                rep   stosd

P_DoneFill :

                pop   si
                pop   di
                pop   cx
                pop   bx
                pop   ax

                add   di, 320
                add   si, 320
                inc   P_YCounter

                jmp   P_Loop

Poly          ENDP

;----------------------------------------------------------------------------
;Name         : StarField2
;Type         : Procedure
;Last update  : 12.02.95
;Action       : Draws/updates a starfield which rotates around you
;Optimized    : Yes.
;
;Input variables : -
;
;Output variables : -
;
;Registers changed : None
;
;Notes : The procedure contains a large table holding the random XYZ-coords
;for 250 stars. I guess it's possible to avoid this in some way. It takes the
;angle in the variables XAngle, YAngle and ZAngle and rotates the stars
;corresponding to these angles.
;----------------------------------------------------------------------------

StarField2    PROC
                pusha                           ;Save registers

                mov   si, OFFSET StarTabl       ;Point si to the startable
StarLoop :
                mov   ax, WORD PTR [si]         ;Load new X
                mov   bx, WORD PTR [si + 2]     ;Load new Y

                mov   cx, WORD PTR [si + 4]     ;Load new Z
                sub   cx, 9                     ;Move star
                cmp   cx, -512                  ;Check if the star has left us
                jg    Valid                     ;If not, don't bother
                mov   cx, 511                   ;If so, move it to front again
                mov   WORD PTR [si + 4], 512    ;/

Valid :
                sub   WORD PTR [si + 4], 9      ;Decrease the value in the table
                push  si                        ;Save pointers
                push  di                        ;/
                mov   dx, IntAngleX             ;Load angles to rotate
                mov   si, IntAngleY
                mov   di, IntAngleZ
                call  cs:Rotate                    ;Rotate it all over!
                pop   di                        ;Restore pointers
                pop   si                        ;/

                cmp   cx, 0                     ;Check if star is in front of the user
                jg    StarOK                    ;If so, then draw
                add   si, 6                     ;Point si to the next star in the table
                cmp   si, OFFSET StarTabl + 900d ;NumStars * 2 (Word = 2 bytes) * 3 (X, Y, Z) = 600 (100 stars)
                jb    StarLoop                  ;If not, do it again
                popa                            ;Restore registers
                ret                             ;Go home!

StarOK :
                add   cx, 255                   ;Move center forward
                mov   Col, cx                   ;Save Z-value
                call  F3DTo2D                   ;Calculate the 2D-coords
                add   ax, 160                   ;Move stars to the center
                add   bx, 100                   ;of the screen

                cmp   ax, 0                     ;
                jle   NoStar                    ;
                cmp   ax, 320                   ;
                jge   NoStar                    ;Test if the 2D-coords are
                cmp   bx, 0                     ;outside screen
                jle   NoStar                    ;
                cmp   bx, 200                   ;
                jge   NoStar                    ;

                mov   dx, bx
                mov   bx, Col                   ;Put Z-value in bx and use it as colour
                shr   bx, 5                     ;Divide it by 16
                mov   cx, 128
                sub   cx, bx

                mov   bx, dx                    ;These four lines
                shl   bx, 6                     ;calculates the
                add   bh, dl                    ;position in the
                add   bx, ax                    ;VGA-buffer

                mov   BYTE PTR es:[bx], cl      ;Put it in the VGA-buffer

NoStar :

                add   si, 6                     ;Point si to the next star in the table
                cmp   si, OFFSET StarTabl + 900d ;NumStars * 2 (Word = 2 bytes) * 3 (X, Y, Z) = 600 (100 stars)
                jb    StarLoop                  ;If not, do it again

                popa

                ret                             ;Updated all stars, go home!
StarField2    ENDP



MyCode        ENDS

;------------------------------ CANVAS SEGMENT -------------------------------
Canvas        SEGMENT
                DB 64000 DUP (?)
Canvas        ENDS

Dings         SEGMENT
                DB 1700 DUP (?)
Dings         ENDS

END             Main
