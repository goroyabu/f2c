      PROGRAM DONEG
      INTEGER I, TOTAL
      TOTAL = 0
      DO 10 I = 5, 1, -2
   10 TOTAL = TOTAL + I
      WRITE (*, 100) TOTAL
  100 FORMAT (I1)
      END
