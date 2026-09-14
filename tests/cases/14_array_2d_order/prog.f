      PROGRAM ARR2D
      INTEGER A(2,2)
      DATA A /11, 21, 12, 22/
      WRITE (*, 100) A(1,1), A(2,1), A(1,2), A(2,2)
  100 FORMAT (I2, 1X, I2, 1X, I2, 1X, I2)
      END
