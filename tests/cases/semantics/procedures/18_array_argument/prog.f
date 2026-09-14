      PROGRAM ARRARG
      INTEGER A(3)
      A(1) = 10
      A(2) = 20
      A(3) = 30
      CALL BUMP3(A)
      WRITE (*, 100) A(1), A(2), A(3)
  100 FORMAT (I2, 1X, I2, 1X, I2)
      END

      SUBROUTINE BUMP3(A)
      INTEGER A(3)
      A(1) = A(1) + 1
      A(2) = A(2) + 2
      A(3) = A(3) + 3
      RETURN
      END
