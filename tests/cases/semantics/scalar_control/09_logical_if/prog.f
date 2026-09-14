      PROGRAM LOGIF
      INTEGER TRES, FRES
      LOGICAL COND
      TRES = 0
      COND = 3 .GT. 2 .AND. .NOT. (1 .GT. 2)
      IF (COND) TRES = 1
      FRES = 0
      COND = 3 .LT. 2 .AND. .NOT. (1 .GT. 2)
      IF (COND) FRES = 1
      WRITE (*, 100) TRES, FRES
  100 FORMAT (I1, 1X, I1)
      END
