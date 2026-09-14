      PROGRAM ARR1D
      INTEGER A(3)
      A(1) = 11
      A(2) = 22
      A(3) = 33
      WRITE (*, 100) A(1), A(2), A(3)
  100 FORMAT (I2, 1X, I2, 1X, I2)
      END
