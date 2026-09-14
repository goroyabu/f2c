      PROGRAM EXPR
      INTEGER NATVAL, GRPVAL
      NATVAL = 2 + 3 * 4
      GRPVAL = (2 + 3) * 4
      WRITE (*, 100) NATVAL, GRPVAL
  100 FORMAT (I2, 1X, I2)
      END
