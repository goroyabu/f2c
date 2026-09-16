      PROGRAM LSTIN
      INTEGER IVAL
      REAL RVAL
      LOGICAL LVAL
      CHARACTER*5 TEXT
      READ (*,*) IVAL, RVAL, LVAL, TEXT
      WRITE (*,100) IVAL, RVAL, LVAL, TEXT
  100 FORMAT (SS,'[',I2,'] [',F3.1,'] [',L1,'] [',A5,']')
      END
