      PROGRAM ARRBND
      INTEGER A(-1:1)
      A(-1) = 41
      A(0) = 42
      A(1) = 43
      WRITE (*, 100) A(-1), A(0), A(1)
  100 FORMAT (I2, 1X, I2, 1X, I2)
      END
