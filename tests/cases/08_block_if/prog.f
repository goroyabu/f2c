      PROGRAM BLKIF
      INTEGER VALUE, NEGVAL, ZERO, POSVAL
      VALUE = -1
      NEGVAL = 0
      IF (VALUE .LT. 0) THEN
         NEGVAL = 1
      ELSE IF (VALUE .EQ. 0) THEN
         NEGVAL = 2
      ELSE
         NEGVAL = 3
      END IF
      VALUE = 0
      ZERO = 0
      IF (VALUE .LT. 0) THEN
         ZERO = 1
      ELSE IF (VALUE .EQ. 0) THEN
         ZERO = 2
      ELSE
         ZERO = 3
      END IF
      VALUE = 1
      POSVAL = 0
      IF (VALUE .LT. 0) THEN
         POSVAL = 1
      ELSE IF (VALUE .EQ. 0) THEN
         POSVAL = 2
      ELSE
         POSVAL = 3
      END IF
      WRITE (*, 100) NEGVAL, ZERO, POSVAL
  100 FORMAT (I1, 1X, I1, 1X, I1)
      END
