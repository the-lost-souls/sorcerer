Model   Small

PUBLIC          StarField2

Assume          cs : MyCode

MyCode        SEGMENT
.386

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
                mov   dx, ObjAngleX             ;Load angles to rotate
                mov   si, ObjAngleY
                mov   di, ObjAngleZ
                call  Rotate                    ;Rotate it all over!
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

END